# Canon EDSDK Integration — Implementation Plan

## Overview

Replace the current input-device-based photo and video capture in `photo_notifier` and `video_notifier` with the Canon EDSDK Flutter plugin (`canon_edsdk`). The webcam video capture in `photo_notifier` is **not** affected — only the still-photo and video capture paths are replaced.

---

## Current Architecture

### photo_notifier (Current)
1. A webcam feed is displayed for a separate feature — **leave this untouched**.
2. Photos are captured from an input device (not the webcam).
3. Captured photo file paths are stored and used to build frames (composites/layouts).

### video_notifier (Current)
1. Video is recorded from the same input device.
2. The resulting video file is then split into individual frames for downstream processing.

---

## Target Architecture

### photo_notifier (After)
1. Webcam feed — **unchanged**.
2. Canon EDSDK **Live View** replaces the input device preview.
3. Canon EDSDK **`takePicture()`** replaces the input device photo capture.
4. The returned file path is stored as before and fed into the frame-building pipeline.

### video_notifier (After)
1. Canon EDSDK **Live View** provides the preview during recording.
2. Canon EDSDK **`startRecordingWithPreview()` / `stopRecordingWithPreview()`** (or `takeVideoWithPreview(seconds)`) replaces the input device video capture.
   - **Do NOT use** `startRecording()`/`stopRecording()` or `takeVideo()` — these freeze the live view.
3. The returned MJPEG AVI file path is used to split frames, identical to the current post-processing pipeline.

---

## Retry & Fallback Strategy

All retry logic lives in `CanonCameraService`. Callers (notifiers, UI) do not implement their own retry — they receive either a successful result or a final failure after all retries are exhausted.

### Retry Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `maxAttempts` | 5 | Maximum number of attempts before giving up. |
| `initialDelay` | 1 second | Delay before the first retry. |
| `backoffMultiplier` | 2.0 | Exponential backoff multiplier per attempt. |
| `maxDelay` | 30 seconds | Cap on the backoff delay. |

### Scenarios with Automatic Retry

| Scenario | Trigger | Retry Behaviour | Fallback |
|----------|---------|-----------------|----------|
| **SDK Initialize** | `initialize()` fails or throws | Retry up to `maxAttempts` with exponential backoff. Log each attempt. | After exhausting retries, surface error to UI with a manual "Retry" button. |
| **Camera Discovery** | `getCameras()` returns empty list or throws | Retry up to `maxAttempts` with backoff. Camera may not be powered on yet. | Surface "No camera found" with manual retry option. |
| **Open Session** | `openSession()` fails (DEVICE_BUSY, comm error) | Retry up to `maxAttempts` with backoff. | Surface error to UI; offer manual retry. |
| **Start Live View** | `startLiveView()` fails | Retry up to `maxAttempts` with backoff. | Surface error; photo/video screens show placeholder with retry button. |
| **Take Picture** | `takePicture()` fails (DEVICE_BUSY, AF_FAILED, comm error) | Retry up to 3 attempts with 1s backoff. DEVICE_BUSY also retried at native layer. | **Contingency capture:** grab the latest live view frame, save it as JPEG to disk, return that path instead. See below. |
| **Start Preview Recording** | `startRecordingWithPreview()` fails | Retry up to 3 attempts with 1s backoff. | Surface error to UI; offer manual retry. |
| **Stop Preview Recording** | `stopRecordingWithPreview()` fails | Retry up to 3 attempts with 500ms backoff. | Force-close the AVI writer; return partial file path if available. |
| **Live View Frame Fetch** | `getLiveViewImage()` returns null or throws | Already handled by sequential polling — skips frame and retries on next interval. | No fallback needed; stream self-heals. |
| **Camera Reconnect** | `CameraDisconnected` event received | Automatically attempt `closeSession()` → `getCameras()` → `openSession()` → `startLiveView()` with full retry cycle. | After exhausting retries, surface "Camera disconnected" with manual retry. |

### Contingency Capture (Live View Screenshot Fallback)

When `takePicture()` fails after all retries, the service performs a **contingency capture**:

