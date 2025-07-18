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
  bool _isRecording = false;
  int _countdown = 7;
  Timer? _countdownTimer;

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

        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.high,
          enableAudio: false,
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
    setState(() {
      _isRecording = true;
      _countdown = 7;
    });

    final videoNotifier = ref.read(videoProvider.notifier);
    await videoNotifier.clearVideo();
    videoNotifier.startVideoRecording();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isRecording = false;
        });
        _setupVideoPreview();
      }
    });
  }

  Future<void> _setupVideoPreview() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Wait for file
    final videoState = ref.read(videoProvider).value;
    if (videoState?.videoPath != null) {
      _videoPlayerController = VideoPlayerController.file(
        File(videoState!.videoPath!),
      );
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setLooping(true);
      await _videoPlayerController!.play();
      setState(() {}); // Rebuild to show video player
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
              '$_countdown',
              style: const TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recording...',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        AspectRatio(
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
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 250,
                height: 80,
                child: OutlinedButton.icon(
                  onPressed: _retakeVideo,
                  icon: const Icon(Icons.replay, size: 32),
                  label: const Text('Retake', style: TextStyle(fontSize: 24)),
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
                width: 250,
                height: 80,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('/flipbook/filter');
                  },
                  icon: const Icon(Icons.check_circle, size: 32),
                  label: const Text('Proceed', style: TextStyle(fontSize: 24)),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_videoPlayerController == null ||
              !_videoPlayerController!.value.isInitialized)
            CameraPreviewWidget(
              isCameraInitialized: _isCameraInitialized,
              cameraController: _cameraController,
            )
          else
            Center(child: _buildVideoPreview()),
          if (_isRecording) _buildRecordingOverlay(),
          if (!_isRecording &&
              (_videoPlayerController == null ||
                  !_videoPlayerController!.value.isInitialized))
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
                onPressed: () => context.go('/flipbook/start'),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          if (videoState.isLoading && !_isRecording)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Processing video...',
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
