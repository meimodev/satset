# Offline orders and bill settlement repair

Status: implemented — 2026-09-10; verification continued 2026-09-11. The final
full-suite result is recorded below. The complete physical host/client matrix
remains to be completed; no Android device was connected on September 11.

## Problem

An offline order captured onto an existing host visit can lack the cached bill
needed for projection. Table detail also reads server tickets and the retired
send queue rather than journal-backed captured lines. The report's successful
cached-bill scenario establishes that seating online is not itself the failure
condition: the missing baseline is.

Source inspection also identified two replay gaps to verify and repair: delivered
events are deleted without advancing the cached bill, and the 60-second stock
replay threshold also gates whether captured ticket identities are honored.

## Accepted decisions

- Missing earlier bill history permits order capture and display of known lines
  and their subtotal, but blocks new payment and bill closure until history is
  recovered. Never treat that subtotal as the full payable bill. A stale cached
  baseline remains usable. See ADR-0140.
- The host supplies complete snapshots for active visits, including zero-line
  visits and actual visit metadata. Proactive caching includes empty visits;
  payable membership still requires billable lines. Empty bill reads must not
  silently relax existing mutation guards.
- This repair includes interrupted replay and stable captured identities, not
  only the two reported screen failures. Reconnection, retry and restart must
  preserve every captured line and payment exactly once in the local bill and
  after host reconciliation.
- Retain acknowledged events until an authoritative host result is saved
  durably. Install that result and retire only the events it includes in one
  local transaction; a successful send alone is not permission to delete the
  local representation of its effect.
- An explicit host refusal makes only the affected visit read-only until human
  resolution. Keep lines, captured money and refusal details visible and retain
  existing events. No new acts may append behind its parked chain. Transport
  interruption alone allows continued offline capture. See ADR-0141.

## Existing contracts this work must fulfill

- Captured lines appear as ordinary badged lines on the bill, table detail and
  `/orders`, with one shared interpretation of later voids and refusal state.
- Visit identity scopes the lines; a reused table must not absorb another
  party's orders. Host echoes must not duplicate captured ticket identities.
- A visit with an undrained chain continues capturing locally after the socket
  returns, unless it has an unresolved refusal under ADR-0141. A live write must
  not overtake its earlier captured events.
- Use the shared bill recomputation rules. Do not introduce a separate subtotal,
  tax, discount or payment model for offline settlement.
- Refusal halts and parks the affected chain; transport interruption preserves
  it for retry. Existing captured money is not discarded to repair missing
  history. ADR-0123 and ADR-0139 continue to govern those cases.

## Verification scope

- Online-seated empty visit, offline-created visit, and an online-seated visit
  with a cached bill containing earlier lines and payments.
- Missing history on an adopted visit: known orders remain visible, with no
  fabricated full total or new payment/close allowed.
- A zero-line host visit carrying a reservation member retains that metadata;
  a nonexistent visit cannot masquerade as an empty one.
- Order then void, with both events retained for replay and the displayed bill
  reflecting the void.
- Reconnect within 60 seconds: captured visit/ticket references remain valid
  for following voids and receipt assignments without relaxing stock rules.
- Disconnect after only an order reaches the host; disconnect after payment;
  restart in each state. Local bill history must remain complete.
- Host commits but response is lost: retry creates no duplicate food or money.
- Events appended during replay remain ordered and are not deleted by a
  checkpoint belonging to an earlier prefix of the chain.
- Successful reconciliation replaces local captured state without duplicate
  lines, lost payments, or a false outstanding amount.
- Explicit refusal blocks further mutations of that visit across screens and
  repository entry points, including after restart; other visits still work.
  A transport timeout does not impose the same restriction.
- Closed-visit completion and venue/member-only chains can finish without
  depending on a nonexistent live bill endpoint.

## Durable replay and recovery

Keep the original baseline and acknowledged events until a replacement snapshot
is installed. Project acknowledged events locally, but do not send them again.
Folding each successful send into a predicted baseline was considered; retaining
events avoids reconstructing unknown earlier history or treating a prediction
as the host's actual result.

Serialize sending and snapshot installation per visit. Record the exact event
prefix covered by a synchronization pass, pause further sends for that visit
while fetching its authoritative snapshot, and atomically install that snapshot
and retire only its acknowledged prefix. Events captured after the boundary
remain ordered and project onto the replacement baseline. Sequence allocation
must also be safe when capture and replay overlap.

