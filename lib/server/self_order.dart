/// **[[Pesan mandiri]]** — the guest self-order writer (ADR-0105). Every write
/// to `guest_sessions`, `guest_orders` and `guest_order_lines` goes through
/// here, for the reason `writeAudit`, `cash.dart` and `members.dart` exist: a
/// rule enforced in one route reaches three call sites out of four.
///
/// Three invariants live in this file and nowhere else:
///
/// - **A guest order is an intent, never a ticket.** Nothing reaches the
///   kitchen, the bill or a report until [acceptGuestOrder] runs the ordinary
///   `submitOrder` path. This is the whole of ADR-0105 — the reason ADR-0080's
///   `TicketStatus.pendingReview` is not coming back.
/// - **The guest is untrusted, so the server prices the order.** Whatever
///   `unitPrice` the phone sends is discarded and recomputed from
///   `menu_items`. The staff order path may trust its caller; this one holds a
///   trust boundary.
/// - **A decision is once.** Accept, reject and cancel all re-read `status`
///   inside `db.transaction` and refuse anything not `pending`, so two waiters
///   tapping Terima on two tablets fire one order, not two (ADR-0100's rule,
///   applied to a state machine rather than a balance).
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/server/modules.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/server/audit_log.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/guest/guest_code.dart';
import 'package:satset/server/routes/tickets_routes.dart'
    show broadcastSubmitted, submitOrder;
import 'package:satset/server/shift.dart' show businessDayStart;
import 'package:satset/server/stock.dart' show deriveStockFlags;
import 'package:satset/server/ws_hub.dart';

const _uuid = Uuid();

/// Thrown for a refusal a person needs to act on. The [code] crosses the wire
/// and the words are composed client-side (ADR-0085).
class SelfOrderException implements Exception {
  final String code;
  const SelfOrderException(this.code);
  @override
  String toString() => 'SelfOrderException($code)';
}

// ---------------------------------------------------------------------------
// settings
// ---------------------------------------------------------------------------

Future<VenueSetting?> _settings(AppDatabase db) => (db.select(
  db.venueSettings,
)..where((x) => x.id.equals('default'))).getSingleOrNull();

/// The venue's guest-facing rules, resolved once per request.
typedef GuestRules = ({
  bool enabled,
  bool noteEnabled,
  int hoursStartMin,
  int hoursEndMin,
  int maxItems,
  int sessionHours,
  int dayStartHour,
});

Future<GuestRules> guestRules(AppDatabase db) async {
  final s = await _settings(db);
  return (
    // Entitlement AND preference (ADR-0107 §3), same shape as `memberConfig`.
    // Off here means the cleartext plane never binds at all — the module does
    // not 403, it does not exist (ADR-0105).
    enabled:
        (s?.guestOrderingEnabled ?? false) &&
        venueHasModule(s, moduleSelfOrder),
    noteEnabled: s?.guestNoteEnabled ?? true,
    hoursStartMin: s?.guestHoursStartMin ?? 0,
    hoursEndMin: s?.guestHoursEndMin ?? 0,
    maxItems: s?.guestMaxItems ?? 20,
    sessionHours: s?.guestSessionHours ?? 4,
    dayStartHour: s?.businessDayStartHour ?? 4,
  );
}

/// Equal start and end ⇒ no window, which is the default and means "whenever
/// the server is up". A window that wraps midnight (22:00–02:00) is legal and
/// is why this is not a plain `>=` and `<`.
bool withinServiceHours(GuestRules r, DateTime now) {
  if (r.hoursStartMin == r.hoursEndMin) return true;
  final m = now.hour * 60 + now.minute;
  return r.hoursStartMin < r.hoursEndMin
      ? m >= r.hoursStartMin && m < r.hoursEndMin
      : m >= r.hoursStartMin || m < r.hoursEndMin;
}

// ---------------------------------------------------------------------------
// table codes
// ---------------------------------------------------------------------------

/// The table a code opens, or null. Also the per-table opt-in gate: a table
/// with self-order switched off has a code that resolves to nothing, so an old
/// printed QR reads as "meja ini tidak melayani pesan mandiri" rather than
/// silently working.
Future<VenueTable?> tableForGuestCode(AppDatabase db, String code) async {
  if (code.isEmpty) return null;
  return (db.select(db.venueTables)..where(
        (t) =>
            t.guestCode.equals(code) &
            t.active.equals(true) &
            t.guestOrderingEnabled.equals(true),
      ))
      .getSingleOrNull();
}

