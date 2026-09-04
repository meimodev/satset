// Two capabilities that were grantable toggles enforcing nothing, made real
// (ADR-0132). Both were reachable from the role sheet, both had ARB copy
// describing what they would do, and neither was ever asked for by a route:
// `adjustStock` because v36 merged it into `manageIngredients`, `manageRoles`
// because role CRUD was gated on `manageStaff` from the start.
//
// The gates here are the whole of the fix — the client hides what a session
// cannot do, but it is these refusals that decide it.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/capability.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/reference_routes.dart';
import 'package:satset/server/routes/stock_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<List<String>> capsOf(String roleId) async {
    final row = await (db.select(
      db.roles,
    )..where((t) => t.id.equals(roleId))).getSingle();
    return (jsonDecode(row.capabilitiesJson) as List).cast<String>();
  }

  group('stock is cut between the catalogue and the ledger', () {
    Future<Response> post(
      TestCaller caller,
      String path,
      Map<String, dynamic> body,
    ) => stockRoutes(db, WsHub(), caller.auth).call(
      Request(
        'POST',
        Uri.parse('http://x$path'),
        headers: {...caller.headers, 'content-type': 'application/json'},
        body: jsonEncode(body),
      ),
    );

    Future<void> ingredient(String id) => db
        .into(db.ingredients)
        .insert(
          IngredientsCompanion.insert(id: id, name: id, unit: 'l'),
        );

    test('adjustStock moves the numbers and cannot author a bahan', () async {
      final caller = await signInForTest(
        db,
        caps: {Capability.adjustStock},
        userId: 'ledger-only',
      );
      await ingredient('susu');

      final received = await post(caller, '/stock/receive', {
        'ingredientId': 'susu',
        'qty': 5000,
      });
      expect(received.statusCode, 200);

      final wasted = await post(caller, '/stock/waste', {
        'ingredientId': 'susu',
        'qty': 100,
      });
      expect(wasted.statusCode, 200);

      // The opname session is one act from open to close, so it sits wholly on
      // this side of the cut — splitting it would strand a half-walked count.
      final opened = await post(caller, '/stock/counts', {'scope': 'all'});
      expect(opened.statusCode, 200);

      // But the catalogue is somebody else's.
      final authored = await post(caller, '/stock/ingredients', {
        'id': 'gula',
        'name': 'Gula',
        'unit': 'kg',
      });
      expect(authored.statusCode, 403);
      expect(authored.readAsString(), completion(contains('manageIngredients')));
    });

    test('manageIngredients authors a bahan and cannot move stock', () async {
      final caller = await signInForTest(
        db,
        caps: {Capability.manageIngredients},
        userId: 'catalogue-only',
      );
      await ingredient('susu');

      final authored = await post(caller, '/stock/ingredients', {
        'id': 'gula',
        'name': 'Gula',
        'unit': 'kg',
      });
      expect(authored.statusCode, 200);

      final received = await post(caller, '/stock/receive', {
        'ingredientId': 'susu',
        'qty': 5000,
      });
      expect(received.statusCode, 403);
      expect(received.readAsString(), completion(contains('adjustStock')));
    });

    test('either authority may read the list — you cannot count what you '
        'cannot see', () async {
      for (final cap in [Capability.adjustStock, Capability.manageIngredients]) {
        final caller = await signInForTest(
          db,
          caps: {cap},
          userId: 'reader-${cap.name}',
        );
        final res = await stockRoutes(db, WsHub(), caller.auth).call(
          Request(
            'GET',
            Uri.parse('http://x/stock/ingredients'),
            headers: caller.headers,
          ),
        );
        expect(res.statusCode, 200, reason: 'reading with ${cap.name}');
      }
    });
  });

  group('rewriting a role\'s permissions costs manageRoles', () {
    Future<Response> send(
      TestCaller caller,
      String method,
      String path,
      Map<String, dynamic> body,
    ) => referenceRoutes(db, WsHub(), caller.auth).call(
      Request(
        method,
        Uri.parse('http://x$path'),
        headers: {...caller.headers, 'content-type': 'application/json'},
        body: jsonEncode(body),
      ),
    );

    Future<void> target() => db
        .into(db.roles)
        .insert(
          RolesCompanion.insert(
            id: 'role-target',
            name: 'Pelayan',
            capabilitiesJson: Value(jsonEncode([Capability.takeOrder.name])),
          ),
        );

    test('manageStaff alone renames but does not re-permission', () async {
      final caller = await signInForTest(
        db,
        caps: {Capability.manageStaff},
        userId: 'staff-only',
      );
      await target();

      final renamed = await send(caller, 'PATCH', '/roles/role-target', {
        'name': 'Pramusaji',
      });
      expect(renamed.statusCode, 200);

      final repermissioned = await send(caller, 'PATCH', '/roles/role-target', {
        'capabilities': [Capability.takeOrder.name, Capability.settleBill.name],
      });
      expect(repermissioned.statusCode, 403);
      expect(await capsOf('role-target'), [Capability.takeOrder.name]);
    });

    test('minting a role that already carries permissions is the same act',
        () async {
      final caller = await signInForTest(
        db,
        caps: {Capability.manageStaff},
        userId: 'staff-only-create',
      );

      // The backdoor the PATCH gate would otherwise leave standing: create the
      // role with the capabilities you wanted and assign somebody to it.
      final loaded = await send(caller, 'POST', '/roles', {
        'id': 'role-backdoor',
        'name': 'Kasir bayangan',
        'capabilities': [Capability.settleBill.name, Capability.refund.name],
      });
      expect(loaded.statusCode, 403);

      // An empty role is a label with no power, so it is still `manageStaff`'s.
      final empty = await send(caller, 'POST', '/roles', {
        'id': 'role-empty',
        'name': 'Baru',
        'capabilities': <String>[],
      });
      expect(empty.statusCode, 200);
    });

    test('manageRoles rewrites the set', () async {
      final caller = await signInForTest(
        db,
        caps: {Capability.manageStaff, Capability.manageRoles},
        userId: 'role-keeper',
      );
      await target();

      final res = await send(caller, 'PATCH', '/roles/role-target', {
        'capabilities': [Capability.takeOrder.name, Capability.settleBill.name],
      });
      expect(res.statusCode, 200);
      expect(
        await capsOf('role-target'),
        containsAll([Capability.takeOrder.name, Capability.settleBill.name]),
      );
    });
  });

  test('the v73 backfill grants from the authority that was doing the job',
      () async {
    Future<void> role(String id, List<Capability> caps) => db
        .into(db.roles)
        .insert(
          RolesCompanion.insert(
            id: id,
            name: id,
            capabilitiesJson: Value(jsonEncode([for (final c in caps) c.name])),
          ),
        );

    // The population v36 left behind: everyone who has been receiving stock
    // holds `manageIngredients`, whether or not they ever held `adjustStock`.
    await role('kitchen', [Capability.manageIngredients]);
    await role('manager', [Capability.manageStaff, Capability.viewReports]);
    await role('waiter', [Capability.takeOrder]);

    await db.backfillRoleAndStockCapabilities();

    // Nobody loses the ledger at the upgrade — enforcing without this would
    // revoke rather than restrict.
    expect(await capsOf('kitchen'), contains('adjustStock'));
    expect(await capsOf('manager'), contains('manageRoles'));
    // And nothing is granted to a role that held neither authority.
    expect(await capsOf('waiter'), ['takeOrder']);

    // Idempotent, like the v36 grant it mirrors.
    await db.backfillRoleAndStockCapabilities();
    expect(
      (await capsOf('kitchen')).where((c) => c == 'adjustStock').length,
      1,
    );
  });
}
