import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';

String _hashPin(String pin) =>
    sha256.convert(utf8.encode('satset.v1::$pin')).toString();

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

/// Resolve the bearer-token user for audit attribution. Returns null when
/// no auth helper is configured (server-mode boot before secret loaded).
Future<User?> _actor(Request req, AppDatabase db, ServerAuth? auth) async {
  if (auth == null) return null;
  final token = req.headers['authorization']
      ?.replaceFirst(RegExp(r'^[Bb]earer\s+'), '');
  return auth.resolveBearer(token);
}

/// Write an audit row + WS-broadcast it. Same shape as POST /audit so
/// clients render server-emitted entries identically to user-emitted ones.
Future<void> _emitAudit(
  AppDatabase db,
  WsHub? hub, {
  required String type,
  required String title,
  String? tableId,
  String? actorUserId,
}) async {
  final id = _uuid.v4();
  final at = DateTime.now();
  await db.into(db.auditEntries).insertOnConflictUpdate(
        AuditEntriesCompanion.insert(
          id: id,
          type: type,
          title: title,
          tableId: Value(tableId),
          at: at,
          actorUserId: Value(actorUserId),
        ),
      );
  final row = await (db.select(db.auditEntries)
        ..where((a) => a.id.equals(id)))
      .getSingleOrNull();
  if (row != null) hub?.broadcast(WsEventTypes.auditCreated, _auditJson(row));
}

/// Reject the mutation if applying it would leave zero enabled users
/// holding a role with [Capability.manageStaff]. [virtualUserId] is the user
/// whose nextRoleId/nextDisabled override the live row (null for non-user
/// mutations like role capability or role delete). [virtualRoleId] is the
/// role whose capability set is overridden (null otherwise).
Future<Response?> _guardLastAdmin(
  AppDatabase db, {
  String? virtualUserId,
  String? nextRoleId,
  bool? nextDisabled,
  bool deletingUserId = false,
  String? virtualRoleId,
  Set<String>? nextRoleCaps,
  bool deletingRoleId = false,
}) async {
  final roles = await db.select(db.roles).get();
  final adminRoleIds = <String>{};
  for (final r in roles) {
    if (deletingRoleId && r.id == virtualRoleId) continue;
    final caps = r.id == virtualRoleId
        ? (nextRoleCaps ?? const <String>{})
        : (jsonDecode(r.capabilitiesJson) as List)
            .cast<String>()
            .toSet();
    if (caps.contains(Capability.manageStaff.name)) adminRoleIds.add(r.id);
  }
  final users = await db.select(db.users).get();
  final hasAdmin = users.any((u) {
    if (deletingUserId && u.id == virtualUserId) return false;
    if (u.id == virtualUserId) {
      return !(nextDisabled ?? u.disabled) &&
          adminRoleIds.contains(nextRoleId ?? u.roleId);
    }
    return !u.disabled && adminRoleIds.contains(u.roleId);
  });
  if (hasAdmin) return null;
  return Response(409,
      body: jsonEncode({
        'code': 'last_admin',
        'message':
            'Must keep at least one active user with “Manage staff” capability',
      }),
      headers: {'content-type': 'application/json'});
}

Map<String, dynamic> _zoneJson(Zone z) => {
      'id': z.id,
      'name': z.name,
      'short': z.short,
      'colorHex': z.colorHex,
      'iconKey': z.iconKey,
    };

