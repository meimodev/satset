# SatSet — Product Specification

**Version:** 2.0
**Status:** Canonical (supersedes v1.0, v1.1, v1.2)
**Audience:** Product, Design, Engineering Leadership

---

## 1. Executive Summary

SatSet is a real-time digital ordering platform built exclusively for hospitality staff. It replaces paper ticket systems and verbal communication between service floor and preparation zones (kitchen and bar) with a synchronized digital workflow.

The architecture is **LAN-first.** The kitchen Android tablet doubles as the local server; all order traffic stays inside the venue WiFi. When the venue has internet, the server mirrors data to the cloud in the background. **Operations never depend on internet being available.**

The core promise: an order placed by a waiter appears on the kitchen or bar display within a second — no tickets lost, no verbal miscommunication, no manual duplication. Service staff, kitchen staff, bar staff, expediters, and managers all work from the same live view of what has been ordered, what is being prepared, and what is ready to be served.

SatSet is designed for the realities of hospitality: loud environments, unreliable internet, and high-pressure rushes.

---

## 2. Problem Statement

Hospitality operations today suffer from a predictable set of friction points that SatSet eliminates:

- **Lost or misread tickets** — handwritten orders are illegible and misinterpreted under rush.
- **Communication gaps** — verbal call-outs between kitchen and floor are unreliable in noisy venues.
- **Delayed order visibility** — kitchens often receive orders in batches rather than in real time.
- **No course pacing coordination** — kitchens guess when to fire mains; floor staff have no structured way to coordinate timing.
- **No single source of truth** — managers have limited ability to monitor floor activity, item availability, or order status in real time.
- **No audit trail** — voids, comps, and corrections happen verbally and disappear.
- **Internet dependency halts service** — cloud-only systems fail when venue internet drops, which is frequent in many target markets.

---

## 3. Product Goals

| Goal | Description |
|---|---|
| Speed | Eliminate time between order entry and kitchen visibility |
| Accuracy | Remove ambiguity through structured digital inputs |
| Reliability | Operate continuously regardless of internet availability |
| Simplicity | Stay fast enough for use during peak service |
| Oversight | Give managers real-time visibility, control, and a full audit trail |
| Pacing | Coordinate courses across kitchen, bar, and floor |

---

## 4. Architecture Overview

SatSet operates on a **LAN-first** model with optional cloud mirroring.

### 4.1 Topology

```
                                ┌──────────────────────┐
                                │  SatSet Cloud        │
                                │  (Read-only mirror)  │
                                └──────────▲───────────┘
                                           │
                                  Internet (optional)
                                           │
                                ┌──────────┴───────────┐
                                │  KDS / Server Tablet │
                                │  (Android, kitchen)  │
                                └──────────▲───────────┘
                                           │
                              ─────────────┼─────────────
                              │            │            │
                       Venue WiFi (LAN) — TLS over local network
                              │            │            │
                  ┌───────────┘    ┌───────┘    ┌───────┘
                  ▼                ▼            ▼
            Waiter phones    Manager tablet  Expediter tablet
            (iOS/Android)    (iOS/Android)    (iOS/Android)
```

### 4.2 Key Properties

- **The KDS Android tablet is the server.** Same device, dual role. No separate server hardware in V1.
- **Server is Android-only.** iOS does not reliably host a long-running background service; iOS is fully supported for client devices.
- **The server is the source of truth.** All menu data, orders, audit logs, and venue config live on it.
- **Cloud is a read-only mirror.** When internet is available, the server pushes recent transactions to the cloud for remote admin access, off-site reporting, support, and backup. Cloud-side editing is not supported in V1.
- **Internet is optional.** Loss of internet has zero effect on in-venue operations. The cloud queue resumes pushing when connectivity returns.
- **Single server, no automatic failover in V1.** Manual recovery from a spare tablet, 5–15 minute target. Hot-standby failover ships in V1.1.

### 4.3 Security

