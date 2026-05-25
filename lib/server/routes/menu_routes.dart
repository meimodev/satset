import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

Future<Response?> _requireCap(
  Request req,
  AppDatabase db,
  ServerAuth? auth,
  Capability needed,
) async {
  if (auth == null) return null;
  final token = req.headers['authorization']
      ?.replaceFirst(RegExp(r'^[Bb]earer\s+'), '');
  final user = await auth.resolveBearer(token);
  if (user == null) return Response(401);
  final role = await (db.select(db.roles)
        ..where((r) => r.id.equals(user.roleId)))
      .getSingleOrNull();
  final caps = role == null
      ? const <String>[]
      : (jsonDecode(role.capabilitiesJson) as List).cast<String>();
  if (!caps.contains(needed.name)) {
    return Response(403,
        body: jsonEncode({
          'code': 'forbidden',
          'message': 'missing capability ${needed.name}',
        }),
        headers: {'content-type': 'application/json'});
  }
  return null;
}

Router menuRoutes(AppDatabase db, WsHub hub, [ServerAuth? auth]) {
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
    return Response.ok(jsonEncode(out),
        headers: {'content-type': 'application/json'});
  });

  r.patch('/menu/items/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    await _writeItem(db, id, body, isInsert: false);
    final out = await _readItem(db, id);
    if (out == null) return Response.notFound('item not found');
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'upsert', 'item': out});
    return Response.ok(jsonEncode(out),
        headers: {'content-type': 'application/json'});
  });

  r.delete('/menu/items/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editMenu);
    if (denied != null) return denied;
    await (db.delete(db.menuItems)..where((i) => i.id.equals(id))).go();
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'delete', 'id': id});
    return Response.ok(jsonEncode({'id': id}),
        headers: {'content-type': 'application/json'});
  });

  // 86 toggle. Body: { "unavailable": bool }. Permission: toggle86 (staff
  // can flip availability without full editMenu).
  r.post('/menu/items/<id>/availability', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.toggle86);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final value = body['unavailable'] as bool?;
    if (value == null) return Response(400, body: 'unavailable required');
    await (db.update(db.menuItems)..where((i) => i.id.equals(id)))
        .write(MenuItemsCompanion(unavailable: Value(value)));
    final out = await _readItem(db, id);
    if (out == null) return Response.notFound('item not found');
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'upsert', 'item': out});
    return Response.ok(jsonEncode(out),
        headers: {'content-type': 'application/json'});
  });

  // Stock delta. Body: { "delta": int } or { "stockCount": int }.
  r.post('/menu/items/<id>/stock', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.adjustStock);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final row = await (db.select(db.menuItems)..where((i) => i.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('item not found');
    int? next;
    if (body.containsKey('delta')) {
      final delta = (body['delta'] as num).toInt();
      next = ((row.stockCount ?? 0) + delta).clamp(0, 1 << 30);
    } else if (body.containsKey('stockCount')) {
      next = body['stockCount'] == null
          ? null
          : (body['stockCount'] as num).toInt();
    } else {
      return Response(400, body: 'delta or stockCount required');
    }
    await (db.update(db.menuItems)..where((i) => i.id.equals(id)))
        .write(MenuItemsCompanion(stockCount: Value(next)));
    final out = await _readItem(db, id);
    if (out == null) return Response.notFound('item not found');
    hub.broadcast(WsEventTypes.menuUpdated, {'kind': 'upsert', 'item': out});
    return Response.ok(jsonEncode(out),
        headers: {'content-type': 'application/json'});
  });

  return r;
}

// ---------- helpers ----------

Future<Map<String, dynamic>> _snapshot(AppDatabase db) async {
  final cats = await db.select(db.menuCategories).get();
  final items = await db.select(db.menuItems).get();
  final mods = await db.select(db.modifierGroups).get();
  return {
    'version': 1,
    'categories': [
      for (final c in cats) {'id': c.id, 'name': c.name},
    ],
    'items': [for (final it in items) _itemRowToJson(it)],
    'modifierGroups': [
      for (final m in mods)
        {
          'id': m.id,
          'name': m.name,
          'required': m.required,
          'multi': m.multi,
          'options': jsonDecode(m.optionsJson),
        }
    ],
  };
}

