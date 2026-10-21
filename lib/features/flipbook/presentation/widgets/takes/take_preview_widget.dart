import 'package:photocafe_windows/widgets/event_design.dart';
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
  String? _error;

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
        if (mounted) setState(() => _error = 'This take is unavailable.');
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
      if (mounted) setState(() => _error = 'This take could not play.');
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
  Widget build(BuildContext context) => Semantics(
    label: 'Take ${widget.takeNumber}',
    selected: widget.isSelected,
    button: true,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected ? const Color(0xffc32121) : Colors.white,
              width: widget.isSelected ? 5 : 2,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(7),
                child: _isInitialized && _controller != null
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    : Center(
                        child: _error == null
                            ? const CircularProgressIndicator()
                            : Text(
                                _error!,
                                style: const TextStyle(color: EventDesign.red),
                              ),
                      ),
              ),
              Positioned(
                top: 10,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: EventDesign.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.takeNumber}',
                    style: const TextStyle(
                      fontFamily: EventDesign.body,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              if (widget.isSelected)
                const Positioned(
                  top: 12,
                  right: 16,
                  child: Icon(
                    Icons.check_circle,
                    color: EventDesign.red,
                    size: 30,
                  ),
                ),
              if (!widget.isSelected && _isInitialized)
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
