import 'dart:math';

/// The code in a guest URL (`/t/<code>`) — the *whole* guest credential
/// (ADR-0105). Crockford-ish alphabet: no `I`, `L`, `O`, `U`, `0`, `1`, so a
/// code read off a printed card cannot be mistyped into a different table's.
const _guestAlphabet = '23456789ABCDEFGHJKMNPQRSTVWXYZ';

final _rng = Random.secure();

/// 8 chars of the 30-symbol alphabet ≈ 39 bits. Guessing one over a LAN, at a
/// table that must also be seated, is not the threat model — rotation is.
String mintGuestCode() =>
    List.generate(8, (_) => _guestAlphabet[_rng.nextInt(_guestAlphabet.length)])
        .join();
