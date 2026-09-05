// Every section the Reports screen draws must reach the file it exports.
//
// The bug this exists to prevent: `/reports` rendered Kas, Pengeluaran
// kunjungan, Piutang and Jam kerja on screen while `reports_exporter.dart`
// wrote none of them, so an owner who exported the month got a file that was
// silently missing four blocks — including the two ledgers an accountant is
// most likely to be after. Nothing failed; the sections simply were not there.
//
// Two guards, because one alone would not have caught it:
//
//   - a **structural** one that reads the screen's own section list and fails
//     when the exporter has never heard of one. That is what catches the *next*
//     section somebody adds to the screen and forgets to export;
//   - a **content** one that runs a fully populated snapshot through the CSV
//     and looks for figures from each block, so a section that is mentioned but
//     emits nothing still fails.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/core/export/reports_exporter.dart';
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/format.dart';

final _id = lookupAppL10n(const Locale('id'));

ReportsSnapshotDto _snapshot() => const ReportsSnapshotDto(
  generatedAt: '2026-09-05T17:00:00.000',
  rangeFrom: '2026-09-01T00:00:00.000',
  rangeTo: '2026-09-06T00:00:00.000',
  range: 'd7',
  filterOptions: FilterOptionsDto(),
  sales: SalesSectionDto(hourly: [0, 0, 1, 2]),
  staff: StaffSectionDto(),
  menu: MenuSectionDto(),
  ops: OpsSectionDto(reservations: ReservationStatsDto()),
  kas: KasSectionDto(
    opening: 500000,
    inflow: 300000,
    outflow: 120000,
    variance: -5000,
    closing: 675000,
    count: 4,
    byCategory: {'Belanja pasar': 90000, 'Transport': 30000},
    byBox: [
      KasBoxSectionDto(
        id: 'box-main',
        name: 'Kas Utama',
        opening: 500000,
        inflow: 100000,
        outflow: 120000,
        closing: 480000,
        byCategory: {'Belanja pasar': 90000},
      ),
      KasBoxSectionDto(
        id: 'box-dapur',
        name: 'Kas Dapur',
        inflow: 200000,
        closing: 195000,
        variance: -5000,
      ),
    ],
  ),
  pengeluaran: PengeluaranSectionDto(
    total: 47000,
    count: 3,
    visitCount: 2,
    byCategory: {'Tisu': 27000},
    byStaff: {'Sari': 47000},
    visits: [
      PengeluaranVisitDto(
        sessionId: 'v1',
        tableLabel: 'A3',
        settledTotal: 310000,
        expenseAmount: 27000,
      ),
    ],
  ),
  piutang: PiutangSectionDto(
    enabled: true,
    opening: 1000000,
    charged: 250000,
    collected: 400000,
    writtenOff: 50000,
    closing: 800000,
    overdueDays: 30,
    overdueTotal: 150000,
    debtorCount: 2,
    byMethod: {'Tunai': 400000},
    debtors: [
      DebtorRowDto(
        memberId: 'm1',
        name: 'Budi',
        phone: '0812',
        balance: 800000,
      ),
    ],
  ),
  jamKerja: JamKerjaSectionDto(
    unclosed: 1,
    staff: [
      JamKerjaRowDto(
        id: 'u1',
        name: 'Sari',
        minutes: 485,
        shifts: 3,
        days: 2,
        unclosed: 1,
      ),
    ],
  ),
);

