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

class ClassicCaptureScreen extends ConsumerStatefulWidget {
  const ClassicCaptureScreen({super.key});

  @override
  ConsumerState<ClassicCaptureScreen> createState() =>
      _ClassicCaptureScreenState();
}

class _ClassicCaptureScreenState extends ConsumerState<ClassicCaptureScreen> {
  CameraController? _cameraController;
  late final photoNotifier = ref.read(photoProvider.notifier);
  bool _isCameraInitialized = false;
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
        print(
          'Capture count from initialized state: ${photoState.captureCount}',
        );

        // Initialize camera once we have a valid state
        await _initializeCamera();

        if (mounted) {
          setState(() {
            _currentPhotoIndex = 0;
          });
        }

        print(
          'Capture screen initialized with capture count: ${photoState.captureCount}',
        );
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
        // Get selected photo camera from settings
        final printerStateAsync = ref.read(printerProvider);
        final selectedPhotoCameraName = printerStateAsync.hasValue
            ? printerStateAsync.value?.photoCameraName
            : null;

        CameraDescription? selectedPhotoCamera;
        if (selectedPhotoCameraName != null) {
          try {
            selectedPhotoCamera = cameras.firstWhere(
              (camera) => camera.name == selectedPhotoCameraName,
            );
          } catch (e) {
            print('Selected photo camera not found, using first available');
          }
        }

        // Fallback to first camera if no selection or camera not found
        selectedPhotoCamera ??= cameras.first;

        // Get capture count to determine resolution preset
        final photoStateAsync = ref.read(photoProvider);
        final captureCount = photoStateAsync.hasValue
            ? (photoStateAsync.value?.captureCount ?? 4)
            : 4;

        print('Initializing camera for capture count: $captureCount');

        // Use higher resolution for 2x2 mode (portrait photos)
        final resolutionPreset = captureCount == 2
            ? ResolutionPreset.high
            : ResolutionPreset.medium;

        // Dispose existing controller if any
        if (_cameraController != null) {
          await _cameraController!.dispose();
        }

        // Initialize photo camera controller with specific settings to avoid conflicts
        _cameraController = CameraController(
          selectedPhotoCamera,
          resolutionPreset,
          enableAudio:
              false, // Disable audio for photo camera to avoid conflicts
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

        print('Photo camera initialized: ${selectedPhotoCamera.name}');
      }
    } catch (e) {
      print('Error initializing photo camera: $e');
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo camera initialization failed: $e'),
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

    final photoState = photoStateAsync.value!;
    print(
      'Starting countdown for capture ${_currentPhotoIndex + 1} of ${photoState.captureCount}',
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

      if (_countdown <= 0) {
        timer.cancel();
        _capturePhoto();
      }
    });
  }

  Future<void> _startVideoRecording() async {
    try {
      // Small delay to ensure photo camera is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

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

      // Try gphoto2 first
      try {
        photoFile = await photoNotifier.captureWithGphoto2();
      } catch (e) {
        print('gphoto2 capture failed: $e');
      }

      // Fallback to camera controller if gphoto2 fails
      if (photoFile == null &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        try {
          final image = await _cameraController!.takePicture();
          photoFile = File(image.path);
        } catch (e) {
          print('Camera controller capture failed: $e');
        }
      }

      if (photoFile != null) {
        final imageBytes = await photoFile.readAsBytes();
        await photoNotifier.addPhoto(imageBytes);
      } else {
        throw Exception('Both camera methods failed');
      }

      // Always read the current capture count from the photo state
      final currentPhotoStateAsync = ref.read(photoProvider);
      if (!currentPhotoStateAsync.hasValue ||
          currentPhotoStateAsync.value == null) {
        throw Exception('Photo state became unavailable');
      }

      final currentPhotoState = currentPhotoStateAsync.value!;
      final captureCount = currentPhotoState.captureCount;
      print('Photo captured: ${_currentPhotoIndex + 1} of $captureCount');

      if (mounted) {
        setState(() {
          _currentPhotoIndex++;
        });
      }

      // Check if we've captured enough photos based on the capture count
      if (_currentPhotoIndex >= captureCount) {
        print('All $captureCount photos captured, stopping video recording');
        // Stop video recording before navigating
        await _stopVideoRecording();

        // All photos captured, navigate to filter screen
        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          context.go('/classic/filter');
        }
      } else {
        // Show success message and prepare for next photo
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Photo ${_currentPhotoIndex} captured! (${captureCount - _currentPhotoIndex} remaining)',
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

  Future<void> _stopVideoRecording() async {
    try {
      await photoNotifier.stopVideoRecording();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop video recording: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Cancel countdown timer
    _countdownTimer?.cancel();
    _countdownTimer = null;

    // Dispose photo camera controller safely
    if (_cameraController != null) {
      _cameraController!
          .dispose()
          .then((_) {
            print('Camera controller disposed successfully');
          })
          .catchError((e) {
            print('Error disposing camera controller: $e');
          });
      _cameraController = null;
    }

    // Ensure video recording is stopped on dispose
    if (_hasStartedSession) {
      photoNotifier.stopVideoRecording().catchError((e) {
        print('Error stopping video recording on dispose: $e');
      });
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview - choose based on capture count
          Consumer(
            builder: (context, ref, child) {
              final photoStateAsync = ref.watch(photoProvider);
              return photoStateAsync.when(
                data: (photoState) {
                  final captureCount = photoState.captureCount;
                  print(
                    'Building camera preview for capture count: $captureCount',
                  );

                  if (captureCount == 2) {
                    // Use 2x2 camera preview for portrait mode (2 photos)
                    return TwoByTwoCameraPreviewWidget(
                      isCameraInitialized: _isCameraInitialized,
                      cameraController: _cameraController,
                    );
                  } else {
                    // Use regular camera preview for 4-photo mode
                    return CameraPreviewWidget(
                      isCameraInitialized: _isCameraInitialized,
                      cameraController: _cameraController,
                    );
                  }
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
