# Event screen design correspondence

This presentation change is based on `codex/frame-editor-modes` at
`99858f9` ([parent PR #1](https://github.com/ajaparicio36/photocafe_windows/pull/1)).
The visual authority is the eight supplied Click Click screen designs, with the
user's explicit 16:10 event monitor adaptation. The source references are 2880×1920. They are review inputs,
not application backgrounds or bundled screen captures.

## Shared visual rules

- The window and letterboxed application shell use 1280×800, 16:10.
- `EventCanvas` gives customer pages a 1280×800 design space fitted on both axes.
  Smaller windows scale the complete composition. Pages do not scroll; frame and
  filter lists have bounded scrolling.
- `RubikMonoOne` is the supplied display face. `SpaceMono` is the supplied text
  face with Regular, Bold, Italic, and BoldItalic registrations.
- The supplied red texture, white/red logos, objects, and figures are copied
  unchanged to `assets/event/`. The title plaque uses white with a deep red
  border; unselected choices use deep red with white outlines; selected choices
  are white. Home and Start controls reproduce the references' glossy pills.
- `EventDesign` applies only under customer `EventCanvas` pages. The staff
  catalog/editor and the existing Classic/Keychain capture theme remain separate.
- Native Material focus, keyboard activation, hover, and press feedback remain
  available. Decorative pieces ignore input. No decorative animation was added.
  Bouncy playback retains its existing pause control and reduced-motion behavior.

## The eight references

| Reference | Route and implementation | Correspondence and 16:10 adaptation |
| --- | --- | --- |
| `home,classic/home.png` | `/` · `start_screen.dart` | White logo, welcome line, Rubik title, spaced instruction, three glossy product pills with `home_screen_figure1/2/3.png`, italic footer. Order is Classic, Keychain, Flipbook. The persisted catalog determines which products appear; the row reflows around visible products. |
| `home,classic/classic1.png` | `/classic/start` · `classic_start_screen.dart` | Portrait, Photobox, Landscape white cards with actual supplied `classic_mode_*` illustrations, red outlines, figures, and separate glossy Start buttons. The matching incumbent `assets/design/start/start_bg.png` contains the approved wall collage, logo, Classic pill, and template heading, so those are not duplicated as overlays. Semantic text describes the baked heading. |
| `home,classic/classicfilters.png` | `/classic/filter` · `classic_filter_screen.dart` | Centered white Filters plaque, back and Skip controls, left selected/unselected filter list and anchored Apply button, right complete photo preview and photo count. Uses the supplied two filter figures. Available choices and filter processing remain the real Classic filter definitions; reference-only filters are not invented. |
| `home,classic/classicframes.png` | `/classic/organize` · `classic_organize_screen.dart` | Three columns: four reorderable photos, bounded frame choices with anchored Proceed to Print, and a complete Bouncy Preview under `frames_figure1.png`. White numbered photo labels and explicit drag handles preserve reordering. Catalog frame names and descriptions remain real data. |
| `flipbook/flipbook_instructions.png` | `/flipbook/start` · `flipbook_start_screen.dart` | Matching incumbent `assets/design/flipbook-home/flipbook-home_bg.png` supplies the wall collage, logo, mode pill and bottom-right figure. The white instructions panel, supplied top figure, and glossy Start button are real widgets/assets. Existing seven-second recording instructions and the upload-video entry remain available. No duplicate baked logo or heading. |
| `flipbook/flipbook_takes.png` | `/flipbook/takes` · `flipbook_takes_screen.dart`, `takes_grid_widget.dart`, `take_preview_widget.dart` | White title plaque, deep red containing panel, two-by-two take grid, numbered white cards, top-right phone and bottom-left figure, centered glossy Proceed. Each video uses its actual playback aspect with containment. Selection plays the chosen take, shows a check, and enables Proceed. Missing/unplayable files show a readable state. |
| `flipbook/flipbook_filters.png` | `/flipbook/filter` · `flipbook_filter_screen.dart` | Same filter plaque, left choices and anchored Apply, supplied filter figures, and right landscape video preview. The complete video fits without stretching. Actual video filter names, preview processing, Skip, and playback controls remain wired. |
| `flipbook/flipbook_frames.png` | `/flipbook/frame` · `flipbook_frame_screen.dart` | Left frame choices and anchored Proceed, right complete print-page preview beneath `frames_figure1.png`. `EventPdfPreview` fits one actual generated PDF page at a time with Previous/Next instead of clipping a long scrolling PDF. The reference's blank preview region is populated by real output. |

All screen paths in the table are under `lib/features/<feature>/presentation/screens/`.
Shared visual components are in `lib/widgets/event_design.dart`; the bounded PDF
preview is in `lib/widgets/event_pdf_preview.dart`.

## Derived screens and preserved behavior

**Keychain:** `/keychain/start` derives the centered logo/pill, white instruction
panel, supplied figure, and glossy Start from the two reference start screens.
The existing `/keychain/design` route contains selection and final review; there
is no new `/keychain/organize` route. It has independent frame/filter choices for
each of four designs, an always-visible complete preview, and bounded choice
lists. Final review and `/keychain/print` use the same plaque/panel vocabulary and
the existing four-design sheet and Bouncy media contracts.

**Print screens:** Classic, Keychain, and Flipbook print pages use the same title
plaque, action panel, figure, and complete preview layout. Existing copies, cut
settings, consent, soft-copy upload, retry, completion, and start-over handlers
remain. Classic and Keychain Back controls remain available during a pending
print, while duplicate print dispatch stays disabled. No upload endpoints or QA
flags are changed here.

**Flipbook navigation correction:** Proceed to Print on `/flipbook/frame` now
generates and archives the PDF, then passes those exact `Uint8List` bytes to the
existing `/flipbook/print` route. The customer explicitly chooses Print Flipbook
there. Previously the frame page printed immediately, leaving the existing print
review route outside the normal flow. The same printer method receives the same
bytes; no page geometry or rendering algorithm changed. Empty-state Record Video
links now use `/flipbook/start`, replacing the nonexistent `/flipbook/home`.

**Capture:** Classic and Keychain share the existing capture screen without
source changes. Flipbook now uses the same black surface, small status header,
complete 16:9 preview, bottom action dock, and progress treatment. Its four-take
sequence, seven-second recording, countdown, processing, and Canon handlers are
preserved. A 16:10 shell never stretches camera content to 16:10.

**Catalog and media:** Product/variant visibility, the last-usable-mode guard,
session snapshots, custom artwork, crop/rotation parity, frame renderers, Bouncy
export, native printer calls, and persistence remain from the parent change.
The Bouncy widget only gains an optional foreground color for readable controls
on the reference's red preview surface.

## Automated evidence

The new `test/event_design_widgets_test.dart` covers:

- Thirteen customer screens at 1280×800 and 1024×640 using the real supplied fonts,
  including bounded panel geometry and no page-wide scroll views.
- Remembered Classic variant visibility.
- Take selection enabling navigation while retaining the chosen video path.
- Independent Keychain frame choices across designs.
- Real Flipbook PDF generation and archive, navigation to review with exactly the
  archived bytes, zero printer calls from Proceed, and page navigation.

The native PDF rasterizer is replaced only inside widget tests with an
aspect-preserving test raster. Native video playback, camera behavior, physical
appearance, and printer hardware are not proved by these tests.

`test/widget_test.dart` verifies the three-product order and provider-driven
hiding using the accessible labels rather than the retired image buttons.
`test/classic_print_feedback_test.dart` now uses the real supplied fonts and
clicks Print and Back through the router to verify safe navigation during pending
success and failure. The feedback assertions are unchanged.

Current production checks on FVM Flutter 3.41.1 at `57207b0`:

- Full suite: **77 passed**; the parent feature `99858f9` passes 71 tests.
- Full production analyzer: exit 0, **zero errors, six warnings and 283 infos**.
- Custom lint retains one inherited notifier-property INFO; command exits 1.
- Full separate QA suite: **90 passed**, including real MP4 acceptance,
  truncation/payload-corruption boundaries with no skips.
- Current normal production release passed in **62.8 seconds** without QA
  defines; separate Iriun QA release passed in **63.5 seconds**, with
  `BOUNCY_CANON=false` and `BOUNCY_QA=false`. Temporary QA camera/validator
  changes remain excluded from production.
- Native colored-filter source-preservation retest passed on `57207b0`; details below.

Current design logs: `.dart_tool/filter-retention-full-tests.log`,
`.dart_tool/filter-retention-full-analyze.log`,
`.dart_tool/filter-retention-custom-lint.log` and
`.dart_tool/filter-retention-production-release.log`. The QA release log is
`.dart_tool/filter-retention-qa-release.log` in the isolated QA worktree.
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
The upload-video screen retains its existing presentation and is outside the eight supplied targets.