/// Give a code to every table that has none. Idempotent, and the *only* safe
/// thing to run on a venue whose QRs are already printed — [rotateGuestCodes]
/// is the deliberate act that kills them.
Future<void> mintMissingGuestCodes(AppDatabase db) async {
  final blank = await (db.select(
    db.venueTables,
  )..where((t) => t.guestCode.equals(''))).get();
  for (final t in blank) {
    await (db.update(db.venueTables)..where((x) => x.id.equals(t.id))).write(
      VenueTablesCompanion(guestCode: Value(mintGuestCode())),
    );
  }
}

/// Remint every table's code. Every printed QR in the venue dies at this
/// moment — which is the point, and why it is audited.
Future<int> rotateGuestCodes(
  AppDatabase db, {
  String? actorId,
  WsHub? hub,
}) async {
  final rows = await db.select(db.venueTables).get();
  await db.transaction(() async {
    for (final t in rows) {
      await (db.update(db.venueTables)..where((x) => x.id.equals(t.id))).write(
        VenueTablesCompanion(guestCode: Value(mintGuestCode())),
      );
    }
  });
  await writeAudit(
    db,
    type: AuditType.selfOrder,
    kind: AuditKind.guestCodesRotated,
    params: {'tables': '${rows.length}'},
    actorUserId: actorId,
    hub: hub,
  );
  return rows.length;
}

// ---------------------------------------------------------------------------
// sessions
// ---------------------------------------------------------------------------

/// Opens (or reuses) this phone's session on [tableId]. The id is the whole
/// credential for "Pesanan saya" — opaque, per-phone, and worthless on any
/// other table.
Future<GuestSession> openGuestSession(
  AppDatabase db, {
  required String tableId,
  required int ttlHours,
}) async {
  final now = SatClock.now();
  final row = GuestSessionsCompanion.insert(
    id: _uuid.v4(),
    tableId: tableId,
    startedAt: now,
    expiresAt: now.add(Duration(hours: ttlHours)),
  );
  return db.into(db.guestSessions).insertReturning(row);
}

/// The session behind an id, or null when it is unknown, expired, or **stale**.
///
/// Stale is the interesting one. A session is bound to a table, and the party
/// at that table changes — so the check is not only "has this session expired"
/// but "is this still the same sitting". Two things end a sitting, and both are
/// already stamped on the table row, which is why this needs no column of its
/// own:
///
/// - `openedAt` moved past the session's start ⇒ the table was freed and
///   reused. A phone left on a windowsill must not order onto the next party.
/// - `billClosedAt` moved past it ⇒ the bill is locked and everything on it is
///   frozen (ADR-0068). Adding to it from a phone is the one thing the till
///   itself refuses to do.
///
/// With one exception, and it is the ordinary case rather than the corner: a
/// guest who scans at an **empty** table opens the sitting *themselves* the
/// moment staff accept, so `openedAt` lands after `startedAt` and the reader
/// would call the party stale in the same second it began. A sitting this
/// session's own accepted order is attached to is by definition its own, so
/// the reuse test asks the visit rather than the clock. `billClosedAt` keeps
/// no such exception — a closed bill ends the sitting for whoever opened it.
Future<GuestSession?> liveGuestSession(AppDatabase db, String id) async {
  final s = await (db.select(
    db.guestSessions,
  )..where((x) => x.id.equals(id))).getSingleOrNull();
  if (s == null || s.closedAt != null) return null;
  if (SatClock.now().isAfter(s.expiresAt)) return null;
  final t = await (db.select(
    db.venueTables,
  )..where((x) => x.id.equals(s.tableId))).getSingleOrNull();
  if (t == null) return null;
  final locked =
      t.billClosedAt != null && t.billClosedAt!.isAfter(s.startedAt);
  if (locked) return null;
  final reopened = t.openedAt != null && t.openedAt!.isAfter(s.startedAt);
  if (!reopened) return s;
  final vid = t.currentVisitId;
  if (vid == null) return null;
  // `get`, not `getSingleOrNull`: a second accepted round on the same sitting
  // is the normal case and would make a single-row read throw.
  final mine =
      await (db.select(db.guestOrders)
            ..where(
              (o) =>
                  o.sessionId.equals(s.id) &
                  o.status.equals('accepted') &
                  o.visitId.equals(vid),
            )
            ..limit(1))
          .get();
  return mine.isEmpty ? null : s;
}

