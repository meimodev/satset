/// [[Pelanggan (member)]] and the [[Poin]] ledger — every write to `members` and
/// `member_points` goes through here, for the reason `writeAudit` and `cash.dart`
/// exist: a rule enforced in one route reaches three call sites out of four.
///
/// Three invariants live in this file and nowhere else:
///
/// - **The phone number is the identity** (ADR-0092). Normalised on the way in,
///   unique in the schema, and an enrol on an existing number *attaches*.
/// - **The points balance is derived.** `SUM(delta)`, every time. Nothing stores
///   it, and it can never go below zero.
/// - **Points earn once, at bill close** (ADR-0095) — never per payment, and a
///   reopen reverses rather than rewrites.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/server/modules.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/server/audit_log.dart';
import 'package:satset/server/debts.dart'
    show creditLimitFor, debtConfig, memberDebt;
// Hidden: Drift generates its own `Member` for the row, and the two are
// different things — one is the table, one is what a reader sees. Same
// collision `cash.dart` resolves the same way.
import 'package:satset/server/db/database.dart' hide Member;
// ...and once more under a prefix, so the row type is still nameable where a
// helper takes a page of them. Two imports beat prefixing every domain use.
import 'package:satset/server/db/database.dart' as rows show Member;
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

/// Thrown for a refusal a person needs to act on. The [code] crosses the wire
/// and the words are composed client-side (ADR-0085).
class MemberException implements Exception {
  final String code;

  /// Present on `insufficient_points` so the till can say how many there are
  /// rather than making the cashier go and look.
  final int? points;

  /// Present on `phone_taken` — the member who already owns the number, so the
  /// UI can offer to attach them instead of arguing.
  final String? memberId;

  const MemberException(this.code, {this.points, this.memberId});

  @override
  String toString() => 'MemberException($code)';
}

/// The membership half of `venue_settings`, read as one row.
class MemberConfig {
  final bool enabled;

  /// Whether a [[Split bill]] may name a [[Pemilik struk]] per receipt
  /// (ADR-0118). Composed here and nowhere else, like [enabled] — a route that
  /// asks about modules for itself is a review finding.
  ///
  /// Fails **closed**: it reads through `venueHasMode`, so an unmirrored venue
  /// is not offered a picker whose only outcome is a mis-attributed row in a
  /// ledger that never expires.
  final bool splitEnabled;
  final bool pointsEnabled;
  final bool punchEnabled;
  final String? presetId;
  final int earnPerThousand;
  final int pointValue;
  final int redeemMin;
  final String? punchItemId;
  final int punchTarget;

  const MemberConfig({
    required this.enabled,
    required this.splitEnabled,
    required this.pointsEnabled,
    required this.punchEnabled,
    required this.presetId,
    required this.earnPerThousand,
    required this.pointValue,
    required this.redeemMin,
    required this.punchItemId,
    required this.punchTarget,
  });

  /// A program needs both the toggle and an item — a toggle alone runs nothing.
  bool get punchRunning => enabled && punchEnabled && punchItemId != null;
}

Future<MemberConfig> memberConfig(AppDatabase db) async {
  final s = await (db.select(
    db.venueSettings,
  )..where((v) => v.id.equals('default'))).getSingleOrNull();
  return MemberConfig(
    // Entitlement AND preference, composed once (ADR-0107 §3): `membersEnabled`
    // is what the venue *wants*, the module is what it *may have*. Kept as two
    // facts so "they said no" stays distinguishable from "they can't", and so
    // re-entitling restores the owner's own choice rather than a default.
    enabled: (s?.membersEnabled ?? false) && venueHasModule(s, moduleMembers),
    // Three facts ANDed, not two: the owner's preference, the sellable module,
    // and the mode key on top (ADR-0118). Attribution is meaningless without
    // membership itself, so it can never outlive it.
    splitEnabled:
        (s?.membersEnabled ?? false) &&
        venueHasModule(s, moduleMembers) &&
        venueHasMode(s, modeMemberSplit),
    pointsEnabled: s?.memberPointsEnabled ?? false,
    punchEnabled: s?.memberPunchEnabled ?? false,
    presetId: s?.memberPresetId,
    earnPerThousand: s?.memberEarnPerThousand ?? 1,
    pointValue: s?.memberPointValue ?? 1000,
    redeemMin: s?.memberRedeemMin ?? 10,
    punchItemId: s?.memberPunchItemId,
    punchTarget: s?.memberPunchTarget ?? 10,
  );
}

/// What a member has right now.
Future<int> memberPoints(AppDatabase db, String memberId) async {
  final sum = db.memberPoints.delta.sum();
  final row =
      await (db.selectOnly(db.memberPoints)
            ..addColumns([sum])
            ..where(db.memberPoints.memberId.equals(memberId)))
          .getSingleOrNull();
  return row?.read(sum) ?? 0;
}

/// The [[Kartu stempel (punch card)]] state for one member, **derived from
/// settled history** — nothing stores a counter, for the reason nothing stores
/// the cash balance.
///
/// `bought` counts paid, non-voided, non-comped units of the program item;
/// `given` counts the comped ones, which is what a reward *is*. A reward is due
/// whenever the cards earned outrun the cards handed over.
class PunchStatus {
  final int bought;
  final int given;
  final int target;
  const PunchStatus({
    required this.bought,
    required this.given,
    required this.target,
  });

  /// How far into the current card, e.g. 3 of 10.
  int get progress => target <= 0 ? 0 : bought % target;
  int get earned => target <= 0 ? 0 : bought ~/ target;
  bool get rewardDue => earned > given;
}

