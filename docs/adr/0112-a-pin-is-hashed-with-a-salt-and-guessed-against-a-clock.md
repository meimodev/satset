# A PIN is hashed with a salt, and guessed against a clock

**Status:** Accepted — 2026-08-22.

## Context

A staff PIN was stored as `sha256('satset.v1::' + pin)` — no salt, no work factor,
the same constant prefix in every install this app has ever produced. A PIN is six
digits, which is a million candidates: the full table of digests fits in a few
tens of megabytes and computes in seconds, so the digest column is not a hash of
the PIN so much as an encoding of it. Anybody holding the database file holds the
PINs.

That is the flaw the audit named. Reading the code around it turned up three more,
and they matter more than the first one because two of them are live faults rather
than a posture.

**The digest was also the lookup key.** `signInWithPin` ran
`WHERE pin_hash = ? … getSingleOrNull`. Two staff on the same PIN therefore did
not resolve to the wrong one — `getSingleOrNull` *throws* on two rows, so both of
them were locked out with a 500 and no message that pointed anywhere. The Staf
sheet's `_pinCollision` guard answers 409 to a PIN already in use, so this can
only arrive through data written before that guard existed, or through a seed. It
had been reachable the whole time.

**There were three hashers.** `ServerAuth.hashPin`, `_hashPin` in
`reference_routes.dart` and `_hashPin` in `seed.dart`, each a copy of the same
line. Every one of them had to agree forever or a PIN set on the Staf sheet would
stop opening the door it was set for. This is the failure mode `writeAudit`,
`cash.dart`, `members.dart`, `stock_counts.dart` and `self_order.dart` each exist
to prevent, and PIN hashing had simply never been given its writer.

**Nothing counted a wrong guess.** The login route is on the LAN, answers in a few
milliseconds, and would happily take a million requests. A million requests at
that rate is under a day, which makes the offline attack above almost beside the
point — the online one needs no database file at all.

## Decision

**A PIN is hashed by PBKDF2-HMAC-SHA256 under a per-user salt, and the stored
string says so.**

```
pbkdf2-sha256$<iterations>$<base64 salt>$<base64 hash>
```

Self-describing, so the work factor is a property of the row rather than of the
build. Raising it later needs no migration: an old row verifies at the cost it was
written with and re-hashes at the new one on its owner's next sign-in.

**`lib/server/pin.dart` is the one place a PIN is hashed or verified.** Sixth of
the single-writer family. The three copies are gone; the two routes and the seed
call it.

**A salted hash cannot be looked up, so sign-in scans and verifies.** `usersForPin`
walks the staff who have a PIN at all and verifies each. This is the cost of the
salt and it is paid deliberately — it also dissolves the collision fault, because
the scan returns a *list*. `userForPin` returns the single match or null, and
**refuses ambiguity rather than guessing**: letting either of two people in would
put the wrong name in the audit log.

The scan runs on its own isolate. Ten thousand rounds times a venue's staff list
is most of a second of tight SHA-256, and the embedded server shares its isolate
with the host tablet's UI.

**Legacy digests still verify, and upgrade themselves on the sign-in that proves
the PIN.** A venue that upgrades mid-service must not find its whole floor locked
out. The plaintext exists for exactly one instant and that instant is the only
place the rewrite can happen.

**Wrong guesses cost time, and the time doubles.** Two attempts are free, then the
device waits 1s, 2s, 4s … capped at a minute, and the route answers 429
`too_many_attempts` with the remaining milliseconds. A success clears the counter.

**There is no lockout.** A lockout on a shared floor device is a denial-of-service
anyone can perform on a colleague mid-rush, in a venue whose whole promise is that
it works when other things do not. The clock is enough: it turns a million guesses
into a geologic span while a waiter who fat-fingered twice waits one second.

The counter is keyed on `deviceId` and held in memory. A restart clears it, and
that is fine — a restart is a physical act by somebody holding the host tablet.

**A failed attempt is audited.** `AuditKind.signInFailed` under its own
`AuditType`, admin-gated like the rest of the staff axis. The row names the device
and the attempt number, never the PIN tried.

**The PIN stays six digits.** Length was considered and rejected: the thing being
protected is a floor device passed between hands mid-service, the entry surface is
a numeric pad reached one-handed with a tray in the other, and eight digits buys
two orders of magnitude against an attacker the clock has already reduced to one
guess a minute. The cost lands on every sign-in of every shift; the benefit lands
on an attack the throttle has already priced out.

## Consequences

- Sign-in is O(staff) in PBKDF2 cost. Fine at a venue's scale, off the UI isolate,
  and the number is on the row if it ever needs to come down.
- `pointycastle` is named directly in `pubspec.yaml`. It was already there
  transitively through `dart_jsonwebtoken`; nothing new is shipped.
- `resolveStepUp` in `settlement_routes.dart` verifies instead of matching, and
  inherits the ambiguity refusal — which is the fail-closed a manager step-up
  already wanted.
- `_pinCollision` verifies against **disabled** staff too. Their PIN is still
  theirs, and handing it to somebody else makes the trail ambiguous the day they
  come back.
- The throttle is per-device, not per-user. A wrong PIN does not identify a user,
  so there is nobody to throttle but the handset doing the asking.
- Amends ADR-0102 and ADR-0080: the LAN is trusted for *presence*, never for
  patience.
