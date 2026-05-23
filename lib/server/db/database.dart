import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Users,
  Roles,
  Zones,
  VenueTables,
  MenuCategories,
  MenuItems,
  ModifierGroups,
  Tickets,
  Sessions,
  Devices,
  PairTokens,
  Idempotency,
  AuditEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'satset.sqlite'));
    final executor = NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA journal_mode=WAL;'),
    );
    return AppDatabase(executor);
  }
}
