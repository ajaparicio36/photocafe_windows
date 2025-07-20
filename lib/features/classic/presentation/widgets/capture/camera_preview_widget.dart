import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewWidget extends StatelessWidget {
  final bool isCameraInitialized;
  final CameraController? cameraController;

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
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: cameraController!.value.aspectRatio * 400,
                  height: 400,
                  child: CameraPreview(cameraController!),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error creating camera preview: $e');
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
