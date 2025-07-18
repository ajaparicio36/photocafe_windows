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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Get selected photo camera from settings
        final printerState = ref.read(printerProvider).value;
        final selectedPhotoCameraName = printerState?.photoCameraName;

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
        final photoState = ref.read(photoProvider).value;
        final captureCount = photoState?.captureCount ?? 4;

        // Use higher resolution for 2x2 mode (portrait photos)
        final resolutionPreset = captureCount == 2
            ? ResolutionPreset.high
            : ResolutionPreset.medium;

        // Initialize photo camera controller with specific settings to avoid conflicts
        _cameraController = CameraController(
          selectedPhotoCamera,
          resolutionPreset,
          enableAudio:
              false, // Disable audio for photo camera to avoid conflicts
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();

        setState(() {
          _isCameraInitialized = true;
        });

        print('Photo camera initialized: ${selectedPhotoCamera.name}');
      }
    } catch (e) {
      print('Error initializing photo camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo camera initialization failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _countdown = 10;
    });

    // Start video recording on first photo
    if (_currentPhotoIndex == 0 && !_hasStartedSession) {
      _startVideoRecording();
      _hasStartedSession = true;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

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
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
      _isCountingDown = false;
    });

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

      final captureCount = ref.read(photoProvider).value?.captureCount ?? 4;

      setState(() {
        _currentPhotoIndex++;
      });

      if (_currentPhotoIndex >= captureCount) {
        // Stop video recording before navigating
        await _stopVideoRecording();

        // All photos captured, navigate to filter screen
        await Future.delayed(const Duration(seconds: 1));
        context.go('/classic/filter');
      } else {
        // Show success message and prepare for next photo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Photo ${_currentPhotoIndex} captured!',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: const TextStyle(fontSize: 16)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isCapturing = false;
      });
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
    _countdownTimer?.cancel();

    // Dispose photo camera controller
    _cameraController?.dispose();

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

                  if (captureCount == 2) {
                    // Use 2x2 camera preview for portrait mode
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
