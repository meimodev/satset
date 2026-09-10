# Offline orders and bill settlement — on-device test checklist

Created: 2026-09-11  
Status: **Not run against the complete repaired host/client pair**

This is the device acceptance checklist for the
[offline order and bill repair](offline-order-bill-repair.md), including
[missing-history handling](../adr/0140-missing-bill-history-is-not-an-empty-bill.md)
and [refused visits](../adr/0141-a-refused-visit-stays-read-only-until-resolved.md).
Automated tests passing does not mark any device case below as passed.

## 1. Devices and setup

- [ ] Install the repaired APK on **both the host and client**. Record the
  commit, version/build number, Android version, device model, and APK hash.
- [ ] Use a dedicated test venue and clearly named test tables/visits. Record
  simulated payments as test data; do not run payment or stock cases against
  live restaurant service.
- [ ] Use an Android tablet as host and a separate Android phone as client on
  the same LAN. An emulator is useful for fault injection, but does not replace
  the physical phone/tablet acceptance run.
- [ ] Have a cashier account, an order-taking account without `settleBill` or
  stock override, and a manager account for existing resolution workflows.
- [ ] Confirm pairing, authentication, online order delivery, and the host's
  kitchen/order view work before introducing a fault.
- [ ] Record venue settings: tax, service, discounts, member features, stock
  enforcement, expense mode, and kitchen bypass. Keep them fixed within a case.
- [ ] Use separate visits for independent cases. Preserve journal/database
  evidence before resolving a refusal or cleaning up test data.
- [ ] Record actual visit IDs, ticket IDs, receipt IDs, event IDs, timestamps,
  and starting bill totals. Table labels alone cannot identify a visit.

### Suggested fixtures

For the basic amount checks, disable tax, service, discounts, and member benefits.
Use these sample items if available, or equivalent items with recorded prices.

| Fixture | Starting state | Test action | Expected amount |
|---|---|---|---|
| A / D2 | Seated online, no lines; complete empty snapshot cached | Capture 1 × Lumpia at Rp55,000 | Total Rp55,000; after full payment, outstanding Rp0 |
| B / D3 | Empty table, client disconnected | Seat, capture 1 × Lumpia, pay, explicitly close | One visit, one line, Rp55,000 paid, outstanding Rp0 |
| C / D1 | Existing open visit with 10 × Krupuk at Rp15,000 and Rp150,000 already paid | Capture one additional Krupuk | Total Rp165,000; paid Rp150,000; outstanding Rp15,000 before the new payment |
| U | Existing host visit with earlier lines; its full snapshot unavailable on this client | Capture 1 × Lumpia | Known captured subtotal Rp55,000; full payable amount unknown; payment blocked |

For C, keep the bill open or reopen it through the existing authorized workflow
before capturing another order. Do not treat adding to a closed bill as supported.

## 2. How to introduce failures

### Manual failures

- Disable connectivity on the **client**, leaving the host running. Verify the
  app reports offline and that a request cannot still reach the host over an
  alternate connection. Record whether Wi-Fi-off or airplane mode was used.
- Reconnect the client to the original host, and record the elapsed offline time.
- For restart cases, force-stop and reopen the client **without clearing storage**.
  Include one device reboot. Swiping the app away alone is not sufficient evidence
  of process-death recovery.
- Make host-side conflicts from another authorized device while the client is
  disconnected, using the normal application workflow where possible.

### Controlled failures — developer support required

Cases marked **Controlled** need a test transport hook, instrumented build, or
equivalent deterministic setup. This checklist does not imply that such a hook
already exists. Mark a case **Blocked** if the required failure cannot be created.
Do not substitute a quick Wi-Fi toggle for proof of a precise commit boundary.

The setup must be able to:

1. Block a visit's bill-snapshot response while allowing its table identity to
   reach the client, to produce genuinely missing history.
2. Let a mutation commit on the host, then discard its response before the
   client receives it.
3. Interrupt after a specific event is acknowledged, before later events or the
   replacement snapshot complete.
4. Delay the snapshot, fail its fetch/write, or stop the client at the checkpoint
   boundary. Relevant reads include the bill, tickets, and tables.

Preserve the application's authentication and production TLS validation. Use a
test-only transport boundary rather than weakening the shipped security rules.

## 3. What every case must prove

For each applicable case, inspect **table detail, Orders, the bill, and the host**.

- [ ] Captured lines have the correct item, quantity, price, modifiers, note,
  course, author, and visit association. Their captured badge is visible.