1. Grab the most recent frame from the live view stream (the service always caches the latest frame).
2. Save the JPEG bytes to the same temp directory used by `takePicture()`, with a timestamped filename (e.g., `contingency_20250101_120000.jpg`).
3. Return the file path to the caller — the frame-building pipeline receives a valid path as usual.
4. Emit a `CameraContingencyCapture(filePath)` event so the UI can show a warning badge (e.g., "Photo captured from preview — lower resolution").

**Trade-offs:**
- Resolution is limited to the live view EVF resolution (typically ~960×640 or ~1920×1280 depending on camera model), much lower than a full shutter capture.
- No RAW file, no full EXIF data.
- Acceptable as a last resort to avoid a completely failed capture in a customer-facing kiosk/booth scenario.

---

## Implementation Steps

### Phase 0 — Dependency & Setup

| # | Task | Details |
|---|------|---------|
| 0.1 | Add `canon_edsdk` to `pubspec.yaml` | Add as a path dependency pointing to `d:\clickclick\canon_edsdk`. |
| 0.2 | Ensure EDSDK DLLs are available | Confirm `EDSDK_64/` folder is at the workspace root with `EDSDK.dll`, `EdsImage.dll`, and `EDSDK.lib`. |
| 0.3 | Verify build | Run `flutter build windows` to confirm the plugin links and DLLs are copied. |

### Phase 1 — Canon Camera Service (Shared Singleton)

| # | Task | Details |
|---|------|---------|
| 1.1 | Create `canon_camera_service.dart` | A singleton (or Riverpod provider) that wraps `CanonEdsdk` and manages lifecycle: `initialize()`, `openSession()`, `dispose()`. This is shared between photo and video notifiers. |
| 1.2 | Implement `_retryWithBackoff()` helper | A private generic method: `Future<T> _retryWithBackoff<T>(Future<T> Function() action, {int maxAttempts, Duration initialDelay, double multiplier, Duration maxDelay})`. Used by all retry-able operations. Logs each attempt and delay. |
| 1.3 | Initialize with retry on app start | Call `canonCameraService.initializeWithRetry()` which internally calls `_retryWithBackoff(() => camera.initialize())` then `_retryWithBackoff(() => camera.getCameras())` then `_retryWithBackoff(() => camera.openSession(index))`. Each step retries independently. |
| 1.4 | Start live view with retry | `startLiveViewWithRetry()` wraps `startLiveView()` in `_retryWithBackoff`. Called after session opens successfully. |
| 1.5 | Cache latest live view frame | Maintain a `Uint8List? _latestFrame` that is updated on every live view stream emission. This is used for contingency capture. |
| 1.6 | Expose live view stream | Provide a `Stream<Uint8List>` from `camera.liveViewStream()` that both notifiers can subscribe to for preview. The service taps the stream to update `_latestFrame`. |
| 1.7 | Handle camera events | Listen to `onCameraEvent` for errors, disconnects, and busy states. Surface these to the UI via a provider or callback. |
| 1.8 | Auto-reconnect on disconnect | When `CameraDisconnected` is received, trigger `_reconnect()` which runs the full init → discover → open → live view cycle with retries. Emit connection state changes so the UI can show "Reconnecting…". |
| 1.9 | Expose connection state | Provide a `Stream<CanonConnectionState>` with values: `disconnected`, `connecting`, `connected`, `reconnecting`, `error`. UI binds to this for status display. |
| 1.10 | Cleanup on app exit | Call `stopLiveView()`, `closeSession()`, `dispose()` on app termination. |

### Phase 2 — photo_notifier Integration

| # | Task | Details |
|---|------|---------|
| 2.1 | Replace input device preview with Live View | Where the current input device preview is displayed, subscribe to the Canon live view stream from the shared service. Display frames using `Image.memory(frame, gaplessPlayback: true)`. |
| 2.2 | Replace photo capture call with retry + fallback | Replace the current input-device capture call with `await canonCameraService.takePictureWithRetry()`. Internally: attempt `takePicture()` up to 3 times with backoff. If all attempts fail, perform contingency capture (save latest live view frame to disk). Return file path in both cases. |
| 2.3 | Store the file path as before | The returned path (from real capture or contingency) is stored in the same state variable / list that the frame-building pipeline reads from. **No changes** to downstream frame building. |
| 2.4 | Handle contingency capture indicator | If the returned path came from a contingency capture, show a subtle warning in the UI (e.g., "Preview quality — camera capture failed"). Listen for `CameraContingencyCapture` events. |
| 2.5 | Handle DEVICE_BUSY | The plugin retries automatically, but add a UI indicator (e.g., brief "Camera busy…" toast) by listening for `CameraDeviceBusy` events. |
| 2.6 | Handle errors | Listen for `CameraError` and `CameraAfFailed` events. Show user-facing error messages. Errors that exhaust retries are surfaced as final failures. |
| 2.7 | Remove old input device photo code | Delete or gate behind a feature flag all input-device-specific photo capture code (but **not** the webcam code). |

