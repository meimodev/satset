# ADR-0125 — Member attribution rides the Ticket

Status: accepted
Date: 2026-09-02

Supersedes [ADR-0118](0118-member-attribution-rides-the-receipt.md) and [ADR-0120](0120-a-tab-follows-the-struk.md) for visits opened after this change. A receipt member labels a financial share, a `piutang` payment explicitly names its debtor, and neither reliably answers who consumed each item. Under the existing `memberSplit` mode, loyalty attribution therefore moves to one nullable member on each Ticket.

## Decision

One Ticket has zero or one [[Pemilik tiket]], regardless of quantity. Different members require different Ticket lines. A member may be chosen on the CartItem before send, and `memberId` participates in stacking identity so otherwise identical lines owned by different members do not merge. The owner receives that line's percentage member tier, points, punch units, and purchase history independently of the payer, [[Pemilik struk]], and [[Pemilik tagihan]]. Unassigned Tickets remain valid sales but receive no member attribution and never fall back to another owner.

The bill-wide member gesture is a bulk shortcut over the explicit Ticket IDs present when the cashier acts. It is not stored as a bill default, so later Tickets begin unassigned and an offline replay cannot capture lines created after the gesture. A bulk change is atomic and refuses if any target is financially frozen.

Kitchen state does not freeze membership. An unpaid Ticket may be assigned, cleared, or reassigned; payment of the receipt containing it freezes the owner until that receipt is reopened. Paying an amount receipt freezes the otherwise-unitemized remainder it covers. `takeOrder` may choose a member only while creating a Ticket through a minimal identity lookup; later mutation keeps the existing `settleBill` capability. Both remain `memberSplit`-gated and server-authoritative, and settlement changes keep the existing journal, idempotency, and WebSocket update path.

Member tiers become percentage, line-scoped discounts with one slot per source per Ticket, so a member tier and one manual promo may stack without two promos of the same source stacking. Points still earn once at bill close: eligible Ticket bases are grouped by member and floored once per member per bill, net of allocated discounts and excluding service and tax. Punch and member product history read the same Ticket ownership snapshot. Redemption names one Ticket owner and distributes only across that member's editable lines.

Piutang belongs to the member explicitly confirmed on each `piutang` payment leg, because debt follows the person accepting responsibility for payment rather than the Ticket consumer or receipt label. One receipt may therefore contain multiple `piutang` legs naming different members, each checked against that member's own credit limit and reversed through its originating payment.

Live Tickets store a weak `member_id`; closed history snapshots it on each table-session Ticket. Closed visits never change. Visits already open when the schema is upgraded finish under ADR-0118, avoiding a half-paid bill whose frozen receipt attribution cannot be represented by the new one-owner-per-Ticket rule.

## Considered options

- **Receipt attribution (ADR-0118):** rejected because a payer, debtor, receipt label, and consumer may differ and one receipt may contain several consumers.
- **Bill-owner fallback:** rejected because it silently reintroduces bill-level ownership and makes an unassigned Ticket look attributed.
- **Quantity-level Ticket ownership:** rejected because it duplicates the receipt-line join and makes a Ticket cease to be the unit of attribution; separate Ticket lines express the exceptional mixed-quantity case.
- **Future-line inheritance after bill-wide assignment:** rejected because the shortcut would become hidden persistent state.

## Consequences

Customer-facing bills may derive a single member header only when every attributed Ticket has the same owner and none is unassigned; mixed bills label owners per line. Order-taking gains a minimal existing-member picker but does not expose profile data, enrollment, loyalty balances, debt, or settlement discounts. Kitchen screens and kitchen prints remain unchanged. Historical ADR-0118 rows remain readable through the legacy snapshot path rather than being rewritten.
