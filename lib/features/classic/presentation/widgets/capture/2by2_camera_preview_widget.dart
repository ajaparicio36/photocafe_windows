import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class TwoByTwoCameraPreviewWidget extends StatelessWidget {
  final bool isCameraInitialized;
  final RTCVideoRenderer? videoRenderer;

  const TwoByTwoCameraPreviewWidget({
    super.key,
    required this.isCameraInitialized,
    required this.videoRenderer,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized || videoRenderer == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    try {
      return Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: 5 / 6, // Portrait aspect ratio for 2x2 mode (5:6)
            child: ClipRect(
              child: RTCVideoView(
                videoRenderer!,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error creating 2x2 photo camera preview: $e');
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Photo camera preview unavailable',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }
}
