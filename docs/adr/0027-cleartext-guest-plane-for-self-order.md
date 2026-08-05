# Cleartext guest plane for QR self-ordering

**Status:** Superseded by [0080](0080-self-order-and-token-pairing-removed.md) — guest QR self-ordering removed. Kept for the reasoning; the feature no longer exists.

Originally: accepted — qualifies [0003](0003-pairing-mdns-qr-self-signed-tls.md) (self-signed TLS for all connections)

## Context

ADR-0003 standardised **every** server connection on self-signed TLS: staff/admin clients pair over mDNS + QR and **pin the cert fingerprint**, so the missing public-CA chain doesn't matter — the pinned device trusts the exact key.

Guest QR self-ordering (CONTEXT.md: *Self-order*) breaks that assumption. The guest uses a **plain mobile browser**, not a paired SatSet client:

- No public CA can sign a certificate for a **LAN IP** (`192.168.x.x`) or an ad-hoc `.local` name, so HTTPS to the server presents an **untrusted self-signed cert**.
- A browser renders that as a full-screen "Your connection is not private" interstitial. For a walk-in guest with no reason to trust the venue's device, this is a **hard bounce** — most abandon.
- There is no opportunity to install/pin a cert on a stranger's phone.

The data crossing this surface is **menu reads + an order submit**, all on the **same LAN** the venue already trusts its own staff devices on. It carries no credentials, no payment (ADR pending: order-only), no admin operations.

## Decision

**Expose guest self-ordering on a second, cleartext HTTP listener — a separate "guest plane" — leaving the TLS staff/admin plane untouched.**

- The Server runtime opens a **second `shelf_io.serve` listener** (distinct guest port, e.g. 8080) with **no `securityContext`**, on `anyIPv4`, started/stopped alongside the existing TLS listener in `ServerRuntime.restart()`.
- The guest listener mounts **only** the guest router: the static SPA, `GET /guest/menu`, `GET /guest/menu/photo/<id>`, `POST /guest/session`, `POST /guest/orders`, `GET /guest/orders`. **No** staff/admin/auth/pairing routes are reachable on it.
- Guests authenticate with a **table-scoped `guest`-scope JWT** (TTL 2h, minted on scan). The **staff `_authMiddleware` rejects any `guest`-scope token**, so even if a guest reaches the TLS port they cannot call staff endpoints.
- **Deployment constraint:** guests must be on the **same LAN segment** as the server (no cross-VLAN / guest-SSID isolation) for v1.

## Considered options

- **Second cleartext listener (chosen)** — the only option that gives a stranger's browser a clean load with zero cert friction, while the staff plane keeps its pinned-TLS guarantees untouched. Cost: an unencrypted surface on the LAN, contained to read-menu + submit-order and scope-isolated from staff operations.
- **Reuse the one TLS port, accept the browser warning** (rejected) — every guest meets a scary interstitial; high abandonment; no way to pin on guest phones.
- **Locally-trusted cert installed on guest devices / captive portal** (rejected) — impossible to provision on walk-in guests; needs router config the venue can't do.
- **mDNS `.local` hostname over TLS** (rejected) — still self-signed (untrusted), and Android Chrome `.local` resolution is unreliable.

## Consequences

- A new **unauthenticated-at-the-edge** surface exists. It is mitigated by: router isolation (guest routes only), `guest`-scope rejection on the staff plane, rate-limiting, visit-close 409s, and server-authoritative pricing/validation. Threat model is a malicious device **already on the venue LAN** — the same trust boundary staff devices sit behind.
- Two listeners now share one `ServerRuntime`; both must start/stop/restart together. WS, mDNS, and the TLS plane are unchanged.
- The guest plane is **plaintext** — never carry credentials, payment, or admin actions on it (see the order-only and isolation ADRs).
- Future: if cross-VLAN guest SSIDs become a requirement, this needs a relay/reverse-proxy design — explicitly out of scope here.
