import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/server/auth.dart';
// Hidden for the reason `members.dart` gives: Drift's row class shares the
// domain model's name and this file means the domain one.
import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/debts.dart';
import 'package:satset/server/members.dart';
import 'package:satset/server/routes/reports_routes.dart' show reportWindow;
import 'package:satset/server/ws_hub.dart';

/// The [[Pelanggan (member)]] directory.
///
/// Capability split, per ADR-0092: **looking up and enrolling** ride
/// `settleBill`, because they happen at the till in the middle of taking money;
/// **editing, merging, deleting and adjusting points** need `manageMembers`,
/// the directory-keeper's authority. Both are enforced here and not only in the
/// UI, because a capability checked client-side is a suggestion.
///
/// Attaching a member to a bill and redeeming points live in
/// `settlement_routes.dart` instead — they are settlement acts and belong with
/// the bill they change (ADR-0093).
Router membersRoutes(AppDatabase db, WsHub hub, ServerAuth auth) {
  final r = Router();

  Future<(String?, Set<String>)?> actor(Request req) async {
    final token = req.headers['authorization']?.replaceFirst(
      RegExp(r'^[Bb]earer\s+'),
      '',
    );
    final user = await auth.resolveBearer(token);
    if (user == null) return null;
    final role = await (db.select(
      db.roles,
    )..where((x) => x.id.equals(user.roleId))).getSingleOrNull();
    final caps = role == null
        ? <String>{}
        : (jsonDecode(role.capabilitiesJson) as List).cast<String>().toSet();
    return (user.id, caps);
  }

  Response json(Object body) => Response.ok(
    jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );

  Response err(
    int status,
    String code, {
    int? points,
    String? memberId,
    int? balance,
    int? limit,
  }) => Response(
    status,
    body: jsonEncode({
      'code': code,
      'points': ?points,
      'memberId': ?memberId,
      'balance': ?balance,
      'limit': ?limit,
    }),
    headers: {'content-type': 'application/json'},
  );

  Response forbidden(Capability c) => Response(
    403,
    body: jsonEncode({'code': 'forbidden', 'capability': c.name}),
    headers: {'content-type': 'application/json'},
  );

  /// Membership off ⇒ every route here answers 404, not 403: the feature does
  /// not exist for this venue rather than being withheld from this reader.
  Future<Response?> enabledGuard() async {
    final cfg = await memberConfig(db);
    return cfg.enabled ? null : err(404, 'members_disabled');
  }

  /// [[Piutang]] off ⇒ 404 as well, and for the same reason: a venue that runs
  /// no tabs should be indistinguishable from a server that never had them.
  Future<Response?> debtGuard() async {
    final off = await enabledGuard();
    if (off != null) return off;
    final cfg = await debtConfig(db);
    return cfg.enabled ? null : err(404, 'debt_disabled');
  }

  /// Reading a balance is open to whoever settles, keeps the directory, or
  /// reports on it — the same three that already read a member.
  bool canRead(Set<String> caps) =>
      caps.contains(Capability.settleBill.name) ||
      caps.contains(Capability.manageMembers.name) ||
      caps.contains(Capability.viewReports.name);

  Response debtErr(DebtException e) => err(
    e.code == 'not_found' ? 404 : 409,
    e.code,
    balance: e.balance,
    limit: e.limit,
  );

  // ---------------------------------------------------------------- piutang
  //
  // **Registered before `/members/<id>`**: shelf_router matches in declaration
  // order, so a literal segment placed after the parameterised one is read as a
  // member whose id happens to be "debtors".

  /// Venue-wide outstanding [[Piutang]], and **the one route here that neither
  /// guard covers** (ADR-0107 §7).
  ///
  /// It exists so the fleet console can refuse to remove the Keanggotaan
  /// [[Modul]] from a venue that is still owed money — which means it has to
  /// answer precisely when the ordinary guards would 404: after an owner has
  /// switched membership off, or with the debt program frozen, balances stand
  /// either way. A gate here would make "nothing owed" and "cannot ask"
  /// the same answer, and the refusal reads that answer as permission.
  ///
  /// Read-only, a single integer, and still behind the ordinary bearer.
  r.get('/members/debt-total', (Request req) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!canRead(a.$2)) return forbidden(Capability.manageMembers);
    return json({'openDebt': await totalDebt(db)});
  });

  /// Everyone who owes something, largest first, with FIFO-derived ageing.
  r.get('/members/debtors', (Request req) async {
    final off = await debtGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!canRead(a.$2)) return forbidden(Capability.manageMembers);
    final list = await listDebtors(db);
    return json([for (final d in list) d.toJson()]);
  });

  /// One member's standing: balance, resolved limit, and a page of the ledger.
  r.get('/members/<id>/debt', (Request req, String id) async {
    final off = await debtGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!canRead(a.$2)) return forbidden(Capability.manageMembers);
    if (await getMember(db, id) == null) return err(404, 'not_found');
    final limit = int.tryParse(req.url.queryParameters['limit'] ?? '') ?? 50;
    return json(
      debtJson(await debtFor(db, id, ledgerLimit: limit.clamp(1, 500))),
    );
  });

  /// Proof photo for one collection. Its own route for the reason a payment's
  /// is: the blob never rides the ledger page.
  r.get('/members/debt/<entryId>/photo', (Request req, String entryId) async {
    final off = await debtGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!canRead(a.$2)) return forbidden(Capability.manageMembers);
    final row = await (db.select(
      db.memberDebts,
    )..where((x) => x.id.equals(entryId))).getSingleOrNull();
    if (row?.photo == null) return Response.notFound('no photo');
    return Response.ok(
      row!.photo,
      headers: {'content-type': 'image/jpeg', 'cache-control': 'no-cache'},
    );
  });

  /// Collect. A till act — `settleBill`, same as taking any other money.
  r.post('/members/<id>/debt/payments', (Request req, String id) async {
    final off = await debtGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.settleBill.name)) {
      return forbidden(Capability.settleBill);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      await payDebt(
        db,
        memberId: id,
        amount: (body['amount'] as num?)?.toInt() ?? 0,
        method: (body['method'] as String?) ?? 'tunai',
        photo: _photo(body['photoBase64']),
        note: _text(body['note']),
        actorUserId: a.$1,
        hub: hub,
      );
      return json(debtJson(await debtFor(db, id)));
    } on DebtException catch (e) {
      return debtErr(e);
    }
  });

  /// Give up collecting. `refund` — the capability that already means a manager
  /// is accepting money is gone.
  r.post('/members/<id>/debt/write-off', (Request req, String id) async {
    final off = await debtGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.refund.name)) {
      return forbidden(Capability.refund);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      await writeOffDebt(
        db,
        memberId: id,
        amount: (body['amount'] as num?)?.toInt() ?? 0,
        note: _text(body['note']) ?? '',
        actorUserId: a.$1,
        hub: hub,
      );
      return json(debtJson(await debtFor(db, id)));
    } on DebtException catch (e) {
      return debtErr(e);
    }
  });

  /// A hand correction, signed. Kept apart from write-off so the bad-debt
  /// figure stays "money we lost" rather than "money we lost, plus typos".
  r.post('/members/<id>/debt/adjust', (Request req, String id) async {
    final off = await debtGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.refund.name)) {
      return forbidden(Capability.refund);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      await adjustDebt(
        db,
        memberId: id,
        delta: (body['delta'] as num?)?.toInt() ?? 0,
        note: _text(body['note']) ?? '',
        actorUserId: a.$1,
        hub: hub,
      );
      return json(debtJson(await debtFor(db, id)));
    } on DebtException catch (e) {
      return debtErr(e);
    }
  });

  /// The window a member-report request asks for.
  ///
  /// Every preset resolves through [reportWindow], so this report and
  /// `/reports` agree about where a business day ends. `all` is resolved
  /// **here and not there** on purpose: an unbounded window is safe for this
  /// payload — it is aggregated to a capped list of members plus a rollup, and
  /// does not grow with the span — where the accounting report is per-bill and
  /// genuinely does. The resolver they share should not quietly hand one
  /// report the other's ceiling.
  Future<(DateTime, DateTime)> windowOf(Request req) async {
    final qp = req.url.queryParameters;
    final now = SatClock.now();
    final settings = await (db.select(
      db.venueSettings,
    )..where((x) => x.id.equals('default'))).getSingleOrNull();
    final hour = settings?.businessDayStartHour ?? 4;
    if (qp['range'] == 'all') {
      // Ends where today does, so a bill taken an hour ago is in "Semua"
      // rather than a day away from it. The client labels the open start with
      // `earliestClosedAt`, the venue's real first trading day.
      final (_, to) = reportWindow('today', now, hour);
      return (DateTime.utc(2000), to);
    }
    return reportWindow(
      qp['range'] ?? 'today',
      now,
      hour,
      fromStr: qp['from'],
      toStr: qp['to'],
    );
  }

  /// The member report (§Laporan anggota): the overview numbers, plus every
  /// member who traded in the window ranked by spend.
  ///
  /// Registered **before** `/members/<id>`, which it would otherwise match as
  /// a member whose id is the word "report".
  ///
  /// Opens to `viewReports` **or** `manageMembers` — the list shape `/kas` and
  /// `/opname` use, because the person who enrols the guests and the person
  /// who reads their spending back are rarely the same one.
  r.get('/members/report', (Request req) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.viewReports.name) &&
        !a.$2.contains(Capability.manageMembers.name)) {
      return forbidden(Capability.viewReports);
    }
    final (from, to) = await windowOf(req);
    return json(await memberTradeReport(db, from: from, to: to));
  });

  /// One member's history: their bills in the window, and every product they
  /// bought.
  ///
  /// Answers for a member who no longer has a directory row — a delete
  /// anonymises and leaves the trade behind (ADR-0092), and those bills are the
  /// venue's record of what happened rather than the person's data. That is the
  /// deliberate difference from `GET /members/<id>`, which 404s.
  r.get('/members/<id>/report', (Request req, String id) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.viewReports.name) &&
        !a.$2.contains(Capability.manageMembers.name)) {
      return forbidden(Capability.viewReports);
    }
    final (from, to) = await windowOf(req);
    final limit = int.tryParse(req.url.queryParameters['limit'] ?? '');
    final body = await memberHistory(
      db,
      id,
      from: from,
      to: to,
      billLimit: limit ?? 200,
    );
    // The directory row when there still is one, so the drill can show
    // lifetime figures beside the window's. Absent for a deleted member, which
    // the client renders as the placeholder rather than as an error.
    final member = await getMember(db, id);
    return json({
      ...body,
      'member': member == null ? null : memberJson(member),
    });
  });

  // The directory, and the till's prefix search. Readable by anyone who can
  // settle, keep the directory, or report on it.
  r.get('/members', (Request req) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    // `takeOrder` reads but never writes: the booking form searches here to
    // avoid enrolling a guest who is already in the directory, which is the
    // whole point of the picker. Enrolment stays at the till and the admin
    // sheet — creating a customer record is a data-quality act.
    if (!a.$2.contains(Capability.settleBill.name) &&
        !a.$2.contains(Capability.manageMembers.name) &&
        !a.$2.contains(Capability.viewReports.name) &&
        !a.$2.contains(Capability.takeOrder.name)) {
      return forbidden(Capability.manageMembers);
    }
    final q = req.url.queryParameters;
    final limit = int.tryParse(q['limit'] ?? '') ?? 50;
    final month = int.tryParse(q['birthdayMonth'] ?? '');
    final lapsed = int.tryParse(q['lapsedDays'] ?? '');
    final list = await listMembers(
      db,
      query: q['q'] ?? '',
      birthdayMonth: (month != null && month >= 1 && month <= 12)
          ? month
          : null,
      lapsedDays: (lapsed != null && lapsed > 0) ? lapsed : null,
      limit: limit.clamp(1, 500),
    );
    return json([for (final m in list) memberJson(m)]);
  });

  /// A member's settled bills, newest first. The keeper's surface only —
  /// reading one guest's spending history back is an admin act, not something
  /// the till does across the counter mid-settlement.
  r.get('/members/<id>/visits', (Request req, String id) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.manageMembers.name)) {
      return forbidden(Capability.manageMembers);
    }
    final limit = int.tryParse(req.url.queryParameters['limit'] ?? '') ?? 30;
    final rows = await memberVisits(db, id, limit: limit.clamp(1, 500));
    return json([for (final v in rows) memberVisitJson(v)]);
  });

  /// One member with everything a detail screen needs — the record, the derived
  /// figures, the punch card and a page of the ledger.
  r.get('/members/<id>', (Request req, String id) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.settleBill.name) &&
        !a.$2.contains(Capability.manageMembers.name) &&
        !a.$2.contains(Capability.viewReports.name)) {
      return forbidden(Capability.manageMembers);
    }
    final member = await getMember(db, id);
    if (member == null) return err(404, 'not_found');
    final punch = await punchStatus(db, id);
    final ledger = await memberLedger(db, id);
    return json({
      ...memberJson(member),
      'punch': {
        'bought': punch.bought,
        'given': punch.given,
        'target': punch.target,
        'progress': punch.progress,
        'rewardDue': punch.rewardDue,
      },
      'ledger': [for (final e in ledger) memberPointEntryJson(e)],
    });
  });

  /// Enrol. A cashier's act, mid-settlement — hence `settleBill` rather than
  /// `manageMembers`. A number that already exists comes back as `phone_taken`
  /// carrying the member who owns it, so the till offers to use them.
  r.post('/members', (Request req) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.settleBill.name) &&
        !a.$2.contains(Capability.manageMembers.name)) {
      return forbidden(Capability.settleBill);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      final member = await createMember(
        db,
        name: (body['name'] as String?) ?? '',
        phone: (body['phone'] as String?) ?? '',
        note: _text(body['note']),
        birthday: _date(body['birthday']),
        address: _address(body['address']) ?? const MemberAddress(),
        actorUserId: a.$1,
        hub: hub,
      );
      return json(memberJson(member));
    } on MemberException catch (e) {
      return err(400, e.code, memberId: e.memberId);
    }
  });

  r.patch('/members/<id>', (Request req, String id) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.manageMembers.name)) {
      return forbidden(Capability.manageMembers);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      final member = await updateMember(
        db,
        id: id,
        name: body['name'] as String?,
        phone: body['phone'] as String?,
        note: body.containsKey('note') ? (_text(body['note']) ?? '') : null,
        birthday: _date(body['birthday']),
        // An explicit null clears the date; an absent key leaves it alone.
        clearBirthday: body.containsKey('birthday') && body['birthday'] == null,
        debtLimit: (body['debtLimit'] as num?)?.toInt(),
        // Same distinction, and it matters more here: an explicit null puts
        // them back on the venue default, which is not the same as 0.
        clearDebtLimit:
            body.containsKey('debtLimit') && body['debtLimit'] == null,
        // Wholesale: absent leaves the address alone, present replaces all four
        // fields. An explicit null is an empty address, which is how the sheet
        // clears one.
        address: body.containsKey('address')
            ? (_address(body['address']) ?? const MemberAddress())
            : null,
        hub: hub,
      );
      return json(memberJson(member));
    } on MemberException catch (e) {
      return err(
        e.code == 'not_found' ? 404 : 400,
        e.code,
        memberId: e.memberId,
      );
    }
  });

  /// Delete **anonymises** — the person and their ledger go, the trade they did
  /// stays counted (ADR-0092).
  r.delete('/members/<id>', (Request req, String id) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.manageMembers.name)) {
      return forbidden(Capability.manageMembers);
    }
    try {
      await deleteMember(db, id: id, actorUserId: a.$1, hub: hub);
      return json({'ok': true});
    } on MemberException catch (e) {
      return err(e.code == 'not_found' ? 404 : 400, e.code);
    }
  });

  /// Fold this member into another. `<id>` is the one absorbed; `intoId` wins.
  r.post('/members/<id>/merge', (Request req, String id) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.manageMembers.name)) {
      return forbidden(Capability.manageMembers);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      final member = await mergeMembers(
        db,
        fromId: id,
        toId: (body['intoId'] as String?) ?? '',
        actorUserId: a.$1,
        hub: hub,
      );
      return json(memberJson(member));
    } on MemberException catch (e) {
      return err(e.code == 'not_found' ? 404 : 400, e.code);
    }
  });

  /// The only way points move without a bill. Mandatory reason, always audited.
  r.post('/members/<id>/points', (Request req, String id) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.manageMembers.name)) {
      return forbidden(Capability.manageMembers);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      final member = await adjustPoints(
        db,
        memberId: id,
        delta: (body['delta'] as num?)?.toInt() ?? 0,
        note: _text(body['note']) ?? '',
        actorUserId: a.$1,
        hub: hub,
      );
      return json(memberJson(member));
    } on MemberException catch (e) {
      return err(400, e.code, points: e.points);
    }
  });

  return r;
}

String? _text(Object? raw) {
  if (raw is! String) return null;
  final t = raw.trim();
  return t.isEmpty ? null : t;
}

Uint8List? _photo(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    return base64Decode(raw);
  } catch (_) {
    return null;
  }
}

DateTime? _date(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// The [[Alamat pelanggan]] off the wire. **No vocabulary check**: the picker
/// is the constraint, not this route. Validating a kecamatan against the
/// bundled list would mean a member enrolled today fails to save tomorrow
/// because their kelurahan was renamed upstream — punishing the record for the
/// list changing, when the stored value is a snapshot precisely so it cannot
/// be rewritten. `manageMembers` on a LAN is the fence that matters.
MemberAddress? _address(Object? raw) {
  if (raw is! Map) return null;
  return MemberAddress.fromJson(Map<String, dynamic>.from(raw));
}
