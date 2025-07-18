import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/capture/camera_preview_widget.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';
import 'package:video_player/video_player.dart';

class FlipbookCaptureScreen extends ConsumerStatefulWidget {
  const FlipbookCaptureScreen({super.key});

  @override
  ConsumerState<FlipbookCaptureScreen> createState() =>
      _FlipbookCaptureScreenState();
}

class _FlipbookCaptureScreenState extends ConsumerState<FlipbookCaptureScreen> {
  CameraController? _cameraController;
  VideoPlayerController? _videoPlayerController;
  bool _isCameraInitialized = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final printerState = ref.read(printerProvider).value;
        final selectedCameraName =
            printerState?.videoCameraName ?? printerState?.photoCameraName;

        CameraDescription? selectedCamera;
        if (selectedCameraName != null) {
          try {
            selectedCamera = cameras.firstWhere(
              (camera) => camera.name == selectedCameraName,
            );
          } catch (e) {
            print('Selected video camera not found, using first available');
          }
        }
        selectedCamera ??= cameras.first;

        // Initialize camera controller for both preview and recording
        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.high,
          enableAudio: true, // Enable audio for video recording
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error initializing camera: $e')));
    }
  }

  Future<void> _startRecording() async {
    if (!_isCameraInitialized || _cameraController == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Camera not initialized')));
      return;
    }

    setState(() {
      _countdown = 7;
      _isRecording = true;
    });

    final videoNotifier = ref.read(videoProvider.notifier);
    await videoNotifier.clearVideo();

    // Start recording using the existing camera controller
    try {
      await _cameraController!.startVideoRecording();
      print('Video recording started with camera controller');

      // Set up automatic stop after 7 seconds
      Timer(const Duration(seconds: 7), () async {
        await _stopRecording();
      });

      // Start countdown timer
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown > 1) {
          if (mounted) {
            setState(() {
              _countdown--;
            });
          }
        } else {
          timer.cancel();
          if (mounted) {
            setState(() {
              _countdown = 0;
            });
          }
        }
      });
    } catch (e) {
      print('Error starting video recording: $e');
      setState(() {
        _isRecording = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start recording: $e')));
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _cameraController == null) return;

    try {
      print('Stopping video recording...');
      final videoXFile = await _cameraController!.stopVideoRecording();

      // Pass the video file to the video notifier
      final videoNotifier = ref.read(videoProvider.notifier);
      await videoNotifier.saveVideoFromCapture(videoXFile);

      setState(() {
        _isRecording = false;
        _countdown = 0;
      });

      _countdownTimer?.cancel();
      _countdownTimer = null;

      // Set up video preview
      await _setupVideoPreview();
    } catch (e) {
      print('Error stopping video recording: $e');
      setState(() {
        _isRecording = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to stop recording: $e')));
    }
  }

  Future<void> _setupVideoPreview() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final videoState = ref.read(videoProvider).value;
    if (videoState?.videoPath != null && mounted) {
      try {
        // Dispose existing controller first
        await _videoPlayerController?.dispose();
        _videoPlayerController = null;

        // Create new controller
        _videoPlayerController = VideoPlayerController.file(
          File(videoState!.videoPath!),
        );

        // Initialize with error handling
        await _videoPlayerController!.initialize();

        // Only proceed if still mounted and initialized successfully
        if (mounted && _videoPlayerController!.value.isInitialized) {
          await _videoPlayerController!.setLooping(true);
          await _videoPlayerController!.play();
          setState(() {});
        }
      } catch (e) {
        print('Error setting up video preview: $e');
        // Clean up on error
        _videoPlayerController?.dispose();
        _videoPlayerController = null;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading video preview: $e')),
          );
        }
      }
    }
  }

  Future<void> _retakeVideo() async {
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;
    final videoNotifier = ref.read(videoProvider.notifier);
    await videoNotifier.clearVideo();
    setState(() {}); // Rebuild to show camera preview
  }

  Widget _buildRecordingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _countdown > 0 ? '$_countdown' : 'Processing...',
              style: const TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _countdown > 0 ? 'Recording...' : 'Almost done...',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            if (_countdown == 0) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: VideoPlayer(_videoPlayerController!),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 40.0,
              vertical: 20.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 200,
                  height: 60,
                  child: OutlinedButton.icon(
                    onPressed: _retakeVideo,
                    icon: const Icon(Icons.replay, size: 24),
                    label: const Text('Retake', style: TextStyle(fontSize: 18)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.go('/flipbook/filter');
                    },
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text(
                      'Proceed',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoProvider);
    final hasVideo = videoState.value?.videoPath != null;

    final showVideoPreview =
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized &&
        !_isRecording;

    final showRecordingOverlay =
        (_isRecording && _countdown > 0) ||
        (hasVideo && !showVideoPreview && _countdown == 0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!showVideoPreview)
            CameraPreviewWidget(
              isCameraInitialized: _isCameraInitialized,
              cameraController: _cameraController,
            )
          else
            Center(child: _buildVideoPreview()),

          if (showRecordingOverlay) _buildRecordingOverlay(),

          if (!showRecordingOverlay && !showVideoPreview && !hasVideo)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 100,
                  child: ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.videocam, size: 40),
                    label: const Text(
                      'Start Recording',
                      style: TextStyle(fontSize: 24),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            top: 60,
            left: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: (showRecordingOverlay || _countdown > 0)
                    ? null
                    : () => context.go('/flipbook/start'),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),

          if (videoState.isLoading &&
              !_isRecording &&
              !hasVideo &&
              _countdown == 0)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Initializing...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
