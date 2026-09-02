# ADR-0066 — The bill detail is a page on every layout

## Status

Accepted. Supersedes this ADR's earlier phone-sheet decision and amends ADR-0064,
which made the bill an overlay on both form factors.
Part of the cashier reconciliation pass ADR-0051 §Scope deferred.

## Context

ADR-0064 moved the bill off a route and into an overlay: a right-edge drawer on a
tablet, a tall bottom sheet on a phone. The tablet later became a page because the
settlement surface outgrew a drawer. Keeping a second phone-only container bought
no useful context—the sheet already covered the screen—but retained swipe and
barrier dismissal, separate chrome, and a second entry behavior.

What changed is what has to fit inside it. The design source settles a bill through
a dedicated pane carrying, at once: a three-way mode row, a four-way method row, a
denomination cash pad with a count badge on each, a quick-tender row, a
received / short / change summary, a denomination breakdown of the change, a
proof-photo capture block, a confirm button and a hint line explaining why it is
disabled. That is not a drawer's worth of content.

The specific failure is not "it scrolls". It is *what* scrolls. A cashier counting
cash reads the running total while tapping notes; if the tally and the pad cannot be
on screen together, the pad has made counting harder than the drawer it replaced.

## Decision

**Bill detail is a page on every layout. Available width still decides its body.**

- **Tablet** — the bill is a full-screen two-pane page pushed on the root navigator.
  Left: header, bill actions, lines, payment history, totals ladder. Right: the
  settle pane. Both panes scroll independently, so the cash tally stays put while
  the line list moves.
- **Phone** — the same root-navigator page uses standard back navigation and one
  compact app bar. Its body stays a single vertical flow with the confirmation
  action pinned below it; it does not imitate the tablet's two-pane composition.

Every entry point goes through `openCashierBill`, so cashier cards, post-send flow,
and table detail cannot disagree about the container. Table detail exposes a compact
header icon only when its current Visit exists and the user may settle bills.

## Consequences

- One page container owns the scaffold, app bar, and way out. `CashierBillView`
  remains container-agnostic and adapts its content to the available width.
- The phone **stacks** where the tablet sits side by side: lines scroll above, the
  settle pane occupies a fixed block below with its confirm bar pinned. A stepped
  flow was considered and rejected — a step between picking items and taking money
  is a step the cashier pays for on every single payment, and the page scrolls well.
  The cost is that a phone cannot see the whole line list and the
  running cash tally at once, which is exactly the thing the tablet page was chosen
  to fix; on a 360dp handset there is no layout that fixes it.
- Losing the drawer on tablet means losing "read the bill against the list", which was
  ADR-0064's stated benefit. The list's header and stat row are what replace it — the
  aggregate the cashier actually glanced at, now always on the list screen rather than
  peeked at behind a drawer.
- Back discards unsubmitted tender, split selection, and proof-photo state exactly as
  the former sheet did. Partial payments refresh in place; closing the Bill pops the
  page back to its origin.
