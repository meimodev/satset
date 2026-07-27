/// CRUD for the [[Preset diskon]] catalogue — the owner-defined discounts a
/// [[Cashier]] may pick from. Cashiers never type a rate (ADR-0037), so this is
/// the only place discount values are authored.
///
/// Reads are open (every paired device caches the list); writes need
/// `editSettings`, matching the venue-settings routes this sits beside.
/// See docs/adr/0037-cashier-stage-catalog-discounts.md.
library;

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

const _scopes = {'order', 'line'};
const _kinds = {'percent', 'fixed'};

Map<String, dynamic> discountPresetJson(DiscountPreset p) => {
  'id': p.id,
  'name': p.name,
  'scope': p.scope,
  'kind': p.kind,
  'value': p.value,
  'active': p.active,
  'sortOrder': p.sortOrder,
};

Future<List<DiscountPreset>> _all(AppDatabase db) =>
    (db.select(db.discountPresets)..orderBy([
          (t) => OrderingTerm(expression: t.sortOrder),
          (t) => OrderingTerm(expression: t.name),
        ]))
        .get();

Response _err(int code, String slug, String message) => Response(
  code,
  body: jsonEncode({'code': slug, 'message': message}),
  headers: {'content-type': 'application/json'},
);

Response _ok(Object? body) => Response.ok(
  jsonEncode(body),
  headers: {'content-type': 'application/json'},
);

Future<Response?> _requireCap(
  Request req,
  AppDatabase db,
  ServerAuth? auth,
  Capability needed,
) async {
  if (auth == null) return null;
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
    return _err(403, 'forbidden', 'missing capability ${needed.name}');
  }
  return null;
}

/// Validate the authored shape. A `fixed` preset scoped to `line` is allowed
/// but clamps per line at apply time; a percent over 100% is rejected outright
/// rather than silently clamped, so the owner sees their typo.
String? _validate(String name, String scope, String kind, int value) {
  if (name.isEmpty) return 'nama diskon wajib diisi';
  if (!_scopes.contains(scope)) return 'scope harus order atau line';
  if (!_kinds.contains(kind)) return 'kind harus percent atau fixed';
  if (value <= 0) return 'nilai diskon harus lebih dari 0';
  if (kind == 'percent' && value > 10000) return 'diskon persen maksimal 100%';
  return null;
}

Router discountPresetRoutes(AppDatabase db, WsHub hub, [ServerAuth? auth]) {
  final r = Router();

  Future<void> broadcast() async {
    hub.broadcast(WsEventTypes.discountPresetsUpdated, {
      'presets': [for (final p in await _all(db)) discountPresetJson(p)],
    });
  }

  r.get('/venue/discount-presets', (Request req) async {
    return _ok({
      'presets': [for (final p in await _all(db)) discountPresetJson(p)],
    });
  });

  r.post('/venue/discount-presets', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final name = (body['name'] as String? ?? '').trim();
    final scope = body['scope'] as String? ?? 'order';
    final kind = body['kind'] as String? ?? 'percent';
    final value = (body['value'] as num?)?.toInt() ?? 0;
    final bad = _validate(name, scope, kind, value);
    if (bad != null) return _err(400, 'invalid', bad);
    final id = _uuid.v4();
    await db
        .into(db.discountPresets)
        .insert(
          DiscountPresetsCompanion.insert(
            id: id,
            name: name,
            scope: Value(scope),
            kind: Value(kind),
            value: Value(value),
            active: Value(body['active'] as bool? ?? true),
            sortOrder: Value((body['sortOrder'] as num?)?.toInt() ?? 0),
          ),
        );
    await broadcast();
    final row = await (db.select(
      db.discountPresets,
    )..where((x) => x.id.equals(id))).getSingle();
    return _ok(discountPresetJson(row));
  });

  r.patch('/venue/discount-presets/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final existing = await (db.select(
      db.discountPresets,
    )..where((x) => x.id.equals(id))).getSingleOrNull();
    if (existing == null) return _err(404, 'not_found', 'preset not found');
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final name = ((body['name'] as String?) ?? existing.name).trim();
    final scope = body['scope'] as String? ?? existing.scope;
    final kind = body['kind'] as String? ?? existing.kind;
    final value = (body['value'] as num?)?.toInt() ?? existing.value;
    final bad = _validate(name, scope, kind, value);
    if (bad != null) return _err(400, 'invalid', bad);
    // Editing a preset never rewrites applied discounts — those snapshotted
    // name/kind/value at apply time (ADR-0037). This only changes what future
    // applications will copy.
    await (db.update(db.discountPresets)..where((x) => x.id.equals(id))).write(
      DiscountPresetsCompanion(
        name: Value(name),
        scope: Value(scope),
        kind: Value(kind),
        value: Value(value),
        active: body.containsKey('active')
            ? Value(body['active'] as bool)
            : const Value.absent(),
        sortOrder: body.containsKey('sortOrder')
            ? Value((body['sortOrder'] as num).toInt())
            : const Value.absent(),
      ),
    );
    await broadcast();
    final row = await (db.select(
      db.discountPresets,
    )..where((x) => x.id.equals(id))).getSingle();
    return _ok(discountPresetJson(row));
  });

  // Hard delete — safe because every applied discount carries its own snapshot,
  // so history stands alone. `presetId` on those rows becomes a dangling weak
  // reference by design; the reporting rollup groups by it but labels from the
  // snapshot (ADR-0039).
  r.delete('/venue/discount-presets/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final n = await (db.delete(
      db.discountPresets,
    )..where((x) => x.id.equals(id))).go();
    if (n == 0) return _err(404, 'not_found', 'preset not found');
    await broadcast();
    return _ok({'ok': true});
  });

  return r;
}
