# Staff frame catalog implementation

Feature branch: `codex/frame-editor-modes`, based on production `master` at
`9122c57dfed078004789ac42df908fe3cda308b2`. The existing Canon EDSDK production
camera, capture aspect ratio, print geometry, and Bouncy completion rules remain
the baseline. The authorized bounded native desktop and real Iriun camera QA pass is complete
on the stacked design implementation. Physical printing
and public-upload QA were not performed and remain outside this checkpoint.

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
editor widget tests. The 16:10 customer design is stacked on this feature.

## Automated evidence — current feature `99858f9`

- Full feature suite: **71 passed**, including catalog publication/recovery,
  concurrency, availability/session routing, editor widgets and render parity.
- Three real-FFmpeg filter regressions fail against the old implementation and
  pass with source preservation, owned-derivative replacement and cleanup.
- Filter-change targeted analyzer: zero errors/warnings, 49 inherited
  `avoid_print` infos. Custom lint retains four inherited INFO findings and
  exits 1; this is not a clean default lint exit.
- Current combined design `57207b0`: **77 tests passed**; full production
  analyzer exits 0 with zero errors, six warnings and 283 infos.
- Full separate QA suite: **90 passed**, including real MP4 acceptance,
  truncation and payload-corruption boundaries with no skips.
- Current `57207b0` normal production release passed in **62.8 seconds** without
  QA defines. The separate Iriun QA release passed in **63.5 seconds** with
  `BOUNCY_CANON=false` and `BOUNCY_QA=false`.
- Native colored-filter source-preservation retest passed on `57207b0`; details below.

Renderer regressions cover all 25 catalog adapters against their original
definitions, unchanged production fingerprints for six unaffected templates,
intentional off-page crop differences, rotated-edge clipping, managed artwork
through both Classic PDF entry points, Keychain preview/final isolate, Classic
and Keychain Bouncy, and Flipbook current-image/repeated/rotated slots.
## Native QA checkpoint — bounded pass complete, 2026-10-21

The authorized native pass uses the real Iriun Webcam through a temporary local
QA override. Production Canon startup and camera selection remain unchanged.
These observations establish local application behavior, not Canon image quality
or timing. Physical printing and public uploads were not tested.

Staff PNG import, move/resize/rotation, duplication to eight slots, source mapping
0,0,1,1,2,2,3,3, Save hidden, enabling and ordinary keyboard input passed. An
approved name-only Cancel preserved the manifest and artwork byte for byte.
Normal restart restored the enabled revision-2 frame and all slot geometry.
The corrected discard dialog has readable text and actions; Keep editing retains
the draft. A later intentional name change saved revision 3. The earlier restart
proof applies to revision 2. Native controls reject disabling the last usable
product or Classic variant, and Classic off/on retains variant choices.
On native `57207b0`, hiding the final Landscape frame is refused with a readable
explanation to keep a frame enabled or disable that variant. All six Landscape
frames and every product/variant were restored enabled. Customer hidden-frame selector verification passed in Landscape below.

Classic Portrait completed four real stills, Sepia, reorder, bundled-frame
selection, Bouncy pause/play, print review and local soft-copy delivery. All four
1280×720 originals fully decode and match camera-source bytes. Its silent H.264
Bouncy is 310×462, six seconds, six fps and 36 decoded distinct frames. The six
ZIP entries match server files byte for byte. The actual printable PNG is
1240×1843; this existing PDFium float-truncation observation does not alter the
logical print geometry. Native PDF equivalence was not established. The archive
lightbox correction contains the complete photostrip with all rows and both
strips visible; attachment hashes remain unchanged.

Keychain completed four independent custom/bundled frame and filter choices,
retained Design 1 on return, whole-sheet preview and print review. All four
1280×720 original/source JPEG pairs are byte-identical. Each 620×922 quadrant of
the 1240×1844 sheet is pixel-identical to its variant. The silent whole-sheet
H.264 is 620×922, six seconds, six fps and 36 decoded distinct frames. All ten
uploads match local files; the 5,786,819-byte ZIP contains ten byte-identical
entries. Chrome contains the complete PNG/MP4 and playback was observed through
0:05/0:06. Media remained retained after normal close/relaunch.

