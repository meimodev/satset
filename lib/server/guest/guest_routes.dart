import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/server/db/database.dart';
import 'package:satset/server/self_order.dart';
import 'package:satset/server/ws_hub.dart';

/// The **guest** half of [[Pesan mandiri]] (ADR-0105). Everything reachable
/// from a stranger's phone lives in this one folder, so the boundary is a
/// directory rather than a convention.
///
/// This router takes **no [ServerAuth]** and that is deliberate — ADR-0102's
/// "every route factory takes a non-null ServerAuth" is a rule about the staff
/// API, and the way to keep a guest out of it is to give the guest a router
/// that has never heard of it. The credential here is the code in the URL plus
/// an opaque session id; there is no guest JWT and no guest auth scope, which
/// is one of the two costs ADR-0080 named and this design removes.
Router guestRoutes(AppDatabase db, WsHub hub) {
  final r = Router();

  Response json(Object body) => Response.ok(
    jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );

  Response err(int status, String code) => Response(
    status,
    body: jsonEncode({'code': code}),
    headers: {'content-type': 'application/json'},
  );

  /// The code rides the query string on reads and the body on writes. A code
  /// that resolves to nothing is a 404 either way — an unknown code, a
  /// deactivated table and a table opted out of self-order must be
  /// indistinguishable, or the QR becomes a way to enumerate the floor plan.
  Future<VenueTable?> table(Request req, [Map<String, dynamic>? body]) =>
      tableForGuestCode(
        db,
        (body?['code'] as String?) ?? req.url.queryParameters['code'] ?? '',
      );

  Future<GuestSession?> session(Request req) async {
    final id = req.headers['x-guest-session'];
    return id == null ? null : liveGuestSession(db, id);
  }

  /// The app shell. Served for any `/t/<code>` — the page reads the code back
  /// out of `location.pathname`, so nothing is templated into the HTML and the
  /// file stays a static asset.
  r.get('/t/<code>', (Request req, String code) async {
    final rules = await guestRules(db);
    if (!rules.enabled) return Response.notFound('not found');
    return Response.ok(
      await rootBundle.loadString('assets/guest_web/index.html'),
      headers: {
        'content-type': 'text/html; charset=utf-8',
        'cache-control': 'no-cache',
      },
    );
  });

  /// Who the guest is looking at: the venue's name and their own table. Also
  /// the liveness check the page runs before it draws anything.
  r.get('/guest/venue', (Request req) async {
    final t = await table(req);
    if (t == null) return err(404, 'not_found');
    final s = await (db.select(
      db.venueSettings,
    )..where((x) => x.id.equals('default'))).getSingleOrNull();
    final rules = await guestRules(db);
    return json({
      'venue': s?.displayName ?? '',
      'tableId': t.id,
      'tableLabel': t.label ?? t.id,
      'open': withinServiceHours(rules, DateTime.now()),
      'noteEnabled': rules.noteEnabled,
      'maxItems': rules.maxItems,
    });
  });

  r.get('/guest/menu', (Request req) async {
    final t = await table(req);
    if (t == null) return err(404, 'not_found');
    return json(await guestMenuJson(db));
  });

  /// The item photo, unauthenticated on purpose: it is the same JPEG the menu
  /// card shows a walk-in guest on paper.
  r.get('/guest/photo/<id>', (Request req, String id) async {
    final row = await (db.select(
      db.menuItems,
    )..where((i) => i.id.equals(id))).getSingleOrNull();
    if (row == null || row.photo == null || !row.guestVisible) {
      return Response.notFound('no photo');
    }
    return Response.ok(
      row.photo,
      headers: {'content-type': 'image/jpeg', 'cache-control': 'max-age=300'},
    );
  });

  r.post('/guest/session', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final t = await table(req, body);
    if (t == null) return err(404, 'not_found');
    final rules = await guestRules(db);
    if (!rules.enabled) return err(404, 'not_found');
    final s = await openGuestSession(
      db,
      tableId: t.id,
      ttlHours: rules.sessionHours,
    );
    return json({'sessionId': s.id, 'expiresAt': s.expiresAt.toIso8601String()});
  });

  r.post('/guest/orders', (Request req) async {
    final s = await session(req);
    if (s == null) return err(401, 'session_expired');
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final t = await table(req, body);
    if (t == null || t.id != s.tableId) return err(404, 'not_found');
    try {
      final o = await submitGuestOrder(
        db,
        session: s,
        table: t,
        lines: ((body['lines'] as List?) ?? const [])
            .cast<Map<String, dynamic>>(),
        hub: hub,
      );
      return json(await guestOrderJson(db, o));
    } on SelfOrderException catch (e) {
      return err(409, e.code);
    }
  });

  /// "Pesanan saya" — polled every few seconds by the phone. There is no
  /// second WebSocket hub for guests: a handful of phones asking a LAN server
  /// for a small JSON list is cheaper than a second fan-out to keep correct.
  r.get('/guest/orders', (Request req) async {
    final s = await session(req);
    if (s == null) return err(401, 'session_expired');
    return json({'orders': await guestOrdersJson(db, sessionId: s.id)});
  });

  r.delete('/guest/orders/<id>', (Request req, String id) async {
    final s = await session(req);
    if (s == null) return err(401, 'session_expired');
    try {
      final o = await cancelGuestOrder(
        db,
        orderId: id,
        sessionId: s.id,
        hub: hub,
      );
      return json(await guestOrderJson(db, o));
    } on SelfOrderException catch (e) {
      return err(e.code == 'not_found' ? 404 : 409, e.code);
    }
  });

  return r;
}
