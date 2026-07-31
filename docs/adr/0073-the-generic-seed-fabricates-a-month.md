# The generic seed fabricates a month, and the prompt is mandatory

Status: accepted

**Supersedes [0052](0052-demo-seed-a-venue-mid-service.md) and [0053](0053-organic-demo-data-and-the-demo-clock.md).**

ADR-0052 built a second dataset — the demo seed — deliberately separate from the [[Generic seed (sample data)|generic seed]], and §1 refused outright to merge them: *"an owner tapping 'load sample data' on their opening day must not inherit somebody's invented walkouts."* Two datasets, two endpoints, two Venue Hub banners, a demo clock propagated to every paired device, and a live half that had to be held at the age it was authored for.

Two things turned out to be true about the split that were not obvious when it was made.

First, **the generic seed on its own is not worth loading.** It seeds reference data and nothing else, so a venue that takes it sees an empty [[Reports|report]], an empty [[Venue audit log]], an empty stock history, and no way to tell whether any of those screens work. The thing an owner actually wants from "load sample data" is to see the app full.

Second, **the protection ADR-0052 §1 bought was already bought twice.** §3's has-not-traded guard refuses on any venue with a single [[Ticket]] or archived session, and §4's tagging means every fabricated row can be removed without touching a real one. The separate endpoint was a third lock on a door with two.

Meanwhile the audit log was empty either way: the demo seed calls `submitOrder` and inserts its settlements directly, so it bypasses every route handler — and every `writeAudit` call site lives in a route handler.

## Decision

1. **One dataset, one action.** `seedSampleVenue` / `POST /seed/generic` seeds the reference half *and* a fabricated month. `seedDemoVenue`, `/seed/demo` and `/seed/demo/reset` are gone. `seedGenericRestaurant` survives as the reference-only half that the sample seed runs first — it is no longer reachable on its own from the UI.

2. **The guard and the tag carry the whole safety story.** ADR-0052 §3 and §4 are kept verbatim: the seed refuses on a venue that has traded, and every fabricated row carries an id prefix (`contoh-`) so the clear deletes by tag and never truncates a table. A real order written on a seeded venue afterwards carries no prefix and survives. What ADR-0052 §1 protected against is now protected by these two plus decision 3.

3. **The clear is transactional-only.** `POST /seed/clear` removes the invented bills, tickets, sessions, stock movements, receipts, payments and audit rows. Zones, tables, menu, staff and bahan stay. This is what an owner actually wants — keep the menu, lose the fake sales — and it means no reference row needs a tag it does not have. A zone or an item they do not want, they delete by hand. Rejected: tagging the reference half too, which buys a truer "undo" at the cost of a `sampleSeeded` column across every reference table and losing an owner's edits to the seeded menu.

4. **History only. The live half is dropped, and the demo clock dies with it.** ADR-0052 §5 and ADR-0053 §1–§4 existed to hold a mid-service snapshot at the age it was authored for: open tables, tickets mid-prep, a course running late, alerts at escalation, all computed from `now − timestamp`. Dropping the snapshot removes the reason for the clock, and with it the whole propagation — `MeDto.demoClockOffsetSeconds`, the `demo.clock` broadcast, every client calling `SatClock.adopt`, and ADR-0053 §4's accepted hazard that *"a device pairing into a demo venue inherits demo time, including a real staff phone."* A seeded venue now runs on real time, always. The floor and KDS states the live half staged are reached by hand, which is what they cost before ADR-0052 and what they are worth.

   `SatClock` **stays** as the seam. Its 120 call sites are untouched; the offset is simply always zero.

5. **Backdating stays explicit, never global.** ADR-0053 §5's `at` override on `submitOrder` and the three in `stock.dart` are the mechanism, and `writeAudit` gains the same pair — `at` and `idPrefix`. Walking `SatClock` through the month instead was considered and rejected for the reason already written into `seed_history.dart`: seeding runs while the app is live, and dragging the process clock swings the running UI's time and fires alerts against nonsense.

6. **The seed authors its own audit trail, both halves.** Nothing comes free, so the month writes `fire` and `modify` alongside its sends, `voidItem` / `discountApplied` / `paymentRecorded` / `billClosed` alongside its settlements, and a hand-authored scatter of admin rows across the month — `staffCreated`, `staffRoleChanged`, `staffPinReset`, `roleRenamed`, `roleCapabilityChanged`, `menuKilled`/`menuRestored`. The admin half is not decoration: ADR-0072 hides exactly those types behind `manageStaff`, and a gate with nothing behind it cannot be seen to work.

