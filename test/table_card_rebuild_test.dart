// The floor card's two clocks (ADR-0081).
//
// The card body derives every signal it shows — reservation holds, service
// state, staleness — from whole-minute comparisons against venue settings, and
// re-scans the reservation list twice to do it. The seated counter beside the
// status is the one thing on the card that moves every second. Wiring the body
// to the seconds ticker made all twenty cards on a zone do those scans sixty
// times a minute to advance one digit.
//
// Two things must stay true, and neither is visible in a diff:
//   1. The body rebuilds on the minute; the counter on the second.
//   2. A table still turns basi from the clock alone. Nothing on the server
//      fires when a threshold is crossed — if the body stops watching a ticker
//      altogether, a stale table simply never repaints.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/state/tickers.dart';
import 'package:satset/ui/features/tables/widgets/table_card.dart';

void main() {
  // Both tickers are driven by hand so a test can fire one without the other —
  // the whole point is that they are no longer the same clock.
  late StreamController<DateTime> seconds;
  late StreamController<DateTime> minutes;

  setUp(() {
    seconds = StreamController<DateTime>.broadcast();
    minutes = StreamController<DateTime>.broadcast();
    tableCardBuilds = 0;
  });

  tearDown(() {
    seconds.close();
    minutes.close();
    SatClock.clear();
  });

  /// Move the app clock forward without moving the tickers.
  void advance(Duration d) => SatClock.adopt(d);

  Future<void> pumpCard(WidgetTester tester, {required DateTime openedAt}) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            secondTickerProvider.overrideWith((ref) => seconds.stream),
            minuteTickerProvider.overrideWith((ref) => minutes.stream),
          ],
          child: MaterialApp(
            // Pinned, exactly as the app pins it (ADR-0083). Without this the
            // test resolves against the host's locale and reads English.
            locale: const Locale('id'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            theme: satTheme(SatTheme.neonTerang),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: TableCard(
                    table: VenueTable(
                      id: 'T1',
                      zoneId: 'terrace',
                      status: TableStatus.occupied,
                      openedAt: openedAt,
                      currentVisitId: 'v1',
                    ),
                    tablet: false,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  String counterText(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.contains('m ') && s.endsWith('d'), orElse: () => '');

  testWidgets('the counter follows seconds, the body does not', (tester) async {
    await pumpCard(
      tester,
      openedAt: SatClock.now().subtract(const Duration(minutes: 12)),
    );
    expect(counterText(tester), '12m 0d');

    final buildsAfterMount = tableCardBuilds;

    advance(const Duration(seconds: 30));
    seconds.add(SatClock.now());
    await tester.pump();

    expect(
      counterText(tester),
      '12m 30d',
      reason: 'the seated counter must track the seconds ticker',
    );
    expect(
      tableCardBuilds,
      buildsAfterMount,
      reason:
          'the card body rebuilt on a seconds tick. Twenty of these on a zone '
          'is the reservation list scanned 40x a second (ADR-0081).',
    );
  });

  testWidgets('the body rebuilds on a minute tick', (tester) async {
    await pumpCard(
      tester,
      openedAt: SatClock.now().subtract(const Duration(minutes: 12)),
    );
    final buildsAfterMount = tableCardBuilds;

    minutes.add(SatClock.now());
    await tester.pump();

    expect(tableCardBuilds, buildsAfterMount + 1);
  });

  testWidgets('a table turns basi on the clock alone, with no server event', (
    tester,
  ) async {
    // Ungreeted escalates to crit past ungreetedMins + ungreetedEscalateMins,
    // 7 + 5 by default. At 12m exactly it is not yet stale.
    await pumpCard(
      tester,
      openedAt: SatClock.now().subtract(const Duration(minutes: 12)),
    );
    expect(find.text(_l10n.staleUngreeted(13)), findsNothing);

    // One minute later — no ticket arrived, no table row changed, nothing came
    // off the socket. The only input is the clock crossing a boundary.
    advance(const Duration(minutes: 1));
    minutes.add(SatClock.now());
    await tester.pump();

    expect(
      find.text(_l10n.staleUngreeted(13)),
      findsOneWidget,
      reason:
          'staleness is derived purely from elapsed time; if the body watches '
          'no ticker it never repaints and the table never turns basi',
    );
  });
}

/// The app boots Indonesian and these tests never switch it (ADR-0083),
/// so the expected copy is read from the same place the widget reads it.
final _l10n = lookupAppL10n(const Locale('id'));