- [ ] An offline captured line has not appeared in the host's kitchen before
  delivery. After delivery, its normal kitchen routing and course rules apply.
- [ ] Host echoes do not duplicate lines. A later void affects the same ticket.
- [ ] Complete bills agree on subtotal, adjustments, tax/service, total, paid,
  refunds, and outstanding. Missing history is explicitly identified and cannot
  be used to collect payment or close the bill.
- [ ] Navigation, refresh, background/foreground, and restart do not make
  captured food or recorded cash disappear.
- [ ] When reconciliation succeeds, the host has each act once; the durable
  local snapshot reflects it before the covered journal events are retired.
- [ ] A second reconnect produces no duplicate order, payment, refund, or expense.

Screenshots alone cannot prove exact-once delivery. For replay cases, also retain
read-only host records and client journal/snapshot evidence, or equivalent logs
that identify the individual acts.

## 4. Core order and bill cases

### DEV-01 — Upgrade and cold-start recovery

- [ ] **Steps:** Prepare pending captures on the previous build; record their IDs
  and amounts. Upgrade with app data preserved. Cold-start while offline.
- **Expected:** Existing session/floor data and captured acts remain available.
  No duplicated or silently deleted events. Repeat after a device reboot.

### DEV-02 — Complete empty snapshots and proactive caching

- [ ] **Steps:** Seat an empty visit online. Do not open its bill on the client.
  Confirm background caching through logs/read-only inspection. Repeat for a
  visit seated from another device and delivered through the table update.
- **Expected:** The actual zero-line visit snapshot is cached automatically.
  It is excluded from the payable list. An empty bill cannot be closed as paid.
  A nonexistent visit remains an error, not a fabricated empty bill.
- **Controlled extension:** Verify active-visit discovery also reaches an open
  visit absent from the client's current table list, such as a detached visit.

### DEV-03 — Scenario A: online-seated empty visit, then offline order

- [ ] **Steps:** Use fixture A with its empty snapshot confirmed cached. Disconnect,
  capture one Lumpia, open table detail, Orders, and the bill. Pay Rp55,000 offline
  and explicitly close. Reconnect.
- **Expected:** The line is visible immediately on all applicable screens; no
  bill-load error. One host visit, one ticket, one payment, and one closure.
  Final outstanding is Rp0.

### DEV-04 — Scenario B: seat, order, pay, and close entirely offline

- [ ] **Steps:** Use fixture B. Disconnect before seating. Seat, order, create the
  receipt, pay, and close. Restart offline before reconnecting.
- **Expected:** The same client-minted visit and ticket survive restart. The bill
  remains Rp55,000 paid with Rp0 outstanding. Replay respects seat → order →
  receipt → payment → close, and the host records each once.

### DEV-05 — Scenario C: preserve earlier lines and payments

- [ ] **Steps:** Cache fixture C's full bill. Disconnect, add one Krupuk, inspect
  all views, then pay the additional Rp15,000. Restart and reconnect.
- **Expected:** Before the additional payment: total Rp165,000, paid Rp150,000,
  outstanding Rp15,000. Afterwards: paid Rp165,000, outstanding Rp0. The earlier
  ten units and payment remain intact; no second collection of Rp150,000.

### DEV-06 — Missing history permits capture, blocks settlement — Controlled

- [ ] **Steps:** Prepare fixture U by blocking its snapshot before the client has
  cached one. Keep its real host visit ID available. Disconnect and capture the
  Rp55,000 line. Open all views and try receipt/payment/close entry points.
- **Expected:** The captured line and known subtotal are visible. The screen
  explains that earlier history is unavailable. Payment and closure are blocked;
  no made-up empty baseline is persisted. On reconnect, recover the complete host
  bill, including its earlier lines and payments, before permitting settlement.

### DEV-07 — A stale, known baseline remains usable

- [ ] **Steps:** Cache a complete existing bill. Leave it beyond the normal cache
  refresh interval, disconnect, capture an additional order, and settle.
- **Expected:** Age alone does not turn known history into missing history.
  Earlier amounts survive; local calculation and final host calculation agree.

### DEV-08 — Empty visit preserves reservation/member metadata

- [ ] **Steps:** Seat a reservation associated with a member, with no order lines.
  Allow the client to cache it, then disconnect and add an order.
- **Expected:** Actual guest/member identity and applicable attribution settings
  survive. No anonymous replacement visit or loss of metadata. With member
  benefits enabled, compare the final host calculation to the offline bill.

### DEV-09 — Shared line display and host-echo deduplication