Future<PunchStatus> punchStatus(
  AppDatabase db,
  String memberId, {
  MemberConfig? cfg,
}) async {
  final c = cfg ?? await memberConfig(db);
  if (!c.punchRunning) {
    return PunchStatus(bought: 0, given: 0, target: c.punchTarget);
  }
  final t = db.tableSessionTickets;
  final s = db.tableSessions;
  final r = db.tableSessionReceipts;
  final rl = db.tableSessionReceiptLines;

  // Which closed sessions can hold a unit of this member's: the ones they
  // owned, plus — under `memberSplit` — any whose receipts name them, which
  // includes bills owned by somebody else entirely (ADR-0118).
  final ownedSessions =
      await (db.selectOnly(s)
            ..addColumns([s.id])
            ..where(s.memberId.equals(memberId)))
          .get();
  final sessionIds = {for (final row in ownedSessions) row.read(s.id)!};
  final attributed =
      await (db.selectOnly(r)
            ..addColumns([r.sessionId])
            ..where(r.memberId.equals(memberId)))
          .get();
  sessionIds.addAll(attributed.map((row) => row.read(r.sessionId)!));
  if (sessionIds.isEmpty) {
    return PunchStatus(bought: 0, given: 0, target: c.punchTarget);
  }

  final tickets =
      await (db.select(t)..where(
            (x) => x.sessionId.isIn(sessionIds) & x.itemId.equals(c.punchItemId!),
          ))
          .get();
  if (tickets.isEmpty) {
    return PunchStatus(bought: 0, given: 0, target: c.punchTarget);
  }

  // Owner of each session, so an unclaimed unit can fall back to them.
  final sessionOwner = {
    for (final row
        in await (db.selectOnly(s)
              ..addColumns([s.id, s.memberId])
              ..where(s.id.isIn(sessionIds)))
            .get())
      row.read(s.id)!: row.read(s.memberId),
  };

  // Receipt → its [[Pemilik struk]], and the line assignments that point at
  // one.
  //
  // Deliberately **not** gated on [MemberConfig.splitEnabled]: a stored
  // attribution is the record of what happened, and unticking the mode today
  // must not change what a closed month counted (ADR-0118 §6 — freeze, never
  // delete). At a venue that never held the mode every `memberId` here is
  // null, so the fallback below hands every unit to whoever owned the bill,
  // which is the pre-ADR-0118 reading exactly. The flag gates the *write* and
  // the picker, never the read.
  final receiptOwner = {
    for (final row
        in await (db.select(r)..where((x) => x.sessionId.isIn(sessionIds))).get())
      row.receiptId: row.memberId,
  };
  final lines = await (db.select(
    rl,
  )..where((x) => x.sessionId.isIn(sessionIds))).get();
  final linesByTicket = <String, List<TableSessionReceiptLine>>{};
  for (final line in lines) {
    (linesByTicket[line.ticketId] ??= <TableSessionReceiptLine>[]).add(line);
  }

  var bought = 0;
  var given = 0;
  void tally(TableSessionTicket tk, int units) {
    if (units <= 0) return;
    final voided = tk.status == 'voided';
    // A comp is a void carrying reason code `comp` (ADR-0006) — so the reward
    // is found the same way the comp tile finds it, not by a second flag.
    if (voided && tk.voidReasonCode == 'comp') {
      given += units;
    } else if (!voided) {
      bought += units;
    }
  }

  for (final tk in tickets) {
    final owner = sessionOwner[tk.sessionId];
    var assigned = 0;
    for (final line
        in linesByTicket[tk.ticketId] ?? const <TableSessionReceiptLine>[]) {
      assigned += line.qtyUnits;
      // An unattributed receipt is the bill owner's, same rule the points
      // remainder follows — a receipt nobody named does not orphan its units.
      final holder = receiptOwner[line.receiptId] ?? owner;
      if (holder == memberId) tally(tk, line.qtyUnits);
    }
    // Units on no receipt at all — including every unit of a bill split into
    // [[Amount receipt|amount receipts]], which own no lines. An even split
    // has already abandoned tracking who ordered what, so its punches stay
    // with the [[Pemilik tagihan]]: money can be attributed there, lines
    // cannot.
    if (owner == memberId) tally(tk, tk.qty - assigned);
  }
  return PunchStatus(bought: bought, given: given, target: c.punchTarget);
}

/// The **only** member fact that may cross the guest plane (ADR-0110): how far
/// into the current card, and how long a card is. Two integers, and nothing
/// else — no name, no phone echoed back, no points, no debt.
///
/// An unknown phone answers in the **same shape** as a known one, a zeroed
/// card. A 404-for-absent would make this an enumeration oracle for enrolment
/// no matter how little it carried, which is the whole reason the list is
/// closed at two integers.
///
/// A finished card reads `progress == target`. That is the reward waiting at
/// the till: `bought % target` alone would show a full card as an empty one,
/// and the guest would be told to buy ten more.
///
/// Returns null only when the program is not running — the route turns that
/// into a 404 identical to every other member route on a venue that never
/// opted in (ADR-0091), so a guest cannot tell an unlicensed venue from an old
/// server.
Future<({int progress, int target})?> guestPunchStatus(
  AppDatabase db,
  String phone,
) async {
  final c = await memberConfig(db);
  if (!c.punchRunning) return null;
  final m = await findMemberByPhone(db, phone);
  if (m == null) return (progress: 0, target: c.punchTarget);
  final p = await punchStatus(db, m.id, cfg: c);
  return (progress: p.rewardDue ? p.target : p.progress, target: p.target);
}

/// Read a member with everything a reader needs, including the two derived
/// figures. Returns null when the id is unknown — which is also what a deleted
/// member looks like, deliberately (ADR-0092).
Future<Member?> getMember(AppDatabase db, String id) async {
  final row = await (db.select(
    db.members,
  )..where((m) => m.id.equals(id))).getSingleOrNull();
  if (row == null) return null;
  final list = await _decorate(db, [row]);
  return list.first;
}

/// Lookup by typed phone. The number is normalised first, so `+62813…` finds
/// the member enrolled as `0813…`.
Future<Member?> findMemberByPhone(AppDatabase db, String phone) async {
  final normalised = normalizePhone(phone);
  if (normalised.isEmpty) return null;
  final row = await (db.select(
    db.members,
  )..where((m) => m.phone.equals(normalised))).getSingleOrNull();
  if (row == null) return null;
  return (await _decorate(db, [row])).first;
}

