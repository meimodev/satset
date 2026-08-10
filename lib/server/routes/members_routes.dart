import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/auth.dart';
// Hidden for the reason `members.dart` gives: Drift's row class shares the
// domain model's name and this file means the domain one.
import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/members.dart';
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
Router membersRoutes(AppDatabase db, WsHub hub, [ServerAuth? auth]) {
  final r = Router();

  Future<(String?, Set<String>)?> actor(Request req) async {
    if (auth == null) {
      return (null, Capability.values.map((c) => c.name).toSet());
    }
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

  Response err(int status, String code, {int? points, String? memberId}) =>
      Response(
        status,
        body: jsonEncode({
          'code': code,
          'points': ?points,
          'memberId': ?memberId,
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
    final list = await listMembers(
      db,
      query: q['q'] ?? '',
      birthdayMonth: (month != null && month >= 1 && month <= 12)
          ? month
          : null,
      limit: limit.clamp(1, 500),
    );
    return json([for (final m in list) memberJson(m)]);
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

DateTime? _date(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
