import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/core/printing/bill_struk_data.dart';
import 'package:satset/core/printing/bill_struk_renderer.dart';
import 'package:satset/core/printing/struk_data.dart';
import 'package:satset/core/printing/struk_renderer.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every receipt prints the current local timestamp below its header',
    () async {
      addTearDown(SatClock.clear);
      final l = lookupAppL10n(const Locale('en'));
      final oldTime = DateTime(2025, 1, 2, 3, 4);
      final slip = StrukData(
        venueName: 'Venue',
        header: 'Header ends here',
        tableLabel: 'Table marker',
        pax: 1,
        at: oldTime,
        lines: const [StrukLine(qty: 1, name: 'Tea')],
      );
      final renderers = <Future<List<int>> Function()>[
        () => StrukRenderer.render(l, slip),
        for (final kind in BillDocKind.values)
          for (final paid in [false, true])
            () => BillStrukRenderer.render(
              l,
              BillStrukData(
                venueName: 'Venue',
                header: 'Header ends here',
                tableLabel: 'Table marker',
                pax: 1,
                at: oldTime,
                kind: kind,
                lines: const [BillStrukLine(qty: 1, name: 'Tea')],
                subtotal: 1000,
                serviceAmount: 0,
                taxAmount: 0,
                total: 1000,
                billTotal: 1000,
                payments: paid
                    ? const [
                        BillStrukPayment(methodLabel: 'Cash', amount: 1000),
                      ]
                    : const [],
                paidNet: paid ? 1000 : 0,
              ),
            ),
      ];

      for (final render in renderers) {
        // Reuse the same document: a reprint must not reuse its old timestamp.
        for (final day in [21, 22]) {
          SatClock.adopt(
            DateTime(2026, 9, day, 14, 35, 30).difference(SatClock.realNow()),
          );
          final text = latin1.decode(await render(), allowInvalid: true);
          final stamp = '$day/09/2026 14:35';
          expect(stamp.allMatches(text), hasLength(1));
          expect(
            text.indexOf(stamp),
            greaterThan(text.indexOf('Header ends here')),
          );
          // The date belongs above the document title, table, and item details.
          final bodyMarkers = [
            'Table marker',
            l.strukBillTitle,
            l.strukReceiptTitle,
            l.strukDebtTitle,
            'Tea',
          ];
          for (final marker in bodyMarkers.where(text.contains)) {
            expect(text.indexOf(stamp), lessThan(text.indexOf(marker)));
          }
          expect(text, isNot(contains('02/01/2025 03:04')));
        }
      }
    },
  );
}
