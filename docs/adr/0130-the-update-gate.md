# ADR-0130 — The update gate: a nudge on the host, a floor for everyone

Status: accepted — the install half is amended by
[ADR-0131](0131-the-update-reaches-every-device.md), which reverses "only the
Main Device installs" and adds the LAN mirror. The gate itself (`min` /
`recommended` / `latest`, who reads the cloud, how the block renders) is
unchanged. Numbered 0087 until the collision with
[0087-permissions-are-edited-one-role-at-a-time.md](0087-permissions-are-edited-one-role-at-a-time.md)
was resolved.
Date: 2026-08-08

Amends [ADR-0015](0015-firebase-admin-auth-and-server-kill-switch.md) (a second
thing the cloud can stop a device doing) and
[ADR-0016](0016-fleet-superadmin-cloud-control-plane.md) (a fleet-wide document
that is not a venue).

## Context

SatSet is not on Play. `codemagic.yaml` builds a signed APK on every `v*` tag,
publishes it to a public GitHub Release, and the website links the stable
`releases/latest/download/satset.apk` URL. There is no auto-update of any kind:
a venue runs whatever build was on the tablet the day someone installed it, for
as long as nobody visits.

The tag grammar for saying an update matters has existed since `/push-deploy`
was written — `v1.2.0`, `v1.2.0-recommended`, `v1.2.0-breaking` — and CI already
parses the suffix off `CM_TAG`. It then throws it away. Nothing downstream has
ever read it, and no build of the app has ever known its own version number:
`package_info_plus` is not a dependency, and `ServerRuntime.defaultVersion` is
the literal string `'1.0.0'`, advertised as `ver` in the mDNS TXT record and
shown on the pairing screen, where it has been wrong since 1.0.1.

So there are two gaps, and they are different gaps. A venue on an old build
cannot be *told*, and a venue on a build that must not run cannot be *stopped*.

## Decision

**One global Firestore doc, `config/release_gate`, holding `min`,
`recommended` and `latest`.** CI writes it; the fleet console can override it.

### 1. `min` is a policy floor, not a compatibility floor

`min` says "nobody may run below this". It does **not** say "an old client
cannot talk to a new host". The LAN protocol is unaffected, the host never
rejects a client for its version, and nothing about the gate is enforced at the
wire.

That choice is what makes the gate cheap and honest. A compatibility floor would
have to live on the host, be derivable offline, and be correct about every route
and DTO shape in both directions. A policy floor is one comparison against one
number that a human decided.

### 2. CI writes it, last, from the tag

The severity suffix cascades so `min ≤ recommended ≤ latest` is an invariant of
the write rather than a thing to check on read:

| Tag | `latest` | `recommended` | `min` |
|---|---|---|---|
| `v1.2.0` | 1.2.0 | — | — |
| `v1.2.0-recommended` | 1.2.0 | 1.2.0 | — |
| `v1.2.0-breaking` | 1.2.0 | 1.2.0 | 1.2.0 |

**The write is the last step of the workflow, after `gh release create`
succeeds.** A floor that rises while the APK is still uploading points every
device in the fleet at a download that does not exist yet, which is the one
failure mode with no recovery inside the app.

**The fleet console can edit the same doc.** This is not symmetry for its own
sake — it is the only correction that reaches a venue nobody can drive to. A
wrong `-breaking` is otherwise fixed only by cutting a higher tag, waiting for
CI, and then physically visiting every device, which is a week of outage for a
typo.

### 3. Only the host reads the cloud; the LAN carries the rest

Clients never touch Firebase (ADR-0015, ADR-0017). The host holds a
`config/release_gate` listener beside the eligibility listener it already runs,
caches what it sees, folds it into the **unauthenticated `/healthz` payload**,
and broadcasts a `releaseGate` WS event on change.

`/healthz` is the carrier because the block must bite *before* PIN login, and
`/healthz` is already in the auth middleware's skip set and already probed by
the client. A client persists the last gate it saw to `SharedPreferences`, so a
gated device stays gated with the host down. An unpaired client has no gate at
all and is never blocked — it has no host to have heard from.

**Everything unknown fails open.** No doc, no network, an unparseable version:
the device is not blocked. A gate that blocks on its own ignorance would take a
venue offline over a Firestore outage.

### 4. The block is immediate, and it is not a route

Below `min`, a non-dismissible surface covers the app **the moment the floor
lands**, wherever the user is.

