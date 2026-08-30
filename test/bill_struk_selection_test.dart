import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/core/printing/bill_struk_builder.dart';
import 'package:satset/core/printing/bill_struk_data.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/l10n/app_localizations.dart';

/// The **[[Rincian pilihan]]** (ADR-0122) — the Per item selection printed
/// before it is minted into a receipt.
///
/// Pinned because the slip is handed to a guest who then pays what it says, and
/// nothing else checks the arithmetic: the renderer is unchanged and no receipt
/// exists for the server to recompute against. Two invariants carry it — the
/// slip's total is the same number the confirm button is about to charge, and
/// its own rows add up to that total.
void main() {
  final l = lookupAppL10n(const Locale('id'));
  const venue = VenueSettingsDto();

  BillLine line(String id, String name, int unitPrice, int qty) => BillLine(
    ticketId: id,
    itemId: 'item-$id',
    name: name,
    variantName: '',
    qty: qty,
    unitPrice: unitPrice,
    lineTotal: unitPrice * qty,
    assignedUnits: 0,
    note: null,
    status: 'sent',
    modifiers: const [],
    sentAt: null,
  );

  // 10% service + 11% tax on a 100_000 subtotal, as the server would send it.
  Bill billOf(List<BillLine> lines, {int service = 10000, int tax = 12100}) {
    final subtotal = lines
        .where((x) => x.status != 'voided')
        .fold<int>(0, (a, x) => a + x.lineTotal);
    return Bill(
      visitId: 'v1',
      tableId: 't1',
      tableLabel: 'M1',
      kind: 'dineIn',
      status: 'occupied',
      detached: false,
      tableFreedAt: null,
      billClosedAt: null,
      pax: 3,
      guestName: null,
      channel: '',
      prepaid: false,
      mode: 'itemized',
      subtotal: subtotal,
      discountAmount: 0,
      billDiscounts: const [],
      member: null,
      splitEnabled: false,
      serviceAmount: service,
      taxAmount: tax,
      total: subtotal + service + tax,
      taxAfterDiscount: true,
      paidAmount: 0,
      outstanding: subtotal + service + tax,
      fullyAssigned: false,
      fullySettled: false,
      lines: lines,
      receipts: const [],
    );
  }

  BillStrukData build(Bill bill, Map<String, int> selection) =>
      BillStrukBuilder.fromSelection(
        l: l,
        bill: bill,
        selection: selection,
        venue: venue,
        logoBytes: null,
      );

  test('only the tapped units reach the slip', () {
    final bill = billOf([
      line('a', 'Nasi Goreng', 30000, 2),
      line('b', 'Es Teh', 10000, 4),
    ]);
    // One of the two nasi goreng, and none of the teh.
    final data = build(bill, {'a': 1});

    expect(data.lines.length, 1);
    expect(data.lines.single.name, 'Nasi Goreng');
    expect(data.lines.single.qty, 1);
    expect(data.lines.single.lineTotal, 30000);
    expect(data.subtotal, 30000);
  });

  test('a voided line is never printed even when selected', () {
    // A stale selection surviving a void must not put the guest's money on a
    // dish that was struck off.
    final voided = line('a', 'Nasi Goreng', 30000, 1);
    final bill = billOf([
      BillLine(
        ticketId: voided.ticketId,
        itemId: voided.itemId,
        name: voided.name,
        variantName: '',
        qty: 1,
        unitPrice: 30000,
        lineTotal: 0,
        assignedUnits: 0,
        note: null,
        status: 'voided',
        modifiers: const [],
        sentAt: null,
      ),
      line('b', 'Es Teh', 10000, 1),
    ]);
    final data = build(bill, {'a': 1, 'b': 1});

    expect(data.lines.map((x) => x.name), ['Es Teh']);
    expect(data.subtotal, 10000);
  });

  test('the total is the bill prorate, and the rows add up to it', () {
    final bill = billOf([
      line('a', 'Nasi Goreng', 30000, 2),
      line('b', 'Es Teh', 10000, 4),
    ]);
    final data = build(bill, {'a': 1});

    // The number the confirm button charges. Anything else is a slip the
    // cashier contradicts at the till.
    expect(data.total, bill.prorate(30000));
    // And the printed ladder must reach it on its own.
    expect(data.subtotal + data.serviceAmount + data.taxAmount, data.total);
  });

  test('a bill with neither service nor tax prints the bare subtotal', () {
    final bill = billOf([line('a', 'Kopi', 25000, 1)], service: 0, tax: 0);
    final data = build(bill, {'a': 1});

    expect(data.serviceAmount, 0);
    expect(data.taxAmount, 0);
    expect(data.total, 25000);
  });

  test('it is a Tagihan: no payments, everything still outstanding', () {
    // Nothing is minted, so the doc can carry no payment — which is what makes
    // the renderer print it as a Tagihan rather than a Struk pembayaran.
    final bill = billOf([line('a', 'Nasi Goreng', 30000, 2)]);
    final data = build(bill, {'a': 2});

    expect(data.payments, isEmpty);
    expect(data.isTagihan, isTrue);
    expect(data.paidNet, 0);
    expect(data.outstanding, data.total);
    expect(data.kind, BillDocKind.itemizedReceipt);
    // The one thing that stops it reading as a settled share.
    expect(data.docLabel, l.printSelectionDocLabel);
  });

  test('an empty or all-zero selection prints nothing', () {
    final bill = billOf([line('a', 'Nasi Goreng', 30000, 2)]);

    expect(build(bill, const {}).lines, isEmpty);
    expect(build(bill, const {'a': 0}).lines, isEmpty);
    expect(build(bill, const {'a': 0}).total, 0);
  });
}
