# Per-item ready target, and the course is the unit of "late"

Amends [ADR-0013](0013-ticket-lifecycle-timestamps-and-service-target.md), which deliberately chose **one** configurable threshold (`prepTargetMins`) so the floor alert and the report SLA could never drift apart. That invariant bought real safety and is not being discarded — it is being restated one level down.

Two changes:

**1. The target resolves per line.** `MenuItems.prepTime` already existed (since v1, default 5) and was written by the seed and the item editor but **read by nothing**. It becomes the per-item ready target ("Waktu siap"), relaxed to **nullable**: null means *inherit `VenueSettings.prepTargetMins` live*, a value is a deliberate override. Inheritance is a live reference, not a copy — moving the venue default moves every non-overridden item, which is the whole point of keeping a venue-level lever once items can differ. `prepTargetMins` survives, reframed as "Target siap (default semua menu)".

Granularity is **item only**. Variants and modifiers can genuinely differ (a bigger cut, a well-done steak), but the course target is a `max` across lines, so a few minutes of variant delta almost never changes which line paces the course — it would be config surface with no signal. `resolvePrepMins` is a single function, so adding a dimension later changes one call site.

**2. The unit of "late" is the course, not the line.** A course's target is the `max` of its lines' resolved targets, and it is ready when its *last* line is ready. Per-line lateness was defensible when every line shared one threshold; with per-item targets it becomes actively wrong for the `sides` course — literally named "Bersama Utama" — which would be flagged late at 6 minutes for correctly waiting on the 25-minute mains it plates with. A cue that fires when staff are doing the right thing is the worst kind of false alarm, because it is technically accurate, and it trains people to ignore the cue.

The report SLA moves to the same unit: **% of courses that hit their own target**, not % of lines against one number. Keeping the alert per-course and the report per-line would have reproduced exactly the drift ADR-0013 existed to prevent.

**Supporting fix.** `Tickets.firedAt` (nullable) is stamped on the `held → sent` fire. `sentAt` was never re-stamped there, so a course held at 19:00 and fired at 19:40 arrived 40 minutes old and was instantly overdue against any target. The prep clock is now `readyAt − (firedAt ?? sentAt)`; `sentAt` keeps meaning "when the guest ordered" (it is the KDS card-grouping key per ADR-0008 and the line time on the struk, so re-stamping it would have corrupted both). `CourseTimings.firedAt` previously *derived* itself from the earliest `sentAt` — it now reads the real column.

## Consequences

- **An item's target stops being independently measurable** once it shares a course with something slower. `slowItems` therefore keeps its per-item averages but **loses its pass/fail colouring** — colouring it against each item's own target would red a `sides` item permanently for correctly waiting. It is now a neutral ranked diagnostic.
- The report headline can no longer name a number ("siap di bawah target 15 menit" → "kursus siap di bawah target masing-masing"). The SLA *percentage* is still a single honest figure; only the target stopped being scalar. `speed.prepTargetMins` still ships, as the venue default.
- Migration v37 rebuilds `menu_items` via `TableMigration` (SQLite has no ALTER COLUMN). Rows sitting at exactly the old default `5` are nulled — treated as untouched, so they inherit — while any other value is preserved as a deliberate override. This cannot distinguish a genuine 5-minute item from an untouched one; the generic seed uses no 5s, so seeded venues migrate cleanly, and the cost of a wrong guess is one item inheriting 15 instead of 5.
- Targets **live-resolve against the current menu** in reports, like allergens (ADR-0012) and unlike modifier snapshots (ADR-0011). History is re-judged when a target changes, not re-priced. Snapshotting the target per line was the alternative; live-resolve keeps the report answering "against today's standard".
- `TableSessionTickets` gains `firedAt` so the snapshot can measure the same way after live tickets are deleted.
