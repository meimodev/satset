import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/auth.dart';
// Hidden for the reason `cash_routes.dart` gives: Drift's row classes share the
// domain models' names and this file means the domain ones.
import 'package:satset/server/db/database.dart'
    hide VisitExpense, VisitExpenseCategory;
import 'package:satset/server/visit_expenses.dart';
import 'package:satset/server/ws_hub.dart';

/// The **[[Pengeluaran kunjungan]]** routes (ADR-0130).
///
/// The feature gate lives in `visitExpenseEnabled`, not here — the rule
/// `modules.dart` states — and an ungated venue answers **404**, not 403: the
/// feature does not exist for it rather than being withheld from this reader,
/// so a client cannot tell an unentitled venue from an old server.
///
/// Capability split: **recording** needs `recordTableExpense`, the floor's own
/// authority; **reading** is open to whoever settles or records, because the
/// cashier has to see what this visit cost before closing it; the **photo** is
/// a `viewReports` read, where the other proofs already live (ADR-0086).
Router visitExpenseRoutes(AppDatabase db, WsHub hub, ServerAuth auth) {
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

  Response err(int status, String code, {int? cap, int? spent}) => Response(
    status,
    body: jsonEncode({'code': code, 'cap': ?cap, 'spent': ?spent}),
    headers: {'content-type': 'application/json'},
  );

  Response forbidden(Capability c) => Response(
    403,
    body: jsonEncode({'code': 'forbidden', 'capability': c.name}),
    headers: {'content-type': 'application/json'},
  );

  Future<Response?> enabledGuard() async =>
      await visitExpenseEnabled(db) ? null : err(404, 'table_expense_disabled');

  /// Record one. The `id` is client-minted and doubles as the idempotency key,
  /// so the [[Antrean kirim]] replays under it — the router is wrapped in
  /// `idempotent()` where it is mounted.
  r.post('/visits/<id>/expenses', (Request req, String id) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.recordTableExpense.name)) {
      return forbidden(Capability.recordTableExpense);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final photo = _decodePhoto(body['photoBase64']);
    // Refused here as well as in the writer: a caller that sends no photo field
    // at all should read the same code as one that sends an empty string.
    if (photo == null) return err(400, 'photo_required');
    try {
      final e = await recordVisitExpense(
        db,
        id: (body['id'] as String?) ?? '',
        visitId: id,
        categoryId: (body['categoryId'] as String?) ?? '',
        amount: (body['amount'] as num?)?.toInt() ?? 0,
        photo: photo,
        note: _text(body['note']),
        actorUserId: a.$1,
        hub: hub,
      );
      return json({
        'expense': visitExpenseJson(e),
        'total': await visitExpenseTotal(db, id),
        'cap': await visitSubtotal(db, id),
      });
    } on VisitExpenseException catch (e) {
      return err(
        e.code == 'visit_not_found' || e.code == 'category_not_found'
            ? 404
            : 400,
        e.code,
        cap: e.cap,
        spent: e.spent,
      );
    }
  });

  /// What this visit has cost, plus the two numbers a sheet needs to say how
  /// much is left. Never carries the photo bytes.
  r.get('/visits/<id>/expenses', (Request req, String id) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.recordTableExpense.name) &&
        !a.$2.contains(Capability.settleBill.name) &&
        !a.$2.contains(Capability.viewReports.name)) {
      return forbidden(Capability.recordTableExpense);
    }
    return json({
      'expenses': [
        for (final e in await visitExpenses(db, id)) visitExpenseJson(e),
      ],
      'total': await visitExpenseTotal(db, id),
      'cap': await visitSubtotal(db, id),
    });
  });

  /// The venue's own vocabulary. Open to any signed-in caller: a picker that
  /// cannot list its options is a picker that cannot be drawn, and the names
  /// are the venue's own words rather than anything about money.
  r.get('/expense-categories', (Request req) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    return json({
      'categories': [
        for (final c in await activeExpenseCategories(db))
          visitExpenseCategoryJson(c),
      ],
    });
  });

  /// Author the venue's own vocabulary. `editSettings` — the owner's authority,
  /// like the [[Preset diskon]] catalogue this is shaped after.
  r.post('/expense-categories', (Request req) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final name = _text(body['name']);
    if (name == null) return err(400, 'name_required');
    final row = await upsertExpenseCategory(
      db,
      id: body['id'] as String?,
      name: name,
      active: body['active'] as bool?,
      sortOrder: (body['sortOrder'] as num?)?.toInt(),
    );
    await _broadcastCategories(db, hub);
    return json(visitExpenseCategoryJson(row));
  });

  /// Deactivate. **There is no delete** (ADR-0130): a removed category orphans
  /// every expense filed under it, and a closed month would then render an id
  /// where a word should be.
  r.patch('/expense-categories/<id>', (Request req, String id) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.editSettings.name)) {
      return forbidden(Capability.editSettings);
    }
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final existing = await (db.select(
      db.visitExpenseCategories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (existing == null) return err(404, 'category_not_found');
    final row = await upsertExpenseCategory(
      db,
      id: id,
      name: _text(body['name']) ?? existing.name,
      active: body['active'] as bool?,
      sortOrder: (body['sortOrder'] as num?)?.toInt(),
    );
    await _broadcastCategories(db, hub);
    return json(visitExpenseCategoryJson(row));
  });

  // Proof bytes for one expense. The blob never rides a list path.
  r.get('/expenses/<id>/photo', (Request req, String id) async {
    final off = await enabledGuard();
    if (off != null) return off;
    final a = await actor(req);
    if (a == null) return Response(401);
    if (!a.$2.contains(Capability.viewReports.name)) {
      return forbidden(Capability.viewReports);
    }
    final row = await (db.select(
      db.visitExpenses,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (row == null) return Response.notFound('no photo');
    return Response.ok(
      row.photo,
      headers: {'content-type': 'image/jpeg', 'cache-control': 'no-cache'},
    );
  });

  return r;
}

/// The whole list, so a client needs no merge logic — the [[Preset diskon]]
/// broadcast's shape, for the same reason.
Future<void> _broadcastCategories(AppDatabase db, WsHub hub) async {
  hub.broadcast(WsEventTypes.expenseCategoriesUpdated, {
    'categories': [
      for (final c in await activeExpenseCategories(db))
        visitExpenseCategoryJson(c),
    ],
  });
}

String? _text(Object? raw) {
  if (raw is! String) return null;
  final t = raw.trim();
  return t.isEmpty ? null : t;
}

Uint8List? _decodePhoto(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    final bytes = base64Decode(raw);
    return bytes.isEmpty ? null : bytes;
  } catch (_) {
    return null;
  }
}
