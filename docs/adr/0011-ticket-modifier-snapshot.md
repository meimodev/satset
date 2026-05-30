# Ticket modifier snapshot: structured objects, built client-side

A sent line snapshots its chosen add-ons as a JSON **array of structured objects** on `modifiersJson` — one per chosen option, each `{groupId, optionId, label, priceDelta}`. The objects are **built on the client** (which holds the menu) and stored **verbatim** by the server. This applies to both `tickets` and `table_session_tickets` (the closed-visit snapshot).

## Why

The kitchen line rendered blank for single-select add-ons. The submit path (`SubmitOrderUseCase`) flattened the modifier selections with `expand((v) => v is List ? ... : [])` — single-select groups are stored as a bare `String` in the sheet's `_selections`, so they were silently dropped, and only multi-select (checkbox) options ever reached the server.

Fixing the drop exposed a second, deeper problem: the line stored option **ids** (`o0`), not a snapshot. The KDS has no menu to resolve ids against, and renaming/deleting a modifier on the menu would retroactively corrupt already-sent lines — directly contradicting ADR-0009's claim that "tickets already snapshot their modifiers." A reference is not a snapshot.

We snapshot the full tuple so each reader is self-sufficient:

- **KDS** reads `label` (no menu lookup, immune to later menu edits).
- **Reports** group by `groupId` (stable attach-rate analytics).
- **Receipts / audit** derive the sign and amount from `priceDelta` (a number, not baked-in `+`/`−` text).

The client builds the objects because only it holds the menu to resolve `optionId → label, priceDelta`. The server already trusts client-supplied `name` and `unitPrice` on the same line (same trust boundary), so storing the array verbatim adds no new trust.

## Considered and rejected

- **Labels only (`List<String>`).** Smallest change — KDS works immediately. Rejected: reports can't group reliably by text, and the option id is lost for stable analytics.
- **Ids only.** Keeps analytics stable but leaves the KDS with unresolvable ids and re-introduces the menu-edit corruption this ADR exists to kill.
- **Resolve ids → labels server-side.** The server has no menu snapshot; would require a new lookup path and still break when the referenced option is later deleted.
- **Tolerant decode + reseed instead of a migration.** Rejected for this repo: existing `tickets` / `table_session_tickets` rows are rewritten by a formal v21→v22 migration so old shapes don't linger behind a permanent runtime shim.

## Consequences

- Wire contract changes: the order line carries `modifiers: [{groupId, optionId, label, priceDelta}]` instead of `modifierOptionIds: [String]`. `TicketDto.modifiers` and domain `Ticket.modifiers` change from `List<String>` to a structured list.
- DB migration **v21 → v22** rewrites `modifiersJson` on both ticket tables: a legacy bare-`String` entry becomes `{groupId:'', optionId:'', label: s, priceDelta: 0}`; already-structured entries pass through. The backfill is **shallow** — it does not join back to the menu to resolve legacy bare ids (the item may be gone; pre-prod volume makes a deep resolve not worth it).
- `seed.dart` emits real structured objects (true `groupId`/`optionId`) so the reports demo populates.
- `label` is stored clean (no `+`/`−` prefix); presentation derives the sign from `priceDelta`.
- Reverting to an ids-only or labels-only wire shape is a migration, not a config flip.
