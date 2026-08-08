import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/localization/audit_text.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/models/ws_event_dto.dart';
// Prefixed: Drift generates its own `AuditEntry` for the row, and the two are
// different things — one is the table, one is what a reader sees.
import 'package:satset/domain/models/audit_entry.dart'
    as domain
    show AuditEntry;
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

/// Money inside an audit parameter, pre-formatted.
///
/// Rupiah never localises (ADR-0084), so the value is rendered once at write
/// time and stored as text — the reader's language changes the sentence around
/// it, never the number. Mirrors the client's `formatIDR`
/// (`lib/ui/core/design/format.dart`).
///
/// One formatter, because there were two: the settlement routes wrote a bare
/// `Rp13986` while the ticket routes wrote `Rp. 13.986`, and the venue log
/// showed both in the same column.
final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp. ',
  decimalDigits: 0,
);

String auditRupiah(int cents) => _rupiah.format(cents);

/// The one place an audit row is written.
///
/// Four routes used to hand-roll this insert, and three of them hand-rolled
/// the broadcast JSON too, which is how `amountCents` and the actor snapshot
/// would have quietly reached three call sites out of four. Everything that
/// audits an act goes through [writeAudit]; everything that reads one renders
/// [auditJson].
///
/// See docs/adr/0072-venue-audit-log.md.
Future<AuditEntry?> writeAudit(
  AppDatabase db, {
  required AuditType type,
  required AuditKind kind,
  Map<String, String> params = const {},
  String? tableId,
  String? actorUserId,
  String? reason,
  String? approvedBy,
  int? amountCents,
  WsHub? hub,

  /// The payment this row can show a **proof photo** for (ADR-0086). Pass it
  /// only when the payment actually carries an image — a cash tender and a
  /// refund pass nothing, and the reader treats non-null as "there is a photo"
  /// rather than joining to find out.
  String? paymentId,

  /// Stamp this instead of "now". The sample seed replays a month through the
  /// audit writer and each row belongs at its own moment; dragging `SatClock`
  /// through the month would swing the running app's clock instead. Production
  /// callers pass nothing. Mirrors `submitOrder`'s override (ADR-0073).
  DateTime? at,

  /// Prefix the generated id, so a seeded row is deletable by tag and a real
  /// row written afterward is not. Production callers pass nothing.
  String? idPrefix,
}) async {
  final id = '${idPrefix ?? ''}${_uuid.v4()}';
  final actor = await resolveActor(db, actorUserId);
  final entry = domain.AuditEntry(
    id: id,
    type: type,
    title: '',
    tableId: tableId ?? '',
    when: '',
    kind: kind.name,
    params: params,
  );
  await db
      .into(db.auditEntries)
      .insertOnConflictUpdate(
        AuditEntriesCompanion.insert(
          id: id,
          type: type.name,
          // A frozen rendering in this device's language, for the fallback path
          // and for anyone reading the table with a SQL client. Never the thing
          // a screen displays — see the column doc.
          title: auditText(satL10n, entry),
          kind: Value(kind.name),
          params: Value(jsonEncode(params)),
          tableId: Value(tableId),
          at: at ?? SatClock.now(),
          reason: Value(reason),
          approvedBy: Value(approvedBy),
          actorUserId: Value(actorUserId),
          amountCents: Value(amountCents),
          actorName: Value(actor?.name),
          actorRoleName: Value(actor?.roleName),
          paymentId: Value(paymentId),
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
/// [fallbackName] / [fallbackRoleName] fill in for rows written before v43,
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
  'kind': e.kind,
  // Non-null ⇒ this row has a proof photo to show (ADR-0086). The bytes never
  // ride this JSON; the client fetches them per row, on tap.
  'paymentId': e.paymentId,
  // Sent decoded, not as a JSON string: the client would only have to parse it
  // again, and a nested-encoded blob is the kind of thing that survives one
  // release and breaks on the next.
  'params': e.params == null
      ? const <String, String>{}
      : (jsonDecode(e.params!) as Map).cast<String, dynamic>(),
};
