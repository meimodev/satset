import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/audit_log.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/shift.dart' show businessDayStart;
import 'package:satset/server/stock.dart';
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

/// Bearer-token user, for audit attribution. Null when no auth helper is
/// configured (server-mode boot before the secret loads).
Future<User?> _actor(Request req, AppDatabase db, ServerAuth auth) async {
  final token = req.headers['authorization']?.replaceFirst(
    RegExp(r'^[Bb]earer\s+'),
    '',
  );
  return auth.resolveBearer(token);
}

Future<Response?> _requireCap(
  Request req,
  AppDatabase db,
  ServerAuth auth,
  Capability needed,
) async {
  final token = req.headers['authorization']?.replaceFirst(
    RegExp(r'^[Bb]earer\s+'),
    '',
  );
  final user = await auth.resolveBearer(token);
  if (user == null) return Response(401);
  final role = await (db.select(
    db.roles,
  )..where((r) => r.id.equals(user.roleId))).getSingleOrNull();
  final caps = role == null
      ? const <String>[]
      : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
  if (!caps.contains(needed.name)) {
    return Response(
      403,
      body: jsonEncode({
        'code': 'forbidden',
        'message': 'missing capability ${needed.name}',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
  return null;
}

Router menuRoutes(AppDatabase db, WsHub hub, ServerAuth auth) {
  final r = Router();

  r.get('/menu', (Request req) async {
    return Response.ok(
      jsonEncode(await _snapshot(db)),
      headers: {'content-type': 'application/json'},
    );
  });

  // Upsert item. Body shape mirrors MenuItemDto. Embedded `modifierGroups`
  // (full objects) are upserted into the ModifierGroups table as a side
  // effect, and the item stores their ids in `modifierGroupIdsJson`.
  r.post('/menu/items', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final id = (body['id'] as String?)?.trim().isNotEmpty == true
        ? body['id'] as String
        : _uuid.v4();
    await _writeItem(db, id, body, isInsert: true);
    final out = await _readItem(db, id);
    if (out == null) return Response.internalServerError();
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'upsert', 'item': out});
    return Response.ok(
      jsonEncode(out),
      headers: {'content-type': 'application/json'},
    );
  });

  r.patch('/menu/items/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    await _writeItem(db, id, body, isInsert: false);
    final out = await _readItem(db, id);
    if (out == null) return Response.notFound('item not found');
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'upsert', 'item': out});
    return Response.ok(
      jsonEncode(out),
      headers: {'content-type': 'application/json'},
    );
  });

  r.delete('/menu/items/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    await (db.delete(db.menuItems)..where((i) => i.id.equals(id))).go();
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'delete', 'id': id});
    return Response.ok(
      jsonEncode({'id': id}),
      headers: {'content-type': 'application/json'},
    );
  });

  // Sold-out toggle. Body: { "unavailable": bool, "reason"?: String }.
  // Permission: markSoldOut (staff can flip availability without full
  // editMenu).
  //
  // Audited, because pulling a dish mid-service is a decision someone made and
  // a manager later asks about. Only this manual path writes a row — the
  // auto-habis derived from zero stock is the stock trail's story, and echoing
  // it here would bury the human calls under bookkeeping.
  r.post('/menu/items/<id>/availability', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.markSoldOut);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final value = body['unavailable'] as bool?;
    if (value == null) return Response(400, body: 'unavailable required');
    final before = await (db.select(
      db.menuItems,
    )..where((i) => i.id.equals(id))).getSingleOrNull();
    await (db.update(db.menuItems)..where((i) => i.id.equals(id))).write(
      MenuItemsCompanion(unavailable: Value(value)),
    );
    final out = await _readItem(db, id);
    if (out == null) return Response.notFound('item not found');
    // Only a real flip is an event; re-asserting the current state is not.
    if (before != null && before.unavailable != value) {
      final reason = (body['reason'] as String?)?.trim();
      await writeAudit(
        db,
        hub: hub,
        type: value ? AuditType.menuKilled : AuditType.menuRestored,
        kind: value ? AuditKind.menuKilled : AuditKind.menuRestored,
        params: {'name': before.name},
        actorUserId: (await _actor(req, db, auth))?.id,
        reason: (reason != null && reason.isNotEmpty) ? reason : null,
      );
    }
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'upsert', 'item': out});
    return Response.ok(
      jsonEncode(out),
      headers: {'content-type': 'application/json'},
    );
  });

  // Item-level stock is gone (ADR-0040): stock lives on ingredients, and an
  // item's auto-habis is derived from its recipe. Kept as an explicit 410 so an
  // un-upgraded client gets a diagnosable answer instead of a bare 404.
  r.post('/menu/items/<id>/stock', (Request req, String id) async {
    return Response(
      410,
      body: jsonEncode({
        'code': 'stock_moved_to_ingredients',
        'message': 'Stok kini per bahan — lihat /stock/ingredients',
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  // ---------- photo (binary side-endpoints) ----------
  // Bytes stay OUT of the item-upsert JSON; the snapshot carries only photoRev.
  // See docs/adr/0014-menu-photo-blob-and-pinned-byte-fetch.md.

  // Stream the JPEG bytes. Ungated, matching the open GET /menu snapshot.
  r.get('/menu/items/<id>/photo', (Request req, String id) async {
    final row = await (db.select(
      db.menuItems,
    )..where((i) => i.id.equals(id))).getSingleOrNull();
    if (row == null || row.photo == null) return Response.notFound('no photo');
    return Response.ok(
      row.photo,
      headers: {'content-type': 'image/jpeg', 'cache-control': 'no-cache'},
    );
  });

  // Replace the photo. Body = raw JPEG bytes. Bumps photoRev, broadcasts.
  r.put('/menu/items/<id>/photo', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    final row = await (db.select(
      db.menuItems,
    )..where((i) => i.id.equals(id))).getSingleOrNull();
    if (row == null) return Response.notFound('item not found');
    final builder = await req.read().fold<BytesBuilder>(
      BytesBuilder(),
      (b, chunk) => b..add(chunk),
    );
    final bytes = builder.takeBytes();
    if (bytes.isEmpty) return Response(400, body: 'empty body');
    await (db.update(db.menuItems)..where((i) => i.id.equals(id))).write(
      MenuItemsCompanion(
        photo: Value(bytes),
        photoRev: Value(row.photoRev + 1),
      ),
    );
    final out = await _readItem(db, id);
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'upsert', 'item': out});
    return Response.ok(
      jsonEncode(out),
      headers: {'content-type': 'application/json'},
    );
  });

  // Clear the photo (back to the avatar fallback). Bumps photoRev, broadcasts.
  r.delete('/menu/items/<id>/photo', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    final row = await (db.select(
      db.menuItems,
    )..where((i) => i.id.equals(id))).getSingleOrNull();
    if (row == null) return Response.notFound('item not found');
    await (db.update(db.menuItems)..where((i) => i.id.equals(id))).write(
      MenuItemsCompanion(
        photo: const Value(null),
        photoRev: Value(row.photoRev + 1),
      ),
    );
    final out = await _readItem(db, id);
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'upsert', 'item': out});
    return Response.ok(
      jsonEncode(out),
      headers: {'content-type': 'application/json'},
    );
  });

  // ---------- categories ----------

  // Create a category. Body: { "name": str, "id"?: str }. sortOrder appended.
  r.post('/menu/categories', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final name = (body['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      return Response(400, body: 'name required');
    }
    final id = (body['id'] as String?)?.trim().isNotEmpty == true
        ? body['id'] as String
        : _uuid.v4().substring(0, 8);
    final maxRow = await (db.selectOnly(
      db.menuCategories,
    )..addColumns([db.menuCategories.sortOrder.max()])).getSingleOrNull();
    final nextSort =
        (maxRow?.read(db.menuCategories.sortOrder.max()) ?? -1) + 1;
    await db
        .into(db.menuCategories)
        .insertOnConflictUpdate(
          MenuCategoriesCompanion.insert(
            id: id,
            name: name,
            sortOrder: Value(nextSort),
          ),
        );
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'category', 'id': id});
    return Response.ok(
      jsonEncode({'id': id, 'name': name}),
      headers: {'content-type': 'application/json'},
    );
  });

  // Rename a category. Body: { "name": str }.
  r.patch('/menu/categories/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final name = (body['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      return Response(400, body: 'name required');
    }
    await (db.update(db.menuCategories)..where((c) => c.id.equals(id))).write(
      MenuCategoriesCompanion(name: Value(name)),
    );
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'category', 'id': id});
    return Response.ok(
      jsonEncode({'id': id, 'name': name}),
      headers: {'content-type': 'application/json'},
    );
  });

  // Delete a category. Rejected with 409 when any item still references it.
  r.delete('/menu/categories/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    final count =
        await (db.selectOnly(db.menuItems)
              ..addColumns([db.menuItems.id.count()])
              ..where(db.menuItems.categoryId.equals(id)))
            .getSingle();
    final n = count.read(db.menuItems.id.count()) ?? 0;
    if (n > 0) {
      return Response(
        409,
        body: jsonEncode({'code': 'category_not_empty', 'count': n}),
        headers: {'content-type': 'application/json'},
      );
    }
    await (db.delete(db.menuCategories)..where((c) => c.id.equals(id))).go();
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'category', 'id': id});
    return Response.ok(
      jsonEncode({'id': id}),
      headers: {'content-type': 'application/json'},
    );
  });

  // Reorder categories. Body: { "ids": [str, ...] } — sortOrder set by index.
  r.post('/menu/categories/reorder', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final ids = (body['ids'] as List?)?.cast<String>();
    if (ids == null) return Response(400, body: 'ids required');
    for (var i = 0; i < ids.length; i++) {
      await (db.update(db.menuCategories)..where((c) => c.id.equals(ids[i])))
          .write(MenuCategoriesCompanion(sortOrder: Value(i)));
    }
    hub.broadcast(WsEventTypes.menuUpdated, {
      'kind': 'category',
      'reorder': true,
    });
    return Response.ok(
      jsonEncode({'ok': true}),
      headers: {'content-type': 'application/json'},
    );
  });

  // ---------- tags (allergen / diet) ----------

  // Create a tag. Body: { "kind": "allergen"|"diet", "name": str,
  // "code"?: str, "id"?: str }. sortOrder appended within its kind.
  r.post('/menu/tags', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final kind = (body['kind'] as String?)?.trim();
    final name = (body['name'] as String?)?.trim();
    if (kind != 'allergen' && kind != 'diet') {
      return Response(400, body: 'kind must be allergen or diet');
    }
    if (name == null || name.isEmpty) {
      return Response(400, body: 'name required');
    }
    final id = (body['id'] as String?)?.trim().isNotEmpty == true
        ? body['id'] as String
        : _uuid.v4().substring(0, 8);
    final maxRow =
        await (db.selectOnly(db.menuTags)
              ..addColumns([db.menuTags.sortOrder.max()])
              ..where(db.menuTags.kind.equals(kind!)))
            .getSingleOrNull();
    final nextSort = (maxRow?.read(db.menuTags.sortOrder.max()) ?? -1) + 1;
    await db
        .into(db.menuTags)
        .insertOnConflictUpdate(
          MenuTagsCompanion.insert(
            id: id,
            kind: kind,
            name: name,
            code: Value((body['code'] as String?)?.trim() ?? ''),
            sortOrder: Value(nextSort),
          ),
        );
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'tag', 'id': id});
    return Response.ok(
      jsonEncode({'id': id}),
      headers: {'content-type': 'application/json'},
    );
  });

  // Update a tag. Body: any subset of { name, code }.
  r.patch('/menu/tags/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    await (db.update(db.menuTags)..where((t) => t.id.equals(id))).write(
      MenuTagsCompanion(
        name: body.containsKey('name')
            ? Value(body['name'] as String)
            : const Value.absent(),
        code: body.containsKey('code')
            ? Value(body['code'] as String)
            : const Value.absent(),
      ),
    );
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'tag', 'id': id});
    return Response.ok(
      jsonEncode({'id': id}),
      headers: {'content-type': 'application/json'},
    );
  });

  // Delete a tag. Cascade-strips its id from every item's allergens/dietary.
  r.delete('/menu/tags/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    await (db.delete(db.menuTags)..where((t) => t.id.equals(id))).go();
    final items = await db.select(db.menuItems).get();
    for (final it in items) {
      final allergens = (jsonDecode(it.allergensJson) as List).cast<String>();
      final dietary = (jsonDecode(it.dietaryJson) as List).cast<String>();
      if (!allergens.contains(id) && !dietary.contains(id)) continue;
      await (db.update(db.menuItems)..where((i) => i.id.equals(it.id))).write(
        MenuItemsCompanion(
          allergensJson: Value(
            jsonEncode(allergens.where((t) => t != id).toList()),
          ),
          dietaryJson: Value(
            jsonEncode(dietary.where((t) => t != id).toList()),
          ),
        ),
      );
    }
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'tag', 'id': id});
    return Response.ok(
      jsonEncode({'id': id}),
      headers: {'content-type': 'application/json'},
    );
  });

  // Reorder tags within a kind. Body: { "ids": [str, ...] } — sortOrder = index.
  r.post('/menu/tags/reorder', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final ids = (body['ids'] as List?)?.cast<String>();
    if (ids == null) return Response(400, body: 'ids required');
    for (var i = 0; i < ids.length; i++) {
      await (db.update(db.menuTags)..where((t) => t.id.equals(ids[i]))).write(
        MenuTagsCompanion(sortOrder: Value(i)),
      );
    }
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'tag', 'reorder': true});
    return Response.ok(
      jsonEncode({'ok': true}),
      headers: {'content-type': 'application/json'},
    );
  });

  return r;
}