### Phase 3 — video_notifier Integration

| # | Task | Details |
|---|------|---------|
| 3.1 | Ensure Live View is active before recording | The preview-based recording requires live view. Confirm `startLiveView()` has been called (the shared service should manage this). If not active, call `startLiveViewWithRetry()`. |
| 3.2 | Replace video capture — manual start/stop with retry | Replace the current input-device recording start with `await canonCameraService.startRecordingWithPreviewRetry(fps: 30)` (retries up to 3 times). Replace stop with `final path = await canonCameraService.stopRecordingWithPreviewRetry()` (retries up to 3 times; on final failure, returns partial AVI path if available). |
| 3.3 | Replace video capture — timed recording | If the current flow records for a fixed duration, use `final path = await canonCameraService.takeVideoWithPreview(seconds, fps: 30)` instead. Wrap in retry at the service level. |
| 3.4 | Use returned AVI path for frame splitting | The returned MJPEG AVI file path replaces the current video file path. Feed it into the existing frame-splitting pipeline. **Verify** the frame splitter handles MJPEG AVI (most FFmpeg-based or OpenCV-based splitters do). |
| 3.5 | Live view stays active during recording | Unlike native recording, preview-based recording does **not** freeze live view. The UI preview widget continues to receive frames — no special handling needed. |
| 3.6 | Listen for recording state events | Subscribe to `CameraPreviewRecordingState` and `CameraPreviewVideoSaved` events for UI feedback (recording indicator, save confirmation). |
| 3.7 | Remove old input device video code | Delete or gate behind a feature flag all input-device-specific video capture code. |

### Phase 4 — UI Updates

| # | Task | Details |
|---|------|---------|
| 4.1 | Live View preview widget | Create a reusable widget (e.g., `CanonLiveViewPreview`) that subscribes to the live view stream and renders frames. Use `Image.memory(frame, gaplessPlayback: true)` for flicker-free display. |
| 4.2 | Connection state indicator | Bind to `CanonCameraService.connectionState` stream. Show "Connecting…", "Reconnecting…", or "Disconnected" overlays on the preview widget as appropriate. |
| 4.3 | Replace input device preview in photo screen | Swap the current input device preview widget with `CanonLiveViewPreview`. Keep the webcam preview widget untouched. |
| 4.4 | Replace input device preview in video screen | Swap the current input device preview widget with `CanonLiveViewPreview`. |
| 4.5 | Recording indicator | Show a recording badge/overlay when `CameraPreviewRecordingState(isRecording: true)` is received. |
| 4.6 | Contingency capture warning | Show a subtle badge/toast when a photo was captured via contingency (live view screenshot) instead of a real shutter capture. |
| 4.7 | Error/disconnect handling UI | Show appropriate messages when `CameraDisconnected` or `CameraError` events are received. During auto-reconnect, show "Reconnecting…". After retries exhausted, offer manual "Retry" button. |

### Phase 5 — Testing & Validation

