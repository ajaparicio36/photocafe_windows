# Bouncy Previews implementation results

Implementation branch: `codex/bouncy-previews`, forked from `popup_sanag_keychain` at `e4b6c18ae6e0fa3385b493decd9e6b8a528214fe`. Only the Flutter application is changed here. Archive integration is implemented independently in the allowed server repository. The historical `edsdk` discovery checkout is read-only; the frame editor is excluded.

## Production checkpoint - 2026-10-21

The development override and fixture results below are historical. Current
production startup initializes Canon normally, and Classic/Keychain capture uses
`BOUNCY_CANON` with `defaultValue: true`; a normal release does not need a camera
define. Temporary Iriun overrides used for authorized local QA remain outside the
production source. Iriun evidence does not establish Canon quality or timing.

Current feature `99858f9` passes 71 tests, including three real-FFmpeg regressions
for accepted Flipbook source preservation. Combined design `57207b0` passes
77 tests; the separate full QA suite passes 90 tests without skips, including
real MP4 acceptance/truncation/payload-corruption boundaries. Production analysis reports zero errors, six warnings and 283 infos.
Current production release passed in 62.8 seconds without QA defines; the
separate Iriun QA release passed in 63.5 seconds. The rebuilt native colored-filter source-preservation retest passed: Vintage Apply,
Back/reselection and No Filter preserved all four original sources and accepted copies. The bounded
native pass also completed Classic Portrait/Landscape/Photobox, Keychain, Flipbook,
hidden-frame visibility, last-usable guards, CUT contrast and final restoration.
The completed bounded native checkpoint and explicit hardware/performance limits are recorded in
`frame-editor-implementation.md`. The earlier fixture/build records below are
historical. The five-second target remains unmet by the measured 24 MP synthetic
runs and is not established by Iriun capture.
## Capture and identity

`BouncySession` receives compressed JPEGs from the existing single Canon EVF subscription. A monotonic stopwatch timestamps arrival. The ring samples at at most 12.5 fps, keeps at most three seconds / 48 frames / 12 MiB, and freezes immediately before the actual single Canon shutter command. Strict Bouncy capture deliberately does not retry internally or accept contingency preview-quality stills. Staff trigger a new attempt after a failure.

Technical coverage thresholds: at least 16 frames, at least 2.8 seconds from first sample to command, latest sample within 250 ms, and no gap above 350 ms. These tolerances accommodate a sampled three-second interval; they never pad, synthesize, or include post-shutter footage. Every retained JPEG must decode, be at least 16 pixels on each axis and at most 1920×1080 pixels. Oversized, malformed, interrupted, missing and short clips require a retake. The active session holds at most four compressed shot clips / 48 MiB. One running and one latest queued render may transiently retain earlier bounded snapshots (at most two further four-clip sets) until cancelled work drains; there is no unbounded render queue. The full-quality camera original is decoded at a bounded validation size, copied byte-for-byte separately, and remains the printable source.

`PhotoModel.captureId` survives reorder/filter operations. A session generation and consumed per-shot attempt token fence late results. A retake validates the target first, then replaces its copied still and clip synchronously after all asynchronous validation. Other pairs remain intact. The next automatic shot is the first missing placement, never the next accepted pair. The first attempt counts down ten seconds; every later attempt and staff retake counts down three seconds. The old two-second inter-shot delay is removed. Countdown progress and controls occupy a reserved bottom dock under a fitted 16:9 preview.

A pending or failed retake blocks readiness even while its prior accepted bytes are retained for atomic replacement.

The existing staged `CameraController` still/preview override is preserved as the default development behavior. It has no real EVF clip source and cannot complete Bouncy capture. `--dart-define=BOUNCY_CANON=true` selects strict Canon capture. `--dart-define=BOUNCY_QA=true` explicitly selects a labeled generated fixture feed, with valid/missing/short controls. This fixture proves application behavior, not Canon timing, optics, exposure, or download fidelity. Flipbook's existing Canon preview recorder and take workflow remain unchanged.

## Shared composition, print and archive

`FrameCompositionRenderer.renderDecodedVariant` supplies the same slot mapping, center crop, rotation and artwork alpha to final Keychain still output and motion frames. Geometry remains exactly 1240×1844 for the print sheet and 620×922 for each tile; no historical bleed or printer compensation is restored.

