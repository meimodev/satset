# Member-per-Ticket attribution — decision review

Status: recommended answers accepted provisionally on 2026-09-02. Push back by question number (for example, “change Q15”).

## Domain model

| # | Question | Chosen answer | Why this is the recommendation | Alternatives rejected |
|---|---|---|---|---|
| Q1 | Budi consumed a Ticket and Ani paid its receipt. Who receives points, tier discount, and purchase history? | **Budi, the Ticket owner.** | Consumption and payment are different facts. | Ani as payer; receipt owner; bill owner. |
| Q2 | Is an “order ticket” one menu line or one send batch? | **One Ticket line.** A send remains a Batch. | Matches the existing code and glossary. | One owner per Batch. |
| Q3 | Can two Tickets from one Batch have different members? | **Yes.** | The Batch is kitchen timing, not customer identity. | Force one member across a send. |
| Q4 | A Ticket has `qty: 3`; may ownership split 2+1? | **No. One owner for the whole Ticket.** Different members require separate Ticket lines. | Avoids a second quantity-level join beside receipt lines. | Quantity join; arbitrary first owner. |
| Q5 | What is bill-wide member assignment? | **An atomic shortcut over the explicit Ticket IDs that exist when invoked.** | Keeps Ticket ownership as the only attribution truth. | Store a second bill-level attribution. |
| Q6 | Do Tickets created after bill-wide assignment inherit its member? | **No; they begin unassigned.** | Inheritance would turn the shortcut into hidden bill state. | Persistent default; inherit from bill owner. |
| Q7 | Does an unassigned Ticket fall back to the bill or receipt owner? | **No. Settlement proceeds, but it has no loyalty attribution or member history.** | “Unassigned” must remain honest. | Block settlement; implicit fallback. |
| Q8 | Is per-Ticket attribution always enabled with membership? | **No; retain the existing `memberSplit` mode gate.** | Avoids changing every venue’s loyalty semantics during rollout. | Always on; new mode key. |
| Q9 | What happens outside `memberSplit`? | **The current single bill-owner behavior remains unchanged.** | Compatibility with venues that did not select split attribution. | Remove legacy behavior globally. |
| Q10 | What remains the role of `Pemilik tagihan`? | **The Visit’s party/floor identity only under `memberSplit`; it does not own Tickets implicitly.** | Reservations and `guestName` still need a Visit identity. | Delete bill owner; use it as fallback. |
| Q11 | What remains the role of `Pemilik struk`? | **An optional receipt label/member association only.** It controls neither loyalty nor Piutang. | The debtor is named by the `piutang` payment leg; the consumer is named by each Ticket. | Delete receipt member; let it override Tickets; use it as debtor. |
| Q12 | Can an amount receipt have a receipt owner even though it has no Ticket lines? | **Yes, for labeling the named share only.** | An even share may still be handed to a known member without inventing consumption or debt attribution. | Invent Ticket ownership for an amount claim; forbid named shares. |

## Loyalty and money