A controlled local-server outage retained the Keychain sheet and consent OFF,
re-enabled Get Soft Copies and showed no QR. Restoring the server and retrying
succeeded with a fitted QR dialog. The four-second network-error snackbar was
not visually captured; source confirms its message, so no missing-feedback
defect is claimed.

Flipbook completed four fresh accepted Iriun takes. All source/accepted copies
are byte-identical and strictly decode at 3840×2160: durations
6.965533 / 6.9818 / 7.0114 / 6.9977 seconds, with 209 / 209 / 210 / 204 decoded
frames respectively. No Filter produced 50 distinct, fully decoded 1920×1080
frames and the actual 25-page staff PDF (5,247,471 bytes; SHA-256
`399F285D2BACC91FE7627011E0579BD2084EF8CA8BC66BC701D567AD53AD728C`).
All 25 pages rendered successfully through Poppler; pages 1 and 25 contain
complete numbered leaves 1/2 and 49/50. The gray binding region is intentional
stock artwork. Native Frame 1→4, Next/Previous page navigation and print review
passed without printing. The earlier temporary QA-only DTS-precision rejection
was corrected locally; original media remained unchanged.

All eight supplied references have now been visually compared. At a 626×393
shell, takes/filter/review remain fitted; Tab to Take 2 and Enter activation
were observed. Pillar bars in the Iriun source are present before app playback,
so they do not establish an application aspect-ratio defect.

Before colored Apply, QA found a production ownership bug: `applyVideoFilter`
deleted an accepted take still referenced by `videoTakes`. Feature `99858f9`,
inherited by design `57207b0`, tracks successful filter derivatives and replaces
only owned, unreferenced outputs. Accepted/imported/unknown sources are retained;
existing `clearVideo` cleans retained derivatives. Three real-FFmpeg regressions
failed against the old behavior and pass with the fix. Feature full suite:
71 passed; targeted analyzer: zero errors/warnings, 49 inherited `avoid_print`
infos; custom lint retains four inherited INFO findings. Current design has
77 passing tests and verified production/QA releases.

On native `57207b0`, four fresh real Iriun takes fully decode at 3840×2160
(6.980633 / 7.004817 / 6.999867 / 6.948667 seconds; 210 / 210 / 210 / 204
distinct decoded frames). Vintage Apply on Take 2 produced 210 distinct filtered
frames and 50 distinct decoded JPEGs. Back loaded all four takes; Take 1 and
reselected Take 2 played their originals. No Filter then produced 50 new distinct
decoded JPEGs and reached the uncolored frame preview, page 1/25. All four
sources and four accepted copies remained byte-for-byte unchanged through every
stage. No fixture, import or media restoration was used.

Classic Landscape completed four live 1280×720 stills with full decode and
byte-identical camera-source/accepted copies. Frame One was hidden before the
session; the customer picker showed only Frames Two–Six. Frame Two's Bouncy
preview and print review fit completely. The local printable PNG is 1240×1843
(existing raster rounding); silent Bouncy is 310×462, six seconds, six fps and
36 distinct decoded frames. Original and accepted-copy bytes remain unchanged.
CUT ON/OFF states are visually distinct and CUT was restored ON; consent stayed
OFF. No print or upload was dispatched. Legacy Frame Two's “Library / 143 Items /
4 Photos Selected” text and blue checkmarks are baked into its bundled artwork,
not leaked application UI; staff can hide or replace that artwork.

Classic Photobox completed four distinct real 1280×720 stills, all fully decoded
and byte-identical to their camera sources. No Filter, Frame One→Frame Two artwork
change, complete 2×2 Bouncy and print review passed. The local printable PNG is
1240×1843 (existing raster rounding); silent Bouncy is 310×462, six seconds,
six fps and 36 distinct decoded frames. All originals and accepted copies
remained byte-for-byte unchanged. No print or upload was dispatched.

Landscape Frame One was restored enabled at revision 5; all six Landscape frames
and every product/variant are enabled. Slot geometry and artwork remain equivalent
to the prior baseline. All planned bounded native cases are complete. Custom
Classic and Flipbook editor/render coverage is automated real-PDF parity; native
custom artwork was exercised in the staff editor and Keychain. No private camera
media or local evidence paths are published here.
The five-second end-to-end media target remains unproven. Earlier exact-compositor
24 MP synthetic runs took approximately eight to ten seconds on the measured
workstation. The Iriun captures do not establish Canon performance.
