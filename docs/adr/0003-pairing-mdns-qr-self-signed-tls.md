# ADR-0003 — LAN pairing: mDNS discovery, QR token claim, self-signed TLS with client-side fingerprint pinning

**Status:** Accepted — 2026-05-28

## Context

Client devices must reach the server tablet over the venue's local Wi-Fi without any of the usual infrastructure that makes that easy:

- No DNS — the server has no fixed hostname, just whatever DHCP gives it.
- No public CA — issuing a real cert to `192.168.x.y` is impossible; LetsEncrypt needs a public domain.
- No internet during the pair flow — venues set up the network themselves and the cert exchange must complete on the LAN.
- Staff cannot type IPs, ports, certificate hashes, or anything else. The pair flow has to be one or two physical actions.

We also wanted the protocol — once paired — to be plain HTTPS + WSS so future hardening (e.g. real CA, mTLS) does not require rewriting clients.

## Decision

**1. mDNS for discovery (`_satset._tcp`).**

`SatSetAdvertiser` (bonsoir, `lib/server/mdns.dart`) broadcasts the service on server boot. TXT attributes carry the load-bearing data:

- `fp` — SHA-256 fingerprint of the TLS leaf cert, lowercase hex. **Clients pin this.**
- `label` — human-readable server name, shown on the pair sheet.
- `ver` — app version (informational).

Clients use `MdnsBrowserService` (`lib/data/services/mdns_browser_service.dart`) which subscribes to `_satset._tcp`, resolves entries, hides the device's own broadcast, and deduplicates stale entries per `host:port` after server restarts. The browser is reference-counted so multiple UI subscribers share one underlying discovery.

**2. TLS uses a self-signed cert, generated on first server boot and pinned by clients.**

`ServerTls.loadOrCreate` (`lib/server/tls.dart`) generates a 2048-bit RSA keypair and a 5-year self-signed leaf (`CN=satset.local`) on first run, persists both PEMs under app-support, and computes the SHA-256 fingerprint of the DER body. The server advertises that fingerprint over mDNS TXT; clients refuse any cert whose hash does not match (`ApiClient.buildPinnedHttpClient`, also shared by `WsClient` so REST and WS pinning cannot diverge).

The only escape hatch is loopback — when `ApiConfig.trustedFingerprint` is empty and the host is `127.0.0.1` / `localhost` / `::1`, pinning is skipped (used by server-mode UI talking to its own runtime). Any non-loopback config with an empty fingerprint `throw`s `StateError` at client construction.

**3. Pairing is a single-use token claimed over the pinned channel.**

`PairingService` (`lib/server/pairing.dart`) issues UUIDv4 tokens with a 5-minute TTL. Claim is atomic in a Drift transaction: marks the token used, inserts the device row, returns the device. Same token cannot be reused.

Two claim endpoints, both unauthenticated (they are the bootstrap):

- `POST /pair/claim` — explicit token entry. The server-side admin presses "Show pair token", a QR appears, the client scans it, posts `{token, deviceId, deviceLabel, publicKey}`.
- `POST /pair/auto-claim` — LAN-trusted shortcut. The client picked an mDNS entry whose fingerprint pin already verified end-to-end at the TLS layer; the server issues+consumes a one-shot token internally and returns the same payload. No physical QR scan required.

Both return `{deviceToken, fingerprint, serverPublicKey}` which the client persists (`SecureStorageService` for `deviceToken`, `PrefsService` for `apiConfigProvider`). The `serverPublicKey` field is reserved for a future signed-payload feature; currently empty.

**4. mDNS-discovered fingerprint is the trust anchor.**

The reasoning: an attacker on the same Wi-Fi can spoof mDNS, but cannot present a cert whose SHA-256 matches the spoofed `fp` unless they have the server's private key. So the client trusts whichever cert hashes to the `fp` it found, and once paired persists that fingerprint into `ApiConfig` for all subsequent connections.

`PIN auth` still gates anything useful after pairing — pairing alone proves "this device is on the venue Wi-Fi", not "this human is allowed to take orders". See ADR-0004.

## Consequences

**Positive:**
- Zero infrastructure: no DNS, no CA, no IT setup. Plug in router → install APK → scan QR. ~30s to onboard a new device.
- Discovery survives DHCP lease renewal: mDNS re-resolves; the client never has a hardcoded IP.
- `/pair/auto-claim` makes "I just installed the app, find the server" a one-tap flow, removing the QR step when LAN pinning is already established.
- TLS pinning sets the security floor higher than HTTP-on-LAN: an attacker would need either the venue Wi-Fi password *and* the server's private key, or to coerce staff into accepting a new pair from a hostile device.
- Reusing the cert across restarts (`loadOrCreate`) means clients don't have to re-pair after the server tablet reboots.

**Negative:**
- Self-signed pinning means **rotating the cert breaks every paired client** until they re-pair. Cert rotation is out of scope for `ServerRuntime.restart`. Mitigation: 5-year cert lifetime; a future flow will handle scheduled rotation with an overlap window. Today, lost private key = re-pair every device.
- mDNS is fragile on guest-isolated Wi-Fi networks and on Android when the device sleeps. Mitigation: explicit `/pair/claim` QR flow as fallback; advertiser/browser are restarted on resume.
- `bonsoir`'s Android resolver returns hostnames like `device.local` that don't always resolve back to IPs. Mitigation: `MdnsBrowserService._isLocalHost` filters the device's own broadcast; remaining edge cases surface to the user as "server not found, try again".
- Pair tokens are sent through QR (rendered on the server, scanned by the client). Anyone with line of sight to the server screen during the 5-minute window can pair. Mitigated by short TTL and the requirement that PIN auth still applies afterward — but worth noting.
- `serverPublicKey` is wired through the pair response and stored, but not yet used for anything. Carries forward as deferred work.

## Alternatives considered

- **Hardcoded IP / manual config.** Rejected: incompatible with DHCP and with the "staff cannot type" constraint.
- **Real CA (LetsEncrypt) on a public domain pointing at a dynamic DNS endpoint.** Rejected: violates "must work without internet during pair", adds annual renewal management, and requires the venue to own a domain.
- **HTTP over LAN with no TLS.** Rejected: token theft over an open café Wi-Fi is trivial and the cost of adding pinned TLS is one PEM file.
- **Mutual TLS (client certs issued at pair time).** Considered for the future. `serverPublicKey` and the pair response's `publicKey` field exist as carriers for that. Not built yet — single-direction pinning + bearer JWT is enough for the current threat model and one less thing for the staff to misplace.
- **Bluetooth pairing.** Rejected: range and discoverability on Android make it worse than mDNS-on-Wi-Fi, and Wi-Fi is the data plane anyway.
