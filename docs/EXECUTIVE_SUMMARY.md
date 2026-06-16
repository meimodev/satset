# SatSet — Executive Summary

*A complete restaurant ordering and service system that runs on your own devices, over your own Wi-Fi.*

---

## In one sentence

SatSet turns ordinary Android phones and tablets into a full restaurant point-of-sale and service system — taking orders, routing them to the kitchen, splitting and settling bills, printing receipts, and reporting on the business — without depending on a monthly cloud subscription or a live internet connection to keep running.

---

## The problem we solve

Most modern restaurant software assumes two things that don't hold in a lot of real venues: a reliable internet connection and a willingness to pay an ongoing per-terminal fee forever. When the internet drops, cloud-based systems slow down or stop. As you add more tables and staff devices, the monthly bill climbs.

SatSet is built the opposite way. Everything that happens during a normal service — seating guests, taking orders, sending them to the kitchen, taking payment — happens **locally, over the restaurant's own Wi-Fi network**. One device acts as the "brain" of the venue; every other phone or tablet connects to it. There is no round-trip to a distant server for everyday work, so the system stays fast and keeps working even if the building's internet goes down.

This makes SatSet a strong fit for independent restaurants, cafés, and small chains — particularly in markets where connectivity is uneven and tight margins make recurring software fees painful.

---

## How it works, in plain terms

- **You need only Android phones or tablets** — the kind of devices most venues already own or can buy cheaply. There is no proprietary hardware to purchase.
- **One device is the host.** The manager's tablet runs the "venue brain." It holds the menu, the staff list, the live tables, and all the day's sales.
- **Every other device pairs to it in seconds** by scanning a QR code or picking the venue off the local network. Waiters carry phones; the kitchen has a screen; the cashier has a tablet — all talking to the same host.
- **The connection is private and secure** to the venue's own network. Staff sign in with a personal PIN, so every action is tied to a named person.
- **It speaks the local language and rules.** The interface is in Bahasa Indonesia, prices are in rupiah, and the bill math follows the standard Indonesian service-charge-then-tax convention out of the box.

A single app install does everything — the same download becomes either the host or a staff device depending on how it's set up. Nothing to provision separately.

---

## What it does across a service

### Floor and reservations
Staff see a live floor of every table with a colour-coded status — open, seated, waiting on the kitchen, or food-ready. They can take walk-ins or work from a reservations strip (name, party size, expected time, notes). Tables can be **moved** (transfer a whole party to another table in one tap) and **merged into the right party** so an old unpaid tab and a new group never get mixed up. The system gently prevents two waiters from editing the same table at once.

### Taking orders
Waiters build an order from a rich menu — categories, photos, sizes/variants, add-ons (spice level, protein choice), and special instructions. Allergen and dietary labels (e.g. gluten, vegan, halal) are shown clearly so staff can answer guest questions. A running estimate of the bill is shown as they go, calculated with the exact same tax and service math the cashier will use later, so the number a waiter quotes always matches the final bill.

Orders can be started **the classic way** (pick a table, then order) or **menu-first** (build the order, then decide where it goes), which also enables takeaway.

### The kitchen
Sent orders appear on a single, shared **kitchen display** in the order they arrived. Cooks mark items as cooking, ready, and done. The system tracks how long each dish has been waiting and raises an **audible alert** when something is running late, so nothing gets forgotten in a rush. When food is ready, waiters hear a separate chime — they don't need to be staring at a screen.

### Takeaway
Takeaway orders are handled as first-class orders that never occupy a table, tracked by guest name, with a clean "hand to guest" step. They're reported separately from dine-in so owners can see each channel's contribution.

### Guest self-ordering (optional)
Where the owner enables it, **guests can order from their own phones** by scanning a QR code at the table — no app to download, just a web page. Crucially, these orders **do not jump straight to the kitchen**: they land in a staff review queue first, so a waiter always confirms before anything is cooked. This keeps the pacing and control with the restaurant while saving the waiter the transcription step. It's strictly an addition to waiter service, not a replacement, and is off by default.

### Paying the bill
A dedicated **cashier screen** lists every open tab across the whole venue in one place. The cashier can:

