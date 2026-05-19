# Product Specification: SatSet

**Tagline:** *Solusi Cepat, Kerja Akurat.* **Product Concept:** A high-speed, internal ordering ecosystem designed to bridge the gap between service staff and the kitchen in real-time — operating entirely on the local network.

---

## 0. Architecture & Network Topology

SatSet operates **100% locally** — no cloud, no internet dependency. All data stays inside the venue's WiFi network.

### Main Device (Server)
- One designated powerful device (typically the **Kitchen Tablet** or a small **Admin PC/NUC** in the back office).
- Hosts the embedded database (SQLite) and the realtime broadcast hub (WebSocket server).
- All orders, menu data, and venue configuration live here.
- Acts as the single source of truth for all connected Host devices.

### Host Devices (Clients)
- Waiter **handhelds**, bar tablets, and the manager's **admin tablet**.
- Each Host connects to the Main Device's IP address over the local WiFi.
- No device communicates directly with another Host — all traffic routes through the Main Device.

### Realtime Transport
- **WebSocket over LAN** — a persistent, bidirectional connection between each Host and the Main Device.
- When an order is "Sent" from a handheld, the Main Device broadcasts the event to the Kitchen tablet in **<0.5 seconds**.
- Status updates (Received → Cooking → Ready) are pushed to all relevant Hosts instantly.

### Fallback & Resilience
- If a Host briefly loses WiFi, it queues orders locally (in-memory) and flushes them on automatic reconnect.
- The Main Device can run headless if needed (no UI required beyond a tray icon), but in practice the Kitchen tablet doubles as both the Main Device and the cook's Order Wall.

```
 ┌─────────────────────────────────────────────────┐
 │                 Local WiFi / LAN                  │
 │                                                   │
 │   ┌──────────┐     ┌──────────┐    ┌──────────┐  │
 │   │  Waiter  │     │  Waiter  │    │ Kitchen  │   │
 │   │ Handheld │     │ Handheld │    │ Tablet   │   │
 │   │  (Host)  │     │  (Host)  │    │ (Main)   │   │
 │   └────┬─────┘     └────┬─────┘    └────┬─────┘  │
 │        │                │               │         │
 │        └────────────────┼───────────────┘         │
 │                         │                         │
 │                  ┌──────┴──────┐                  │
 │                  │  SQLite DB   │                  │
 │                  │  WebSocket   │                  │
 │                  │  Server      │                  │
 │                  └─────────────┘                   │
 └─────────────────────────────────────────────────┘
```

> **No internet required.** The venue's router provides the LAN. SatSet never phones home.

---

## 1. Vision & Purpose
In high-pressure environments like busy pubs, cafes, and sprawling resorts, manual communication leads to errors and delays. **SatSet** is built to "eliminate the noise." It ensures that the moment a waiter takes an order, the kitchen is already preparing it. No shouting, no lost paper tickets, just a seamless digital flow.

---

## 2. The User Experience (Roles)

### 2.1 The Service Team (Floor Handheld)
* **The Goal:** Speed and Accuracy.
* **Key Action:** Waiters move through a visual map of the venue (Zones/Tables). Selecting a table opens a "Smart Menu" where they can tap items and select specific preferences (e.g., "Extra Spicy" or "No Ice") with zero typing.
* **The Benefit:** They never have to walk back to the kitchen just to drop off an order. They stay on the floor, attending to guests.

### 2.2 The Preparation Team (Kitchen/Bar Tablet — also serves as Main Device)
* **The Goal:** Clear Priorities.
* **Key Action:** A digital "Order Wall" replaces paper slips. New orders pop up instantly with a distinct sound. Chefs can see exactly how long a table has been waiting and tap a button to signal when the food is "Ready."
* **The Benefit:** No more messy handwriting or lost tickets. The kitchen stays organized even during peak "SatSet" hours.
* **Dual Role:** In the typical deployment, this tablet also acts as the **Main Device** — hosting the SQLite database and WebSocket server. All waiter handhelds connect directly to this tablet.

