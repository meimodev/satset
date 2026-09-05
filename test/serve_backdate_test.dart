// A serve captured while the handset was terputus stamps `servedAt` from when
// the plate went down, not from when the queue drained (ADR-0138).
//
// It exists because the failure is invisible in the app and only shows up in a
// report a month later: `servedAt − readyAt` is the pickup-lag metric, so a
// 25-minute reconnect books 25 minutes of food dying under the lamp against a
// waiter who served instantly. The lower clamp guards the nastier half — a
// handset whose clock runs slow would mint a *negative* lag, which
// `reports_routes` does not reject but silently discards, so the sample
// disappears rather than being visibly wrong.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/tickets_routes.dart';
import 'package:satset/server/ws_hub.dart';
import 'package:shelf/shelf.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late Handler router;
  late TestCaller caller;

  final readyAt = DateTime.now().subtract(const Duration(minutes: 30));

  Future<String> seedReadyTicket() async {
    const id = 'tk-1';
    await db
        .into(db.tickets)
        .insertOnConflictUpdate(
          TicketsCompanion.insert(
            id: id,
            tableId: 't-1',
            itemId: 'i1',
            name: 'Nasi Ayam',
            qty: const Value(1),
            price: 25000,
            status: 'ready',
            course: 'mains',
            sentAt: readyAt.subtract(const Duration(minutes: 10)),
            readyAt: Value(readyAt),
          ),
        );
    return id;
  }

  Future<Response> serve(String id, {DateTime? capturedAt}) async => router(
    Request(
      'POST',
      Uri.parse('http://x/tickets/$id/transition'),
      body: jsonEncode({
        'status': 'served',
        if (capturedAt != null) 'capturedAt': capturedAt.toIso8601String(),
      }),
      headers: caller.headers,
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

  test('a drained serve stamps servedAt from capture, not from drain', () async {
    final id = await seedReadyTicket();
    final captured = readyAt.add(const Duration(minutes: 2));

    final res = await serve(id, capturedAt: captured);
    expect(res.statusCode, 200);

    final t = await read(id);
    expect(t.servedAt!.difference(captured).inSeconds.abs(), lessThan(2));
    expect(
      t.servedAt!.difference(t.readyAt!).inMinutes,
      2,
      reason: 'the pickup lag is the plate, not the outage',
    );
  });

  test('a live serve with no capturedAt still stamps now', () async {
    final id = await seedReadyTicket();

    expect((await serve(id)).statusCode, 200);

    final t = await read(id);
    expect(
      t.servedAt!.difference(DateTime.now()).inSeconds.abs(),
      lessThan(5),
      reason: 'the online path is unchanged',
    );
  });

  test('a capture before readyAt clamps up instead of minting a negative lag',
      () async {
    final id = await seedReadyTicket();

    final res = await serve(
      id,
      capturedAt: readyAt.subtract(const Duration(minutes: 5)),
    );
    expect(res.statusCode, 200);

    final t = await read(id);
    expect(t.servedAt, t.readyAt);
    expect(
      t.servedAt!.isBefore(t.readyAt!),
      isFalse,
      reason: 'a negative lag is discarded by the report, not flagged',
    );
  });

  test('a capture from the future clamps down to now', () async {
    final id = await seedReadyTicket();

    final res = await serve(
      id,
      capturedAt: DateTime.now().add(const Duration(hours: 3)),
    );
    expect(res.statusCode, 200);

    final t = await read(id);
    expect(t.servedAt!.isAfter(DateTime.now()), isFalse);
  });

  test('capturedAt is ignored on every other transition', () async {
    // Only a serve is backdatable. `readyAt` is a fact the host observed
    // itself, and a handset must not move it.
    const id = 'tk-2';
    await db
        .into(db.tickets)
        .insertOnConflictUpdate(
          TicketsCompanion.insert(
            id: id,
            tableId: 't-1',
            itemId: 'i1',
            name: 'Es Teh',
            qty: const Value(1),
            price: 8000,
            status: 'cooked',
            course: 'drinks',
            sentAt: DateTime.now().subtract(const Duration(minutes: 20)),
          ),
        );

    final res = await router(
      Request(
        'POST',
        Uri.parse('http://x/tickets/$id/transition'),
        body: jsonEncode({
          'status': 'ready',
          'capturedAt': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
        }),
        headers: caller.headers,
      ),
    );
    expect(res.statusCode, 200);

    final t = await read(id);
    expect(t.readyAt!.difference(DateTime.now()).inSeconds.abs(), lessThan(5));
  });
}
