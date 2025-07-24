import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewWidget extends StatelessWidget {
  final bool isCameraInitialized;
  final CameraController?
  cameraController; // This is now the video camera controller

  const CameraPreviewWidget({
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
            aspectRatio: 4 / 3, // Landscape aspect ratio for 4x4 mode (4:3)
            child: ClipRect(
              child: Transform.scale(
                // Scale the video camera preview to fit the 4:3 aspect ratio
                scale: cameraController!.value.aspectRatio > (4 / 3)
                    ? cameraController!.value.aspectRatio / (4 / 3)
                    : (4 / 3) / cameraController!.value.aspectRatio,
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
      print('Error creating video camera preview: $e');
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Video camera preview unavailable',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }
}