/// The directory, and the cashier's prefix search behind one function.
///
/// [query] matches a phone **prefix** (the till's numeric keypad) or a name
/// substring (the admin directory). [birthdayMonth] is 1..12 for the "ulang
/// tahun bulan ini" filter, which is the whole of the birthday feature.
///
/// [lapsedDays] keeps only members whose last settled visit is older than that
/// many days — the "belum kembali" cut. **Never visited counts as lapsed**: an
/// enrolment that never came back is exactly who the filter is for. Nothing is
/// stored and no status exists; lapse is read off `lastVisitAt` each time, for
/// the reason points never expire (ADR-0095) — the server has no scheduler.
Future<List<Member>> listMembers(
  AppDatabase db, {
  String query = '',
  int? birthdayMonth,
  int? lapsedDays,
  int limit = 50,
}) async {
  final q = db.select(db.members);
  final typed = query.trim();
  if (typed.isNotEmpty) {
    final digits = normalizePhone(typed);
    if (digits.isNotEmpty) {
      q.where((m) => m.phone.like('$digits%'));
    } else {
      q.where((m) => m.name.lower().like('%${typed.toLowerCase()}%'));
    }
  }
  q
    ..orderBy([(m) => OrderingTerm.asc(m.name)])
    ..limit(limit);
  var rows = await q.get();
  if (birthdayMonth != null) {
    rows = rows.where((m) => m.birthday?.month == birthdayMonth).toList();
  }
  final page = await _decorate(db, rows);
  if (lapsedDays == null) return page;
  // Filtered after the page, like the birthday cut above: `lastVisitAt` is
  // derived in _decorate, not a column to put in a WHERE.
  final cutoff = SatClock.now().toUtc().subtract(Duration(days: lapsedDays));
  return page
      .where((m) => m.lastVisitAt == null || m.lastVisitAt!.isBefore(cutoff))
      .toList();
}

/// Attach the derived figures to a page of rows with two grouped queries rather
/// than two per member — the directory is read on every till lookup.
Future<List<Member>> _decorate(
  AppDatabase db,
  List<rows.Member> page, {
  MemberConfig? cfg,
}) async {
  if (page.isEmpty) return const [];
  final ids = page.map((r) => r.id).toList();
  final c = cfg ?? await memberConfig(db);

  final pSum = db.memberPoints.delta.sum();
  final pRows =
      await (db.selectOnly(db.memberPoints)
            ..addColumns([db.memberPoints.memberId, pSum])
            ..where(db.memberPoints.memberId.isIn(ids))
            ..groupBy([db.memberPoints.memberId]))
          .get();
  final points = {
    for (final r in pRows) r.read(db.memberPoints.memberId)!: r.read(pSum) ?? 0,
  };

  final dSum = db.memberDebts.delta.sum();
  final dRows =
      await (db.selectOnly(db.memberDebts)
            ..addColumns([db.memberDebts.memberId, dSum])
            ..where(db.memberDebts.memberId.isIn(ids))
            ..groupBy([db.memberDebts.memberId]))
          .get();
  final debts = {
    for (final r in dRows) r.read(db.memberDebts.memberId)!: r.read(dSum) ?? 0,
  };
  final dCfg = await debtConfig(db);

  final s = db.tableSessions;
  final cnt = s.id.count();
  final spend = s.settledTotal.sum();
  final last = s.closedAt.max();
  final sRows =
      await (db.selectOnly(s)
            ..addColumns([s.memberId, cnt, spend, last])
            ..where(s.memberId.isIn(ids))
            ..groupBy([s.memberId]))
          .get();
  final visits = {for (final r in sRows) r.read(s.memberId)!: r.read(cnt) ?? 0};
  final spent = {
    for (final r in sRows) r.read(s.memberId)!: r.read(spend) ?? 0,
  };
  final lastAt = {for (final r in sRows) r.read(s.memberId)!: r.read(last)};

  final out = <Member>[];
  for (final r in page) {
    final punch = await punchStatus(db, r.id, cfg: c);
    out.add(
      Member(
        id: r.id,
        name: r.name,
        phone: r.phone,
        code: r.code,
        note: r.note,
        birthday: r.birthday,
        joinedAt: r.joinedAt,
        points: points[r.id] ?? 0,
        punchProgress: punch.progress,
        visitCount: visits[r.id] ?? 0,
        lifetimeSpend: spent[r.id] ?? 0,
        lastVisitAt: lastAt[r.id],
        debt: debts[r.id] ?? 0,
        debtLimit: creditLimitFor(r.debtLimit, dCfg),
        ownDebtLimit: r.debtLimit,
      ),
    );
  }
  return out;
}

