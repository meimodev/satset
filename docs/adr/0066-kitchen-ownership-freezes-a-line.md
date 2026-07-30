# ADR-0066 — Kitchen ownership freezes a line

## Status

Accepted. Defines the editable window for a sent line, closing a question
ADR-0043 (`firedAt`, per-item ready targets) opened and ADR-0006 (void
attribution) assumed an answer to. Retires "refire" as a concept.

## Context

A [[Ticket]] has always had exactly two post-send remedies: advance it, or
void it. There was no way to change one. `AuditType.modify` had existed in the
enum since the first audit work and was emitted by nothing; the line action
sheet offered `fire` / `serve` / `unserve` / `void` and no edit.

That gap is felt in the ordinary case, not an exotic one. A guest changes
their mind about a side, or asks for two instead of one, seconds after the
waiter submits. Today the waiter must void the line and re-add it — which
loses the original line's history, and inflates the venue's void count with
events that were never cancellations. The number a manager uses to spot a
problem gets noisier every time the system fails to offer an edit.

Designing the edit forced the real question: **how late may a line change?**

The tempting answer is "always, and tell the kitchen loudly" — flag the
changed line on the KDS, re-sort it, fire the alert. The design prototype went
further and split the case in two: edits before the station acknowledges apply
immediately, edits after become a *proposal* the cook accepts or rejects.

Both answers are wrong here, for the same reason. Once a line is fired the
cook's copy **is** the order. A pan is on the heat. Rewriting the order under
someone who is already executing it — even loudly, even with a confirmation
step — makes the ticket in front of them something that can change while they
read it. That is a worse failure than a re-key, and the accept/reject variant
buys it at the cost of a two-party negotiation protocol: a pending-change
payload on the ticket, two new transitions, KDS proposal UI, and a fresh
question about what a *rejected* proposal means for the bill.

`held` is already the line the domain draws. ADR-0043 defines `held → sent` as
the moment the kitchen takes ownership — it stamps `firedAt`, and the prep
clock starts there rather than at `sentAt`, precisely so a course held forty
minutes is not born overdue. A held line is submitted but not yet anyone's
work.

## Decision

**A line is editable while `held`, and frozen from `sent` onward.**

- `PATCH /tickets/<id>` changes `qty`, `note` and `modifiers` on a `held` row,
  gated by `modifyOrder`, and writes an `AuditType.modify` row carrying the
  before/after value.
- Any other status returns **409 `line_frozen`**. The rule is enforced by the
  route, not by hiding the button — a stale client, a replayed request or a
  race against a fire must all fail the same way.
- Variant is not editable. A different variant is a different dish at a
  different price, often on a different station; that is an add and a void.
- After fire, the only remedy is a void with a reason, which already exists
  and is already attributed (ADR-0006).
- **Refire is not a concept in this system.** It had no transition, no button
  and no audit type; it survived only in two lines of UI copy suggesting it,
  which are now removed.

Stock is re-booked rather than diffed: the old consumption is reversed as
`untouched` and the new need is consumed fresh. That is safe *because* of the
freeze rule — nothing has been cooked, so nothing is wasted — and it handles a
modifier swap changing which ingredients are needed, not merely how many.

## Consequences

A guest who changes their mind after the course is fired still costs a void.
That is the honest outcome: the food is being made, and the venue's log should
say a line was cancelled, because one was.

The "Ubah" tile on the venue audit log (ADR-0067) counts held-line edits only.
It is narrower than the "post-send mods" the design prototype showed, and the
prototype's `3 pre-prep · 2 acknowledged` split does not exist — there is no
acknowledged case to count.

If a venue later needs post-fire edits, this ADR is the thing to revisit, and
the accept/reject protocol above is the shape it would take. It should be
its own decision with its own KDS design, not an extension of an edit button.
