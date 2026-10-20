# Staff frame catalog implementation

Feature branch: `codex/frame-editor-modes`, based on production `master` at
`9122c57dfed078004789ac42df908fe3cda308b2`. The existing Canon EDSDK production
camera, capture aspect ratio, print geometry, and Bouncy completion rules remain
the baseline. Interactive camera and desktop QA awaits user continuation.
Physical printing and public-upload QA were not performed and are not requested
for this feature checkpoint.

## Staff workflow and event choices

Settings opens a staff frame catalog. Staff import PNG artwork, create or edit a
template, and move, resize, rotate, and assign photo slots on its logical canvas.
Editing uses a local draft. Save validates and creates an immutable revision;
Cancel leaves the published template unchanged. New templates start disabled
and become customer choices through their separate Enabled control.

Classic, Keychain, and Flipbook have independent persisted product switches.
Classic Portrait, Landscape, and Photobox have separate persisted switches;
turning Classic off and back on preserves those choices. Frame visibility is
also persisted. Rejected changes display a staff-readable error and retain the
previous catalog. At least one product must remain usable; every enabled product
and enabled Classic variant needs at least one compatible enabled frame.

Production defaults enable all three products and all three Classic variants.
The original 25 active Classic templates and six Flipbook templates stay enabled.
Ten historical inactive Classic definitions remain available to staff, disabled.
Keychain shares Classic portrait artwork; Landscape and Photobox templates are
excluded from its customer picker because they have different physical contracts.

Customer home and Classic start choices use the persisted configuration. Direct
navigation to disabled products redirects home, and direct continuation without
an accepted session redirects to its start screen. Settings stays reachable.
Accepting a session freezes a catalog snapshot and immutable artwork references.
Later staff edits or visibility changes affect subsequent sessions; the accepted
session can finish. Returning home clears its pinned renderer definitions.

## Coordinates and output

Artwork pixel dimensions and placement coordinates are separate. Classic uses
the existing 297.6 × 442.56 PDF-point page, equivalent to the native 1240 × 1844
raster at 300 DPI. Keychain reuses the same composition at 620 × 922 per tile and
1240 × 1844 for the four-design sheet. No bleed or printer compensation is added.
Signed positions and centered rotations remain supported, including the shipped
Landscape slots at top −10 and rotation −90 degrees. Source photo indices are
explicit integers 0–3, including repeated photos.

All output paths now cover-crop into the full authored rectangle, rotate about
its center, and clip at the page boundary. The previous raster path shrank an
off-page slot before cropping and cropped expanded rotations back into the
unrotated rectangle. Correcting that intentionally changes Landscape motion
preview edges and the old raster source crop in eight Portrait and five Photobox
templates. The eight Portrait IDs are `4by4_frame_three`, `4by4_frame_twelve`,
`4by4_frame_thirteen`, `4by4_frame_fourteen`, `4by4_frame_fifteen`,
`4by4_frame_sixteen`, `4by4_frame_seventeen`, and `4by4_frame_twenty_one`.
The five Photobox IDs are `2by2_frame_one`, `2by2_frame_four`,
`2by2_frame_five`, `2by2_frame_six`, and `2by2_frame_seven`.
Their geometry and native Classic PDF output remain unchanged; the corresponding
Keychain raster crop now agrees with that print/editor contract. This correction
was accepted after its existing-frame impact was explained. The native page and
sheet dimensions stay unchanged. Four Portrait and two Photobox templates that
remain inside the page retain exact production raster fingerprints.

Flipbook keeps its 432 × 288 logical template and existing two half-height
leaves per sheet, 50 sequence images across 25 pages. Every slot uses source
index 0 to mean the current leaf's sequence image, rather than the first image
of the sequence. Multiple slots repeat that current image. Rotation is centered
in logical coordinates and conjugated by the existing vertical half-height
transform; original zero-rotation physical cover cropping is preserved.

Classic preview/PDF (both PDF entry points), Keychain preview/final isolate,
Bouncy previews/archive preparation, Flipbook preview/PDF, and printer calibration
artwork loading use `FrameArtworkLoader`. Isolate work receives loaded artwork
bytes and explicit slot indices. The alternate Classic PDF method previously
painted a green background and discarded template rotation; it now uses white
and combines template rotation with optional per-photo rotation consistently.
Printer calibration still selects the original fixed bundled patterns.

## Local persistence and recovery

`getApplicationSupportDirectory()/frame_catalog/` owns the catalog independently
from customer upload retention and Flipbook archives. `catalog.json` uses schema
version 1 with `enabledProducts`, `enabledClassicVariants`, and `templates`.
Each template stores stable ID, name, revision, kind, artwork reference, slots,
enabled state, and bundled origin. Each slot stores ID, source index, signed
left/top, positive width/height, and rotation in degrees.