// ---------------------------------------------------------------------------
// the menu the guest sees
// ---------------------------------------------------------------------------

/// Course for a line, derived from the item's category. The staff path takes
/// the course from the waiter's own grouping; a guest has no such notion, so
/// the kitchen's grouping is inferred here and is a *hint*, never a gate —
/// exactly what `course` is on the staff path too.
///
// ponytail: category id → course by name, because the seeded ids already read
// as courses. A venue that renames its categories lands on `mains`; give
// `menu_categories` a `course` column the day that matters.
String courseForCategory(String categoryId) => switch (categoryId) {
  'soft' || 'beer' || 'cocktails' || 'wine' || 'drinks' => 'drinks-now',
  'starters' => 'starters',
  'sides' => 'sides',
  'desserts' => 'desserts',
  _ => 'mains',
};

/// The guest menu: visible items only, priced, with a resolved sold-out flag.
///
/// `guestStockOverride` is the manual call and wins over the derivation, but
/// only for the business day it was made on — a `forceOut` set at last night's
/// rush must not still be hiding rendang at lunch.
///
/// [includeHidden] is the **staff** read of the same shape: the Menu tamu tab
/// has to draw the items a guest cannot see, or hiding one removes the only
/// control that could bring it back. The guest plane never passes it.
Future<Map<String, dynamic>> guestMenuJson(
  AppDatabase db, {
  bool includeHidden = false,
}) async {
  final rules = await guestRules(db);
  final today = businessDayStart(SatClock.now(), rules.dayStartHour);
  final cats = await (db.select(
    db.menuCategories,
  )..orderBy([(c) => OrderingTerm(expression: c.sortOrder)])).get();
  final items =
      await (db.select(db.menuItems)
            ..where(
              (i) => includeHidden
                  ? const Constant(true)
                  : i.guestVisible.equals(true),
            )
            ..orderBy([(i) => OrderingTerm(expression: i.name)]))
          .get();
  final flags = await deriveStockFlags(db);

  Map<String, dynamic> itemJson(MenuItem i) {
    final override = i.guestOverrideAt != null && !i.guestOverrideAt!.isBefore(today)
        ? i.guestStockOverride
        : 'auto';
    final auto = i.unavailable || (flags[i.id]?.autoSoldOut ?? false);
    final soldOut = switch (override) {
      'forceIn' => false,
      'forceOut' => true,
      _ => auto,
    };
    return {
      'id': i.id,
      'name': i.name,
      'categoryId': i.categoryId,
      'description': i.description,
      'basePrice': i.basePrice,
      'variants': jsonDecode(i.variantsJson),
      'modifierGroups': jsonDecode(i.modifierGroupsJson),
      'featured': i.guestFeatured,
      'visible': i.guestVisible,
      'soldOut': soldOut,
      // The **effective** override, not the stored one: a force that has
      // outlived its business day already reads `auto` above, and the tab
      // must not draw a button as held down when the server has let go.
      'stockOverride': override,
      'alcohol': i.alcohol,
      'photoRev': i.photoRev,
    };
  }

  // Only categories that hold something. `menu_categories` carries a pseudo
  // row (`all`, "Semua") that the staff menu uses as its all-items tab and no
  // item is ever filed under — emitted here it drew a second "Semua" chip
  // beside the page's own, and tapping it filtered the menu down to nothing.
  final stocked = {for (final i in items) i.categoryId};
  return {
    'categories': [
      for (final c in cats)
        if (stocked.contains(c.id)) {'id': c.id, 'name': c.name},
    ],
    'items': [for (final i in items) itemJson(i)],
    'noteEnabled': rules.noteEnabled,
    'maxItems': rules.maxItems,
  };
}

// ---------------------------------------------------------------------------
// submitting
// ---------------------------------------------------------------------------

