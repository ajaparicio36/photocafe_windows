# Photo mirroring

Classic (all layouts), Arcade and Keychain support horizontal photo mirroring. Flipbook and the staff frame editor are unchanged.

Staff can enable **Mirror photos by default** in **Frames & modes**. Existing catalogs load with this setting OFF. A new customer session freezes the current default; later staff changes affect the next session. Classic's Frames page and Keychain's design page provide one **Mirror photos** switch for all session photos. Keychain applies it to all four designs. The switch is disabled while final output is prepared and in Keychain's final review (return to Design 4 to change it). Arcade inherits the default and keeps its capture-to-print flow.

Mirroring affects only photo content. Frame artwork, lettering, slot positions, crop geometry, rotation angles, print dimensions and ordering remain unchanged. EXIF orientation is normalized before reflecting the photo, and the authored slot rotation follows the reflection. Classic's still preview and print share the PDF photo transform. Keychain tiles/sheets and Bouncy previews/MP4 exports use the shared source-pixel compositor. Source-coordinate filter effects, including the Photobooth vignette, follow the reflected photo.

Soft copies include the mirrored final framed image/PDF, Keychain tiles/sheet, Bouncy MP4 when enabled, and separate mirrored individual photos. Camera originals remain untouched locally. Individual downloads preserve the existing unfiltered-original semantics; mirroring does not add the customer's composition filter to those downloads. With mirroring OFF, the original attachment paths and bytes are used directly.

Individual mirrored downloads are generated only when Get Soft Copies is requested. One original at a time is decoded, oriented, mirrored and encoded in an isolate at its full oriented dimensions, using the existing full-resolution JPEG quality 92 convention. This adds one JPEG encoding pass and can change the attachment size; it avoids full-size PNG expansion and does no full-resolution encoding when a customer merely toggles the switch. Four fixed destinations inside the owned session directory bound the derivative cache across retries, reorder and retakes. Session reset drains pending work before removing the owned directory. No new dependency or external JPEG tool is required.

The session's composition revision fences PDF continuation, Keychain review/persistence, Bouncy preparation/export, individual download preparation and upload cancellation. Rapid on/off/on changes cannot reuse an earlier orientation. Capture IDs, Bouncy ON/OFF gating, retained live-view budgets and original-photo storage are preserved.

## Verification

Completed with FVM Flutter 3.41.1:

- `fvm flutter test --no-pub --reporter expanded`: 124 tests passed (41 seconds).
- `fvm flutter analyze --no-pub` scoped to the 19 changed Dart files: no errors or warnings; 13 existing info diagnostics remain (legacy prints, unbraced conditions and one deprecated opacity call).
- `fvm dart run custom_lint`: one existing info diagnostic for `PhotoNotifier.savedFramePdfPath`; no new diagnostics.
- `fvm flutter build windows --release --no-pub`: production Canon release built successfully (59.2 seconds).
- `git diff --check`: clean. The two pre-existing generated Windows files retained identical SHA-256 hashes through the build.

Logs: `build/qa/mirror-photos/full-tests.log`, `analyze-final.log`, `custom-lint-final.log`, and `windows-release-build.log` in the same directory.

- Focused pixel tests compare asymmetric sources and artwork, odd center crops, signed/page-clipped rotations, EXIF 6 and every active filter against independently transformed source images.
- PDF pixel tests load the PDFium DLL already produced by the Windows printing plugin. They open no application window and use no printer. On hosts without that built DLL, the PDF-specific test reports its prerequisite; raster and lifecycle tests still run.
- Keychain tests cover preview-cache orientation and all four final tiles/sheet, including the sheet PDF. Bouncy tests encode an actual H.264 MP4 and inspect its decoded first frame, then reject stale export/preparation.
- Download tests verify full oriented dimensions, original-byte preservation, OFF attachment behavior, cached retries, rapid toggles and queued-work reset/drain.
- Headless widget tests exercise the staff default, the Classic customer switch and the single Keychain switch, including keyboard interaction and disabled output state.

Interactive QA remains pending until the user explicitly continues. No browser, camera, printer, device or network upload was used for this implementation verification. Production Canon configuration remains enabled; no webcam override was applied.
