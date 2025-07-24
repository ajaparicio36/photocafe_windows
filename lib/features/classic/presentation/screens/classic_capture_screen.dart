import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/core/colors/colors.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/capture/camera_preview_widget.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/capture/2by2_camera_preview_widget.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/capture/capture_overlay.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/core/services/sound_service.dart';

class ClassicCaptureScreen extends ConsumerStatefulWidget {
  const ClassicCaptureScreen({super.key});

  @override
  ConsumerState<ClassicCaptureScreen> createState() =>
      _ClassicCaptureScreenState();
}

class _ClassicCaptureScreenState extends ConsumerState<ClassicCaptureScreen> {
  CameraController?
  _cameraController; // Video camera for both preview and recording
  late final photoNotifier = ref.read(photoProvider.notifier);
  final SoundService _soundService = SoundService();
  bool _isCameraInitialized = false;
  bool _isCountingDown = false;
  bool _isCapturing = false;
  int _countdown = 10;
  int _currentPhotoIndex = 0;
  Timer? _countdownTimer;
  bool _hasStartedSession = false;
  bool _isDisposed = false;
  bool _isVideoRecording = false;

  @override
  void initState() {
    super.initState();

    // Initialize sound service (this will be fast since SoLoud is already initialized)
    _soundService.initialize();

    // Wait for the widget to be built before initializing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitForValidStateAndInitialize();
    });
  }

  Future<void> _waitForValidStateAndInitialize() async {
    try {
      // Since providers are pre-initialized, we should have valid state immediately
      final photoStateAsync = ref.read(photoProvider);

      if (photoStateAsync.hasValue && photoStateAsync.value != null) {
        final photoState = photoStateAsync.value!;

        // Always set capture count to 4 regardless of layout mode
        // Layout mode only affects how photos are arranged on the final print
        await photoNotifier.setCaptureCount(4);

        print('Capture count set to 4 (layout mode only affects arrangement)');

        // Initialize camera once we have a valid state
        await _initializeCamera();

        if (mounted) {
          setState(() {
            _currentPhotoIndex = 0;
          });
        }

        print('Capture screen initialized - always capturing 4 photos');
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

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Get selected video camera from settings (not photo camera)
        final printerStateAsync = ref.read(printerProvider);
        final selectedVideoCameraName = printerStateAsync.hasValue
            ? printerStateAsync.value?.videoCameraName
            : null;

        CameraDescription? selectedVideoCamera;
        if (selectedVideoCameraName != null) {
          try {
            selectedVideoCamera = cameras.firstWhere(
              (camera) => camera.name == selectedVideoCameraName,
            );
          } catch (e) {
            print('Selected video camera not found, using first available');
          }
        }

        // Fallback to first camera if no selection or camera not found
        selectedVideoCamera ??= cameras.first;

        print('Initializing video camera for preview and recording');

        // Dispose existing controller if any
        if (_cameraController != null) {
          await _cameraController!.dispose();
        }

        // Initialize video camera controller for both preview and recording
        _cameraController = CameraController(
          selectedVideoCamera,
          ResolutionPreset.medium,
          enableAudio: true, // Enable audio for video recording
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        if (!_isDisposed) {
          await _cameraController!.initialize();

          if (mounted && !_isDisposed) {
            setState(() {
              _isCameraInitialized = true;
            });
          }
        }

        print(
          'Video camera initialized for preview: ${selectedVideoCamera.name}',
        );
      }
    } catch (e) {
      print('Error initializing video camera: $e');
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video camera initialization failed: $e'),
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

    // Start video recording on first photo
    if (_currentPhotoIndex == 0 && !_hasStartedSession) {
      _startVideoRecording();
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

  Future<void> _startVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('Camera controller not ready for video recording');
      return;
    }

    try {
      print('Starting video recording with preview camera...');

      // Start video recording directly with the preview camera
      await _cameraController!.startVideoRecording();

      setState(() {
        _isVideoRecording = true;
      });

      // Update photo notifier state to indicate recording
      await photoNotifier.setVideoRecordingState(true);

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
      print('Failed to start video recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video recording failed: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_isVideoRecording || _cameraController == null) {
      print('No video recording to stop');
      return;
    }

    try {
      print('Stopping video recording...');

      // Stop video recording and get the file
      final videoXFile = await _cameraController!.stopVideoRecording();

      setState(() {
        _isVideoRecording = false;
      });

      // Save the video file through the photo notifier
      await photoNotifier.saveVideoFromCapture(videoXFile);

      // Update photo notifier state to indicate recording stopped
      await photoNotifier.setVideoRecordingState(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.stop_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Video recording completed!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error stopping video recording: $e');
      setState(() {
        _isVideoRecording = false;
      });

      // Update photo notifier state
      await photoNotifier.setVideoRecordingState(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop video recording: $e'),
          backgroundColor: AppColors.error,
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
      File? photoFile;

      // Try gphoto2 first for photo capture
      try {
        photoFile = await photoNotifier.captureWithGphoto2();
      } catch (e) {
        print('gphoto2 capture failed: $e');
      }

      // Fallback to video camera controller if gphoto2 fails
      if (photoFile == null &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        try {
          final image = await _cameraController!.takePicture();
          photoFile = File(image.path);
        } catch (e) {
          print('Video camera controller capture failed: $e');
        }
      }

      if (photoFile != null) {
        final imageBytes = await photoFile.readAsBytes();
        await photoNotifier.addPhoto(imageBytes);
      } else {
        throw Exception('Both camera methods failed');
      }

      // Always read the current capture count from the photo state (should be 4)
      final currentPhotoStateAsync = ref.read(photoProvider);
      if (!currentPhotoStateAsync.hasValue ||
          currentPhotoStateAsync.value == null) {
        throw Exception('Photo state became unavailable');
      }

      final currentPhotoState = currentPhotoStateAsync.value!;
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
        await _stopVideoRecording();

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
            ),
          );
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

    // Dispose sound service resources (but not SoLoud instance)
    _soundService.dispose();

    // Stop video recording if active
    if (_isVideoRecording && _cameraController != null) {
      _cameraController!
          .stopVideoRecording()
          .then((videoXFile) {
            // Save video on dispose if possible
            photoNotifier.saveVideoFromCapture(videoXFile).catchError((e) {
              print('Error saving video on dispose: $e');
            });
          })
          .catchError((e) {
            print('Error stopping video recording on dispose: $e');
          });
    }

    // Dispose video camera controller safely
    if (_cameraController != null) {
      _cameraController!
          .dispose()
          .then((_) {
            print('Video camera controller disposed successfully');
          })
          .catchError((e) {
            print('Error disposing video camera controller: $e');
          });
      _cameraController = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview - choose based on the layout mode being used (not capture count)
          Consumer(
            builder: (context, ref, child) {
              final photoStateAsync = ref.watch(photoProvider);
              return photoStateAsync.when(
                data: (photoState) {
                  // Always show regular camera preview since we're capturing 4 photos
                  // The frame choice will determine how they're used
                  print('Building camera preview - always capturing 4 photos');

                  return CameraPreviewWidget(
                    isCameraInitialized: _isCameraInitialized,
                    cameraController: _cameraController,
                  );
                },
                loading: () => Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                error: (error, stack) => Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'Camera preview unavailable',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
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
