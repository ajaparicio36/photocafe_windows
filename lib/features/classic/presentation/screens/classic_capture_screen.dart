import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/core/colors/colors.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/capture/capture_overlay.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/core/services/sound_service.dart';
import 'package:photocafe_windows/services/canon_camera_service.dart';
import 'package:photocafe_windows/widgets/canon_live_view_preview.dart';

class ClassicCaptureScreen extends ConsumerStatefulWidget {
  const ClassicCaptureScreen({super.key});

  @override
  ConsumerState<ClassicCaptureScreen> createState() =>
      _ClassicCaptureScreenState();
}

class _ClassicCaptureScreenState extends ConsumerState<ClassicCaptureScreen> {
  late final photoNotifier = ref.read(photoProvider.notifier);
  final SoundService _soundService = SoundService();
  bool _isCountingDown = false;
  bool _isCapturing = false;
  int _countdown = 10;
  int _currentPhotoIndex = 0;
  Timer? _countdownTimer;
  bool _hasStartedSession = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    // Initialize sound service
    _soundService.initialize();

    // Wait for the widget to be built before initializing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitForValidStateAndInitialize();
    });
  }

  Future<void> _waitForValidStateAndInitialize() async {
    try {
      final photoStateAsync = ref.read(photoProvider);

      if (photoStateAsync.hasValue && photoStateAsync.value != null) {
        // Always set capture count to 4 regardless of layout mode
        await photoNotifier.setCaptureCount(4);

        print('Capture count set to 4 (layout mode only affects arrangement)');

        // Canon EDSDK live view is managed by CanonCameraService (shared singleton).
        // The preview widget subscribes to the live-view stream automatically.

        if (mounted) {
          setState(() {
            _currentPhotoIndex = 0;
          });
        }

        print('Classic capture screen initialized - always capturing 4 photos');
        print('Starting with photo index: $_currentPhotoIndex');
        return;
      } else {
        throw Exception(
          'Photo provider state is not available even after app initialization',
        );
      }
    } catch (e, stackTrace) {
      print('Error during capture screen initialization: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize photo session: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _startCountdown() {
    if (_isDisposed) return;

    // Ensure we have a valid photo state before starting countdown
    final photoStateAsync = ref.read(photoProvider);
    if (!photoStateAsync.hasValue || photoStateAsync.value == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo session not initialized properly'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    print(
      'Starting countdown for capture ${_currentPhotoIndex + 1} of 4 (always capture 4)',
    );

    if (mounted) {
      setState(() {
        _isCountingDown = true;
        _countdown = 10;
      });
    }

    // Start video recording in photo notifier on first photo
    if (_currentPhotoIndex == 0 && !_hasStartedSession) {
      _startVideoRecordingInNotifier();
      _hasStartedSession = true;
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (mounted) {
        setState(() {
          _countdown--;
        });
      }

      // Play countdown tick sound
      if (_countdown > 0) {
        _soundService.playCountdownTick();
      } else {
        // Play shutter sound when countdown reaches zero
        _soundService.playShutterSound();
        timer.cancel();
        _capturePhoto();
      }
    });
  }

  Future<void> _startVideoRecordingInNotifier() async {
    try {
      print('Starting video recording in photo notifier...');
      await photoNotifier.startVideoRecording();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.videocam, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Video recording started!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Failed to start video recording in notifier: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video recording failed: $e'),
          backgroundColor: AppColors.lightCard,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || _isDisposed) return;

    if (mounted) {
      setState(() {
        _isCapturing = true;
        _isCountingDown = false;
      });
    }

    try {
      // Get the Canon camera service
      final canonService = ref.read(canonCameraServiceProvider);

      // Get the current layout mode and landscape orientation
      final printerStateAsync = ref.read(printerProvider);
      final layoutMode = printerStateAsync.hasValue
          ? printerStateAsync.value?.layoutMode ?? 4
          : 4;
      final isLandscape = printerStateAsync.hasValue
          ? printerStateAsync.value?.isLandscape ?? false
          : false;

      // Capture photo using Canon EDSDK (with retry + contingency fallback)
      final filePath = await canonService.takePictureWithRetry();

      // Add the Canon photo to the notifier's state
      await photoNotifier.addPhotoFromFile(
        filePath,
        layoutMode: layoutMode,
        isLandscape: isLandscape,
      );

      // Always read the current capture count from the photo state (should be 4)
      final currentPhotoStateAsync = ref.read(photoProvider);
      if (!currentPhotoStateAsync.hasValue ||
          currentPhotoStateAsync.value == null) {
        throw Exception('Photo state became unavailable');
      }

      final captureCount = 4; // Always capture 4 photos
      print('Photo captured: ${_currentPhotoIndex + 1} of $captureCount');

      if (mounted) {
        setState(() {
          _currentPhotoIndex++;
        });
      }

      // Check if we've captured 4 photos
      if (_currentPhotoIndex >= 4) {
        print('All 4 photos captured, stopping video recording');
        await photoNotifier.stopVideoRecording();

        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          context.go('/classic/filter');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Photo ${_currentPhotoIndex} captured! (${4 - _currentPhotoIndex} remaining)',
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );

          // Automatically start countdown for the next photo after a short delay
          await Future.delayed(const Duration(seconds: 2));
          if (mounted && !_isDisposed && _currentPhotoIndex < 4) {
            _startCountdown();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(fontSize: 16)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Cancel countdown timer
    _countdownTimer?.cancel();
    _countdownTimer = null;

    // Dispose sound service resources
    _soundService.dispose();

    // Canon EDSDK lifecycle is managed by CanonCameraService (shared singleton)
    // — nothing to dispose here.

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Canon EDSDK live-view preview — aspect ratio adapts to layout mode
          Consumer(
            builder: (context, ref, child) {
              final printerStateAsync = ref.watch(printerProvider);

              return printerStateAsync.when(
                data: (printerState) {
                  // Choose aspect ratio based on layout mode
                  double previewAspectRatio;
                  if (printerState.layoutMode == 2) {
                    previewAspectRatio = 5 / 6; // 2x2 portrait
                  } else if (printerState.layoutMode == 4 &&
                      printerState.isLandscape) {
                    previewAspectRatio = 3 / 4; // 4x4 landscape
                  } else {
                    previewAspectRatio = 4 / 3; // 4x4 normal
                  }

                  return CanonLiveViewPreview(aspectRatio: previewAspectRatio);
                },
                loading: () => Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                error: (error, stack) {
                  return const CanonLiveViewPreview(aspectRatio: 4 / 3);
                },
              );
            },
          ),

          // Top back button
          Positioned(
            top: 60,
            left: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: () => context.go('/classic/start'),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),

          // Capture overlay
          CaptureOverlay(
            currentPhotoIndex: _currentPhotoIndex,
            isCountingDown: _isCountingDown,
            isCapturing: _isCapturing,
            countdown: _countdown,
            onStartCountdown: _startCountdown,
          ),
        ],
      ),
    );
  }

  double min(double a, double b) => a < b ? a : b;
}
