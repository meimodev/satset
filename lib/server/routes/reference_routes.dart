import 'dart:convert';
import 'package:satset/server/routes/tables_routes.dart' show tableRowToJson;
import 'package:satset/core/log/sat_log.dart';
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/audit_entry.dart'
    show AuditType, isAdminAuditType;
import 'package:satset/core/localization/audit_text.dart';
import 'package:satset/data/repositories/audit_repository.dart'
    show auditEntryFromJson;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/server/shift.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/audit_log.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/db/seed.dart';
import 'package:satset/server/db/seed_history.dart';
import 'package:satset/server/pin.dart' as pin_lib;
import 'package:satset/server/seed_job.dart';
import 'package:satset/server/ws_hub.dart';

/// One hasher for the whole server (ADR-0112). This file used to carry its
/// own copy of the digest, as did the seed.
String _hashPin(String pin) => pin_lib.hashPin(pin);

const _uuid = Uuid();

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

/// Resolve the bearer-token user for audit attribution. Returns null when
/// no auth helper is configured (server-mode boot before secret loaded).
Future<User?> _actor(Request req, AppDatabase db, ServerAuth auth) async {
  final token = req.headers['authorization']?.replaceFirst(
    RegExp(r'^[Bb]earer\s+'),
    '',
  );
  return auth.resolveBearer(token);
}

/// Write an audit row + WS-broadcast it. Thin shim over [writeAudit], kept
/// because this file names its `type` as a string rather than the enum.
Future<void> _emitAudit(
  AppDatabase db,
  WsHub? hub, {
  required String type,
  required AuditKind kind,
  Map<String, String> params = const {},
  String? tableId,
  String? actorUserId,
}) => writeAudit(
  db,
  hub: hub,
  type: AuditType.values.byName(type),
  kind: kind,
  params: params,
  tableId: tableId,
  actorUserId: actorUserId,
);

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
        : (jsonDecode(r.capabilitiesJson) as List).cast<String>().toSet();
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
  return Response(
    409,
    body: jsonEncode({
      'code': 'last_admin',
      'message':
          'Must keep at least one active user with “Manage staff” capability',
    }),
    headers: {'content-type': 'application/json'},
  );
}

/// Whether [roleId] currently carries `manageStaff` — i.e. an admin-level
/// role. Used to enforce "admin is Firebase-only": such a role may never be
/// assigned to a PIN user, nor newly created/granted, from the venue's own
/// staff screen (only a super admin makes admins). Since ADR-0077 it also
/// makes the role **immutable and undeletable** from that screen — the venue's
/// one admin cannot be edited out of its own capabilities. See ADR-0017.
Future<bool> _roleHasManageStaff(AppDatabase db, String roleId) async {
  final r = await (db.select(
    db.roles,
  )..where((x) => x.id.equals(roleId))).getSingleOrNull();
  if (r == null) return false;
  return (jsonDecode(r.capabilitiesJson) as List).cast<String>().contains(
    Capability.manageStaff.name,
  );
}

/// The `WHERE` for one venue-log request, built once and reused by the page,
/// the summary and the CSV. Sharing it is the point: three hand-rolled copies
/// is how a tile ends up counting rows the table below it does not show.
Future<Expression<bool> Function($AuditEntriesTable)> _venueAuditFilter(
  Request req,
  AppDatabase db,
  ServerAuth auth,
  Map<String, String> q,
) async {
  final from = DateTime.tryParse(q['from'] ?? '');
  final wanted = (q['type'] ?? '')
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();

  // Fails closed on an unresolvable caller: no session ⇒ no admin rows.
  final me = await _actor(req, db, auth);
  final canSeeAdmin = me != null && await _roleHasManageStaff(db, me.roleId);
  final hidden = canSeeAdmin
      ? const <String>{}
      : {for (final t in AuditType.values.where(isAdminAuditType)) t.name};

  // The parameter type is spelled out on purpose. Left to inference here it
  // lands as `dynamic`, every column comparison below becomes a dynamic call,
  // and `isBiggerOrEqualValue` — an extension, so not dispatchable at runtime
  // — throws NoSuchMethod on the first filtered request. It analyses clean
  // either way, which is what makes it worth a comment.
  return ($AuditEntriesTable a) {
    Expression<bool> e = const Constant(true);
    if (from != null) e = e & a.at.isBiggerOrEqualValue(from);
    if (wanted.isNotEmpty) e = e & a.type.isIn(wanted.toList());
    if (hidden.isNotEmpty) e = e & a.type.isNotIn(hidden.toList());
    return e;
  };
}

