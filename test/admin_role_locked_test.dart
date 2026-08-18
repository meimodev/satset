// The admin role is immutable from the venue's own staff screen, through the
// real shelf routes and an in-memory database.
//
// The UI hides the controls, but the UI is not the guard — a venue's one admin
// is a Firebase identity (ADR-0077), and the capabilities its local role
// carries are the only thing standing between that account and the admin
// screens. Stripping `editSettings` off it locks the only admin out of the
// screen that could put it back, with no second admin role to repair it from.
// That edit used to be allowed: the old rule blocked *granting* manageStaff
// and said nothing about editing a role that already had it.
//
// See docs/adr/0077-one-admin-one-device.md and
// docs/adr/0017-main-device-host-and-admin-clients.md.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/reference_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late Handler router;
  late TestCaller caller;

  const adminRoleId = 'role-admin';
  const waiterRoleId = 'role-waiter';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Route gates want a real caller now (ADR-0102).
    caller = await signInForTest(db);
    router = referenceRoutes(db, WsHub(), caller.auth).call;
    await db
        .into(db.roles)
        .insertOnConflictUpdate(
          RolesCompanion.insert(
            id: adminRoleId,
            name: 'Admin',
            capabilitiesJson: Value(
              jsonEncode([for (final c in Capability.values) c.name]),
            ),
          ),
        );
    await db
        .into(db.roles)
        .insertOnConflictUpdate(
          RolesCompanion.insert(
            id: waiterRoleId,
            name: 'Waiter',
            capabilitiesJson: Value(
              jsonEncode([Capability.takeOrder.name, Capability.voidItem.name]),
            ),
          ),
        );
    // The venue's one admin, as auto-provisioned on first Firebase sign-in
    // (ADR-0015). Without it the last-admin guard rejects every role edit,
    // which is correct but is not the rule under test here.
    await db
        .into(db.users)
        .insertOnConflictUpdate(
          UsersCompanion.insert(
            id: 'admin-1',
            name: 'Admin',
            initials: 'AD',
            roleId: adminRoleId,
            pinHash: '',
            firebaseUid: const Value('uid-1'),
          ),
        );
  });
  tearDown(() => db.close());

  Future<Response> patchRole(String id, Map<String, dynamic> body) async =>
      router(
        Request(
          'PATCH',
          Uri.parse('http://x/roles/$id'),
          body: jsonEncode(body),
          headers: caller.headers,
        ),
      );

  Future<Set<String>> capsOf(String id) async {
    final row = await (db.select(
      db.roles,
    )..where((r) => r.id.equals(id))).getSingle();
    return (jsonDecode(row.capabilitiesJson) as List).cast<String>().toSet();
  }

  test('the admin role cannot have a capability stripped', () async {
    final before = await capsOf(adminRoleId);
    final res = await patchRole(adminRoleId, {
      'capabilities': [
        for (final c in Capability.values)
          if (c != Capability.editSettings) c.name,
      ],
    });
    expect(res.statusCode, 403);
    // The refusal has to be a refusal, not a 403 after the write landed.
    expect(await capsOf(adminRoleId), before);
  });

  test('the admin role cannot be renamed or recoloured either', () async {
    final res = await patchRole(adminRoleId, {
      'name': 'Bukan Admin',
      'colorHex': '#000000',
    });
    expect(res.statusCode, 403);
    final row = await (db.select(
      db.roles,
    )..where((r) => r.id.equals(adminRoleId))).getSingle();
    expect(row.name, 'Admin');
  });

  test('the admin role cannot be deleted', () async {
    final res = await router(
      Request(
        'DELETE',
        Uri.parse('http://x/roles/$adminRoleId'),
        headers: caller.headers,
      ),
    );
    expect(res.statusCode, 403);
    final still = await (db.select(
      db.roles,
    )..where((r) => r.id.equals(adminRoleId))).getSingleOrNull();
    expect(still, isNotNull);
  });

  test('an ordinary role is still fully editable', () async {
    // The lock must be narrow: it protects one role, not the screen.
    final res = await patchRole(waiterRoleId, {
      'name': 'Pelayan',
      'capabilities': [Capability.takeOrder.name],
    });
    expect(res.statusCode, 200);
    expect(await capsOf(waiterRoleId), {Capability.takeOrder.name});
  });

  test('an ordinary role still cannot be handed manageStaff', () async {
    // The older rule (ADR-0017) survives the new one: no minting a local admin
    // by granting the capability to a role you are allowed to edit.
    final res = await patchRole(waiterRoleId, {
      'capabilities': [Capability.takeOrder.name, Capability.manageStaff.name],
    });
    expect(res.statusCode, 403);
    expect(
      await capsOf(waiterRoleId),
      isNot(contains(Capability.manageStaff.name)),
    );
  });

  test('a new role carrying manageStaff is refused at creation', () async {
    final res = await router(
      Request(
        'POST',
        Uri.parse('http://x/roles'),
        body: jsonEncode({
          'id': 'role-backdoor',
          'name': 'Backdoor',
          'capabilities': [Capability.manageStaff.name],
        }),
        headers: caller.headers,
      ),
    );
    expect(res.statusCode, 403);
    final row = await (db.select(
      db.roles,
    )..where((r) => r.id.equals('role-backdoor'))).getSingleOrNull();
    expect(row, isNull);
  });
}