### 2.3 The Management (Admin Dashboard)
* **The Goal:** Control and Insights.
* **Key Action:** Managers can "Kill" an item (mark as Sold Out) instantly across all devices. They can also see a live "Heatmap" of which tables are waiting the longest.
* **The Benefit:** Immediate control over inventory and staff performance without leaving the office.

---

## 3. Core Functional Features

### ⚡ Real-Time Synchronization (Local WebSocket)
* **Instant Push (LAN):** When an order is "Sent" from a handheld, it travels over the local WiFi to the Main Device, which immediately broadcasts to the kitchen tablet — all in under 0.5 seconds. No cloud round-trip, ever.
* **Live Status Updates:** Waiters see the live progress of their orders (e.g., *Order Received* ➔ *Cooking* ➔ *Ready to Serve*) pushed from the Main Device via WebSocket.
* **Connection Model:** Host → Main Device (WebSocket). The Main Device broadcasts to all relevant Hosts. If the Main Device fails, a secondary device can take over.

### 🗺️ Visual Venue Mapping
* **Custom Layouts:** The app reflects the actual physical layout of the resort, pub, or cafe (e.g., "Poolside," "VIP Room," or "Main Hall").
* **Table Status:** Colors indicate if a table is Empty, Ordering, Waiting for Food, or needs the Bill.

### 🛠️ Smart Menu & Modifiers
* **Mandatory Choices:** The app prevents "incomplete" orders. For example, if a steak is selected, the app forces a choice of "Doneness" before the order can be sent.
* **Quick Search:** A fast-access bar for the most popular items.

### 🔔 Smart Notifications
* **Haptic Feedback:** Handhelds vibrate when an order is ready for pickup.
* **Audio Cues:** Distinct, non-annoying sounds for different events (New Order vs. Order Cancelled).

---

## 4. Design Guidelines

> **Design system reference:** All color tokens, typography, spacing, and component specs are defined in [`DESIGN.md`](./stitch_export/DESIGN.md) (Heritage Hospitality — "Quiet Luxury"). The guidelines below are the product-level interpretation for the operational context.

### Visual Style
* **"Speed-First" UI:** High-contrast colors and large touch targets (48px minimum). Staff often have wet or busy hands; they shouldn't have to squint or aim precisely.
* **Heritage Foundation:** The base palette is warm and tactile — Soft Cream backgrounds (`#FBF9F4`), Rich Brown primary (`#4A3728`), and Taupe borders (`#A39382`). This provides a premium, calming backdrop even in high-stress environments.
* **Dark Mode Variant:** For dimly lit pub/restaurant environments, the inverse surface tokens from DESIGN.md apply — dark backgrounds (`#30312E`) with cream text (`#F2F1EC`).

### Status Color Coding
Mapped to the Heritage Hospitality palette:

| State                     | Token              | Hex       | Meaning                                |
| ------------------------- | ------------------ | --------- | -------------------------------------- |
| Idle / Empty              | `outlineVariant`   | `#D2C4BB` | Table available, no current activity   |
| Order in Progress         | `tertiaryContainer`| `#46392B` | Dark Walnut — order being prepared     |
| Ready for Pickup          | `secondaryFixed`   | `#F2DFCC` | Warm cream — food/drinks at pass       |
| Warning (waiting too long)| `error`            | `#BA1A1A` | Deep red — attention required          |

### Interaction Patterns
* **Zero-Typing Policy:** 95% of the app should be operable through taps and swipes only.
* **Bottom-Heavy Navigation:** All critical buttons should be within reach of a thumb for one-handed operation on mobile devices.
* **100ms Transitions:** All hover/selection animations use a 100ms ease-out curve — fast enough for operational speed, smooth enough for polish.
* **Icons:** 1pt stroke, 20–24px, in Primary Rich Brown (`#4A3728`). See DESIGN.md §7.7.

---

## 5. Success Indicators
* **Reduced "Dead Time":** Less time spent by waiters walking back and forth to the kitchen.
* **Order Accuracy:** A 100% reduction in "forgotten" modifiers (e.g., no more sending out a coffee that was supposed to be sugar-free).
* **Staff Happiness:** Less stress during peak hours due to clear, quiet, and organized communication.
