import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/printers_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  test(
    'shared printer relays reviewed bytes; rejects unsigned and invalid jobs',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(db.close);
      addTearDown(server.close);
      final caller = await signInForTest(db);
      await db
          .into(db.printers)
          .insert(
            PrintersCompanion.insert(
              id: 'front',
              label: 'Front desk',
              host: '127.0.0.1',
              port: Value(server.port),
              createdAt: DateTime.now(),
            ),
          );
      final router = printersRoutes(db, WsHub(), caller.auth);
      Future<Response> request(
        Object body, {
        bool signed = true,
        String id = 'front',
      }) => router.call(
        Request(
          'POST',
          Uri.parse('http://host/printers/$id/print'),
          headers: {
            if (signed) ...caller.headers,
            'content-type': 'application/json',
          },
          body: jsonEncode(body),
        ),
      );
      expect((await request({'bytes': 'AQID'}, signed: false)).statusCode, 401);
      expect((await request({'bytes': 123})).statusCode, 400);
      expect((await request({'bytes': '%%%'})).statusCode, 400);
      expect((await request({'bytes': ''})).statusCode, 400);
      expect((await request({'bytes': 'AQID'}, id: 'missing')).statusCode, 404);
      await (db.update(db.printers)..where((p) => p.id.equals('front'))).write(
        const PrintersCompanion(enabled: Value(false)),
      );
      expect((await request({'bytes': 'AQID'})).statusCode, 404);
      await (db.update(db.printers)..where((p) => p.id.equals('front'))).write(
        const PrintersCompanion(enabled: Value(true)),
      );

      final received = Completer<List<int>>();
      server.listen((socket) async {
        final bytes = await socket.fold<List<int>>(
          [],
          (all, chunk) => all..addAll(chunk),
        );
        socket.destroy();
        received.complete(bytes);
      });
      final bytes = [27, 64, ...utf8.encode('Reviewed receipt\n'), 29, 86, 0];
      expect((await request({'bytes': base64Encode(bytes)})).statusCode, 200);
      expect(await received.future.timeout(const Duration(seconds: 5)), bytes);
    },
  );
}
