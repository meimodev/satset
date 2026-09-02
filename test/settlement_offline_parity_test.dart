// **The offline bill and the online bill are the same bill** (ADR-0123).
//
// The whole argument for one shared `recomputeBill` is that a
// [[Terputus (client disconnected)|terputus]] till quotes the guest the number
// the host will later agree with. Nothing enforces that but this: one event
// sequence run through the ordinary settlement routes and through the local
// projection, asserting the two bills match.
//
// Without it the shared function drifts the first time somebody edits one side,
// and the symptom is a guest charged one figure at the counter and a different
// one in the books.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/domain/models/settlement_event.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/domain/use_cases/settlement_projection.dart';
import 'package:satset/server/db/database.dart' hide Member;
import 'package:satset/server/routes/settlement_routes.dart';
import 'package:satset/server/ws_hub.dart';

import 'support/route_auth.dart';

void main() {
  late AppDatabase db;
  late TestCaller caller;
  late Future<Response> Function(Request) router;

  // Service and tax both on: the parity that matters is the whole ladder, not
  // the subtotal. `taxAfterDiscount` left at its DPP-correct default.
  Future<void> settings() => db
      .into(db.venueSettings)
      .insertOnConflictUpdate(
        VenueSettingsCompanion.insert(
          id: 'default',
          serviceEnabled: const Value(true),
          serviceMode: const Value('percent'),
          serviceRateBps: const Value(500),
          taxEnabled: const Value(true),
          taxRateBps: const Value(1100),
        ),
      );

  Future<void> visit() => db
      .into(db.visits)
      .insert(
        VisitsCompanion.insert(
          id: 'v1',
          tableId: 't1',
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

  Future<void> preset(String id, String kind, int value) => db
      .into(db.discountPresets)
      .insert(
        DiscountPresetsCompanion.insert(
          id: id,
          name: 'Promo',
          scope: const Value('bill'),
          kind: Value(kind),
          value: Value(value),
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

  Future<Map<String, dynamic>> serverBill() async {
    final res = await router(
      Request(
        'GET',
        Uri.parse('http://x/settlement/visits/v1/bill'),
        headers: caller.headers,
      ),
    );
    final body = await res.readAsString();
    expect(res.statusCode, 200, reason: body);
    return (jsonDecode(body) as Map).cast<String, dynamic>();
  }

  const cfg = ProjectionConfig(
    tax: TaxServiceConfig(
      taxEnabled: true,
      taxRateBps: 1100,
      serviceEnabled: true,
      serviceMode: 'percent',
      serviceRateBps: 500,
      serviceFixedAmount: 0,
    ),
  );

  /// The money ladder, which is what a guest is quoted and what the books
  /// record. Compared as a map so a mismatch names the rung.
  Map<String, Object?> ladder(Map<String, dynamic> bill) => {
    'subtotal': bill['subtotal'],
    'discountAmount': bill['discountAmount'],
    'serviceAmount': bill['serviceAmount'],
    'taxAmount': bill['taxAmount'],
    'total': bill['total'],
    'paidAmount': bill['paidAmount'],
    'outstanding': bill['outstanding'],
    'fullyAssigned': bill['fullyAssigned'],
    'fullySettled': bill['fullySettled'],
    'receipts': [
      for (final r in (bill['receipts'] as List).cast<Map>())
        {
          'id': r['id'],
          'subtotal': r['subtotal'],
          'discountAmount': r['discountAmount'],
          'serviceAmount': r['serviceAmount'],
          'taxAmount': r['taxAmount'],
          'total': r['total'],
          'status': r['status'],
          'paidNet': r['paidNet'],
        },
    ],
  };

  SettlementEvent ev(
    int seq,
    String id,
    SettlementEventKind kind,
    Map<String, dynamic> payload,
  ) => SettlementEvent(
    id: id,
    visitId: 'v1',
    seq: seq,
    kind: kind,
    payload: payload,
    capturedAt: DateTime.utc(2026, 8, 30, 12),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    caller = await signInForTest(db);
    router = settlementRoutes(db, WsHub(), caller.auth).call;
    await settings();
    await visit();
  });
  tearDown(() => db.close());

  test('a whole-bill settle projects to what the host computes', () async {
    await line('tk1', 50000, qty: 2);
    await line('tk2', 30000);
    // The base: what the till last heard, before it went dark.
    final base = await serverBill();

    final events = [
      ev(0, 'rc1', SettlementEventKind.mintReceipt, {
        'mode': 'itemized',
        'label': 'A',
        'assignAll': true,
      }),
      ev(1, 'pay1', SettlementEventKind.recordPayment, {
        'receiptId': 'rc1',
        'method': 'tunai',
        'amount': 151515,
        'tendered': 200000,
      }),
    ];
    final projected = projectBill(base, events, cfg);

    // The same acts, through the ordinary routes.
    expect(
      (await post('/settlement/visits/v1/receipts', {
        'id': 'rc1',
        'mode': 'itemized',
        'label': 'A',
        'assignAll': true,
      })).statusCode,
      200,
    );
    expect(
      (await post('/settlement/receipts/rc1/payments', {
        'id': 'pay1',
        'method': 'tunai',
        'amount': 151515,
        'tendered': 200000,
      })).statusCode,
      200,
    );

    expect(ladder(projected), ladder(await serverBill()));
    // And the projection is not vacuously equal: the bill really did settle.
    expect(projected['fullySettled'], isTrue);
  });

  test('a discount stacked on a split projects to the rupiah', () async {
    await line('tk1', 100000);
    await line('tk2', 60000);
    await preset('p10', 'percent', 1000);
    final base = await serverBill();

    final events = [
      ev(0, 'rcA', SettlementEventKind.mintReceipt, {
        'mode': 'itemized',
        'label': 'A',
        'lines': [
          {'ticketId': 'tk1', 'qtyUnits': 1},
        ],
      }),
      ev(1, 'rcB', SettlementEventKind.mintReceipt, {
        'mode': 'itemized',
        'label': 'B',
        'lines': [
          {'ticketId': 'tk2', 'qtyUnits': 1},
        ],
      }),
      // A bill-scope promo, which has to fan across both shares before either
      // can be totalled — the rung most likely to drift between two rules.
      ev(2, 'dsc1', SettlementEventKind.applyBillDiscount, {
        'presetId': 'p10',
        'name': 'Promo',
        'kind': 'percent',
        'value': 1000,
        'source': 'manual',
      }),
    ];
    final projected = projectBill(base, events, cfg);

    for (final spec in [('rcA', 'A', 'tk1'), ('rcB', 'B', 'tk2')]) {
      expect(
        (await post('/settlement/visits/v1/receipts', {
          'id': spec.$1,
          'mode': 'itemized',
          'label': spec.$2,
          'lines': [
            {'ticketId': spec.$3, 'qtyUnits': 1},
          ],
        })).statusCode,
        200,
      );
    }
    final dRes = await post('/settlement/visits/v1/discounts', {
      'id': 'dsc1',
      'presetId': 'p10',
    });
    expect(dRes.statusCode, 200, reason: await dRes.readAsString());

    expect(ladder(projected), ladder(await serverBill()));
    expect(projected['discountAmount'], 16000);
  });

  test('a replayed settlement closes when the money was taken', () async {
    // The whole point of ADR-0123 §capturedAt: a bill collected at 23:50 on a
    // dark till and drained at 00:10 belongs to the shift that collected it.
    // The payment row and the session it is filed under must agree — a
    // backdated payment inside a session stamped at drain time is reported on
    // the wrong day by everything that buckets on `TableSession.closedAt`.
    await line('tk1', 40000);
    final captured = DateTime.utc(2026, 8, 29, 16, 50);
    expect(
      (await post('/settlement/visits/v1/receipts', {
        'id': 'rc1',
        'mode': 'itemized',
        'assignAll': true,
        'capturedAt': captured.toIso8601String(),
      })).statusCode,
      200,
    );
    final pay = await post('/settlement/receipts/rc1/payments', {
      'id': 'pay1',
      'method': 'tunai',
      'amount': 46620,
      'capturedAt': captured.toIso8601String(),
    });
    expect(pay.statusCode, 200, reason: await pay.readAsString());

    final v = await (db.select(
      db.visits,
    )..where((x) => x.id.equals('v1'))).getSingle();
    expect(v.billClosedAt?.toUtc(), captured, reason: 'bill close backdates');
    final p = await (db.select(
      db.payments,
    )..where((x) => x.id.equals('pay1'))).getSingle();
    expect(p.at.toUtc(), captured, reason: 'payment backdates');

    // And the venue log agrees with itself. `billClosed` backdates because the
    // close does; a `paymentRecorded` left at drain time files the close
    // *before* the payment that caused it, which is an order of events that
    // never happened.
    final rows = await (db.select(
      db.auditEntries,
    )..where((x) => x.kind.isIn(['paymentRecorded', 'billClosed']))).get();
    expect(rows, hasLength(2));
    for (final row in rows) {
      expect(row.at.toUtc(), captured, reason: '${row.kind} backdates');
    }
  });

  test('the points a backdated close earns are filed with it', () async {
    // The member report and the sales report bucket the same meal. A points
    // row stamped at drain time puts the earn in one day and the bill that
    // earned it in another.
    await db
        .into(db.venueSettings)
        .insertOnConflictUpdate(
          VenueSettingsCompanion.insert(
            id: 'default',
            membersEnabled: const Value(true),
            memberPointsEnabled: const Value(true),
          ),
        );
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'm1',
            name: 'Adi',
            phone: '0812',
            joinedAt: DateTime.now().toUtc(),
          ),
        );
    await (db.update(db.visits)..where((v) => v.id.equals('v1'))).write(
      const VisitsCompanion(memberId: Value('m1')),
    );
    await line('tk1', 40000);

    final captured = DateTime.utc(2026, 8, 29, 16, 50);
    await post('/settlement/visits/v1/receipts', {
      'id': 'rc1',
      'mode': 'itemized',
      'assignAll': true,
      'capturedAt': captured.toIso8601String(),
    });
    final pay = await post('/settlement/receipts/rc1/payments', {
      'id': 'pay1',
      'method': 'tunai',
      // Whatever the ladder came to: this test is about *when* the earn is
      // filed, so it must actually settle.
      'amount': (await serverBill())['outstanding'],
      'capturedAt': captured.toIso8601String(),
    });
    expect(pay.statusCode, 200, reason: await pay.readAsString());
    expect((await serverBill())['fullySettled'], isTrue);

    final pts = await (db.select(
      db.memberPoints,
    )..where((x) => x.memberId.equals('m1'))).get();
    expect(pts, isNotEmpty, reason: 'the close earned nothing');
    for (final row in pts) {
      expect(row.at.toUtc(), captured, reason: '${row.kind} backdates');
    }
  });

  test('a future capturedAt is ignored, never booked into tomorrow', () async {
    await line('tk1', 40000);
    final ahead = DateTime.now().toUtc().add(const Duration(days: 2));
    await post('/settlement/visits/v1/receipts', {
      'id': 'rc1',
      'mode': 'itemized',
      'assignAll': true,
    });
    await post('/settlement/receipts/rc1/payments', {
      'id': 'pay1',
      'method': 'tunai',
      'amount': 46620,
      'capturedAt': ahead.toIso8601String(),
    });
    final p = await (db.select(
      db.payments,
    )..where((x) => x.id.equals('pay1'))).getSingle();
    expect(p.at.toUtc().isBefore(ahead), isTrue);
  });

  test('an id the caller minted is the id the host stores', () async {
    // Client-minted ids (ADR-0123 §Q6): a queued payment names the struk it is
    // for before that struk has ever reached the host.
    await line('tk1', 40000);
    await post('/settlement/visits/v1/receipts', {
      'id': 'my-receipt',
      'mode': 'itemized',
      'assignAll': true,
    });
    await post('/settlement/receipts/my-receipt/payments', {
      'id': 'my-payment',
      'method': 'tunai',
      'amount': 46620,
    });
    final bill = await serverBill();
    final rec = (bill['receipts'] as List).cast<Map>().single;
    expect(rec['id'], 'my-receipt');
    expect((rec['payments'] as List).cast<Map>().single['id'], 'my-payment');
  });

  test('a refund taken offline projects to what the host computes', () async {
    // The one act whose sign is easy to get wrong on one side only: the
    // projection appends a negative leg, the host writes a negative payment
    // row. A cashier who hands cash back on a dark till must see the same
    // outstanding the books will show.
    await line('tk1', 40000);
    final base = await serverBill();

    final events = [
      ev(0, 'rc1', SettlementEventKind.mintReceipt, {
        'mode': 'itemized',
        'assignAll': true,
      }),
      ev(1, 'pay1', SettlementEventKind.recordPayment, {
        'receiptId': 'rc1',
        'method': 'tunai',
        'amount': 46620,
      }),
      ev(2, 'ref1', SettlementEventKind.refund, {
        'receiptId': 'rc1',
        'paymentId': 'pay1',
        'amount': 20000,
      }),
    ];
    final projected = projectBill(base, events, cfg);

    await post('/settlement/visits/v1/receipts', {
      'id': 'rc1',
      'mode': 'itemized',
      'assignAll': true,
    });
    await post('/settlement/receipts/rc1/payments', {
      'id': 'pay1',
      'method': 'tunai',
      'amount': 46620,
    });
    final ref = await post('/settlement/receipts/rc1/refund', {
      'id': 'ref1',
      'paymentId': 'pay1',
      'amount': 20000,
    });
    expect(ref.statusCode, 200, reason: await ref.readAsString());

    expect(ladder(projected), ladder(await serverBill()));
    // Not vacuous: the money really did come back out.
    expect(projected['paidAmount'], 26620);
  });

  test('a refund and a discount taken offline are filed when taken', () async {
    // Same rule as the payment: the row and its audit belong to the shift that
    // handed the cash back, not the one the till happened to reconnect in.
    await line('tk1', 100000);
    await preset('p10', 'percent', 1000);
    final captured = DateTime.utc(2026, 8, 29, 16, 50);

    final dsc = await post('/settlement/visits/v1/discounts', {
      'id': 'dsc1',
      'presetId': 'p10',
      'capturedAt': captured.toIso8601String(),
    });
    expect(dsc.statusCode, 200, reason: await dsc.readAsString());
    await post('/settlement/visits/v1/receipts', {
      'id': 'rc1',
      'mode': 'itemized',
      'assignAll': true,
      'capturedAt': captured.toIso8601String(),
    });
    final due = (await serverBill())['outstanding'] as int;
    await post('/settlement/receipts/rc1/payments', {
      'id': 'pay1',
      'method': 'tunai',
      'amount': due,
      'capturedAt': captured.toIso8601String(),
    });
    final ref = await post('/settlement/receipts/rc1/refund', {
      'id': 'ref1',
      'paymentId': 'pay1',
      'amount': 20000,
      'capturedAt': captured.toIso8601String(),
    });
    expect(ref.statusCode, 200, reason: await ref.readAsString());

    final back = await (db.select(
      db.payments,
    )..where((x) => x.id.equals('ref1'))).getSingle();
    expect(back.at.toUtc(), captured, reason: 'refund row backdates');
    expect(
      back.amount,
      -20000,
      reason: 'a refund is the leg running backwards',
    );

    final audit = await (db.select(
      db.auditEntries,
    )..where((x) => x.kind.equals('refund'))).getSingle();
    expect(audit.at.toUtc(), captured, reason: 'refund audit backdates');
  });

  test('a parked event is not in the projection', () async {
    await line('tk1', 40000);
    final base = await serverBill();
    final events = [
      ev(0, 'rc1', SettlementEventKind.mintReceipt, {
        'mode': 'itemized',
        'assignAll': true,
      }),
      SettlementEvent(
        id: 'pay1',
        visitId: 'v1',
        seq: 1,
        kind: SettlementEventKind.recordPayment,
        payload: const {'receiptId': 'rc1', 'method': 'tunai', 'amount': 46620},
        capturedAt: DateTime.utc(2026, 8, 30, 12),
        // The chain halted before this one. It is untried, not applied — a
        // parked payment the projection still counted would show the cashier a
        // settled bill the host has never heard of.
        status: 'parked',
      ),
    ];
    final projected = projectBill(base, events, cfg);
    expect(projected['paidAmount'], 0);
    expect(projected['fullySettled'], isFalse);
  });

  test('ticket ownership projects while its assignment is queued', () async {
    await line('tk1', 40000);
    final projected = projectBill(await serverBill(), [
      ev(0, 'owner1', SettlementEventKind.assignTicketMembers, {
        'ticketIds': ['tk1'],
        'memberId': 'member-1',
      }),
    ], cfg);

    expect((projected['lines'] as List).single['memberId'], 'member-1');
  });
}