This is deliberately harsher than the ADR-0015 offline-grace lock, which "only
bites on restart". That guard protects against a network the venue can fix by
walking to the router; this one protects against a build the venue must stop
running now. The cost is stated plainly: a mis-tagged `-breaking` darkens every
venue mid-service, and the console override is the mitigation, not a cure.

It renders as a `Stack` layer in the `MaterialApp.router` builder, beside
`AlertHost`, **not** as a pushed overlay and **not** as a rung in the redirect
ladder. A pushed overlay would need push/pop bookkeeping against a state that
can lift, and a ladder rung would put a fifth conditional into the thing
ADR-0078 exists to keep loop-safe. A declarative layer above the router is
above the floating tab bar for the same structural reason ADR-0061 gives, needs
no lifecycle, and cannot be popped by the back button.

**The block never stops the embedded server.** A host that tore down its server
while blocked would tell every client "host offline" instead of "fetch an
admin", which is the wrong instruction at the worst moment.

### 5. The nag is host-only; so is the install

Between `recommended` and `latest`, the **Main Device alone** carries a
persistent shell banner, third under `AdminGraceBanner` and `VenueBillingBanner`
in `app_shell.dart`. No sheet, no snooze state, no release notes — just "Versi
1.1.0 tersedia · Anda di 1.0.3". CI release notes are `--generate-notes`: raw
English commit subjects, on a screen where every other word is localised.

**Only the Main Device installs.** It downloads the APK over the existing `http`
dependency and hands it to Android's package installer via `open_filex`. Staff
clients and admin-clients alike are told to fetch an admin.

This is the shape of the business, not a permission model: SatSet is distributed
by hand, so updating a device means a person holding that device. A nag on a
waiter's phone is unactionable noise on the one screen the design principles
require to stay quiet under chaos.

**The app learns its own version from `package_info_plus`** — the installed
`versionName`, not a constant that drifts from `pubspec.yaml`. The same value
replaces the hardcoded `ServerRuntime.defaultVersion`, so the `ver` in the mDNS
TXT record stops lying as a side effect.

Comparison is on `versionName` alone. The build number is invisible to the gate,
because CI is free to move it and the tag never carries it.

## Consequences

- **A new fleet-wide document class.** `config/release_gate` is the first
  Firestore doc that belongs to no venue and no admin. `firestore.rules` gains a
  signed-in-read / no-client-write rule, and the CI service account needs
  Firestore write on top of Firebase App Distribution Admin — which the
  `firebase-adminsdk` account already has, so in practice nothing was granted.
- **`/healthz` stops being a bare liveness probe.** It carries state now.
  `ping_repository` is unaffected — it ignores the body — but the endpoint is no
  longer free to change shape.
- **`/push-deploy`'s severity choice acquires teeth.** Its existing guardrail
  ("never tag `-breaking` without an explicit user signal") stops being advice.
- **An admin-client is treated as staff by the gate.** It can be blocked and
  cannot act, which is an asymmetry with the rest of ADR-0017 and is accepted:
  the alternative is a second definition of who may install.
- **`min` will strand devices for days, by design.** A blocked waiter phone is
  out of service until someone with an admin session physically holds it. That
  is the true cost of hand distribution, made visible rather than avoided.
- The pairing screen's `v…` line becomes true for the first time.

## Alternatives rejected

**Poll the GitHub Releases API instead of Firestore.** No backend, no IAM
change, and the tag is already the source of truth. Rejected: it needs internet
on the reading device (clients have none), it is rate-limited per IP, and it
offers no override — the one lever that makes an immediate block survivable.

**Block at the next cold launch, like ADR-0015's lock.** Strictly safer, and it
has precedent in this codebase. Rejected on the grounds that a floor exists
precisely for builds that must stop running, and a kitchen tablet that is never
restarted would never stop.

**Enforce `min` on the host, at pair/auth.** Cannot be bypassed by a stale
client cache, and works fully offline. Rejected: it makes the floor a property
of the LAN protocol, which is the compatibility floor this ADR declines to
build, and it fails a client into "cannot connect" rather than into a screen
that says what to do.

**Let staff install after all, so a stranded phone can unstick itself.**
Genuinely kinder to the blocked waiter. Rejected: it puts "install unknown
apps" on every handset in the venue, to serve a case that is rare by
construction.

**A per-venue floor, for staged rollout.** Attractive for a fleet updated
by hand at different times. Rejected: a floor is a statement about which builds
are acceptable, not a schedule, and nothing in CI could sensibly decide which
venues to raise.
