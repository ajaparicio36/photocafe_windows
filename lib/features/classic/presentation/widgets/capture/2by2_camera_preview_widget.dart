import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class TwoByTwoCameraPreviewWidget extends StatelessWidget {
  final bool isCameraInitialized;
  final CameraController? cameraController;

  const TwoByTwoCameraPreviewWidget({
    super.key,
    required this.isCameraInitialized,
    required this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized ||
        cameraController == null ||
        !cameraController!.value.isInitialized) {
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
              child: Transform.scale(
                scale: cameraController!.value.aspectRatio / (5 / 6),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: cameraController!.value.aspectRatio,
                    child: CameraPreview(cameraController!),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error creating 2x2 camera preview: $e');
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Camera preview unavailable',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }
}