7. **The reference half grows to a venue worth looking at.** 4 zones (Dalam / Luar / Teras / VIP), 20 tables at pax 2–10, ~42 menu items across the eight real categories, each with a resep, the bahan to back it and a weight in the mix table. `D1`/`D2`/`L1`/`L2` and every existing item id are unchanged — the seed is idempotent and re-postable, and renaming them would orphan an existing install. Volume stays at ~1500 bills over 30 days rather than scaling with the floor: reports read totals, not per-table density, and seed time is already minutes.

8. **The first-run prompt is mandatory, blocking, and asked exactly once.** An empty venue opening the Venue Hub gets a non-dismissible dialog — no barrier dismiss, no back button, two actions: *Muat contoh data* / *Lewati*. It replaces both banners. The answer is stored **server-side and venue-wide**, because "never ask again" is a property of the venue: skipping on the tablet must also skip on the phone.

9. **Skipping is permanent, so Admin → Sistem carries a permanent way back in.** CONTEXT.md had claimed such an action existed since ADR-0017; it never did. Without it, one tap on *Lewati* would put the sample data out of reach forever.

10. **The prompt is answered on completion or on skip — never on tap.** A job takes minutes and there is no resume (ADR-0053 §9). If the host is backgrounded or reclaimed mid-run, the question was never actually answered: the dialog returns on the next boot, reads `complete == false`, and offers *Hapus & muat ulang* / *Lewati*. Writing the flag when the job starts would leave a venue holding half a month with no surface anywhere offering to clear it.

11. **Progress lives in the blocking dialog, not in a hub banner.** A determinate bar, `hari 12/30`, the keep-app-open line, then *Selesai*. The job dies if the app is backgrounded, so the honest UI keeps the admin on the dialog rather than letting them wander into a venue that is twelve days into a month and looks broken.

## Considered options

- **Keep the split and just enrich the demo seed's audit trail** — no ADR needed, no migration. Rejected: it leaves the generic seed as the thing an owner actually taps and the thing that shows them nothing.
- **One button, history behind a toggle** — single endpoint, a "sertakan riwayat contoh" switch. Rejected: it re-introduces ADR-0052 §1's two datasets as two code paths behind one control, and the guard already answers the question the toggle was asking.
- **One seed, no guard, no tagging** — clear means wipe. Rejected for ADR-0052 §4's original reason: a destructive path whose safety rests on one predicate being exhaustive is the wrong thing to ship in release builds.
- **Clear everything the seed wrote, reference half included** — a truer undo. Rejected per decision 3.
- **Keep the live half without the clock** — seed it once and let it rot. Rejected: a day later every table reads hours-basi and every alert pins red, which is worse than not staging those states at all.
- **Walk `SatClock` through the month while seeding** — fewer parameters on production signatures. Rejected per decision 5; it also means unpicking threading that already works.
- **Escapable prompt** — softer, lets the admin look around first. Rejected: "mandatory" that a stray tap escapes is not mandatory, and the flag would then only be written on an explicit choice.
- **Device-local skip flag** — no server change. Rejected per decision 8: it makes "never again" mean "never again on this tablet", which is a different promise.
- **Interrupted-job banner on the hub** — the alternative to decision 10. Rejected: two surfaces where one does, and answering-on-completion is strictly more correct anyway.

## Consequences

- A schema migration (v44) drops `demo_states.anchor_at`, adds `prompt_answered`, and **deletes any `demo-` tagged rows outright** on an upgrading device. Migrating them is not worth it: their ids carry a tag the new clear path does not know, so leaving them in place would strand rows nothing can delete. The guard means such a venue never traded for real.
- `MeDto` loses a field and the WS vocabulary loses `demo.clock`; `demo.progress` becomes `seed.progress`. Host and client ship together, so this is a rename rather than a compatibility problem.
- ADR-0052 §8's state table is no longer the scope. Floor, KDS and bill states are reached by driving the app; reports, the audit log and stock history are what the dataset is now for.
- The seeded month is ~1500 bills, several thousand audit rows and ~20k stock movements written through the production path — still a multi-minute operation and a materially larger DB file.
- Every new menu item the seed gains needs a resep, bahan and a weight, or it looks like a slow seller and may reject lines for want of stock. The seed fails loudly if more than 2% of planned lines are lost that way.
- The prompt fires on the Venue Hub only, which is server mode — a client device never sees it. Correct: seeding is a host act.
