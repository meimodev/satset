import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:satset/core/time/sat_clock.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/guest/guest_plane.dart';
import 'package:satset/server/self_order.dart';
import 'package:satset/server/ws_hub.dart';

/// The **staff** half of [[Pesan mandiri]] (ADR-0105): the review queue, the
/// table codes and the numbers. The guest half is a different plane entirely
/// and lives under `lib/server/guest/` — nothing here is reachable without a
/// bearer, and nothing there ever sees one.
///
/// Capability split: **deciding** a guest order is order-taking (`takeOrder`),
/// because a waiter on a phone must be able to do it mid-shift. **Rotating
/// codes** is the owner's authority (`editSettings`) — it kills every printed
/// QR in the venue.
Router selfOrderRoutes(AppDatabase db, WsHub hub, ServerAuth auth) {
  final r = Router();

  Future<(String, Set<String>)?> actor(Request req) async {
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

  Response err(int status, String code) => Response(
    status,
    body: jsonEncode({'code': code}),
    headers: {'content-type': 'application/json'},
  );

  Response forbidden(Capability c) => Response(
    403,
    body: jsonEncode({'code': 'forbidden', 'capability': c.name}),
    headers: {'content-type': 'application/json'},
  );

  /// The queue plus the day's numbers plus the tables and their codes — one
  /// response, because the screen shows all three at once and a tablet on a
  /// busy floor should not pay three round trips for one tab switch.
  r.get('/selforder', (Request req) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.takeOrder.name) &&
        !a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.takeOrder);
    }
    final status = req.url.queryParameters['status'];
    final tables = await db.select(db.venueTables).get();
    final zones = {
      for (final z in await db.select(db.zones).get()) z.id: z.name,
    };
    final host = await guestLanHost();
    return json({
      // The address a printed QR must carry. Resolved here because only the
      // machine running the plane knows which interface a guest can reach —
      // the tablet's own client half is paired over loopback.
      'host': host,
      'guestPort': guestPlanePort,
      // The counter's own code (ADR-0109), minted here on first read. This is
      // the moment an owner opens the QR tab having turned the switch on, and
      // it is the only place that mints — a code handed out anywhere else is a
      // live QR nobody asked to publish. Null when the switch is off.
      'counterCode': await counterGuestCode(db, mint: true) ?? '',
      'orders': await guestOrdersJson(db, status: status, staffView: true),
      'stats': await guestOrderStats(db),
      // The [[Menu tamu]] tab's rows, resolved exactly as the guest page sees
      // them — including the derived sold-out, so the owner reads the same
      // answer their guest is reading rather than a second computation of it.
      'menu': await guestMenuJson(db, includeHidden: true),
      'tables': [
        for (final t in tables)
          {
            'id': t.id,
            'label': t.label,
            'zoneId': t.zoneId,
            // Resolved here rather than shipping the zone list beside it: the
            // QR tab prints a card that says which room the table is in, and
            // a printed card is no place for an id.
            'zoneName': zones[t.zoneId] ?? '',
            'seats': t.capacity,
            'code': t.guestCode,
            'enabled': t.guestOrderingEnabled,
          },
      ],
    });
  });

  r.post('/selforder/orders/<id>/accept', (Request req, String id) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.takeOrder.name)) {
      return forbidden(Capability.takeOrder);
    }
    try {
      final out = await acceptGuestOrder(
        db,
        orderId: id,
        actorId: a.$1,
        hub: hub,
      );
      return json({
        'order': await guestOrderJson(db, out.order, staffView: true),
        'rejected': out.rejected,
      });
    } on SelfOrderException catch (e) {
      return err(e.code == 'not_found' ? 404 : 409, e.code);
    }
  });

  r.post('/selforder/orders/<id>/reject', (Request req, String id) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.takeOrder.name)) {
      return forbidden(Capability.takeOrder);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      final o = await rejectGuestOrder(
        db,
        orderId: id,
        actorId: a.$1,
        // A code, never a sentence (ADR-0085).
        reasonCode: (body['reasonCode'] as String?) ?? 'other',
        hub: hub,
      );
      return json(await guestOrderJson(db, o, staffView: true));
    } on SelfOrderException catch (e) {
      return err(e.code == 'not_found' ? 404 : 409, e.code);
    }
  });

  /// Accept everything waiting. Partial success is the normal outcome — one
  /// order may fail its stock check while four go through — so this reports
  /// per-order rather than refusing the batch.
  r.post('/selforder/orders/accept-all', (Request req) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.takeOrder.name)) {
      return forbidden(Capability.takeOrder);
    }
    final pending = await guestOrdersJson(db, status: 'pending');
    final failed = <Map<String, String>>[];
    var ok = 0;
    for (final o in pending) {
      try {
        await acceptGuestOrder(
          db,
          orderId: o['id'] as String,
          actorId: a.$1,
          hub: hub,
        );
        ok++;
      } on SelfOrderException catch (e) {
        failed.add({'id': o['id'] as String, 'code': e.code});
      }
    }
    return json({'accepted': ok, 'failed': failed});
  });

  /// The [[Menu tamu]] write. On this router rather than the menu one because
  /// the person curating what guests may order holds `editSettings`, not
  /// `editMenu` — deciding what is on the menu and deciding what a stranger's
  /// phone may see are different authorities.
  r.patch('/selforder/items/<id>', (Request req, String id) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final n = await (db.update(db.menuItems)..where((i) => i.id.equals(id)))
        .write(
          MenuItemsCompanion(
            guestVisible: body.containsKey('guestVisible')
                ? Value(body['guestVisible'] == true)
                : const Value.absent(),
            guestFeatured: body.containsKey('guestFeatured')
                ? Value(body['guestFeatured'] == true)
                : const Value.absent(),
            // Not a guest-only fact, but this is the only screen that shows
            // it, so this is the only route that writes it.
            alcohol: body.containsKey('alcohol')
                ? Value(body['alcohol'] == true)
                : const Value.absent(),
            guestStockOverride: body.containsKey('guestStockOverride')
                ? Value(
                    const {'auto', 'forceIn', 'forceOut'}.contains(
                          body['guestStockOverride'],
                        )
                        ? body['guestStockOverride'] as String
                        : 'auto',
                  )
                : const Value.absent(),
            // Stamped so the read side can expire a manual call at the
            // business-day rollover instead of trusting it forever.
            guestOverrideAt: body.containsKey('guestStockOverride')
                ? Value(SatClock.now())
                : const Value.absent(),
          ),
        );
    return n == 0 ? err(404, 'not_found') : json({'ok': true});
  });

  /// A category's [[Jam tayang]]. Send both `fromMin` and `toMin` to set one,
  /// or both null to clear it — a half-window is not a thing, so the pair is
  /// written together or not at all.
  r.patch('/selforder/categories/<id>', (Request req, String id) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final from = (body['fromMin'] as num?)?.toInt();
    final to = (body['toMin'] as num?)?.toInt();
    // Either a whole window or none. An equal pair is rejected rather than
    // stored: it would mean a category that is never on, and "never" already
    // has a control — hide the items.
    if ((from == null) != (to == null)) return err(400, 'bad_request');
    if (from != null && to != null) {
      if (from < 0 || from > 1439 || to < 0 || to > 1439 || from == to) {
        return err(400, 'bad_request');
      }
    }
    final n =
        await (db.update(db.menuCategories)..where((c) => c.id.equals(id)))
            .write(
              MenuCategoriesCompanion(
                guestFromMin: Value(from),
                guestToMin: Value(to),
              ),
            );
    return n == 0 ? err(404, 'not_found') : json({'ok': true});
  });

  r.post('/selforder/codes/rotate', (Request req) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final n = await rotateGuestCodes(db, actorId: a.$1, hub: hub);
    return json({'rotated': n});
  });

  /// Per-table opt-in. A venue runs self-order on the dining room and keeps the
  /// bar counter staff-only.
  r.patch('/selforder/tables/<id>', (Request req, String id) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final n = await (db.update(db.venueTables)..where((t) => t.id.equals(id)))
        .write(
          VenueTablesCompanion(
            guestOrderingEnabled: body.containsKey('enabled')
                ? Value(body['enabled'] == true)
                : const Value.absent(),
          ),
        );
    return n == 0 ? err(404, 'not_found') : json({'ok': true});
  });

  return r;
}
