# ADR-0138 — Paid bills close only with confirmation

## Status

Accepted, 2026-09-07. Supersedes ADR-0069.

## Context

Automatically closing a fully paid bill locks it before the cashier can decide
whether the party is finished ordering. Reopening may no longer be possible if
the table was already released and the visit archived. Payment and bill closure
therefore need separate decisions even when nothing remains to collect.

## Decision

Settlement records payment without closing the bill. When an action on the bill
screen changes an open bill from unsettled to fully settled, including a discount,
ask **Close bill / Keep open**. Partial settlement does not prompt. Dismissing the
dialog keeps the bill open and all recorded payments intact.

A fully paid open bill retains a manual **Close bill** action and appears in
**Settled** and **All**. Merely opening it does not repeat the prompt. Additional
items follow the existing ordering rules; settling new outstanding items prompts
again. Confirming closure uses the existing explicit close operation and returns
to the cashier list.

## Consequences

The cashier gains a real choice at the cost of one confirmation. An open, paid
bill is now a lasting state. Loyalty points accrue at explicit closure, and
archiving still requires both bill closure and table release (or takeaway handover).
Keeping a bill open does not undo payment or free a table. Offline payment and
closure remain separate journal events. Write-off and reopen rules are unchanged.
