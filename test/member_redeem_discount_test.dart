// A points redemption is rupiah off, not a percentage.
//
// The bug this pins was silent and total: the `redeem`-slot discount row went
// in with a kind `resolveDiscountAmount` does not know, and every kind that is
// not 'fixed' is read as **basis points**. 50 poin worth Rp 50.000 became a
// value of 50000 bps, clamped to 10000 — 100% off. The bill settled at Rp 0
// and nothing threw.
//
// See docs/adr/0094-a-bill-discount-has-a-source.md and
// docs/adr/0095-points-earn-at-bill-close-and-never-expire.md.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/members.dart';
import 'package:satset/server/routes/settlement_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late TestCaller caller;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Route gates want a real caller now (ADR-0102).
    caller = await signInForTest(db);
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            membersEnabled: const Value(true),
            memberPointsEnabled: const Value(true),
            memberPointValue: const Value(1000),
            memberRedeemMin: const Value(10),
            // No service, no tax — the arithmetic under test is the discount.
            serviceEnabled: const Value(false),
            taxEnabled: const Value(false),
          ),
        );
  });
  tearDown(() => db.close());

  test('redeeming points takes their rupiah value off, not the bill', () async {
    final member = await createMember(db, name: 'Budi', phone: '081234567890');
    await adjustPoints(db, memberId: member.id, delta: 50, note: 'seed');

    await db
        .into(db.visits)
        .insert(
          VisitsCompanion.insert(
            id: 'v1',
            tableId: 't1',
            memberId: Value(member.id),
            openedAt: Value(DateTime.now().toUtc()),
            createdAt: DateTime.now().toUtc(),
          ),
        );
    await db
        .into(db.tickets)
        .insert(
          TicketsCompanion.insert(
            id: 'tk1',
            tableId: 't1',
            visitId: const Value('v1'),
            itemId: 'i1',
            name: 'Nasi Goreng',
            course: 'mains',
            qty: const Value(2),
            price: 85000,
            status: 'sent',
            sentAt: DateTime.now().toUtc(),
          ),
        );

    final router = settlementRoutes(db, WsHub(), caller.auth).call;
    final res = await router(
      Request(
        'POST',
        Uri.parse('http://x/settlement/visits/v1/redeem'),
        body: jsonEncode({'points': 50}),
        headers: caller.headers,
      ),
    );
    expect(res.statusCode, 200);

    final bill = ((jsonDecode(await res.readAsString()) as Map)['bill'] as Map)
        .cast<String, dynamic>();
    expect(bill['subtotal'], 170000);
    expect(bill['discountAmount'], 50000, reason: '50 poin x Rp1.000');
    expect(bill['total'], 120000, reason: 'the whole bill was discounted away');

    // The ledger and the bill move together — the points really left.
    expect(await memberPoints(db, member.id), 0);

    // The slot has to survive the wire (ADR-0094). Drop `source` and every row
    // reads as `manual` on the client: the member panel loses its undo button
    // and the printed Diskon label names a redemption as the cashier's promo.
    final discs = (bill['billDiscounts'] as List).cast<Map>();
    expect(discs.single['source'], 'redeem');
  });
}
