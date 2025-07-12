import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  final bool isCameraInitialized;
  final CameraController? cameraController;

  const CameraPreviewWidget({
    super.key,
    required this.isCameraInitialized,
    this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: isCameraInitialized && cameraController != null
                ? CameraPreview(cameraController!)
                : Container(
                    color: Colors.grey[900],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          size: 80,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 4,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Initializing camera...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
