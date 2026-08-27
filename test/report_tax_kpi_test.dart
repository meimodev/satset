// **Pajak + service** on the Laporan screen — the KPI that used to be a guess.
//
// It was `net * 0.18`, documented as a cosmetic estimate (ADR-0032 §1) on the
// grounds that the real figures were only in the accounting export. They are
// not: `bill_math.dart` freezes `taxAmount` / `serviceAmount` onto the very
// `table_sessions` rows the sales fold already walks. The estimate therefore
// bought nothing and cost the one thing a report owes — being true — including
// for a venue that charges neither, which the unconditional multiply billed
// anyway.
//
// What is pinned here: the KPI is the sum of what was actually collected, and
// a venue collecting nothing gets a zero rather than 18% of its takings.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/reports_routes.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(VenueSettingsCompanion.insert(id: 'default'));
  });
  tearDown(() => db.close());

  final now = DateTime.now().toUtc();

  /// One bill closed in today's window carrying the figures a settlement
  /// would have frozen onto it.
  Future<void> closeBill(
    String id, {
    required int settled,
    int tax = 0,
    int service = 0,
  }) => db
      .into(db.tableSessions)
      .insert(
        TableSessionsCompanion.insert(
          id: id,
          tableId: 't1',
          zoneId: 'z1',
          openedAt: Value(now.subtract(const Duration(hours: 1))),
          closedAt: now,
          pax: const Value(2),
          subtotal: Value(settled),
          settledTotal: Value(settled),
          taxAmount: Value(tax),
          serviceAmount: Value(service),
        ),
      );

  Future<Map<String, dynamic>> taxKpi() async {
    final caller = await signInForTest(db);
    final res = await reportsRoutes(db, caller.auth).call(
      Request(
        'GET',
        Uri.parse('http://x/reports/snapshot?range=today'),
        headers: caller.headers,
      ),
    );
    final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
    final kpis =
        (body['sales'] as Map<String, dynamic>)['kpis'] as List<dynamic>;
    return kpis.cast<Map<String, dynamic>>().firstWhere(
      (k) => k['key'] == 'taxService',
    );
  }

  test('the KPI sums the tax and service actually collected', () async {
    await closeBill('s1', settled: 111000, tax: 11000, service: 5000);
    await closeBill('s2', settled: 222000, tax: 22000, service: 10000);

    // 48.000 — not 0.18 × 333.000 = 59.940, which is what the estimate said.
    expect((await taxKpi())['rupiah'], 48000);
  });

  test(
    'a venue charging neither reports zero, and still gets the tile',
    () async {
      await closeBill('s1', settled: 500000);

      final kpi = await taxKpi();
      expect(kpi['rupiah'], 0);
    },
  );
}
