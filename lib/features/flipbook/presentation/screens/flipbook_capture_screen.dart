import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';
import 'package:photocafe_windows/core/services/sound_service.dart';
import 'package:photocafe_windows/services/canon_camera_service.dart';
import 'package:photocafe_windows/widgets/canon_live_view_preview.dart';
import 'package:video_player/video_player.dart';

class FlipbookCaptureScreen extends ConsumerStatefulWidget {
  const FlipbookCaptureScreen({super.key});

  @override
  ConsumerState<FlipbookCaptureScreen> createState() =>
      _FlipbookCaptureScreenState();
}

class _FlipbookCaptureScreenState extends ConsumerState<FlipbookCaptureScreen> {
  VideoPlayerController? _videoPlayerController;
  final SoundService _soundService = SoundService();
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _isRecording = false;
  bool _isCountingDown = false;
  bool _isProcessingVideo = false; // Add flag to track video processing

  @override
  void initState() {
    super.initState();

    // Initialize sound service
    _soundService.initialize();

    // Canon EDSDK live view is managed by CanonCameraService (shared singleton).
    // The preview widget subscribes to the live-view stream automatically.
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _countdownTimer?.cancel();

    // Dispose sound service resources
    _soundService.dispose();

    // Canon EDSDK lifecycle is managed by CanonCameraService (shared singleton)

    super.dispose();
  }

  Future<void> _startRecording() async {
    // Start 10-second countdown before recording
    setState(() {
      _countdown = 10;
      _isCountingDown = true;
    });

    // Only clear on the very first take
    final videoState = ref.read(videoProvider).value;
    if (videoState?.videoTakes.isEmpty ?? true) {
      final videoNotifier = ref.read(videoProvider.notifier);
      await videoNotifier.clearVideo();
    }

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
      final canonService = ref.read(canonCameraServiceProvider);
      print('Starting Canon preview-based video recording for flipbook...');

      // Start Canon preview recording (live view stays active)
      await canonService.startRecordingWithPreviewRetry(fps: 30);

      // Start the recording countdown timer (7 seconds)
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

      print('Canon preview recording started for flipbook');
    } catch (e) {
      print('Error starting Canon preview recording for flipbook: $e');
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
      final canonService = ref.read(canonCameraServiceProvider);

      print('Stopping Canon preview recording for flipbook...');

      setState(() {
        _isRecording = false;
        _countdown = 0;
        _isProcessingVideo = true; // Set processing flag
      });

      _countdownTimer?.cancel();
      _countdownTimer = null;

      // Stop Canon preview recording – returns the AVI file path
      final videoPath = await canonService.stopRecordingWithPreviewRetry();

      if (videoPath != null) {
        // Save as a take in the video notifier
        final videoNotifier = ref.read(videoProvider.notifier);
        await videoNotifier.saveVideoTake(videoPath);

        // Set up video preview
        await _setupVideoPreview();
      } else {
        print('Warning: Canon stopRecordingWithPreview returned null');
      }

      setState(() {
        _isProcessingVideo = false; // Clear processing flag
      });
    } catch (e) {
      print('Error stopping Canon preview recording for flipbook: $e');
      setState(() {
        _isRecording = false;
        _isProcessingVideo = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to stop recording: $e')));
    }
  }

  Future<void> _setupVideoPreview() async {
    // Reduced delay - file copy is fast now, just need minimal wait for file system
    await Future.delayed(const Duration(milliseconds: 100));
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

  Future<void> _prepareForNextTake() async {
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;

    // Just reset UI state - keep all video takes intact
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
          width: 180, // Reduced from 200
          height: 180, // Reduced from 200
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
                  fontSize: 50, // Reduced from 60
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6), // Reduced from 8
              Text(
                subText,
                style: const TextStyle(
                  fontSize: 14, // Reduced from 16
                  color: Colors.white,
                ),
              ),
              if (_countdown == 0 && _isRecording) ...[
                const SizedBox(height: 10), // Reduced from 12
                const SizedBox(
                  width: 24, // Reduced from 30
                  height: 24, // Reduced from 30
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5, // Reduced from 3
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
    final currentTakeNumber = videoState.value?.videoTakes.length ?? 0;
    final canRecordMore = currentTakeNumber < 4;
    final showVideoPreview =
        _videoPlayerController?.value.isInitialized == true &&
        !_isRecording &&
        !_isCountingDown &&
        !_isProcessingVideo;
    final busy = _isCountingDown || _isRecording || _isProcessingVideo;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Flipbook',
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    ),
                    Text(
                      'Take ${showVideoPreview ? currentTakeNumber : (currentTakeNumber + 1).clamp(1, 4)} of 4',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (showVideoPreview)
                          VideoPlayer(_videoPlayerController!)
                        else
                          const CanonLiveViewPreview(aspectRatio: 16 / 9),
                        if (busy) _buildRecordingOverlay(),
                        if (videoState.isLoading &&
                            !_isRecording &&
                            !hasVideo &&
                            _countdown == 0)
                          const ColoredBox(
                            color: Colors.black54,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 58,
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(
                          i < currentTakeNumber
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: i < currentTakeNumber
                              ? Colors.greenAccent
                              : Colors.white54,
                        ),
                      ),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _isProcessingVideo
                              ? 'Preparing your take…'
                              : _isCountingDown
                              ? 'Get ready in $_countdown seconds'
                              : _isRecording
                              ? 'Recording…'
                              : showVideoPreview
                              ? 'Review your take'
                              : 'Ready when you are',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    if (showVideoPreview)
                      FilledButton(
                        onPressed: () {
                          if (canRecordMore) {
                            _prepareForNextTake();
                          } else {
                            context.go('/flipbook/takes');
                          }
                        },
                        child: Text(canRecordMore ? 'Next Take' : 'Proceed'),
                      )
                    else
                      FilledButton(
                        onPressed:
                            busy || !canRecordMore || videoState.isLoading
                            ? null
                            : _startRecording,
                        child: Text(
                          currentTakeNumber == 0
                              ? 'Start Recording'
                              : 'Record Take ${currentTakeNumber + 1}',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _isRecording ? (1 - _countdown / 7).clamp(0.0, 1.0) : 0,
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
}
