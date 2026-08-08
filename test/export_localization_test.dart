import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/staff_report_exporter.dart';
import 'package:satset/core/printing/bill_struk_data.dart';
import 'package:satset/core/printing/bill_struk_renderer.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/data/repositories/staff_report_repository.dart';
import 'package:satset/l10n/app_localizations.dart';

/// The exports and the printed slips are the half of the app that leaves the
/// building — a CSV lands in an accountant's inbox and a receipt in a guest's
/// hand. Nothing else covers them: the ratchet in `design_tokens_test.dart`
/// scans `Text()` calls in `lib/ui`, and neither a `csvRow` nor an ESC/POS byte
/// buffer is one, so an Indonesian column header could sit in an English
/// build's spreadsheet forever without a red test.
///
/// This asserts the two halves of ADR-0083 + ADR-0084 together, because they
/// are only interesting as a pair: **words follow the device's language, and
/// the money in between them does not**.

final _id = lookupAppL10n(const Locale('id'));
final _en = lookupAppL10n(const Locale('en'));

StaffReport _report() => StaffReport(
  generatedAt: DateTime(2026, 8, 6, 21, 30),
  rangeFrom: DateTime(2026, 8, 1),
  rangeTo: DateTime(2026, 8, 7),
  range: ReportRange.d7,
  rows: const [
    StaffReportRow(
      id: 'u1',
      name: 'Sari',
      sessions: 12,
      covers: 41,
      items: 96,
      net: 4250000,
      avgTicket: 354167,
      upsellRate: 0.14,
      voidCount: 2,
      voidPct: 2.1,
      lostRupiah: 34000,
      topReasonCode: 'outOfStock',
    ),
  ],
  net: 4250000,
  voidCount: 2,
  lostRupiah: 34000,
);

BillStrukData _paidBill() => BillStrukData(
  venueName: 'Warung Sebelah',
  tableLabel: 'M7',
  pax: 4,
  at: DateTime(2026, 8, 6, 18, 14),
  kind: BillDocKind.wholeBill,
  lines: const [BillStrukLine(qty: 1, name: 'Es Teh', lineTotal: 12000)],
  subtotal: 12000,
  serviceAmount: 600,
  taxAmount: 1386,
  total: 13986,
  billTotal: 13986,
  payments: const [BillStrukPayment(methodLabel: 'Cash', amount: 13986)],
  paidNet: 13986,
);

void main() {
  // The ESC/POS renderer loads its capability profile from a package asset.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a CSV export follows the device language', () {
    final id = buildStaffCsv(_id, _report());
    final en = buildStaffCsv(_en, _report());

    expect(id, contains('Laporan Staf SatSet'));
    expect(id, contains('Alasan teratas'));
    expect(en, contains('SatSet Staff Report'));
    expect(en, contains('Top reason'));

    // The point of the pair: no Indonesian header survives into the English
    // file. A single missed `csvRow(['Nama', ...])` fails here.
    for (final indonesian in ['Nama', 'Sesi', 'Rata tagihan', 'Periode']) {
      expect(
        en,
        isNot(contains(indonesian)),
        reason: '"$indonesian" leaked into the English CSV',
      );
    }
  });

  test('money in an English CSV is still Indonesian rupiah (ADR-0084)', () {
    // Rp with `.` thousands, in both files, always. The cashier is reading the
    // screen against a stack of physical notes; `Rp 4,250,000` invites a
    // decimal misread on a live till, and the bank slip beside it groups on
    // `.` regardless of what language the report is in.
    for (final csv in [
      buildStaffCsv(_id, _report()),
      buildStaffCsv(_en, _report()),
    ]) {
      expect(csv, contains('Rp. 4.250.000'));
      expect(csv, isNot(contains('4,250,000')));
    }
  });

  test('a printed receipt follows the device language', () async {
    // ESC/POS is bytes; the copy is latin-1 text with control codes around it.
    String text(List<int> b) => latin1.decode(b, allowInvalid: true);

    final id = text(await BillStrukRenderer.render(_id, _paidBill()));
    final en = text(await BillStrukRenderer.render(_en, _paidBill()));

    expect(id, contains('STRUK PEMBAYARAN'));
    expect(id, contains('LUNAS'));
    expect(id, contains('Pajak'));
    expect(en, contains('PAYMENT RECEIPT'));
    expect(en, contains('SETTLED'));
    expect(en, contains('Tax'));

    // The venue's own name is content, not copy — never translated.
    expect(en, contains('Warung Sebelah'));
    // And the total is rupiah in both.
    expect(en, contains('Rp13.986'));
  });

  test(
    'a range label follows the device language, a date span follows the locale',
    () {
      expect(rangeLabel(_id, ReportRange.month), 'Bulan ini');
      expect(rangeLabel(_en, ReportRange.month), 'This month');

      // Custom windows render a *date*, which localises (ADR-0084). Guarded here
      // because the span used to come off a hand-rolled Indonesian month array
      // that printed `Agu` inside an English shell.
      final from = DateTime(2026, 8, 12);
      final to = DateTime(2026, 8, 15);
      expect(
        rangeLabel(_id, ReportRange.custom, from: from, to: to),
        '12 Agu – 15 Agu',
      );
      Intl.defaultLocale = 'en_US';
      addTearDown(() => Intl.defaultLocale = 'id_ID');
      expect(
        rangeLabel(_en, ReportRange.custom, from: from, to: to),
        '12 Aug – 15 Aug',
      );
    },
  );
}