/// One line as the phone sends it: `{itemId, variantId?, optionIds[], qty, note}`.
/// **No price** — anything the guest sends about money is ignored.
Future<GuestOrder> submitGuestOrder(
  AppDatabase db, {
  required GuestSession session,
  required VenueTable table,
  required List<Map<String, dynamic>> lines,
  WsHub? hub,
}) async {
  final rules = await guestRules(db);
  if (!rules.enabled) throw const SelfOrderException('self_order_off');
  if (!withinServiceHours(rules, SatClock.now())) {
    throw const SelfOrderException('outside_service_hours');
  }
  if (lines.isEmpty) throw const SelfOrderException('empty_order');
  if (lines.length > rules.maxItems) {
    throw const SelfOrderException('too_many_items');
  }

  final orderId = _uuid.v4();
  final rows = <GuestOrderLinesCompanion>[];
  var subtotal = 0;

  for (final l in lines) {
    final itemId = (l['itemId'] as String?) ?? '';
    final item = await (db.select(
      db.menuItems,
    )..where((i) => i.id.equals(itemId))).getSingleOrNull();
    if (item == null || !item.guestVisible) {
      throw const SelfOrderException('item_unavailable');
    }
    final qty = ((l['qty'] as num?)?.toInt() ?? 1).clamp(1, 99);

    // Price from the menu, never from the phone. A variant's `price` is
    // absolute; an option's `priceDelta` adds to it — the same arithmetic the
    // staff modifier sheet does, held here so the two cannot drift.
    final variants = (jsonDecode(item.variantsJson) as List).cast<Map<String, dynamic>>();
    final wantVariant = l['variantId'] as String?;
    final variant = variants.isEmpty
        ? null
        : variants.firstWhere(
            (v) => v['id'] == wantVariant,
            orElse: () => variants.first,
          );
    var unit = (variant?['price'] as num?)?.toInt() ?? item.basePrice;

    final optionIds = ((l['optionIds'] as List?) ?? const []).cast<String>();
    final groups = (jsonDecode(item.modifierGroupsJson) as List).cast<Map<String, dynamic>>();
    final chosen = <Map<String, dynamic>>[];
    for (final g in groups) {
      final opts = (g['options'] as List).cast<Map<String, dynamic>>();
      final multi = g['multi'] == true;
      final picked = opts.where((o) => optionIds.contains(o['id'])).toList();
      if (g['required'] == true && picked.isEmpty) {
        throw const SelfOrderException('modifier_required');
      }
      if (!multi && picked.length > 1) {
        throw const SelfOrderException('modifier_invalid');
      }
      for (final o in picked) {
        unit += (o['priceDelta'] as num?)?.toInt() ?? 0;
        chosen.add({'optionId': o['id']});
      }
    }

    final note = rules.noteEnabled ? (l['note'] as String?)?.trim() : null;
    subtotal += unit * qty;
    rows.add(
      GuestOrderLinesCompanion.insert(
        id: _uuid.v4(),
        orderId: orderId,
        itemId: item.id,
        name: item.name,
        variantName: Value((variant?['name'] as String?) ?? ''),
        course: Value(courseForCategory(item.categoryId)),
        qty: Value(qty),
        modifiersJson: Value(jsonEncode(chosen)),
        note: Value(
          note == null || note.isEmpty
              ? null
              : note.substring(0, note.length > _noteMax ? _noteMax : note.length),
        ),
        unitPrice: unit,
      ),
    );
  }

  final order = GuestOrdersCompanion.insert(
    id: orderId,
    sessionId: session.id,
    tableId: table.id,
    submittedAt: SatClock.now(),
    subtotal: Value(subtotal),
  );
  late GuestOrder saved;
  await db.transaction(() async {
    saved = await db.into(db.guestOrders).insertReturning(order);
    await db.batch((b) => b.insertAll(db.guestOrderLines, rows));
  });
  hub?.broadcast(
    WsEventTypes.guestOrderSubmitted,
    await guestOrderJson(db, saved, staffView: true),
  );
  return saved;
}

/// The guest note cap. Long enough for "tanpa sambal, alergi kacang", short
/// enough that the kitchen ticket stays readable.
const _noteMax = 120;

// ---------------------------------------------------------------------------
// deciding
// ---------------------------------------------------------------------------

