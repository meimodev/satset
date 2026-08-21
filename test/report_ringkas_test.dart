import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/features/admin/report_ringkas.dart';

/// **Laporan ringkas** — the one-page close (ADR-0109, switch `ringkasReport`).
///
/// The card's whole claim is that it is a **layout, not a computation**: every
/// number on it already exists in the snapshot, so it cannot disagree with the
/// section underneath it. That claim is only true while it keeps *reading*
/// rather than recounting, which is what this pins — the counts come from the
/// `net` tile's own `args`, not from summing the rows on screen. Feed it a
/// snapshot whose menu rows add up to something else and the card must still
/// say what the tile says.
///
/// The two figures it does derive are arithmetic on those same numbers: the
/// average bill, and the sign of the cash variance. Both are held here, the
/// average including the case that has no answer — a window with no bills
/// divides by zero.
void main() {
  late AppL10n l10n;

  setUpAll(() async => l10n = await AppL10n.delegate.load(const Locale('id')));

  ReportsSnapshotDto snapshot({
    int revenue = 400000,
    List<int> args = const [8, 19],
    bool withNet = true,
    KasSectionDto kas = const KasSectionDto(),
    List<MenuItemRowDto> top = const [],
  }) => ReportsSnapshotDto(
    generatedAt: '2026-08-20T22:15:00',
    rangeFrom: '2026-08-20',
    rangeTo: '2026-08-20',
    range: 'today',
    filterOptions: const FilterOptionsDto(),
    sales: SalesSectionDto(
      kpis: [
        // A tile the card must ignore, sitting before the one it wants.
        const KpiTileDto(key: 'gross', rupiah: 999999, args: [99, 99]),
        if (withNet) KpiTileDto(key: 'net', rupiah: revenue, args: args),
      ],
    ),
    staff: const StaffSectionDto(),
    menu: MenuSectionDto(top: top),
    ops: const OpsSectionDto(reservations: ReservationStatsDto()),
    kas: kas,
  );

  Future<void> pump(WidgetTester tester, ReportsSnapshotDto s) async {
    await tester.pumpWidget(
      MaterialApp(
        // Pinned exactly as the app pins it (ADR-0083); without this the test
        // reads the host's locale.
        locale: const Locale('id'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        theme: satTheme(SatTheme.neonTerang),
        home: Scaffold(
          body: SingleChildScrollView(child: ReportRingkas(snapshot: s)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the counts are read from the tile, never recounted', (
    tester,
  ) async {
    await pump(
      tester,
      snapshot(
        // Rows that sum to 30 covers — nothing on the card may notice.
        top: const [
          MenuItemRowDto(itemId: 'a', name: 'Kopi Susu', qty: 30, revenue: 1),
        ],
      ),
    );

    expect(find.text(formatIDR(400000)), findsOneWidget);
    expect(find.text('8'), findsOneWidget, reason: 'bills, from args[0]');
    expect(find.text('19'), findsOneWidget, reason: 'covers, from args[1]');
    expect(
      find.text('30'),
      findsNothing,
      reason: 'summing the rows would be a second place to disagree',
    );
  });

  testWidgets('the average bill is revenue over bills', (tester) async {
    await pump(tester, snapshot());
    expect(find.text(formatIDR(50000)), findsOneWidget);
  });

  testWidgets('a window with no bills does not divide by zero', (tester) async {
    await pump(tester, snapshot(revenue: 0, args: const [0, 0]));
    // Revenue and average are both zero, so the same string renders twice.
    expect(find.text(formatIDR(0)), findsNWidgets(2));
  });

  testWidgets('a build that never met the tile still renders', (tester) async {
    await pump(tester, snapshot(withNet: false));
    expect(find.byType(ReportRingkas), findsOneWidget);
    expect(find.text(formatIDR(0)), findsNWidgets(2));
    expect(
      find.text(formatIDR(999999)),
      findsNothing,
      reason: 'the wrong tile is not a fallback',
    );
  });

  testWidgets('a box that agrees is a result, not a question', (tester) async {
    await pump(
      tester,
      snapshot(kas: const KasSectionDto(closing: 180000, variance: 0)),
    );
    expect(find.text(l10n.rptRingkasKasOk(formatIDR(180000))), findsOneWidget);
  });

  testWidgets('a short box reads as short, by its size not its sign', (
    tester,
  ) async {
    await pump(
      tester,
      snapshot(kas: const KasSectionDto(closing: 180000, variance: -20000)),
    );
    expect(
      find.text(l10n.rptRingkasKasOff(formatIDR(180000), formatIDR(20000))),
      findsOneWidget,
      reason: 'a missing 20rb is 20rb missing, not minus 20rb',
    );
  });

  testWidgets('the top list stops at five', (tester) async {
    await pump(
      tester,
      snapshot(
        top: [
          for (var i = 1; i <= 7; i++)
            MenuItemRowDto(itemId: '$i', name: 'Item $i', qty: i, revenue: i),
        ],
      ),
    );
    expect(find.text('Item 5'), findsOneWidget);
    expect(find.text('Item 6'), findsNothing);
    expect(find.text('Item 7'), findsNothing);
  });

  testWidgets('nothing sold draws no list at all', (tester) async {
    await pump(tester, snapshot());
    expect(find.text(l10n.rptRingkasTop.toUpperCase()), findsNothing);
  });
}
