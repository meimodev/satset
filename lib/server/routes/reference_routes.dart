import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/server/db/database.dart';

Router referenceRoutes(AppDatabase db) {
  final r = Router();

  r.get('/zones', (Request req) async {
    final rows = await db.select(db.zones).get();
    return _ok([
      for (final z in rows)
        {
          'id': z.id,
          'name': z.name,
          'short': z.short,
          'colorHex': z.colorHex,
          'iconKey': z.iconKey,
        }
    ]);
  });

  r.get('/roles', (Request req) async {
    final rows = await db.select(db.roles).get();
    return _ok([
      for (final r in rows)
        {
          'id': r.id,
          'name': r.name,
          'colorHex': r.colorHex,
          'capabilities': jsonDecode(r.capabilitiesJson),
        }
    ]);
  });

  /// Public reference: never returns PIN material or hash.
  r.get('/staff', (Request req) async {
    final rows = await db.select(db.users).get();
    return _ok([
      for (final u in rows)
        {
          'id': u.id,
          'name': u.name,
          'initials': u.initials,
          'roleId': u.roleId,
          'zoneAssigned': u.zoneAssigned,
          'onDuty': u.onDuty,
          'disabled': u.disabled,
        }
    ]);
  });

  return r;
}

Response _ok(Object body) => Response.ok(jsonEncode(body),
    headers: {'content-type': 'application/json'});
