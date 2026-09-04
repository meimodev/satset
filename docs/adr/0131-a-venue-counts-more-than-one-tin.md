# A venue counts more than one tin

**Status:** Accepted — 2026-09-04 — **amends** [0088](0088-the-petty-cash-box-cannot-go-negative.md) and [0089](0089-petty-cash-is-not-revenue.md); neither is superseded.

[[Kas kecil (petty cash)]] modelled the venue's small cash as **one** fund. A
real kitchen keeps several: a tin the owner holds, a tin the kitchen spends from
for the morning market, a tin at the bar. This ADR gives each one a name and its
own arithmetic, and keeps every rule the single box already had.

## Context

Nothing about ADR-0088 or ADR-0089 was wrong; the ledger was simply one row
short. Everything else stayed true, and each one narrowed how this could be
built.

**A guard against the wrong total is not a guard.** ADR-0088 refuses an expense
larger than the balance, because a would-be negative is always a movement nobody
wrote down, and refusing is what produces the conversation. Summed venue-wide,
that guard passes while the kitchen tin is empty and the owner's tin is full —
the supervisor is told to go ahead, and there are no notes in the drawer they
are standing at. The balance had to become **per box** or the check would have
started lying on the day the second box appeared.

**A name is content, not copy.** A box is called *Kas Dapur* because the venue
calls it that. It is a zone name, a menu item name — never an ARB key, never
translated, and never a closed set the way [[Kategori pengeluaran|CashCategory]]
is (ADR-0085 keeps *codes* crossing the layer; this is not a code).

**A closed month must still name where the money came from.** So a box is
retired, never deleted, exactly as a [[Preset diskon]] and a visit-expense
category are.

**Moving money between two tins is not a purchase.** It is the movement that
most obviously needed a name, and the one most likely to corrupt a report if it
got the wrong one: booked as an expense it becomes a cost the venue never
incurred, and it lands in whatever category the cashier picked.

## Decision

**One ledger, several boxes.** `cash_boxes` is a venue-authored catalogue —
id, name, `active`, `sortOrder` — shaped like `VisitExpenseCategories` and
`DiscountPresets`. `cash_entries.box_id` is **NOT NULL with a default of
`box-main`**, which is the box every pre-v73 row was backfilled to and the one
every venue starts with, named **Kas Utama**. Seeded on create, on the v73
upgrade and on every Server boot, so no path can leave a venue with nowhere to
file a movement.

**Every balance is `SUM(delta)` over one box**, and the ADR-0088 refusal is
checked against that box alone, inside the write transaction (ADR-0100). The
venue-wide arm of `cashBalance` exists for the report's totals and **no guard
may use it**.

**A transfer is two ordinary rows, not a fifth `CashEntryKind`.** An `expense`
out of the source and a `topUp` into the destination, linked by
`transfer_peer_id`, written in one transaction by `transferCash`. Every reader
that already sums a box therefore needs no new arm. Neither leg carries a
category — nothing was bought — so `byCategory` never sees one. It audits
**once**: two rows are one act seen from two tins, and two audit lines would
read as two transfers. Its capability is `editSettings`, not `manageCash`: a
transfer funds a tin, and the supervisor who may empty one must not be able to
quietly refill it.

**A transfer is reversed whole.** `reverseCash` follows `transfer_peer_id` and
undoes both legs in one transaction, refusing if either is already reversed.
Reversing one leg alone would leave money standing in the destination that never
left the source — the venue total, the one number no single-box bug could
corrupt, would start to lie.

**Retiring is refused while the box holds money** (`box_not_empty`, carrying the
balance), the posture the console takes to removing the `members` module with
debt outstanding. Hiding a tin from the picker must never hide rupiah with it.

**Every venue figure in the Kas report is the sum of the boxes.** That is what
makes a transfer vanish from the totals with no rule to exclude it: the legs are
equal and opposite. Per box they are counted, because a transfer *is* real
movement for that tin. `byCategory` stays venue-wide — a category says what was
bought, not which tin paid.

**Authority stays venue-wide.** `manageCash` spends from any box, `editSettings`
funds, counts, transfers and manages the boxes themselves. A per-box ACL is a
join table and a check on four routes, for a distinction no venue has asked for;
the audit trail already names both the actor and the box.

**No module or mode key.** One box is the degenerate case of N, not a different
feature. A key would also have to fail closed (ADR-0109) and would hide an
existing venue's box on the venue that never phoned home.

**The audit line names the box.** `{box}` joins the params of `cashToppedUp`,
`cashSpent`, `cashCounted` and `cashReversed`, and the v73 migration backfills
`"box": "Kas Utama"` into every existing `cashMovement` row — `auditText` renders
a missing param as an empty string, so without the backfill an upgraded venue
would read half a sentence. Five kinds are new and, like every `AuditKind`, may
never be renamed: `cashTransferred`, `cashBoxCreated`, `cashBoxRenamed`,
`cashBoxRetired`, `cashBoxReopened`.

**The client caches nothing.** Unlike the venue settings of ADR-0128, `/kas` is
tablet-only, admin, and has no offline path: a derived balance somebody is about
to count against comes from the host or not at all. The WS frame carries **one
box's** balance and the client re-sums the venue total, which is what makes a
transfer's two frames correct in either order.

**The screen hides itself when there is one tin.** The selector, the transfer
action and the report's per-box breakdown all appear only above one box. A venue
that keeps a single tin sees the screen it has always seen.

## Consequences

The day's opening and closing ritual funds and counts the venue's **first active
box** only. That is what it did before this ADR, and a venue with several tins
counts the rest on `/kas`; a box picker belongs in that sheet the day someone
asks to close two at once.

Two boxes make it possible to hold cash the day ritual never counts. That is a
property of keeping several tins, not of this design, and the per-box closing
figures in the Kas report are where it becomes visible.

Nothing here reaches revenue. ADR-0089 stands unchanged: the boxes are still a
float that only ever pays out, still isolated from `netTotal`, `settledTotal`,
Bruto and the payment mix, and still nothing to do with the drawer or with a
[[Pengeluaran kunjungan (visit expense)]].
