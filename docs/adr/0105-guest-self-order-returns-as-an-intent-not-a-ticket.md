# Guest self-ordering returns as an intent, not a ticket

**Status:** Accepted — 2026-08-19 — supersedes [0080](0080-self-order-and-token-pairing-removed.md) §1 (self-ordering removed in full); re-decides [0027](0027-cleartext-guest-plane-for-self-order.md) (cleartext guest plane), [0028](0028-guest-orders-pending-review-not-auto-fire.md) (guest orders rest in review), [0029](0029-guest-web-app-hand-rolled-spa-not-flutter-web.md) (hand-rolled guest SPA), [0064](0064-a-guest-order-gets-its-own-cue.md) (the guest-order cue). ADR-0080 §2 (token pairing removed) stands and is untouched.

## Context

ADR-0080 deleted guest self-ordering fourteen days ago, and its reasoning was
sound: what shipped was "a second ordering path, a second auth scope, a second
network plane and a second product surface". Four costs, one feature.

It is being rebuilt, from scratch, because two of those four costs were
implementation choices rather than the feature, and the version below does not
pay them. Nothing from the old build survives — schema v45 dropped the columns
and deleted the rows — so this is not a revert, and the shape below is
deliberately not the shape ADR-0080 removed.

Reading the four costs one at a time:

- **A second ordering path.** Not paid. A guest order is an *intent* that a
  staff member accepts, and accepting calls the same `submitOrder` a waiter's
  send calls — same stock check, same visit attachment, same idempotency claim,
  same audit. There is exactly one thing in this codebase that writes a ticket.
- **A second auth scope.** Not paid. There is no guest JWT, no guest signing
  key and no scope claim to get wrong. The credential is a rotatable per-table
  code in the URL plus an opaque session id.
- **A second network plane.** Paid, deliberately, and unavoidably: a phone that
  has never met this venue cannot be taught to trust its self-signed
  certificate, and a browser interstitial in front of a menu is a feature
  nobody uses.
- **A second product surface.** Paid. A guest-facing page is the feature.

## Decision

**1. A guest order is an intent, in its own tables.** `guest_orders` +
`guest_order_lines`, with a `status` of `pending | accepted | rejected |
cancelled`. `TicketStatus.pendingReview` is **not** coming back.

That state was the expensive part of the old design and the reason ADR-0080 §3
had to *delete* rows rather than remap them: an unapproved order living in
`tickets` meant every reader of `tickets` — the bill, the KDS, the reports, the
floor signals, `ticketStatusFromKey`'s fallback — had to know to exclude it,
and the day one of them forgot, an order nobody approved landed on a paying
guest's bill. An intent in its own table is invisible to all of them by
construction. Accept is the moment it becomes real, and it becomes real the
ordinary way.

**2. The guest is untrusted, so the server prices the order.** The phone posts
item ids, a variant id, option ids, a quantity and a note. Every rupiah is
re-derived from `menu_items` server-side — a variant's `price` is absolute, an
option's `priceDelta` adds — and a `unitPrice` on the wire is ignored. Required
and single-select modifier groups are validated the same pass. An item with
`guest_visible = 0` cannot be ordered even by id.

**3. The code in the URL replaces the guest JWT.** `venue_tables.guest_code` is
eight characters from a 30-symbol alphabet with the homoglyphs removed, minted
for every table and rotatable venue-wide in one audited act.

A JWT was the wrong instrument. It bought signing, expiry and revocation for a
credential that is *printed on a laminated card and left on a table* — so its
real lifetime is "until someone reprints the QR", which no expiry claim can
model, and revoking one meant rotating a signing key the staff app also used. A
code is revoked by reminting it, which is the same act as reprinting the QR.
What the code opens is a menu and a submit button on one table, and both are
things a person sitting at that table can already do by speaking.

Per-table opt-in rides the same lookup: a table with self-order switched off
has a code that resolves to nothing, and so does an unknown one — one
indistinguishable 404, or the QR becomes a way to enumerate the floor plan.

**4. A session is bound to a sitting, not to a table.** `guest_sessions` gives
the phone an opaque id so "Pesanan saya" can exist without a login. It is dead
once the table is reopened (`openedAt` moved past the session's start) or its
bill closed (`billClosedAt` did) — derived from the table row rather than
stored, so *every* path that frees a table closes the sessions on it without
knowing they exist. A phone left on a windowsill must not order onto the next
party's bill.

**5. The plane binds only while the venue flag is on.** Cleartext HTTP on
:8080, `guestRoutes` and nothing else, built without a `ServerAuth` at all —
ADR-0102's "every route factory takes a non-null `ServerAuth`" is a rule about
the staff API, and the way to keep a stranger out of it is to hand them a
router that has never heard of it. Off means the socket does not exist, rather
than existing and answering 403.

**6. Payment stays at the cashier.** No QRIS, no pay-state, no auto-terima. The
guest orders; the bill settles where it settles today.

**7. One new `AuditType`, five new `AuditKind`s, no new `Capability`.**
Configuring self-order is `editSettings`; deciding an order is `takeOrder` — it
is an order, not a setting. Both open the screen, because the waiter who
accepts and the owner who curates share it.

## Consequences

- The server binds 8080 again and serves HTML again, for venues that switch it
  on. A venue that never does has no second socket.
- The guest page polls `GET /guest/orders` every 5s. No second WS hub — the
  staff hub broadcasts `guestOrder.submitted` / `guestOrder.decided` so the
  queue and the hub badge stay live without polling.
- `AlertEvent.guestPending` returns, with its preset default and its column.
- `guest_orders.status`, `guest_stock_override` and `StockCountScope`-style
  enum names are **persisted strings**: renaming one orphans every stored row.
- The guest page's copy is Indonesian and lives in `assets/guest_web/`, outside
  the ARB pipeline. It is the one user-facing surface in this app that is not
  localised, because it is not a staff tool and a guest scanning a QR in a
  Jakarta warung is not choosing a language.
- v56 is one-way. A downgraded APK will not read an upgraded DB.
- The rebuilt feature is ~2600 lines across server, client and page. If it goes
  unused a second time, it is deletable in one commit again — which is the
  strongest argument for keeping it in its own tables and its own folder.

## Alternatives considered

- **Revive `pendingReview`.** Rejected on ADR-0080's own evidence: the state
  forced every reader of `tickets` to carry an exclusion, and the failure mode
  when one forgot was money.
- **A guest JWT again.** Rejected — see §3. Signing, expiry and revocation
  bought nothing for a credential printed on a card.
- **HTTPS on the guest plane with the venue's self-signed cert.** Rejected: the
  browser warning is the whole experience, and no guest clicks through it.
  Nothing crossing this plane is a credential.
- **Flutter Web for the guest page.** Rejected again, with ADR-0029's
  reasoning: a multi-megabyte payload over venue Wi-Fi, for a menu.
- **Auto-accept a guest order.** Rejected: a stranger's phone firing food into
  a kitchen with no human in between is the failure this design is shaped to
  avoid, and the accept step is what makes the stock check meaningful.
- **Guest payment on the phone (QRIS / GoPay / OVO / card), with paid orders
  auto-accepted.** Re-proposed by the v2 tablet design (2026-08-19) and
  rejected again on §5 and §6: the plane a guest reaches is cleartext HTTP with
  no auth, so a payment token or provider redirect would cross it in the open,
  and the webhook has no public address to land on. Auto-accepting the paid
  ones would then hand that same plane a path to the kitchen. Both would need
  the guest plane behind TLS first, which §5 explains is the one thing it
  cannot have.
- **Price the order on the phone.** Rejected without discussion; it is the
  trust boundary.
