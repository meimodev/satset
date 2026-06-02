# Struk printing: two printer scopes (venue vs device), one shared renderer

**Status:** superseded by [0022](0022-bluetooth-printers-live-discovery-and-heartbeat.md) — Bluetooth is no longer deferred; see 0022 for the scope×transport model, auto-discovery, and reachability heartbeat. The two-scope split + shared renderer below still hold.

## Context

A waiter taps "Cetak struk meja" to hand the guest a printed order-confirmation slip (item, qty, modifiers, notes — no money; see the [[Struk (cetak struk meja)]] glossary term). The receipt printers it can target are **network ESC/POS** units on the venue LAN. Two facts pull in opposite directions: the [[Main Device]] owns the authoritative DB and is the only device guaranteed reachable from the venue's shared printer, but a waiter may also keep a printer of their own that only their phone reaches. A naive "all printers are server-owned, server always sends" model can't express the second case; an "every device owns its own printers" model loses the shared venue printer and duplicates config across phones.

## Decision

**A printer has one of two scopes, and the scope decides who transmits — but a single shared renderer produces the struk bytes for both.**

- **Venue printer** — stored once in the Main Device's Drift DB (`printers` table), shared by every device. The client only *triggers* a print: `POST /tables/:id/print {printerId}`; the **server** loads the table's lines + [[Venue (cloud)|venue]] header/footer, renders, and opens the socket to the printer's host:port. Any authenticated staff may add / discover (mDNS) / test a venue printer; **only an admin (`editSettings`) may delete** one, because it is shared config.
- **Device printer** — private to one device, persisted locally on it (no server row, no shared-config authz). That device builds the struk, renders, and sends over its **own** socket to the printer's host:port.
- The print picker **merges both scopes**, tagging each ("Venue" / "Alat ini"); it is always shown, even for a single printer. Adding/discovering a printer is reachable **inline from the picker** (clients have no admin screens) as well as from the admin System screen.
- **One shared, pure renderer** (`esc_pos_utils_plus`, a pure-Dart lib usable in both the in-process server and the Flutter client) turns a struk's data into ESC/POS bytes. Only the **transport** differs (server socket vs device socket), never the byte content — so a struk looks the same whoever prints it. The same renderer is reused by the table-detail action, the Tutup meja flow, and the order-sent screen.

## Considered options

- **Two scopes + shared renderer (chosen)** — expresses both the shared venue printer and a waiter's personal printer without duplicating render logic. Cost: two send paths to maintain, and device printers don't survive a reinstall (acceptable — they're personal convenience).
- **All printers server-owned, server always sends** (rejected) — simplest authz and one send path, but cannot represent a printer only one phone reaches, and routes every print through the Main Device.
- **All printers device-local** (rejected) — no shared venue printer; every device re-adds the front-desk printer and they drift out of sync.
- **`esc_pos_utils_plus` vs a hand-rolled byte encoder** — chose the library despite pulling the `image` package transitively, to get column layout now and logo/QR/barcode for free later; the struk is text-only today but is expected to grow a venue logo.

## Consequences

- **Bluetooth is deliberately deferred.** Device-direct sending makes a BT pocket printer technically feasible now, but it needs a BT plugin + Android runtime permissions + a pairing UI, so the live transport for both scopes stays **network ESC/POS**. The `kind` field is reserved for BT; nothing ships it yet.
- The previous `/printers/:id/test` stub (which only bumped `lastSeenAt`) becomes a **real** test print over the socket; "connected" now means a test actually succeeded.
- Printing a table with **no sent, non-voided lines** is aborted with a message — there is nothing to confirm.
- Device printers carry no server audit; venue prints can be stamped server-side.