- [ ] **Steps:** Capture multiple lines using different courses, quantities,
  modifiers, and notes. Navigate between table detail, Orders, and the bill.
  Reconnect while one of these screens stays open.
- **Expected:** All views represent the same captured tickets. Delivery removes
  the captured indication appropriately without a second row or a disappearing
  line. Existing host lines remain intact.

### DEV-10 — Capture an order, then void it

- [ ] **Steps:** Capture two different lines offline; void one with a reason.
  Restart offline, inspect the bill, then reconnect.
- **Expected:** Only the unvoided line is payable. Both order and void acts remain
  available for replay/audit. The host records the same ticket as voided with its
  reason and actor; it is not replaced by a newly generated ticket.

## 5. Reconnect, retry, and checkpoint cases

### DEV-11 — Reconnect in less than 60 seconds

- [ ] **Steps:** Capture a seat/order and a dependent act such as receipt
  assignment or void. Reconnect promptly, recording timestamps that establish
  the capture age is below 60 seconds.
- **Expected:** Visit and ticket IDs remain unchanged. The dependent act reaches
  the correct entity. Fresh captures still use ordinary stock enforcement.

### DEV-12 — Historical order replay with depleted stock

- [ ] **Steps:** Capture an order offline. Use a separate authorized host action
  to deplete the relevant stock. Keep the capture offline well past 60 seconds,
  then reconnect.
- **Expected:** Historical replay follows the established stock/audit policy for
  already captured food, preserving its IDs and amounts. Any override/debt
  evidence required by that policy is visible; food is not silently discarded.

### DEV-13 — Retry the same submission

- [ ] **Steps:** Retry one captured submission under its original idempotency key;
  include repeated reconnects and reopening the order screen. Use instrumentation
  if the UI cannot explicitly retry the same act.
- **Expected:** One event chain and the original ticket IDs. No second seat,
  receipt, or ticket. Deliberately submitting a new order is a different act and
  must not be confused with this test.

### DEV-14 — Host commits order, response is lost — Controlled

- [ ] **Steps:** Let the host commit a submitted order, discard its response, and
  let the client retain/capture the ambiguous act. Restart offline, then retry.
- **Expected:** One host ticket per captured line and one stock effect. The
  client uses the original IDs and key, and displays the line once throughout.

### DEV-15 — Host commits payment, response is lost — Controlled

- [ ] **Steps:** Let a known-bill payment commit, discard its response, restart
  the client offline, then reconnect and retry the same payment key.
- **Expected:** Local paid/outstanding amounts stay correct. Exactly one host
  payment and associated money movement; no second collection prompt. Repeat
  with a non-cash method supported by the venue, including its proof attachment.

### DEV-16 — Disconnect after the order is acknowledged — Controlled

- [ ] **Steps:** Queue order → receipt → payment. Allow only the order to be
  acknowledged, then interrupt delivery before the receipt/payment. Inspect the
  bill, restart offline, and reconnect.
- **Expected:** The acknowledged order remains represented locally. The pending
  money acts retain their prerequisites. The order is not sent again once its
  acknowledgment is durable, and final reconciliation loses no amount.

### DEV-17 — Disconnect after payment acknowledgment — Controlled

- [ ] **Steps:** Allow payment acknowledgment, then block the replacement bill
  snapshot. Navigate away and back; restart offline; finally restore delivery.
- **Expected:** The client continues showing the recorded payment and correct
  outstanding amount. It does not ask for the same money again. The event is
  retired only after the replacement snapshot is durable.

### DEV-18 — Snapshot fetch or local write fails — Controlled

- [ ] **Steps:** In separate runs, fail the bill read, the floor refresh, and the
  local checkpoint write after successful sends. Also stop the client around
  the checkpoint transaction boundary, then reopen offline.
- **Expected:** Recovery yields a consistent baseline plus retained events, or
  the committed replacement snapshot. No half-retired chain, duplicate payment,
  empty floor caused by premature retirement, or silently swallowed write error.

### DEV-19 — New capture arrives while a snapshot is delayed — Controlled

- [ ] **Steps:** Capture one Rp55,000 order. Reconnect and pause its snapshot read.
  Capture another Rp55,000 order on the same visit; then release the snapshot.
- **Expected:** The combined bill is Rp110,000 exactly once. The later event has
  its own ordered sequence and survives the earlier checkpoint. It cannot
  overtake its prerequisites. A later successful drain leaves two host tickets.

### DEV-20 — Repeated connection events and navigation during drain

- [ ] **Steps:** With several queued acts, briefly cycle connectivity and move
  between table detail, Orders, and the open bill while recovery runs.
