import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Connection states for the system camera, mirroring [CanonConnectionState].
enum SystemCameraConnectionState { disconnected, connecting, connected, error }

/// A service that uses the `camera` package (system webcams) to capture photos,
/// serving as a fallback when the Canon EDSDK plugin is unavailable.
///
/// Mirrors the subset of [CanonCameraService] API needed by capture screens:
/// - [initializeWithRetry] / [dispose]
/// - [takePictureWithRetry] → returns a file path
/// - Live-view stream via [previewStream] (camera preview frames)
/// - Connection state via [connectionState]
class SystemCameraService {
  CameraController? _controller;
  String? _tempPath;

  // ---------------------------------------------------------------------------
  // Connection state
  // ---------------------------------------------------------------------------
  final StreamController<SystemCameraConnectionState>
  _connectionStateController =
      StreamController<SystemCameraConnectionState>.broadcast();

  Stream<SystemCameraConnectionState> get connectionState =>
      _connectionStateController.stream;

  SystemCameraConnectionState _currentState =
      SystemCameraConnectionState.disconnected;
  SystemCameraConnectionState get currentConnectionState => _currentState;

  void _setConnectionState(SystemCameraConnectionState state) {
    _currentState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  // ---------------------------------------------------------------------------
  // Preview stream (live-view equivalent)
  // ---------------------------------------------------------------------------
  final StreamController<CameraImage> _previewController =
      StreamController<CameraImage>.broadcast();
  StreamSubscription<CameraImage>? _previewSubscription;

  /// The underlying camera controller, exposed for building a [CameraPreview].
  CameraController? get controller => _controller;

  bool get isInitialized =>
      _controller != null && _controller!.value.isInitialized;

  // ---------------------------------------------------------------------------
  // Video recording for flipbook
  // ---------------------------------------------------------------------------
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  // ---------------------------------------------------------------------------
  // Initialize
  // ---------------------------------------------------------------------------

  /// Initialize the system camera by name.
  /// If [cameraName] is null, the first available camera is used.
  Future<void> initializeWithRetry({String? cameraName}) async {
    _setConnectionState(SystemCameraConnectionState.connecting);

    try {
      // Ensure temp dir
      final tempDir = await getTemporaryDirectory();
      _tempPath = p.join(tempDir.path, 'system_camera');
      final dir = Directory(_tempPath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await dispose();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No system cameras found on this device.');
      }

      CameraDescription selectedCamera;
      if (cameraName != null) {
        selectedCamera = cameras.firstWhere(
          (cam) => cam.name == cameraName,
          orElse: () {
            print(
              '[SystemCameraService] Camera "$cameraName" not found, '
              'falling back to: ${cameras.first.name}',
            );
            return cameras.first;
          },
        );
      } else {
        selectedCamera = cameras.first;
      }

      print(
        '[SystemCameraService] Initializing camera: ${selectedCamera.name}',
      );

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      _setConnectionState(SystemCameraConnectionState.connected);
      print('[SystemCameraService] Camera initialized successfully.');
    } catch (e) {
      print('[SystemCameraService] Initialization failed: $e');
      _setConnectionState(SystemCameraConnectionState.error);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Photo capture
  // ---------------------------------------------------------------------------

  /// Capture a photo and return the file path.
  /// Mirrors [CanonCameraService.takePictureWithRetry].
  Future<String> takePictureWithRetry() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception(
        'System camera not initialized. Call initializeWithRetry() first.',
      );
    }

    try {
      final xFile = await _controller!.takePicture();

      // Move to our managed temp directory
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = p.join(_tempPath!, 'system_capture_$timestamp.jpg');

      final sourceFile = File(xFile.path);
      await sourceFile.copy(outputPath);

      // Clean up the original temp file
      try {
        await sourceFile.delete();
      } catch (_) {}

      print('[SystemCameraService] Photo captured: $outputPath');
      return outputPath;
    } catch (e) {
      print('[SystemCameraService] takePicture failed: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Video recording (for flipbook)
  // ---------------------------------------------------------------------------

  /// Start video recording. Mirrors [CanonCameraService.startRecordingWithPreviewRetry].
  Future<void> startRecordingWithPreviewRetry({int fps = 30}) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('System camera not initialized.');
    }

    if (_isRecording) {
      print('[SystemCameraService] Already recording, ignoring start request');
      return;
    }

    await _controller!.startVideoRecording();
    _isRecording = true;
    print('[SystemCameraService] Video recording started');
  }

  /// Stop video recording and return the file path.
  /// Mirrors [CanonCameraService.stopRecordingWithPreviewRetry].
  Future<String?> stopRecordingWithPreviewRetry() async {
    if (_controller == null || !_isRecording) {
      print('[SystemCameraService] Not recording, nothing to stop');
      _isRecording = false;
      return null;
    }

    try {
      final xFile = await _controller!.stopVideoRecording();
      _isRecording = false;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = p.join(_tempPath!, 'system_recording_$timestamp.mp4');

      final sourceFile = File(xFile.path);
      await sourceFile.copy(outputPath);

      try {
        await sourceFile.delete();
      } catch (_) {}

      print('[SystemCameraService] Recording stopped. Saved to: $outputPath');
      return outputPath;
    } catch (e) {
      _isRecording = false;
      print('[SystemCameraService] Failed to stop recording: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  Future<void> dispose() async {
    _previewSubscription?.cancel();
    _previewSubscription = null;

    if (_isRecording) {
      try {
        await _controller?.stopVideoRecording();
      } catch (_) {}
      _isRecording = false;
    }

    await _controller?.dispose();
    _controller = null;

    _setConnectionState(SystemCameraConnectionState.disconnected);
    print('[SystemCameraService] Disposed');
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

/// Singleton provider for [SystemCameraService].
final systemCameraServiceProvider = Provider<SystemCameraService>((ref) {
  final service = SystemCameraService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Stream provider for [SystemCameraConnectionState].
final systemCameraConnectionStateProvider =
    StreamProvider<SystemCameraConnectionState>((ref) {
      final service = ref.watch(systemCameraServiceProvider);
      return service.connectionState;
    });