- **Pairing** — Clients pair to the server by scanning a QR code displayed on the server tablet's "Pair Device" screen. The QR encodes the server's local address and a one-time auth token.
- **Transport** — Client/server traffic is TLS-encrypted using a self-signed certificate generated by the server on first run. The certificate is bound to each client at pairing; mismatched certs are rejected (protecting against server impersonation on the LAN).
- **Identity** — Every action checked against the signed-in user's role. Personal devices used for sign-in have sessions that expire at shift end with no local data persistence.

---

## 5. Target Segment & Personas

### 5.1 V1 Target Segment

Single-location independent and small-chain table-service venues:
- Casual dining restaurants (40–150 covers)
- Gastropubs and bars
- Cafés with table service

### 5.2 Out of V1 Target

- Resorts and hotels (multi-outlet — see V2)
- QSR / counter service (different workflow)
- Customer-facing ordering / QR menus (different product)

### 5.3 Primary Personas

**Maya — Floor Server.** 30, working a 120-cover bistro. Six tables at peak. Uses her own phone. Needs to send orders without breaking eye contact with guests, walks 8km a shift, hates apps that take more than two taps to do anything.

**Budi — Line Cook / Bar Lead.** Works the pass on the shared kitchen Android tablet (which also runs the local server). Speaks limited English. Needs to see the next 6 tickets without scrolling, flag items running low, and recall a ticket if marked ready by mistake.

**Sari — Floor Manager.** Runs the floor during service, handles closing on the POS, manages the menu before each shift. Owns the kill-switch and approves comps. Needs to glance at one screen and know the state of the venue.

**Wira — Expediter / Head Chef** (venues above ~80 covers). Calls plates from the pass. Needs full tables, not individual items. Fires courses, flags refires, coordinates timing.

---

## 6. User Roles

### 6.1 Service Staff (Waiters)

**Device:** Personal or venue-issued smartphone (iOS or Android), paired to the venue's local server.

Primary order-entry users. Interface must be fast enough to use tableside in seconds.

**Workflow:**
1. Sign in to shift via PIN.
2. Open active zone, select table.
3. Browse menu by category, tap items to add.
4. Complete required modifiers in the prompt that appears.
5. Assign each item to a course (Starters / Mains / Desserts / Drinks-Now / Drinks-With-Meal / custom).
6. Review summary, submit.
7. Receive push, audio, and haptic alert when items are ready.
8. Confirm collection and delivery (state advances to *Served*).

**Needs:**
- Large tap targets, high contrast for use in bright or dim environments.
- Add items to an existing open order (e.g., a second round of drinks) without disturbing what the kitchen has already done.
- Quick access to a table's full order history during service.
- Ability to fire later courses manually.

### 6.2 Kitchen & Bar Staff (Preparation Teams)

**Device:** Shared wall-mounted Android tablet. **This device also runs the local SatSet server** — every venue requires one.

The kitchen tablet is the most stable device in the venue: plugged in, stationary, in active use throughout service. Running the server on this device keeps hardware cost down and avoids a second always-on machine.

**Workflow:**
1. New tickets appear automatically, routed by station mapping.
2. Each ticket card shows table, course, items, quantities, modifiers, allergen flags, time elapsed.
3. Tap to mark *Preparing*, then *Ready*.
4. Bump recall — marked-ready tickets remain visible for 60 seconds and can be unmarked.
5. Refire flag if the kitchen identifies an issue mid-prep.

**Needs:**
- Visual distinction between new, in-progress, ready, and Held tickets.
- Audio and visual alerts for incoming orders.
- Per-item prep-time targets driving urgency color (not a single global threshold).
- IP54 splash-resistant case and dock.
- Server-status indicator visible at all times.

### 6.3 Expediter

**Device:** Tablet at the pass. Optional role, enabled per venue (typically above 80 covers).

Sees full table tickets across all stations on a single card per table. Fires courses, recalls tickets, marks refires, coordinates timing back to floor. Read-only view of expediter cards available to managers for oversight.

### 6.4 Managers & Venue Administrators

**Device:** Tablet or desktop browser.

Three sub-roles:

- **Owner** — full access including financial reporting, user management, voids and comps without limit.
- **Manager** — operational controls: kill-switch, void approval, comps up to a configurable threshold.
- **Floor Supervisor** — same as Manager minus comps over the configurable amount.

