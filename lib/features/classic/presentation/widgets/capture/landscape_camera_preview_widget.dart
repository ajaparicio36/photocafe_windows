import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class LandscapeCameraPreviewWidget extends StatelessWidget {
  final bool isCameraInitialized;
  final CameraController?
  cameraController; // This is now the photo camera controller

  const LandscapeCameraPreviewWidget({
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
            aspectRatio:
                3 /
                4, // Portrait aspect ratio for landscape mode (3:4) - captured photos will be rotated in the frame
            child: ClipRect(
              child: Transform.scale(
                // Scale the photo camera preview to fit the 3:4 aspect ratio
                scale: cameraController!.value.aspectRatio > (3 / 4)
                    ? cameraController!.value.aspectRatio / (3 / 4)
                    : (3 / 4) / cameraController!.value.aspectRatio,
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
      print('Error creating landscape photo camera preview: $e');
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
