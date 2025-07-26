import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class TwoByTwoCameraPreviewWidget extends StatelessWidget {
  final bool isCameraInitialized;
  final CameraController?
  cameraController; // This is now the photo camera controller

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
                // Scale the photo camera preview to fit the 5:6 aspect ratio
                scale: cameraController!.value.aspectRatio > (5 / 6)
                    ? cameraController!.value.aspectRatio / (5 / 6)
                    : (5 / 6) / cameraController!.value.aspectRatio,
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