| # | Question | Chosen answer | Why this is the recommendation | Alternatives rejected |
|---|---|---|---|---|
| Q13 | Where does a member tier discount apply on a mixed bill? | **Only to that member’s Tickets, as line-scoped discounts.** | Ani’s tier must not discount Budi’s food. | Receipt-wide; bill-wide; payer’s tier. |
| Q14 | May a fixed-amount preset be the automatic member tier under `memberSplit`? | **No; the automatic tier must be percentage-based.** | Repeating Rp25k per Ticket silently multiplies the benefit. | Repeat fixed amount; distribute a fixed amount across lines. |
| Q15 | Can a member tier and a cashier’s manual line promo stack? | **Yes, one discount per source per Ticket.** Two manual promos still cannot stack. | Preserves the existing `manual/member/redeem` source model without making the automatic tier suppress an intentional promo. | Largest wins; manual replaces tier; no stacking at all. |
| Q16 | How do bill/receipt-wide discounts affect member points and history? | **Allocate them proportionally across eligible Ticket values with deterministic remainder handling.** | Member shares must reconcile exactly to the settled bill. | Ignore shared discounts; assign all rounding to bill owner. |
| Q17 | At what grain are points rounded? | **Group each member’s Ticket base for the bill, then floor once per member at bill close.** | Avoids losing points by flooring every small Ticket. | Floor per Ticket; floor per receipt; floor once for the whole bill. |
| Q18 | Which units advance the punch card? | **Qualifying, non-voided, non-comped units on that member’s Tickets.** | Punch tracks consumption and follows the same ownership truth. | Receipt lines; bill owner; payer. |
| Q19 | How does member history count a mixed bill? | **One visit per distinct Ticket owner; products are their Tickets; spend is their net Ticket value plus proportional service/tax.** | Shows what they consumed while keeping member and unassigned shares equal to settled revenue. | Count only payer; omit service/tax; duplicate the whole bill total per member. |
| Q20 | Who may redeem points on a mixed bill? | **Choose one Ticket owner; redemption is capped to and distributed across only that member’s editable Tickets.** | Spending a member balance should not discount another member’s consumption. | Bill owner redeems across all; receipt owner redeems across all. |
| Q21 | Who incurs Piutang when Ani pays Budi’s Tickets on account? | **Ani: the member explicitly named on that `piutang` payment leg.** Debt follows the person taking responsibility for payment, never Ticket or receipt ownership. | One receipt can contain several consumers, and the person promising payment is an independent fact. | Split debt by Ticket ownership; infer debtor from receipt owner; infer debtor from bill owner. |
| Q22 | Does a member-tier change retroactively alter an unpaid Ticket? | **Yes; resolve/recompute until payment, then snapshot the applied discount.** | Unpaid money is still editable; paid money must not drift. | Snapshot tier at order send; recalculate paid receipts. |

## Lifecycle and corrections

| # | Question | Chosen answer | Why this is the recommendation | Alternatives rejected |
|---|---|---|---|---|
| Q23 | Does kitchen status freeze Ticket ownership? | **No. Held, sent, prep, ready, and served Tickets remain assignable while financially unpaid.** | Membership does not rewrite the kitchen’s order. | Reuse the held-only line-edit guard. |
| Q24 | When does Ticket ownership freeze? | **When the receipt containing it receives payment. Reopening that receipt unlocks it.** | Matches the existing money-freeze boundary. | Freeze at send; freeze only at bill close. |
| Q25 | What does a paid amount receipt freeze? | **All then-unitemized Tickets whose remainder it covers.** | An amount claim has no line join, so changing those Tickets could move the paid total underneath it. | Leave every Ticket editable; invent a synthetic allocation. |
| Q26 | What if bill-wide assignment includes one frozen Ticket? | **Reject the whole bulk action atomically and identify the frozen Ticket/receipt.** | A command named “all” must not silently become partial. | Skip frozen lines; partially apply then warn. |
| Q27 | Can a cashier clear or reassign an unpaid Ticket owner? | **Yes; replace/remove its automatic member discount in the same transaction.** | Identity and its monetary consequence must not drift. | Append assignments; leave stale discounts. |
| Q28 | What happens when a Ticket is voided? | **Keep its owner for audit, but exclude it from discount, points, punch, and purchase history.** | Voiding should not erase who it was for, but it is no purchase. | Clear owner; keep rewards. |
| Q29 | What happens after reopening and reassigning a closed/paid bill? | **Reverse prior earns through the existing ledger path, then recompute on re-close.** | Append-only ledgers retain a truthful correction trail. | Rewrite old point rows; adjust only the new owner. |
| Q30 | What happens if an assigned member is deleted? | **Keep the weak ID and render “Pelanggan dihapus”; skip new balance writes if the profile no longer exists.** Unpaid Tickets may be reassigned. | Deletion must not rewrite historical attribution. | Cascade-clear every Ticket; block all member deletion. |
| Q31 | What happens when members merge? | **Repoint live Ticket ownership and closed snapshots to the survivor, alongside existing ledgers.** | Merge declares both identities were one person. | Preserve absorbed IDs forever; treat merge as reassignment. |

## UX and permissions

