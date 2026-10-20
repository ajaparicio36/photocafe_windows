# edsdk production integration — 2026-10-20

## Provenance and retained behavior

- Branch: `codex/edsdk-unified`; isolated checkout: `D:/clickclick/.worktrees/edsdk-unified`.
- Parent: `edsdk` at `4db2bad5010c121d9264e14d86395df0843cc332`.
- Ported the Bouncy/media change from `8d0bcbabee41507f80dcc707d5832be0e9f6ed24` using a single no-commit cherry-pick and resolved its real screen/compositor conflicts. The branches share ancestor `1e1a79804e30709b001b09c97e44265f89b282bc`; equivalent existing Keychain optimization/selection fixes stay on the edsdk ancestry. The popup history and its catalog pruning were not merged.
- Selectively ported native-page geometry from the source parent: 1240×1844 sheet, 620×922 tile, origin-aligned frame artwork, no scale/bleed/offset compensation. Existing point-coordinate slots stay intact. Test-print artwork remains edsdk's shipped `frame1.png`.
- `main.dart` stays byte-identical to edsdk, including ordered Canon startup. `BOUNCY_CANON` now defaults to true; a normal release needs no camera define. The temporary webcam override was not imported. Explicit `BOUNCY_QA` fixtures remain available.
- Strict single-command Canon Bouncy capture, bounded live-view clips, atomic still/clip retakes, stable capture identity, cancellation/draining, sample-first exact filters, full-quality still print sources and the six-second silent composition MP4 are retained.
- Complete edsdk frame definitions, assets, pubspec, router and Flipbook feature code are byte-identical to the parent. The only shared video-notifier change removes an unused field. Classic's Portrait/Photobox/Landscape start choices remain available; reset gets the Bouncy discard guard.

## Automated evidence

All commands used FVM Flutter 3.41.1. Dependencies and ignored generated model sources were prepared with `fvm flutter pub get` and `fvm dart run build_runner build --delete-conflicting-outputs`.

| Check | Result |
| --- | --- |
| Parent baseline `fvm flutter test --no-pub` | 14 passed, 22 seconds |
| Parent baseline `fvm flutter analyze --no-pub` | 492 issues, zero errors, 19 warnings |
| Final `fvm flutter test --no-pub` | 36 passed, 21 seconds |
| Final `fvm flutter analyze --no-pub` | 328 issues, zero errors, eight preexisting warnings; analyzer exit is nonzero for legacy findings |
| `fvm dart run custom_lint` | Successful exit; four informational notifier API findings already present in the imported source |
| `fvm flutter build windows --release --no-pub` | Succeeded, 142.7 seconds, normal production defaults |
| `git diff --check` and cached equivalent | Passed |

The final suite includes real ffmpeg software fallback and ffprobe validation of silent six-second output, acquisition/lifecycle/retake fencing, exact filter/compositor pixel comparisons, native PDF page/zero-transform and sheet/tile geometry, and a new all-catalog integration regression. The catalog regression loads every active artwork path and renders all 25 layouts: 12 Portrait, seven Photobox and six Landscape, including the existing rotated/signed slots. This proves availability/renderability; physical print fidelity still requires the coordinated hardware check.

Release executable: `build/windows/x64/runner/Release/photocafe_windows.exe`.
SHA-256: `891CD5D59E9EE4E08DC2660F9403632F3276A9C0CAB04AE038C6EE447FFACC0A`.

Build warnings originate in third-party CMake/plugin code (notably SoLoud conversion/shadow diagnostics). Codegen notes the pinned analyzer's older language support. Neither prevented generation or release compilation. The eight analyzer warnings are unchanged legacy unused imports/variable in Classic start/filter/organize widgets, Flipbook takes, settings, main and webcam service.

## Preservation and handoff

The original popup checkout stays clean. The user's existing edsdk checkout still has its modified CLAUDE.md, untracked docs and both untracked `assets/flipbook/flipbook-frame*.png`. Those PNGs are not referenced by current Flipbook code or pubspec, which use tracked `frame1.png`/`frame2.png`, so no asset copy was needed. All nine stashes remain present; the newest override remains `c15e1a524227db594640b204fb7cbcebac3c4b44` and was inspected but never applied. An exact ignored `.env` copy exists only in this integration checkout and is not staged.

No graphical/native/camera/printer QA, public upload, remote push, default-branch change, merge, PR or cleanup was performed. Lead owns publication and the integration choice. Pause for the user's shared-resource confirmation before interactive QA. Apply the preserved override only for later local QA as requested; keep the production baseline Canon-enabled.
