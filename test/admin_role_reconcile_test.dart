import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/db/seed.dart';
import 'package:satset/server/db/seed_data.dart' as seed;

/// The admin role **is** `Capability.values` by definition, and the Staf sheet
/// shows it read-only — so a stored snapshot of it is the one capability set
/// nobody in the venue can repair by hand.
///
/// That is not hypothetical: adding `manageCash` to the enum once left every
/// already-seeded venue's admin at the old count, holding a capability list
/// that no longer matched the routes, with no UI path back. `_ensureAdminRole`
/// rewrites the row on every Server boot for exactly that reason, and this is
/// what stops the next person from "optimising" it into a write-once.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<String>> adminCaps() async {
    final row = await (db.select(
      db.roles,
    )..where((r) => r.id.equals(seed.DummyData.roleAdminId))).getSingleOrNull();
    return (jsonDecode(row!.capabilitiesJson) as List).cast<String>();
  }

  test('a fresh venue gets an admin role holding every capability', () async {
    await seedInfra(db);
    expect(await adminCaps(), [for (final c in Capability.values) c.name]);
  });

  test('a stale admin role is repaired on the next boot', () async {
    await seedInfra(db);

    // What an upgrade looks like from the row's point of view: the enum grew,
    // and the stored list is now the old one.
    await (db.update(
      db.roles,
    )..where((r) => r.id.equals(seed.DummyData.roleAdminId))).write(
      RolesCompanion(capabilitiesJson: Value(jsonEncode(['viewKds']))),
    );
    expect(await adminCaps(), ['viewKds']);

    await seedInfra(db);

    expect(
      await adminCaps(),
      [for (final c in Capability.values) c.name],
      reason: 'a capability added to the enum has no other way to reach an '
          'already-seeded venue: the Staf sheet will not edit this role',
    );
  });

  test('reconciling does not disturb the rest of the row', () async {
    await seedInfra(db);
    final before = await (db.select(
      db.roles,
    )..where((r) => r.id.equals(seed.DummyData.roleAdminId))).getSingle();

    await seedInfra(db);
    final after = await (db.select(
      db.roles,
    )..where((r) => r.id.equals(seed.DummyData.roleAdminId))).getSingle();

    expect(after.name, before.name);
    expect(after.colorHex, before.colorHex);
  });

  test('a non-admin role keeps whatever the venue granted it', () async {
    await seedInfra(db);
    // A role the owner narrowed by hand on the Staf sheet. Every role but
    // admin stores its own set, and boot must not flatten that.
    await db
        .into(db.roles)
        .insertOnConflictUpdate(
          RolesCompanion.insert(
            id: 'role-kasir',
            name: 'Kasir',
            capabilitiesJson: Value(jsonEncode(['settleBill'])),
          ),
        );

    await seedInfra(db);

    final row = await (db.select(
      db.roles,
    )..where((r) => r.id.equals('role-kasir'))).getSingle();
    expect((jsonDecode(row.capabilitiesJson) as List), ['settleBill']);
  });
}
