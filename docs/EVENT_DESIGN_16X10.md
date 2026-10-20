# Event screen design correspondence

This presentation change is based on `codex/frame-editor-modes` at
`8b09830c98ac5b38ab1118ea71a3411dbe365c4f` ([parent PR #1](https://github.com/ajaparicio36/photocafe_windows/pull/1)).
The visual authority is the eight supplied screen designs in
`E:/Downloads/clickclick-assets/designs`, with the user's explicit 16:10 event
monitor adaptation. The source references are 2880×1920. They are review inputs,
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

Final production checks on FVM Flutter 3.41.1:

- Full test suite: **72 passed**.
- Analyzer: **zero errors**; 290 diagnostics (six inherited warnings and 284 infos).
- `custom_lint`: one inherited `avoid_public_notifier_properties` INFO at
  `photo_notifier.dart:236`; the command exits 1 for that diagnostic.
- Windows release build: **succeeded**, producing
  `build/windows/x64/runner/Release/photocafe_windows.exe`; native dependency
  compiler warnings remain.

Test and build logs live under `.dart_tool/event-design-*.log` in the
implementation worktree.

## Visual verification status

The source reference pixels and supplied assets were inspected before
implementation. Automated layout checks are not visual approval. Actual native
screen comparison, camera workflows, video playback, focus/interaction checks,
and local soft-copy flows are pending. The user has already authorized that QA
pass; it will run after production review/build and stacked PR publication.
Physical printing and public uploads are outside that QA scope.

The unchanged upload-video screen retains its existing presentation and runtime
behavior; it is not one of the eight supplied screen targets.
