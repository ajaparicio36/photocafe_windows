import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:photocafe_windows/models/canon_connection_state.dart';
import 'package:photocafe_windows/services/canon_camera_service.dart';

/// A reusable widget that subscribes to the Canon EDSDK live-view stream
/// and renders frames. Displays connection-state overlays when the camera
/// is not fully connected.
///
/// Usage:
/// ```dart
/// CanonLiveViewPreview(aspectRatio: 4 / 3)
/// ```
class CanonLiveViewPreview extends ConsumerWidget {
  /// The desired aspect ratio for the preview area (default 4:3).
  final double aspectRatio;

  const CanonLiveViewPreview({super.key, this.aspectRatio = 4 / 3});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(canonConnectionStateProvider);
    final frameAsync = ref.watch(canonLiveViewStreamProvider);

    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1 — Live-view frame (or placeholder)
              _buildFrame(frameAsync),

              // Layer 2 — Connection-state overlay
              _buildConnectionOverlay(connectionAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrame(AsyncValue<Uint8List> frameAsync) {
    return frameAsync.when(
      data: (frame) =>
          Image.memory(frame, gaplessPlayback: true, fit: BoxFit.cover),
      loading: () => Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      error: (_, __) => Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off, color: Colors.white54, size: 48),
              SizedBox(height: 12),
              Text(
                'Live view unavailable',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionOverlay(
    AsyncValue<CanonConnectionState> connectionAsync,
  ) {
    final state = connectionAsync.valueOrNull;

    // No overlay when connected
    if (state == null || state == CanonConnectionState.connected) {
      return const SizedBox.shrink();
    }

    final (icon, message) = switch (state) {
      CanonConnectionState.connecting => (
        Icons.camera_alt_outlined,
        'Connecting to camera…',
      ),
      CanonConnectionState.reconnecting => (Icons.sync, 'Reconnecting…'),
      CanonConnectionState.error => (
        Icons.error_outline,
        'Camera connection failed',
      ),
      CanonConnectionState.disconnected => (
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
            if (state == CanonConnectionState.connecting ||
                state == CanonConnectionState.reconnecting)
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
