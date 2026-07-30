# ADR-0066 — The bill detail is a page on a tablet and a sheet on a phone

## Status

Accepted. Amends ADR-0064, which made the bill an overlay on both form factors.
Part of the cashier reconciliation pass ADR-0051 §Scope deferred.

## Context

ADR-0064 moved the bill off a route and into an overlay: a right-edge drawer on a
tablet, a tall bottom sheet on a phone. The reasoning was sound and still is — the
cashier reads a bill *against* the payable list, and a 560px side panel on a phone
would be the whole screen anyway.

What changed is what has to fit inside it. The design source settles a bill through
a dedicated pane carrying, at once: a three-way mode row, a four-way method row, a
seven-button cash pad with a note-count badge on each, a quick-tender row, a
received / short / change summary, a folded-notes readout of the change, a
proof-photo capture block, a confirm button and a hint line explaining why it is
disabled. That is not a drawer's worth of content.

The specific failure is not "it scrolls". It is *what* scrolls. A cashier counting
cash reads the running total while tapping notes; if the tally and the pad cannot be
on screen together, the pad has made counting harder than the drawer it replaced.

## Decision

**Hardware decides, as it already does everywhere else (ADR-0049).**

- **Tablet** — the bill is a full-screen two-pane page pushed on the root navigator.
  Left: header, bill actions, lines, payment history, totals ladder. Right: the
  settle pane. Both panes scroll independently, so the cash tally stays put while
  the line list moves.
- **Phone** — ADR-0064 stands unchanged. The tall sheet, root-navigator by
  construction, so the floating tab bar still cannot float over the confirm button.

ADR-0064 is amended rather than superseded: its reasoning was never wrong, it was
scoped to a screen that has since grown.

## Consequences

- Two containers for one body. The bill content stays container-agnostic — no
  `Scaffold`, no `AppBar`, exactly as `CashierBillView` is already written — and each
  container supplies its own chrome. This is the shape the booking book already uses
  (ADR-0048).
- The phone **stacks** where the tablet sits side by side: lines scroll above, the
  settle pane occupies a fixed block below with its confirm bar pinned. A stepped
  flow was considered and rejected — a step between picking items and taking money
  is a step the cashier pays for on every single payment, and the sheet already
  scrolls well. The cost is that a phone cannot see the whole line list and the
  running cash tally at once, which is exactly the thing the tablet page was chosen
  to fix; on a 360dp handset there is no layout that fixes it.
- Losing the drawer on tablet means losing "read the bill against the list", which was
  ADR-0064's stated benefit. The list's header and stat row are what replace it — the
  aggregate the cashier actually glanced at, now always on the list screen rather than
  peeked at behind a drawer.
- The source has **no phone layout at all**. Everything on the phone side here is ours,
  and is not fidelity to anything.
