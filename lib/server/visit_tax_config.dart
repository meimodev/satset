import 'dart:convert';

import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/server/db/database.dart';

Future<TaxServiceConfig> venueTaxConfig(AppDatabase db) async {
  final settings = await (db.select(
    db.venueSettings,
  )..where((s) => s.id.equals('default'))).getSingleOrNull();
  return TaxServiceConfig(
    taxEnabled: settings?.taxEnabled ?? false,
    taxRateBps: settings?.taxRateBps ?? 1100,
    serviceEnabled: settings?.serviceEnabled ?? false,
    serviceMode: settings?.serviceMode ?? 'percent',
    serviceRateBps: settings?.serviceRateBps ?? 500,
    serviceFixedAmount: settings?.serviceFixedAmount ?? 0,
    taxAfterDiscount: settings?.taxAfterDiscount ?? true,
  );
}

Future<TaxServiceConfig> visitTaxConfig(AppDatabase db, String visitId) async {
  final visit = await (db.select(
    db.visits,
  )..where((v) => v.id.equals(visitId))).getSingleOrNull();
  final session = visit == null
      ? await (db.select(
          db.tableSessions,
        )..where((s) => s.id.equals(visitId))).getSingleOrNull()
      : null;
  final json = visit?.taxConfigJson ?? session?.taxConfigJson;
  if (json != null) {
    try {
      return TaxServiceConfig.fromJson(
        (jsonDecode(json) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      // Old or damaged snapshots fall back to venue configuration.
    }
  }
  return venueTaxConfig(db);
}
