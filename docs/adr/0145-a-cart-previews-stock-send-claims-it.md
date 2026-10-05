# A cart previews stock; send claims it

Status: accepted

SatSet already holds stock on ingredients, derives **Habis** through recipes (ADR-0040), and deducts stock atomically when an order is sent (ADR-0041). A connected waiter's cart must reflect what the host can make now, without implying that an unsent cart reserves those ingredients. This decision keeps send as the claim on stock while making known shortages visible before a waiter promises a dish.

## Decision

- The host calculates **available portions** for the exact item, variant, and modifier options. It accounts for the ingredient demand of the other lines in the same cart, including different dishes sharing an ingredient. An item has no separate stock balance; a product sold by the unit uses a one-to-one ingredient recipe. A recipe-less item has no stock-based limit.
- While connected, the menu, an open modifier sheet, and the cart react to host stock and menu changes. The menu tile shows the simple **Habis** state; the quantity control explains a relevant portion limit. A line that becomes unavailable stays visible with its reason and must be adjusted before sending. No line disappears silently.
- The host checks again inside the order transaction. If another order wins the last portion, covered lines may still be accepted (ADR-0041); rejected lines remain in the waiter's cart with the host's reason, while accepted lines leave it.
- Manual **Habis** is enforced at selection and send, even when ingredients remain. It is cleared through the `markSoldOut` action. The `overrideStock` capability permits an ingredient shortfall only through an explicit, reasoned action recorded in the audit trail; merely holding the capability does not bypass the guard.
- A disconnected device shows that availability is stale and may still capture orders. A captured line remains authoritative on reconnect, even if stock is then short; the host records and audits the negative balance as ADR-0139 requires.

## Why

Reserving stock when someone taps a cart would hold ingredients for abandoned orders and require a new expiry and conflict protocol across devices. A preview can be stale, so the final transaction still decides the race. Requiring an explicit override prevents a granted capability from silently turning an ordinary waiter action into a sale past zero. Keeping partial acceptance avoids making a waiter re-enter covered dishes, while retaining rejected lines gives them a direct path to repair the order.
