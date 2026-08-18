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
    final limit = int.tryParse(req.url.queryParameters['limit'] ?? '') ?? 50;
    final entries = await cashLedger(db, limit: limit.clamp(1, 500));
    return json({
      'balance': await cashBalance(db),
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
    final category = cashCategoryFromName(body['category'] as String?);
    if (category == null) return err(400, 'category_required');
    try {
      final entry = await spendCash(
        db,
        amount: (body['amount'] as num?)?.toInt() ?? 0,
        category: category,
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
      final entry = await reverseCash(
        db,
        entryId: id,
        note: _text(body['note']) ?? '',
        actorUserId: a.$1,
        hub: hub,
      );
      return json(await _broadcast(db, hub, entry));
    } on CashException catch (e) {
      return err(e.code == 'not_found' ? 404 : 400, e.code, balance: e.balance);
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

/// Fan the movement out with the **new authoritative balance** alongside it, and
/// hand the same object back to the caller.
///
/// The balance rides the event because it is derived: a client that appends the
/// row locally holds only a page and cannot sum what it cannot see. Unfiltered,
/// like `auditCreated` — see §Kas kecil.
Future<Map<String, dynamic>> _broadcast(
  AppDatabase db,
  WsHub hub,
  CashEntry entry,
) async {
  final payload = {
    'entry': cashEntryJson(entry),
    'balance': await cashBalance(db),
  };
  hub.broadcast(WsEventTypes.cashEntryCreated, payload);
  return payload;
}

String? _text(Object? raw) {
  if (raw is! String) return null;
  final t = raw.trim();
  return t.isEmpty ? null : t;
}

Uint8List? _decodePhoto(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    return base64Decode(raw);
  } catch (_) {
    return null;
  }
}