// ---------- helpers ----------

Future<Map<String, dynamic>> _snapshot(AppDatabase db) async {
  final cats = await (db.select(
    db.menuCategories,
  )..orderBy([(c) => OrderingTerm(expression: c.sortOrder)])).get();
  final items = await _selectItemsNoBlob(db);
  final flags = await deriveStockFlags(db);
  final pop = await menuPopularity(db);
  final tags = await (db.select(
    db.menuTags,
  )..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();
  return {
    'version': 1,
    'categories': [
      for (final c in cats) {'id': c.id, 'name': c.name},
    ],
    'items': [
      for (final r in items)
        _itemResultToJson(
          db,
          r,
          flags: flags[r.read(db.menuItems.id)!],
          popQty: pop[r.read(db.menuItems.id)!] ?? 0,
        ),
    ],
    'tags': [for (final t in tags) _tagRowToJson(t)],
  };
}

/// Every item column EXCEPT the `photo` blob. The blob is read only by the
/// photo route — keeping it out of the hot snapshot/read path is mandatory
/// (see docs/adr/0014-menu-photo-blob-and-pinned-byte-fetch.md).
List<Expression> _itemCols(AppDatabase db) => [
  db.menuItems.id,
  db.menuItems.name,
  db.menuItems.categoryId,
  db.menuItems.description,
  db.menuItems.basePrice,
  db.menuItems.cost,
  db.menuItems.prepTime,
  db.menuItems.variantsJson,
  db.menuItems.modifierGroupsJson,
  db.menuItems.allergensJson,
  db.menuItems.dietaryJson,
  db.menuItems.unavailable,
  db.menuItems.photoRev,
  // [[Menu tamu]] (ADR-0105) — three fields the guest page reads and the
  // "Menu tamu" tab writes. They ride the ordinary snapshot rather than a
  // second endpoint, so a menu edit and a guest-visibility edit cannot
  // disagree about which item they mean.
  db.menuItems.guestVisible,
  db.menuItems.guestFeatured,
  db.menuItems.guestStockOverride,
];

Future<List<TypedResult>> _selectItemsNoBlob(AppDatabase db, {String? id}) {
  final q = db.selectOnly(db.menuItems)..addColumns(_itemCols(db));
  if (id != null) q.where(db.menuItems.id.equals(id));
  return q.get();
}

/// [flags] carries the **derived** availability for this item (item, variant,
/// and option granularity). Nothing about it is stored — it is recomputed from
/// ingredient stock, so receiving un-habises an item automatically (ADR-0040).
Map<String, dynamic> _itemResultToJson(
  AppDatabase db,
  TypedResult r, {
  ItemStockFlags? flags,
  int popQty = 0,
}) => {
  'id': r.read(db.menuItems.id)!,
  'name': r.read(db.menuItems.name)!,
  'categoryId': r.read(db.menuItems.categoryId)!,
  'description': r.read(db.menuItems.description)!,
  'basePrice': r.read(db.menuItems.basePrice)!,
  'cost': r.read(db.menuItems.cost)!,
  // Null rides the wire as null — the client resolves it against the
  // venue default so the inherit stays live (ADR-0043).
  'prepTime': r.read(db.menuItems.prepTime),
  'variants': jsonDecode(r.read(db.menuItems.variantsJson)!),
  'modifierGroups': jsonDecode(r.read(db.menuItems.modifierGroupsJson)!),
  'allergens': jsonDecode(r.read(db.menuItems.allergensJson)!),
  'dietary': jsonDecode(r.read(db.menuItems.dietaryJson)!),
  'unavailable': r.read(db.menuItems.unavailable)!,
  'autoSoldOut': flags?.autoSoldOut ?? false,
  'soldOutVariantIds': flags?.soldOutVariantIds.toList() ?? const <String>[],
  'soldOutOptionIds': flags?.soldOutOptionIds.toList() ?? const <String>[],
  'photoRev': r.read(db.menuItems.photoRev)!,
  'guestVisible': r.read(db.menuItems.guestVisible)!,
  'guestFeatured': r.read(db.menuItems.guestFeatured)!,
  'guestStockOverride': r.read(db.menuItems.guestStockOverride)!,
  // [[Menu populer]] (ADR-0113). Derived like `autoSoldOut`, never stored, and
  // 0 on the single-item read — that route feeds an editor, which does not
  // rank. See [menuPopularity].
  'popQty': popQty,
};

/// Lines sold per item since 30 business days ago — the [[Menu populer]] rank
/// (ADR-0113).
///
/// Rollover-aligned, not `now - 30d`: a venue whose day starts at 04:00 counts
/// the same set of days at 03:00 as it will at 05:00, so the grid does not
/// reshuffle mid-close. Voided lines are excluded and *every other* status
/// counts, `draft` and `held` included — popularity is about what a guest
/// asked for, not what the bill kept, which is why this is not the Reports
/// ranking (that one is by revenue, `reports_routes.dart`).
///
/// Recomputed on every snapshot rather than cached: `deriveStockFlags` already
/// walks every recipe on this same call, and a cache here would be a second
/// thing to invalidate on a WS event that already means "re-read the menu".
Future<Map<String, int>> menuPopularity(AppDatabase db) async {
  final settings = await (db.select(
    db.venueSettings,
  )..where((s) => s.id.equals('default'))).getSingleOrNull();
  final from = businessDayStart(
    SatClock.now(),
    settings?.businessDayStartHour ?? 4,
  ).subtract(const Duration(days: 30));
  final qty = db.tickets.qty.sum();
  final q = db.selectOnly(db.tickets)
    ..addColumns([db.tickets.itemId, qty])
    ..where(
      db.tickets.sentAt.isBiggerOrEqualValue(from) &
          db.tickets.status.equals('voided').not(),
    )
    ..groupBy([db.tickets.itemId]);
  return {
    for (final r in await q.get())
      r.read(db.tickets.itemId)!: r.read(qty) ?? 0,
  };
}

Map<String, dynamic> _tagRowToJson(MenuTag t) => {
  'id': t.id,
  'kind': t.kind,
  'name': t.name,
  'code': t.code,
  'sortOrder': t.sortOrder,
};

Future<Map<String, dynamic>?> _readItem(AppDatabase db, String id) async {
  final rows = await _selectItemsNoBlob(db, id: id);
  if (rows.isEmpty) return null;
  final flags = await deriveStockFlags(db);
  return _itemResultToJson(db, rows.first, flags: flags[id]);
}

/// Upsert or partial-update a row.  `body` carries DTO-shaped fields. For
/// inserts every required column needs to be present; for PATCH any subset
/// is allowed and untouched columns stay as-is. Modifier groups are stored
/// per-item as a JSON blob (private, not shared) — see
/// docs/adr/0009-per-item-embedded-modifiers.md.
Future<void> _writeItem(
  AppDatabase db,
  String id,
  Map<String, dynamic> body, {
  required bool isInsert,
}) async {
  if (isInsert) {
    await db
        .into(db.menuItems)
        .insertOnConflictUpdate(
          MenuItemsCompanion.insert(
            id: id,
            name: (body['name'] as String?) ?? '',
            categoryId: (body['categoryId'] as String?) ?? '',
            description: Value((body['description'] as String?) ?? ''),
            basePrice: (body['basePrice'] as num?)?.toInt() ?? 0,
            cost: Value((body['cost'] as num?)?.toInt() ?? 0),
            // Absent ⇒ null ⇒ inherits the venue default (ADR-0043).
            prepTime: Value((body['prepTime'] as num?)?.toInt()),
            variantsJson: Value(jsonEncode(body['variants'] ?? const [])),
            modifierGroupsJson: Value(
              jsonEncode(body['modifierGroups'] ?? const []),
            ),
            allergensJson: Value(jsonEncode(body['allergens'] ?? const [])),
            dietaryJson: Value(jsonEncode(body['dietary'] ?? const [])),
            unavailable: Value((body['unavailable'] as bool?) ?? false),
            guestVisible: Value((body['guestVisible'] as bool?) ?? true),
            guestFeatured: Value((body['guestFeatured'] as bool?) ?? false),
          ),
        );
  } else {
    await (db.update(db.menuItems)..where((i) => i.id.equals(id))).write(
      MenuItemsCompanion(
        name: body.containsKey('name')
            ? Value(body['name'] as String)
            : const Value.absent(),
        categoryId: body.containsKey('categoryId')
            ? Value(body['categoryId'] as String)
            : const Value.absent(),
        description: body.containsKey('description')
            ? Value(body['description'] as String)
            : const Value.absent(),
        basePrice: body.containsKey('basePrice')
            ? Value((body['basePrice'] as num).toInt())
            : const Value.absent(),
        cost: body.containsKey('cost')
            ? Value((body['cost'] as num).toInt())
            : const Value.absent(),
        guestVisible: body.containsKey('guestVisible')
            ? Value(body['guestVisible'] == true)
            : const Value.absent(),
        guestFeatured: body.containsKey('guestFeatured')
            ? Value(body['guestFeatured'] == true)
            : const Value.absent(),
        // The manual habis call for the guest page. Stamped with *when*,
        // because a `forceOut` set at last night's rush must not still be
        // hiding rendang at lunch — the read side expires it at the business
        // day rollover rather than trusting the value alone.
        guestStockOverride: body.containsKey('guestStockOverride')
            ? Value(
                const {'auto', 'forceIn', 'forceOut'}.contains(
                      body['guestStockOverride'],
                    )
                    ? body['guestStockOverride'] as String
                    : 'auto',
              )
            : const Value.absent(),
        guestOverrideAt: body.containsKey('guestStockOverride')
            ? Value(SatClock.now())
            : const Value.absent(),
        // Explicit null clears the override back to "ikut target venue".
        prepTime: body.containsKey('prepTime')
            ? Value((body['prepTime'] as num?)?.toInt())
            : const Value.absent(),
        variantsJson: body.containsKey('variants')
            ? Value(jsonEncode(body['variants']))
            : const Value.absent(),
        modifierGroupsJson: body.containsKey('modifierGroups')
            ? Value(jsonEncode(body['modifierGroups']))
            : const Value.absent(),
        allergensJson: body.containsKey('allergens')
            ? Value(jsonEncode(body['allergens']))
            : const Value.absent(),
        dietaryJson: body.containsKey('dietary')
            ? Value(jsonEncode(body['dietary']))
            : const Value.absent(),
        unavailable: body.containsKey('unavailable')
            ? Value(body['unavailable'] as bool)
            : const Value.absent(),
      ),
    );
  }
}
