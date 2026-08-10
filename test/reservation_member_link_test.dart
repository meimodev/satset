// A booking made against a [[Pelanggan (member)]] hands the member to the
// visit it opens.
//
// Without this the picker on the reservation screen is decoration: the host
// finds the regular, the booking stores who they are, and then the till opens
// a blank visit and the cashier looks the same person up again — which is the
// duplicate-entry the link exists to kill.
//
// See docs/adr/0092 (a member is a phone number) and the `memberId` column on
// `Reservations` in lib/server/db/tables.dart.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/members.dart';
import 'package:satset/server/routes/reservations_routes.dart';
import 'package:satset/server/routes/tables_routes.dart';
import 'package:satset/server/ws_hub.dart';

void main() {
  late AppDatabase db;
  late WsHub hub;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    hub = WsHub();
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            membersEnabled: const Value(true),
          ),
        );
    await db
        .into(db.venueTables)
        .insert(
          VenueTablesCompanion.insert(
            id: 't1',
            label: const Value('D1'),
            zoneId: 'z1',
            capacity: const Value(4),
            status: const Value('available'),
          ),
        );
  });
  tearDown(() => db.close());

  test('a booking carries its member, and hands it to the visit', () async {
    final member = await createMember(db, name: 'Budi', phone: '081234567890');

    // The wire has to carry the link both ways, or the client cannot draw the
    // member glyph on a row it just created.
    final res = await reservationsRoutes(db, hub).call(
      Request(
        'POST',
        Uri.parse('http://x/reservations'),
        body: jsonEncode({
          'name': 'Budi',
          'phone': '081234567890',
          'partySize': 2,
          'expectedAt': DateTime.now().toUtc().toIso8601String(),
          'memberId': member.id,
        }),
      ),
    );
    expect(res.statusCode, 200);
    final booking = jsonDecode(await res.readAsString()) as Map;
    expect(booking['memberId'], member.id);

    final seat = await tablesRoutes(db, hub).call(
      Request(
        'POST',
        Uri.parse('http://x/tables/t1/seat'),
        body: jsonEncode({'pax': 2, 'reservationId': booking['id']}),
      ),
    );
    expect(seat.statusCode, 200);

    final visit = await (db.select(
      db.visits,
    )..where((v) => v.tableId.equals('t1'))).getSingle();
    expect(
      visit.memberId,
      member.id,
      reason: 'the till must open with the member already attached',
    );
  });

  test('a walk-in seat opens a visit with no member', () async {
    final seat = await tablesRoutes(db, hub).call(
      Request(
        'POST',
        Uri.parse('http://x/tables/t1/seat'),
        body: jsonEncode({'pax': 2}),
      ),
    );
    expect(seat.statusCode, 200);
    final visit = await (db.select(
      db.visits,
    )..where((v) => v.tableId.equals('t1'))).getSingle();
    expect(visit.memberId, isNull);
  });

  test('clearing the link unlinks the booking, not the member', () async {
    final member = await createMember(db, name: 'Budi', phone: '081234567890');
    final router = reservationsRoutes(db, hub).call;
    final made =
        jsonDecode(
              await (await router(
                Request(
                  'POST',
                  Uri.parse('http://x/reservations'),
                  body: jsonEncode({
                    'name': 'Budi',
                    'expectedAt': DateTime.now().toUtc().toIso8601String(),
                    'memberId': member.id,
                  }),
                ),
              )).readAsString(),
            )
            as Map;

    final patched = await router(
      Request(
        'PATCH',
        Uri.parse('http://x/reservations/${made['id']}'),
        body: jsonEncode({'memberId': null}),
      ),
    );
    expect(patched.statusCode, 200);
    expect((jsonDecode(await patched.readAsString()) as Map)['memberId'], null);
    expect(await getMember(db, member.id), isNotNull);
  });
}