Workflow: live floor view, kill-switch, void/comp approvals, end-of-session reporting.

---

## 7. Core Product Features

### 7.1 Real-Time Order Synchronization

All synchronization happens over the venue LAN against the local server.

- Orders submitted by waiters reach the KDS server at typical LAN latency: P50 < 300ms, P95 < 800ms.
- Any status change reflects on all paired clients near-instantly.
- No internet required for any synchronization.
- No manual refresh anywhere — the system is always live.

**Order Lifecycle:**

```
Draft → Sent → Acknowledged → Preparing → Ready → Served
```

| State | Triggered By | Visible To |
|---|---|---|
| Draft | Waiter building order | Waiter only |
| Sent | Waiter confirms submission | Kitchen / Bar / Expo, Manager |
| Acknowledged | Station receives ticket (auto on KDS; manual on offline-buffer recovery) | Waiter, Manager |
| Preparing | Station marks in-progress | Waiter, Manager |
| Ready | Station marks complete | Waiter (push/audio/haptic alert), Manager |
| Served | Waiter confirms collection and delivery | Manager |

Payment is handled outside SatSet. *Served* is the terminal state; external POS handles billing.

### 7.2 Course Firing & Pacing

Every item is assigned to a course at order entry. All items submit together, but only the first course (and any *Drinks-Now* items) auto-fire to the kitchen. Later courses sit in *Held* state, visible but greyed out on the KDS.

- The waiter (or expediter, if present) fires the next course manually when ready.
- Items can be re-paced after submission (move *Held* → *Fire Now*, or vice versa).
- KDS shows fire-time targets per course.
- Course definitions are configurable per venue.

The default course for every item is *Fire Now*, so venues that don't use course pacing don't need to think about it.

### 7.3 Order Modification, Void & Comp

After submission:

- **Add items** to an existing order — appears as a follow-up ticket on the KDS marked *ADD* with sequence number, never silently appended to the original ticket.
- **Modify item before Preparing** — instant, no approval needed.
- **Modify item after Preparing** — requires station acknowledgement ("we can still change this" / "too late").
- **Void item** — requires manager PIN or sub-role permission. Reason code required: sent-in-error, customer-changed-mind, allergy, complaint, other.
- **Comp item** — manager-only with full audit trail. Affects reporting.
- **Refire** — kitchen-initiated. Ticket reopens with a refire flag visible to floor.

All mutations logged with user, timestamp, and reason.

### 7.4 Structured Menu, Variants & Modifiers

- Items belong to a **category** and route to a **station** (Kitchen / Bar / Coffee Bar / Custom).
- **Variants** (size, format) are separate SKUs with separate pricing and availability.
- **Modifiers** attach to a variant. Single- or multi-select. Required or optional.
- **Modifier pricing** — each modifier option can carry a price delta (positive or negative). Modifiers can also be cost-neutral.
- **Allergen tags** — structured list (gluten, nut, dairy, shellfish, egg, soy, sesame). Not freeform.
- **Special instructions** — freeform text, last resort, capped at 80 characters, displayed in red on the KDS.

### 7.5 Auto-Routing Between Stations

Every menu item carries a station mapping. On submission, the order auto-splits into station-specific tickets. The waiter sees one combined order; each station sees only its own items. Cross-station tickets are linked by a shared order ID so the expediter view can reconstruct the full table.

### 7.6 LAN Architecture & Cloud Sync

#### Local Server (KDS Tablet)
The kitchen Android tablet holds the authoritative copy of menu, orders, audit log, staff sessions, and venue configuration. All client devices connect to it over venue WiFi.

#### Client/Server Pairing
New clients pair by scanning a QR code on the server's "Pair Device" screen. No manual IP entry, no typing of credentials. Pairing binds each client to that server's identity.

#### Local-Network Security
TLS encryption using a self-signed certificate generated by the server on first run. Mismatched certs on subsequent connections are rejected.

#### Internet Behavior

