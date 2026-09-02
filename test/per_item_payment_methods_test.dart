// Paying a [[Split bill]] share by any method, including the tab — over the
// wire, through the real settlement routes.
//
// What is pinned here, and why each would be silent if it broke:
//
//   - **A tab charges the [[Pemilik struk]]** (ADR-0120). The route used to
//     read `visit.memberId`, so a share named to one guest raised a debt
//     against whoever was seated first. Everything succeeds in that world; the
//     wrong person is simply asked for money weeks later.
//   - **An unnamed share still falls back to the [[Pemilik tagihan]]**, so a
//     venue that never split behaves exactly as it did.
//   - **A struk may be born named**, because the settle pane mints at confirm
//     and has no receipt to attach a member to beforehand.
//   - **Split tender on one struk** — part Tunai, part tab. `CONTEXT.md` has
//     always described this; the bill-wide tender lock made it unreachable.
//   - **A payment cannot exceed the struk's outstanding.** Nothing capped it
//     while the settle mode computed the amount.
//   - **A refund names its leg** (ADR-0121), and refunding the tab leg reverses
//     the ledger rather than opening the drawer.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/debts.dart';
import 'package:satset/server/members.dart';
import 'package:satset/server/routes/settlement_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late TestCaller caller;
  late Future<Response> Function(Request) router;

  Future<void> settings({bool split = true}) => db
      .into(db.venueSettings)
      .insertOnConflictUpdate(
        VenueSettingsCompanion.insert(
          id: 'default',
          membersEnabled: const Value(true),
          memberDebtEnabled: const Value(true),
          memberDebtLimit: const Value(500000),
          modules: Value([moduleMembers, if (split) modeMemberSplit].join(',')),
          // No service, no tax — the money under test is the food.
          serviceEnabled: const Value(false),
          taxEnabled: const Value(false),
        ),
      );

  Future<void> visit({String? memberId}) => db
      .into(db.visits)
      .insert(
        VisitsCompanion.insert(
          id: 'v1',
          tableId: 't1',
          memberId: Value(memberId),
          openedAt: Value(DateTime.now().toUtc()),
          createdAt: DateTime.now().toUtc(),
        ),
      );

  Future<void> line(String id, int price) => db
      .into(db.tickets)
      .insert(
        TicketsCompanion.insert(
          id: id,
          tableId: 't1',
          visitId: const Value('v1'),
          itemId: 'i1',
          name: 'Nasi Goreng',
          course: 'mains',
          price: price,
          status: 'sent',
          sentAt: DateTime.now().toUtc(),
        ),
      );

  Future<Response> post(String path, [Map<String, Object?> body = const {}]) =>
      router(
        Request(
          'POST',
          Uri.parse('http://x$path'),
          body: jsonEncode(body),
          headers: caller.headers,
        ),
      );

  Future<Map<String, dynamic>> bill() async {
    final res = await router(
      Request(
        'GET',
        Uri.parse('http://x/settlement/visits/v1/bill'),
        headers: caller.headers,
      ),
    );
    expect(res.statusCode, 200);
    return (jsonDecode(await res.readAsString()) as Map)
        .cast<String, dynamic>();
  }

  /// Mint an itemized receipt owning [ticketIds] whole, optionally born named.
  Future<String> mint(
    String label,
    List<String> ticketIds, {
    String? memberId,
  }) async {
    final res = await post('/settlement/visits/v1/receipts', {
      'mode': 'itemized',
      'label': label,
      'memberId': memberId,
      'lines': [
        for (final t in ticketIds) {'ticketId': t, 'qtyUnits': 1},
      ],
    });
    final body = await res.readAsString();
    expect(res.statusCode, 200, reason: body);
    return (jsonDecode(body) as Map)['receiptId'] as String;
  }

  Map<String, dynamic> receiptOf(Map<String, dynamic> b, String label) =>
      (b['receipts'] as List)
          .cast<Map>()
          .firstWhere((r) => r['label'] == label)
          .cast<String, dynamic>();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    caller = await signInForTest(db);
    router = settlementRoutes(db, WsHub(), caller.auth).call;
  });
  tearDown(() => db.close());

  test(
    'a tab on a named share charges that member, not the bill owner',
    () async {
      await settings();
      final host = await createMember(db, name: 'Ani', phone: '081100000001');
      final guest = await createMember(db, name: 'Budi', phone: '081100000002');
      await visit(memberId: host.id);
      await line('tk1', 40000);
      await line('tk2', 60000);

      final mine = await mint('A', ['tk1'], memberId: guest.id);
      await mint('B', ['tk2']);

      final res = await post('/settlement/receipts/$mine/payments', {
        'method': 'piutang',
        'amount': 40000,
        'memberId': guest.id,
      });
      expect(res.statusCode, 200, reason: await res.readAsString());

      expect(await memberDebt(db, guest.id), 40000);
      expect(
        await memberDebt(db, host.id),
        0,
        reason: 'the host ate none of it and owes none of it',
      );
    },
  );

  test(
    'a tab on an unnamed share charges the explicitly named payer',
    () async {
      await settings();
      final host = await createMember(db, name: 'Ani', phone: '081100000001');
      await visit(memberId: host.id);
      await line('tk1', 35000);

      final r = await mint('A', ['tk1']);
      expect(
        (await post('/settlement/receipts/$r/payments', {
          'method': 'piutang',
          'amount': 35000,
          'memberId': host.id,
        })).statusCode,
        200,
      );
      expect(await memberDebt(db, host.id), 35000);
    },
  );

  test(
    'a struk is born named, and the mint refuses without the mode',
    () async {
      await settings(split: false);
      final guest = await createMember(db, name: 'Budi', phone: '081100000002');
      await visit();
      await line('tk1', 20000);

      final res = await post('/settlement/visits/v1/receipts', {
        'mode': 'itemized',
        'label': 'A',
        'memberId': guest.id,
        'lines': [
          {'ticketId': 'tk1', 'qtyUnits': 1},
        ],
      });
      expect(res.statusCode, 409);
      expect(jsonDecode(await res.readAsString())['code'], 'split_disabled');
      expect(
        (await bill())['receipts'],
        isEmpty,
        reason: 'a refused mint leaves no half-made receipt behind',
      );
    },
  );

  test('one struk takes part Tunai and part tab', () async {
    await settings();
    final guest = await createMember(db, name: 'Budi', phone: '081100000002');
    await visit();
    await line('tk1', 100000);

    final r = await mint('A', ['tk1'], memberId: guest.id);
    expect(
      (await post('/settlement/receipts/$r/payments', {
        'method': 'tunai',
        'amount': 70000,
        'tendered': 70000,
      })).statusCode,
      200,
    );
    // The bill-wide tender lock would have made this second, different method
    // unreachable from the till (ADR-0121).
    expect(
      (await post('/settlement/receipts/$r/payments', {
        'method': 'piutang',
        'amount': 30000,
        'memberId': guest.id,
      })).statusCode,
      200,
    );

    final rec = receiptOf(await bill(), 'A');
    expect(rec['paidNet'], 100000);
    expect((rec['payments'] as List).length, 2);
    expect(await memberDebt(db, guest.id), 30000);
  });

  test('a payment cannot exceed what the struk still owes', () async {
    await settings();
    await visit();
    await line('tk1', 50000);

    final r = await mint('A', ['tk1']);
    expect(
      (await post('/settlement/receipts/$r/payments', {
        'method': 'tunai',
        'amount': 30000,
      })).statusCode,
      200,
    );

    final res = await post('/settlement/receipts/$r/payments', {
      'method': 'tunai',
      'amount': 30000,
    });
    expect(res.statusCode, 409);
    final body = jsonDecode(await res.readAsString()) as Map;
    expect(body['code'], 'overpayment');
    expect(body['outstanding'], 20000);
  });

  test('a refund names its leg, and a tab leg unwinds on the ledger', () async {
    await settings();
    final guest = await createMember(db, name: 'Budi', phone: '081100000002');
    await visit();
    await line('tk1', 100000);

    final r = await mint('A', ['tk1'], memberId: guest.id);
    await post('/settlement/receipts/$r/payments', {
      'method': 'tunai',
      'amount': 60000,
      'tendered': 60000,
    });
    await post('/settlement/receipts/$r/payments', {
      'method': 'piutang',
      'amount': 40000,
      'memberId': guest.id,
    });
    expect(await memberDebt(db, guest.id), 40000);

    final pays = (receiptOf(await bill(), 'A')['payments'] as List).cast<Map>();
    final tab = pays.firstWhere((p) => p['method'] == 'piutang');
    final cash = pays.firstWhere((p) => p['method'] == 'tunai');

    // A method could not have told these apart if both had been `tunai`; the
    // leg id can.
    final res = await post('/settlement/receipts/$r/refund', {
      'paymentId': tab['id'],
      'amount': 15000,
    });
    expect(res.statusCode, 200, reason: await res.readAsString());
    expect(
      await memberDebt(db, guest.id),
      25000,
      reason: 'the tab went down; no rupiah left the drawer',
    );

    // The cash leg is untouched by that refund and keeps its own cap.
    final after = receiptOf(await bill(), 'A');
    final refundRow = (after['payments'] as List).cast<Map>().firstWhere(
      (p) => p['isRefund'] == true,
    );
    expect(refundRow['refundsPaymentId'], tab['id']);
    expect(refundRow['method'], 'piutang');

    // Over-refunding a leg is refused on that leg's own remainder, not the
    // struk's total money.
    final over = await post('/settlement/receipts/$r/refund', {
      'paymentId': tab['id'],
      'amount': 26000,
    });
    expect(over.statusCode, 409);
    expect(jsonDecode(await over.readAsString())['code'], 'over_refund');

    // And the reopen reverses only what still stands, so the member nets zero.
    expect(
      (await post('/settlement/receipts/$r/reopen')).statusCode,
      200,
      reason: cash['id'] as String,
    );
    expect(await memberDebt(db, guest.id), 0);
  });
}
