// The venue audit log's load-bearing promises, through the real shelf routes
// and an in-memory database.
//
// Everything here fails *silently* when broken — no exception, just a wrong
// number on the one screen whose entire job is being trustworthy. That is why
// these five and not others.
//
// See docs/adr/0071-kitchen-ownership-freezes-a-line.md and
// docs/adr/0072-venue-audit-log.md.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/audit_log.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/reference_routes.dart';
import 'package:satset/server/routes/tickets_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late TestCaller caller;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Route gates want a real caller now (ADR-0102). The permissions group
    // below signs in its own, narrower callers — this one is the default for
    // the groups whose subject is the log's shape rather than who may read it.
    caller = await signInForTest(db);
  });
  tearDown(() => db.close());

  Future<Response> get(Handler router, String path) async => await router(
    Request('GET', Uri.parse('http://x$path'), headers: caller.headers),
  );

  Future<dynamic> getJson(Handler router, String path) async {
    final res = await get(router, path);
    return jsonDecode(await res.readAsString());
  }

  // ---------------------------------------------------------------------
  // 1. Keyset paging across a same-millisecond burst.
  // ---------------------------------------------------------------------

  test(
    'paging a burst written in one millisecond loses and repeats nothing',
    () async {
      // A round of voids fired back to back lands on one timestamp. With `at`
      // alone as the cursor every row after the first at that instant is either
      // skipped or served twice — which is exactly the shape of event this log
      // exists to record.
      final at = DateTime.utc(2026, 3, 1, 19, 30);
      for (var i = 0; i < 25; i++) {
        await db
            .into(db.auditEntries)
            .insert(
              AuditEntriesCompanion.insert(
                id: 'a${i.toString().padLeft(2, '0')}',
                type: AuditType.voidItem.name,
                title: 'void $i',
                at: at,
              ),
            );
      }
      final router = referenceRoutes(db, WsHub(), caller.auth).call;

      final seen = <String>[];
      String? cursor;
      var pages = 0;
      do {
        final q = cursor == null
            ? '/audit/venue?limit=10'
            : '/audit/venue?limit=10&before=${Uri.encodeQueryComponent(cursor)}';
        final body = await getJson(router, q) as Map<String, dynamic>;
        seen.addAll([for (final e in body['items'] as List) e['id'] as String]);
        cursor = body['nextCursor'] as String?;
        pages++;
        expect(pages, lessThan(10), reason: 'cursor is not advancing');
      } while (cursor != null);

      expect(seen.length, 25, reason: 'a row was dropped at a page boundary');
      expect(seen.toSet().length, 25, reason: 'a row was served on two pages');
    },
  );

  // ---------------------------------------------------------------------
  // 2. The tiles agree with the table.
  // ---------------------------------------------------------------------

  test('summary counts the filtered window, not the page', () async {
    final now = DateTime.utc(2026, 3, 1, 12);
    for (var i = 0; i < 30; i++) {
      await writeAudit(
        db,
        type: AuditType.voidItem,
        kind: AuditKind.voidItem,
        params: {'qty': '1', 'name': 'void $i', 'amount': 'Rp. 1.000'},
        amountCents: 1000,
      );
    }
    await writeAudit(
      db,
      type: AuditType.comp,
      kind: AuditKind.comp,
      params: const {'qty': '1', 'name': 'comp', 'amount': 'Rp. 500'},
      amountCents: 500,
    );
    // Yesterday — inside the type filter but outside the time window.
    await db
        .into(db.auditEntries)
        .insert(
          AuditEntriesCompanion.insert(
            id: 'old',
            type: AuditType.voidItem.name,
            title: 'old void',
            at: now.subtract(const Duration(days: 2)),
            amountCents: const Value(99999),
          ),
        );

    final router = referenceRoutes(db, WsHub(), caller.auth).call;
    final from = now.subtract(const Duration(days: 1)).toIso8601String();
    final body =
        await getJson(router, '/audit/venue?limit=5&from=$from')
            as Map<String, dynamic>;
    final summary = (body['summary'] as Map).cast<String, dynamic>();

    // Only five rows came back, but the tile has to speak for all thirty.
    expect((body['items'] as List).length, 5);
    expect(summary[AuditType.voidItem.name]['count'], 30);
    expect(summary[AuditType.voidItem.name]['amount'], 30 * 1000);
    expect(summary[AuditType.comp.name]['count'], 1);

    // And the window has to bind the tile too — the old row is excluded from
    // both, or the amount would carry a day that is not on screen.
    expect(summary[AuditType.voidItem.name]['amount'], isNot(contains(99999)));

    // A type filter narrows the summary the same way.
    final onlyComps =
        await getJson(
              router,
              '/audit/venue?from=$from&type=${AuditType.comp.name}',
            )
            as Map<String, dynamic>;
    final compSummary = (onlyComps['summary'] as Map).cast<String, dynamic>();
    expect(compSummary.keys, [AuditType.comp.name]);
    expect((onlyComps['items'] as List).length, 1);
  });

  // ---------------------------------------------------------------------
  // 3. Who may read what.
  // ---------------------------------------------------------------------

  group('permissions', () {
    late ServerAuth auth;
    late Handler router;

    /// Seed a role + user and sign in, returning the bearer token.
    Future<String> signIn(String id, String pin, Set<Capability> caps) async {
      await db
          .into(db.roles)
          .insertOnConflictUpdate(
            RolesCompanion.insert(
              id: 'role-$id',
              name: 'Role $id',
              capabilitiesJson: Value(
                jsonEncode([for (final c in caps) c.name]),
              ),
            ),
          );
      await db
          .into(db.users)
          .insertOnConflictUpdate(
            UsersCompanion.insert(
              id: id,
              name: id,
              initials: id.substring(0, 2).toUpperCase(),
              roleId: 'role-$id',
              pinHash: auth.hashPin(pin),
            ),
          );
      final s = await auth.signInWithPin(pin: pin, deviceId: 'dev-$id');
      return s!.token;
    }

    Future<Response> getAs(String path, String token) async => await router(
      Request(
        'GET',
        Uri.parse('http://x$path'),
        headers: {'authorization': 'Bearer $token'},
      ),
    );

    setUp(() async {
      auth = ServerAuth(db, secret: 'test-secret');
      router = referenceRoutes(db, WsHub(), auth).call;
      await writeAudit(
        db,
        type: AuditType.voidItem,
        kind: AuditKind.voidItem,
        params: const {'qty': '1', 'name': 'a void', 'amount': 'Rp. 0'},
      );
      await writeAudit(
        db,
        type: AuditType.staffPinReset,
        kind: AuditKind.staffPinReset,
        params: const {'name': 'a waiter'},
      );
    });

    test('viewReports is required to read the log at all', () async {
      final token = await signIn('waiter', '1111', {Capability.takeOrder});
      final res = await getAs('/audit/venue', token);
      expect(res.statusCode, 403);
    });

    test(
      'admin rows need manageStaff, in the table and in the tiles',
      () async {
        // A cashier may read the venue's money history but not its personnel
        // history — an unauthorised reader must not learn a PIN was reset, and
        // must not see the count either, which would leak the same fact.
        final cashier = await signIn('cashier', '2222', {
          Capability.viewReports,
        });
        final body =
            jsonDecode(
                  await (await getAs('/audit/venue', cashier)).readAsString(),
                )
                as Map<String, dynamic>;
        final types = [
          for (final e in body['items'] as List) e['type'] as String,
        ];
        expect(types, contains(AuditType.voidItem.name));
        expect(types, isNot(contains(AuditType.staffPinReset.name)));
        expect(
          (body['summary'] as Map).containsKey(AuditType.staffPinReset.name),
          isFalse,
          reason: 'a hidden row must not be counted either',
        );

        // The manager sees both.
        final mgr = await signIn('mgr', '3333', {
          Capability.viewReports,
          Capability.manageStaff,
        });
        final full =
            jsonDecode(await (await getAs('/audit/venue', mgr)).readAsString())
                as Map<String, dynamic>;
        expect([
          for (final e in full['items'] as List) e['type'] as String,
        ], contains(AuditType.staffPinReset.name));
      },
    );
  });

  // ---------------------------------------------------------------------
  // 4. The freeze rule.
  // ---------------------------------------------------------------------

  group('a line is frozen once the kitchen owns it', () {
    late Handler tickets;

    Future<void> seedTicket(String id, String status) => db
        .into(db.tickets)
        .insert(
          TicketsCompanion.insert(
            id: id,
            tableId: 't1',
            itemId: 'i1',
            name: 'Nasi Goreng',
            course: 'mains',
            qty: const Value(2),
            price: 25000,
            status: status,
            sentAt: DateTime.utc(2026, 3, 1, 19),
          ),
        );

    Future<Response> patch(String id, Map<String, dynamic> body) async =>
        await tickets(
          Request(
            'PATCH',
            Uri.parse('http://x/tickets/$id'),
            body: jsonEncode(body),
            headers: caller.headers,
          ),
        );

    setUp(() {
      // The caller holds every capability, so what is under test is the
      // status rule itself rather than the permission in front of it.
      tickets = ticketsRoutes(db, WsHub(), caller.auth).call;
    });

    test('a held line accepts an edit', () async {
      await seedTicket('k1', 'held');
      final res = await patch('k1', {'qty': 3, 'note': 'tanpa sambal'});
      expect(res.statusCode, 200);

      final row = await (db.select(
        db.tickets,
      )..where((t) => t.id.equals('k1'))).getSingle();
      expect(row.qty, 3);
      expect(row.note, 'tanpa sambal');
    });

    test('a sent line refuses, and is left untouched', () async {
      await seedTicket('k2', 'sent');
      final res = await patch('k2', {'qty': 9});
      expect(res.statusCode, 409);
      expect(
        jsonDecode(await res.readAsString())['code'],
        'line_frozen',
        reason: 'the client needs to tell this apart from a generic conflict',
      );

      final row = await (db.select(
        db.tickets,
      )..where((t) => t.id.equals('k2'))).getSingle();
      expect(row.qty, 2, reason: 'a rejected edit must not half-apply');
    });

    test('every post-fire status refuses', () async {
      for (final s in ['sent', 'prep', 'cooked', 'ready', 'served']) {
        await seedTicket('k-$s', s);
        expect(
          (await patch('k-$s', {'qty': 4})).statusCode,
          409,
          reason: '$s must not be editable',
        );
      }
    });

    test('an accepted edit is audited with the value it moved', () async {
      await seedTicket('k3', 'held');
      await patch('k3', {'qty': 4, 'unitPrice': 25000});
      final rows = await (db.select(
        db.auditEntries,
      )..where((a) => a.type.equals(AuditType.modify.name))).get();
      expect(rows, hasLength(1));
      // 2 × 25000 → 4 × 25000, so the change is worth 50000.
      expect(rows.single.amountCents, 50000);
    });
  });

  // ---------------------------------------------------------------------
  // 5. The export is the whole window.
  // ---------------------------------------------------------------------

  test('the CSV carries every filtered row, not just the first page', () async {
    for (var i = 0; i < 120; i++) {
      await writeAudit(
        db,
        type: AuditType.voidItem,
        kind: AuditKind.voidItem,
        params: {'qty': '1', 'name': 'void $i', 'amount': 'Rp. 0'},
      );
    }
    final router = referenceRoutes(db, WsHub(), caller.auth).call;

    // One page is capped well below the total.
    final page =
        await getJson(router, '/audit/venue?limit=50') as Map<String, dynamic>;
    expect((page['items'] as List).length, 50);
    expect(page['nextCursor'], isNotNull);

    final res = await get(router, '/audit/venue.csv');
    expect(res.headers['content-type'], contains('text/csv'));
    final lines = (await res.readAsString())
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    // Header + every row.
    expect(lines.length, 121);
  });

  test('a CSV cell carrying a comma or a quote stays one cell', () async {
    await writeAudit(
      db,
      type: AuditType.voidItem,
      kind: AuditKind.voidItem,
      // The comma and the quotes reach the CSV through a *parameter* now, which
      // is the shape a real row has — the sentence around them is the template.
      params: const {
        'qty': '1',
        'name': '"Nasi Goreng", meja 4',
        'amount': 'Rp. 0',
      },
      reason: 'tamu bilang: "salah pesan"',
    );
    final router = referenceRoutes(db, WsHub(), caller.auth).call;
    final csv = await (await get(router, '/audit/venue.csv')).readAsString();
    final row = csv.split('\n')[1];
    // Quotes doubled, field wrapped — otherwise the reason column shifts into
    // the next one and every later column reads as the wrong field.
    expect(row, contains('"Dibatalkan ×1 ""Nasi Goreng"", meja 4 · Rp. 0"'));
  });
}
