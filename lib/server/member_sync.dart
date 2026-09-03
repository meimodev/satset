/// The server half of the [[Salinan pelanggan]] — one paged, cursor-driven read
/// that fills and refreshes a device's copy of the directory (ADR-0129).
///
/// Why this is a file of its own rather than another function in
/// `members.dart`: everything here is about **the copy**, not the member. The
/// cursor, the tombstone stream and the masking rule are one concern with one
/// invariant — *a device that keeps calling with the cursor it was given
/// converges on the venue's directory and never silently misses a row* — and
/// `members.dart` is already the writer of record for four ledgers.
///
/// The one thing it must never become is a second reader of member state.
/// `listMembers` and `getMember` stay the way a member is read; this walks
/// them in revision order and nothing else.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/db/database.dart' as rows show Member;
import 'package:satset/server/members.dart';

/// How many rows one sync page carries. A first sync of a low-thousands
/// directory is a handful of these; a steady-state one is almost always a
/// single short page.
const kMemberSyncPage = 200;

/// A member that went away, on the wire.
typedef MemberTombstoneRow = ({String id, String? mergedInto});

/// One page of the mirror: rows to upsert, ids to forget, and where to resume.
class MemberSyncPage {
  const MemberSyncPage({
    required this.upserts,
    required this.tombstones,
    required this.cursor,
    required this.hasMore,
  });

  final List<Member> upserts;
  final List<MemberTombstoneRow> tombstones;

  /// Where the next call resumes. Opaque to the client on purpose — it is a
  /// revision number today and the client must never parse it, because a
  /// cursor it can build is a cursor it can build wrong.
  final String? cursor;

  /// Whether another page is waiting **now**. A client drains until this is
  /// false, then stops until the next reconnect; it is not a "more later" flag.
  final bool hasMore;
}

/// Mint the venue's mask salt if it has none yet, and hand it back.
///
/// Never rotated: a new salt blinds every mirror in the venue until each one
/// refetches, and the only thing rotation would buy is invalidating hashes
/// that are already on devices the venue still trusts.
Future<String> memberMirrorSalt(AppDatabase db) async {
  final row = await db.select(db.venueSettings).getSingleOrNull();
  final existing = row?.memberMirrorSalt ?? '';
  if (existing.isNotEmpty) return existing;
  final rng = Random.secure();
  final salt = [
    for (var i = 0; i < 32; i++) rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
  await db
      .update(db.venueSettings)
      .write(VenueSettingsCompanion(memberMirrorSalt: Value(salt)));
  return salt;
}

/// The searchable stand-in for a phone number on a masked mirror.
///
/// Salted, because a bare digest of a phone number is not a mask — the number
/// space is small enough to enumerate, so an unsalted hash hands back every
/// number to anyone holding the file.
String memberPhoneHash(String phone, String salt) =>
    sha256.convert(utf8.encode('$salt:${normalizePhone(phone)}')).toString();

/// Last four digits, for reading an identity back over a counter.
String memberPhoneTail(String phone) {
  final digits = normalizePhone(phone);
  return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
}

/// Everything changed since [cursor], oldest first.
///
/// Upserts and tombstones are paged **together** against one budget, so a
/// venue that deleted three hundred members cannot starve the upsert stream (or
/// the reverse). Both sit in one revision sequence, which is what lets a single
/// integer resume both.
Future<MemberSyncPage> memberSyncPage(
  AppDatabase db, {
  String? cursor,
  int limit = kMemberSyncPage,
}) async {
  final from = int.tryParse(cursor ?? '') ?? 0;
  final take = limit.clamp(1, 1000);

  // `mirrorRev` is nullable only for rows written before v71 backfilled it. A
  // null reads as 0 — the very start of the stream — so such a row is handed
  // over on a first sync rather than dropping out of the walk entirely.
  final rev = coalesce([db.members.mirrorRev, const Constant(0)]);
  final memberRows =
      await (db.select(db.members)
            ..where((m) => rev.isBiggerThanValue(from))
            ..orderBy([(m) => OrderingTerm.asc(rev)])
            // One over the budget, so "is there more" is an observation rather
            // than a second count query that can disagree with the page it
            // describes.
            ..limit(take + 1))
          .get();

  final tombRows =
      await (db.select(db.memberTombstones)
            ..where((t) => t.rev.isBiggerThanValue(from))
            ..orderBy([(t) => OrderingTerm.asc(t.rev)])
            ..limit(take + 1))
          .get();

  // Merge the two streams on the shared sequence and cut at the budget. The cut
  // point is what the cursor names, so nothing between them is skipped:
  // whichever side lost the race is simply still there on the next call.
  final merged =
      <({int rev, rows.Member? member, MemberTombstoneRow? tomb})>[
        for (final m in memberRows)
          (rev: m.mirrorRev ?? 0, member: m, tomb: null),
        for (final t in tombRows)
          (
            rev: t.rev,
            member: null,
            tomb: (id: t.id, mergedInto: t.mergedInto),
          ),
      ]..sort((a, b) => a.rev.compareTo(b.rev));

  final hasMore = merged.length > take;
  final page = hasMore ? merged.sublist(0, take) : merged;
  final upsertRows = [
    for (final e in page)
      if (e.member != null) e.member!,
  ];

  return MemberSyncPage(
    // Decorated exactly as the directory decorates: a mirror must never
    // compute a figure the server computes, so it is handed the same numbers
    // `/members` would have handed it (ADR-0092, ADR-0095).
    upserts: upsertRows.isEmpty
        ? const []
        : await decorateMembers(db, upsertRows),
    tombstones: [
      for (final e in page)
        if (e.tomb != null) e.tomb!,
    ],
    cursor: page.isEmpty ? cursor : '${page.last.rev}',
    hasMore: hasMore,
  );
}

/// One mirrored member on the wire.
///
/// [salt] non-null means **masked**: the number leaves as a salted hash plus
/// its last four digits and never in the clear. That is the whole difference
/// between what a till stores and what a handset that may only take orders
/// stores — the same split `/members/lookup` already makes on the wire, applied
/// to a copy that sits on disk.
Map<String, dynamic> memberMirrorJson(Member m, {String? salt}) {
  final full = memberJson(m);
  if (salt == null) return full;
  return {
    ...full,
    'phone': '',
    'phoneHash': memberPhoneHash(m.phone, salt),
    'phoneTail': memberPhoneTail(m.phone),
    // Withheld with the number, because both are contact details and a masked
    // mirror is not the place to keep the venue's notes on a person.
    'note': null,
    'birthday': null,
    'address': const MemberAddress().toJson(),
  };
}

/// The wire shape of one page.
Map<String, dynamic> memberSyncJson(
  MemberSyncPage page, {
  String? salt,
  required bool masked,
}) => {
  'members': [
    for (final m in page.upserts)
      memberMirrorJson(m, salt: masked ? salt : null),
  ],
  'gone': [
    for (final t in page.tombstones)
      {'id': t.id, if (t.mergedInto != null) 'mergedInto': t.mergedInto},
  ],
  'cursor': page.cursor,
  'hasMore': page.hasMore,
  'masked': masked,
  // Only an unmasked caller is trusted with the salt, and only a masked one
  // needs it. Handed over once per sync rather than on its own route: a device
  // that can read the mirror can read the salt, and a second endpoint is a
  // second thing to authorise.
  if (masked) 'salt': salt,
  'at': SatClock.now().toIso8601String(),
};
