# A visit expense is revenue, not petty cash

**Status:** Accepted — 2026-09-04 — **amends** [0039](0039-settled-total-over-redefining-net-total.md) and sits deliberately beside [0088](0088-the-petty-cash-box-cannot-go-negative.md) / [0089](0089-petty-cash-is-not-revenue.md) without touching them.

A [[Waiter|pelayan]] spends small cash on a party while serving it — tissues, a
complimentary something, an errand to the warung next door — out of the money
that [[Visit|kunjungan]] is producing. This ADR gives that act a home: a
**[[Pengeluaran kunjungan (visit expense)]]**, a capped, photographed,
append-only row against the visit that reduces what the venue **collected** and
touches neither the guest's bill nor the petty cash box.

## Context

The obvious home was [[Kas kecil (petty cash)]]. It already has categories, a
note, an optional photo, append-only rows and one writer. Tagging a `visitId`
onto a `cash_entries` row looked like a day's work.

It was the wrong ledger twice over, and the second reason is the one that
matters.

**The box refuses the waiter.** ADR-0088 makes `spendCash` throw
`insufficient_cash` inside its transaction, and the reasoning is sound for the
box: a would-be negative balance is always a row nobody wrote down, and refusing
is what produces the conversation. But a waiter cannot top the box up
(`editSettings`) and cannot wait. Standing on the floor holding a Rp 15.000
receipt, the refusal does not produce a conversation — it produces an
**unrecorded expense**, which is precisely the failure 0088 exists to prevent,
inverted. We considered a third exemption alongside `reversal` and `count`, and
would have taken it, had the ledger been right at all.

**The box is not where this money comes from.** ADR-0089 is categorical: petty
cash is a standing float that only ever leaves the venue, it is *not revenue*,
and it never enters `netTotal`, `settledTotal`, Bruto or the payment mix. A visit
expense is the opposite fact. The money did not come from a float; it came out of
what this table was paying. It **is** revenue-affecting, and filing it beside
petty cash would make one report section mean two irreconcilable things.

So: a second ledger, and the two never touch. An expense here moves no box
balance; no top-up can fund it.

## The guest pays in full

The tempting shortcut is to net the expense off the outstanding. It is wrong: the
guest ate what they ordered and owes for it, and the venue absorbed a cost. A
reduction of what the guest owes is a [[Diskon (discount)]] and already exists as
`source: manual`.

Keeping them distinct has a mechanical payoff. `recomputeBill` — the one money
function both sides run (ADR-0123) — never learns a visit expense exists. Its
purity, and the offline parity test that pins it, survive this feature untouched.

## Which figure moves

`netTotal` was frozen by ADR-0039 at `subtotal − void + service + tax`
specifically so its meaning would never change again. `settledTotal` is
`netTotal − discountAmount` and is documented as *"money actually collected: the
revenue figure every report and export reads."*

This feature makes that sentence false — collected cash is `settledTotal −
expenseAmount`. There were two ways out:

- **Redefine `settledTotal`.** Truthful to the docstring, and it silently
  rewrites every historical comparison and every accounting export already in a
  customer's spreadsheet.
- **A new frozen column.** `TableSessions.expenseAmount`, `settledTotal`
  untouched, a new figure below it in Reports.

We took the second, which is ADR-0039's own posture applied a second time. What
changes is 0039's *prose*, not its arithmetic: `settledTotal` is money **billed
and settled**, and money in hand is that minus `expenseAmount`. A figure whose
formula never moves is worth more than a figure whose name is perfectly accurate.

## Controls, and the one we deliberately left out

An arbitrary-amount, revenue-reducing write in a waiter's hand is a worse fraud
surface than [[Item bebas (open item)]], whose `sellOpenItem` capability was
withheld from the waiter role for exactly this reason. Four controls stand in
for that refusal:

