import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/cash_entry.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/cash.dart';
// Hidden for the reason `cash.dart` gives: Drift's row class shares the domain
// model's name and this file means the domain one.
import 'package:satset/server/db/database.dart' hide CashEntry;
import 'package:satset/server/ws_hub.dart';

/// The petty cash box (§Kas kecil).
///
/// Capability split, per the glossary: **posting an expense** needs `manageCash`
/// so a supervisor can spend from the box, while **funding and counting** it need
/// `editSettings` — the owner's authority. Both are enforced here and not only in
/// the UI, because a capability checked client-side is a suggestion.
///
/// A venue holds several named boxes (ADR-0131). Authority stays **venue-wide**:
/// whoever may spend may spend from any box. Moving money *between* boxes is
/// funding, not spending, so it sits with `editSettings` — the supervisor who
/// may empty a tin must not be able to quietly refill it. Managing the boxes
/// themselves is `editSettings` for the same reason.
Router cashRoutes(AppDatabase db, WsHub hub, ServerAuth auth) {
  final r = Router();

  Future<(String?, Set<String>)?> actor(Request req) async {
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

  Response err(int status, String code, {int? balance}) => Response(
    status,
    body: jsonEncode({'code': code, 'balance': ?balance}),
    headers: {'content-type': 'application/json'},
  );

  Response forbidden(Capability c) => Response(
    403,
    body: jsonEncode({'code': 'forbidden', 'capability': c.name}),
    headers: {'content-type': 'application/json'},
  );

  /// The ledger page plus the authoritative balance, in one response — the
  /// balance is derived, so a client holding one page cannot compute it.
  r.get('/cash', (Request req) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    // Reading the box is for anyone who can act on it or report on it.
    if (!a.$2.contains(Capability.manageCash.name) &&
        !a.$2.contains(Capability.editSettings.name) &&
        !a.$2.contains(Capability.viewReports.name)) {
      return forbidden(Capability.manageCash);
    }
    final rawLimit = req.url.queryParameters['limit'] ?? '';
    // `all` is the export's unpaged read of one window (ADR-0136). It is not a
    // bigger page: it asks for one row more than the cap so the route can tell
    // "exactly at the ceiling" from "over it" without a second COUNT query.
    final unpaged = rawLimit == 'all';
    final limit = int.tryParse(rawLimit) ?? 50;
    // Absent means the "Semua" arm — every box's rows in one list.
    final boxId = req.url.queryParameters['boxId'];
    final from = _at(req.url.queryParameters['from']);
    final to = _at(req.url.queryParameters['to']);
    final entries = await cashLedger(
      db,
      boxId: boxId,
      limit: unpaged ? kCashWindowMax + 1 : limit.clamp(1, 500),
      from: from,
      to: to,
    );
    // Refuse, never truncate. The window chips are on the screen that asked.
    if (unpaged && entries.length > kCashWindowMax) {
      return err(400, 'window_too_large');
    }
    final boxes = await cashBoxList(db);
    return json({
      // Movement over the window, summed server-side over every row in it —
      // the client holds a page and must never add up a ledger (ADR-0136).
      'totals': await cashWindowTotals(db, boxId: boxId, from: from, to: to),
      // Kept for readers that predate ADR-0131 and for the "Semua" hero: the
      // venue total is the sum of the boxes, never a figure of its own.
      'balance': [for (final b in boxes) b.balance].fold(0, (a, b) => a + b),
      'boxes': [for (final b in boxes) cashBoxJson(b)],
      // Every box's categories, inactive ones included: the picker filters, but
      // a ledger row filed under a retired word still has to render it.
      'categories': [
        for (final c in await cashCategoryList(db)) cashCategoryJson(c),
      ],
      'entries': [for (final e in entries) cashEntryJson(e)],
    });
  });

  r.post('/cash/topup', (Request req) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      final entry = await topUpCash(
        db,
        boxId: _boxId(body),
        amount: (body['amount'] as num?)?.toInt() ?? 0,
        note: _text(body['note']),
        actorUserId: a.$1,
        // Passed for the audit broadcast inside the writer, not the ledger one:
        // `_broadcast` below sends `cashEntryCreated`, while `writeAudit` only
        // emits `auditCreated` when it has the hub. Without this the venue Audit
        // screen never hears a cash act until it re-fetches.
        hub: hub,
      );
      return json(await _broadcast(db, hub, entry));
    } on CashException catch (e) {
      return err(400, e.code, balance: e.balance);
    }
  });

  r.post('/cash/expense', (Request req) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.manageCash.name)) {
      return forbidden(Capability.manageCash);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    // An id now, scoped to the box (ADR-0135). Whether it exists, is active and
    // belongs to *this* box is the writer's call, inside the transaction.
    final categoryId = _text(body['category']);
    if (categoryId == null) return err(400, 'category_required');
    try {
      final entry = await spendCash(
        db,
        boxId: _boxId(body),
        amount: (body['amount'] as num?)?.toInt() ?? 0,
        categoryId: categoryId,
        note: _text(body['note']),
        // Optional here, unlike a non-cash payment's mandatory proof: the pasar
        // has no receipt printer, and a required field staff cannot satisfy gets
        // satisfied with a photo of the floor.
        photo: _decodePhoto(body['photoBase64']),
        actorUserId: a.$1,
        hub: hub,
      );
      return json(await _broadcast(db, hub, entry));
    } on CashException catch (e) {
      return err(400, e.code, balance: e.balance);
    }
  });

  r.post('/cash/count', (Request req) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      final entry = await countCash(
        db,
        boxId: _boxId(body),
        counted: (body['counted'] as num?)?.toInt() ?? 0,
        note: _text(body['note']),
        actorUserId: a.$1,
        hub: hub,
      );
      return json(await _broadcast(db, hub, entry));
    } on CashException catch (e) {
      return err(400, e.code, balance: e.balance);
    }
  });

  /// Undo a row. Reachable by either authority: whoever may post a kind of
  /// movement may take it back, and a reversal is the only correction there is.
  r.post('/cash/<id>/reverse', (Request req, String id) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.manageCash.name) &&
        !a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.manageCash);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      // A transfer comes back as two reversals — both legs, one act. The caller
      // is handed the last payload, and every client hears both over the socket.
      final entries = await reverseCash(
        db,
        entryId: id,
        note: _text(body['note']) ?? '',
        actorUserId: a.$1,
        hub: hub,
      );
      Map<String, dynamic>? last;
      for (final e in entries) {
        last = await _broadcast(db, hub, e);
      }
      return json(last ?? const {});
    } on CashException catch (e) {
      return err(
        e.code == 'not_found' || e.code == 'box_not_found' ? 404 : 400,
        e.code,
        balance: e.balance,
      );
    }
  });

  /// Move money between two boxes (ADR-0131). Funding, so `editSettings`.
  r.post('/cash/transfer', (Request req) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      final legs = await transferCash(
        db,
        fromId: _text(body['fromId']) ?? '',
        toId: _text(body['toId']) ?? '',
        amount: (body['amount'] as num?)?.toInt() ?? 0,
        note: _text(body['note']),
        actorUserId: a.$1,
        hub: hub,
      );
      Map<String, dynamic>? last;
      for (final e in legs) {
        last = await _broadcast(db, hub, e);
      }
      return json(last ?? const {});
    } on CashException catch (e) {
      return err(
        e.code == 'box_not_found' ? 404 : 400,
        e.code,
        balance: e.balance,
      );
    }
  });

  /// The boxes themselves. Creating, renaming and retiring one is the owner's.
  r.post('/cash/boxes', (Request req) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      final box = await createCashBox(
        db,
        name: _text(body['name']) ?? '',
        actorUserId: a.$1,
        hub: hub,
      );
      return json(await _broadcastBoxes(db, hub, box));
    } on CashException catch (e) {
      return err(400, e.code, balance: e.balance);
    }
  });

  r.patch('/cash/boxes/<id>', (Request req, String id) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      final box = await updateCashBox(
        db,
        id: id,
        name: _text(body['name']),
        active: body['active'] as bool?,
        actorUserId: a.$1,
        hub: hub,
      );
      return json(await _broadcastBoxes(db, hub, box));
    } on CashException catch (e) {
      return err(
        e.code == 'box_not_found' ? 404 : 400,
        e.code,
        balance: e.balance,
      );
    }
  });

  /// A box's vocabulary (ADR-0135). Authoring what a tin spends on is the same
  /// authority as authoring the tin, and it writes no audit row — a category is
  /// vocabulary, and every movement already carries both.
  r.post('/cash/boxes/<boxId>/categories', (Request req, String boxId) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      await createCashCategory(
        db,
        boxId: boxId,
        name: _text(body['name']) ?? '',
      );
      return json(await _broadcastBoxes(db, hub, null));
    } on CashException catch (e) {
      return err(e.code == 'box_not_found' ? 404 : 400, e.code);
    }
  });

  r.patch('/cash/boxes/<boxId>/categories/<id>', (
    Request req,
    String boxId,
    String id,
  ) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    try {
      await updateCashCategory(
        db,
        boxId: boxId,
        id: id,
        name: _text(body['name']),
        active: body['active'] as bool?,
      );
      return json(await _broadcastBoxes(db, hub, null));
    } on CashException catch (e) {
      return err(e.code == 'unknown_category' ? 404 : 400, e.code);
    }
  });

  // Receipt-photo bytes for one expense. Blob never rides the ledger path.
  r.get('/cash/<id>/photo', (Request req, String id) async {
    final a = await actor(req);
    if (a == null) return Response(401);
    final row = await (db.select(
      db.cashEntries,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (row == null || row.photo == null) return Response.notFound('no photo');
    return Response.ok(
      row.photo,
      headers: {'content-type': 'image/jpeg', 'cache-control': 'no-cache'},
    );
  });

  return r;
}

/// Fan the movement out with **that box's new authoritative balance** alongside
/// it, and hand the same object back to the caller.
///
/// The balance rides the event because it is derived: a client that appends the
/// row locally holds only a page and cannot sum what it cannot see. It is the
/// one box's, not the venue's (ADR-0131) — the client holds every box and
/// re-sums the total itself, so a transfer's two broadcasts leave it correct
/// after either one arrives. Unfiltered, like `auditCreated` — see §Kas kecil.
Future<Map<String, dynamic>> _broadcast(
  AppDatabase db,
  WsHub hub,
  CashEntry entry,
) async {
  final payload = {
    'entry': cashEntryJson(entry),
    'boxId': entry.boxId,
    'balance': await cashBalance(db, boxId: entry.boxId),
  };
  hub.broadcast(WsEventTypes.cashEntryCreated, payload);
  return payload;
}

/// A box changed — created, renamed or retired. The whole list goes out rather
/// than the one box: it is a handful of rows, and a client that only patched
/// one would still have to re-sort.
/// [box] is null when a **category** changed rather than a box: the frame is
/// the same one either way (ADR-0135), because a category hangs off a box and
/// the client replaces the list wholesale regardless.
Future<Map<String, dynamic>> _broadcastBoxes(
  AppDatabase db,
  WsHub hub,
  CashBox? box,
) async {
  final boxes = await cashBoxList(db);
  final payload = {
    if (box != null) 'box': cashBoxJson(box),
    'boxes': [for (final b in boxes) cashBoxJson(b)],
    'categories': [
      for (final c in await cashCategoryList(db)) cashCategoryJson(c),
    ],
  };
  hub.broadcast(WsEventTypes.cashBoxesUpdated, payload);
  return payload;
}

/// Which box a movement names. Defaults to the venue's first box so a caller
/// that predates ADR-0131 — a test, an older client — still posts somewhere
/// real rather than against a tin that does not exist.
String _boxId(Map<String, dynamic> body) =>
    _text(body['boxId']) ?? 'box-main';

String? _text(Object? raw) {
  if (raw is! String) return null;
  final t = raw.trim();
  return t.isEmpty ? null : t;
}

/// A window bound off the query string. Unparseable reads as absent — the
/// **Semua** arm — because a typo'd date must not silently return an empty
/// ledger that looks like an empty box.
DateTime? _at(String? raw) =>
    (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);

Uint8List? _decodePhoto(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    return base64Decode(raw);
  } catch (_) {
    return null;
  }
}