- **Expected:** No overlapping sends of the same journal act, crashes, duplicate
  rows, or temporary unpaid bill inviting recollection. The final state remains
  correct after closing and reopening each screen.

### DEV-21 — Close completes after the live visit is removed

- [ ] **Steps:** Prepare a visit whose table is already freed so successful bill
  closure snapshots/removes the live visit. Capture final payment/close offline,
  then reconnect. Also exercise a normal online close.
- **Expected:** Explicit successful closure allows the journal to finish despite
  the live bill no longer existing. History contains the closed bill once. A
  normal online close does not create a second captured close event.
- **Controlled negative:** An unrelated bill GET 404 without an acknowledged
  close must not authorize dropping the visit's captured food or money.

## 6. Refusal, permissions, and visit isolation

### DEV-22 — Refusal preserves food, cash, and the successful prefix

- [ ] **Steps:** Cache an unpaid receipt. Disconnect the client and capture an
  order followed by payment on that receipt. On the host, delete the still-unpaid
  receipt through the normal workflow. Reconnect the client.
- **Expected:** The order may succeed, but the payment refusal parks the affected
  chain. The delivered order, captured cash amount, and refusal reason remain
  visible. The UI must not represent that cash as successfully settled on host.
  If this conflict cannot be prepared through the UI, use a controlled refusal.

### DEV-23 — Refused visit stays read-only, including after restart

- [ ] **Steps:** Use DEV-22's refused visit. Try new orders, voids, edits, course
  actions, receipt changes, discounts, payments, refunds, closure, expenses, and
  table/visit changes exposed to that account. Repeat after restart and reconnect.
- **Expected:** Every applicable entry point blocks new acts on that visit;
  reopening a screen or regaining connectivity does not clear the restriction.
  Existing food and cash evidence stays readable. Another visit remains usable.
- **Resolution:** Use the existing authorized human resolution workflow only
  after recording the discrepancy. Confirm normal eligibility rules apply again.

### DEV-24 — Partial stock rejection on a fresh captured order

- [ ] **Steps:** Use a waiter without stock override. Capture an order with two
  lines; make only one unavailable on the host. Reconnect within 60 seconds.
- **Expected:** A response accepting one line and rejecting another is not
  treated as complete success. The visit is parked/read-only; both the accepted
  host line and refused captured line remain understandable without duplication.

### DEV-25 — Transport interruption is not a refusal

- [ ] **Steps:** Cause a timeout or unreachable host without a business refusal.
  Add another order to the same visit. Where a complete baseline exists, perform
  another supported offline settlement act.
- **Expected:** The visit is not parked just because transport failed. Capture
  continues in sequence; reconnection can complete the chain normally.

### DEV-26 — Table reused for a different party

- [ ] **Steps:** Capture work for visit A offline. On the host, free the table and
  seat visit B. Reconnect and inspect both visits and the current table.
- **Expected:** The table remains associated with B. A's captured lines, money,
  and any detached history remain associated with A. Neither party absorbs the
  other's items or payments.

### DEV-27 — One refused visit does not block the rest

- [ ] **Steps:** Queue work for at least three visits and arrange a refusal on
  the middle visit. Reconnect, inspect all outcomes, and restart.
- **Expected:** Only the contradicted visit is read-only. Other visits reconcile
  successfully and remain usable. Their snapshots and money are not mixed.

### DEV-28 — Waiter snapshot access and cashier-only mutations

- [ ] **Steps:** Sign in with `takeOrder` but no `settleBill`. Capture/reconcile an
  order and confirm the journal can finish. Attempt settlement through available
  UI and, with an authenticated test client, the underlying mutation routes.
- **Expected:** Bill reads needed for reconciliation succeed. Receipt/payment/
  bill-close mutations remain forbidden. An unauthenticated snapshot request
  remains denied. Repeat with a cashier to verify legitimate settlement works.

## 7. Money and adjacent journal behavior

### DEV-29 — Tax, service, discounts, rounding, and split receipts

- [ ] **Steps:** Record an online reference bill using non-round prices and the
  venue's actual tax/service settings. Repeat the same lines and supported
  discount/split actions offline on a separate visit, then reconnect.
- **Expected:** Subtotal, discounts, tax/service, receipt allocation, rounding,
  paid amounts, and outstanding match the reference. Include an itemized split,
  an even split, and a partially paid bill. Capture actual reference values;
  do not use the tax-disabled fixture totals for this case.

### DEV-30 — Refund and reopen recovery

