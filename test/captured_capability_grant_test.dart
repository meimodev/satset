import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/auth_routes.dart';
import 'package:satset/server/routes/tables_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  test(
    'host grant accepts an old captured action after role revocation',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final caller = await signInForTest(db, caps: {Capability.takeOrder});
      final me = await authRoutes(caller.auth).call(Request(
        'GET',
        Uri.parse('http://x/auth/me'),
        headers: caller.headers,
      ));
      final grant = (jsonDecode(await me.readAsString()) as Map)['captureGrant']
          as String;
      await (db.update(db.roles)
            ..where((r) => r.id.equals('role-${caller.userId}')))
          .write(const RolesCompanion(capabilitiesJson: Value('[]')));
      final route = tablesRoutes(db, WsHub(), caller.auth).call;

      Future<Response> seat(Map<String, String> headers) => route(
        Request(
          'POST',
          Uri.parse('http://x/tables/missing/seat'),
          headers: headers,
          body: jsonEncode({'pax': 1}),
        ),
      );

      expect((await seat(caller.headers)).statusCode, 403);
      expect(
        (await seat({
          ...caller.headers,
          'x-idempotency-key': 'capture-1',
          'x-capture-grant': '${grant}tampered',
        })).statusCode,
        403,
      );
      expect(
        (await seat({
          ...caller.headers,
          'x-idempotency-key': 'capture-1',
          'x-capture-grant': grant,
        })).statusCode,
        isNot(403),
      );
    },
  );
}