- **Split a bill** — either itemised ("pay for what you ordered," down to individual units of a shared dish) or an even split among any number of guests.
- **Take partial payment** — one guest can pay and leave early while others stay.
- **Accept mixed payment methods** — cash, card, QRIS, transfer, or other, including split tender on a single receipt.
- **Show change** for cash, automatically.

Freeing the table and closing the money are treated as two separate acts that can happen in either order — so a waiter can clear a table for the next party while the bill is still being settled, and a guest can linger after paying. This reflects how service actually flows, rather than forcing an artificial "everything at once" close.

### Built-in safeguards for the money
- **Non-cash payments require a photo.** Every card/QRIS/transfer payment must be backed by a live camera photo of the proof at the moment it's recorded — protecting the owner against staff skimming and disputes. Cash is exempt.
- **Voids and corrections are accountable.** Cancelling an item requires a reason, and is tied to the staff member who did it. Cancelling something already served requires manager approval and is recorded as a refund, never quietly erased.
- **Unpaid walkouts are recorded as a loss**, distinct from legitimate manager comps, so the books tell the truth.
- **Every sensitive action is logged** against a named person.

### Printing
SatSet prints both **kitchen-confirmation slips** for guests (what was ordered, no prices) and **itemised bills and payment receipts** (with tax, service, totals, payment method, and change). It works with standard network and Bluetooth thermal printers — the inexpensive kind already common in the market — and a printer shared by the venue can be used by any device.

### Reporting and menu insight
Owners get sales reports by day, week, or month, including:

- Sales, covers (guests served), and averages.
- Staff performance, including void/cancellation rates.
- **Menu engineering** — every dish is classified by how well it sells *and* how profitable it is, with plain-language guidance: dishes to keep and promote, dishes to reprice, dishes to push, and dishes to consider cutting.
- Kitchen speed — how long food takes to prepare and how long it sits before pickup — measured against a target the owner sets.

Any report or the order history can be **exported to PDF or spreadsheet** and shared straight from the device.

---

## For owners of more than one venue

SatSet includes a **fleet control panel** for operators running multiple locations or for the company selling the software. From one place, an operator can create and manage venues and their managers, see which venues are online, track billing status, and — if a venue stops paying or breaks terms — remotely switch it off. Each venue's name and address are managed centrally and flow down to that venue's receipts automatically.

Day-to-day restaurant operation never depends on this panel being reachable; it's a management layer on top, not a dependency underneath.

---

## Why it's different

| What owners worry about | How SatSet answers it |
|---|---|
| "The internet here is unreliable." | Everyday service runs entirely on local Wi-Fi. Internet isn't needed to take orders or payments. |
| "I don't want another monthly bill per device." | Staff devices simply pair to the host — adding a waiter's phone doesn't add a subscription line. |
| "I need special hardware." | Runs on ordinary Android phones and tablets, with standard thermal printers. |
| "Staff could skim or hide mistakes." | Per-person PINs, mandatory photo proof for non-cash payments, reasoned and logged voids, manager-approved refunds. |
| "Bills are confusing to split." | Itemised or even splits, partial payment, mixed payment methods, automatic change. |
| "I can't tell which dishes actually make money." | Menu engineering report with plain-language recommendations. |
| "Software in English doesn't fit us." | Built in Bahasa Indonesia with local tax/service rules and rupiah. |

---

## Who it's for

- **Independent restaurants and cafés** that want professional order-taking, kitchen routing, and bill-splitting without enterprise cost or complexity.
- **Small and growing chains** that need consistent operations across locations plus a central view of the fleet.
- **Operators in connectivity-challenged settings** who can't risk a service that stalls when the internet does.
- **Owners who care about control and honesty in the cash drawer** — the accountability features are a core selling point, not an afterthought.

---

## The shape of the opportunity

The market is full of cloud point-of-sale products priced per terminal per month, designed for always-online environments. SatSet's positioning is deliberately contrarian: **local-first, hardware-light, language- and tax-native, and strong on staff accountability.** That combination is well suited to the large base of independent and mid-market venues that find global cloud POS too expensive, too internet-dependent, or too foreign to their way of working.

A sensible commercial model is a modest per-venue plan (rather than per-device), billed and toggled from the fleet panel already built in — letting a venue add as many staff devices as it likes without penalty, which lowers the barrier to adoption while keeping a predictable recurring revenue line per location.

---

*This document describes the product in business terms. Technical architecture and implementation details are maintained separately by the engineering team.*