| # | Question | Chosen answer | Why this is the recommendation | Alternatives rejected |
|---|---|---|---|---|
| Q32 | Where is first-version assignment exposed? | **In both order-taking and the cashier bill:** a member picker on each CartItem/Ticket plus the existing bill-wide cashier shortcut. | Order-time selection is the only clean way to prevent differently owned identical items from stacking into one Ticket. | Cashier only; kitchen board; new screen. |
| Q33 | Should order-taking/cart gain member controls now? | **Yes. Add nullable `memberId` to CartItem and its stacking identity.** Identical items stack only when their member IDs also match. | Makes the accepted one-owner-per-Ticket rule expressible before the kitchen freezes quantity edits. | Cashier-only assignment; quantity-level ownership join. |
| Q34 | How is a mixed bill shown? | **Member chip/name per Ticket; derive a single header label only when every Ticket is attributed to the same member.** | The display mirrors the real grain without storing a duplicate header owner. | Always show bill owner; group/reorder Tickets by member. |
| Q35 | How does bill-wide overwrite an already mixed bill? | **Require confirmation, then atomically replace every editable target.** | Prevents a one-tap loss of careful per-line assignments. | Merge only blanks; overwrite silently. |
| Q36 | Is there a bill-wide clear action? | **Yes, with confirmation, over the same explicit current Ticket set.** | Assignment and removal should be symmetric. | Clear each Ticket manually. |
| Q37 | Does member identity print on kitchen tickets/KDS? | **No.** It may print on customer bill/payment documents, per line when mixed. | Kitchen production does not depend on loyalty identity. | Add member labels throughout the KDS. |
| Q38 | Which capability authorizes assignment? | **`takeOrder` may set the member while creating a Ticket; `settleBill` may assign, clear, or reassign live Tickets.** Both remain server-enforced and `memberSplit`-gated. | Creation and settlement are already separate authorized acts. | Give waiters settlement mutation; use `modifyOrder`; add a new capability. |

## Persistence, API, offline, and migration

| # | Question | Chosen answer | Why this is the recommendation | Alternatives rejected |
|---|---|---|---|---|
| Q39 | What is stored on a live Ticket? | **Nullable weak `member_id`, indexed, with no foreign-key cascade.** | Minimal representation; member deletion cannot erase sales. | Embed Member; join table; bill-only field. |
| Q40 | What is frozen at bill close? | **`member_id` on each table-session Ticket snapshot.** | History and loyalty must survive live-row/member changes. | Reconstruct from receipts; store only aggregate member totals. |
| Q41 | How is member identity transported? | **Cart/order payload and Ticket DTO carry `memberId`; bill projections may include resolved `memberName`; each `piutang` payment carries its own debtor `memberId`.** Live rows store IDs only. | Avoids stale duplicated profiles while preserving the independent consumer and debtor facts. | Embed full Member objects; infer debtor from Ticket/receipt. |
| Q42 | Which mutation surface owns assignment? | **Dedicated settlement attribution endpoints/events for single and bulk assignment, not the existing held-only Ticket edit endpoint.** | Kitchen edits and financial attribution have different freeze rules and capabilities. | Add `memberId` to generic Ticket PATCH. |
| Q43 | How is bill-wide assignment made replay-safe offline? | **Journal the explicit Ticket IDs captured at tap time under one idempotency key.** | A delayed replay must not assign Tickets created later. | Replay “all Tickets currently on bill”; client loop of individual writes. |
| Q44 | What happens on a stale/offline assignment? | **A standalone settlement assignment parks with a machine-readable failure. An offline food order still submits if its chosen member vanished; that Ticket lands unassigned and the response carries an attribution warning.** | Optional CRM attribution must not discard or delay food, while an explicit later correction must not disappear silently. | Reject the whole food order; silently attach a different member; retry forever. |
| Q45 | How do other clients update? | **Broadcast the existing Ticket-updated wire shape after the transaction; repositories merge authoritative Tickets.** | Reuses the current resync/WS path. | New member-assignment cache or event model. |
| Q46 | Is assignment audited? | **Yes: one audit event per user action with actor, old/new member, and affected Ticket IDs.** | The act changes discounts and durable loyalty history. | One audit row per Ticket; no audit. |
| Q47 | What happens to visits already open during upgrade? | **They finish under ADR-0118 receipt attribution; only newly opened visits use Ticket attribution.** | Avoids an unrepresentable half-paid visit with frozen qty-level receipt ownership. | Backfill heuristically; force reopen every receipt; rewrite history. |
| Q48 | What happens to closed history? | **Never rewrite it. Legacy snapshots continue through the ADR-0118 read path; new snapshots use ADR-0125.** | Historical money and loyalty must remain immutable. | Bulk migrate old attribution. |