| Internet State | Effect on Venue |
|---|---|
| **Up** | Server pushes recent transactions to cloud in background. Cloud holds a read-only mirror for remote access, reporting, support, and backup. |
| **Down** | Local operations are unaffected. The server queues outbound cloud updates and resumes pushing when internet returns. **This is the normal mode, not a degraded mode.** |

Cloud is a mirror, not a source of truth. Menu and configuration edits happen on the server (in-venue). Cloud-side admin is read-only in V1. Bidirectional sync with conflict resolution is deferred to V2.

#### WiFi Requirements
Venue must provide WiFi covering all service zones with sufficient bandwidth for the number of paired devices. SatSet's onboarding checklist includes a router recommendation and a signal-strength test step performed during setup. SatSet does not ship a router in V1; a spare consumer router is recommended in the venue setup kit.

#### Server-Tablet Failure (V1)
If the server tablet fails mid-service, all clients lose connection and active orders pause. Recovery:

1. Power on the spare Android tablet (shipped in the venue setup kit).
2. Spare restores from the most recent cloud backup (if internet available) or from the venue's local backup storage device.
3. Clients re-pair to the new server via QR.
4. Resume service.

**Target recovery time: 5–15 minutes.** Hot-standby with automatic failover ships in V1.1.

### 7.7 Kitchen Display System (KDS)

The KDS is the kitchen and bar-facing view, replacing the physical ticket rail with a live touch-interactive display.

- Tickets appear as cards in a queue, ordered oldest to newest.
- Each card shows table, course, time elapsed, items, modifiers, allergens.
- Per-item prep-time targets drive urgency color (not a single global threshold).
- 60-second bump recall on marked-ready tickets.
- Held vs. Fired states clearly differentiated.
- Auto-refresh, no manual reload.
- Audio and visual alerts on incoming orders.

### 7.8 Expediter View

Available on tablet at venues that enable the role.

- One card per active table showing all in-flight items across all stations.
- Course-by-course timing: when did Starters fire, when are Mains expected.
- *Fire Course*, *Recall*, *Refire* controls.
- Read-only view available to managers for oversight.

### 7.9 Manager Controls

**Item Kill-Switch.** Instant disable from admin panel. Item disappears from waiter menus immediately and cannot be added to new orders. Existing orders unaffected. Propagation P95 < 500ms over LAN.

**Live Floor View.** Grid of zones and tables, color-coded by status (Available, Occupied, Order Pending, Ready to Collect). Surfaces alerts:
- Table waiting > 12 minutes for first item
- Station backlog over configurable threshold
- KDS / server health degraded
- High void rate in current shift

**Session Reporting (V1 minimal):**
- Covers per zone
- Items sold — top 10, bottom 10
- Average time Sent → Ready, per station
- Voids and comps with reason codes

Anything beyond this is V2.

### 7.10 Authentication, Identity & Audit

- **Shift sign-in** — staff sign in with PIN on the venue's primary device at start of shift. Session can be promoted to personal devices for the duration of the shift.
- **Role enforcement** — every action checked against role.
- **Audit log** — every void, comp, kill-switch toggle, and post-send modification logged with user, timestamp, and reason. Owner-accessible.
- **BYOD policy** — personal devices supported. Session expires at shift end. No order data persists locally after sign-out.

### 7.11 Physical Ticket Printing (Paid Add-On Module)

Available as a paid add-on, not core V1.

- **Bluetooth** — printer paired directly to a phone or tablet
- **LAN / WiFi** — printer joins the venue WiFi; any paired client can print via the local server

Default off; opt-in per venue. Delivery confirmation loop — if a print fails, the waiter is alerted and can reprint from the order detail view. No internet required for either connection mode.

### 7.12 Server Status Visibility

A dedicated server status screen on the KDS tablet displays at all times:
- Server health (green / amber / red)
- Connected client count
- Cloud sync status (synced / pending / offline)
- Storage usage
- Time since last successful cloud push
- Battery and charging status

Designed to surface problems before staff notice them.

---

## 8. UX Principles

**Speed over features.** Every extra tap is a cost. A waiter should select a table, build an order, and submit it in under 30 seconds for a typical 2–3 item order.

