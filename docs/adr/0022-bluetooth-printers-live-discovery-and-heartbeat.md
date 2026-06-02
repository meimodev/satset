# Bluetooth printers, auto-discovery on open, and a reachability heartbeat

**Status:** accepted — supersedes [0020](0020-two-scope-printers-shared-renderer.md)

## Context

ADR-0020 shipped the two-scope printer model (venue vs device) with one shared ESC/POS renderer, and **deliberately deferred Bluetooth**: the live transport for both scopes stayed network ESC/POS, with the `kind` field "reserved for BT; nothing ships it yet." It also gave the print picker a manual **"Cari printer"** button (one-shot 4s mDNS) and a manual add dialog, and surfaced an "online" dot whose only data source was a successful **test print** (`lastSeenAt`).

Three problems pushed past that design:

1. **Waiters carry Bluetooth pocket printers.** The deferral was explicit, but the field need is real — a cheap thermal BT printer in an apron is the common case, not the LAN raw-9100 unit.
2. **The online dot lied.** `lastSeenAt` only ever moved on a manual test, so a printer that hadn't been tested in 10 minutes showed offline even while healthy, and device printers showed nothing at all. "Online" was never actually probed.
3. **The picker behaved like a config screen, not a print dialog.** Open it, hunt for the "Cari" button, wait 4 frozen seconds, pick, save, then print. The desired feel is an AirPrint-style sheet: open → see what's reachable now → tap → print.

## Decision

**Bluetooth ships now (device-scope only); the picker auto-discovers on open and lists only printers a heartbeat proves reachable.**

- **Scope × transport, not just scope.** A printer has a **transport** (`wifi` | `bluetooth`) as well as a scope. Only three combinations are valid: `venue+wifi`, `device+wifi`, `device+bluetooth`. **`venue+bluetooth` is impossible** — the [[Main Device]] (server) cannot open an RFCOMM socket to a printer bonded to a waiter's phone — and is rejected in the add flow. Venue printers stay wifi-only; **only `DevicePrinter` gains `transport` + `mac`**, so the server `printers` Drift table and `PrinterDto` are untouched (no migration; the old `kind` field is now vestigial — venue can never be BT).
- **Bluetooth is Classic SPP, paired-first.** Thermal printers speak Bluetooth **Classic (RFCOMM/SPP)**, not BLE, so we use `print_bluetooth_thermal` and send the **same renderer's bytes** over a new BT transport beside `StrukSocket`. The app **enumerates bonded devices only** — pairing happens once in Android settings; there is no in-app air-scan for unpaired printers. `BLUETOOTH_CONNECT` is requested **lazily** (via `permission_handler`) on first sheet-open when a BT adapter is present and on; denial or adapter-off degrades the BT section to an affordance and never blocks the wifi list.
- **Auto-discovery on open; the "Cari printer" button is removed.** Opening the picker immediately starts mDNS discovery (refactored to **stream** results so rows pop in instead of freezing for 4s) and enumerates paired BT printers. "Tambah manual" stays (static-IP / non-advertising units). The sheet is a **live merged view** deduped by address (`host:port` for wifi, `mac` for BT): registered venue + registered device + freshly discovered wifi + paired BT. A registered identity wins the dedup (keeps its label/scope). Tapping an **unregistered** discovered printer prints immediately and **lazily persists it as device scope** (private — no admin gate, no shared-config write).
- **Online means a heartbeat answered.** The picker lists only **online** printers as tappable; offline ones drop to a greyed "Offline" section; a **disabled** venue printer is hidden entirely. Reachability is split by who can reach the printer:
  - **Venue wifi** → the Main Device runs a **periodic TCP probe** (connect + close, no bytes, short timeout, in parallel) on a **~15s tick**, writes `lastSeenAt` on success, and broadcasts `printerUpdated` so clients refresh dots without re-fetching.
  - **Device wifi/BT** → the owning phone probes its own printers (TCP connect for wifi, the plugin's connection check for BT), held in local provider state; while the sheet is open it re-probes every ~10s.
  - Client online window = **30s** (≤2 missed 15s ticks), coupled to the tick so a healthy printer never flips offline between probes.

## Considered options

- **Full Bluetooth now + live heartbeat picker (chosen)** — matches the real field device and makes "online" honest. Cost: a BT plugin + Android runtime permission + the paired-first UX caveat; a constant 15s server probe; two reachability probers (server for venue, phone for device).
- **Wireless-only, BT-ready model, defer BT again** (rejected) — cheapest and keeps ADR-0020 intact, but leaves waiters' actual printers unsupported; the deferral had already outlived its usefulness.
- **BLE instead of Classic SPP** (rejected) — `flutter_blue_plus` is BLE-only; most thermal printers don't expose a BLE ESC/POS service, so it would talk to almost none of the target hardware.
- **In-app air-scan for unpaired BT printers** (rejected) — flaky, needs the pairing intent + (pre-31) location permission; pairing once in Android settings is more reliable and keeps us out of location-permission territory.
- **Keep the one-shot 4s discovery batch** (rejected) — simpler, but the auto-on-open sheet would sit frozen for 4s; streaming results is the whole point of an instant print dialog.
- **Constant background heartbeat regardless of sheet** (partially taken) — venue wifi does tick in the background (so cross-device dots stay warm over WS); device probing is gated to while-the-sheet-is-open to spare battery.

## Consequences

- **ADR-0020's BT deferral is reversed.** Its "Bluetooth is deliberately deferred / `kind` reserved" consequence no longer holds; the rest of 0020 (two scopes, one shared renderer, venue-delete authz, real test print) stands.
- **Device printers don't survive a reinstall** — unchanged from 0020, and now also true of paired-BT entries (the bond lives in Android, the label/identity in local prefs).
- **The Main Device does steady work** — N short-lived sockets every 15s. Acceptable: it's the always-on host (usually plugged). A dead printer can't stall the tick (parallel probes, per-printer timeout).
- **"Online" is now trustworthy** — the dot reflects an actual recent probe, not the last manual test; reports/audit are unaffected (heartbeat writes only `lastSeenAt`).
- **One new Android permission** (`BLUETOOTH_CONNECT`, plus capped legacy `BLUETOOTH`/`BLUETOOTH_ADMIN` for API ≤30) and one new dependency (`print_bluetooth_thermal`, `permission_handler`).
