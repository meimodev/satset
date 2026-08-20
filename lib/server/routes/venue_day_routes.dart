import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/audit_log.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';

/// **Buka kedai / Tutup kedai** (ADR-0111) — the venue day.
///
/// Two routes and no table. The day is not an entity: opening and closing are
/// *things that happened*, so the record is a pair of [[Audit]] rows and there
/// is no state anywhere that can get stuck half-open. Everything else the
/// ritual touches — the float, the count, the numbers — already has a writer,
/// and this file deliberately calls none of them: the screen sequences
/// `/cash/topup`, `/cash/count` and Reports itself, so a ledger guard keeps
/// living inside the one transaction that can hold it (ADR-0100).
///
/// The two capabilities are the ones `seed_data.dart` has granted since they
/// were added and nothing has ever checked. They name this act, so they gate it.
Router venueDayRoutes(AppDatabase db, WsHub hub, ServerAuth auth) {
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

  Response forbidden(Capability c) => Response(
    403,
    body: jsonEncode({'code': 'forbidden', 'capability': c.name}),
    headers: {'content-type': 'application/json'},
  );

  /// One handler for both ends: the two differ only in which capability opens
  /// them and which kind they stamp, and splitting that into two copies is how
  /// one of them later grows a field the other forgets.
  Future<Response> mark(
    Request req, {
    required Capability cap,
    required AuditKind kind,
  }) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(cap.name)) return forbidden(cap);
    // `note` is free text and optional — the one thing a closer sometimes has
    // to say ("mati lampu jam 8") has no closed set of codes behind it.
    final raw = await req.readAsString();
    final body = raw.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final note = (body['note'] as String?)?.trim();
    final entry = await writeAudit(
      db,
      type: AuditType.venueDay,
      kind: kind,
      actorUserId: a.$1,
      reason: (note == null || note.isEmpty) ? null : note,
      hub: hub,
    );
    return Response.ok(
      jsonEncode({'ok': true, 'id': entry?.id}),
      headers: {'content-type': 'application/json'},
    );
  }

  r.post(
    '/venue/day/open',
    (Request req) =>
        mark(req, cap: Capability.openDrawer, kind: AuditKind.venueOpened),
  );

  r.post(
    '/venue/day/close',
    (Request req) =>
        mark(req, cap: Capability.closeShift, kind: AuditKind.venueClosed),
  );

  return r;
}
