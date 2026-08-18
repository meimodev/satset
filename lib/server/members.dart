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
    enabled: s?.membersEnabled ?? false,
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
  final rows =
      await (db.select(t).join([innerJoin(s, s.id.equalsExp(t.sessionId))])
            ..where(
              s.memberId.equals(memberId) & t.itemId.equals(c.punchItemId!),
            ))
          .get();
  var bought = 0;
  var given = 0;
  for (final r in rows) {
    final tk = r.readTable(t);
    final voided = tk.status == 'voided';
    // A comp is a void carrying reason code `comp` (ADR-0006) — so the reward
    // is found the same way the comp tile finds it, not by a second flag.
    if (voided && tk.voidReasonCode == 'comp') {
      given += tk.qty;
    } else if (!voided) {
      bought += tk.qty;
    }
  }
  return PunchStatus(bought: bought, given: given, target: c.punchTarget);
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
  // ...but a live [[Piutang]] balance IS money, and deleting it would erase a
  // receivable with no record of the amount (ADR-0098). Refuse, so the owner
  // has to say which it was — collected, or given up on. Both are routes.
  final owed = await memberDebt(db, id);
  if (owed != 0) throw const MemberException('has_outstanding_debt');
  await (db.delete(db.memberPoints)..where((p) => p.memberId.equals(id))).go();
  // The debt ledger stays. The balance is zero, so nothing is owed to anyone —
  // but a `charge` or a `writeOff` is money that moved, and dropping the rows
  // would rewrite last month's bad-debt total from a delete button. Same rule
  // as the bills: the person goes, the trade stays counted.
  await (db.delete(db.members)..where((m) => m.id.equals(id))).go();
  await writeAudit(
    db,
    type: AuditType.memberChanged,
    kind: AuditKind.memberDeleted,
    params: {'name': row.name},
    actorUserId: actorUserId,
    hub: hub,
  );
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
  await (db.update(db.memberPoints)..where((p) => p.memberId.equals(fromId)))
      .write(MemberPointsCompanion(memberId: Value(toId)));
  // The [[Piutang]] ledger repoints for the same reason the points one does:
  // the balance is `SUM(delta)`, so a fold needs nothing reconciled (ADR-0098).
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
    final already = await _earnRowFor(db, visitId);
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
  final earn = await _earnRowFor(db, visitId);
  if (earn == null) return;
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
  String? actorUserId,
  WsHub? hub,
}) async {
  final redeem = await _redeemRowFor(db, visitId);
  if (redeem == null) return;
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

/// The live earn on a visit — an `earn` row with no `reversal` against it.
///
/// A visit can hold a reversed redemption too, so reversals are paired by
/// **sign**: undoing an earn takes points away (negative), undoing a redemption
/// gives them back (positive). Counting them together would let a cancelled
/// redemption make an earn look already reversed, and the bill would pay out
/// twice on its next close.
Future<MemberPoint?> _earnRowFor(AppDatabase db, String visitId) async {
  final rows = await (db.select(
    db.memberPoints,
  )..where((p) => p.visitId.equals(visitId))).get();
  final earns = rows.where((r) => r.kind == MemberPointKind.earn.name).length;
  final reversals = rows
      .where((r) => r.kind == MemberPointKind.reversal.name && r.delta < 0)
      .length;
  if (earns <= reversals) return null;
  return rows.lastWhere((r) => r.kind == MemberPointKind.earn.name);
}

/// The live redemption on a visit — a `redeem` row with no reversal against it.
Future<MemberPoint?> _redeemRowFor(AppDatabase db, String visitId) async {
  final rows = await (db.select(
    db.memberPoints,
  )..where((p) => p.visitId.equals(visitId))).get();
  final spends = rows
      .where((r) => r.kind == MemberPointKind.redeem.name)
      .length;
  final undone = rows
      .where((r) => r.kind == MemberPointKind.reversal.name && r.delta > 0)
      .length;
  if (spends <= undone) return null;
  return rows.lastWhere((r) => r.kind == MemberPointKind.redeem.name);
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

  var memberBills = 0;
  var memberNet = 0;
  var guestBills = 0;
  var guestNet = 0;
  final spendBy = <String, int>{};
  final visitsBy = <String, int>{};
  for (final row in sessions) {
    final id = row.memberId;
    if (id == null) {
      guestBills++;
      guestNet += row.settledTotal;
      continue;
    }
    memberBills++;
    memberNet += row.settledTotal;
    spendBy[id] = (spendBy[id] ?? 0) + row.settledTotal;
    visitsBy[id] = (visitsBy[id] ?? 0) + 1;
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
