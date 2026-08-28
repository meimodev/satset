// The seed guard is **self-tripping and one-way** (ADR-0052 §3): once a venue
// holds a live ticket or an archived session, `canSeedSample` is false and
// nothing brings it back — `clearSampleData` deletes by the `contoh-` tag, so
// it can never reach a row a real order wrote.
//
// That is the whole of the "reseed always errors" report: the dialog offered
// clear-and-retry, the clear succeeded, and the retry 409'd every time. What
// is pinned here is the 409 itself, plus the `failed` verdict surviving in
// `/seed/state` rather than living only in the `seed.progress` broadcast.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/reference_routes.dart';
import 'package:satset/server/seed_job.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late WsHub hub;
  late TestCaller caller;
  late Router router;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    hub = WsHub();
    caller = await signInForTest(db);
    router = referenceRoutes(db, hub, caller.auth);
  });
  tearDown(() async => db.close());

  Future<Response> get(String path) =>
      router.call(Request('GET', Uri.parse('http://x$path'),
          headers: caller.headers));

  Future<Response> post(String path) => router.call(
        Request('POST', Uri.parse('http://x$path'),
            headers: {...caller.headers, 'content-type': 'application/json'},
            body: '{}'),
      );

  Future<Map<String, dynamic>> state() async =>
      jsonDecode(await (await get('/seed/state')).readAsString())
          as Map<String, dynamic>;

  /// One live ticket is enough — the guard is "any ticket row", not "any
  /// settled bill", because closing a bill hard-deletes its tickets.
  Future<void> tradeOnce() => db.into(db.tickets).insert(
        TicketsCompanion.insert(
          id: 'real-1',
          tableId: 't1',
          itemId: 'i1',
          name: 'Nasi Goreng',
          course: 'mains',
          price: 35000,
          status: 'sent',
          sentAt: DateTime.now(),
        ),
      );

  test('a traded venue is refused, with a code the client can read', () async {
    await tradeOnce();
    expect((await state())['canSeed'], isFalse);

    final res = await post('/seed/generic');
    expect(res.statusCode, 409);
    expect(
      jsonDecode(await res.readAsString())['code'],
      'seedRefused',
    );
  });

  test('a clear does not free a traded venue', () async {
    await tradeOnce();
    expect((await post('/seed/clear')).statusCode, 200);
    // The row a real order wrote carries no `contoh-` tag, so the clear cannot
    // reach it — retrying after clearing is what 409'd forever.
    expect((await state())['canSeed'], isFalse);
    expect((await post('/seed/generic')).statusCode, 409);
  });

  test('a failed verdict reaches /seed/state', () async {
    await SeedJob.begin(db, daysTotal: 30);
    expect((await state())['failed'], isFalse);
    await SeedJob.markFailed(db);

    final s = await state();
    expect(s['failed'], isTrue);
    // Same recovery either way: the verdict changes the sentence, not the
    // button.
    expect(s['seedIncomplete'], isTrue);
  });

  test('a clear keeps the answer the venue already gave', () async {
    await SeedJob.markSkipped(db);
    expect((await post('/seed/clear')).statusCode, 200);
    expect((await state())['promptAnswered'], isTrue);
  });
}