/// Enrol. **A number that already exists attaches rather than duplicating** —
/// the caller is told which member owns it and offers to use them (ADR-0092).
Future<Member> createMember(
  AppDatabase db, {
  required String name,
  required String phone,
  String? note,
  DateTime? birthday,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  final cleanName = name.trim();
  final cleanPhone = normalizePhone(phone);
  if (cleanName.isEmpty) throw const MemberException('name_required');
  // There is no anonymous member. A guest who will not give a number is simply
  // not one, and a placeholder identity would poison the uniqueness rule that
  // the whole scheme rests on.
  if (cleanPhone.length < 6) throw const MemberException('phone_required');
  final existing = await (db.select(
    db.members,
  )..where((m) => m.phone.equals(cleanPhone))).getSingleOrNull();
  if (existing != null) {
    throw MemberException('phone_taken', memberId: existing.id);
  }
  final id = '${idPrefix ?? ''}${_uuid.v4()}';
  final when = at ?? SatClock.now();
  await db
      .into(db.members)
      .insert(
        MembersCompanion.insert(
          id: id,
          name: cleanName,
          phone: cleanPhone,
          joinedAt: when,
          code: Value(_codeFor(cleanPhone)),
          note: Value(note),
          birthday: Value(birthday),
        ),
      );
  await writeAudit(
    db,
    type: AuditType.memberChanged,
    kind: AuditKind.memberCreated,
    params: {'name': cleanName},
    actorUserId: actorUserId,
    hub: hub,
    at: at,
    idPrefix: idPrefix,
  );
  final member = (await getMember(db, id))!;
  _broadcast(hub, member);
  return member;
}

/// Last six digits — short enough to read back over a counter, long enough not
/// to collide in a venue's directory. Display only; [Member.phone] is the key,
/// so a collision would be cosmetic rather than an identity bug.
String _codeFor(String phone) =>
    phone.length <= 6 ? phone : phone.substring(phone.length - 6);

Future<Member> updateMember(
  AppDatabase db, {
  required String id,
  String? name,
  String? phone,
  String? note,
  DateTime? birthday,
  bool clearBirthday = false,

  /// This member's own credit limit. Absent leaves it alone; [clearDebtLimit]
  /// puts them back on the venue default — the two are different, which is why
  /// a null here cannot mean both.
  int? debtLimit,
  bool clearDebtLimit = false,
  WsHub? hub,
}) async {
  final row = await (db.select(
    db.members,
  )..where((m) => m.id.equals(id))).getSingleOrNull();
  if (row == null) throw const MemberException('not_found');
  var newPhone = row.phone;
  if (phone != null) {
    newPhone = normalizePhone(phone);
    if (newPhone.length < 6) throw const MemberException('phone_required');
    if (newPhone != row.phone) {
      final clash = await (db.select(
        db.members,
      )..where((m) => m.phone.equals(newPhone))).getSingleOrNull();
      if (clash != null) {
        throw MemberException('phone_taken', memberId: clash.id);
      }
    }
  }
  await (db.update(db.members)..where((m) => m.id.equals(id))).write(
    MembersCompanion(
      name: name == null ? const Value.absent() : Value(name.trim()),
      phone: Value(newPhone),
      code: Value(_codeFor(newPhone)),
      note: note == null ? const Value.absent() : Value(note),
      birthday: clearBirthday
          ? const Value(null)
          : (birthday == null ? const Value.absent() : Value(birthday)),
      debtLimit: clearDebtLimit
          ? const Value(null)
          : (debtLimit == null ? const Value.absent() : Value(debtLimit)),
    ),
  );
  final member = (await getMember(db, id))!;
  _broadcast(hub, member);
  return member;
}

/// **Delete anonymises; it never erases money** (ADR-0092).
///
/// The person and their ledger go. Every closed [[Bill (tab)]] keeps its
/// `memberId` and renders as "Pelanggan dihapus", so the member/non-member sales
/// split still tells the truth about trade that actually happened.
Future<void> deleteMember(
  AppDatabase db, {
  required String id,
  String? actorUserId,
  WsHub? hub,
}) async {
  final row = await (db.select(
    db.members,
  )..where((m) => m.id.equals(id))).getSingleOrNull();
  if (row == null) throw const MemberException('not_found');
  // Check and delete are one atomic step (ADR-0100). The debt balance is
  // `SUM(delta)` like every other ledger here, so the guard below is Dart and
  // nothing else — a charge landing between the read and the delete would take
  // a live receivable out with the person, which is the one outcome this
  // function exists to refuse.
  await db.transaction(() async {
    // ...because a live [[Piutang]] balance IS money, and deleting it would
    // erase a receivable with no record of the amount (ADR-0098). Refuse, so
    // the owner has to say which it was — collected, or given up on. Both are
    // routes.
    final owed = await memberDebt(db, id);
    if (owed != 0) throw const MemberException('has_outstanding_debt');
    await (db.delete(
      db.memberPoints,
    )..where((p) => p.memberId.equals(id))).go();
    // The debt ledger stays. The balance is zero, so nothing is owed to anyone
    // — but a `charge` or a `writeOff` is money that moved, and dropping the
    // rows would rewrite last month's bad-debt total from a delete button.
    // Same rule as the bills: the person goes, the trade stays counted.
    await (db.delete(db.members)..where((m) => m.id.equals(id))).go();
    await writeAudit(
      db,
      type: AuditType.memberChanged,
      kind: AuditKind.memberDeleted,
      params: {'name': row.name},
      actorUserId: actorUserId,
      hub: hub,
    );
  });
  hub?.broadcast(WsEventTypes.memberDeleted, {'id': id});
}

/// Fold [fromId] into [toId]. Points sum (the ledger simply repoints), punch
/// progress takes the max **because it is derived** — repointing the sessions
/// is what makes that true, with no counter to reconcile.
///
/// Duplicates arrive by typo no matter how strict the uniqueness rule is, so
/// this exists rather than pretending they will not.
Future<Member> mergeMembers(
  AppDatabase db, {
  required String fromId,
  required String toId,
  String? actorUserId,
  WsHub? hub,
}) async {
  if (fromId == toId) throw const MemberException('same_member');
  final from = await (db.select(
    db.members,
  )..where((m) => m.id.equals(fromId))).getSingleOrNull();
  final to = await (db.select(
    db.members,
  )..where((m) => m.id.equals(toId))).getSingleOrNull();
  if (from == null || to == null) throw const MemberException('not_found');
  // Six writes are one act (ADR-0100). A fold that stops halfway has repointed
  // some of the person's history and not the rest — points moved, debt did
  // not, and both balances are `SUM(delta)` over rows that now name two
  // different people. There is no repair for that from the outside, so it
  // either all lands or none of it does.
  await db.transaction(() async {
    await (db.update(db.memberPoints)..where((p) => p.memberId.equals(fromId)))
        .write(MemberPointsCompanion(memberId: Value(toId)));
    // The [[Piutang]] ledger repoints for the same reason the points one does:
    // the balance is `SUM(delta)`, so a fold needs nothing reconciled
    // (ADR-0098).
    await (db.update(db.memberDebts)..where((p) => p.memberId.equals(fromId)))
        .write(MemberDebtsCompanion(memberId: Value(toId)));
    await (db.update(db.tableSessions)..where((s) => s.memberId.equals(fromId)))
        .write(TableSessionsCompanion(memberId: Value(toId)));
    await (db.update(db.visits)..where((v) => v.memberId.equals(fromId))).write(
      VisitsCompanion(memberId: Value(toId)),
    );
    await (db.update(db.reservations)..where((x) => x.memberId.equals(fromId)))
        .write(ReservationsCompanion(memberId: Value(toId)));
    await (db.delete(db.members)..where((m) => m.id.equals(fromId))).go();
    await writeAudit(
      db,
      type: AuditType.memberChanged,
      kind: AuditKind.memberMerged,
      params: {'from': from.name, 'to': to.name},
      actorUserId: actorUserId,
      hub: hub,
    );
  });
  final member = (await getMember(db, toId))!;
  _broadcast(hub, member);
  hub?.broadcast(WsEventTypes.memberDeleted, {'id': fromId});
  return member;
}

/// A hand correction — the only movement with no bill behind it, so it carries
/// a mandatory reason and always audits.
Future<Member> adjustPoints(
  AppDatabase db, {
  required String memberId,
  required int delta,
  required String note,
  String? actorUserId,
  WsHub? hub,
}) async {
  if (delta == 0) throw const MemberException('invalid_amount');
  if (note.trim().isEmpty) throw const MemberException('note_required');
  await _post(
    db,
    memberId: memberId,
    kind: MemberPointKind.adjust,
    delta: delta,
    note: note.trim(),
    actorUserId: actorUserId,
  );
  await writeAudit(
    db,
    type: AuditType.memberChanged,
    kind: AuditKind.memberPointsAdjusted,
    params: {
      'name': (await _nameOf(db, memberId)) ?? '',
      'points': '${delta > 0 ? '+' : ''}$delta',
    },
    actorUserId: actorUserId,
    reason: note.trim(),
    hub: hub,
  );
  final member = (await getMember(db, memberId))!;
  _broadcast(hub, member);
  return member;
}

/// Spend points against a live bill. Writes **only the ledger row** — the caller
/// applies the matching bill discount in the `redeem` slot, so the two land in
/// one settlement request or not at all.
Future<int> spendPoints(
  AppDatabase db, {
  required String memberId,
  required String visitId,
  required int points,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  final cfg = await memberConfig(db);
  if (!cfg.enabled || !cfg.pointsEnabled) {
    throw const MemberException('points_disabled');
  }
  if (points <= 0) throw const MemberException('invalid_amount');
  if (points < cfg.redeemMin) {
    throw MemberException('below_minimum', points: cfg.redeemMin);
  }
  final amount = points * cfg.pointValue;
  // Check and write are one atomic step (ADR-0100): two tills redeeming the
  // same member at once must not both clear a balance neither still meets.
  await db.transaction(() async {
    final balance = await memberPoints(db, memberId);
    if (points > balance) {
      // The ledger cannot go negative, for the reason the cash box cannot: a
      // balance that can be overdrawn is a balance somebody spent twice.
      throw MemberException('insufficient_points', points: balance);
    }
    await _post(
      db,
      memberId: memberId,
      kind: MemberPointKind.redeem,
      delta: -points,
      visitId: visitId,
      actorUserId: actorUserId,
      at: at,
      idPrefix: idPrefix,
    );
    await writeAudit(
      db,
      type: AuditType.memberChanged,
      kind: AuditKind.memberPointsRedeemed,
      params: {
        'name': (await _nameOf(db, memberId)) ?? '',
        'points': '$points',
        'amount': auditRupiah(amount),
      },
      actorUserId: actorUserId,
      amountCents: amount,
      hub: hub,
      at: at,
      idPrefix: idPrefix,
    );
  });
  final member = await getMember(db, memberId);
  if (member != null) _broadcast(hub, member);
  return amount;
}

/// Earn at [[Bill close (Tutup tagihan)|bill close]], once per visit (ADR-0095).
///
/// [base] is the bill net of discount, excluding service and tax — the caller
/// computes it from the same breakdown the receipt printed, so the guest's
/// points agree with the guest's slip.
///
/// **Idempotent**: an un-reversed earn already on this visit wins, because
/// close can be reached twice (a reopen and a re-close, an auto-close racing a
/// manual one) and a guest must not earn twice for one meal.
Future<int> earnPointsForVisit(
  AppDatabase db, {
  required String memberId,
  required String visitId,
  required int base,
  String? actorUserId,
  WsHub? hub,
  DateTime? at,
  String? idPrefix,
}) async {
  final cfg = await memberConfig(db);
  if (!cfg.enabled || !cfg.pointsEnabled) return 0;
  if (base <= 0 || cfg.earnPerThousand <= 0) return 0;
  // Check and write are one atomic step (ADR-0100): the idempotency guard is
  // worth nothing if a re-close can read "no earn yet" while the first close
  // is still inserting one — the guest earns twice for one meal.
  final points = await db.transaction(() async {
    final already = await _earnRowFor(db, visitId, memberId);
    if (already != null) return already.delta;
    final earned = (base ~/ 1000) * cfg.earnPerThousand;
    if (earned <= 0) return 0;
    await _post(
      db,
      memberId: memberId,
      kind: MemberPointKind.earn,
      delta: earned,
      visitId: visitId,
      baseAmount: base,
      actorUserId: actorUserId,
      at: at,
      idPrefix: idPrefix,
    );
    return earned;
  });
  if (points <= 0) return 0;
  final member = await getMember(db, memberId);
  if (member != null) _broadcast(hub, member);
  return points;
}

/// Reverse the earn a reopened bill already paid out. The subsequent re-close
/// earns afresh rather than un-reversing this — an append-only ledger corrects
/// forwards, exactly as the cash box does.
///
/// Taking a redemption back off a *live* bill is [reverseRedeemForVisit], not
/// this. A redemption on a bill already **paid** is never unwound here — the
/// guest took the money off, and correcting that is an audited hand adjustment.
Future<void> reverseEarnForVisit(
  AppDatabase db, {
  required String visitId,
  String? actorUserId,
  WsHub? hub,
}) async {
  // **Every** live earn, not the last one. A [[Split bill]] under
  // `memberSplit` pays out once per member (ADR-0118), so reversing a single
  // row would reopen a bill that still has three of its four guests paid — and
  // nothing downstream would ever surface it.
  final earns = await _liveEarnRows(db, visitId);
  for (final earn in earns) {
    await _post(
      db,
      memberId: earn.memberId,
      kind: MemberPointKind.reversal,
      delta: -earn.delta,
      visitId: visitId,
      actorUserId: actorUserId,
    );
    final member = await getMember(db, earn.memberId);
    if (member != null) _broadcast(hub, member);
  }
}

/// Give a live bill's redemption back — the cashier detached the member, or
/// took the redemption off before any money was taken.
///
/// Points return, which is why this is refused once the bill is settled: the
/// caller checks that, because only it can see the receipts. The matching
/// `redeem`-source discount row is the caller's to delete, for the same reason
/// [spendPoints] does not create it — the two land together or not at all.
Future<void> reverseRedeemForVisit(
  AppDatabase db, {
  required String visitId,
  String? memberId,
  String? actorUserId,
  WsHub? hub,
}) async {
  // [memberId] scopes this to one guest — detaching one [[Pemilik struk]]
  // must not hand back the points of the three sitting beside them. Null means
  // every live redemption on the bill: a visit detach, or a reopen.
  final redeems = await _liveRedeemRows(db, visitId);
  for (final redeem in redeems) {
    if (memberId != null && redeem.memberId != memberId) continue;
    await _post(
      db,
      memberId: redeem.memberId,
      kind: MemberPointKind.reversal,
      delta: -redeem.delta, // positive: the points come back
      visitId: visitId,
      actorUserId: actorUserId,
    );
    final member = await getMember(db, redeem.memberId);
    if (member != null) _broadcast(hub, member);
  }
}

/// The live earn on a visit — an `earn` row with no `reversal` against it.
///
/// A visit can hold a reversed redemption too, so reversals are paired by
/// **sign**: undoing an earn takes points away (negative), undoing a redemption
/// gives them back (positive). Counting them together would let a cancelled
/// redemption make an earn look already reversed, and the bill would pay out
/// twice on its next close.
/// Every live earn on [visitId] — one per member who still has an unreversed
/// one. A [[Split bill]] under `memberSplit` earns for each [[Pemilik struk]]
/// and for the [[Pemilik tagihan]]'s remainder (ADR-0118), so a visit holds as
/// many earns as it had members; without the mode it holds at most one and
/// this returns a list of that length.
///
/// The earn/reversal tally is struck **per member**. Striking it across the
/// visit is what the single-member version did and it silently reads one
/// member's reversal as cancelling another's earn.
/// One receipt's contribution to a bill's points base: who it is *for*, and
/// its own money net of service and tax.
typedef ReceiptBase = ({String? memberId, int base});

/// How a closing bill's points base divides between its members (ADR-0118).
/// Returns `memberId → base`; every entry becomes exactly one earn row.
///
/// The [[Pemilik tagihan]] takes **everything no other member's receipt
/// claimed** — their own receipts, unattributed receipts, and the money no
/// receipt covers at all, which on an unsplit bill is the whole of it. Stated
/// as a subtraction rather than a sum precisely so the three cases need no
/// arms: whatever is not somebody else's is the owner's, and the parts always
/// add back up to [billBase].
///
/// With [splitEnabled] false this returns at most `{owner: billBase}`, which
/// is the pre-ADR-0118 reading exactly.
Map<String, int> pointsBaseByMember({
  required int billBase,
  required String? ownerId,
  required Iterable<ReceiptBase> receipts,
  required bool splitEnabled,
}) {
  final out = <String, int>{};
  var claimedByOthers = 0;
  if (splitEnabled) {
    for (final r in receipts) {
      final id = r.memberId;
      if (id == null || id == ownerId) continue;
      out[id] = (out[id] ?? 0) + r.base;
      claimedByOthers += r.base;
    }
  }
  if (ownerId != null) {
    final ownerBase = billBase - claimedByOthers;
    if (ownerBase > 0) out[ownerId] = ownerBase;
  }
  return out;
}

Future<List<MemberPoint>> _liveEarnRows(AppDatabase db, String visitId) async {
  final rows = await (db.select(
    db.memberPoints,
  )..where((p) => p.visitId.equals(visitId))).get();
  final byMember = <String, List<MemberPoint>>{};
  for (final r in rows) {
    (byMember[r.memberId] ??= <MemberPoint>[]).add(r);
  }
  final live = <MemberPoint>[];
  for (final entry in byMember.entries) {
    final earns = entry.value
        .where((r) => r.kind == MemberPointKind.earn.name)
        .toList();
    final reversals = entry.value
        .where((r) => r.kind == MemberPointKind.reversal.name && r.delta < 0)
        .length;
    if (earns.length > reversals) live.add(earns.last);
  }
  return live;
}

Future<MemberPoint?> _earnRowFor(
  AppDatabase db,
  String visitId,
  String memberId,
) async {
  final live = await _liveEarnRows(db, visitId);
  for (final r in live) {
    if (r.memberId == memberId) return r;
  }
  return null;
}

/// The live redemption on a visit — a `redeem` row with no reversal against it.
/// Every live redemption on [visitId] — one per member who still has an
/// unreversed one. Under `memberSplit` each [[Pemilik struk]] may redeem
/// against their own receipt (ADR-0118), so the spend/undone tally is struck
/// **per member** for the reason [_liveEarnRows] gives.
Future<List<MemberPoint>> _liveRedeemRows(
  AppDatabase db,
  String visitId,
) async {
  final rows = await (db.select(
    db.memberPoints,
  )..where((p) => p.visitId.equals(visitId))).get();
  final byMember = <String, List<MemberPoint>>{};
  for (final r in rows) {
    (byMember[r.memberId] ??= <MemberPoint>[]).add(r);
  }
  final live = <MemberPoint>[];
  for (final entry in byMember.entries) {
    final spends = entry.value
        .where((r) => r.kind == MemberPointKind.redeem.name)
        .toList();
    final undone = entry.value
        .where((r) => r.kind == MemberPointKind.reversal.name && r.delta > 0)
        .length;
    if (spends.length > undone) live.add(spends.last);
  }
  return live;
}


Future<String?> _nameOf(AppDatabase db, String memberId) async {
  final row = await (db.select(
    db.members,
  )..where((m) => m.id.equals(memberId))).getSingleOrNull();
  return row?.name;
}

Future<void> _post(
  AppDatabase db, {
  required String memberId,
  required MemberPointKind kind,
  required int delta,
  String? visitId,
  int baseAmount = 0,
  String? note,
  String? actorUserId,
  DateTime? at,
  String? idPrefix,
}) async {
  // Every path but a redemption reaches here without a balance check, so the
  // floor is enforced once, here, rather than trusted to four callers.
  //
  // And it wraps itself (ADR-0100). The balance is `SUM(delta)`, so no `CHECK`
  // can hold the floor and the guard lives entirely in Dart — which makes it
  // worth nothing unless the read and the insert are one step. `spendPoints`
  // and `earnPointsForVisit` bring their own transaction; this one nests as a
  // savepoint inside theirs, and is the whole transaction for the hand
  // adjustment and the two reversals, which had none.
  await db.transaction(() async {
    if (delta < 0) {
      final balance = await memberPoints(db, memberId);
      if (balance + delta < 0) {
        throw MemberException('insufficient_points', points: balance);
      }
    }
    final actor = await resolveActor(db, actorUserId);
    await db
        .into(db.memberPoints)
        .insert(
          MemberPointsCompanion.insert(
            id: '${idPrefix ?? ''}${_uuid.v4()}',
            memberId: memberId,
            kind: kind.name,
            delta: delta,
            at: at ?? SatClock.now(),
            visitId: Value(visitId),
            baseAmount: Value(baseAmount),
            note: Value(note),
            actorUserId: Value(actorUserId),
            actorName: Value(actor?.name),
          ),
        );
  });
}

/// Ledger rows for one member, newest first, paged by growing limit (ADR-0079).
Future<List<MemberPointEntry>> memberLedger(
  AppDatabase db,
  String memberId, {
  int limit = 50,
}) async {
  final rows =
      await (db.select(db.memberPoints)
            ..where((p) => p.memberId.equals(memberId))
            ..orderBy([
              (p) => OrderingTerm.desc(p.at),
              (p) => OrderingTerm.desc(p.id),
            ])
            ..limit(limit))
          .get();
  return [
    for (final r in rows)
      MemberPointEntry(
        id: r.id,
        memberId: r.memberId,
        kind: memberPointKindFromName(r.kind) ?? MemberPointKind.adjust,
        delta: r.delta,
        visitId: r.visitId,
        baseAmount: r.baseAmount,
        note: r.note,
        actorUserId: r.actorUserId,
        actorName: r.actorName,
        at: r.at,
      ),
  ];
}

void _broadcast(WsHub? hub, Member m) =>
    hub?.broadcast(WsEventTypes.memberUpdated, memberJson(m));

/// Wire shape for one member.
Map<String, dynamic> memberJson(Member m) => {
  'id': m.id,
  'name': m.name,
  'phone': m.phone,
  'code': m.code,
  'note': m.note,
  'birthday': m.birthday?.toIso8601String(),
  'joinedAt': m.joinedAt.toIso8601String(),
  'points': m.points,
  'punchProgress': m.punchProgress,
  'visitCount': m.visitCount,
  'lifetimeSpend': m.lifetimeSpend,
  'lastVisitAt': m.lastVisitAt?.toIso8601String(),
  'debt': m.debt,
  'debtLimit': m.debtLimit,
  'ownDebtLimit': m.ownDebtLimit,
};

/// One settled bill in a member's history, read straight off the snapshot the
/// close writes ([TableSessions], ADR-0024). Deliberately **lifetime** — the
/// report's window lives on the report; a person's file does not have a range.
///
/// Carries no points figure: a `member_points` row names the *visit*, and the
/// snapshot mints its own id while the visit is deleted (`snapshotVisitAndDelete`
/// in `tables_routes.dart`), so nothing joins the two. The ledger tab is where
/// points are read.
class MemberVisitRow {
  final String id;
  final DateTime closedAt;
  final String? tableLabel;
  final int pax;

  /// `dineIn` | `takeaway`, frozen at snapshot (ADR-0026).
  final String kind;

  /// Money actually collected on this bill (ADR-0039).
  final int settledTotal;
  final int discountAmount;

  /// Non-zero ⇒ a walkout close. Rendered as such, never as a small spend.
  final int lossAmount;

  const MemberVisitRow({
    required this.id,
    required this.closedAt,
    required this.tableLabel,
    required this.pax,
    required this.kind,
    required this.settledTotal,
    required this.discountAmount,
    required this.lossAmount,
  });
}

/// A member's settled bills, newest first. Paged by **growing limit** — the
/// cashier-history pattern (ADR-0079): no cursor, no offset, the client asks
/// for more of the same list.
Future<List<MemberVisitRow>> memberVisits(
  AppDatabase db,
  String memberId, {
  int limit = 30,
}) async {
  final s = db.tableSessions;
  final rows =
      await (db.select(s)
            ..where((x) => x.memberId.equals(memberId))
            ..orderBy([(x) => OrderingTerm.desc(x.closedAt)])
            ..limit(limit))
          .get();
  return [
    for (final r in rows)
      MemberVisitRow(
        id: r.id,
        closedAt: r.closedAt,
        tableLabel: r.tableLabel,
        pax: r.pax,
        kind: r.kind,
        settledTotal: r.settledTotal,
        discountAmount: r.discountAmount,
        lossAmount: r.lossAmount,
      ),
  ];
}

Map<String, dynamic> memberVisitJson(MemberVisitRow v) => {
  'id': v.id,
  'closedAt': v.closedAt.toIso8601String(),
  'tableLabel': v.tableLabel,
  'pax': v.pax,
  'kind': v.kind,
  'settledTotal': v.settledTotal,
  'discountAmount': v.discountAmount,
  'lossAmount': v.lossAmount,
};

Map<String, dynamic> memberPointEntryJson(MemberPointEntry e) => {
  'id': e.id,
  'kind': e.kind.name,
  'delta': e.delta,
  'visitId': e.visitId,
  'baseAmount': e.baseAmount,
  'note': e.note,
  'actorUserId': e.actorUserId,
  'actorName': e.actorName,
  'at': e.at.toIso8601String(),
};

/// How many members the ranked list carries. The report is one payload, so an
/// uncapped list grows with the venue's success until the snapshot is the
/// problem; 100 is already past where anyone reads, and the remainder ships as
/// a count.
const _topRankLimit = 100;

/// The Keanggotaan block of the venue report.
///
/// Answers the only question a membership program has to answer to justify
/// itself: **do the people who joined spend more, and come back?** Everything
/// here is read off settled history, so a member merged or anonymised since
/// still counts toward the trade they did (ADR-0092).
///
/// [from] already carries the caller's `businessDayStartHour` rollover, so a
/// 02:00 bill lands with the night it belongs to — same contract
/// `cashReportSection` keeps.
Future<Map<String, dynamic>> memberReportSection(
  AppDatabase db, {
  required DateTime from,
  required DateTime to,
}) async {
  final cfg = await memberConfig(db);
  final s = db.tableSessions;
  final sessions =
      await (db.select(s)..where(
            (x) =>
                x.closedAt.isBiggerOrEqualValue(from) &
                x.closedAt.isSmallerThanValue(to),
          ))
          .get();

  // Receipts of the sessions in this window that name a [[Pemilik struk]]
  // (ADR-0118), grouped by session. Read unconditionally, not behind
  // [MemberConfig.splitEnabled]: a window that was attributed keeps reporting
  // as attributed after the mode is unticked, and at a venue that never held
  // it this map is empty and everything below collapses to the per-bill
  // reading it had before.
  final attributedBySession = <String, List<TableSessionReceipt>>{};
  if (sessions.isNotEmpty) {
    final ids = sessions.map((x) => x.id).toList();
    final recs = await (db.select(db.tableSessionReceipts)
          ..where((x) => x.sessionId.isIn(ids) & x.memberId.isNotNull()))
        .get();
    for (final rec in recs) {
      (attributedBySession[rec.sessionId] ??= <TableSessionReceipt>[]).add(rec);
    }
  }

  var memberBills = 0;
  var memberNet = 0;
  var guestBills = 0;
  var guestNet = 0;
  final spendBy = <String, int>{};
  final visitsBy = <String, int>{};
  // How many bills in this window were split between two or more members —
  // the one figure that says "these numbers are two shapes" when a report
  // spans the moment the mode was switched on.
  var splitBills = 0;
  for (final row in sessions) {
    final owner = row.memberId;

    // **Bills stay bills**, counted on the owner (ADR-0118 §6). A
    // part-member, part-guest bill is one bill by whoever held it, so every
    // saved comparison still means what it meant; the finer truth lives in
    // the per-member rollup below.
    if (owner == null) {
      guestBills++;
      guestNet += row.settledTotal;
    } else {
      memberBills++;
      memberNet += row.settledTotal;
    }

    // Spend divides the way the points base does: a receipt naming someone
    // other than the owner is theirs, and the owner takes everything left —
    // their own receipts, unnamed ones, and money on no receipt at all. The
    // parts therefore always add back to `settledTotal`.
    final touched = <String>{};
    var claimedByOthers = 0;
    for (final rec
        in attributedBySession[row.id] ?? const <TableSessionReceipt>[]) {
      final id = rec.memberId!;
      if (id == owner) continue;
      spendBy[id] = (spendBy[id] ?? 0) + rec.total;
      claimedByOthers += rec.total;
      touched.add(id);
    }
    if (touched.length + (owner == null ? 0 : 1) > 1) splitBills++;
    if (owner != null) {
      // Clamped because an amount receipt's claim is frozen at minting
      // (ADR-0068) and a later void can leave the shares claiming more than
      // the bill settled for — the owner's share floors at zero rather than
      // going negative and dragging the ranked list with it.
      final ownerSpend = (row.settledTotal - claimedByOthers)
          .clamp(0, 1 << 31)
          .toInt();
      spendBy[owner] = (spendBy[owner] ?? 0) + ownerSpend;
      touched.add(owner);
    }
    // A visit each, not a share each: the ranked list's "kunjungan" column
    // counts bills a member was on, and three friends at one table ate out
    // once apiece.
    for (final id in touched) {
      visitsBy[id] = (visitsBy[id] ?? 0) + 1;
    }
  }

  // Points moved *in this window*, split the way the ledger splits them: what
  // the venue promised (earn) against what it actually gave back (redeem, at
  // the venue's own rate). A reversal nets itself out of whichever it undid.
  final p = db.memberPoints;
  final ledger =
      await (db.select(p)..where(
            (x) =>
                x.at.isBiggerOrEqualValue(from) & x.at.isSmallerThanValue(to),
          ))
          .get();
  var earned = 0;
  var redeemed = 0;
  var adjusted = 0;
  // Per-member earn, for the ranked list's points column. Keyed on the ledger's
  // own `memberId` — a points row cannot be traced to one session (the snapshot
  // mints a fresh id and the visit it names is deleted), so this is the finest
  // grain the schema supports.
  final earnedBy = <String, int>{};
  for (final row in ledger) {
    switch (memberPointKindFromName(row.kind)) {
      case MemberPointKind.earn:
        earned += row.delta;
        earnedBy[row.memberId] = (earnedBy[row.memberId] ?? 0) + row.delta;
      case MemberPointKind.redeem:
        redeemed += -row.delta;
      case MemberPointKind.adjust:
        adjusted += row.delta;
      case MemberPointKind.reversal:
        // Undoes an earn (negative) or a redemption (positive), so it is
        // subtracted from whichever side it belongs to rather than reported.
        if (row.delta < 0) {
          earned += row.delta;
          earnedBy[row.memberId] = (earnedBy[row.memberId] ?? 0) + row.delta;
        } else {
          redeemed -= row.delta;
        }
      case null:
        break;
    }
  }

  // The whole outstanding liability, not just this window's — points never
  // expire (ADR-0095), so what the venue owes is a running total or nothing.
  final sum = p.delta.sum();
  final owedRow = await (db.selectOnly(p)..addColumns([sum])).getSingleOrNull();
  final owedPoints = owedRow?.read(sum) ?? 0;

  final enrolled =
      await (db.select(db.members)..where(
            (m) =>
                m.joinedAt.isBiggerOrEqualValue(from) &
                m.joinedAt.isSmallerThanValue(to),
          ))
          .get();

  final top = spendBy.keys.toList()
    ..sort((a, b) => (spendBy[b] ?? 0).compareTo(spendBy[a] ?? 0));
  final topRows = <Map<String, dynamic>>[];
  for (final id in top.take(_topRankLimit)) {
    final name = await _nameOf(db, id);
    topRows.add({
      'memberId': id,
      // Null when the member has since been deleted — the trade stands, the
      // person does not (ADR-0092). The client renders its own placeholder.
      'name': name,
      'visits': visitsBy[id] ?? 0,
      'spend': spendBy[id] ?? 0,
      'points': earnedBy[id] ?? 0,
    });
  }

  return {
    'enabled': cfg.enabled,
    // The points program runs independently of membership itself, so the client
    // hides the points column rather than drawing a column of structural zeros.
    'pointsEnabled': cfg.pointsEnabled,
    'enrolled': enrolled.length,
    'activeMembers': spendBy.length,
    'memberBills': memberBills,
    'memberNet': memberNet,
    // Bills in this window that carried more than one member (ADR-0118). Zero
    // at a venue without the mode, and the marker that lets the section say a
    // window spanning the switch is showing two shapes rather than one.
    'splitBills': splitBills,
    'splitEnabled': cfg.splitEnabled,
    'guestBills': guestBills,
    'guestNet': guestNet,
    'avgMemberBill': memberBills == 0 ? 0 : memberNet ~/ memberBills,
    'avgGuestBill': guestBills == 0 ? 0 : guestNet ~/ guestBills,
    'pointsEarned': earned,
    'pointsRedeemed': redeemed,
    'pointsAdjusted': adjusted,
    'pointsOutstanding': owedPoints,
    // What the outstanding points would cost the venue if every one of them
    // were spent tomorrow, at today's rate. The rate can move; the liability
    // is only ever an estimate, which is why it is named one.
    'liabilityEstimate': owedPoints * cfg.pointValue,
    'top': topRows,
    // Members who traded in the window but fell off the end of the list. Sent
    // as a count so the client can say "+380 lainnya" rather than implying the
    // hundredth name is the last one.
    'topTruncated': spendBy.length - topRows.length,
  };
}
