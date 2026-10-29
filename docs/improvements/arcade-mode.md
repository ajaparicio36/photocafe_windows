# Arcade Mode

Staff setup: **Settings → Frames & modes → Arcade frame**, choose an enabled
Classic frame, then enable **Arcade Mode**. The frame determines Portrait,
Landscape or Photobox and the number of captures (highest source photo index
plus one, from one to four). Repeated slots and gaps keep their authored source
mapping. The selected frame cannot be hidden while Arcade is on; choose another
frame or switch Arcade off first. Editing its geometry affects new sessions.

Customer flow: **Start → Classic Mode → Capture → Print preview**. Capture keeps
the normal countdown and Bouncy still/clip pairing. After the last shot, the app
uses capture order, no filter and the staff frame to prepare the existing PDF and
print confirmation screen. It does not print automatically. Print's Back button
returns to Capture for retakes; Capture's Back button confirms discarding work
and returns home. PDF failures retain shots and offer Continue to print again.
Native 1240×1844 print geometry, no bleed, 16:9 camera content and the 16:10 shell
are unchanged.

The catalog persists Arcade independently of the normal product and variant
switches. Those controls show their saved values while Arcade is on. Turning it
off restores them; normal sessions still capture four photos. Older catalogs
load with Arcade off. A missing/hidden Arcade frame in an externally changed
catalog blocks customer starts with staff guidance, rather than silently using
another frame. Each accepted customer session freezes its frame and variant.

## Bouncy soft-copy quality

Soft copies remain silent six-second MP4s at six frames per second. The live
capture ring and interactive preview are unchanged. Export renders again from
the retained camera JPEGs with a 640-pixel source working limit (preview: 320),
producing Classic 620×922 instead of 310×462. Keychain remains 620×922 and uses the
larger source working limit. The common compositor preserves authored geometry;
the export does not enlarge the already reduced preview. NVENC uses VBR/CQ 21,
QSV global quality 21 and software x264 CRF 21 (previous software CRF: 23).
Unsupported hardware still falls back to software. Export may take a little
longer and produce larger files. This retains more available detail; it cannot
recover detail the camera did not supply. Compressed raster retention is capped
at 12 MiB for preview and 24 MiB for export, with reversed frames sharing buffers.

## Verification and remaining manual QA

Headless regression coverage exercises persistence, normal-menu restoration,
invalid frame guards, direct route guards, frozen session behavior, all three
Classic variants with one to four shots, original source order, no-filter PDF
generation, Bouncy pairing and a Home-to-Capture widget flow. Media tests compare
high-frequency source detail with an enlarged preview and validate an actual
silent six-second software-encoded MP4 with FFprobe.

Interactive QA is pending explicit user confirmation that the shared application
and webcam are available. Then exercise Arcade only: choose a staff frame, enable,
start Classic, complete captures, reach Print without choices, retake via Back,
cancel/restart, verify frame and Bouncy soft copy, then turn Arcade off and confirm
the saved normal menu. Do not send a print job without the agreed QA scope.

Production uses Canon (`BOUNCY_CANON=true`, `BOUNCY_QA=false`). The reusable webcam
test override belongs in a separate stash after production review and isolation;
it is not part of this feature or the production build. Original stashes must be
preserved. Actual webcam recovery and hardware-encoder quality remain manual
device checks; headless tests do not establish those results.
