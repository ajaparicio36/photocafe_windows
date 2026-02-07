import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:canon_edsdk/canon_edsdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:photocafe_windows/models/canon_connection_state.dart';

/// Custom service-level event emitted when a contingency capture (live-view
/// screenshot fallback) is used instead of a real shutter capture.
///
/// This is intentionally NOT a subclass of [CameraEvent] because that is
/// a `sealed` hierarchy owned by the canon_edsdk plugin.
class CameraContingencyCapture {
  /// The absolute file path of the saved contingency image.
  final String filePath;

  const CameraContingencyCapture({required this.filePath});

  @override
  String toString() => 'CameraContingencyCapture(filePath: $filePath)';
}

/// A singleton service that manages the Canon EDSDK camera lifecycle,
/// providing retry logic, auto-reconnect, live view frame caching,
/// contingency capture, and connection state broadcasting.
///
/// Both `photo_notifier` and `video_notifier` share this service.
class CanonCameraService {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  static final CanonCameraService _instance = CanonCameraService._internal();
  factory CanonCameraService() => _instance;
  CanonCameraService._internal();

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------
  final CanonEdsdk _camera = CanonEdsdk();

  /// The underlying plugin instance (exposed read-only for advanced callers).
  CanonEdsdk get camera => _camera;

  /// Cached list of discovered cameras from the most recent discovery.
  List<CameraInfo> _cameras = [];
  List<CameraInfo> get cameras => List.unmodifiable(_cameras);

  /// Index of the currently-opened camera (null if no session).
  int? _openCameraIndex;
  int? get openCameraIndex => _openCameraIndex;

  /// Latest live-view frame, kept up-to-date by the frame tap.
  Uint8List? _latestFrame;
  Uint8List? get latestFrame => _latestFrame;

  /// Temp directory for contingency captures and other artifacts.
  String? _tempPath;

  // ---------------------------------------------------------------------------
  // Retry configuration (plan defaults)
  // ---------------------------------------------------------------------------
  static const int _maxAttempts = 5;
  static const Duration _initialDelay = Duration(seconds: 1);
  static const double _backoffMultiplier = 2.0;
  static const Duration _maxDelay = Duration(seconds: 30);

  // Tighter retry for capture / recording operations
  static const int _captureMaxAttempts = 3;
  static const Duration _captureInitialDelay = Duration(seconds: 1);
  static const Duration _stopRecordingInitialDelay = Duration(
    milliseconds: 500,
  );

  // ---------------------------------------------------------------------------
  // Connection state
  // ---------------------------------------------------------------------------
  final StreamController<CanonConnectionState> _connectionStateController =
      StreamController<CanonConnectionState>.broadcast();

  /// Stream of connection state changes. UI binds to this for status display.
  Stream<CanonConnectionState> get connectionState =>
      _connectionStateController.stream;

  CanonConnectionState _currentState = CanonConnectionState.disconnected;
  CanonConnectionState get currentConnectionState => _currentState;

