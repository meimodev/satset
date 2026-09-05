import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/server/audit_log.dart';
import 'package:satset/server/auth.dart';
// Hidden for the reason `members.dart` gives: Drift's row class shares the
// domain model's name and this file means the domain one.
import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/debts.dart';
import 'package:satset/server/member_import.dart';
import 'package:satset/server/member_sync.dart';
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
    int? row,
  }) => Response(
    status,
    body: jsonEncode({
      'code': code,
      'points': ?points,
      'memberId': ?memberId,
      'balance': ?balance,
      'limit': ?limit,
      'row': ?row,
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

  Future<List<int>> csvBytes(Request req) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in req.read()) {
      bytes.add(chunk);
      if (bytes.length > memberImportMaxBytes) {
        throw const MemberImportException('file_too_large');
      }
    }
    return bytes.takeBytes();
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

  /// The member report (§Laporan pelanggan): the overview numbers, plus every
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

  // ----------------------------------------------------------------- exports
  //
  // An export is a **fresh, uncapped fetch**, never a copy of what the screen
  // is holding (ADR-0137). Every read above is capped — the directory at 500,
  // the ranked list at 500, a member's bills at 200 — so a file rendered from
  // loaded state stops wherever the reader happened to stop and calls itself
  // complete. These three answer the same questions with the cap lifted to
  // [kMemberExportMax], and **refuse** rather than truncate above it.
  //
  // Registered here, beside the reads they mirror, and — for `/members/export`
  // — necessarily **before** `/members/<id>`, which would otherwise match it as
  // a member whose id is the word "export".
  //
  // They gate exactly what the screen behind them gates. The §Export rule that
  // puts every other export behind `viewReports` exists because the order board
  // is open to `takeOrder`, so exporting it widened what that role could see;
  // here it widens nothing, and demanding `viewReports` on top would hand a
  // directory keeper a button that only ever refuses.

  /// Everything past the ceiling, in the shape the export sheet expects.
  Response tooLarge() =>
      err(413, 'export_too_large', limit: kMemberExportMax);

  /// The whole directory, honouring the screen's active filters.
  ///
  /// The filters ride along on purpose: "export the members who have not come
  /// back in ninety days" is the reason an owner exports a roster at all, and a
  /// file that can only ever be everybody cannot answer it.
  ///
  /// `manageMembers` alone, unlike `GET /members` — the till and the booking
  /// form read that route to find one guest mid-service, which is a different
  /// act from taking the customer list off the device. Which also means no
  /// masked caller reaches this: the mask is for a `takeOrder`-only device
  /// (ADR-0129), and one of those is refused here before masking is a question.
  r.get('/members/export', (Request req) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.manageMembers.name)) {
      return forbidden(Capability.manageMembers);
    }
    final q = req.url.queryParameters;
    final month = int.tryParse(q['birthdayMonth'] ?? '');
    final lapsed = int.tryParse(q['lapsedDays'] ?? '');
    final list = await listMembers(
      db,
      query: q['q'] ?? '',
      birthdayMonth: (month != null && month >= 1 && month <= 12)
          ? month
          : null,
      lapsedDays: (lapsed != null && lapsed > 0) ? lapsed : null,
      // One past the ceiling, so "exactly at the ceiling" and "over it" are
      // distinguishable without a second count query.
      limit: kMemberExportMax + 1,
    );
    if (list.length > kMemberExportMax) return tooLarge();

    // The one export that audits itself. The two below do not: they are
    // aggregates over a window their reader already had on screen, while this
    // is the roster — names, numbers, birthdays, addresses — leaving the device
    // through the Android share sheet.
    await writeAudit(
      db,
      type: AuditType.memberChanged,
      kind: AuditKind.memberDirectoryExported,
      params: {'rows': '${list.length}'},
      actorUserId: a.$1,
      hub: hub,
    );
    return json([for (final m in list) memberJson(m)]);
  });

  /// The ranked list, uncapped. Same window rules as `/members/report`,
  /// including the open-ended `Semua` arm — which on a venue with years of
  /// trade is precisely what trips the ceiling, and the refusal says so.
  ///
  /// `membersTruncated` is stripped: on an uncapped payload it is always zero,
  /// and a field that can only ever say "nothing was dropped" is one a future
  /// reader will trust to mean something.
  r.get('/members/report/export', (Request req) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.viewReports.name) &&
        !a.$2.contains(Capability.manageMembers.name)) {
      return forbidden(Capability.viewReports);
    }
    final (from, to) = await windowOf(req);
    final body = await memberTradeReport(
      db,
      from: from,
      to: to,
      rankLimit: kMemberExportMax + 1,
    );
    if ((body['members'] as List).length > kMemberExportMax) {
      return tooLarge();
    }
    return json({...body}..remove('membersTruncated'));
  });

  /// One member's history, uncapped. Answers for a member with no directory row
  /// for the reason `/members/<id>/report` does — the bills are the venue's
  /// record of what happened, not the person's data (ADR-0092).
  r.get('/members/<id>/report/export', (Request req, String id) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.viewReports.name) &&
        !a.$2.contains(Capability.manageMembers.name)) {
      return forbidden(Capability.viewReports);
    }
    final (from, to) = await windowOf(req);
    final body = await memberHistory(
      db,
      id,
      from: from,
      to: to,
      billLimit: kMemberExportMax + 1,
    );
    // `billsTotal` is the true count before any cap, so it is the honest test
    // — the bill list itself has already been trimmed by the time we see it.
    if ((body['billsTotal'] as int) > kMemberExportMax) return tooLarge();
    final member = await getMember(db, id);
    return json({
      ...body,
      'member': member == null ? null : memberJson(member),
    });
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

  /// The [[Salinan pelanggan]] feed — everything that changed since the
  /// cursor the device was last given (ADR-0129).
  ///
  /// **Registered before `/members/<id>`**, like every other literal here.
  ///
  /// Openable by the three who may already read a member on a device that
  /// takes orders or settles; `viewReports` is deliberately **not** among them
  /// — a reporting screen reads live and has no reason to keep a copy of the
  /// venue's customer list on disk.
  ///
  /// The payload is **masked** for a caller who can only take orders: the
  /// number leaves as a salted hash plus its last four digits, which is the
  /// same split `/members/lookup` already makes, applied to a copy that
  /// persists. A till gets the whole record, and that is the accepted risk the
  /// ADR names rather than a hole to close here.
  r.get('/members/sync', (Request req) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final cfg = await memberConfig(db);
    // The owner switched mirroring off: 404, exactly as membership off does,
    // so a client cannot tell "not for this venue" from "not on this server".
    if (!cfg.mirrorEnabled) return err(404, 'member_mirror_disabled');
    final a = await actor(req);
    if (a == null) return Response(401);
    final caps = a.$2;
    final settles =
        caps.contains(Capability.settleBill.name) ||
        caps.contains(Capability.manageMembers.name);
    if (!settles && !caps.contains(Capability.takeOrder.name)) {
      return forbidden(Capability.takeOrder);
    }
    final q = req.url.queryParameters;
    final limit = int.tryParse(q['limit'] ?? '') ?? kMemberSyncPage;
    final page = await memberSyncPage(
      db,
      cursor: q['since'],
      limit: limit.clamp(1, 1000),
    );
    // Minted on demand, and only when somebody is actually going to mask with
    // it — a venue whose only paired devices are tills never grows one.
    final salt = settles ? null : await memberMirrorSalt(db);
    return json(memberSyncJson(page, salt: salt, masked: !settles));
  });

  r.get('/members/lookup', (Request req) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.settleBill.name) &&
        !a.$2.contains(Capability.takeOrder.name)) {
      return forbidden(Capability.takeOrder);
    }
    String masked(String phone) {
      final tail = phone.length <= 4
          ? phone
          : phone.substring(phone.length - 4);
      return '•••• $tail';
    }

    // Resolving a known set of ids rather than searching — the floor naming
    // the [[Pemilik tiket]] on a line it has already sent. Deliberately not a
    // second route: same gate, same minimal identity, only the key differs. An
    // id with no row is a member since deleted (ADR-0092) and is simply absent
    // from the answer, which is what the caller renders the placeholder from.
    final ids = (req.url.queryParameters['ids'] ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    if (ids.isNotEmpty) {
      final named = await memberNamesOf(db, ids.take(200).toList());
      return json([
        for (final e in named.entries)
          {'id': e.key, 'name': e.value.name, 'phone': masked(e.value.phone)},
      ]);
    }

    final list = await listMembers(
      db,
      query: req.url.queryParameters['q'] ?? '',
      limit: 50,
    );

    return json([
      for (final member in list)
        {'id': member.id, 'name': member.name, 'phone': masked(member.phone)},
    ]);
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

  Future<Response> importResponse(Request req, {required bool commit}) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.manageMembers.name)) {
      return forbidden(Capability.manageMembers);
    }
    try {
      final bytes = await csvBytes(req);
      final preview = commit
          ? await importMembers(db, bytes, actorUserId: a.$1!, hub: hub)
          : await previewMemberImport(db, bytes);
      return json(preview.toJson());
    } on MemberImportException catch (e) {
      return err(400, e.code, row: e.row);
    }
  }

  r.post(
    '/members/import/preview',
    (Request req) => importResponse(req, commit: false),
  );
  r.post('/members/import', (Request req) => importResponse(req, commit: true));

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
    // An offline capture identifies itself by carrying the id it minted and
    // the moment it was taken (ADR-0129). That, and not the caller, is what
    // switches enrolment from "refuse a duplicate number so the till can offer
    // the standing record" to "fold, because there is nobody at the counter
    // left to ask".
    final capturedId = _text(body['id']);
    final capturedAt = _date(body['capturedAt']);
    try {
      if (capturedId != null && capturedAt != null) {
        final out = await enrolCapturedMember(
          db,
          id: capturedId,
          name: (body['name'] as String?) ?? '',
          phone: (body['phone'] as String?) ?? '',
          note: _text(body['note']),
          birthday: _date(body['birthday']),
          address: _address(body['address']) ?? const MemberAddress(),
          actorUserId: a.$1,
          hub: hub,
          capturedAt: capturedAt,
        );
        return json({
          ...memberJson(out.member),
          // The device rewrites its mirror off this: everything it queued
          // behind the enrolment names the id it minted, which may have lost.
          'folded': out.folded,
        });
      }
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
