# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Windows-only Flutter kiosk app ("Photo Cafe") for a photobooth/flipbook experience. Drives a Canon DSLR (via the local `canon_edsdk` plugin) for stills and video, plus a separate webcam for a parallel video feature, and prints composites to a connected Windows printer.

## Flutter SDK — FVM

This project is **pinned to Flutter 3.41.1 via FVM** (see `.fvmrc` and `.vscode/settings.json` which points `dart.flutterSdkPath` at `.fvm/versions/3.41.1`). Always invoke Flutter/Dart through FVM so the pinned version is used; a system `flutter` on a different channel will mismatch the lockfile and generated code.

```bash
fvm flutter pub get
fvm flutter run -d windows
fvm flutter build windows
fvm flutter analyze
fvm flutter test
fvm flutter test test/path/to/file_test.dart    # single test file
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run build_runner watch --delete-conflicting-outputs
fvm dart run custom_lint                         # riverpod_lint checks
```

`*.freezed.dart` and `*.g.dart` are gitignored — you must run `build_runner` after pulling or after editing any `@freezed` / `@JsonSerializable` / Riverpod-annotated class, or the build will fail with missing `part` files.

## Local path dependency

`pubspec.yaml` declares `canon_edsdk` as `path: ../canon_edsdk`. The sibling repo must be checked out next to this one (i.e. `D:\clickclick\canon_edsdk`), and Canon's `EDSDK_64/` DLLs (`EDSDK.dll`, `EdsImage.dll`) must be present where the plugin expects them for the Windows build to link and run. See `docs/CANON_SDK_IMPLEMENTATION.md` for the full integration contract.

## Architecture

### Two camera sources, one app

There are **two independent camera pipelines** and they must not be conflated:

1. **Canon EDSDK** (DSLR) — drives live-view preview, still capture, and preview-based video recording for the main photobooth/flipbook flows. Owned by `lib/services/canon_camera_service.dart`, a process-wide singleton wrapping `CanonEdsdk`.
2. **Webcam** (`camera_windows`) — a separate, parallel video feature used inside `photo_notifier`. Do not replace or route it through the Canon service.

`CanonCameraService` centralizes all retry/backoff, auto-reconnect on `CameraDisconnected`, live-view frame caching, and **contingency capture** (when `takePicture` fails after retries, it saves the latest cached live-view frame to disk and returns that path so the downstream frame-building pipeline still receives a valid file). Notifiers and UI must not implement their own retry loops — they call the `*WithRetry` methods on the service and handle only the final result. See `docs/CANON_SDK_IMPLEMENTATION.md` for the full retry matrix and invariants (e.g. never use native `startRecording`/`stopRecording` — they freeze live view; always use the `*WithPreview` variants).

### State management

Riverpod (`flutter_riverpod` + `riverpod_annotation`) with Freezed-backed state classes. The app eagerly initializes its top-level `AsyncNotifier`s in `main.dart#_initializeProviders` **in order**:

1. `photoProvider` (sets up temp dirs)
2. `printerProvider` (applies persisted fullscreen setting via `window_manager`)
3. `videoProvider`
4. `canonCameraServiceProvider.initializeWithRetry()` — non-fatal: failure leaves the service in an error state and the UI shows a retry affordance via the connection-state overlay.

A splash `FutureBuilder` gates `MaterialApp.router` until this completes. Preserve this ordering when adding new top-level providers — later providers may depend on printer settings or temp paths set up earlier.

### Navigation

`go_router` with all routes declared flat in `lib/core/router/router.dart`. Flows are named by feature prefix: `/classic/{start,capture,organize,filter,print}` and `/flipbook/{start,capture,takes,filter,frame,print}`. Several print routes pass `Uint8List` PDF bytes via `state.extra` — the `extra` payload shape is route-specific (sometimes a raw `Uint8List`, sometimes a `Map<String, dynamic>` with `pdfBytes` + `isLandscape`), so check the route definition before pushing.

### Feature layout

```
lib/features/<feature>/
  presentation/{screens,widgets,constants}/    # UI only
  domain/data/{models,providers,constants}/    # Freezed state + AsyncNotifiers
  domain/services/                             # feature-scoped services
```

`classic` and `flipbook` are presentation-only features that consume shared state from `photos`, `print`, and `videos` (which hold the data/notifier layers). `settings` has both layers and also owns the flipbook archive persistence (writes to `getApplicationSupportDirectory()/flipbook_archives/`).

### Windowing

The app forces a **16:9 aspect ratio** with letterboxing. `main.dart` sets the window size to 1280×720 via `window_manager`, locks aspect ratio to `kAspectRatio = 16/9`, and wraps the router in a black-bar `AspectRatio` container. Fullscreen is a persisted user setting applied after `printerProvider` resolves. Do not add top-level widgets that escape this aspect-ratio wrapper.

### Printing

Composites are rendered to PDF via `pdf` + `printing` and dispatched to a Windows printer via `windows_printer`. The selected printer and orientation live in `printerProvider`.

### Misc runtime

- `.env` is loaded via `flutter_dotenv` at startup and is listed as a Flutter asset — do not rename it without updating `pubspec.yaml`.
- Audio cues use `flutter_soloud`, initialized once in `main.dart` before `runApp`.

## Lint

`analysis_options.yaml` layers `package:flutter_lints/flutter.yaml` with the `custom_lint` analyzer plugin enabled, which picks up `riverpod_lint` rules. Surface both with `fvm flutter analyze` and `fvm dart run custom_lint`.
