import 'dart:async';

import 'dart:io';

import 'package:camera/camera.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';

import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';

import 'package:photocafe_windows/core/services/sound_service.dart';

import 'package:photocafe_windows/services/bouncy_session.dart';

import 'package:photocafe_windows/services/bouncy_fixture.dart';

import 'package:photocafe_windows/services/canon_camera_service.dart';

import 'package:photocafe_windows/widgets/canon_live_view_preview.dart';
import 'package:photocafe_windows/features/classic/domain/arcade_flow.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';

class ClassicCaptureScreen extends ConsumerStatefulWidget {
  final String backRoute;

  final String completionRoute;

  const ClassicCaptureScreen({
    super.key,
    this.backRoute = '/classic/start',

    this.completionRoute = '/classic/filter',
  });

  @override
  ConsumerState<ClassicCaptureScreen> createState() =>
      _ClassicCaptureScreenState();
}

class _ClassicCaptureScreenState extends ConsumerState<ClassicCaptureScreen> {
  static const _canon = bool.fromEnvironment(
    'BOUNCY_CANON',
    defaultValue: true,
  );

  CameraController? _controller;

  final _sound = SoundService();

  final _fixture = BouncyFixture();

  Timer? _timer;

  bool _ready = false;

  bool _capturing = false;

  bool _leaving = false;

  bool _retake = false;
  bool _qaPauseAfterTwo = false;

  int _shot = 0;

  int _seconds = 10;

  int _total = 10;

  String? _error;

  Future<void>? _captureWork;

  late final BouncySession _session;
  late final CanonCameraService _canonService;

  int _generation = 0;
  late final FrameTemplate? _arcadeFrame;
  int get _captureCount => _arcadeFrame?.captureCount ?? 4;
  bool _preparingPrint = false;

  @override
  void initState() {
    super.initState();
    _arcadeFrame = FrameCatalogRuntime.instance.sessionArcadeFrame;

    _session = ref.read(bouncySessionProvider);
    _canonService = ref.read(canonCameraServiceProvider);

    _generation = _session.generation;

    _sound.initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    try {
      _session.setMotionEnabled(
        FrameCatalogRuntime.instance.sessionBouncyEnabled,
      );
      final canon = _canonService;
      // Live view remains active; only the compressed motion ring is detached.
      canon.bouncySession =
          _session.motionEnabled && _canon && !BouncyFixture.enabled
          ? _session
          : null;
      await ref.read(photoProvider.notifier).setCaptureCount(_captureCount);

      _shot = ref.read(photoProvider).requireValue.photos.length;

      if (_shot >= _captureCount) {
        _shot = 0;
        _retake = true;
      }

      if (BouncyFixture.enabled) {
        await _fixture.start(_session);
      } else if (_canon) {
        if (!canon.isInitialized) await canon.initializeWithRetry();
      } else {
        // Preserve the user's CameraController still/preview test override.

        // It has no Canon EVF source: a still alone cannot pass Bouncy validation.

        final cameras = await availableCameras();

        if (cameras.isEmpty) throw StateError('No photo camera found.');

        final name = ref.read(printerProvider).value?.photoCameraName;

        final camera = cameras.firstWhere(
          (c) => c.name == name,

          orElse: () => cameras.first,
        );

        _controller = CameraController(
          camera,
          ResolutionPreset.high,

          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();
      }

      if (mounted && !_leaving) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _error = 'Photo camera unavailable: $error');
    }
  }

  void _countdown() {
    if (!_ready ||
        _capturing ||
        _preparingPrint ||
        _leaving ||
        _timer != null) {
      return;
    }
    if (_session.motionEnabled &&
        _canon &&
        !BouncyFixture.enabled &&
        !_session.hasFreshPreview) {
      setState(
        () => _error =
            'Waiting for fresh Canon live view. Restore the camera preview, then try this shot again.',
      );
      return;
    }

    setState(() {
      _total = BouncySession.countdown(shot: _shot, retake: _retake);

      _seconds = _total;

      _error = null;
    });

    final elapsed = Stopwatch()..start();

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || _leaving) {
        timer.cancel();
        return;
      }

      final remaining = (_total - elapsed.elapsedMilliseconds / 1000)
          .ceil()
          .clamp(0, _total);

      if (remaining != _seconds) {
        setState(() => _seconds = remaining);

        if (remaining > 0) _sound.playCountdownTick();
      }

