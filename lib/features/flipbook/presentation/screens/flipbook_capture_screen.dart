import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/core/services/sound_service.dart';
import 'package:video_player/video_player.dart';

class FlipbookCaptureScreen extends ConsumerStatefulWidget {
  const FlipbookCaptureScreen({super.key});

  @override
  ConsumerState<FlipbookCaptureScreen> createState() =>
      _FlipbookCaptureScreenState();
}

class _FlipbookCaptureScreenState extends ConsumerState<FlipbookCaptureScreen> {
  RTCVideoRenderer? _photoVideoRenderer;
  MediaStream? _photoStream;
  VideoPlayerController? _videoPlayerController;
  final SoundService _soundService = SoundService();
  bool _isCameraInitialized = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _isRecording = false;
  bool _isCountingDown = false;

  @override
  void initState() {
    super.initState();

    // Initialize sound service
    _soundService.initialize();

    _initializePhotoCamera();
  }

  @override
  void dispose() {
    _photoStream?.dispose();
    _photoVideoRenderer?.dispose();
    _videoPlayerController?.dispose();
    _countdownTimer?.cancel();

    // Dispose sound service resources
    _soundService.dispose();

    super.dispose();
  }

  Future<void> _initializePhotoCamera() async {
    try {
      // Initialize video renderer
      _photoVideoRenderer = RTCVideoRenderer();
      await _photoVideoRenderer!.initialize();

      final printerState = ref.read(printerProvider).value;
      final selectedPhotoCameraDeviceId = printerState?.photoCameraName;

      print(
        'Initializing photo camera for flipbook preview and video recording',
      );

      // Get user media constraints
      final Map<String, dynamic> constraints = {
        'video': selectedPhotoCameraDeviceId != null
            ? {
                'deviceId': selectedPhotoCameraDeviceId,
                'width': {'ideal': 1920},
                'height': {'ideal': 1080},
              }
            : {
                'width': {'ideal': 1920},
                'height': {'ideal': 1080},
              },
        'audio': true, // Enable audio for video recording
      };

      _photoStream = await navigator.mediaDevices.getUserMedia(constraints);
      _photoVideoRenderer!.srcObject = _photoStream;

      setState(() {
        _isCameraInitialized = true;
      });

      print(
        'Photo camera initialized for flipbook preview and video recording',
      );
    } catch (e) {
      print('Error initializing photo camera for flipbook: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error initializing camera: $e')));
    }
  }

  Future<void> _startRecording() async {
    if (!_isCameraInitialized || _photoVideoRenderer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Camera not initialized')));
      return;
    }

    // Start 10-second countdown before recording
    setState(() {
      _countdown = 10;
      _isCountingDown = true;
    });

    final videoNotifier = ref.read(videoProvider.notifier);
    await videoNotifier.clearVideo();

    // Start pre-recording countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        // Play countdown tick sound
        _soundService.playCountdownTick();
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        // Play shutter sound when countdown reaches zero
        _soundService.playShutterSound();
        timer.cancel();
        _startVideoRecording();
      }
    });
  }

  Future<void> _startVideoRecording() async {
    setState(() {
      _countdown = 7;
      _isRecording = true;
      _isCountingDown = false;
    });

    try {
      print('Starting video recording with MediaRecorder...');

      if (_photoStream == null) {
        throw Exception('Photo stream not available for recording');
      }

      // Start recording using VideoNotifier with MediaRecorder
      final videoNotifier = ref.read(videoProvider.notifier);
      await videoNotifier.startRecording(_photoStream!);

      // Start the recording countdown timer
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
          // Stop recording after 7 seconds
          _stopVideoRecording();
        }
      });

      print('Video recording started with MediaRecorder');
    } catch (e) {
      print('Error starting video recording: $e');
      setState(() {
        _isRecording = false;
        _isCountingDown = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start recording: $e')));
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_isRecording) return;

    try {
      print('Stopping video recording...');

      final videoNotifier = ref.read(videoProvider.notifier);
      await videoNotifier.stopRecording();

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

        final videoFile = File(videoState!.videoPath!);

        // Verify the file exists and has content
        if (!await videoFile.exists()) {
          throw Exception('Video file does not exist: ${videoState.videoPath}');
        }

        final fileSize = await videoFile.length();
        if (fileSize < 1024) {
          throw Exception('Video file is too small: $fileSize bytes');
        }

        print('Setting up video preview for: ${videoState.videoPath}');
        print('Video file size: $fileSize bytes');

        // Create new controller
        _videoPlayerController = VideoPlayerController.file(videoFile);

        // Initialize with error handling
        await _videoPlayerController!.initialize();

        // Only proceed if still mounted and initialized successfully
        if (mounted && _videoPlayerController!.value.isInitialized) {
          await _videoPlayerController!.setLooping(true);
          await _videoPlayerController!.play();
          setState(() {});
          print('Video preview setup successfully');
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

  Widget _buildVideoPreview() {
    return Column(
      children: [
        Expanded(
          flex: 4, // Increased from 3 to give more space
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
              vertical: 10.0, // Reduced from 20.0
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 180, // Reduced from 200
                  height: 50, // Reduced from 60
                  child: OutlinedButton.icon(
                    onPressed: _retakeVideo,
                    icon: const Icon(Icons.replay, size: 20), // Reduced from 24
                    label: const Text(
                      'Retake',
                      style: TextStyle(fontSize: 16),
                    ), // Reduced from 18
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
                  width: 180, // Reduced from 200
                  height: 50, // Reduced from 60
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.go('/flipbook/filter');
                    },
                    icon: const Icon(
                      Icons.check_circle,
                      size: 20,
                    ), // Reduced from 24
                    label: const Text(
                      'Proceed',
                      style: TextStyle(fontSize: 16), // Reduced from 18
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

  Future<void> _retakeVideo() async {
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;
    final videoNotifier = ref.read(videoProvider.notifier);
    await videoNotifier.clearVideo();

    // Reset countdown states
    setState(() {
      _isCountingDown = false;
      _isRecording = false;
      _countdown = 0;
    });

    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Widget _buildRecordingOverlay() {
    String overlayText;
    String subText;

    if (_isCountingDown) {
      overlayText = '$_countdown';
      subText = 'Get Ready!';
    } else if (_isRecording) {
      overlayText = _countdown > 0 ? '$_countdown' : 'Processing...';
      subText = _countdown > 0 ? 'Recording...' : 'Almost done...';
    } else {
      overlayText = 'Processing...';
      subText = 'Almost done...';
    }

    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.8),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                overlayText,
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subText,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              if (_countdown == 0 && _isRecording) ...[
                const SizedBox(height: 12),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoProvider);
    final hasVideo = videoState.value?.videoPath != null;

    final showVideoPreview =
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized &&
        !_isRecording &&
        !_isCountingDown;

    final showCountdownOverlay =
        _isCountingDown ||
        (_isRecording && _countdown >= 0) ||
        (hasVideo && !showVideoPreview && _countdown == 0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo camera preview for flipbook
          if (!showVideoPreview)
            Container(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 10, // Flipbook aspect ratio
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: _isCameraInitialized && _photoVideoRenderer != null
                          ? RTCVideoView(
                              _photoVideoRenderer!,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            )
          else
            Center(child: _buildVideoPreview()),

          if (showCountdownOverlay) _buildRecordingOverlay(),

          // Start recording button
          if (!showCountdownOverlay && !showVideoPreview && !hasVideo)
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

          // Back button
          Positioned(
            top: 60,
            left: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: (_isCountingDown || _isRecording || _countdown > 0)
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

          // Loading indicator
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
