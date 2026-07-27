# Demo seed: a venue mid-service, separate from the generic seed

Status: accepted

Every screen in this app has states that only exist against **transactional** data: a [[Basi (stale)|basi]] table, a late course on the [[KDS / Antrian Persiapan|KDS]], a [[Split bill|split]], a [[Walkout (tak tertagih)|walkout]], a stock-driven [[Habis / Sold out (menu item out of stock)|habis]], a [[Reports|report]] with real settled figures, an [[Audio alert|alert]] at its second escalation. None of them can be reached from the [[Generic seed (first-run sample data)|generic seed]], which by design seeds reference data only. Reviewing or demoing those states today means hand-driving a live venue through an hour of service, once per state, per device.

The obvious move is to enrich the generic seed. That is the one thing this ADR refuses to do.

## Decision

1. **A second, separate dataset — the [[Demo seed (venue mid-service)|demo seed]].** `seedDemoVenue` / `POST /seed/demo`, distinct from `seedGenericRestaurant` / `POST /seed/generic`. The generic seed keeps its contract unchanged: reference data, no fabricated history, safe to load into a venue that is about to trade for real (ADR-0017, ADR-0042 §1). The demo seed is the opposite contract — it deliberately fabricates a venue mid-service — and the two must never be the same call, because an owner tapping "load sample data" on their opening day must not inherit somebody's invented walkouts. The demo seed runs the generic seed first and builds on top of it.

2. **Production-reachable, not debug-gated.** It ships in release builds, hangs off the Venue Hub beside the existing seed action, and is gated on `manageStaff` like `/seed/generic`. Demoing the app to a prospective venue, and reviewing UI on a real device, both happen on release builds; a `kDebugMode` gate would make the feature useless exactly when it is most wanted. The safety therefore rests entirely on decision 3.

3. **It hard-refuses on a venue that has traded. The predicate is "any ticket row **or** any archived session exists."** A venue with a single [[Ticket]] has real service history, and the demo seed returns a refusal rather than writing anything. The archived half of the predicate is not redundant: closing a bill **hard-deletes** the live tickets into `TableSessions` (ADR-0024), so a venue with a month of genuine trading and no open orders has *zero* ticket rows. A ticket-only guard would wave that venue straight through and bury real history under fabricated history — the exact outcome this ADR exists to prevent. Deliberately *not* "any stock movement exists": the generic seed already writes one opening `receive` per [[Bahan (Ingredient)|bahan]] (ADR-0042 §1), so that predicate would refuse on precisely the freshly-seeded venue this feature targets. Because the demo's own rows trip the guard, a re-seed requires a reset first — which is correct, not incidental.

4. **Demo rows are tagged; reset deletes by tag.** Every row the demo writes carries a `demoSeeded` marker, and reset removes them by that marker. This costs a Drift schema version bump and a migration across the transactional tables. The cheaper alternative — wipe the transactional tables wholesale, justified by the guard proving there was nothing real to lose — was rejected: the guard protects against *known* trading history, and a destructive path whose safety depends on one predicate being exhaustive is the wrong thing to ship into release builds. Tagging fails safe; wiping fails catastrophically.

5. **Two clocks, two populations.** The dataset splits in half, and they age differently:
   - **Historical** — roughly a month of settled service behind today. A twelve-day-old bill is still twelve days old tomorrow, so this half does not decay.
   - **Live** — the snapshot of *now*: open tables, tickets mid-prep, a course running late, alerts at escalation. Every one of these is computed from `now − timestamp`, so they are authored relative to seed time and go stale within minutes. Left alone overnight, every table reads hours-basi and every alert pins red.

   Reset therefore regenerates the **live** half by default and leaves the historical half intact. A full reset (both halves, all tagged rows) exists separately. The alternative — injecting a frozen clock so nothing decays — was rejected: it means threading an injectable `now` through every elapsed-time computation in the app, which is real surgery on production code to serve a demo.