void main() {
  test('the exporter knows every section the screen draws', () {
    // The screen's own list, read from source rather than restated here — a
    // copy would go stale exactly when this test matters.
    final view = File(
      'lib/ui/features/admin/report_sections_view.dart',
    ).readAsStringSync();
    final exporter = File(
      'lib/core/export/reports_exporter.dart',
    ).readAsStringSync();

    final drawn =
        RegExp(r'l10n\.(rptSec[A-Za-z]+)')
            .allMatches(view)
            .map((m) => m[1]!)
            .toSet()
          // Bahan is the stock block, which comes from its own provider and not
          // from the snapshot this exporter is handed. It has its own export.
          ..remove('rptSecBahan');

    // The four sections whose titles the exporter spells directly, plus the
    // ones it labels with an `exp*` key of its own. A section is "reached" when
    // the exporter names either its screen title or its own snapshot field.
    const fieldFor = {
      'rptSecSales': 's.sales',
      'rptSecStaff': 's.staff',
      'rptSecMenu': 's.menu',
      'rptSecOps': 's.ops',
      'rptSecKas': 's.kas',
      'rptSecPengeluaran': 's.pengeluaran',
      'rptSecMembers': 's.members',
      'rptSecPiutang': 's.piutang',
      'rptSecJamKerja': 's.jamKerja',
    };

    final missing = <String>[];
    for (final key in drawn) {
      final field = fieldFor[key];
      expect(
        field,
        isNotNull,
        reason:
            '$key is drawn on /reports but this test does not know which '
            'snapshot field it reads. Add it to fieldFor.',
      );
      if (!exporter.contains(field!)) missing.add('$key ($field)');
    }
    expect(
      missing,
      isEmpty,
      reason:
          'these sections render on /reports and never reach its export. '
          'An owner exporting the month gets a file quietly missing them.',
    );
  });

  test('a populated snapshot carries every block into the CSV', () {
    final csv = buildReportsCsv(_id, _snapshot(), ReportRange.d7);

    // Section headings.
    for (final title in [
      _id.rptSecKas,
      _id.rptSecPengeluaran,
      _id.rptSecPiutang,
      _id.rptSecJamKerja,
    ]) {
      expect(
        csv,
        contains(title.toUpperCase()),
        reason: '$title is missing from the export',
      );
    }

    // Figures, so a section that is titled but empty still fails. Through
    // `formatIDR` rather than as literals: money is pinned to id_ID in both
    // languages (ADR-0084), and a test that hardcoded the grouping would be
    // asserting the formatter rather than the export.
    expect(csv, contains(formatIDR(675000))); // kas closing
    // Signed, because which way a count went is the finding.
    expect(csv, contains(formatIDR(-5000))); // kas variance
    expect(csv, contains('Kas Dapur')); // per-box block, two tins
    expect(csv, contains('Belanja pasar')); // venue's own category word
    expect(csv, contains(formatIDR(47000))); // pengeluaran total
    expect(csv, contains(formatIDR(800000))); // piutang closing
    expect(csv, contains('Budi')); // the debtor
    expect(csv, contains('Sari')); // jam kerja and pengeluaran byStaff
    expect(csv, contains(_id.rptJamHours(8, 5))); // 485 minutes worked
  });

  test('an empty block is left out rather than exported blank', () {
    // A section with nothing in it reads, in a filing copy, as a system that
    // failed to fetch — not as a quiet box.
    final csv = buildReportsCsv(
      _id,
      const ReportsSnapshotDto(
        generatedAt: '2026-09-05T17:00:00.000',
        rangeFrom: '2026-09-01T00:00:00.000',
        rangeTo: '2026-09-06T00:00:00.000',
        range: 'd7',
        filterOptions: FilterOptionsDto(),
        sales: SalesSectionDto(),
        staff: StaffSectionDto(),
        menu: MenuSectionDto(),
        ops: OpsSectionDto(reservations: ReservationStatsDto()),
      ),
      ReportRange.d7,
    );
    expect(csv, isNot(contains(_id.rptSecKas.toUpperCase())));
    expect(csv, isNot(contains(_id.rptSecPiutang.toUpperCase())));
    expect(csv, isNot(contains(_id.rptSecJamKerja.toUpperCase())));
    // The always-present blocks still are.
    expect(csv, contains(_id.expSummary.toUpperCase()));
  });
}