| # | Task | Details |
|---|------|---------|
| 5.1 | Unit tests — retry logic | Test `_retryWithBackoff` with a mock that fails N times then succeeds. Verify attempt count, delays, and final result. |
| 5.2 | Unit tests — contingency capture | Mock `takePicture()` to always fail. Verify `takePictureWithRetry()` falls back to saving the cached live view frame and returns a valid path. |
| 5.3 | Unit tests — auto-reconnect | Mock `CameraDisconnected` event. Verify the service triggers the reconnect cycle and emits correct connection states. |
| 5.4 | Unit tests — notifiers | Mock `CanonCameraService` in photo_notifier and video_notifier tests. Verify state transitions and path storage for both success and fallback paths. |
| 5.5 | Integration test — photo flow | With a real Canon camera: start live view → take picture → verify path stored → verify frame building works. |
| 5.6 | Integration test — photo fallback | Simulate capture failure (cover lens for AF fail): verify contingency capture fires and returns a live view screenshot path. |
| 5.7 | Integration test — video flow | With a real Canon camera: start live view → start preview recording → stop → verify AVI path → verify frame splitting works. |
| 5.8 | Integration test — reconnect | Disconnect USB cable during live view. Verify auto-reconnect triggers. Reconnect cable. Verify session resumes. |
| 5.9 | Verify webcam is unaffected | Confirm the webcam feed in photo_notifier continues to work independently. |
| 5.10 | Edge cases | Test: camera disconnected mid-capture, camera busy during rapid captures, very long video recordings, app exit during recording, multiple rapid retries. |

---

## File Change Summary

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | **Modify** | Add `canon_edsdk` path dependency. |
| `lib/services/canon_camera_service.dart` | **Create** | Singleton/provider wrapping `CanonEdsdk` with retry logic, auto-reconnect, contingency capture, connection state stream, and latest-frame cache. |
| `lib/models/canon_connection_state.dart` | **Create** | Enum: `disconnected`, `connecting`, `connected`, `reconnecting`, `error`. |
| `lib/widgets/canon_live_view_preview.dart` | **Create** | Reusable widget for displaying Canon live view frames with connection state overlay. |
| `lib/providers/photo_notifier.dart` | **Modify** | Replace input device preview and capture with Canon EDSDK calls (with retry + contingency fallback). Keep webcam code. |
| `lib/providers/video_notifier.dart` | **Modify** | Replace input device recording with `startRecordingWithPreview`/`stopRecordingWithPreview` (with retry). |
| Photo/video screen widgets | **Modify** | Swap input device preview widgets with `CanonLiveViewPreview`. Add connection state and contingency indicators. |
| Old input device service/plugin | **Remove/gate** | Remove or feature-flag the old input device capture code (not webcam). |

---

## Key Constraints

1. **Do NOT touch the webcam feed** in `photo_notifier` — it serves a separate feature.
2. **Do NOT use native recording** (`startRecording`/`stopRecording`/`takeVideo`) — it freezes live view.
3. **Always use preview-based recording** (`startRecordingWithPreview`/`stopRecordingWithPreview`/`takeVideoWithPreview`) for video.
4. **Frame-building and frame-splitting pipelines are unchanged** — only the capture source and file path origin change.
5. The MJPEG AVI output from preview recording must be compatible with the existing frame splitter. Validate this in Phase 5.
6. **All retry logic is centralized** in `CanonCameraService` — notifiers and UI do not implement their own retry loops.
7. **Contingency capture is a last resort** — always attempt real shutter capture first with retries before falling back to a live view screenshot.

---

## Risk & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| MJPEG AVI not compatible with frame splitter | Frame splitting fails | Test early; if needed, add a transcode step (FFmpeg) or adjust the splitter. |
| Live view frame rate too low for video quality | Poor video quality | Tune `fps` parameter; consider camera EVF settings; document minimum acceptable FPS. |
| Camera DEVICE_BUSY during rapid photo captures | Capture delay | Plugin has built-in retry with backoff; service adds Dart-level retry; contingency capture as final fallback. |
| Camera disconnects mid-session | App crash or hang | Auto-reconnect with full retry cycle; `CameraDisconnected` event triggers reconnect; UI shows "Reconnecting…". |
| Two features (photo + video) competing for camera | Conflicts | The shared `CanonCameraService` serializes access; only one operation at a time. |
| Contingency capture low resolution | Poor photo quality | Clearly warn the user; log for diagnostics; contingency is last resort only after all real capture retries fail. |
| Retry storms overwhelming the camera | Camera locks up | Exponential backoff with `maxDelay` cap; max 5 attempts; cooldown between retry cycles. |
| Auto-reconnect loop if camera is permanently removed | Infinite retry | Cap reconnect attempts; after `maxAttempts`, stop and surface manual retry to user. |
