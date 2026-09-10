# Missing bill history is not an empty bill

**Status:** Accepted — 2026-09-09 — clarifies [ADR-0123](0123-an-offline-settlement-is-a-journal-not-an-intent.md) and limits the adopted-visit settlement promise in [ADR-0139](0139-a-captured-visit-is-authoritative-until-it-drains.md).

A device may capture orders for an existing visit without holding its earlier
bill history. An absent bill snapshot does not establish that the visit has no
earlier charges, payments, discounts or member attribution. Treating that absence
as an empty bill could produce a plausible total that silently omits them.

The device continues to capture and display known orders, including their
subtotal, but identifies the earlier bill history as unavailable. Until that
history is recovered, it must not present the known subtotal as the full payable
bill, capture a payment against that incomplete bill, or close the bill. This
restriction is about missing history, not about the presence of captured lines.

A visit created on this device, or one with a reliable empty baseline, remains
settleable offline. An existing cached bill may also be used when stale, under
ADR-0123's existing rules; freshness is not a new settlement requirement. An
empty baseline must preserve known visit metadata rather than assume that zero
orders also means no member or other bill context.

## Trade-off

We accept that a cashier already holding a visit with missing history cannot
finish settlement during an outage. Fabricating an empty bill or recording a
payment before recovering that history was rejected for this flow. Establishing
the baseline while online prevents future gaps but cannot reconstruct history
already missing from an offline device.

## Establishing the baseline

Accepted on 2026-09-10: the host supplies a complete bill snapshot for every
active visit, including visits with zero orders and their actual member and
other bill metadata. Clients proactively cache those snapshots; discovery must
include empty visits rather than depend only on the payable list. A nonexistent
visit remains distinct from an existing visit with an empty bill.

Empty visits show an appropriate empty state and enter the cashier's payable
list only when they have billable lines. Supplying an empty snapshot for reading
does not itself permit payment, splitting, or printing an empty bill.

The accepted recovery design is recorded in the
[repair plan](../plans/offline-order-bill-repair.md). This decision records the
product boundary, not completion of the implementation.

Order-taking staff may read these canonical snapshots so their floor journals
can finish reconciliation. The read routes accept `takeOrder` or `settleBill`;
payment, receipt and bill-close mutations retain their existing capabilities.