The still pipeline decodes each original once and directly assembles the four raster tiles into the sheet before PNG encoding. Fused nearest-neighbor crop sampling preserves the old floor coordinates without copying a multi-megapixel crop per slot. uint16, palette, EXIF orientations 2–8 and animated sources keep the original crop/resize fallback. EXIF orientation 1 uses the proven equivalent fast path. Pointwise filters run on sampled pixels; Photobooth carries original source coordinates into its vignette, so sampling does not move the vignette. The sigmoid lookup is identical to the old integer-domain formula. Original camera files are never overwritten by filtering.

Live-view working images are never upscaled and fit within a 320-pixel longest side, including extreme aspect ratios. The interactive Bouncy Preview and MP4 use the same bounded raster cycle: 18 forward samples and their reverse at six fps, a six-second silent loop. The four-design Keychain output is 620×922, with four 310×461 tiles, preserving all selected frames/filters and stable shot mapping. Classic uses a 310×461 composition on a 310×462 white canvas for even H.264 dimensions; the deliberate single padding row does not rescale slot geometry. No animation bytes enter the still PDF or printer. Preview playback can pause and respects reduced motion. Only one render runs and one latest request waits; decoded display frames are evicted on replacement/disposal. Encoded forward samples are capped at 12 MiB, with reverse playback sharing the same compressed buffers.

Motion export runs independently after print files and all four valid pairs are ready. Real H.264 encode attempts try NVENC, QSV, then software libx264. Each output is checked for one video stream with no audio, expected dimensions, approximately six seconds, minimum file size and a decodable frame. Failed encoding retains valid pairs and print availability. Soft Copies reports motion export unavailable and offers retry later; no archive uploads without the required MP4. It does not substitute raw/synthetic video or inherit the historical webcam photos-only policy. The new attachment is exactly `bouncy_preview.mp4`, while original photos, still compositions and existing archives remain intact.

## Ownership and cancellation

Every photo session has a unique owned OS-temp directory. Reset coalesces repeated requests, advances generation, cancels owned uploads/encoders, drains capture/filter/raster/composition/upload readers, then deletes exactly its owned files. No shared-directory globs or remote rollback are used. Start Over confirms destructive cancellation. Export directories are tracked individually and removed after readers drain. The retired Classic/Keychain companion webcam recording/VHS branches and their synthetic fallback paths are disconnected/removed; the CameraController still override and reachable Flipbook code remain.

## Measured performance and GPU decision

All synthetic benchmarks below ran on the available Ryzen 7 5700X / 32 GiB / RTX 5060 Ti workstation with FVM Flutter 3.41.1 and FFmpeg 8.0.1. They do not establish performance on the user's described Intel i7 / Iris Xe laptop. Four 6000×4000 JPEG fixture originals, four bundled frame designs, final four PNGs, sheet PNG and PDF were included; source file reads preceded timed AOT work. Other workloads were active.

| Workload | Original AOT | Integrated exact compositor |
| --- | --- | --- |
| No filter | 89.759 / 76.290 s | 8.440 / 7.987 s before final filter integration |
| Photobooth | 127.961 / 135.842 s | 9.926 / 10.088 s |
| Four distinct filters | 107.092 / 99.048 s with the earlier reduced-codec path | 9.577 / 9.489 s |

The approximate five-second local target is **not met** for these full 24 MP fixtures. Original JPEG decoding alone takes roughly 4.8–5 seconds during integrated measurements. The final EXIF-1 fast-path fixture measured 7.854–7.899 seconds for Photobooth and 7.222–8.091 seconds for mixed filters, still above the five-second target. Original no-filter sheet SHA-256 remains `6DCD9552DBCA883253612F5439F2841131BDF0F16AB841912FE3169627C72F29`. Independent actual-source differential checks passed 75/75 filter/layout/crop/rotation/alpha/EXIF cases; the final orientation-1 proposal passed 100/100 combined compositor and uint16/multi-frame/EXIF fallback checks. Removing the prior intermediate lossy filtered JPEG improves fidelity and intentionally changes filtered pixels relative to that lossy intermediate; sample-first output matches the full-source lossless-filter comparator exactly.