**Legibility in all conditions.** High-contrast pairings. Large fonts on primary actions and item names. Readable in bright outdoor sunlight and dim bar environments.

**Error prevention, not recovery.** Required modifiers before items add. Clear order summary before submission. Reason codes before voids.

**Consistent feedback.** Every action produces immediate visual, audio, or haptic feedback so users never second-guess whether a tap registered.

**Constrain freeform input.** Allergens are structured tags. Special instructions are a last resort, capped, and visually flagged on the KDS.

**LAN-first means zero-friction reliability.** Users should not need to know whether the venue has internet. The app behaves the same way either way.

---

## 9. Key Screens

### 9.1 Table / Zone Map (Waiter)
Grid or floor-plan of all tables, grouped by zone. Status color-coded (Available, Occupied, Order Pending, Ready to Collect). Tapping a table opens it for order entry.

### 9.2 Product Menu / Order Entry (Waiter)
Category-browsable grid with images, names, prices. Tapping an item with required modifiers opens a sheet. Persistent order summary footer. Course selector visible during item add.

### 9.3 Order Review & Submission (Waiter)
Full-screen summary grouped by course. Shows table, items, modifiers, allergens, special notes, totals. Confirmation button sends.

### 9.4 Ticket Card (KDS)
Condensed card showing table, course, time elapsed, items, modifiers, allergens. *Start Preparing* and *Mark Ready* are large and visually differentiated. Held tickets visibly distinct.

### 9.5 Expediter Card
One per active table. All items across all stations grouped by course. *Fire Course*, *Recall*, *Refire* controls.

### 9.6 Admin Panel (Manager)
Menu list with availability toggle (kill-switch). Live floor map. Reporting tab. Audit log access.

### 9.7 Server Status (KDS Tablet)
Always-visible health summary. Connected clients, cloud sync state, storage, battery, alerts.

### 9.8 Pair Device (Server Tablet)
QR code for client pairing, with revoke/regenerate options.

---

## 10. Onboarding & Setup

Four phases. Target time-to-first-order: **< 4 hours of admin work for a 60-cover venue.**

**Phase 1 — Account & Venue (Day 1, ~30 min).**
Owner signs up via cloud admin, creates venue profile, invites managers.

**Phase 2 — Server Tablet Setup (Day 1, ~20 min).**
1. Unbox and dock the kitchen Android tablet in its wall mount.
2. Install the SatSet app and switch to **Server Mode**.
3. Run the setup wizard — server generates its TLS certificate and pairing QR.
4. Connect to venue WiFi.
5. Run signal-strength test across all service zones using a client device.

**Phase 3 — Menu, Floor Plan & Stations (Day 1–2, 1–3 hrs).**
Built on the server tablet or remotely via cloud read/write admin during setup phase. Spreadsheet import template or manual entry. Items assigned to stations and modifier groups. Floor plan via grid editor.

**Phase 4 — Team & Client Pairing (Day 2–3).**
Staff invited via SMS link. Each device pairs to the server by scanning the QR. PIN setup. Role-specific in-app tutorial.

Optional concierge setup call for venues above 80 covers.

---

## 11. Hardware Requirements

### 11.1 Venue Setup Kit (Recommended)

Shipped pre-tested by SatSet:
- 1× Android tablet (server + KDS), 8" minimum, Android 12+, 4GB+ RAM, 64GB+ storage
- 1× spare Android tablet, identical model
- 1× spare consumer router (recommended; venue may supply their own)
- 1× tablet wall mount
- 1× IP54 splash-resistant case
- 1× charging dock with cable management
- 1× local backup storage device (USB-attached, for cloud-less recovery scenarios)
- Setup checklist and signal-test app

### 11.2 Client Devices

- Waiter handhelds: iOS 16+ or Android 11+, smartphone form factor
- Manager device: iOS 16+ or Android 11+ tablet, or modern desktop browser
- Expediter tablet: iOS 16+ or Android 11+, 10" recommended

### 11.3 Printer (Optional)

- Bluetooth thermal receipt printer, OR
- LAN/WiFi thermal receipt printer
- Must support 80mm standard receipt format