Managed artwork is immutable under relative `artwork/<unique-id>.png` paths.
References outside that owned namespace are rejected. Imports require a decoded
PNG no larger than 30 MB, 8192 pixels per side, or 32 million pixels. Geometry
must be finite and bounded, indices compatible with the product, and IDs unique.
Bundled references must match shipped artwork; original assets are never deleted.

One notifier serializes mutations and validates against the latest state. A
stale editor revision is rejected. Saves also acquire an exclusive operating-system
lock on `catalog.lock` and compare manifest bytes with the repository's last
loaded/saved version while holding the lock. A competing application instance
cannot silently overwrite newer choices; staff must reload before retrying.
New artwork is written before metadata; the
manifest is flushed to a unique temporary file and renamed into place, retaining
the previous complete manifest as `catalog.backup.json`. Memory publishes only
after durable save succeeds. Failed saves preserve earlier metadata and artwork.

Unreadable primary metadata recovers the backup with a visible staff warning.
Before a later save, damaged primary data is copied to a unique recovery file.
If neither manifest is usable, bundled defaults are available and original data
and artwork remain preserved. A future schema version is kept read-only and
staff see an update warning. Unavailable local storage permits bundled operation
with a warning. Newly shipped IDs are merged disabled into an existing catalog,
preserving existing event choices and authored overrides.

## Change ownership

Domain/runtime worker: new `frame_catalog/domain/` models, repository, provider,
runtime adapters, artwork loader; Classic/Flipbook constant extensions; Classic,
Keychain, Bouncy, and Flipbook render integration; router/startup; customer home,
start and picker data wiring; printer artwork loader; catalog and render tests;
the existing Keychain compatibility assertion; this implementation record.

Presentation worker: new `frame_catalog/presentation/` screens/canvas/styles,
Settings entry, native PNG picker dependency and generated registration, and
editor widget tests. The separate design phase will start from this feature.

## Automated evidence

- `fvm flutter test test/frame_catalog_test.dart --reporter expanded`: 11 passed.
  Covers all product defaults and signed seed geometry, persistence round trip,
  concurrent mutations, stale revisions, failed writes, artwork preservation,
  corrupt recovery, future-schema preservation, last-product/frame rejection,
  unavailable-storage fallback, OS writer locking, cross-instance stale writes,
  and session/route policy.
- `fvm flutter test test/frame_catalog_rendering_test.dart --reporter expanded`:
  exercises all 25 migrated definitions against their original definitions using
  the unified renderer; their raster pixels agree exactly. Separate production
  pixel fingerprints prove that unaffected Portrait/Photobox cases stay exact,
  while the eight/five off-page cases intentionally change. Signed crop and
  rotated-edge probes verify the corrected page-clipping contract;
  imported artwork reaches both Classic PDF paths, Keychain preview/final isolate,
  all Classic Bouncy variants and four-design Keychain Bouncy; Flipbook PDF has
  25 pages with rotated repeated slots using distinct current sequence images.
- `fvm flutter test --reporter expanded`: **66 passed**, including the 12 final
  editor/catalog widget tests and the existing home test updated to initialize
  the real bundled catalog and verify all three defaults, persisted hiding, and
  continued Settings access. Full run completed in 28 seconds.
- `fvm flutter analyze --no-fatal-infos --no-fatal-warnings`: exit 0, **0 errors,
  8 existing warnings and 318 infos**. No diagnostics in the new catalog code.
- `fvm dart run custom_lint`: exit 1 with **4 existing INFO findings**, all
  `avoid_public_notifier_properties`, in `photo_notifier.dart:236` and
  `classic_print_feedback_test.dart:123–125`. No new catalog findings. The
  project's default command treats INFO as fatal; this was not reported as a
  clean exit. Standalone targeted `dart analyze` previously encountered a
  Windows analyzer-plugin startup error, but the final Flutter analyzer and
  standalone custom-lint command completed and produced the findings above.
- Final local logs are `.dart_tool/frame-editor-tests.log`,
  `.dart_tool/frame-editor-analyze.log`, `.dart_tool/frame-editor-custom-lint.log`,
  and `.dart_tool/frame-editor-build.log` in the feature worktree.
- `fvm flutter build windows --release`: exit 0, **production Windows build
  passed** in 43 seconds. Output:
  `build/windows/x64/runner/Release/photocafe_windows.exe`. No QA or camera
  override defines were supplied; Canon retains its production default.

No interactive QA, production capture, physical print, or user-media fixture was
used for this feature's automated checks.
