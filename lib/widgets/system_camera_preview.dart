import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:photocafe_windows/services/system_camera_service.dart';

/// A reusable widget that displays the system camera preview using
/// [CameraPreview]. Shows connection-state overlays when the camera
/// is not ready.
///
/// This is the fallback equivalent of [CanonLiveViewPreview].
class SystemCameraPreview extends ConsumerWidget {
  final double aspectRatio;

  const SystemCameraPreview({super.key, this.aspectRatio = 4 / 3});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(systemCameraConnectionStateProvider);
    final service = ref.watch(systemCameraServiceProvider);

    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1 — Camera preview (or placeholder)
              _buildPreview(service),

              // Layer 2 — Connection-state overlay
              _buildConnectionOverlay(connectionAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(SystemCameraService service) {
    if (service.isInitialized && service.controller != null) {
      return CameraPreview(service.controller!);
    }

    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text(
              'Camera preview unavailable',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionOverlay(
    AsyncValue<SystemCameraConnectionState> connectionAsync,
  ) {
    final state = connectionAsync.valueOrNull;

    // No overlay when connected
    if (state == null || state == SystemCameraConnectionState.connected) {
      return const SizedBox.shrink();
    }

    final (icon, message) = switch (state) {
      SystemCameraConnectionState.connecting => (
        Icons.camera_alt_outlined,
        'Connecting to camera…',
      ),
      SystemCameraConnectionState.error => (
        Icons.error_outline,
        'Camera connection failed',
      ),
      SystemCameraConnectionState.disconnected => (
        Icons.videocam_off_outlined,
        'Camera disconnected',
      ),
      _ => (Icons.camera_alt_outlined, ''),
    };

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state == SystemCameraConnectionState.connecting)
              const CircularProgressIndicator(color: Colors.white)
            else
              Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