  void _setConnectionState(CanonConnectionState state) {
    _currentState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  // ---------------------------------------------------------------------------
  // Camera event relay
  // ---------------------------------------------------------------------------
  final StreamController<CameraEvent> _eventController =
      StreamController<CameraEvent>.broadcast();

  /// Stream of native EDSDK camera events.
  Stream<CameraEvent> get onCameraEvent => _eventController.stream;

  // ---------------------------------------------------------------------------
  // Contingency capture notifications
  // ---------------------------------------------------------------------------
  final StreamController<CameraContingencyCapture> _contingencyController =
      StreamController<CameraContingencyCapture>.broadcast();

  /// Stream of contingency capture events (live-view fallback shots).
  /// UI can listen to show a "preview quality" warning badge.
  Stream<CameraContingencyCapture> get onContingencyCapture =>
      _contingencyController.stream;

  StreamSubscription<CameraEvent>? _nativeEventSubscription;

  // ---------------------------------------------------------------------------
  // Live-view stream management
  // ---------------------------------------------------------------------------
  StreamSubscription<Uint8List>? _liveViewSubscription;
  final StreamController<Uint8List> _liveViewBroadcast =
      StreamController<Uint8List>.broadcast();

  /// Broadcast stream of live-view JPEG frames. Multiple consumers
  /// (photo preview, video preview, etc.) can listen simultaneously.
  Stream<Uint8List> get liveViewStream => _liveViewBroadcast.stream;

  bool get isLiveViewActive => _camera.isLiveViewActive;
  bool get isInitialized => _camera.isInitialized;

  // ---------------------------------------------------------------------------
  // Reconnect guard
  // ---------------------------------------------------------------------------
  bool _isReconnecting = false;

  // ---------------------------------------------------------------------------
  // Generic retry helper (§1.2 of plan)
  // ---------------------------------------------------------------------------

  /// Execute [action] with exponential backoff. Logs each attempt.
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() action, {
    int maxAttempts = _maxAttempts,
    Duration initialDelay = _initialDelay,
    double multiplier = _backoffMultiplier,
    Duration maxDelay = _maxDelay,
    String label = 'operation',
  }) async {
    var delay = initialDelay;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (e) {
        print(
          '[CanonCameraService] $label attempt $attempt/$maxAttempts failed: $e',
        );

        if (attempt == maxAttempts) {
          print(
            '[CanonCameraService] $label exhausted all $maxAttempts attempts.',
          );
          rethrow;
        }

        print(
          '[CanonCameraService] Retrying $label in ${delay.inMilliseconds}ms…',
        );
        await Future.delayed(delay);

        // Exponential backoff with cap
        delay = Duration(
          milliseconds: (delay.inMilliseconds * multiplier).round(),
        );
        if (delay > maxDelay) delay = maxDelay;
      }
    }