## Verification and explicit omissions

| # | Question | Chosen answer | Why this is the recommendation | Alternatives rejected |
|---|---|---|---|---|
| Q49 | What is the smallest durable verification set? | **Migration parity; gate/capability; single/bulk atomicity; future-line exclusion; freeze/reopen; discount replacement/stacking; points/punch/history grouping; legacy-visit compatibility; one cashier layout test.** | Covers every non-trivial invariant without a test per helper. | Snapshot every widget; rely only on analyzer. |
| Q50 | What is deliberately not part of this change? | **No quantity-level owner join, future-line default, new capability/mode, KDS changes, or new dependency.** | Cart-level selection is included, but a generalized guest-allocation subsystem is not. | Build quantity allocations, inherited defaults, or KDS membership. |

## Re-grill after Q21 and Q33 pushback

| # | Question | Chosen answer | Why this is the recommendation | Alternatives rejected |
|---|---|---|---|---|
| Q51 | Where is the debtor stored? | **On each `piutang` Payment leg as `member_id`, copied to its debt charge.** | The payment act is where somebody accepts the debt. | Receipt member; Ticket member; bill member. |
| Q52 | Can one receipt put separate amounts on two members’ tabs? | **Yes, as two `piutang` payment legs, each with its own member and amount.** | Split tender already models several payment legs; no new debt split entity is needed. | One debtor per receipt; split by Ticket. |
| Q53 | May the debtor be inferred or defaulted? | **The cashier must explicitly confirm a member for every `piutang` leg; no Ticket/bill fallback.** A visible preselection is allowed only as an editable suggestion. | Debt is high-stakes and must name who promised payment. | Silent receipt-owner fallback; bill-owner fallback. |
| Q54 | What member data may order-taking search expose? | **A minimal `memberSplit`-gated lookup: ID, name, and masked phone only; no history, points, debt, address, or profile editing.** | Waiters need identity selection, not CRM access. | Reuse the full directory payload; hide the picker from waiters. |
| Q55 | Does choosing a CartItem member change the cart estimate? | **No.** The cart records ownership, but tier discounts remain settlement-stage and the estimate remains undiscounted. | Preserves the existing Estimasi promise and avoids discount logic in ordering. | Preview/apply member discount in cart. |
| Q56 | Can order-taking enroll a new member from the CartItem picker? | **No; lookup existing members only.** Enrollment remains under the established membership/settlement flow. | Avoids turning a quick order gesture into data-quality/profile creation. | Inline enrollment; free-text pseudo-member. |
| Q57 | What happens when CartItem ownership changes? | **Re-run the existing stack merge using `memberId` as part of identity; same-member identical lines merge, different-member lines stay separate.** | Preserves existing stacking behavior while enforcing one owner per Ticket. | Never re-stack; keep member outside equality. |

## Implementation map

The change should stay in the existing modules:

- database migration and Ticket/session snapshot columns in `lib/server/db/database.dart`;
- Ticket and CartItem domain/DTO/repository wire plumbing, including the stacking key;
- dedicated assignment handling beside settlement routes and the existing offline settlement journal;
- a minimal member lookup for `takeOrder` and a member picker on CartItem;
- debtor `memberId` on each `piutang` payment leg and its reversal path;
- member reward/history calculations in `lib/server/members.dart` and bill-close flow;
- cashier line chips and bulk shortcut in the existing bill/member panel;
- focused schema, server invariant, reward, and cashier layout tests.

No implementation has been performed in this grilling session. The canonical glossary is updated in `CONTEXT.md`; ADR-0125 records the architectural reversal, and ADR-0118 plus ADR-0120 are marked superseded for new visits.