/// Per-type `{count, amount}` over the whole filtered window.
///
/// `amount` is a sum of magnitudes within one type (see the column doc), so it
/// is always meaningful and never mixes directions. Types that carry no money
/// sum to null and are reported as 0.
Future<Map<String, dynamic>> _venueAuditSummary(
  AppDatabase db,
  Expression<bool> Function($AuditEntriesTable) filter,
) async {
  final t = db.auditEntries;
  final count = t.id.count();
  final total = t.amountCents.sum();
  final q = db.selectOnly(t)
    ..addColumns([t.type, count, total])
    ..where(filter(t))
    ..groupBy([t.type]);
  final rows = await q.get();
  return {
    for (final r in rows)
      r.read(t.type)!: {
        'count': r.read(count) ?? 0,
        'amount': r.read(total) ?? 0,
      },
  };
}

/// Render rows, resolving attribution for pre-v43 entries that carry no
/// snapshot. Batched into two queries regardless of page size — a per-row join
/// would turn a 50-row page into 100 round trips.
Future<List<Map<String, dynamic>>> _auditJsonWithFallback(
  AppDatabase db,
  List<AuditEntry> rows,
) async {
  final needing = {
    for (final e in rows)
      if (e.actorName == null && e.actorUserId != null) e.actorUserId!,
  };
  if (needing.isEmpty) return [for (final e in rows) auditJson(e)];

  final users = await (db.select(
    db.users,
  )..where((u) => u.id.isIn(needing.toList()))).get();
  final roles =
      await (db.select(db.roles)..where(
            (r) => r.id.isIn(users.map((u) => u.roleId).toSet().toList()),
          ))
          .get();
  final roleById = {for (final r in roles) r.id: r};
  final byId = {for (final u in users) u.id: u};

  return [
    for (final e in rows)
      auditJson(
        e,
        fallbackName: byId[e.actorUserId]?.name,
        fallbackRoleName: roleById[byId[e.actorUserId]?.roleId]?.name,
      ),
  ];
}

({DateTime at, String id})? _decodeCursor(String? raw) {
  if (raw == null) return null;
  final i = raw.lastIndexOf('|');
  if (i <= 0) return null;
  final at = DateTime.tryParse(raw.substring(0, i));
  if (at == null) return null;
  return (at: at, id: raw.substring(i + 1));
}

String _csvCell(Object? v) {
  final s = '$v';
  if (!s.contains(RegExp(r'[",\n\r]'))) return s;
  return '"${s.replaceAll('"', '""')}"';
}