Map<String, dynamic> _itemRowToJson(MenuItem it) => {
      'id': it.id,
      'name': it.name,
      'categoryId': it.categoryId,
      'station': it.station,
      'description': it.description,
      'basePrice': it.basePrice,
      'prepTime': it.prepTime,
      'variants': jsonDecode(it.variantsJson),
      'modifierGroupIds': jsonDecode(it.modifierGroupIdsJson),
      'allergens': jsonDecode(it.allergensJson),
      'dietary': jsonDecode(it.dietaryJson),
      'unavailable': it.unavailable,
      'stockCount': it.stockCount,
      'autoEightySixAtZero': it.autoEightySixAtZero,
    };

Future<Map<String, dynamic>?> _readItem(AppDatabase db, String id) async {
  final row = await (db.select(db.menuItems)..where((i) => i.id.equals(id)))
      .getSingleOrNull();
  return row == null ? null : _itemRowToJson(row);
}

/// Upsert or partial-update a row.  `body` carries DTO-shaped fields. For
/// inserts every required column needs to be present; for PATCH any subset
/// is allowed and untouched columns stay as-is. Embedded modifier groups,
/// when sent as full objects, are mirrored into the ModifierGroups table.
Future<void> _writeItem(
  AppDatabase db,
  String id,
  Map<String, dynamic> body, {
  required bool isInsert,
}) async {
  // Embedded modifier groups → upsert into ModifierGroups table.
  final embedded = body['modifierGroups'];
  List<String>? modIds;
  if (embedded is List) {
    final ids = <String>[];
    for (final raw in embedded) {
      if (raw is! Map) continue;
      final m = raw.cast<String, dynamic>();
      final mid = (m['id'] as String?)?.trim();
      if (mid == null || mid.isEmpty) continue;
      await db.into(db.modifierGroups).insertOnConflictUpdate(
            ModifierGroupsCompanion.insert(
              id: mid,
              name: (m['name'] as String?) ?? '',
              required: Value((m['required'] as bool?) ?? false),
              multi: Value((m['multi'] as bool?) ?? false),
              optionsJson: Value(jsonEncode(m['options'] ?? const [])),
            ),
          );
      ids.add(mid);
    }
    modIds = ids;
  } else if (body['modifierGroupIds'] is List) {
    modIds = (body['modifierGroupIds'] as List).cast<String>();
  }

  if (isInsert) {
    await db.into(db.menuItems).insertOnConflictUpdate(
          MenuItemsCompanion.insert(
            id: id,
            name: (body['name'] as String?) ?? '',
            categoryId: (body['categoryId'] as String?) ?? '',
            station: (body['station'] as String?) ?? 'kitchen',
            description: Value((body['description'] as String?) ?? ''),
            basePrice: (body['basePrice'] as num?)?.toInt() ?? 0,
            prepTime: Value((body['prepTime'] as num?)?.toInt() ?? 5),
            variantsJson: Value(jsonEncode(body['variants'] ?? const [])),
            modifierGroupIdsJson: Value(jsonEncode(modIds ?? const [])),
            allergensJson: Value(jsonEncode(body['allergens'] ?? const [])),
            dietaryJson: Value(jsonEncode(body['dietary'] ?? const [])),
            unavailable: Value((body['unavailable'] as bool?) ?? false),
            stockCount: Value((body['stockCount'] as num?)?.toInt()),
            autoEightySixAtZero:
                Value((body['autoEightySixAtZero'] as bool?) ?? false),
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
        station: body.containsKey('station')
            ? Value(body['station'] as String)
            : const Value.absent(),
        description: body.containsKey('description')
            ? Value(body['description'] as String)
            : const Value.absent(),
        basePrice: body.containsKey('basePrice')
            ? Value((body['basePrice'] as num).toInt())
            : const Value.absent(),
        prepTime: body.containsKey('prepTime')
            ? Value((body['prepTime'] as num).toInt())
            : const Value.absent(),
        variantsJson: body.containsKey('variants')
            ? Value(jsonEncode(body['variants']))
            : const Value.absent(),
        modifierGroupIdsJson:
            modIds != null ? Value(jsonEncode(modIds)) : const Value.absent(),
        allergensJson: body.containsKey('allergens')
            ? Value(jsonEncode(body['allergens']))
            : const Value.absent(),
        dietaryJson: body.containsKey('dietary')
            ? Value(jsonEncode(body['dietary']))
            : const Value.absent(),
        unavailable: body.containsKey('unavailable')
            ? Value(body['unavailable'] as bool)
            : const Value.absent(),
        stockCount: body.containsKey('stockCount')
            ? Value((body['stockCount'] as num?)?.toInt())
            : const Value.absent(),
        autoEightySixAtZero: body.containsKey('autoEightySixAtZero')
            ? Value(body['autoEightySixAtZero'] as bool)
            : const Value.absent(),
      ),
    );
  }
}