    // Should never reach here – dart complains without a final return.
    return await action();
  }

  // ---------------------------------------------------------------------------
  // Phase 1.3 – Initialize with retry
  // ---------------------------------------------------------------------------

  /// Full initialization sequence: SDK init → discover cameras → open session
  /// → start live view. Each step retries independently.
  ///
  /// [cameraIndex] selects which discovered camera to open (default 0 = first).
  Future<void> initializeWithRetry({int cameraIndex = 0}) async {
    _setConnectionState(CanonConnectionState.connecting);

    try {
      // Ensure temp dir
      final tempDir = await getTemporaryDirectory();
      _tempPath = p.join(tempDir.path, 'canon_edsdk');
      final dir = Directory(_tempPath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Step 1: Initialize SDK
      await _retryWithBackoff(
        () => _camera.initialize(),
        label: 'SDK initialize',
      );

      // Step 2: Discover cameras
      await _retryWithBackoff(() async {
        _cameras = await _camera.getCameras();
        if (_cameras.isEmpty) {
          throw Exception('No Canon cameras found');
        }
      }, label: 'camera discovery');

      // Step 3: Open session
      final idx = cameraIndex < _cameras.length ? cameraIndex : 0;
      await _retryWithBackoff(
        () => _camera.openSession(idx),
        label: 'open session',
      );
      _openCameraIndex = idx;

      // Step 4: Start live view
      await startLiveViewWithRetry();

      // Step 5: Subscribe to native camera events and relay them
      _subscribeToNativeEvents();

      _setConnectionState(CanonConnectionState.connected);
      print('[CanonCameraService] Fully initialized and connected.');
    } catch (e) {
      print('[CanonCameraService] Initialization failed after retries: $e');
      _setConnectionState(CanonConnectionState.error);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 1.4 – Start live view with retry
  // ---------------------------------------------------------------------------

  /// Starts live view with retry, then begins populating the shared
  /// live-view broadcast stream.
  Future<void> startLiveViewWithRetry() async {
    await _retryWithBackoff(
      () => _camera.startLiveView(),
      label: 'start live view',
    );

    // Tap into the live-view polling stream and relay + cache frames.
    _liveViewSubscription?.cancel();
    _liveViewSubscription = _camera
        .liveViewStream(interval: const Duration(milliseconds: 33))
        .listen(
          (frame) {
            _latestFrame = frame; // § 1.5 – cache latest frame
            if (!_liveViewBroadcast.isClosed) {
              _liveViewBroadcast.add(frame);
            }
          },
          onError: (e) {
            print('[CanonCameraService] Live view stream error: $e');
          },
        );
  }

  // ---------------------------------------------------------------------------
  // Phase 1.7 – Handle camera events
  // ---------------------------------------------------------------------------

  void _subscribeToNativeEvents() {
    _nativeEventSubscription?.cancel();
    _nativeEventSubscription = _camera.onCameraEvent.listen(
      (event) {
        // Relay to consumers
        if (!_eventController.isClosed) {
          _eventController.add(event);
        }

        // § 1.8 – Auto-reconnect on disconnect
        if (event is CameraDisconnected) {
          print(
            '[CanonCameraService] Camera disconnected – starting reconnect.',
          );
          _reconnect();
        }
      },
      onError: (e) {
        print('[CanonCameraService] Native event stream error: $e');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 1.8 – Auto-reconnect
  // ---------------------------------------------------------------------------

  Future<void> _reconnect() async {
    if (_isReconnecting) return;
    _isReconnecting = true;
    _setConnectionState(CanonConnectionState.reconnecting);

    try {
      // Tear down current session gracefully
      _liveViewSubscription?.cancel();
      _liveViewSubscription = null;

      try {
        await _camera.stopLiveView();
      } catch (_) {}
      try {
        await _camera.closeSession();
      } catch (_) {}

      // Re-run full init cycle (SDK is already initialized, but re-discover + open)
      await _retryWithBackoff(() async {
        _cameras = await _camera.getCameras();
        if (_cameras.isEmpty) throw Exception('No cameras found for reconnect');
      }, label: 'reconnect discovery');

      final idx = _openCameraIndex ?? 0;
      final safeIdx = idx < _cameras.length ? idx : 0;

      await _retryWithBackoff(
        () => _camera.openSession(safeIdx),
        label: 'reconnect open session',
      );
      _openCameraIndex = safeIdx;

      await startLiveViewWithRetry();

      _setConnectionState(CanonConnectionState.connected);
      print('[CanonCameraService] Reconnect successful.');
    } catch (e) {
      print('[CanonCameraService] Reconnect failed after retries: $e');
      _setConnectionState(CanonConnectionState.error);
    } finally {
      _isReconnecting = false;
    }
  }

  /// Manual reconnect triggered from the UI (e.g. a "Retry" button).
  Future<void> manualReconnect({int cameraIndex = 0}) async {
    _isReconnecting = false; // reset guard so _reconnect works
    _openCameraIndex = cameraIndex;
    await _reconnect();
  }

  // ---------------------------------------------------------------------------
  // Phase 2.2 – Take picture with retry + contingency capture
  // ---------------------------------------------------------------------------

  /// Attempts to capture a photo via the real shutter. On failure after
  /// retries, falls back to a contingency capture (latest live-view frame
  /// saved to disk).
  ///
  /// Always returns a valid file path.
  Future<String> takePictureWithRetry() async {
    try {
      final path = await _retryWithBackoff(
        () => _camera.takePicture(),
        maxAttempts: _captureMaxAttempts,
        initialDelay: _captureInitialDelay,
        label: 'take picture',
      );
      return path;
    } catch (e) {
      print(
        '[CanonCameraService] takePicture failed after retries, '
        'falling back to contingency capture: $e',
      );
      return _contingencyCapture();
    }
  }

  /// Save the most recent live-view frame as a JPEG file.
  Future<String> _contingencyCapture() async {
    if (_latestFrame == null || _latestFrame!.isEmpty) {
      throw Exception(
        'Contingency capture failed: no live-view frame available.',
      );
    }

    final dir = _tempPath ?? (await getTemporaryDirectory()).path;
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('.', '');
    final filePath = p.join(dir, 'contingency_$timestamp.jpg');

    final file = File(filePath);
    await file.writeAsBytes(_latestFrame!, flush: true);

    print('[CanonCameraService] Contingency capture saved: $filePath');

    // Notify listeners about the contingency capture
    if (!_contingencyController.isClosed) {
      _contingencyController.add(CameraContingencyCapture(filePath: filePath));
    }

    return filePath;
  }

  // ---------------------------------------------------------------------------
  // Phase 3.2 – Preview-based recording with retry
  // ---------------------------------------------------------------------------

  /// Start preview-based video recording with retry.
  Future<void> startRecordingWithPreviewRetry({int fps = 30}) async {
    // Ensure live view is active (§3.1)
    if (!_camera.isLiveViewActive) {
      await startLiveViewWithRetry();
    }

    await _retryWithBackoff(
      () => _camera.startRecordingWithPreview(fps: fps),
      maxAttempts: _captureMaxAttempts,
      initialDelay: _captureInitialDelay,
      label: 'start preview recording',
    );
  }

  /// Stop preview-based video recording with retry. Returns the AVI file path.
  /// On final failure, returns `null`.
  Future<String?> stopRecordingWithPreviewRetry() async {
    try {
      final path = await _retryWithBackoff(
        () => _camera.stopRecordingWithPreview(),
        maxAttempts: _captureMaxAttempts,
        initialDelay: _stopRecordingInitialDelay,
        label: 'stop preview recording',
      );
      return path;
    } catch (e) {
      print(
        '[CanonCameraService] stopRecordingWithPreview failed after retries: $e',
      );
      return null;
    }
  }

  /// Record preview-based video for [seconds] seconds, then stop.
  /// Returns the AVI file path.
  Future<String?> takeVideoWithPreviewRetry(int seconds, {int fps = 30}) async {
    try {
      await startRecordingWithPreviewRetry(fps: fps);
      await Future.delayed(Duration(seconds: seconds));
      return await stopRecordingWithPreviewRetry();
    } catch (e) {
      print('[CanonCameraService] takeVideoWithPreview failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 1.10 – Cleanup
  // ---------------------------------------------------------------------------

  /// Tear down the service: stop live view, close session, terminate SDK.
  Future<void> dispose() async {
    _liveViewSubscription?.cancel();
    _liveViewSubscription = null;

    _nativeEventSubscription?.cancel();
    _nativeEventSubscription = null;

    try {
      if (_camera.isLiveViewActive) {
        await _camera.stopLiveView();
      }
    } catch (e) {
      print('[CanonCameraService] Error stopping live view on dispose: $e');
    }

    try {
      await _camera.closeSession();
    } catch (e) {
      print('[CanonCameraService] Error closing session on dispose: $e');
    }

    try {
      await _camera.dispose();
    } catch (e) {
      print('[CanonCameraService] Error disposing SDK: $e');
    }

    _setConnectionState(CanonConnectionState.disconnected);

    // Don't close the broadcast controllers so that new listeners can
    // still attach after a hot restart. They'll simply receive no events
    // until initializeWithRetry is called again.
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider – exposes the singleton so notifiers and widgets can
// depend on it via ref.read / ref.watch.
// ---------------------------------------------------------------------------

/// A singleton provider for [CanonCameraService].
///
/// Usage:
/// ```dart
/// final service = ref.read(canonCameraServiceProvider);
/// ```
final canonCameraServiceProvider = Provider<CanonCameraService>((ref) {
  final service = CanonCameraService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// A [StreamProvider] exposing the current [CanonConnectionState].
final canonConnectionStateProvider = StreamProvider<CanonConnectionState>((
  ref,
) {
  final service = ref.watch(canonCameraServiceProvider);
  return service.connectionState;
});

/// A [StreamProvider] exposing the live-view frame stream.
final canonLiveViewStreamProvider = StreamProvider<Uint8List>((ref) {
  final service = ref.watch(canonCameraServiceProvider);
  return service.liveViewStream;
});

/// A [StreamProvider] exposing native camera events.
final canonCameraEventProvider = StreamProvider<CameraEvent>((ref) {
  final service = ref.watch(canonCameraServiceProvider);
  return service.onCameraEvent;
});

/// A [StreamProvider] exposing contingency capture events.
final canonContingencyCaptureProvider =
    StreamProvider<CameraContingencyCapture>((ref) {
      final service = ref.watch(canonCameraServiceProvider);
      return service.onContingencyCapture;
    });
