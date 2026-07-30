import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

/// The one place an audit row is written.
///
/// Four routes used to hand-roll this insert, and three of them hand-rolled
/// the broadcast JSON too, which is how `amountCents` and the actor snapshot
/// would have quietly reached three call sites out of four. Everything that
/// audits an act goes through [writeAudit]; everything that reads one renders
/// [auditJson].
///
/// See docs/adr/0067-venue-audit-log.md.
Future<AuditEntry?> writeAudit(
  AppDatabase db, {
  required AuditType type,
  required String title,
  String? tableId,
  String? actorUserId,
  String? reason,
  String? approvedBy,
  int? amountCents,
  WsHub? hub,
}) async {
  final id = _uuid.v4();
  final actor = await resolveActor(db, actorUserId);
  await db
      .into(db.auditEntries)
      .insertOnConflictUpdate(
        AuditEntriesCompanion.insert(
          id: id,
          type: type.name,
          title: title,
          tableId: Value(tableId),
          at: SatClock.now(),
          reason: Value(reason),
          approvedBy: Value(approvedBy),
          actorUserId: Value(actorUserId),
          amountCents: Value(amountCents),
          actorName: Value(actor?.name),
          actorRoleName: Value(actor?.roleName),
        ),
      );
  final row = await (db.select(
    db.auditEntries,
  )..where((a) => a.id.equals(id))).getSingleOrNull();
  if (row != null) hub?.broadcast(WsEventTypes.auditCreated, auditJson(row));
  return row;
}

/// Who a user is *right now* — read once at write time and frozen into the
/// row. Never call this to decorate a read: resolving attribution live would
/// let a later rename or a `staffDeleted` rewrite history.
Future<({String name, String? roleName})?> resolveActor(
  AppDatabase db,
  String? userId,
) async {
  if (userId == null) return null;
  final user = await (db.select(
    db.users,
  )..where((u) => u.id.equals(userId))).getSingleOrNull();
  if (user == null) return null;
  final role = await (db.select(
    db.roles,
  )..where((r) => r.id.equals(user.roleId))).getSingleOrNull();
  return (name: user.name, roleName: role?.name);
}

/// Wire shape for one audit row, shared by the personal feed, the venue log
/// and the WebSocket fan-out.
///
/// [fallbackName] / [fallbackRoleName] fill in for rows written before v42,
/// which carry no snapshot. The read path resolves those with a live join and
/// passes them here; a row whose actor has since been deleted keeps a null
/// name and renders as "Sistem" client-side.
Map<String, dynamic> auditJson(
  AuditEntry e, {
  String? fallbackName,
  String? fallbackRoleName,
}) => {
  'id': e.id,
  'type': e.type,
  'title': e.title,
  'tableId': e.tableId,
  'at': e.at.toIso8601String(),
  'approvedBy': e.approvedBy,
  'reason': e.reason,
  'actorUserId': e.actorUserId,
  'amountCents': e.amountCents,
  'actorName': e.actorName ?? fallbackName,
  'actorRoleName': e.actorRoleName ?? fallbackRoleName,
};
