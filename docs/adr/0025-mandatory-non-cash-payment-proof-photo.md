# Mandatory camera-shot proof photo on every non-cash payment

**Status:** accepted — builds on [0023](0023-two-phase-settlement-and-split-bills.md) (settlement/payments), [0024](0024-visit-decoupled-from-table-and-bill-close.md) (snapshot timing), and [0014](0014-menu-photo-blob-and-pinned-byte-fetch.md) (blob storage + pinned byte fetch).

**Amended by [0086](0086-proof-lives-on-the-audit-trail.md):** the "Pembayaran non-tunai" report section named below is **gone**. A proof photo is now reached from the venue log's payment row (camera glyph → lightbox), which is where the void and the comp it sits beside already live. Everything else here — the photo is mandatory, captured in the same request, pinned, one size — is unchanged.

## Context

[[Payment (manual confirmation)]] records money with **no gateway** — recording *is* the confirmation, so there is nothing external attesting that a card/QRIS/transfer actually cleared. Owners want a hard audit trail for non-cash money: a photo of the EDC slip / QR confirmation / transfer screen taken at the till. Cash needs none (the drawer is the evidence).

The requirement: every payment whose method is **not `tunai`** must carry a **mandatory** photo, the photo must be a **live camera shot** (a saved screenshot defeats the point), it must be visible when reading [[Past bills]], and it must surface in a report. No payment-method report existed (the `TableSessionPayments` "source for the report" comment was aspirational), so the report is built here too.

## Decision

**A non-cash [[Payment (manual confirmation)|Payment]] requires exactly one mandatory, camera-shot proof photo, server-enforced, stored as a blob that rides the payment into immutable history.**

- **Per Payment, not per receipt/bill.** Every method except `tunai` (kartu, qris, transfer, lainnya) demands one photo. A split tender (part QRIS + part transfer on one receipt) carries one photo each — the photo proves *that* tender, so it cannot be shared.
- **Camera-only.** Captured via `image_picker` `ImageSource.camera` only — no gallery — so the proof is a live shot, not a re-used screenshot. JPEG-compressed client-side (~1080px long edge, q80) like the [[Menu photo]].
- **Atomic capture.** The bytes ride in the **same** `POST …/payments` request as the payment fields (base64). Server stores `Payment` + photo blob in one transaction — unlike the menu photo's two-step PUT (which targets an already-persisted row); a payment is created fresh, so a two-step flow would leave a transient photo-less row contradicting the fail-closed gate.
- **Server-enforced, fail-closed.** The settlement route rejects (`400 photo_required`) a non-cash payment with no photo bytes; the cashier UI also disables confirm until a photo is shot. UI-only would let a non-app client skip it.
- **Storage: blob on both payment tables.** A nullable `photo` blob is added to **`Payments`** (live) and **`TableSessionPayments`** (snapshot). At [[Bill close (Tutup tagihan)|bill close]] the snapshot copies the bytes across (it already mints a fresh row id, so live and history photos are fetched by different ids). The blob is **never** selected in list/bill queries; a dedicated **pinned-byte route** serves it on demand, per ADR-0014. The snapshot stays self-contained (immutable history owns its own bytes).
- **Refunds are exempt.** A [[Payment (manual confirmation)|refund]] (negative payment) carries no photo — out of the "doing payment" scope, and already manager-gated.
- **Surfaces.** Past-bills **Struk pembayaran** detail shows a thumbnail per non-cash payment (tap → fullscreen); a **new "Pembayaran non-tunai" report section** lists every non-cash payment in the range (method, amount, table, cashier, time) with the same thumbnail-to-fullscreen, sourced from `TableSessionPayments` over the existing reports date range.

A schema migration adds the two blob columns. No backfill — payments closed before this feature simply have no photo (rendered as "tidak ada bukti").

## Considered options

- **Per-payment, camera-only, atomic, server-enforced, blob-on-both (chosen)** — strictest reading of "each time, mandatory, photo only". Cost: a migration, byte-copy at snapshot, two fetch ids.
- **Per-receipt photo** (rejected) — one photo for a receipt regardless of how many non-cash tenders. Cheaper UI, but a split QRIS+transfer receipt then can't prove *which* tender each slip belongs to.
- **Gallery allowed** (rejected) — convenient, but a saved screenshot is trivially faked/re-used; camera-only is the whole point of "proof".
- **Two-step pay-then-upload** (rejected) — mirrors the menu-photo PUT, but a freshly-created payment would exist photo-less between the two calls, contradicting the fail-closed gate and needing a "pending photo" state.
- **Separate `payment_photos` table** (rejected) — avoids copying bytes at close, but the immutable snapshot would no longer be self-contained and would depend on id continuity across the live→session boundary (which the snapshot deliberately breaks by minting new ids).
- **UI-only enforcement** (rejected) — lighter, but a non-app client could record a photo-less non-cash payment; money policy must be server-owned.

## Consequences

- Cashier cannot record a non-cash payment on a device with no working camera — accepted limitation (cash always remains photo-free).
- Bill payloads stay lean (blob excluded); each thumbnail/fullscreen view costs one extra pinned-byte fetch.
- Bill-close copies blobs, so closing a heavily-split non-cash bill moves more bytes — bounded (one compressed JPEG per non-cash tender).
- The new report is the first payment-method surface in `reports_routes`; future per-method KPIs can hang off the same `TableSessionPayments` aggregation.
