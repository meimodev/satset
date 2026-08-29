// The void path, end to end through the real shelf route: what the server
// demands of a reason, who the row is attributed to, and what a refusal
// answers with.
//
// It exists because the reason contract broke silently. ADR-0085 stopped the
// client sending a localized label, ADR-0006's server guard still demanded
// non-empty free text, and four of the five reasons the picker offers started
// returning `400 reason_required` — with no test in the suite that ever posted
// a void without free text.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/tickets_routes.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:shelf/shelf.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late Handler router;
  late TestCaller caller;

  Future<String> seedTicket({String status = 'sent'}) async {
    const id = 'tk-1';
    await db
        .into(db.tickets)
        .insertOnConflictUpdate(
          TicketsCompanion.insert(
            id: id,
            tableId: 't-1',
            itemId: 'i1',
            name: 'Nasi Ayam',
            qty: const Value(2),
            price: 25000,
            status: status,
            course: 'mains',
            sentAt: DateTime.now(),
          ),
        );
    return id;
  }

  Future<Response> voidLine(
    String id,
    Map<String, dynamic> body, {
    TestCaller? as,
  }) async => router(
    Request(
      'POST',
      Uri.parse('http://x/tickets/$id/transition'),
      body: jsonEncode({'status': 'voided', ...body}),
      headers: (as ?? caller).headers,
    ),
  );

  Future<Ticket> read(String id) => (db.select(
    db.tickets,
  )..where((t) => t.id.equals(id))).getSingle();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    caller = await signInForTest(db);
    router = ticketsRoutes(db, WsHub(), caller.auth).call;
    await db
        .into(db.venueTables)
        .insertOnConflictUpdate(
          VenueTablesCompanion.insert(
            id: 't-1',
            zoneId: 'z-1',
            label: const Value('Meja 1'),
          ),
        );
  });

  tearDown(() => db.close());

  test('a canonical reason code voids with no free text at all', () async {
    // The regression. Every reason but `other` sends an empty `voidReason`,
    // because the words are composed at read time from the code (ADR-0085).
    for (final code in const [
      'wrongOrder',
      'customerChange',
      'outOfStock',
      'kitchenError',
    ]) {
      final id = await seedTicket();
      final res = await voidLine(id, {
        'voidReason': '',
        'voidReasonCode': code,
      });
      expect(res.statusCode, 200, reason: 'reason code $code was refused');
      final row = await read(id);
      expect(row.status, 'voided');
      expect(row.voidReasonCode, code);
    }
  });

  test('`other` still has to say what it means', () async {
    final id = await seedTicket();
    final res = await voidLine(id, {
      'voidReason': '   ',
      'voidReasonCode': 'other',
    });
    expect(res.statusCode, 400);
    expect(
      jsonDecode(await res.readAsString())['code'],
      'reason_required',
    );
    expect((await read(id)).status, 'sent');
  });

  test('a void with no code at all is still refused', () async {
    final id = await seedTicket();
    final res = await voidLine(id, {'voidReason': 'apa saja'});
    expect(res.statusCode, 400);
    expect(jsonDecode(await res.readAsString())['code'], 'reason_required');
  });

  test('a served line costs compItem, and the refusal says so', () async {
    final waiter = await signInForTest(
      db,
      caps: {Capability.takeOrder, Capability.voidItem},
      userId: 'waiter-1',
    );
    final id = await seedTicket(status: 'served');
    final res = await voidLine(id, {
      'voidReason': '',
      'voidReasonCode': 'comp',
    }, as: waiter);
    expect(res.statusCode, 403);
    expect(jsonDecode(await res.readAsString())['code'], 'forbidden');
    expect((await read(id)).status, 'served');
  });

  test('a replayed void is attributed to the waiter, not the drainer', () async {
    // A drain runs under whoever is signed in when the socket returns. Without
    // `actorId` one waiter's backlog lands under the next one's name, in the
    // per-waiter void rate that is ADR-0006's entire deterrent.
    final id = await seedTicket();
    final res = await voidLine(id, {
      'voidReason': '',
      'voidReasonCode': 'customerChange',
      'actorId': 'waiter-who-voided',
    });
    expect(res.statusCode, 200);
    expect((await read(id)).voidedByUserId, 'waiter-who-voided');
  });

  test('a live void with no actorId still takes the bearer', () async {
    final id = await seedTicket();
    await voidLine(id, {'voidReason': '', 'voidReasonCode': 'outOfStock'});
    expect((await read(id)).voidedByUserId, caller.userId);
  });

  test('voiding an already-voided line is a 409, which is what makes replay '
      'safe', () async {
    final id = await seedTicket(status: 'voided');
    final res = await voidLine(id, {
      'voidReason': '',
      'voidReasonCode': 'outOfStock',
    });
    expect(res.statusCode, 409);
    expect(
      jsonDecode(await res.readAsString())['code'],
      'illegal_transition',
    );
  });
}