Response _adminRoleForbidden() => Response(
  403,
  body: jsonEncode({
    'code': 'admin_role_forbidden',
    'message': 'Admin-level roles can only be granted by a super admin',
  }),
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _zoneJson(Zone z) => {
  'id': z.id,
  'name': z.name,
  'short': z.short,
  'colorHex': z.colorHex,
  'iconKey': z.iconKey,
};

Router referenceRoutes(AppDatabase db, WsHub? hub, ServerAuth auth) {
  final r = Router();

  r.get('/zones', (Request req) async {
    final rows = await (db.select(
      db.zones,
    )..orderBy([(z) => OrderingTerm.asc(z.sortOrder)])).get();
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
    final maxOrder = await (db.selectOnly(
      db.zones,
    )..addColumns([db.zones.sortOrder.max()])).getSingle();
    final next = (maxOrder.read(db.zones.sortOrder.max()) ?? -1) + 1;
    await db
        .into(db.zones)
        .insertOnConflictUpdate(
          ZonesCompanion.insert(
            id: id,
            name: body['name'] as String,
            short:
                (body['short'] as String?) ?? _shortFor(body['name'] as String),
            colorHex: Value((body['colorHex'] as String?) ?? '#FF9233'),
            iconKey: Value((body['iconKey'] as String?) ?? 'table_restaurant'),
            sortOrder: Value(next),
          ),
        );
    final row = await (db.select(
      db.zones,
    )..where((z) => z.id.equals(id))).getSingleOrNull();
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
    final row = await (db.select(
      db.zones,
    )..where((z) => z.id.equals(id))).getSingleOrNull();
    if (row == null) return Response.notFound('zone not found');
    hub?.broadcast(WsEventTypes.zoneUpdated, _zoneJson(row));
    return _ok(_zoneJson(row));
  });

  r.delete('/zones/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.editSettings);
    if (denied != null) return denied;
    // Block delete while any table still references the zone; the floor
    // would otherwise leak orphan rows the UI cannot recover.
    final inUse = await (db.select(
      db.venueTables,
    )..where((t) => t.zoneId.equals(id))).get();
    if (inUse.isNotEmpty) {
      return Response(
        409,
        body: jsonEncode({
          'code': 'zone_in_use',
          'message': '${inUse.length} table(s) still in zone',
        }),
        headers: {'content-type': 'application/json'},
      );
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
    // No new admin-level roles: a local admin can't mint a custom role that
    // carries manageStaff and assign it as a backdoor. See ADR-0017.
    final newCaps = ((body['capabilities'] as List?) ?? const [])
        .cast<String>();
    if (newCaps.contains(Capability.manageStaff.name)) {
      return _adminRoleForbidden();
    }
    await db
        .into(db.roles)
        .insertOnConflictUpdate(
          RolesCompanion.insert(
            id: id,
            name: body['name'] as String,
            colorHex: Value((body['colorHex'] as String?) ?? '#C08AFF'),
            capabilitiesJson: Value(
              jsonEncode(body['capabilities'] ?? const <String>[]),
            ),
          ),
        );
    final row = await (db.select(
      db.roles,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null) return Response.internalServerError();
    hub?.broadcast(WsEventTypes.rolesUpdated, _roleJson(row));
    final actor = await _actor(req, db, auth);
    await _emitAudit(
      db,
      hub,
      type: AuditType.roleCreated.name,
      kind: AuditKind.roleCreated,
      params: {'name': row.name},
      actorUserId: actor?.id,
    );
    return _ok(_roleJson(row));
  });

  r.patch('/roles/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final prev = await (db.select(
      db.roles,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (prev == null) return Response.notFound('role not found');

    // An admin-level role is infrastructure, not a role this screen owns: it
    // belongs to the venue's one Firebase admin (ADR-0077). Immutable from here
    // in **both** directions. Blocking only the grant left the far worse edit
    // open — stripping `editSettings` or `viewReports` off the admin role locks
    // the venue's only admin out of the screens that could put them back, and
    // admin is Firebase-only, so there is no second admin role to repair it
    // from. Refuse the whole PATCH, name and colour included, so the server
    // agrees with the locked row the staff screen renders.
    if (await _roleHasManageStaff(db, id)) {
      return _adminRoleForbidden();
    }

    Set<String>? nextCapsKeys;
    if (body.containsKey('capabilities')) {
      nextCapsKeys = <String>{
        for (final c in (body['capabilities'] as List)) c as String,
      };
      // Can't newly grant manageStaff to a role that lacked it — that would mint
      // a local admin as a backdoor. See ADR-0017.
      if (nextCapsKeys.contains(Capability.manageStaff.name)) {
        return _adminRoleForbidden();
      }
      final guard = await _guardLastAdmin(
        db,
        virtualRoleId: id,
        nextRoleCaps: nextCapsKeys,
      );
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
    final row = await (db.select(
      db.roles,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null) return Response.notFound('role not found');
    hub?.broadcast(WsEventTypes.rolesUpdated, _roleJson(row));

    final actor = await _actor(req, db, auth);
    final actorId = actor?.id;
    if (body.containsKey('name') && prev.name != row.name) {
      await _emitAudit(
        db,
        hub,
        type: AuditType.roleRenamed.name,
        kind: AuditKind.roleRenamed,
        params: {'from': prev.name, 'to': row.name},
        actorUserId: actorId,
      );
    }
    if (body.containsKey('colorHex') && prev.colorHex != row.colorHex) {
      await _emitAudit(
        db,
        hub,
        type: AuditType.roleColorChanged.name,
        kind: AuditKind.roleColorChanged,
        params: {'name': row.name},
        actorUserId: actorId,
      );
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
        await _emitAudit(
          db,
          hub,
          type: AuditType.roleCapabilityChanged.name,
          kind: AuditKind.roleCapabilityChanged,
          params: {'name': row.name, 'changes': parts.join(' ')},
          actorUserId: actorId,
        );
      }
    }
    return _ok(_roleJson(row));
  });

  r.delete('/roles/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    final prev = await (db.select(
      db.roles,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (prev == null) return Response.notFound('role not found');
    // Same lock as PATCH: the admin role is the venue's Firebase admin's, and
    // deleting it would strand that account's user row on a role lookup that
    // returns nothing. See ADR-0077.
    if (await _roleHasManageStaff(db, id)) {
      return _adminRoleForbidden();
    }
    // Block delete while any staff row still references the role; sign-in
    // would otherwise crash on role lookup.
    final inUse = await (db.select(
      db.users,
    )..where((u) => u.roleId.equals(id))).get();
    if (inUse.isNotEmpty) {
      return Response(
        409,
        body: jsonEncode({
          'code': 'role_in_use',
          'message': '${inUse.length} staff still in role',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    final guard = await _guardLastAdmin(
      db,
      virtualRoleId: id,
      deletingRoleId: true,
    );
    if (guard != null) return guard;

    await (db.delete(db.roles)..where((r) => r.id.equals(id))).go();
    hub?.broadcast(WsEventTypes.rolesUpdated, {'deleted': id});

    final actor = await _actor(req, db, auth);
    await _emitAudit(
      db,
      hub,
      type: AuditType.roleDeleted.name,
      kind: AuditKind.roleDeleted,
      params: {'name': prev.name},
      actorUserId: actor?.id,
    );
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
      return Response(
        400,
        body: jsonEncode({'code': 'bad_pin', 'message': '6 digits required'}),
        headers: {'content-type': 'application/json'},
      );
    }
    if (await _pinCollision(db, pin, exceptId: null)) {
      return _pinCollisionResponse();
    }
    // Admin is Firebase-only: never mint a PIN user holding an admin-level
    // (manageStaff) role from the staff screen. See ADR-0017.
    if (await _roleHasManageStaff(db, body['roleId'] as String)) {
      return _adminRoleForbidden();
    }
    await db
        .into(db.users)
        .insertOnConflictUpdate(
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
    final row = await (db.select(
      db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
    if (row == null) return Response.internalServerError();
    hub?.broadcast(WsEventTypes.staffCreated, _staffJson(row));
    final actor = await _actor(req, db, auth);
    await _emitAudit(
      db,
      hub,
      type: AuditType.staffCreated.name,
      kind: AuditKind.staffCreated,
      params: {'name': row.name},
      actorUserId: actor?.id,
    );
    return _ok(_staffJson(row));
  });

  r.patch('/staff/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final prev = await (db.select(
      db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
    if (prev == null) return Response.notFound('user not found');

    final pin = body['pin'] as String?;
    if (pin != null) {
      if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
        return Response(
          400,
          body: jsonEncode({'code': 'bad_pin', 'message': '6 digits required'}),
          headers: {'content-type': 'application/json'},
        );
      }
      if (await _pinCollision(db, pin, exceptId: id)) {
        return _pinCollisionResponse();
      }
    }

    final nextRoleId = body.containsKey('roleId')
        ? body['roleId'] as String
        : prev.roleId;
    final nextDisabled = body.containsKey('disabled')
        ? body['disabled'] as bool
        : prev.disabled;
    // Block re-assigning a PIN user *into* an admin-level (manageStaff) role
    // (admin is Firebase-only). A no-op keep of an already-admin row is
    // allowed so other fields stay editable. See ADR-0017.
    if (body.containsKey('roleId') &&
        nextRoleId != prev.roleId &&
        await _roleHasManageStaff(db, nextRoleId)) {
      return _adminRoleForbidden();
    }
    if (body.containsKey('roleId') || body.containsKey('disabled')) {
      final guard = await _guardLastAdmin(
        db,
        virtualUserId: id,
        nextRoleId: nextRoleId,
        nextDisabled: nextDisabled,
      );
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
        pinHash: pin == null ? const Value.absent() : Value(_hashPin(pin)),
        avatarColorHex: body.containsKey('avatarColorHex')
            ? Value((body['avatarColorHex'] as num?)?.toInt())
            : const Value.absent(),
      ),
    );
    final row = await (db.select(
      db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
    if (row == null) return Response.notFound('user not found');
    hub?.broadcast(WsEventTypes.staffUpdated, _staffJson(row));

    final actor = await _actor(req, db, auth);
    final actorId = actor?.id;
    if (body.containsKey('roleId') && prev.roleId != row.roleId) {
      final oldRole = await _roleName(db, prev.roleId);
      final newRole = await _roleName(db, row.roleId);
      await _emitAudit(
        db,
        hub,
        type: AuditType.staffRoleChanged.name,
        kind: AuditKind.staffRoleChanged,
        params: {'name': row.name, 'from': oldRole, 'to': newRole},
        actorUserId: actorId,
      );
    }
    if (body.containsKey('disabled') && prev.disabled != row.disabled) {
      if (row.disabled) {
        // Disabling is meant to take the device out of service, so the token
        // already on it has to go. Without this the bearer stays valid until
        // it expires — up to twelve hours of a "disabled" member ordering.
        await auth.revokeAllFor(row.id);
      }
      await _emitAudit(
        db,
        hub,
        type: row.disabled
            ? AuditType.staffDisabled.name
            : AuditType.staffEnabled.name,
        kind: row.disabled ? AuditKind.staffDisabled : AuditKind.staffEnabled,
        params: {'name': row.name},
        actorUserId: actorId,
      );
    }
    if (pin != null) {
      final isReset = (body['reset'] as bool?) == true;
      await _emitAudit(
        db,
        hub,
        type: isReset
            ? AuditType.staffPinReset.name
            : AuditType.staffPinSet.name,
        kind: isReset ? AuditKind.staffPinReset : AuditKind.staffPinSet,
        params: {'name': row.name},
        actorUserId: actorId,
      );
    }
    return _ok(_staffJson(row));
  });

  // ---------- audit ----------

  /// **Your own** audit rows for **this business day** — the feed and the
  /// integrity counters behind the "Saya" tab.
  ///
  /// Scoped from the bearer, never from a query parameter: the caller cannot
  /// name a user, so there is no way to read a colleague's log. Bounded by the
  /// business day rather than a row limit, so the counters can never be
  /// silently truncated — "3 pembatalan" means three, not three among the rows
  /// that fit in the page.
  ///
  /// The window was the *shift* until ADR-0097 made every sign-out end one. A
  /// waiter handing a shared handset over now starts a fresh shift several times
  /// a night, and scoping to it would blank this list on each handover. The
  /// question the screen answers — "what have I done tonight" — is a business-day
  /// question; the shift is the attendance unit, and it lives in Laporan.
  ///
  /// Fails **closed**. No session yields an empty list: defaulting to the
  /// venue-wide log would leak every colleague's voids onto a personal screen.
  ///
  /// There is deliberately no `POST /audit`. Audit rows are written only by the
  /// server paths that perform the audited act, which stamp `actorUserId` from
  /// the JWT — attribution for voids and comps is evidence (ADR-0006), so it is
  /// never taken from a client-supplied field.
  r.get('/audit', (Request req) async {
    final me = await _actor(req, db, auth);
    if (me == null) return _ok(const []);
    final settings = await (db.select(
      db.venueSettings,
    )..where((x) => x.id.equals('default'))).getSingleOrNull();
    final since = businessDayStart(
      SatClock.now(),
      settings?.businessDayStartHour ?? 4,
    );
    final rows =
        await (db.select(db.auditEntries)
              ..where((a) => a.actorUserId.equals(me.id))
              ..where((a) => a.at.isBiggerOrEqualValue(since))
              ..orderBy([(a) => OrderingTerm.desc(a.at)]))
            .get();
    return _ok([for (final e in rows) auditJson(e)]);
  });

  /// The **venue-wide** integrity log (ADR-0072) — every actor, paged back
  /// through history. Deliberately a separate route from `/audit` above rather
  /// than a parameter on it: that one's whole contract is that scope comes from
  /// the bearer and cannot be widened by a query string, and this one is a
  /// different product behind a different permission.
  ///
  /// `viewReports` reads it. Admin rows (staff and role edits) additionally
  /// require `manageStaff` — a user who can read shift figures has no business
  /// in the venue's personnel history — and they are filtered out of the
  /// summary as well, so the tiles never count rows the table cannot show.
  ///
  /// Paged by keyset on `(at, id)`, never by offset: rows arrive at the head
  /// while a manager reads, and an offset window would silently re-show or skip
  /// a void. `id` breaks ties because a burst of voids lands in the same
  /// millisecond and `at` alone would drop rows at the page boundary.
  ///
  /// `summary` rides page one only, computed over the **whole filtered
  /// window** rather than the loaded page — a tile reading "3 pembatalan" has
  /// to mean three in the venue, not three in the rows that fit.
  r.get('/audit/venue', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.viewReports);
    if (denied != null) return denied;
    final q = req.requestedUri.queryParameters;
    final filter = await _venueAuditFilter(req, db, auth, q);
    final limit = (int.tryParse(q['limit'] ?? '') ?? 50).clamp(1, 200);

    final sel = db.select(db.auditEntries)
      ..where(filter)
      ..orderBy([
        (a) => OrderingTerm.desc(a.at),
        (a) => OrderingTerm.desc(a.id),
      ])
      // One extra row is the cheapest way to know whether another page exists
      // without a second COUNT over the same window.
      ..limit(limit + 1);
    final cursor = _decodeCursor(q['before']);
    if (cursor != null) {
      sel.where(
        (a) =>
            a.at.isSmallerThanValue(cursor.at) |
            (a.at.equals(cursor.at) & a.id.isSmallerThanValue(cursor.id)),
      );
    }
    final rows = await sel.get();
    final hasMore = rows.length > limit;
    final page = hasMore ? rows.sublist(0, limit) : rows;

    return _ok({
      'items': await _auditJsonWithFallback(db, page),
      'nextCursor': hasMore && page.isNotEmpty
          ? '${page.last.at.toIso8601String()}|${page.last.id}'
          : null,
      if (q['before'] == null) 'summary': await _venueAuditSummary(db, filter),
    });
  });

  /// Same window, same filters, **unpaged** — an audit export that stopped at
  /// the loaded page would be a truncated record wearing the word "complete".
  /// Rendered server-side for that reason: the client never owns the full set.
  r.get('/audit/venue.csv', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.viewReports);
    if (denied != null) return denied;
    final q = req.requestedUri.queryParameters;
    final filter = await _venueAuditFilter(req, db, auth, q);
    final rows =
        await (db.select(db.auditEntries)
              ..where(filter)
              ..orderBy([
                (a) => OrderingTerm.desc(a.at),
                (a) => OrderingTerm.desc(a.id),
              ]))
            .get();
    final json = await _auditJsonWithFallback(db, rows);
    final buf = StringBuffer()..writeln(satL10n.expAuditCsvHeader);
    for (final e in json) {
      buf.writeln(
        [
          e['at'],
          e['type'],
          e['actorName'] ?? '',
          e['actorRoleName'] ?? '',
          // Composed here rather than read off `title`, so the CSV follows the
          // exporting device's language like every other export (ADR-0083).
          // Pre-ADR-0085 rows have no kind and fall back to their sentence.
          auditText(satL10n, auditEntryFromJson(e)),
          e['tableId'] ?? '',
          e['amountCents']?.toString() ?? '',
          e['reason'] ?? '',
          e['approvedBy'] ?? '',
        ].map(_csvCell).join(','),
      );
    }
    return Response.ok(
      buf.toString(),
      headers: {
        'content-type': 'text/csv; charset=utf-8',
        'content-disposition': 'attachment; filename="audit.csv"',
      },
    );
  });

  r.delete('/staff/<id>', (Request req, String id) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    // Never let the dedicated admin row be deleted via the API; it would
    // strand the email+password sign-in path on the next boot.
    if (id == 'admin') {
      return Response(
        409,
        body: jsonEncode({
          'code': 'admin_locked',
          'message': 'cannot delete admin',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    final prev = await (db.select(
      db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
    if (prev == null) return Response.notFound('user not found');
    final guard = await _guardLastAdmin(
      db,
      virtualUserId: id,
      deletingUserId: true,
    );
    if (guard != null) return guard;

    // Null any venue_tables.lastActorId references so the UI doesn't render
    // a dangling handler badge after delete; broadcast each affected table.
    final affected = await (db.select(
      db.venueTables,
    )..where((t) => t.lastActorId.equals(id))).get();
    if (affected.isNotEmpty) {
      await (db.update(db.venueTables)..where((t) => t.lastActorId.equals(id)))
          .write(const VenueTablesCompanion(lastActorId: Value(null)));
      for (final t in affected) {
        final row = await (db.select(
          db.venueTables,
        )..where((x) => x.id.equals(t.id))).getSingleOrNull();
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
    await _emitAudit(
      db,
      hub,
      type: AuditType.staffDeleted.name,
      kind: AuditKind.staffDeleted,
      params: {'name': prev.name},
      actorUserId: actor?.id,
    );
    return _ok({'id': id});
  });

  // ---------- sample data: one seed, one prompt (ADR-0073) ----------

  /// Everything the Venue Hub prompt needs to decide which of its four states
  /// to render: offer, running, interrupted, or nothing at all.
  r.get('/seed/state', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    final (done, total) = await SeedJob.progressOf(db);
    return _ok({
      'needsSeed': await needsGenericSeed(db),
      // The has-not-traded guard (ADR-0052 §3). Self-tripping once the sample
      // month is written, so a re-seed requires a clear first — correct, not
      // incidental.
      'canSeed': await canSeedSample(db),
      'hasSampleData': await hasSampleData(db),
      // A job that started and never finished: the prompt must offer only
      // clear-and-retry, because partial history reports a loaded venue that
      // is quietly short (ADR-0053 §9).
      'seedIncomplete': await SeedJob.isIncomplete(db),
      // Written on skip or on a completed seed, never on tap — an interrupted
      // job means the question went unanswered and the prompt fires again.
      'promptAnswered': await SeedJob.promptAnswered(db),
      'daysDone': done,
      'daysTotal': total,
    });
  });

  /// Load the sample dataset: 4 zones / 20 tables / the generic menu / 4 staff,
  /// plus a fabricated month of settled service and its audit trail.
  ///
  /// 202 and run in the background: ~1500 bills through the production order
  /// path takes minutes, and a blocked call gives no way to tell slow from
  /// wedged (ADR-0053 §8). Progress arrives on `seed.progress`.
  r.post('/seed/generic', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    if (!await canSeedSample(db)) {
      return Response(
        409,
        body: jsonEncode({
          'code': 'seedRefused',
          'message':
              'Venue sudah punya riwayat pesanan. Contoh data tidak dimuat.',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    await SeedJob.begin(db, daysTotal: historyDays);
    unawaited(
      Future(() async {
        try {
          await seedSampleVenue(
            db,
            hub: hub,
            onDay: (done, total) {
              unawaited(SeedJob.progress(db, done));
              hub?.broadcast(WsEventTypes.seedProgress, {
                'daysDone': done,
                'daysTotal': total,
              });
            },
          );
          // Only now is the prompt answered (ADR-0073).
          await SeedJob.markComplete(db);
          await _broadcastSeeded(db, hub);
          hub?.broadcast(WsEventTypes.seedProgress, const {'done': true});
        } catch (e, st) {
          SatLog.err('sample seed', e, st);
          // The incomplete marker stays set and the prompt stays unanswered,
          // so the dialog returns offering clear-and-retry.
          hub?.broadcast(WsEventTypes.seedProgress, const {'failed': true});
        }
      }),
    );
    final actor = await _actor(req, db, auth);
    await _emitAudit(
      db,
      hub,
      type: AuditType.staffCreated.name,
      kind: AuditKind.sampleDataLoaded,
      actorUserId: actor?.id,
    );
    return Response(
      202,
      body: jsonEncode({'started': true}),
      headers: {'content-type': 'application/json'},
    );
  });

  /// Remove every fabricated transactional row, leaving zones, tables, menu,
  /// staff and bahan standing. Deletes by tag only (ADR-0073).
  r.post('/seed/clear', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    await clearSampleData(db, hub: hub);
    await SeedJob.clear(db);
    await _broadcastSeeded(db, hub);
    return _ok({'ok': true});
  });

  /// The admin declined the first-run prompt. It never fires again; Admin →
  /// Settings stays as the deliberate way back in (ADR-0073).
  r.post('/seed/skip', (Request req) async {
    final denied = await _requireCap(req, db, auth, Capability.manageStaff);
    if (denied != null) return denied;
    await SeedJob.markSkipped(db);
    return _ok({'ok': true});
  });

  return r;
}

/// Nudge every paired device to re-pull after a bulk seed/reset — the rows go
/// in under the repositories, so without this they keep showing stale caches.
Future<void> _broadcastSeeded(AppDatabase db, WsHub? hub) async {
  if (hub == null) return;
  hub.broadcast(WsEventTypes.menuUpdated, {'seeded': true});
  hub.broadcast(WsEventTypes.rolesUpdated, {'seeded': true});
  final zones = await (db.select(
    db.zones,
  )..orderBy([(z) => OrderingTerm.asc(z.sortOrder)])).get();
  for (final z in zones) {
    hub.broadcast(WsEventTypes.zoneCreated, _zoneJson(z));
  }
  final tables = await db.select(db.venueTables).get();
  for (final t in tables) {
    hub.broadcast(WsEventTypes.tableCreated, tableRowToJson(t));
  }
}

Map<String, dynamic> _roleJson(Role r) => {
  'id': r.id,
  'name': r.name,
  'colorHex': r.colorHex,
  'capabilities': jsonDecode(r.capabilitiesJson),
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
  // Disabled staff count: their PIN is still theirs, and handing it to
  // somebody else would make the audit trail ambiguous the day they come
  // back. A salted hash cannot be matched, so this verifies (ADR-0112).
  final hit = await pin_lib.usersForPin(db, pin, onlyEnabled: false);
  return hit.any((u) => u.id != exceptId);
}

Response _pinCollisionResponse() => Response(
  409,
  body: jsonEncode({'code': 'pin_in_use', 'message': 'PIN already in use'}),
  headers: {'content-type': 'application/json'},
);

Future<String> _roleName(AppDatabase db, String id) async {
  final r = await (db.select(
    db.roles,
  )..where((x) => x.id.equals(id))).getSingleOrNull();
  return r?.name ?? id;
}

String _shortFor(String name) {
  final n = name.trim();
  return n.length <= 3 ? n : n.substring(0, 3);
}

Response _ok(Object body) => Response.ok(
  jsonEncode(body),
  headers: {'content-type': 'application/json'},
);