/// Accept: the intent becomes real tickets through the **ordinary**
/// `submitOrder` path — the same stock check, the same visit attachment, the
/// same idempotency claim a waiter's order gets. That reuse is the point of
/// ADR-0105; a second write path is what ADR-0080 was right to delete.
Future<({GuestOrder order, List<Map<String, dynamic>> rejected})>
acceptGuestOrder(
  AppDatabase db, {
  required String orderId,
  required String actorId,
  WsHub? hub,
}) async {
  final claimed = await _claim(db, orderId);
  final lines = await (db.select(
    db.guestOrderLines,
  )..where((l) => l.orderId.equals(orderId))).get();

  final result = await submitOrder(
    db,
    tableId: claimed.tableId,
    // The intent's own id: a double-tapped Terima on two tablets replays the
    // same claim rather than firing the food twice.
    idem: 'guest-$orderId',
    actorId: actorId,
    lines: [
      for (final l in lines)
        {
          'itemId': l.itemId,
          'name': l.name,
          'variantName': l.variantName,
          'course': l.course,
          'qty': l.qty,
          'modifiers': jsonDecode(l.modifiersJson),
          'note': l.note,
          'unitPrice': l.unitPrice,
        },
    ],
  );

  if (result.createdIds.isEmpty) {
    // Nothing was written, so the intent goes back on the queue rather than
    // dying as "accepted" with no food behind it.
    await _release(db, orderId);
    throw const SelfOrderException('accept_rejected_by_stock');
  }

  // The same fan-out `POST /orders` does. Without it the tickets exist and no
  // screen knows: the KDS stays empty and the bill stays short until someone
  // refetches by hand.
  if (hub != null) await broadcastSubmitted(db, hub, result);

  final now = SatClock.now();
  await (db.update(db.guestOrders)..where((o) => o.id.equals(orderId))).write(
    GuestOrdersCompanion(
      status: const Value('accepted'),
      decidedAt: Value(now),
      decidedByUserId: Value(actorId),
      visitId: Value(result.visitId),
      ticketIdsJson: Value(jsonEncode(result.createdIds)),
    ),
  );
  final saved = await _byId(db, orderId);
  await writeAudit(
    db,
    type: AuditType.selfOrder,
    kind: AuditKind.guestOrderAccepted,
    params: {
      'table': result.tableRow?.label ?? claimed.tableId,
      'lines': '${lines.length}',
    },
    tableId: claimed.tableId,
    actorUserId: actorId,
    hub: hub,
  );
  hub?.broadcast(
    WsEventTypes.guestOrderDecided,
    await guestOrderJson(db, saved, staffView: true),
  );
  return (order: saved, rejected: result.rejected);
}

Future<GuestOrder> rejectGuestOrder(
  AppDatabase db, {
  required String orderId,
  required String actorId,
  required String reasonCode,
  WsHub? hub,
}) async {
  final claimed = await _claim(db, orderId, to: 'rejected');
  final table = await (db.select(
    db.venueTables,
  )..where((t) => t.id.equals(claimed.tableId))).getSingleOrNull();
  final lines = await (db.select(
    db.guestOrderLines,
  )..where((l) => l.orderId.equals(orderId))).get();
  await (db.update(db.guestOrders)..where((o) => o.id.equals(orderId))).write(
    GuestOrdersCompanion(
      decidedAt: Value(SatClock.now()),
      decidedByUserId: Value(actorId),
      rejectReasonCode: Value(reasonCode),
    ),
  );
  final saved = await _byId(db, orderId);
  await writeAudit(
    db,
    type: AuditType.selfOrder,
    kind: AuditKind.guestOrderRejected,
    params: {
      'table': table?.label ?? claimed.tableId,
      'lines': '${lines.length}',
    },
    tableId: claimed.tableId,
    actorUserId: actorId,
    reason: reasonCode,
    hub: hub,
  );
  hub?.broadcast(
    WsEventTypes.guestOrderDecided,
    await guestOrderJson(db, saved, staffView: true),
  );
  return saved;
}

/// The guest withdrawing their own order, while it is still only an intent.
/// Once accepted it is a ticket, and a ticket is voided by staff — a guest may
/// not unsend food the kitchen is already cooking.
Future<GuestOrder> cancelGuestOrder(
  AppDatabase db, {
  required String orderId,
  required String sessionId,
  WsHub? hub,
}) async {
  final row = await _byId(db, orderId);
  if (row.sessionId != sessionId) throw const SelfOrderException('not_found');
  await _claim(db, orderId, to: 'cancelled');
  await (db.update(db.guestOrders)..where((o) => o.id.equals(orderId))).write(
    GuestOrdersCompanion(decidedAt: Value(SatClock.now())),
  );
  final saved = await _byId(db, orderId);
  hub?.broadcast(
    WsEventTypes.guestOrderDecided,
    await guestOrderJson(db, saved, staffView: true),
  );
  return saved;
}

Future<GuestOrder> _byId(AppDatabase db, String id) async {
  final row = await (db.select(
    db.guestOrders,
  )..where((o) => o.id.equals(id))).getSingleOrNull();
  if (row == null) throw const SelfOrderException('not_found');
  return row;
}