Actual Vulkan upload/scale/flip/overlay/readback succeeded but took 4.2–4.9 seconds against 0.6–1.0 seconds for the corresponding simple native CPU fixture, with PSNR 22.1 dB due to different sampling/color. It is not adopted for print. A native JPEG-decoder experiment reached about 5.15 seconds with PSNR 59.5 dB rather than pixel equality; it is also not adopted for print. Actual NVENC encode and CUDA decode/readback succeeded. Actual QSV failed MFX -9 on this non-Intel host. Hardware video encoding is used with a tested software fallback; no claim of GPU still-filter/JPEG/PNG acceleration is made.

Benchmark media and scripts remain OS-temp only. Durable documentation contains no private camera/desktop footage or secrets.

## Verification record

Baseline: 20/20 tests passed after dependency generation and an exact local copy of the ignored `.env`. Original staged override patch and isolated transferred patch both hash to `CD404EF6FB0FC76696DFA59D631D446039A218A8B15EE18D870A7A18E01210F7`; the original staged patch was rechecked unchanged after implementation.

Meaningful added tests exercise ring time/count/byte bounds, immutable bytes, invalid coverage/corruption, consumed attempts, unique IDs, stable reorder/atomic retake, missing retake targets, coalesced reset, filter/PDF late-result fencing, composition/filter pixel equivalence, shared whole-sheet playback/export, real encoder fallback, independent print readiness after encoder failure, cancellation and exact owned output cleanup. The final current-source suite passed **35/35** in 18 seconds. Static analysis reports zero errors, seven preexisting warnings and 326 total legacy issues (baseline: 478 issues, 16 warnings). Custom lint exits successfully with four existing informational notifier-API findings. The final QA release build succeeded in 46.9 seconds using `--dart-define=BOUNCY_QA=true`. `git diff --check` passes. Build-only generated Windows plugin line endings were verified as having no substantive diff and normalized to repository CRLF. The original checkout remains exactly the same two staged overrides with the SHA-256 above.

No real Canon camera, physical printing, public upload or Iris Xe validation is claimed. Interactive desktop and local Chrome archive QA are coordinated by the root agent under the user's shared-resource confirmation.

Final root-run native fixture QA completed capture → upload → Chrome archive at `http://127.0.0.1:3017/archive/22d21d6a-e5e0-4b65-83c7-5c257bdf4c5a`. The archive contains ten attachments: silent H.264 `bouncy_preview.mp4` (620×922, six seconds, 36 frames, 854266 bytes), a 1240×1844 sheet, four 620×922 variants and four 640×360 originals. Chrome autoplayed the entire four-design composition. Downloaded MP4 SHA-256: `56A16CFF2C9E8849C7FBCF4FD5F5A8BCCFEAB45059808E3F1538CC09097960E2`.

At the native 1266×713 viewport, Classic and Keychain capture, filter/design, reorder/review and full composition previews fit. Root exercised first countdown ten seconds, later/retake countdown three seconds, pause after shot two → atomic shot-one retake → missing shot three. The missing clip blocked progression while preserving the accepted pairs; a valid retake completed the session. Encoder failure left printing available and prevented archive upload. The approved Start Over returned Home without late result resurrection. The newest release also includes shared confirmation/draining for start-screen resets and Classic print completion; these final caller changes passed automated tests after the exhaustive native QA binary was built. A separate smoke of the exact final current-source release executable passed Home → Keychain → Start → ready fixture → ten-second first countdown → four accepted pairs → fitted, animated Design 1 of 4, with no observed error or late state. Root then closed the app without deleting session files.

### Developer / local QA commands

```powershell
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test --no-pub
fvm flutter analyze --no-pub
fvm dart run custom_lint
fvm flutter build windows --release --dart-define=BOUNCY_CANON=true
# Explicit generated fixture, never real-camera evidence:
fvm flutter build windows --release --dart-define=BOUNCY_QA=true
```

In fixture capture, select valid/missing/short and optionally enable **QA pause after shot 2** before starting. The latter uses the normal paused state after two accepted shots so a staff retake can be tested deterministically. On the print screen **QA encoder failure** exercises export failure independently of printing. QA builds force Soft Copies to `http://127.0.0.1:3017`; `BOUNCY_QA_API_BASE` may select a different loopback server, and non-loopback hosts are rejected. Production upload settings remain unchanged. All fixture output is disposable OS-temp media.
