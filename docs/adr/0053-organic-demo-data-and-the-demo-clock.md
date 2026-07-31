# Organic demo data and the demo clock

Status: superseded by [0073](0073-the-generic-seed-fabricates-a-month.md)

**Amends [0052](0052-demo-seed-a-venue-mid-service.md).** ADR-0052 built the [[Demo seed (venue mid-service)|demo seed]] and accepted two compromises to keep it cheap: the live half decays and is repaired by pressing **Segarkan**, and the fabricated month is written as direct row inserts with statistically flat contents. Both turned out to be the wrong trade once the dataset was used. A demo opened the next morning shows every table hours-basi until someone remembers a button, and the reports it produces are visibly synthetic — a flat hourly curve, cocktails selling as fast as rice, no drink attached to a main.

This ADR replaces the decay-plus-refresh model with a **demo clock**, and the flat generator with a **hand-authored distribution written through the production order path**.

## Decision

1. **A demo clock replaces the refresh button.** The host stores a demo time offset and every device routes its `now` through it. On boot the offset is re-anchored so app-now equals the instant the demo was seeded, and then **time runs forward normally** — timers tick, alerts escalate, the demo ages during the session, and it re-anchors the next time the app opens. ADR-0052 §5's live/historical split therefore stops being a *refresh* concern: nothing decays, because the clock keeps the whole snapshot at the age it was authored for. `POST /seed/demo/refresh` and the **Segarkan** action are removed.

2. **The offset is server-authoritative and pushed to clients.** Elapsed time is computed on whichever device renders it — `table_card`, `elapsed_pill`, `kitchen_screen`, `reservations_surface`, `cashier_bill_screen`, the top bar — and in a real demo those are a paired waiter phone and a KDS tablet, not the host. A host-only clock makes the tablet read "34m" while the phone reads "3 days", which is worse than the decay it replaces. The host ships the offset in `/auth/me` and broadcasts it on change; every device reads `now` through a single `SatClock` seam instead of calling `DateTime.now()` directly.

3. **The demo clock stamps domain writes; security always uses the real clock.** A demo device is a working POS and someone will take an order on it, so `sentAt`, `firedAt`, `readyAt`, `closedAt`, payment `at` and audit `at` run on demo time — otherwise an order sent during the demo is stamped days after the table it joins and reads as instantly overdue. **JWT `issuedAt`/`expiresAt`, session validation, pairing-token expiry and TLS cert validity always use the real clock.** A rewound auth clock means tokens that should have expired keep validating and the short-lived pairing window stops being short-lived — an authentication defect that outlives the demo, not a demo feature.

4. **The clock is bound to the demo data.** It is active exactly while demo data exists, and `Hapus` clears both. There is no separate toggle: demo data with a real clock is the decayed state this ADR exists to remove. The accepted consequence is that a device pairing into a demo venue inherits demo time, including a real staff phone — so a venue holding demo data is not a venue to take real orders on, and the demo data's own presence is the only signal.

5. **History is generated through the production order path.** Sends go through the same submission code as a waiter's order rather than direct inserts, so recipe resolution, variant and modifier snapshots, stock checks and per-ticket consumption are exercised for real. ADR-0052 §6's daily stock roll-up dies with it: movements are now **per ticket**, roughly 20k rows rather than 1.1k. The live half routes the same way — it is nine lines and free.

6. **A hand-authored distribution table drives what gets ordered.** Per-item popularity weights, per-category attach rates (a drink on most covers, dessert on roughly a third, starters around half), an hourly arrival curve with lunch and dinner humps, and a party-size distribution that drives line count. It is authored beside the seed data and tuned by hand, because the failure mode is a human looking at a report and saying "nobody orders that much rendang" — and only an explicit table lets them fix it. Derived heuristics were rejected: a guess dressed as a model that nobody can adjust per item.

7. **Volume stays at ~1460 bills.** Realistic volume was chosen in ADR-0052 §7 when sends were cheap inserts; routing them through the real path makes seeding a multi-minute operation on a tablet. The volume is what makes the reports look like a real venue's month, so the cost is paid rather than the dataset thinned.

8. **Seeding becomes an async job with WS progress.** `POST /seed/demo` returns 202 immediately; the server runs the seed and broadcasts progress; the Venue Hub shows a progress bar and enables `Hapus` when it lands. A four-minute blocked HTTP call gives no way to distinguish slow from wedged, and the 5-minute client timeout was already marginal.

9. **An interrupted job is marked, not resumed.** A `demo-incomplete` marker is written when the job starts and cleared when it finishes. If the host is backgrounded, reclaimed or force-quit mid-run, the next boot finds the marker and the hub offers **only** `Hapus`. Partial data otherwise trips the ADR-0052 §3 guard — refusing a re-seed — while `hasDemoData` reports a loaded venue, so the reports look real and are quietly a fortnight short. Resume was rejected as real state machinery for a demo feature; the cost is losing the four minutes.

## Considered options

- **Shift the demo's timestamps forward instead of injecting a clock** — one UPDATE on boot, no client changes, nothing to propagate, deterministic, and visibly identical to decision 1. Rejected by the author in favour of a real clock after the trade-off was put twice; recorded here because it remains the cheaper path if the `SatClock` seam proves too invasive to maintain.
- **Frozen clock** (app-now pinned at the seed instant, never advancing) — simplest form of decision 1. Rejected: no elapsed timer ever ticks, lateness never climbs, alert escalation stops. A demo where nothing counts up is its own kind of obviously-fake.
- **Host-only clock** — no wire format, no client changes. Rejected per decision 2: it breaks precisely the multi-device demo worth giving.
- **Demo clock on auth too** — fully coherent. Rejected per decision 3; see the security note there.
- **Keep the real order path but keep flat data** (B without the distribution) — correct plumbing, invisible benefit. Rejected: nobody reading a report can see that a line went through `needForLine`, but everybody can see a flat hourly chart.
- **Cut volume to ~500 bills to pay for the real path** — seeding in about a minute. Rejected per decision 7.
- **Blocking seed with a longer timeout** — one line. Rejected per decision 8.
- **Resumable seed job** — respects the four minutes lost to an interruption. Rejected per decision 9.

## Consequences

- **`DateTime.now()` becomes a lint-worthy call in UI and domain code.** Every elapsed-time site moves to the `SatClock` seam; one missed call site is a screen that disagrees with the rest of the app, and the bug only appears on a demo venue.
- **A device that misses the offset broadcast is silently wrong** until it resyncs. The offset must ride the `/auth/me` bootstrap as well as the WS event, so a reconnecting device recovers on its own (the ADR-0021 resync posture).
- **Seeding takes minutes and writes ~20k stock movements.** The DB on a demo device grows substantially, and the seed exercises the production submit path 4771 times — a change to submission's shape now breaks the seed loudly, which is the intended coupling and a slower test suite.
- **Stock rejection becomes a real failure mode.** The production path refuses a line when stock is short, so the restock sizing derived in ADR-0052 §6 must hold against the new, non-uniform consumption; if it is ever wrong the dataset silently loses lines rather than failing. The seed must assert its planned line count against what actually landed.
- **Real orders taken on a demo venue carry demo timestamps** (decision 4). They are indistinguishable from seeded rows except by their untagged ids, and they survive `Hapus` — which deletes only tagged rows — leaving genuinely real rows stamped in the past with nothing explaining why.
- **The distribution table is a second authored dataset** that drifts when the seeded menu changes. A menu item added without a weight falls to a default and will look under-ordered.