/// Move `pending` → [to] and hand back the row, or refuse. The read and the
/// write are one transaction because two tablets showing the same queue is the
/// normal case, not the edge one.
Future<GuestOrder> _claim(
  AppDatabase db,
  String id, {
  String to = 'accepted',
}) => db.transaction(() async {
  final row = await _byId(db, id);
  if (row.status != 'pending') throw const SelfOrderException('already_decided');
  await (db.update(db.guestOrders)..where(
        (o) => o.id.equals(id) & o.status.equals('pending'),
      ))
      .write(GuestOrdersCompanion(status: Value(to)));
  return row;
});

Future<void> _release(AppDatabase db, String id) =>
    (db.update(db.guestOrders)..where((o) => o.id.equals(id))).write(
      const GuestOrdersCompanion(status: Value('pending')),
    );

// ---------------------------------------------------------------------------
// reading
// ---------------------------------------------------------------------------

/// [staffView] adds what the review queue needs and the guest must not have:
/// the table's own label and the name of whoever decided the order. A guest
/// page is told what happened to its order, never by whom.
Future<Map<String, dynamic>> guestOrderJson(
  AppDatabase db,
  GuestOrder o, {
  bool staffView = false,
}) async {
  final lines = await (db.select(
    db.guestOrderLines,
  )..where((l) => l.orderId.equals(o.id))).get();
  String? label;
  String? decidedBy;
  if (staffView) {
    final t = await (db.select(
      db.venueTables,
    )..where((x) => x.id.equals(o.tableId))).getSingleOrNull();
    label = t?.label;
    if (o.decidedByUserId != null) {
      final u = await (db.select(
        db.users,
      )..where((x) => x.id.equals(o.decidedByUserId!))).getSingleOrNull();
      decidedBy = u?.name;
    }
  }
  return {
    'id': o.id,
    'sessionId': o.sessionId,
    'tableId': o.tableId,
    'tableLabel': label,
    'decidedBy': decidedBy,
    'status': o.status,
    'submittedAt': o.submittedAt.toIso8601String(),
    'decidedAt': o.decidedAt?.toIso8601String(),
    'rejectReasonCode': o.rejectReasonCode,
    'subtotal': o.subtotal,
    'lines': [
      for (final l in lines)
        {
          'id': l.id,
          'itemId': l.itemId,
          'name': l.name,
          'variantName': l.variantName,
          'qty': l.qty,
          'note': l.note,
          'unitPrice': l.unitPrice,
          'modifiers': jsonDecode(l.modifiersJson),
        },
    ],
  };
}

Future<List<Map<String, dynamic>>> guestOrdersJson(
  AppDatabase db, {
  String? status,
  String? sessionId,
  bool staffView = false,
  int limit = 100,
}) async {
  final q = db.select(db.guestOrders)
    ..orderBy([(o) => OrderingTerm.desc(o.submittedAt)])
    ..limit(limit);
  if (status != null) q.where((o) => o.status.equals(status));
  if (sessionId != null) q.where((o) => o.sessionId.equals(sessionId));
  return [
    for (final o in await q.get())
      await guestOrderJson(db, o, staffView: staffView),
  ];
}

/// The `/selforder` hero numbers, for the current business day. Derived on
/// read: nothing stores a self-order total, so there is no second place for it
/// to disagree with itself.
Future<Map<String, dynamic>> guestOrderStats(AppDatabase db) async {
  final rules = await guestRules(db);
  final from = businessDayStart(SatClock.now(), rules.dayStartHour);
  final rows = await (db.select(
    db.guestOrders,
  )..where((o) => o.submittedAt.isBiggerOrEqualValue(from))).get();
  final accepted = rows.where((o) => o.status == 'accepted').toList();
  final waits = [
    for (final o in accepted)
      if (o.decidedAt != null)
        o.decidedAt!.difference(o.submittedAt).inSeconds,
  ]..sort();
  return {
    'total': rows.length,
    'pending': rows.where((o) => o.status == 'pending').length,
    'accepted': accepted.length,
    'rejected': rows.where((o) => o.status == 'rejected').length,
    'value': accepted.fold<int>(0, (a, o) => a + o.subtotal),
    'medianWaitSecs': waits.isEmpty ? 0 : waits[waits.length ~/ 2],
  };
}
