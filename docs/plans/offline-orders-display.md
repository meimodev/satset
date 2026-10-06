# Offline Orders display

Status: implemented on 2026-10-06; device acceptance pending.

The Orders board shows captured orders as ordinary rows, following ADR-0139,
while distinguishing capture from host acknowledgement.

## Agreed behavior

- While the order submission awaits acknowledgement, show Tertangkap / Captured
  instead of TERKIRIM / SENT. Keep meaningful preparation or terminal statuses
  alongside the capture badge. Connectivity alone does not remove the badge.
- Format the original capture time as a local 24-hour clock. Retain it after
  acknowledgement and after restoring the ticket cache; do not substitute the
  delivery or reconnect time. Ordinary orders retain their existing sent clock.
- Show the complete item note beneath the modifiers using the existing quiet
  Instruksi khusus / Special instructions presentation. Empty notes take no space.
- Pending rows show elapsed time since capture without kitchen-lateness styling.
  Once acknowledged, elapsed time and lateness follow the existing kitchen clock.

## Verification

- Flutter 3.41.9 analysis: zero issues.
- 37 focused checks passed, including pending-to-acknowledged changes, host echo
  before journal removal, capture-time cache writes/restoration, captured
  ready/voided statuses, empty/long notes, both languages, and phone/tablet note
  wrapping with larger text.
- Full Flutter suite: 1,506 passed, three existing skips.
- Control goldens: 37 passed, 34 pixel mismatches. The unchanged HEAD checkout
  reproduced the same 34 mismatches with identical reported pixel counts on the
  same Flutter 3.41.9 runtime. Existing baselines were not updated.
- Physical-device acceptance remains pending. Earlier DEV-09 evidence predates
  this fix and does not constitute a pass for the current build.
- A pre-existing Active/Done scope-tab overflow at 1.5 text scale on a 360-pixel
  phone remains outside this change; the large-text row checks use Ready to
  exercise the notes independently of that control.

This is a reversible display correction under the existing capture/delivery
model, so no new ADR is needed.