### 11.4 Network

- 2.4GHz/5GHz dual-band WiFi router
- Coverage tested across all service zones during setup
- Internet connection is optional (recommended but not required for operation)

---

## 12. Out of Scope (V1)

| Feature | Rationale |
|---|---|
| Customer-facing ordering / QR menus | Different product category |
| Payment / POS integration | External handoff in V1 |
| Multi-venue / resort multi-outlet | V2 |
| Bidirectional cloud sync / remote menu editing | V2 |
| Hot-standby server failover | V1.1 |
| SatSet-provided WiFi hardware | Venue supplies router |
| Staff scheduling / HR | Outside ordering workflow |
| Loyalty / CRM | Outside ordering workflow |
| AI demand forecasting | Post-launch analytics product |
| Inventory management | V1 tracks availability flag only |
| Multi-language menus beyond English + Bahasa Indonesia | V2 |

---

## 13. Roadmap

### 13.1 V1.1 (Next Release After V1)

- **Hot-standby server failover.** Secondary tablet maintains continuously replicated copy of server state. On primary failure, secondary self-promotes and clients reconnect automatically.

### 13.2 V2

- Multi-outlet / resort tier (centralized menu, cross-outlet reporting, shared staff pools)
- POS integration & payment
- Inventory tracking with auto-86
- Multi-language menus (5+ languages)
- Bidirectional cloud sync with conflict resolution
- Advanced analytics (revenue, item profitability, staff performance, peak-hour analysis)
- Customer ordering surface (QR / web order)
- Public API for third-party integrations

---

## 14. Success Metrics

| Metric | Target |
|---|---|
| Order transmission time (Sent → Visible on KDS), P50 | < 300ms over LAN |
| Order transmission time, P95 | < 800ms over LAN |
| Waiter order entry time (3-item order, light modifiers) | < 45s |
| Order error rate vs. paper baseline | ≥ 50% reduction |
| Local server uptime during defined service hours | ≥ 99.9% monthly |
| Operation continuity during internet outage | 100% — zero service interruption |
| Cloud sync recovery after internet restoration | 100% of queued transactions within 5 minutes |
| Manager kill-switch propagation (over LAN), P95 | < 500ms |
| Time-to-first-order for new venue (60 covers) | < 4 hours admin work |
| Spare-tablet recovery time after server failure | < 15 minutes |
| Audit log completeness | 100% of voids, comps, kill-switch events logged |

---

## 15. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Server tablet single point of failure (V1) | Spare tablet in setup kit; documented 5–15 min manual recovery; hot standby in V1.1 |
| Venue WiFi router failure halts service | Spare consumer router in setup kit; SatSet remote diagnostic when internet is up |
| Server tablet sleep / Android Doze interrupts service | Setup wizard locks display-on and disables sleep; battery health monitored and surfaced in server status screen |
| Android tablet model fragmentation | Published supported-models matrix; releases gated on test matrix |
| iOS waiter phones cannot host the server | Documented; not a concern given Android-only server policy |
| Cloud → server bidirectional editing blocked in V1 | Acceptable: most edits happen in-venue. Remote editing arrives in V2 |
| Bluetooth printer reliability | Demoted to opt-in add-on; delivery confirmation loop required |
| BYOD security exposure on waiter phones | Session expiry at shift end, no local persistence, audit log of personal-device sign-ins |
| Tablet aging / replacement cycle | Recommend 24-month replacement cadence; lifecycle reminders in admin panel |
| Resort sales pipeline impact (deferred to V2) | Confirm with sales whether current deals depend on multi-outlet before scope freeze |

---

## 16. Open Items Requiring Stakeholder Input

1. **Pricing model.** Per device, per location, per order, hybrid? Affects feature-gating decisions and the V2 roadmap.
2. **Paper-baseline error rate.** Pilot venues must be instrumented to measure pre-SatSet error rates so the success metric in §14 has a real comparison.

---

*Technical architecture, API design, and the LAN protocol & pairing handshake specification are maintained separately in the Engineering Specification.*