A timeout after a possible host commit remains ambiguous. Resolve it by retrying
the same idempotency key before taking a snapshot that might already include
that effect. Do not blindly combine a host snapshot with ambiguous pending
payments or refunds. Ticket deduplication alone cannot make that safe.

If fetching or saving the replacement fails, retain the baseline and journal
and keep the visit locally authoritative. On an adopted visit with no baseline,
known lines stay visible but new payment and closure remain blocked until a
valid baseline is installed. Recover on reconnect through the same ordered
replay; do not invent missing history or discard existing captured money.

Preserve refusal records separately from successful-prefix cleanup so the
read-only restriction and the human report survive restart. An acknowledged
prefix must not cause the refused or untried suffix to disappear.

Completion must account for closed visits whose successful close removes the
live visit: use an authoritative closed-session result or explicit closure
confirmation rather than treating an arbitrary GET 404 as success. Venue-scope
member events have no bill to fetch and retain their existing separate terminal
path and authority exception.

## Implementation order

1. Add focused reproductions for the missing-baseline capture path, journal
   visibility, interrupted replay and replay within 60 seconds.
2. Establish complete empty-visit snapshots and proactive discovery/caching;
   enforce the missing-history settlement boundary in repository and UI paths.
3. Preserve captured identities independently of the stock replay threshold,
   then implement durable acknowledgment and snapshot installation together
   with refusal guards and restart recovery.
4. Expose a shared reactive view of captured and host ticket state to bill,
   table detail and `/orders`, retaining void/refusal semantics and deduplicating
   host echoes by stable identity.
5. Run focused tests and `flutter analyze`, then repeat the report's device
   matrix with exact totals and an interrupted reconnect/restart cycle. Verify
   both the offline result and the final host state.

## Implementation and verification record — 2026-09-10

- Complete empty-visit snapshots and active-visit discovery now preserve the
  visit metadata while keeping empty visits out of the payable list. Empty
  bill closure still returns `no_lines`. Staff with `takeOrder` may read
  snapshots; settlement mutations keep their existing capability guards.
- Client-minted visit/ticket IDs are honored immediately. The historical stock
  threshold remains independent. Repeated offline taps reuse the stored IDs.
- The journal retains acknowledged effects through snapshot failure and restart.
  Bill replacement and retiring the covered event prefix share a transaction;
  concurrent captures keep unique sequence numbers and retain their suffix.
- Floor snapshots are fetched and persisted before retiring captured floor
  events. Orders, table detail and bills display captured lines; host echoes
  deduplicate by ticket identity. Visit expenses use the same ordered journal.
- Missing history displays known lines without payment or close controls.
  Explicit refusal preserves captured food/cash and its delivered prefix, and
  blocks new acts until human resolution. Other visits remain writable.
- Successful online closure is handled as a closure confirmation, avoiding a
  duplicate captured close caused by parsing the response as a bill.

Evidence:

- Focused affected batch: **94 tests passed** (capture, host replay, bill UI,
  projection parity, design tokens, resync and expense panels).
- Offline repair regression file: **10 tests passed**, including production
  journal-provider checks for stock refusal and durable floor checkpointing.
- Lost-payment-response test exercises the real host routes and idempotency
  middleware: after client-journal restart and retry there is one payment,
  Rp116,550 paid, and zero outstanding.
- `flutter analyze`: **no issues**.
- `flutter build apk --debug`: **passed**. The APK was installed with `adb
  install -r` on `emulator-5556`, preserving existing app data.
- A pre-existing table-counter test exposed a wall-clock timing assumption
  under load. Its assertion now checks that the seconds tick changes the
  counter without rebuilding the table body; all **3 tests** in that file pass.
- Final full suite, 2026-09-11: **1,396 passed, 3 skipped, zero failures**.
  Static analysis also passed again with zero issues.

Device evidence: after an initial Android launcher ANR and ADB timeouts, the
upgraded emulator cold-launched SatSet and restored the offline P1 session.
Opening D2's bill displayed the missing-history explanation without payment
controls or the old load error. A read-only journal inspection confirmed that
the existing D3 order/payment/close chain and D1 order survived the upgrade;
there was no remaining D2 order event in that device's journal.

Device limitation: this does not establish the complete A/B/C matrix or
physical-host reconciliation. The host APK has not been replaced. The D3
table-detail check was interrupted, and no Android device was connected when
work resumed on September 11.

CodeGraph: repaired the desktop launch path and disabled the hanging shared
query daemon through the supported `CODEGRAPH_NO_DAEMON=1` setting. A real MCP
probe succeeded. The project index was synced after implementation, with no
pending changes, unresolved references, or worktree mismatch.
