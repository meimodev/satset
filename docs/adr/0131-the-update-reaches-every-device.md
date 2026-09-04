# ADR-0131 — The update reaches every device, and the host mirrors it

Status: accepted
Date: 2026-09-04

Amends [ADR-0130](0130-the-update-gate.md) — reverses its install rule and adds
a fourth verdict. The gate itself is untouched: `min` / `recommended` /
`latest`, who reads the cloud, how the block renders, and the fail-open rule all
stand exactly as written.

## Context

ADR-0130 shipped complete. Eight releases have gone out since, every one of them
plain-tagged, and **not one device in the fleet has ever drawn the banner or the
block**. The install path in `app_update_service.dart` has never run outside the
widget book. The mechanism is finished and dormant, and the venue still updates
the way it did before: somebody opens the website and downloads an APK.

Two independent reasons, and neither is a bug.

**`latest` is invisible.** The gate holds three numbers and `verdictFor` reads
two. A plain tag moves only `latest` — deliberately, so that a routine patch
does not nag a fleet — but nothing anywhere renders it either. So a build that
is newer than yours, downloadable right now, on a device that could install it,
produces exactly the same silence as no release at all. `/push-deploy`'s own
severity table papers over this with the line *"Old clients see nothing in-app
(Play auto-update only)"*. SatSet is not on Play. There is no auto-update to
fall through to. That sentence describes a mechanism that does not exist, which
is why nobody noticed the gap it was covering.

**Only the Main Device could act.** So the one surface that could ever show
anything was a single banner on a single tablet, reachable only behind a tag
suffix somebody had to remember at 2am. ADR-0130 rejected staff-installable
updates on the grounds that it *"puts 'install unknown apps' on every handset in
the venue, to serve a case that is rare by construction."*

Two things are wrong with that sentence now.

The case is not rare — it is **every** case. Hand distribution means a person
walks to each device; 0130 made that walk the fleet's entire update flow rather
than a fallback for the awkward device. And a device below `min` is **out of
service**. Refusing to let it unblock itself protects nobody: it converts a
two-minute install into a stranded handset waiting for someone with an admin
session to arrive.

## Decision

Four changes that are really one change: **the update becomes something a person
can go and get.**

### 1. A fourth verdict — `available`

`installed < latest`, no floor crossed. Ordering is `blocked` > `recommended` >
`available` > `none`, and everything unknown still resolves to `none`.

It is a **pull, never a push**. Nothing new appears uninvited anywhere.
`recommended` keeps its exact meaning — the severity that earns screen space
without being asked — and `min` keeps the block. What `available` buys is that
the ordinary release stops being unreachable from inside the app.

### 2. Every device installs

**Reverses 0130's "Only the Main Device ever installs."** The capability split is
by situation, not by device:

- **While blocked, install is ungated.** Any device, any session, no capability.
  Unblocking a device that is already out of service is never the wrong act, and
  a gate there is pure harm.
- **Otherwise `editSettings`.** A discretionary 60 MB download and a process
  restart on a live handset mid-shift is a manager's decision. This is also what
  keeps the runtime `REQUEST_INSTALL_PACKAGES` grant off waiters' phones in the
  ordinary case — which, read charitably, is the thing 0130 was actually
  protecting.

### 3. The host mirrors the APK; the client falls back

`GET /update/apk?v=<semver>` on the existing TLS server.

**Unauthenticated, like `/healthz`.** Same timing reason — a blocked device may
be sitting at sign-in — plus one 0130 did not have: the route serves a
byte-identical copy of a file already published at a public GitHub URL. There is
no secret in it, and a bearer buys nothing but refusing a stranger a download
they could fetch from github.com anyway. It is in the middleware's skip set, not
a route that cannot identify its caller — [ADR-0102](0102-a-route-that-cannot-identify-its-caller-refuses-it.md)
is untouched. **It is not mounted on the guest plane**
([ADR-0105](0105-guest-self-order-returns-as-an-intent-not-a-ticket.md)); that
socket takes no staff routes and this is not the exception.

**The host prefetches eagerly**, whenever the gate's `latest` exceeds its own
version, into the **application support dir** — not the cache dir the existing
install path uses. The two files have opposite lifetimes and the distinction is
load-bearing: the client's own download is throwaway the instant the installer
has it, while the mirror exists to still be there weeks later, during the outage
that is the whole reason to mirror. Android evicts cache dirs under storage
pressure without asking, and it would evict this one on the tablet whose venue
is already in trouble. The previous release's file is deleted on each new pull,
so it is one APK and not a growing pile; the download lands on `.part` and is
renamed on completion, so a half-file is never served.

**`?v=` is the handshake.** The host 404s on a version it does not hold and the
client falls back. The version rides the request rather than being advertised in
`/healthz` because a payload is stale by construction, and 0130 already notes
that `/healthz` is no longer free to change shape.

