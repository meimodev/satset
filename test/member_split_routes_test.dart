// **[[Pemilik struk]]** over the wire (ADR-0118) — naming a member on one
// share, spending their points against it, and what the bill close then writes.
//
// Three things are pinned here that no unit test can reach:
//
// 1. The mode gates the **write**. Without it the routes refuse, so a venue
//    that never bought the shape cannot acquire attributed rows by accident.
// 2. The earn at bill close is **one row per member**, and the money no share
//    claimed is the [[Pemilik tagihan]]'s. A guest holding two slips ate one
//    meal; the host holding none still ate.
// 3. A reopen reverses **every** member, not the first one found. The bug that
//    shape prevents is silent and expensive: three of four guests keep points
//    for a bill the venue un-settled.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/members.dart';
import 'package:satset/server/routes/settlement_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late TestCaller caller;
  late Future<Response> Function(Request) router;

  /// The venue as the till sees it. [split] off is the same venue minus the
  /// mode key — every other setting identical, so a difference in outcome can
  /// only be the gate.
  Future<void> settings({bool split = true}) => db
      .into(db.venueSettings)
      .insertOnConflictUpdate(
        VenueSettingsCompanion.insert(
          id: 'default',
          membersEnabled: const Value(true),
          memberPointsEnabled: const Value(true),
          memberPointValue: const Value(1000),
          memberRedeemMin: const Value(10),
          modules: Value([moduleMembers, if (split) modeMemberSplit].join(',')),
          // No service, no tax — the base under test is the food.
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

  Future<void> line(String id, int price, {int qty = 1}) => db
      .into(db.tickets)
      .insert(
        TicketsCompanion.insert(
          id: id,
          tableId: 't1',
          visitId: const Value('v1'),
          itemId: 'i1',
          name: 'Nasi Goreng',
          course: 'mains',
          qty: Value(qty),
          price: price,
          status: 'sent',
          sentAt: DateTime.now().toUtc(),
        ),
      );

  /// An itemized receipt owning [ticketIds] whole.
  Future<String> receipt(
    String id,
    String label,
    List<String> ticketIds,
  ) async {
    final res = await router(
      Request(
        'POST',
        Uri.parse('http://x/settlement/visits/v1/receipts'),
        body: jsonEncode({
          'mode': 'itemized',
          'label': label,
          'lines': [
            for (final t in ticketIds) {'ticketId': t, 'qtyUnits': 1},
          ],
        }),
        headers: caller.headers,
      ),
    );
    expect(res.statusCode, 200, reason: await res.readAsString());
    final bill = jsonDecode(await _reread(db, caller, router)) as Map;
    final rec = (bill['receipts'] as List).cast<Map>().firstWhere(
      (r) => r['label'] == label,
    );
    return rec['id'] as String;
  }

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

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    caller = await signInForTest(db);
    router = settlementRoutes(db, WsHub(), caller.auth).call;
  });
  tearDown(() => db.close());

  test('without the mode the routes refuse to name anyone', () async {
    await settings(split: false);
    await visit();
    await line('tk1', 100000);
    final a = await receipt('r1', 'A', ['tk1']);
    final m = await createMember(db, name: 'Budi', phone: '081100000011');

    final res = await post('/settlement/receipts/$a/member', {
      'memberId': m.id,
    });
    expect(res.statusCode, 409);
    expect(
      jsonDecode(await res.readAsString())['code'],
      'split_disabled',
      reason: 'the gate refuses the write, and says which gate',
    );

    final b = await bill();
    expect(b['splitEnabled'], isFalse);
    expect((b['receipts'] as List).cast<Map>().single['memberId'], isNull);
  });

  test('a named share carries its member on the wire', () async {
    await settings();
    await visit();
    await line('tk1', 100000);
    final a = await receipt('r1', 'A', ['tk1']);
    final m = await createMember(db, name: 'Budi', phone: '081100000011');

    expect(
      (await post('/settlement/receipts/$a/member', {
        'memberId': m.id,
      })).statusCode,
      200,
    );

    final b = await bill();
    expect(b['splitEnabled'], isTrue);
    final rec = (b['receipts'] as List).cast<Map>().single;
    expect(rec['memberId'], m.id);
    expect((rec['member'] as Map)['name'], 'Budi');
    // The punch fields the whole-bill member carries — the slip a guest takes
    // home must say the same thing either document would.
    expect((rec['member'] as Map).containsKey('punchTarget'), isTrue);
  });

  test('attribution is frozen by this share\'s own payment', () async {
    await settings();
    await visit();
    await line('tk1', 100000);
    await line('tk2', 100000);
    final a = await receipt('r1', 'A', ['tk1']);
    // B keeps the bill open, so the refusal under test is this share's own
    // payment and not the bill lock a fully settled visit would raise first.
    await receipt('r2', 'B', ['tk2']);
    final m = await createMember(db, name: 'Budi', phone: '081100000011');
    expect(
      (await post('/settlement/receipts/$a/payments', {
        'method': 'tunai',
        'amount': 100000,
      })).statusCode,
      200,
    );

    final res = await post('/settlement/receipts/$a/member', {
      'memberId': m.id,
    });
    expect(res.statusCode, 409);
    expect(jsonDecode(await res.readAsString())['code'], 'receipt_paid');
  });

  test('a redemption on a share is scoped to that share', () async {
    await settings();
    await visit();
    await line('tk1', 100000);
    await line('tk2', 100000);
    final a = await receipt('r1', 'A', ['tk1']);
    await receipt('r2', 'B', ['tk2']);
    final m = await createMember(db, name: 'Budi', phone: '081100000011');
    await adjustPoints(db, memberId: m.id, delta: 50, note: 'seed');
    await post('/settlement/receipts/$a/member', {'memberId': m.id});

    expect(
      (await post('/settlement/receipts/$a/redeem', {'points': 20})).statusCode,
      200,
    );

    final b = await bill();
    final byLabel = {
      for (final r in (b['receipts'] as List).cast<Map>()) r['label']: r,
    };
    expect(byLabel['A']!['total'], 80000, reason: '20 poin x Rp1.000');
    expect(byLabel['B']!['total'], 100000, reason: 'the other guest pays full');
    final discs = (byLabel['A']!['discounts'] as List).cast<Map>();
    expect(discs.single['source'], 'redeem');
    expect(await memberPoints(db, m.id), 30);

    // And it comes back off, points and all.
    expect(
      (await post('/settlement/receipts/$a/redeem/remove')).statusCode,
      200,
    );
    expect(await memberPoints(db, m.id), 50);
  });

  test('bill close earns per member, and the owner takes the rest', () async {
    await settings();
    final host = await createMember(db, name: 'Host', phone: '081000000010');
    final a1 = await createMember(db, name: 'Ana', phone: '081100000011');
    final b1 = await createMember(db, name: 'Bayu', phone: '081200000012');
    await visit(memberId: host.id);
    await line('tk1', 100000);
    await line('tk2', 100000);
    await line('tk3', 100000);
    final ra = await receipt('r1', 'A', ['tk1']);
    final rb = await receipt('r2', 'B', ['tk2']);
    final rc = await receipt('r3', 'C', ['tk3']);
    await post('/settlement/receipts/$ra/member', {'memberId': a1.id});
    await post('/settlement/receipts/$rb/member', {'memberId': b1.id});
    // C is nobody's — its money is the bill owner's (ADR-0118 §1).

    for (final r in [ra, rb, rc]) {
      expect(
        (await post('/settlement/receipts/$r/payments', {
          'method': 'tunai',
          'amount': 100000,
        })).statusCode,
        200,
      );
    }
    // No explicit close: the last payment settles the bill and it closes
    // itself (ADR-0069), which is the path the points ride in production.
    expect((await bill())['billClosedAt'], isNotNull);

    // 1 poin per Rp 1.000: one share each for the guests, one for the host.
    expect(await memberPoints(db, a1.id), 100);
    expect(await memberPoints(db, b1.id), 100);
    expect(
      await memberPoints(db, host.id),
      100,
      reason: 'the unclaimed share is the owner\'s, not nobody\'s',
    );
  });

  test('a reopen reverses every member, not just the first', () async {
    await settings();
    final host = await createMember(db, name: 'Host', phone: '081000000010');
    final a1 = await createMember(db, name: 'Ana', phone: '081100000011');
    final b1 = await createMember(db, name: 'Bayu', phone: '081200000012');
    await visit(memberId: host.id);
    await line('tk1', 100000);
    await line('tk2', 100000);
    await line('tk3', 100000);
    final ra = await receipt('r1', 'A', ['tk1']);
    final rb = await receipt('r2', 'B', ['tk2']);
    final rc = await receipt('r3', 'C', ['tk3']);
    await post('/settlement/receipts/$ra/member', {'memberId': a1.id});
    await post('/settlement/receipts/$rb/member', {'memberId': b1.id});
    for (final r in [ra, rb, rc]) {
      await post('/settlement/receipts/$r/payments', {
        'method': 'tunai',
        'amount': 100000,
      });
    }
    expect((await bill())['billClosedAt'], isNotNull);
    expect(await memberPoints(db, a1.id), 100);

    expect((await post('/settlement/visits/v1/reopen')).statusCode, 200);

    for (final m in [a1, b1, host]) {
      expect(
        await memberPoints(db, m.id),
        0,
        reason: '${m.name} kept points for a bill that was un-settled',
      );
    }
  });
}

/// Re-read the bill as raw JSON — the receipt helper needs the server's own id
/// for the row it just created, and the create route answers with the bill.
Future<String> _reread(
  AppDatabase db,
  TestCaller caller,
  Future<Response> Function(Request) router,
) async {
  final res = await router(
    Request(
      'GET',
      Uri.parse('http://x/settlement/visits/v1/bill'),
      headers: caller.headers,
    ),
  );
  return res.readAsString();
}
