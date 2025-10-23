import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class TakePreviewWidget extends StatefulWidget {
  final String videoPath;
  final int takeNumber;
  final bool isSelected;
  final VoidCallback onTap;

  const TakePreviewWidget({
    super.key,
    required this.videoPath,
    required this.takeNumber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<TakePreviewWidget> createState() => _TakePreviewWidgetState();
}

class _TakePreviewWidgetState extends State<TakePreviewWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(TakePreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _disposeController();
      _initializeVideo();
    }

    // Auto-play when selected
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller?.play();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller?.pause();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      final videoFile = File(widget.videoPath);
      if (!await videoFile.exists()) {
        print('Video file does not exist: ${widget.videoPath}');
        return;
      }

      _controller = VideoPlayerController.file(videoFile);
      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        _controller!.setLooping(true);

        // Auto-play if this take is selected
        if (widget.isSelected) {
          _controller!.play();
        }
      }
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? Colors.yellow
                : Colors.white.withOpacity(0.5),
            width: widget.isSelected ? 4 : 2,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video preview
              if (_isInitialized && _controller != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),

              // Take number badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Take ${widget.takeNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Selected indicator
              if (widget.isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),

              // Play icon overlay when not selected
              if (!widget.isSelected)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
