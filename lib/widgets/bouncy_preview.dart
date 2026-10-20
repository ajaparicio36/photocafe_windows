import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';
import 'package:photocafe_windows/features/photos/domain/data/models/photo_model.dart';
import 'package:photocafe_windows/services/bouncy_media_service.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';

class BouncyPreview extends ConsumerStatefulWidget {
  final List<PhotoModel> photos;
  final List<KeychainVariantSelection> selections;
  final FrameLayoutType? classicLayout;
  final bool archive;
  final Color foregroundColor;
  const BouncyPreview({
    super.key,
    required this.photos,
    required this.selections,
    this.classicLayout,
    this.archive = false,
    this.foregroundColor = const Color(0xff740000),
  });
  @override
  ConsumerState<BouncyPreview> createState() => _BouncyPreviewState();
}

class _BouncyPreviewState extends ConsumerState<BouncyPreview> {
  late final BouncyMediaService _media = widget.archive
      ? ref.read(bouncyMediaProvider)
      : BouncyMediaService(ref.read(bouncySessionProvider));
  List<Uint8List>? _frames;
  Timer? _timer;
  String? _error;
  int _index = 0;
  int _request = 0;
  bool _paused = false;
  String get _key =>
      '${widget.photos.map((p) => '${p.captureId}:${p.index}').join('|')}:'
      '${widget.selections.map((s) => '${s.frameId}:${s.filterId}').join('|')}:${widget.classicLayout}';
  String? _activeKey;
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(BouncyPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activeKey != _key) _prepare();
  }

  Future<void> _prepare() async {
    final request = ++_request;
    _activeKey = _key;
    _timer?.cancel();
    _frames = null;
    _error = null;
    try {
      final frames = await _media.prepare(
        photos: widget.photos,
        selections: widget.selections,
        classicLayout: widget.classicLayout,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _frames = frames;
        _index = 0;
      });
      final elapsed = Stopwatch()..start();
      _timer = Timer.periodic(const Duration(milliseconds: 167), (_) {
        if (!mounted || _paused || MediaQuery.of(context).disableAnimations) {
          return;
        }
        final next = (elapsed.elapsedMilliseconds ~/ 167) % frames.length;
        final old = MemoryImage(frames[_index]);
        setState(() => _index = next);
        // Retain one decoded displayed frame, not an entire animation per design.
        if (frames[_index] != old.bytes) unawaited(old.evict());
      });
      if (widget.archive) {
        unawaited(
          _media.export().catchError((Object error) {
            if (mounted) {
              setState(
                () => _error =
                    'Motion export unavailable. Photos are printable. Retry in Soft Copies.',
              );
            }
            return '';
          }),
        );
      }
    } catch (error) {
      if (mounted && request == _request) setState(() => _error = '$error');
    }
  }

  @override
  void dispose() {
    _request++;
    _timer?.cancel();
    final frames = _frames;
    if (frames != null) {
      for (final frame in frames.toSet()) {
        unawaited(MemoryImage(frame).evict());
      }
    }
    if (!widget.archive) {
      _media.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: _frames == null
            ? Center(
                child: _error == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: widget.foregroundColor,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Preparing Bouncy Preview…',
                            style: TextStyle(color: widget.foregroundColor),
                          ),
                        ],
                      )
                    : Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: widget.foregroundColor),
                      ),
              )
            : Image.memory(
                _frames![_index],
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
      ),
      if (_frames != null)
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: widget.foregroundColor),
          onPressed: () => setState(() => _paused = !_paused),
          icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
          label: Text(_paused ? 'Play Bouncy Preview' : 'Pause Bouncy Preview'),
        ),
      if (_frames != null && _error != null)
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(color: widget.foregroundColor),
        ),
    ],
  );
}