- **A cap.** The visit's subtotal of sent, non-voided lines, pre-tax and
  pre-discount — you cannot take more out of a table than the table produced.
  It binds the **running sum** of the visit's expenses, and is checked **at
  capture only**. A later void that drops the subtotal below what was already
  spent leaves the expense standing: the cash left, and a ledger that unwound it
  would be lying. Refusal at capture is the control; a permanent invariant is not
  available here.
- **Its own capability**, `recordTableExpense` — granted to the seeded waiter
  role, but separately, so an owner revokes it without touching order-taking and
  the audit row names a distinct authority.
- **A mandatory photo.** No skip affordance; submit stays disabled without one.
  A denied camera permission is a blocking error, not a bypass — softening that
  makes the requirement optional in the only situation where it bites.
- **Append-only.** Never edited, never deleted, the posture the box takes.

We deliberately did **not** require a manager step-up. Authority does not travel
offline (ADR-0099), so a step-up would make the feature unusable in exactly the
conditions it is for — and the waiter, holding a receipt and no way to file it,
records nothing. That is the round-one failure again in a different costume.

## Offline

An [[Antrean kirim (send queue)|intent]] (ADR-0090), not a settlement journal
event (ADR-0123): one append-only row is not a chain and is never read back
locally. Two adjustments the existing queue does not have:

- **The photo cannot live in the queue.** The send queue is a prefs blob, loaded
  synchronously at boot; a base64 JPEG per queued expense would put megabytes in
  a string parsed on every launch. The blob goes in the client Drift database
  instead — ADR-0124's title is literally *the client holds a database for money
  it cannot send* — keyed by the intent id, deleted on successful drain, and
  posted as multipart on replay so the online and offline paths share one route
  shape.
- **No cached subtotal, no capture.** A handset that never loaded the visit's
  bill has nothing to cap against. Allowing an uncapped capture would make the
  cap opt-out-able by turning off Wi-Fi, which is the one thing a fraud control
  cannot survive. A stale subtotal is fine — the server re-checks at drain.

At drain the cap is the only refusal that can fire, and like `voidTicket`'s 403
it is a business refusal that must **not** stall the queue.

## Consequences

- **A fifth writer file.** `lib/server/visit_expenses.dart`, joining `cash.dart`,
  `members.dart`, `stock_counts.dart` and `self_order.dart`. Its invariants: the
  cap, and append-only.
- **A venue-authored category catalogue**, contradicting the argument written
  into `cash_entry.dart` — that a venue-authored list buys a CRUD screen, an
  ARB-exempt string and an ungroupable report. That argument was made for a
  ledger seeing tens of rows a week; the owner's own vocabulary is worth the
  screen here. Shaped exactly like `DiscountPresets` (`id, name, active,
  sortOrder`), **soft-delete only**, so a closed month keeps naming its
  categories. Cached client-side and **warmed at `AppShell`** beside the discount
  presets — ADR-0128 documents that exact bug (a lazy first watch failing on a
  dark handset and the sheet claiming the owner authored nothing), and this would
  otherwise repeat it verbatim.
- **A new mode key**, `tableExpense` in `venueModeKeys` / `MODE_MODULES` —
  fail-closed, outside the trial grant, independent of `counterService`. It
  branches no writer; it gates the route, which answers 404 when off.
- **A new `AuditKind`**, `tableExpenseRecorded` — not `cashSpent`; different
  ledger, and the name is persisted forever.
- **Reached from the visit, not the table tile** — table detail's context sheet
  and the [[Cashier]] bill overlay — so a [[Kedai (counter mode)|Kedai]] venue
  with `menuHome` on and no floor still has the feature. A counter shop buys more
  tissues, not fewer.
- **Photos are not purged**, matching payment proofs and cash-expense photos: a
  proof you deleted is a proof you did not have. At ~150KB and twenty expenses a
  day that is roughly a gigabyte a year on the host tablet. Seen and accepted; if
  it needs a cap, that is a later ADR and not a later crisis.
