// The venue day is an **audit pair, not an entity** (ADR-0111).
//
// What is pinned here is the whole of the design: two routes, two capabilities,
// two rows, and no state anywhere that a second open could contradict. Opening
// twice is not an error — a day nobody stores cannot be "already open" — and
// closing does not care whether it was ever opened, because the log is a record
// of what people did, not a machine that refuses the second half of a sequence
// it never saw the first half of.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/venue_day_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late WsHub hub;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    hub = WsHub();
  });
  tearDown(() async => db.close());

  Future<Response> call(
    TestCaller? caller,
    String path, {
    Object? body,
  }) {
    final router = venueDayRoutes(
      db,
      hub,
      caller?.auth ?? ServerAuth(db, secret: 'test-secret'),
    );
    return router.call(
      Request(
        'POST',
        Uri.parse('http://x$path'),
        headers: {
          if (caller != null) ...caller.headers,
          'content-type': 'application/json',
        },
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<List<AuditEntry>> rows() => db.select(db.auditEntries).get();

  test('an unsigned caller marks nothing', () async {
    expect((await call(null, '/venue/day/open')).statusCode, 401);
    expect((await call(null, '/venue/day/close')).statusCode, 401);
    expect(await rows(), isEmpty);
  });

  test('each end wants its own capability', () async {
    final opener = await signInForTest(
      db,
      caps: {Capability.openDrawer},
      userId: 'opener',
      pin: '1111',
    );
    final closer = await signInForTest(
      db,
      caps: {Capability.closeShift},
      userId: 'closer',
      pin: '2222',
    );

    expect((await call(opener, '/venue/day/open')).statusCode, 200);
    expect((await call(opener, '/venue/day/close')).statusCode, 403);
    expect((await call(closer, '/venue/day/close')).statusCode, 200);
    expect((await call(closer, '/venue/day/open')).statusCode, 403);

    final kinds = [for (final r in await rows()) r.kind];
    expect(kinds, [
      AuditKind.venueOpened.name,
      AuditKind.venueClosed.name,
    ]);
  });

  test('a note rides along, and an empty one is not stored as one', () async {
    final c = await signInForTest(db, userId: 'both');
    await call(c, '/venue/day/close', body: {'note': ' mati lampu jam 8 '});
    await call(c, '/venue/day/open', body: {'note': '   '});
    final got = await rows();
    expect(got.first.reason, 'mati lampu jam 8');
    expect(got.last.reason, isNull);
  });

  test('opening twice is two rows, not an error', () async {
    final c = await signInForTest(db, userId: 'twice');
    expect((await call(c, '/venue/day/open')).statusCode, 200);
    expect((await call(c, '/venue/day/open')).statusCode, 200);
    expect(await rows(), hasLength(2));
  });
}
