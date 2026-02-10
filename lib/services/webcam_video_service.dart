import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';

/// Service that manages webcam-based video recording using the `camera` package.
///
/// This is used for recording the VHS-processed companion video during
/// Classic capture sessions. Photos are taken via Canon EDSDK, but the
/// background video is recorded from the system webcam selected in Settings
/// ("Video Recording Camera").
class WebcamVideoService {
  CameraController? _controller;
  bool _isRecording = false;
  String? _tempPath;

  bool get isRecording => _isRecording;
  CameraController? get controller => _controller;

  /// Initialize the webcam controller for the camera matching [cameraName].
  /// If [cameraName] is null, the first available camera is used.
  Future<void> initialize(String? cameraName) async {
    // Dispose any existing controller first
    await dispose();

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No webcam cameras found on this device.');
    }

    // Find the camera by name, or fall back to the first one
    CameraDescription selectedCamera;
    if (cameraName != null) {
      selectedCamera = cameras.firstWhere(
        (cam) => cam.name == cameraName,
        orElse: () {
          print(
            '[WebcamVideoService] Camera "$cameraName" not found, '
            'falling back to: ${cameras.first.name}',
          );
          return cameras.first;
        },
      );
    } else {
      selectedCamera = cameras.first;
    }

    print('[WebcamVideoService] Initializing camera: ${selectedCamera.name}');

    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium, // Good balance of quality and performance
      enableAudio: false, // We don't need audio for VHS video
    );

    await _controller!.initialize();

    // Set up temp directory
    final tempDir = await getTemporaryDirectory();
    _tempPath = p.join(tempDir.path, 'webcam_videos');
    final dir = Directory(_tempPath!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    print('[WebcamVideoService] Camera initialized successfully');
  }

  /// Start recording video from the webcam.
  Future<void> startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Webcam not initialized. Call initialize() first.');
    }

    if (_isRecording) {
      print('[WebcamVideoService] Already recording, ignoring start request');
      return;
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      print('[WebcamVideoService] Video recording started');
    } catch (e) {
      print('[WebcamVideoService] Failed to start recording: $e');
      rethrow;
    }
  }

  /// Stop recording and return the path to the recorded video file.
  /// Returns null if recording was not active.
  Future<String?> stopRecording() async {
    if (_controller == null || !_isRecording) {
      print('[WebcamVideoService] Not recording, nothing to stop');
      _isRecording = false;
      return null;
    }

    try {
      final xFile = await _controller!.stopVideoRecording();
      _isRecording = false;

      // Move the recorded file to our temp directory with a timestamped name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = p.join(_tempPath!, 'webcam_recording_$timestamp.mp4');

      // Copy from the camera's temp location to our managed location
      final sourceFile = File(xFile.path);
      await sourceFile.copy(outputPath);

      // Clean up the original temp file
      try {
        await sourceFile.delete();
      } catch (_) {}

      final outputFile = File(outputPath);
      final fileSize = await outputFile.length();
      print(
        '[WebcamVideoService] Recording stopped. '
        'Saved to: $outputPath ($fileSize bytes)',
      );

      return outputPath;
    } catch (e) {
      _isRecording = false;
      print('[WebcamVideoService] Failed to stop recording: $e');
      rethrow;
    }
  }

  /// Dispose the camera controller and release resources.
  Future<void> dispose() async {
    if (_isRecording) {
      try {
        await _controller?.stopVideoRecording();
      } catch (_) {}
      _isRecording = false;
    }

    await _controller?.dispose();
    _controller = null;
    print('[WebcamVideoService] Disposed');
  }
}

/// Riverpod provider for the [WebcamVideoService] singleton.
final webcamVideoServiceProvider = Provider<WebcamVideoService>((ref) {
  final service = WebcamVideoService();

  // Dispose when the provider is destroyed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