      if (remaining == 0) {
        timer.cancel();
        _timer = null;

        _captureWork = _session.track(_capture());
      }
    });
  }

  Future<void> _capture() async {
    if (_capturing || _leaving) return;

    setState(() => _capturing = true);

    final existing = ref
        .read(photoProvider)
        .requireValue
        .photos
        .where((p) => p.index == _shot)
        .firstOrNull;
    final id = existing?.captureId ?? '${_generation}_shot_$_shot';

    final attempt = _session.attempt(id);

    String? source;

    try {
      // Freeze at the monotonic shutter-command boundary. SDK download time

      // never becomes part of the clip; strict Canon capture never retries.

      BouncyClip? clip = _session.motionEnabled ? _session.freeze() : null;

      if (clip != null && BouncyFixture.enabled && _fixture.mode == 'short') {
        final frozen = clip;
        clip = BouncyClip(
          frozen.frames
              .where((f) => frozen.shutterMicros - f.micros < 1000000)
              .toList(),
          frozen.shutterMicros,
        );
      } else if (clip != null &&
          BouncyFixture.enabled &&
          _fixture.mode == 'missing') {
        clip = BouncyClip([], clip.shutterMicros);
      }

      _sound.playShutterSound();

      source = BouncyFixture.enabled
          ? await _fixture.still()
          : _canon
          ? await ref
                .read(canonCameraServiceProvider)
                .takeBouncyPicture(
                  onShutterCommand: _session.motionEnabled
                      ? () => clip = _session.freeze()
                      : null,
                )
          : (await _controller!.takePicture()).path;

      if (!_session.current(attempt) || _leaving) return;

      if (_session.motionEnabled) {
        final frozen = clip!;
        if (frozen.problem != null) throw StateError(frozen.problem!);
        clip = await validateBouncyClipAsync(frozen);
      }

      if (!_session.current(attempt) || _leaving) return;

      final photos = ref.read(photoProvider).requireValue.photos;

      await ref
          .read(photoProvider.notifier)
          .addPhotoFromFile(
            source,

            attempt: attempt,
            clip: clip,

            replaceIndex: photos.any((p) => p.index == _shot) ? _shot : null,
          );

      if (!mounted || _leaving) return;

      setState(() {
        final completed = ref
            .read(photoProvider)
            .requireValue
            .photos
            .map((p) => p.index)
            .toSet();
        _shot = List.generate(_captureCount, (index) => index).firstWhere(
          (index) => !completed.contains(index),
          orElse: () => _captureCount,
        );
        _retake = false;
        _capturing = false;
      });

      if (_shot == _captureCount) {
        await _completeCapture();
      } else if (!(BouncyFixture.enabled && _qaPauseAfterTwo && _shot == 2)) {
        _countdown(); // No old two-second inter-shot delay.
      }
    } catch (error) {
      if (mounted && !_leaving) {
        setState(() {
          _retake = true;

          _error = '$error Other completed shots are safe.';
        });
      }
    } finally {
      if (source != null) {
        final file = File(source);

        if (await file.exists()) await file.delete();

        if (BouncyFixture.enabled && await file.parent.exists()) {
          await file.parent.delete();
        }
      }

      if (mounted && !_leaving) setState(() => _capturing = false);
    }
  }

  Future<void> _completeCapture() async {
    if (_arcadeFrame == null) {
      context.go(widget.completionRoute);
      return;
    }
    if (_preparingPrint || _leaving) return;
    setState(() {
      _preparingPrint = true;
      _error = null;
    });
    try {
      final pdf = await ref.read(arcadeFlowProvider).preparePrint();
      if (!mounted || _leaving || _generation != _session.generation) return;
      context.go(
        '/classic/print',
        extra: {
          'pdfBytes': pdf,
          'isLandscape':
              _arcadeFrame.classicVariant == ClassicVariant.landscape,
        },
      );
    } catch (error) {
      if (mounted && !_leaving) {
        setState(
          () => _error =
              'Could not prepare print: $error Your photos are safe. Retry to continue.',
        );
      }
    } finally {
      if (mounted) setState(() => _preparingPrint = false);
    }
  }

  Future<void> _back() async {
    if (_leaving) return;

    final unfinished = _shot > 0 || _capturing || _timer != null || _retake;

    if (unfinished) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          backgroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Color(0xff740000),
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: const TextStyle(
            color: Color(0xff740000),
            fontSize: 16,
          ),
          title: const Text('Cancel and start over?'),

          content: Text(
            _session.motionEnabled
                ? 'This will discard this session’s photos and motion clips.'
                : 'This will discard this session’s photos.',
          ),

          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xff740000),
              ),
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Keep session'),
            ),

            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Cancel and start over'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    _leaving = true;

    _timer?.cancel();
    _timer = null;

    _detachMotionFeed();
    _session.reset(); // Fence results before draining owned camera work.

    await _captureWork;

    await ref.read(photoProvider.notifier).clearAllPhotos();

    await _controller?.dispose();
    _controller = null;

    if (mounted) context.go(_arcadeFrame == null ? widget.backRoute : '/');
  }

  @override
  void dispose() {
    _leaving = true;
    _timer?.cancel();
    _fixture.dispose();
    _sound.dispose();
    _detachMotionFeed();

    final controller = _controller;

    unawaited(
      (_captureWork ?? Future<void>.value()).whenComplete(() async {
        await controller?.dispose();
      }),
    );

    super.dispose();
  }

  void _detachMotionFeed() {
    final canon = _canonService;
    if (identical(canon.bouncySession, _session)) canon.bouncySession = null;
  }

  Widget _preview() {
    if (BouncyFixture.enabled) {
      return StreamBuilder<int>(
        stream: Stream.periodic(const Duration(milliseconds: 83), (i) => i),

        builder: (context, _) => _fixture.latest == null
            ? const SizedBox()
            : Image.memory(
                _fixture.latest!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
      );
    }

    if (_canon) return const CanonLiveViewPreview(aspectRatio: 16 / 9);

    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox();
    }

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,

        child: SizedBox(
          width: controller.value.previewSize?.width ?? 1920,

          height: controller.value.previewSize?.height ?? 1080,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,

    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: _back,

                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),

                Expanded(
                  child: Text(
                    BouncyFixture.enabled
                        ? 'Disposable QA fixture • ${_session.motionEnabled ? 'Bouncy Previews' : 'Photo capture'}'
                        : _session.motionEnabled
                        ? 'Bouncy Previews'
                        : 'Photo capture',

                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ),

                if (BouncyFixture.enabled)
                  Row(
                    children: [
                      const Text(
                        'QA pause after shot 2',
                        style: TextStyle(color: Colors.white),
                      ),
                      Switch(
                        value: _qaPauseAfterTwo,
                        onChanged: _capturing
                            ? null
                            : (value) =>
                                  setState(() => _qaPauseAfterTwo = value),
                      ),
                    ],
                  ),
                Text(
                  'Photo ${(_shot + 1).clamp(1, _captureCount)} of $_captureCount',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),

            Expanded(
              child: Center(
                child: AspectRatio(aspectRatio: 16 / 9, child: _preview()),
              ),
            ),

            const SizedBox(height: 12),

            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Color(0xffffb4ab)),
                textAlign: TextAlign.center,
              ),

            Row(
              children: [
                for (var i = 0; i < _captureCount; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),

                    child: IconButton(
                      tooltip: 'Retake photo ${i + 1}',
                      onPressed:
                          _capturing ||
                              _preparingPrint ||
                              _timer != null ||
                              !ref
                                  .read(photoProvider)
                                  .requireValue
                                  .photos
                                  .any((p) => p.index == i)
                          ? null
                          : () => setState(() {
                              _shot = i;
                              _retake = true;
                              _error = null;
                            }),
                      icon: Icon(
                        ref
                                    .watch(photoProvider)
                                    .value
                                    ?.photos
                                    .any((p) => p.index == i) ==
                                true
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color:
                            ref
                                    .watch(photoProvider)
                                    .value
                                    ?.photos
                                    .any((p) => p.index == i) ==
                                true
                            ? Colors.greenAccent
                            : Colors.white54,
                      ),
                    ),
                  ),

                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _preparingPrint
                          ? 'Preparing print…'
                          : _capturing
                          ? 'Capturing…'
                          : _timer != null
                          ? 'Photo ${_shot + 1} in $_seconds seconds'
                          : !_ready
                          ? 'Preparing camera…'
                          : _retake
                          ? 'Ready to retake photo ${_shot + 1}. Other shots are safe.'
                          : 'Ready when you are',

                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),

                if (BouncyFixture.enabled)
                  DropdownButton<String>(
                    value: _fixture.mode,

                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),

                    items: ['valid', 'missing', 'short']
                        .map(
                          (m) =>
                              DropdownMenuItem(value: m, child: Text('QA $m')),
                        )
                        .toList(),

                    onChanged: _capturing || _timer != null
                        ? null
                        : (mode) => setState(() => _fixture.mode = mode!),
                  ),

                if (_timer != null)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => setState(() {
                      _timer?.cancel();
                      _timer = null;
                    }),

                    child: const Text('Pause'),
                  )
                else
                  FilledButton(
                    onPressed: !_ready || _capturing || _preparingPrint
                        ? null
                        : _shot == _captureCount
                        ? _completeCapture
                        : _countdown,

                    child: Text(
                      _shot == _captureCount
                          ? 'Continue to print'
                          : _retake
                          ? 'Retake this shot'
                          : 'Start capture',
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: _timer == null ? 0 : 1 - _seconds / _total,

              color: Colors.white,
              backgroundColor: Colors.white24,
              minHeight: 6,
            ),
          ],
        ),
      ),
    ),
  );
}