6. **Historical sales deduct stock honestly, and the demo seeds the restocks to match.** A month of sales through the ADR-0041 path would drive every balance far negative against a single opening `receive` — and `overrideStock` is deliberately ungranted (ADR-0042 §7) precisely so balances cannot drift negative. So the demo writes periodic `receive` movements across the month, **sized from the consumption its own seeded sales actually produce**, not guessed. `Σ movements == stockOnHand` holds across the whole window, and the stock history reads like a venue that has been buying and selling for a month. Rejected: skipping deduction on historical tickets (breaks the invariant the ADR-0041 tests pin), and making history settlement-only with no line-level consumption (reports work, but a month of sales that consumed nothing is incoherent the moment anyone opens stock history).

7. **Realistic volume, fixed seed.** ~30–80 tickets/day across the month — one to two thousand tickets and several thousand lines — because a report built from ten tickets a day does not look like the report an owner will actually read, and volume is the point of the reports half. The RNG is seeded to a fixed constant, so the dataset is byte-identical run to run: screenshots are comparable, a bug found in a demo state is reproducible, and goldens are possible later.

8. **Scope is the enumerated state list, not "all states."** The dataset is authored to reach, and is complete when it reaches:

   | Area | States |
   |---|---|
   | Tables / floor | kosong, terisi, [[Dipesan (table hold)|dipesan]], basi, [[Terlambat (reservation late)|terlambat]], [[Table lock|locked]], [[Reservasi berikutnya (next booking)|reservasi berikutnya]] |
   | KDS | pending, fired, late course, ready, multi-station, batch |
   | Orders / bill | open, split, settled, walkout, [[Void (item)|voided]] line |
   | Menu | habis, [[Unavailable]], stock-driven habis, recipe-less |
   | Reports | non-empty month, real settled figures |
   | Alerts | each channel, each escalation step |

## Considered options

- **Enrich `seedGenericRestaurant` in place** — one dataset, less code, no second endpoint. Rejected: it overturns ADR-0042 §1 and ADR-0017's "no fake report history", and the venue that loads it on opening day inherits fabricated bills it must clean up before trading.
- **Widen UI-level stub fixtures instead of touching the DB** — no schema change, no seed at all. Rejected: stubs reach shared widgets, not whole screens fed through repositories and WS. The states in decision 8 are properties of the data flowing through the stack, and testing them anywhere but the DB tests something else.
- **Debug-build-only demo seed** — no guard needed, zero release-build risk. Rejected per decision 2: demos and device review happen on release builds.
- **Frozen/injectable clock so the live half never decays** — correct forever. Rejected per decision 5: invasive surgery on production code for a demo affordance.
- **Wipe transactional tables on reset instead of tagging** — strictly less code, and the guard means there is nothing real to lose. Rejected per decision 4.
- **Today-only history** — no month to author, no restock arithmetic. Rejected: reports over any range wider than a day read as a single spike against empty days, which is a worse impression than an empty report.

## Consequences

- A schema migration lands on a shipped DB to carry `demoSeeded` across the transactional tables. Every future table the demo writes to must carry the marker or reset silently orphans its rows — the failure mode is leftover demo data, not lost real data, which is the direction chosen deliberately.
- Seeding writes thousands of rows in one transaction on mid-range Android. Expect a multi-second operation with progress UI, and a materially larger DB file on demo devices.
- The demo seed depends on the same production write paths the generic seed does (`receiveStock`, the ADR-0041 deduction path), plus the ticket and settlement paths. A change to any of their shapes breaks the demo seed loudly — the intended coupling, same as ADR-0042.
- The restock sizing in decision 6 is derived, not authored: it must be computed from the generated sales, so the generator runs sales first and stock arrivals second. Authoring restocks by hand would silently drift the ledger.
- The guard means a venue mid-demo cannot re-seed without resetting. This is the correct behaviour and will be reported as a bug at least once.
