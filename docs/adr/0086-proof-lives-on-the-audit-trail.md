# ADR-0086 — A proof photo lives on the audit trail, not in a report

Status: accepted
Date: 2026-08-08

Supersedes parts of [ADR-0025](0025-mandatory-non-cash-payment-proof-photo.md),
[ADR-0036](0036-owner-cloud-report-snapshot.md) and
[ADR-0072](0072-venue-audit-log.md). See §Consequences for exactly which parts.

## Context

Every non-cash payment carries a mandatory proof photo (ADR-0025). Until now the
only way to browse those photos across a date range was a **Pembayaran** card at
the foot of Admin → Reports: per-method totals, then one row per tender with a
56px thumbnail.

That card was in the wrong place, for three reasons that only became obvious
once the venue log existed.

**A report is for totals; a proof is evidence.** Reports answer "how did we
trade" — net, covers, top items, waste. A proof photo answers "is this tender
real", which is the same question a void, a comp and a manager-approved discount
ask. Those three already live together on the venue log (ADR-0072). The proof
sat one screen away from its own kind.

**The log could not show it.** `audit_entries` had no reference to a payment, so
a manager scanning the log for something wrong could see `Bayar Rp. 340.000` and
had no way to reach the slip behind it without leaving for Reports and finding
the row again by eye.

**The link was impossible anyway.** Closing a bill copies `payments` into
`table_session_payments` and, until this ADR, minted a fresh uuid on the way.
Any reference stamped at payment time would have dangled the moment the bill
closed — which is to say, always, by the time anyone audits it.

There is one genuine cost to removing the card. The off-site owner (ADR-0036)
reads a cloud snapshot and has **no route to `/audit`**, which is a LAN endpoint
on a tablet-only screen. For them the card was not redundant with the log; it
was the only sight of an individual tender they had.

## Decision

**A proof photo is reached from the audit row that records the payment.** The
non-cash card is gone from `ReportSectionsView` — from the admin's report and
the owner's alike.

**`audit_entries.payment_id` (v48), nullable.** Written by the payment route,
and *only when an image actually exists* — so it doubles as the has-photo flag
and the read path needs no join. Cash tenders and refunds store null.

It is a column and not an ADR-0085 `params` key. `params` exists to compose a
sentence in the reader's language; this is a reference. References belong
somewhere queryable, not inside an opaque blob.

**The payment id survives the close.** `tables_routes.dart` carries `p.id` into
`table_session_payments` instead of generating one. `GET
/audit/payments/<id>/photo` looks in both tables, because the log scrolls across
the close and cannot know which side a row fell on.

**On the venue log, the proof is a glyph and a tap** — a ~16px camera mark in
the event column, opening the shared `ProofViewer` lightbox. Not a thumbnail
column: the log is a fixed six-column table, a 56px slip would set the row
height for all six on every row in the log, and each page would pull a JPEG per
row to decorate the roughly one in twenty that is a card tender.

**The owner gets the money half of the log in the snapshot instead.** Rows where
`amount_cents IS NOT NULL` — payments, refunds, voids, comps, discounts,
write-offs — published newest-first, capped at 500 per range with a `truncated`
flag, rendered as stacked rows (not the tablet table) on `OwnerReportScreen`.

The filter is the amount column rather than a list of types on purpose: that
column is by definition what a row is worth, so a money type added later
publishes itself without anyone remembering to come back.

**No proof bytes off-site, still.** ADR-0036 rejected hauling audit-grade JPEGs
through the cloud and that reasoning is untouched. The owner sees that a card
tender happened, for how much, by whom; the image stays where the auditor is.
Their rows carry no `paymentId` at all — an indicator that opens nothing is
worse than no indicator.

## Consequences

- ADR-0025 still stands entire: the photo is still mandatory, still captured in
  the same request, still pinned, still one size (ADR-0082). Only the sentence
  naming the reports card as its browsing surface is superseded.
- ADR-0036's "the owner sees every payment's method/amount/cashier/time" is now
  delivered by the money-audit block, not the payments section. Its
  **no-photos-off-site** rule is reaffirmed, not weakened.
- ADR-0072's row shape gains one nullable column.
- **No backfill.** Rows written before v48 have no `payment_id` and show no
  indicator. A payment that closed before v48 had its id regenerated, so there
  is genuinely nothing left to point at — inventing a link by matching on time
  and amount would be a guess, and a wrong guess on an integrity log is worse
  than an honest blank.
- The cap is a real ceiling. A venue busy enough to write more than 500
  money rows in a range shows the owner the most recent 500 and says so. Without
  it the snapshot document would eventually exceed Firestore's 1 MiB limit,
  which fails the *whole* write — sales, staff and menu included — not just the
  audit rows.
- The sample seed spends a small budget of stand-in JPEGs (20, within the last
  seven days) so the glyph and the lightbox can be exercised on a freshly seeded
  venue. They are 1×1 images and are not pretending to be bank slips.
