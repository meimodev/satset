// [[Item bebas]] — a line typed at the till with no menu row behind it.
//
// What is pinned here is the whole of why it needed its own capability: an
// off-menu line is the one sale nothing else in the system can explain
// afterwards. There is no menu id to look up, no resep to explode, no cost to
// compare the price against. So the route demands a capability a waiter does
// not hold, refuses an unexplained one, and writes the audit row that is the
// only record the sale will ever have.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/menu_item.dart' show openItemId;
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/tickets_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late WsHub hub;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    hub = WsHub();
  });
  tearDown(() => db.close());

  Future<Response> order(
    TestCaller caller, {
    required Map<String, Object?> line,
    String idem = 'idem-1',
  }) {
    return ticketsRoutes(db, hub, caller.auth).call(
      Request(
        'POST',
        Uri.parse('http://x/orders'),
        headers: {...caller.headers, 'content-type': 'application/json'},
        body: jsonEncode({
          'takeaway': true,
          'guestName': 'Tamu',
          'idempotencyKey': idem,
          'actorId': caller.userId,
          'lines': [line],
        }),
      ),
    );
  }

  Map<String, Object?> openLine({
    String name = 'Kue titipan',
    int price = 15000,
    String note = 'titipan tetangga',
    int qty = 2,
  }) => {
    'itemId': openItemId,
    'name': name,
    'unitPrice': price,
    'qty': qty,
    'note': note,
    'course': 'fire-now',
  };

  test('takeOrder alone does not open an off-menu line', () async {
    // The waiter role in the seed holds takeOrder and modifyOrder. Hiding the
    // button is convenience; this 403 is the rule.
    final waiter = await signInForTest(
      db,
      caps: {Capability.takeOrder, Capability.modifyOrder},
      userId: 'u-waiter',
      pin: '1111',
    );
    final res = await order(waiter, line: openLine());
    expect(res.statusCode, 403);
    expect(await res.readAsString(), contains('sellOpenItem'));
    expect(await db.select(db.tickets).get(), isEmpty);
  });

  test('an unexplained price is refused', () async {
    final till = await signInForTest(
      db,
      caps: {Capability.takeOrder, Capability.sellOpenItem},
      userId: 'u-till',
      pin: '2222',
    );
    for (final bad in [
      openLine(note: ''),
      openLine(price: 0),
      openLine(name: ''),
    ]) {
      final res = await order(till, line: bad);
      expect(res.statusCode, 400);
      expect(await res.readAsString(), contains('open_item_incomplete'));
    }
    expect(await db.select(db.tickets).get(), isEmpty);
  });

  test('a sold open item lands on the KDS and in the audit log', () async {
    final till = await signInForTest(
      db,
      caps: {Capability.takeOrder, Capability.sellOpenItem},
      userId: 'u-till',
      pin: '2222',
    );
    final res = await order(till, line: openLine());
    expect(res.statusCode, 200);

    // A ticket like any other — the kitchen is told, and the reserved id is
    // what every later reader keys off.
    final ticket = (await db.select(db.tickets).get()).single;
    expect(ticket.itemId, openItemId);
    expect(ticket.name, 'Kue titipan');
    expect(ticket.price, 15000);
    expect(ticket.status, 'sent');

    // One row, priced at the line total, carrying the seller's reason.
    final audit = (await db.select(db.auditEntries).get()).single;
    expect(audit.kind, AuditKind.openItemSold.name);
    expect(audit.amountCents, 30000);
    expect(audit.reason, 'titipan tetangga');
    expect(audit.actorUserId, till.userId);
  });

  test('an ordinary line is untouched by any of it', () async {
    final waiter = await signInForTest(
      db,
      caps: {Capability.takeOrder},
      userId: 'u-waiter',
      pin: '1111',
    );
    final res = await order(
      waiter,
      line: {
        'itemId': 'nasgor',
        'name': 'Nasi Goreng',
        'unitPrice': 25000,
        'qty': 1,
        'course': 'mains',
      },
    );
    expect(res.statusCode, 200);
    expect((await db.select(db.tickets).get()).single.itemId, 'nasgor');
    expect(await db.select(db.auditEntries).get(), isEmpty);
  });
}
