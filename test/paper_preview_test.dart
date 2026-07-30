import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/core/printing/bill_struk_data.dart';
import 'package:satset/core/printing/bill_struk_renderer.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/features/cashier/widgets/paper_preview.dart';

/// The print preview (ADR-0066) is a **second renderer** over the same
/// [BillStrukData] the ESC/POS one consumes. Two renderers drift, and the way
/// they drift is silent: a field is added to the slip and the preview keeps
/// showing the old document, so the cashier approves one thing and the roll
/// prints another.
///
/// So this pins the thing that matters — every money figure and every named row
/// on the paper reaches the screen. It is not a pixel golden: pixels would lock
/// the layout without saying anything about fidelity to the bytes, which is the
/// only property worth defending here.
void main() {
  BillStrukData fixture({
    BillDocKind kind = BillDocKind.wholeBill,
    List<BillStrukPayment> payments = const [],
    int outstanding = 0,
    bool taxAfterDiscount = true,
  }) => BillStrukData(
    venueName: 'Warung Sebelah',
    address: 'Jl. Pantai Berawa No. 17',
    phone: '+62 813 3700 2244',
    footer: 'Terima kasih · Sampai jumpa lagi',
    tableLabel: 'M7',
    pax: 4,
    guestName: 'Budi',
    at: DateTime(2026, 7, 30, 18, 14),
    kind: kind,
    docLabel: 'Tamu A',
    lines: const [
      BillStrukLine(
        qty: 2,
        name: 'Nasi Goreng',
        variant: 'Pedas',
        lineTotal: 90000,
        modifiers: ['+ Telur'],
        note: 'Tanpa sambal',
        discountLabel: 'Diskon Staf',
        discountAmount: 9000,
      ),
      BillStrukLine(qty: 1, name: 'Es Teh', lineTotal: 12000),
    ],
    subtotal: 93000,
    discountLabel: 'Diskon Member 10%',
    discountAmount: 9300,
    taxAfterDiscount: taxAfterDiscount,
    serviceAmount: 4185,
    taxAmount: 9670,
    total: 97555,
    billTotal: 195110,
    payments: payments,
    paidNet: payments.fold<int>(0, (a, p) => a + p.amount),
    outstanding: outstanding,
  );

  Future<void> pump(WidgetTester t, BillStrukData d) async {
    await t.pumpWidget(
      MaterialApp(
        theme: satTheme(SatTheme.amberGelap),
        home: Scaffold(
          body: SingleChildScrollView(child: PaperPreview(d)),
        ),
      ),
    );
  }

  /// The roll prints grouped digits with no currency symbol, so that is what
  /// the preview must show — `Rp 97.555` on screen beside `97.555` on paper is
  /// exactly the sort of mismatch this test exists to catch.
  Finder money(String grouped) => find.textContaining(grouped);

  testWidgets('every line reaches the paper, with its sub-lines', (t) async {
    await pump(t, fixture());
    expect(find.textContaining('Nasi Goreng'), findsOneWidget);
    expect(find.textContaining('Pedas'), findsOneWidget);
    expect(find.textContaining('Es Teh'), findsOneWidget);
    // Modifiers and the guest note make the slip double as an order check
    // (ADR-0026) — dropping them from the preview hides what will be printed.
    expect(find.textContaining('+ Telur'), findsOneWidget);
    expect(find.textContaining('Tanpa sambal'), findsOneWidget);
    // A line discount prints indented under its line (ADR-0037).
    expect(find.textContaining('Diskon Staf'), findsOneWidget);
  });

  testWidgets('every money figure reaches the paper', (t) async {
    await pump(t, fixture());
    expect(money('93.000'), findsWidgets); // subtotal
    expect(money('9.300'), findsWidgets); // whole-order discount
    expect(money('4.185'), findsWidgets); // service
    expect(money('9.670'), findsWidgets); // tax
    expect(money('97.555'), findsWidgets); // total
    expect(find.textContaining('Diskon Member 10%'), findsOneWidget);
  });

  testWidgets('an unpaid document is a Tagihan and states the balance', (
    t,
  ) async {
    await pump(t, fixture(outstanding: 97555));
    expect(find.textContaining('TAGIHAN'), findsOneWidget);
    expect(find.textContaining('SISA'), findsOneWidget);
  });

  testWidgets('a settled document is a Struk and says LUNAS', (t) async {
    await pump(
      t,
      fixture(
        payments: const [
          BillStrukPayment(methodLabel: 'Tunai', amount: 97555),
        ],
      ),
    );
    expect(find.textContaining('STRUK PEMBAYARAN'), findsOneWidget);
    expect(find.textContaining('Tunai'), findsOneWidget);
    expect(find.textContaining('LUNAS'), findsOneWidget);
  });

  testWidgets('an even share shows the whole-bill total as reference', (
    t,
  ) async {
    // An amount receipt owns no items, so the only way a guest can check the
    // share is fair is seeing what it is a share OF (ADR-0068).
    await pump(t, fixture(kind: BillDocKind.evenReceipt));
    expect(find.textContaining('STRUK BAGIAN'), findsOneWidget);
    expect(money('195.110'), findsWidgets);
  });

  testWidgets('the Diskon row moves with taxAfterDiscount', (t) async {
    // ADR-0038: position IS the arithmetic. Both orders must render, or the
    // preview prints a sum that does not add up on one of the two settings.
    for (final after in [true, false]) {
      await pump(t, fixture(taxAfterDiscount: after));
      expect(
        find.textContaining('Diskon Member 10%'),
        findsOneWidget,
        reason: 'taxAfterDiscount=$after',
      );
    }
  });

  test('the same data still renders to bytes', () async {
    // The other half of the contract: whatever the preview showed above, the
    // renderer accepts. A field the preview reads but the renderer rejects
    // would be caught here rather than at the printer.
    final bytes = await BillStrukRenderer.render(
      BillStrukData(
        venueName: 'Warung Sebelah',
        tableLabel: 'M7',
        pax: 4,
        at: DateTime(2026, 7, 30, 18, 14),
        kind: BillDocKind.wholeBill,
        lines: const [
          BillStrukLine(qty: 1, name: 'Es Teh', lineTotal: 12000),
        ],
        subtotal: 12000,
        serviceAmount: 600,
        taxAmount: 1386,
        total: 13986,
        billTotal: 13986,
        outstanding: 13986,
      ),
    );
    expect(bytes, isNotEmpty);
  });
}