**The client falls back to GitHub** on any host failure. Clients sit on the same
AP as a host that needs internet for Firebase, so WAN is usually present; the
mirror is what lets a venue with a dead uplink still unblock six handsets from a
tablet that already holds the file.

**No hash and no signature check of our own**, holding 0130's line. Android
refuses to install an APK signed by a different key over an installed package —
that is the actual protection, we cannot do it better than the platform, and a
hash in the gate doc would add a CI step, a field, and a fresh way for a correct
download to be rejected because somebody typed in the console.

### 4. The `/me` version line becomes the pull surface

`_VersionLine` already prints this build on every device. It gains the second
number and, under `editSettings`, becomes the control:
*Versi 1.0.8 · 1.0.9 tersedia · Perbarui*.

Without the capability it renders as **state, not a refused tap** — text, no
gesture target, one `Semantics` label. That is the shape
[ADR-0087](0087-permissions-are-edited-one-role-at-a-time.md) settled for locked
capability rows, and the reason is the same: a control that exists only to
refuse you is worse than a fact.

`/me` rather than `/system` because this is how a waiter's handset actually gets
updated — a manager takes the phone and signs in — and because the version line
already raises the question ("is this current?") on every device while answering
it on none.

**The `recommended` banner stays host-only.** It is the one surface that
interrupts, and neither the phone bar budget
([ADR-0062](0062-the-phone-bar-is-budgeted-for-a-360dp-handset.md)) nor "stay
quiet under chaos" has changed. **The block screen gains an install button on
every device** — it is already full-screen and already interrupting, so the
button costs no quiet, and self-rescue matters most exactly there.

### 5. A host install takes the venue down, and says so

Installing replaces the process: the embedded server stops and every client
loses its host mid-service. Nothing warns today.

Mirror [ADR-0015](0015-firebase-admin-auth-and-server-kill-switch.md)'s logout —
**warn, naming the live table count, then proceed.** Refusing while tables are
live is worse than it sounds: a `min` floor exists for builds that must stop
running, and a venue that never closes a table could never comply. A client
install takes down only itself and warns about nothing.

## Consequences

- **`/update/apk` is the second unauthenticated route on the staff plane**,
  after `/healthz`. The skip set is now a list, not an exception.
- **The host holds ~60 MB of durable state that is not the venue's data** — the
  first thing in the app support dir that is not a database or a key.
  `allowBackup=false` and `@xml/data_extraction_rules` already cover it.
- **A client fetches bytes from the host that are not venue data.**
  [ADR-0017](0017-main-device-host-and-admin-clients.md)'s shape holds — clients
  read the LAN, never the cloud — and the GitHub fallback is the one deliberate
  exception.
- **`REQUEST_INSTALL_PACKAGES` becomes reachable on staff handsets.** The
  manifest already declares it fleet-wide; what changes is that the runtime
  grant is now asked outside the Main Device.
- **`/push-deploy`'s severity table is rewritten.** It cited ADR-0015 (means
  0130) and claimed plain tags fall through to Play. A plain tag now means
  "offered on the version line, nagged nowhere" — which is a real answer, so the
  skill stops needing a fiction.
- **`codemagic.yaml` cited ADR-0015** for the gate write; corrected to 0130.
- **New ARB entries in both locales** for the version line's available state and
  for the block screen's install action on a non-host device. The block's
  existing "fetch an admin" copy survives only as the fallback when a device
  genuinely cannot install.
- **`UpdateBanner`'s doc comment and its `CATALOG.md` row keep saying "Main
  Device only"** — still true of the banner, and now true *only* of the banner.

## Alternatives rejected

**Tag `-recommended` more often.** Zero code. Rejected: it stakes the entire
update mechanism on remembering a suffix, and eight releases is the evidence
about how that goes.

**Widen the banner to `latest`.** Every patch nags every host. Rejected:
`recommended` stops meaning anything, and the banner is the one thing 0130
rationed correctly.

**Client pulls GitHub directly, no mirror.** No server work at all. Rejected: it
fails precisely when the venue's uplink is down — the scenario this app exists
for — and pulls the same 60 MB once per handset through one connection.

**Host as the only source, no GitHub fallback.** Cleaner, and it matches the
gate's own "host reads the world, the LAN carries it". Rejected: a host that has
not prefetched yet would strand a device with perfectly good internet, for
symmetry's sake.

**Host mirrors only what it downloaded for its own install.** Free — the file is
already on disk. Rejected: it ties every client's ability to update to whether
anybody updated the host first, reintroducing the dependency this ADR exists to
remove.

**No capability gate at all**, the literal reading of "every device installs".
Rejected: a discretionary mid-shift download and restart on a live handset is
not a waiter's call, and the ungated-while-blocked carve-out already covers the
case where waiting for a manager causes harm.

**Refuse a host install while tables are live.** Rejected in §5 — a floor exists
for builds that must stop running.

**Advertise the mirrored version in `/healthz` instead of the `?v=` query.**
Fewer round trips on a miss. Rejected: the payload is stale by construction and
`/healthz` is no longer free to change shape.
