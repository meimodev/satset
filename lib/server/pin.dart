/// **The** place a staff PIN is turned into a stored secret, or checked against
/// one. Sixth of the single-writer family, and it exists for the reason the
/// others do: `_hashPin` was copy-pasted into three files and every one of them
/// had to agree, forever, or a PIN set on the Staf sheet would stop opening the
/// door it was set for.
///
/// A stored hash is self-describing:
///
/// ```
/// pbkdf2-sha256$<iterations>$<base64 salt>$<base64 hash>
/// ```
///
/// which is what makes the cost raisable later without a migration, and what
/// lets [verifyPin] still recognise the old `sha256('satset.v1::' + pin)` hex
/// a venue already has on disk. See docs/adr/0112-pin-hardening.md.
library;

import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:pointycastle/export.dart';

import 'db/database.dart';

/// Work factor for a new hash. Every sign-in scans the staff list — a salted
/// hash cannot be looked up by value — so the cost the venue pays is this
/// times the number of people who work there, not this once. Ten thousand
/// keeps a thirty-person venue under a second on the host tablet, off the UI
/// isolate. Raising it costs nothing but time: existing rows carry the number
/// they were written with, and re-hash on their owner's next sign-in.
const int pinIterations = 10000;

const String _scheme = 'pbkdf2-sha256';
const int _saltBytes = 16;
const int _keyBytes = 32;

final Random _rng = Random.secure();

/// Hash [pin] under a freshly drawn salt. Two people with the same PIN get
/// different stored values, which is the whole point: a six-digit PIN has a
/// million candidates, so an unsalted digest is a rainbow-table lookup and,
/// worse, made the two rows *visibly identical* to anyone reading the table.
String hashPin(String pin, {int iterations = pinIterations}) {
  final salt = Uint8List.fromList(
    List<int>.generate(_saltBytes, (_) => _rng.nextInt(256)),
  );
  final key = _derive(pin, salt, iterations);
  return '$_scheme\$$iterations\$${base64.encode(salt)}\$${base64.encode(key)}';
}

/// Whether [pin] is the secret behind [stored].
///
/// Accepts both shapes. A venue that has been running since before ADR-0112
/// holds bare hex digests, and refusing those would lock every member of staff
/// out of a venue that upgraded mid-service — so they still verify, and
/// [ServerAuth] re-hashes the row the moment one of them signs in.
bool verifyPin(String stored, String pin) {
  if (stored.isEmpty || pin.isEmpty) return false;
  if (isLegacyPinHash(stored)) {
    return _constantTimeEquals(
      utf8.encode(stored),
      utf8.encode(legacyHashPin(pin)),
    );
  }
  final parts = stored.split(r'$');
  if (parts.length != 4 || parts[0] != _scheme) return false;
  final iterations = int.tryParse(parts[1]);
  if (iterations == null || iterations <= 0) return false;
  final Uint8List salt;
  final Uint8List expected;
  try {
    salt = base64.decode(parts[2]);
    expected = base64.decode(parts[3]);
  } on FormatException {
    return false;
  }
  return _constantTimeEquals(expected, _derive(pin, salt, iterations));
}

/// True for the pre-ADR-0112 shape — a bare sha256 hex digest with no scheme,
/// no salt and no cost. An empty hash is *not* legacy: it means this user has
/// no PIN at all (the host admin, authed by Firebase), and nothing may verify
/// against it.
bool isLegacyPinHash(String stored) =>
    stored.isNotEmpty && !stored.startsWith('$_scheme\$');

/// The old digest, kept only so [verifyPin] can recognise what is already on
/// disk. Never write one.
String legacyHashPin(String pin) =>
    sha256.convert(utf8.encode('satset.v1::$pin')).toString();

Uint8List _derive(String pin, Uint8List salt, int iterations) {
  final d = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
    ..init(Pbkdf2Parameters(salt, iterations, _keyBytes));
  return d.process(Uint8List.fromList(utf8.encode(pin)));
}

/// Compare without leaking where the two differ. The timing of a PIN check is
/// observable over the LAN, and an early return on the first wrong byte is the
/// classic way to turn a million-candidate space into six ten-candidate ones.
bool _constantTimeEquals(List<int> a, List<int> b) {
  var diff = a.length ^ b.length;
  for (var i = 0; i < a.length && i < b.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

/// Every candidate [pin] could belong to, in no particular order.
///
/// A salted hash cannot be looked up by value, so this scans. That is the
/// price of the salt and it is paid deliberately: the query it replaces was
/// `WHERE pin_hash = ?` with `getSingleOrNull`, which meant two people sharing
/// a PIN did not merely resolve to the wrong one — it *threw*, and both of
/// them were locked out with a 500.
///
/// The verification loop runs on its own isolate. [pinIterations] rounds times
/// a venue's staff list is most of a second of tight SHA-256, and the embedded
/// server shares its isolate with the host tablet's UI.
///
/// Legacy rows re-hash themselves here, on the sign-in that proves the PIN: it
/// is the only moment the plaintext exists, so it is the only moment the
/// upgrade can happen.
Future<List<User>> usersForPin(
  AppDatabase db,
  String pin, {
  bool onlyEnabled = true,
}) async {
  if (pin.isEmpty) return const [];
  // A user with no PIN is not a candidate for any PIN. The venue's one admin
  // is authed in-process by Firebase and holds an empty hash (ADR-0077).
  final query = db.select(db.users)..where((u) => u.pinHash.equals('').not());
  if (onlyEnabled) query.where((u) => u.disabled.equals(false));
  final rows = await query.get();
  if (rows.isEmpty) return const [];

  final hashes = [for (final u in rows) u.pinHash];
  final matched = await Isolate.run(() {
    return [
      for (var i = 0; i < hashes.length; i++)
        if (verifyPin(hashes[i], pin)) i,
    ];
  });

  final users = [for (final i in matched) rows[i]];
  for (final u in users) {
    if (isLegacyPinHash(u.pinHash)) {
      await (db.update(db.users)..where((x) => x.id.equals(u.id))).write(
        UsersCompanion(pinHash: Value(hashPin(pin))),
      );
    }
  }
  return users;
}

/// The single user [pin] identifies, or null when it identifies none — or more
/// than one.
///
/// Ambiguity is refused rather than guessed. The Staf sheet has always
/// answered 409 to a PIN already in use, so two live rows sharing one can only
/// come from data written before that guard; letting either of them in would
/// mean the audit log names the wrong person.
Future<User?> userForPin(
  AppDatabase db,
  String pin, {
  bool onlyEnabled = true,
}) async {
  final users = await usersForPin(db, pin, onlyEnabled: onlyEnabled);
  return users.length == 1 ? users.first : null;
}