Router referenceRoutes(AppDatabase db, [WsHub? hub, ServerAuth? auth]) {
  final r = Router();

  r.get('/zones', (Request req) async {
    final rows = await (db.select(db.zones)
          ..orderBy([(z) => OrderingTerm.asc(z.sortOrder)]))
        .get();
    return _ok([for (final z in rows) _zoneJson(z)]);
  });

  // Admin floor management. Capability gated; broadcasts so every client
  // mirrors the change without polling.
  r.post('/zones', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final id = (body['id'] as String?) ?? _uuid.v4();
    // New zones sort after every existing zone so the order matches the
    // user's insertion intent without rewriting siblings.
    final maxOrder = await (db.selectOnly(db.zones)
          ..addColumns([db.zones.sortOrder.max()]))
        .getSingle();
    final next = (maxOrder.read(db.zones.sortOrder.max()) ?? -1) + 1;
    await db.into(db.zones).insertOnConflictUpdate(
          ZonesCompanion.insert(
            id: id,
            name: body['name'] as String,
            short: (body['short'] as String?) ?? _shortFor(body['name'] as String),
            colorHex: Value((body['colorHex'] as String?) ?? '#FF9233'),
            iconKey:
                Value((body['iconKey'] as String?) ?? 'table_restaurant'),
            sortOrder: Value(next),
          ),
        );
    final row = await (db.select(db.zones)..where((z) => z.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.internalServerError();
    hub?.broadcast(WsEventTypes.zoneCreated, _zoneJson(row));
    return _ok(_zoneJson(row));
  });

  r.patch('/zones/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    await (db.update(db.zones)..where((z) => z.id.equals(id))).write(
      ZonesCompanion(
        name: body.containsKey('name')
            ? Value(body['name'] as String)
            : const Value.absent(),
        short: body.containsKey('short')
            ? Value(body['short'] as String)
            : (body.containsKey('name')
                ? Value(_shortFor(body['name'] as String))
                : const Value.absent()),
        colorHex: body.containsKey('colorHex')
            ? Value(body['colorHex'] as String)
            : const Value.absent(),
        iconKey: body.containsKey('iconKey')
            ? Value(body['iconKey'] as String)
            : const Value.absent(),
      ),
    );
    final row = await (db.select(db.zones)..where((z) => z.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('zone not found');
    hub?.broadcast(WsEventTypes.zoneUpdated, _zoneJson(row));
    return _ok(_zoneJson(row));
  });

  r.delete('/zones/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    // Block delete while any table still references the zone; the floor
    // would otherwise leak orphan rows the UI cannot recover.
    final inUse = await (db.select(db.venueTables)
          ..where((t) => t.zoneId.equals(id)))
        .get();
    if (inUse.isNotEmpty) {
      return Response(409,
          body: jsonEncode({
            'code': 'zone_in_use',
            'message': '${inUse.length} table(s) still in zone',
          }),
          headers: {'content-type': 'application/json'});
    }
    await (db.delete(db.zones)..where((z) => z.id.equals(id))).go();
    hub?.broadcast(WsEventTypes.zoneDeleted, {'id': id});
    return _ok({'id': id});
  });

  r.get('/roles', (Request req) async {
    final rows = await db.select(db.roles).get();
    return _ok([for (final r in rows) _roleJson(r)]);
  });

  r.post('/roles', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final id = (body['id'] as String?) ?? _uuid.v4();
    await db.into(db.roles).insertOnConflictUpdate(RolesCompanion.insert(
          id: id,
          name: body['name'] as String,
          colorHex: Value((body['colorHex'] as String?) ?? '#C08AFF'),
          capabilitiesJson:
              Value(jsonEncode(body['capabilities'] ?? const <String>[])),
        ));
    final row = await (db.select(db.roles)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.internalServerError();
    hub?.broadcast(WsEventTypes.rolesUpdated, _roleJson(row));
    final actor = await _actor(req, db, auth);
    await _emitAudit(db, hub,
        type: AuditType.roleCreated.name,
        title: 'Created role ${row.name}',
        actorUserId: actor?.id);
    return _ok(_roleJson(row));
  });

  r.patch('/roles/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final prev = await (db.select(db.roles)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    if (prev == null) return Response.notFound('role not found');

    Set<String>? nextCapsKeys;
    if (body.containsKey('capabilities')) {
      nextCapsKeys = <String>{
        for (final c in (body['capabilities'] as List)) c as String,
      };
      final guard = await _guardLastAdmin(db,
          virtualRoleId: id, nextRoleCaps: nextCapsKeys);
      if (guard != null) return guard;
    }

    await (db.update(db.roles)..where((r) => r.id.equals(id))).write(
      RolesCompanion(
        name: body.containsKey('name')
            ? Value(body['name'] as String)
            : const Value.absent(),
        colorHex: body.containsKey('colorHex')
            ? Value(body['colorHex'] as String)
            : const Value.absent(),
        capabilitiesJson: body.containsKey('capabilities')
            ? Value(jsonEncode(body['capabilities']))
            : const Value.absent(),
      ),
    );
    final row = await (db.select(db.roles)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('role not found');
    hub?.broadcast(WsEventTypes.rolesUpdated, _roleJson(row));

    final actor = await _actor(req, db, auth);
    final actorId = actor?.id;
    if (body.containsKey('name') && prev.name != row.name) {
      await _emitAudit(db, hub,
          type: AuditType.roleRenamed.name,
          title: 'Role: ${prev.name} → ${row.name}',
          actorUserId: actorId);
    }
    if (body.containsKey('colorHex') && prev.colorHex != row.colorHex) {
      await _emitAudit(db, hub,
          type: AuditType.roleColorChanged.name,
          title: 'Color changed for ${row.name}',
          actorUserId: actorId);
    }
    if (nextCapsKeys != null) {
      final prevCaps = (jsonDecode(prev.capabilitiesJson) as List)
          .cast<String>()
          .toSet();
      final added = nextCapsKeys.difference(prevCaps).toList()..sort();
      final removed = prevCaps.difference(nextCapsKeys).toList()..sort();
      if (added.isNotEmpty || removed.isNotEmpty) {
        final parts = <String>[
          if (added.isNotEmpty) '+${added.join(",")}',
          if (removed.isNotEmpty) '-${removed.join(",")}',
        ];
        await _emitAudit(db, hub,
            type: AuditType.roleCapabilityChanged.name,
            title: '${row.name}: ${parts.join(" ")}',
            actorUserId: actorId);
      }
    }
    return _ok(_roleJson(row));
  });

  r.delete('/roles/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    final prev = await (db.select(db.roles)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    if (prev == null) return Response.notFound('role not found');
    // Block delete while any staff row still references the role; sign-in
    // would otherwise crash on role lookup.
    final inUse = await (db.select(db.users)
          ..where((u) => u.roleId.equals(id)))
        .get();
    if (inUse.isNotEmpty) {
      return Response(409,
          body: jsonEncode({
            'code': 'role_in_use',
            'message': '${inUse.length} staff still in role',
          }),
          headers: {'content-type': 'application/json'});
    }
    final guard = await _guardLastAdmin(db,
        virtualRoleId: id, deletingRoleId: true);
    if (guard != null) return guard;

    await (db.delete(db.roles)..where((r) => r.id.equals(id))).go();
    hub?.broadcast(WsEventTypes.rolesUpdated, {'deleted': id});

    final actor = await _actor(req, db, auth);
    await _emitAudit(db, hub,
        type: AuditType.roleDeleted.name,
        title: 'Deleted role ${prev.name}',
        actorUserId: actor?.id);
    return _ok({'id': id});
  });

  /// Public reference: never returns PIN material or hash.
  r.get('/staff', (Request req) async {
    final rows = await db.select(db.users).get();
    return _ok([for (final u in rows) _staffJson(u)]);
  });

  r.post('/staff', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final id = (body['id'] as String?) ?? _uuid.v4();
    final pin = body['pin'] as String?;
    if (pin == null || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      return Response(400,
          body: jsonEncode({'code': 'bad_pin', 'message': '6 digits required'}),
          headers: {'content-type': 'application/json'});
    }
    if (await _pinCollision(db, pin, exceptId: null)) {
      return _pinCollisionResponse();
    }
    await db.into(db.users).insertOnConflictUpdate(
          UsersCompanion.insert(
            id: id,
            name: body['name'] as String,
            initials: body['initials'] as String,
            roleId: body['roleId'] as String,
            zoneAssigned: Value(body['zoneAssigned'] as String?),
            pinHash: _hashPin(pin),
            disabled: Value((body['disabled'] as bool?) ?? false),
            avatarColorHex: Value((body['avatarColorHex'] as num?)?.toInt()),
          ),
        );
    final row = await (db.select(db.users)..where((u) => u.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.internalServerError();
    hub?.broadcast(WsEventTypes.staffCreated, _staffJson(row));
    final actor = await _actor(req, db, auth);
    await _emitAudit(db, hub,
        type: AuditType.staffCreated.name,
        title: 'Created ${row.name}',
        actorUserId: actor?.id);
    return _ok(_staffJson(row));
  });

  r.patch('/staff/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final prev = await (db.select(db.users)..where((u) => u.id.equals(id)))
        .getSingleOrNull();
    if (prev == null) return Response.notFound('user not found');

    final pin = body['pin'] as String?;
    if (pin != null) {
      if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
        return Response(400,
            body: jsonEncode(
                {'code': 'bad_pin', 'message': '6 digits required'}),
            headers: {'content-type': 'application/json'});
      }
      if (await _pinCollision(db, pin, exceptId: id)) {
        return _pinCollisionResponse();
      }
    }

    final nextRoleId =
        body.containsKey('roleId') ? body['roleId'] as String : prev.roleId;
    final nextDisabled = body.containsKey('disabled')
        ? body['disabled'] as bool
        : prev.disabled;
    if (body.containsKey('roleId') || body.containsKey('disabled')) {
      final guard = await _guardLastAdmin(db,
          virtualUserId: id,
          nextRoleId: nextRoleId,
          nextDisabled: nextDisabled);
      if (guard != null) return guard;
    }

    await (db.update(db.users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        name: body.containsKey('name')
            ? Value(body['name'] as String)
            : const Value.absent(),
        initials: body.containsKey('initials')
            ? Value(body['initials'] as String)
            : const Value.absent(),
        roleId: body.containsKey('roleId')
            ? Value(body['roleId'] as String)
            : const Value.absent(),
        zoneAssigned: body.containsKey('zoneAssigned')
            ? Value(body['zoneAssigned'] as String?)
            : const Value.absent(),
        disabled: body.containsKey('disabled')
            ? Value(body['disabled'] as bool)
            : const Value.absent(),
        pinHash:
            pin == null ? const Value.absent() : Value(_hashPin(pin)),
        avatarColorHex: body.containsKey('avatarColorHex')
            ? Value((body['avatarColorHex'] as num?)?.toInt())
            : const Value.absent(),
      ),
    );
    final row = await (db.select(db.users)..where((u) => u.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.notFound('user not found');
    hub?.broadcast(WsEventTypes.staffUpdated, _staffJson(row));

    final actor = await _actor(req, db, auth);
    final actorId = actor?.id;
    if (body.containsKey('roleId') && prev.roleId != row.roleId) {
      final oldRole = await _roleName(db, prev.roleId);
      final newRole = await _roleName(db, row.roleId);
      await _emitAudit(db, hub,
          type: AuditType.staffRoleChanged.name,
          title: '${row.name}: $oldRole → $newRole',
          actorUserId: actorId);
    }
    if (body.containsKey('disabled') && prev.disabled != row.disabled) {
      await _emitAudit(db, hub,
          type: row.disabled
              ? AuditType.staffDisabled.name
              : AuditType.staffEnabled.name,
          title: row.disabled ? 'Disabled ${row.name}' : 'Enabled ${row.name}',
          actorUserId: actorId);
    }
    if (pin != null) {
      final isReset = (body['reset'] as bool?) == true;
      await _emitAudit(db, hub,
          type: isReset
              ? AuditType.staffPinReset.name
              : AuditType.staffPinSet.name,
          title: isReset
              ? 'PIN reset for ${row.name}'
              : 'PIN changed for ${row.name}',
          actorUserId: actorId);
    }
    return _ok(_staffJson(row));
  });

  // ---------- audit ----------

  r.get('/audit', (Request req) async {
    final rows = await (db.select(db.auditEntries)
          ..orderBy([(a) => OrderingTerm.desc(a.at)]))
        .get();
    return _ok([for (final e in rows) _auditJson(e)]);
  });

  r.post('/audit', (Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final id = (body['id'] as String?) ?? _uuid.v4();
    final at = body['at'] != null
        ? DateTime.tryParse(body['at'] as String) ?? DateTime.now()
        : DateTime.now();
    await db.into(db.auditEntries).insertOnConflictUpdate(
          AuditEntriesCompanion.insert(
            id: id,
            type: body['type'] as String,
            title: body['title'] as String,
            tableId: Value(body['tableId'] as String?),
            at: at,
            approvedBy: Value(body['approvedBy'] as String?),
            reason: Value(body['reason'] as String?),
            actorUserId: Value(body['actorUserId'] as String?),
          ),
        );
    final row = await (db.select(db.auditEntries)
          ..where((a) => a.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return Response.internalServerError();
    hub?.broadcast(WsEventTypes.auditCreated, _auditJson(row));
    return _ok(_auditJson(row));
  });

  r.delete('/staff/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    // Never let the dedicated admin row be deleted via the API; it would
    // strand the email+password sign-in path on the next boot.
    if (id == 'admin') {
      return Response(409,
          body: jsonEncode(
              {'code': 'admin_locked', 'message': 'cannot delete admin'}),
          headers: {'content-type': 'application/json'});
    }
    final prev = await (db.select(db.users)..where((u) => u.id.equals(id)))
        .getSingleOrNull();
    if (prev == null) return Response.notFound('user not found');
    final guard = await _guardLastAdmin(db,
        virtualUserId: id, deletingUserId: true);
    if (guard != null) return guard;

    // Null any venue_tables.lastActorId references so the UI doesn't render
    // a dangling handler badge after delete; broadcast each affected table.
    final affected = await (db.select(db.venueTables)
          ..where((t) => t.lastActorId.equals(id)))
        .get();
    if (affected.isNotEmpty) {
      await (db.update(db.venueTables)
            ..where((t) => t.lastActorId.equals(id)))
          .write(const VenueTablesCompanion(lastActorId: Value(null)));
      for (final t in affected) {
        final row = await (db.select(db.venueTables)
              ..where((x) => x.id.equals(t.id)))
            .getSingleOrNull();
        if (row != null) {
          hub?.broadcast(WsEventTypes.tableUpdated, {
            'id': row.id,
            'zoneId': row.zoneId,
            'label': row.label,
            'pax': row.pax,
            'active': row.active,
            'status': row.status,
            'openAmount': row.openAmount,
            'readyCount': row.readyCount,
            'lastActorId': row.lastActorId,
          });
        }
      }
    }

    // Revoke any live sessions so a deleted user can't keep mutating with
    // a stale bearer token.
    await (db.delete(db.sessions)..where((s) => s.userId.equals(id))).go();
    await (db.delete(db.users)..where((u) => u.id.equals(id))).go();
    hub?.broadcast(WsEventTypes.staffDeleted, {'id': id});

    final actor = await _actor(req, db, auth);
    await _emitAudit(db, hub,
        type: AuditType.staffDeleted.name,
        title: 'Deleted ${prev.name}',
        actorUserId: actor?.id);
    return _ok({'id': id});
  });

  return r;
}

Map<String, dynamic> _roleJson(Role r) => {
      'id': r.id,
      'name': r.name,
      'colorHex': r.colorHex,
      'capabilities': jsonDecode(r.capabilitiesJson),
    };

Map<String, dynamic> _auditJson(AuditEntry e) => {
      'id': e.id,
      'type': e.type,
      'title': e.title,
      'tableId': e.tableId,
      'at': e.at.toIso8601String(),
      'approvedBy': e.approvedBy,
      'reason': e.reason,
      'actorUserId': e.actorUserId,
    };

Map<String, dynamic> _staffJson(User u) => {
      'id': u.id,
      'name': u.name,
      'initials': u.initials,
      'roleId': u.roleId,
      'zoneAssigned': u.zoneAssigned,
      'disabled': u.disabled,
      'avatarColorHex': u.avatarColorHex,
    };

Future<bool> _pinCollision(
  AppDatabase db,
  String pin, {
  required String? exceptId,
}) async {
  final hash = _hashPin(pin);
  final hit = await (db.select(db.users)
        ..where((u) => u.pinHash.equals(hash)))
      .get();
  return hit.any((u) => u.id != exceptId);
}

Response _pinCollisionResponse() => Response(409,
    body: jsonEncode(
        {'code': 'pin_in_use', 'message': 'PIN already in use'}),
    headers: {'content-type': 'application/json'});

Future<String> _roleName(AppDatabase db, String id) async {
  final r = await (db.select(db.roles)..where((x) => x.id.equals(id)))
      .getSingleOrNull();
  return r?.name ?? id;
}

String _shortFor(String name) {
  final n = name.trim();
  return n.length <= 3 ? n : n.substring(0, 3);
}

Response _ok(Object body) => Response.ok(jsonEncode(body),
    headers: {'content-type': 'application/json'});
