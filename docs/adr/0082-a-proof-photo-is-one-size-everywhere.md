# ADR-0082 — A proof photo is one size everywhere

Status: accepted
Date: 2026-08-06

## Context

A non-cash payment must carry a photo of its slip (ADR-0025), and those bytes
never leave the venue's LAN server (ADR-0036). Four surfaces show that photo,
and each had picked its own number:

| where | size | state handling |
| --- | --- | --- |
| live bill, receipt payment row | 22 | thumb only |
| settled bill detail, payment row | 26 | thumb only |
| reports, non-cash payment row | 44 | thumb, plus a hand-rolled 44dp box for the two image-less cases |
| settle flow, capture preview | 56 | raw `Image.memory`, not tappable |

Nobody chose those four numbers against each other; each was chosen against the
row it sat in. At 22dp a proof is a marker that something is attached, not an
image anyone can judge — the cashier who took the shot could not tell a bank
slip from a photo of the ceiling without opening the lightbox, and the whole
reason the photo is mandatory is that someone later has to.

The reports call site also owned a second copy of the box, because the widget
only knew "bytes or no bytes" while that screen needs three states. Two boxes
drawn to the same size by hand is a size that drifts: the placeholder was 44
with an 18dp glyph, tuned once, against a thumb free to change independently.

The thumb also rebuilt its `Future` inside `build()`, so every theme flip and
every parent `setState` re-pulled the JPEG over the pinned client.

## Decision

**One widget, one size, no size parameter.** `PaymentProofThumb`
(`lib/ui/core/widgets/payment_proof_thumb.dart`) renders every proof image in
the app as a `satProofThumb` (56dp) square, cropped `cover`, opening a
fullscreen `InteractiveViewer` lightbox on tap. Call sites pass no size.

The widget owns all three states, so the box is the same whatever the row
carries and a column of payments keeps one left edge:

- **the slip** — bytes from `proofPhotoProvider`, or handed in via `previewBytes`;
- **taken, unreachable** — `fetchable: false`. Off-site owner reading a cloud
  report: the proof exists, its bytes are on the venue's LAN (ADR-0036);
- **no proof** — `hasPhoto: false`. Cash, or a row predating the requirement.

56 is sized for *recognition*, not reading. A square crop of a portrait slip
cuts the nominal and the sender name, which sit at the edges; no inline size
short of a full-width band fixes that, and a band costs the row density that
makes a payment list scannable. So the thumb answers "is this a real slip" and
the lightbox answers "what does it say" — and every proof is tappable,
including the capture preview, because pre-submit is the one moment a blurry
shot is still fixable with `Ambil ulang` right there.

`proofPhotoProvider` (`FutureProvider.autoDispose.family`, in
`settlement_repository.dart` beside `paymentPhoto`) replaces the in-`build`
fetch. Keyed by `(id, history)`, so the same slip shown on a bill and in a
report is fetched once, and a rebuild is free.

## Consequences

- The widget moved out of `cashier_bill_screen.dart` into `core/widgets/`, with
  the `CATALOG.md` and widget-book entries that obliges (ADR-0054, ADR-0055).
  `report_sections_view.dart` no longer imports a screen for a widget.
- `paymentId` is nullable, for the capture preview — a proof that has no payment
  to name yet. Such a call must pass `previewBytes`; an assert says so.
- `previewBytes` exists partly for the book: the loaded state cannot be shown
  from an unpaired debug build any other way, and a widget whose main state is
  absent from the catalogue is not catalogued.
- Rows on all four surfaces are taller. That is the change, not a side effect.
- A future payment surface that reaches for its own number is the regression
  this ADR exists to prevent. `payment_proof_thumb_test.dart` asserts the same
  56 box in every state, which is the shape both old bugs took.