- [ ] **Steps:** On a cached bill, exercise supported authorized offline refund
  and reopen actions. Restart before reconnecting. Repeat with a lost refund
  response using controlled transport.
- **Expected:** The refund is applied once and preserves its payment reference.
  Paid/outstanding amounts and final host history agree. Required manager or
  online-only approvals remain enforced; do not bypass them to complete a case.

### DEV-31 — Member-only and venue-only chains finish

- [ ] **Steps:** Capture a member enrollment without a visit, then reconnect.
  Separately capture supported member attachment/attribution acts. Include an
  enrollment whose identity the host resolves to an existing member.
- **Expected:** Enrollment does not require a nonexistent bill endpoint. Member
  identity is resolved consistently before dependent acts. Member-only work does
  not incorrectly confer money authority or leave a permanently stuck chain.

### DEV-32 — Visit expense follows the order and retains proof

- [ ] **Steps:** With expense mode/capability enabled and a usable expense cap,
  capture an order and a permitted expense with its required proof photo.
  Restart, reconnect, and repeat with a lost response. Also try a refused visit.
- **Expected:** The expense follows its visit's prerequisites in the same
  journal, posts once, retains its photo and author, and is included in the
  expense summary once. Existing cap/proof checks and the refusal lock remain
  effective. An expense does not become an item charged to the guest.

### DEV-33 — Correct author and capture time across a shift boundary

- [ ] **Steps:** Capture work under one staff account/shift. Reconnect later,
  including across midnight or a shift change, using another authorized carrier
  if the existing login policy allows it.
- **Expected:** Order/payment/expense audit records preserve the original actor
  and capture time according to the existing shift policy. Reconnection time or
  the carrier's identity must not replace who performed the act.

### DEV-34 — Cash collected independently on another device

- [ ] **Steps:** With a cached client bill offline, make a conflicting authorized
  host-side settlement on a second device. Reconnect the original client's
  captured payment chain.
- **Expected:** Apply the existing conflict/refusal policy. Never silently erase
  either captured cash evidence or merge conflicting payments into a false clean
  bill. This does not assume automatic reconciliation of independent offline tills.

## 8. Device/UI repetitions

- [ ] Repeat DEV-03 through DEV-06 and DEV-23 on a physical phone and a tablet
  layout. Check readable warnings, visible amounts, and reachable permitted
  actions at normal and increased system text size.
- [ ] Include background/foreground, screen lock/unlock, force-stop, and one
  reboot while the client holds pending work.
- [ ] Keep a bill open during reconnect and while switching tabs. Check for
  load errors, blank/duplicated lines, stale totals, and enabled actions on a
  refused or missing-history bill.
- [ ] Verify captured lines do not appear as delivered kitchen work before the
  host accepts them; verify normal kitchen routing after successful delivery.

## 9. Result and evidence template

Use **Pass / Fail / Blocked / Not applicable**. Leave unchecked cases as Not run.
Explain every Blocked or Not applicable result, especially a feature disabled by
the venue or a controlled failure that could not be injected.

| Case | Host/client builds and devices | Visit/event IDs | Expected vs actual amounts/state | Result | Evidence link | Tester/date |
|---|---|---|---|---|---|---|
| DEV-__ | | | | Not run | | |

For a failure, include reproduction steps, the first unexpected state, relevant
screenshots, log timestamps, and a sanitized read-only journal/host record excerpt.
Do not include bearer tokens, PINs, payment-proof images, or guest personal data
in broadly shared reports.

## 10. Acceptance gate

- [ ] Every applicable case has a recorded result and evidence.
- [ ] All core cases and money/replay/refusal cases pass; controlled cases are
  not marked passed merely because a manual reconnect looked correct.
- [ ] No lost food, cash, refund, or expense; no duplicate delivery or collection.
- [ ] No cross-visit leakage, payment from unknown history, or mutation behind
  an unresolved refusal.
- [ ] Both the offline client result and final host state have been verified.
- [ ] Remaining blocked cases and any release decision are explicitly recorded.
- [ ] Reconcile test cash/stock through the normal test-venue workflow, preserve
  failure evidence, and return connectivity/settings to their original state.

### Prior evidence to carry forward, not substitute for this run

On September 10 the upgraded emulator restored the offline P1 session. D2's
missing-history bill showed the new explanation without payment controls.
Read-only inspection found the existing D3 order/payment/close chain and D1 order;
there was no D2 order event remaining in that device's journal. The D3 table view
and complete repaired-host reconnect matrix were not verified. No Android devices
were connected when verification resumed on September 11.
