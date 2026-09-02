import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/discount_preset_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a bill preset can be authored and returned in the catalogue', () async {
    final caller = await signInForTest(db, caps: {Capability.editSettings});
    final router = discountPresetRoutes(db, WsHub(), caller.auth).call;

    final created = await router(
      Request(
        'POST',
        Uri.parse('http://x/venue/discount-presets'),
        headers: {...caller.headers, 'content-type': 'application/json'},
        body: jsonEncode({
          'name': 'Whole table 10%',
          'scope': 'bill',
          'kind': 'percent',
          'value': 1000,
        }),
      ),
    );

    expect(created.statusCode, 200);
    expect(jsonDecode(await created.readAsString())['scope'], 'bill');

    final listed = await router(
      Request(
        'GET',
        Uri.parse('http://x/venue/discount-presets'),
        headers: caller.headers,
      ),
    );
    final presets = (jsonDecode(await listed.readAsString())['presets'] as List)
        .cast<Map<String, dynamic>>();
    expect(presets.single['scope'], 'bill');
  });
}
