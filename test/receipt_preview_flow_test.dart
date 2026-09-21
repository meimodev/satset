import 'dart:async';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:satset/core/printing/bill_struk_data.dart';
import 'package:satset/core/printing/bill_struk_renderer.dart';
import 'package:satset/core/printing/struk_data.dart';
import 'package:satset/core/printing/struk_renderer.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/features/printing/receipt_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'preview capture preserves printer bytes for every receipt kind',
    () async {
      final l = await AppL10n.delegate.load(const Locale('en'));
      final profile = await CapabilityProfile.load();
      final at = DateTime(2026, 9, 21, 12, 30);
      final logo = img.encodePng(img.Image(width: 16, height: 16));
      final slip = StrukData(
        venueName: 'Cafe',
        tableLabel: 'A1',
        pax: 2,
        at: at,
        logoBytes: logo,
        guestNote: 'Birthday',
        lines: const [
          StrukLine(qty: 2, name: 'Tea', modifiers: ['Milk'], note: 'Hot'),
        ],
      );
      final orderGenerator = ReceiptPreviewGenerator(PaperSize.mm58, profile);
      expect(
        await StrukRenderer.render(
          l,
          slip,
          generator: orderGenerator,
          printedAt: at,
        ),
        await StrukRenderer.render(l, slip, printedAt: at),
      );
      expect(orderGenerator.children, isNotEmpty);
      for (final kind in BillDocKind.values) {
        final data = BillStrukData(
          venueName: 'Cafe',
          tableLabel: 'A1',
          pax: 2,
          at: at,
          kind: kind,
          logoBytes: logo,
          qrUrl: 'https://example.com',
          lines: const [
            BillStrukLine(
              qty: 1,
              name:
                  'A very long item name that wraps over several thermal rows',
              lineTotal: 10000,
              modifiers: ['Hot'],
              note: 'No sugar',
            ),
          ],
          subtotal: 10000,
          serviceAmount: 0,
          taxAmount: 0,
          total: 10000,
          billTotal: 10000,
          memberName: 'Guest',
          memberPoints: 20,
          receiptOwners: const ['A · Guest'],
          payments: const [
            BillStrukPayment(methodLabel: 'Cash', amount: 10000),
          ],
        );
        final generator = ReceiptPreviewGenerator(PaperSize.mm58, profile);
        expect(
          await BillStrukRenderer.render(
            l,
            data,
            generator: generator,
            printedAt: at,
          ),
          await BillStrukRenderer.render(l, data, printedAt: at),
          reason: kind.name,
        );
        final texts = generator.children
            .whereType<Text>()
            .map((w) => w.data)
            .join('\n');
        expect(texts, contains('Cafe'));
        expect(texts, contains('21/09/2026 12:30'));
      }
    },
  );

  Future<void> open(
    WidgetTester t, {
    required Future<PreparedReceipt> Function() load,
    required Future<String?> Function(List<int>) send,
    bool offline = false,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        theme: satTheme(SatTheme.amberGelap),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSatSheet<bool>(
                context,
                dismissible: false,
                builder: (_) => ReceiptPreviewSheet(
                  title: 'Receipt · Printer · 58 mm',
                  load: load,
                  send: send,
                  offline: () => offline,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
  }

  testWidgets(
    'changes require review; failures retry explicitly; offline notice',
    (t) async {
      var version = 1;
      final sent = <List<int>>[];
      var fail = true;
      final busy = Completer<String?>();
      await open(
        t,
        offline: true,
        load: () async =>
            PreparedReceipt([version], [Text('Document $version')]),
        send: (bytes) async {
          sent.add(bytes);
          if (fail) return 'Printer disconnected';
          return busy.future;
        },
      );
      expect(sent, isEmpty);
      expect(find.textContaining('Offline'), findsOneWidget);
      version = 2;
      await t.tap(find.text('Print'));
      await t.pumpAndSettle();
      expect(sent, isEmpty);
      expect(find.text('Document 2'), findsOneWidget);
      expect(find.textContaining('document has changed'), findsOneWidget);
      await t.tap(find.text('Print'));
      await t.pumpAndSettle();
      expect(sent, [
        [2],
      ]);
      expect(find.textContaining('avoid a duplicate'), findsOneWidget);
      fail = false;
      await t.tap(find.text('Try again'));
      await t.pump();
      await t.tap(find.text('Try again'));
      await t.pump();
      expect(sent, [
        [2],
        [2],
      ]);
      busy.complete(null);
      await t.pumpAndSettle();
      expect(find.byType(ReceiptPreviewSheet), findsNothing);
    },
  );

  testWidgets(
    'cancel sends nothing and a refresh error never prints stale data',
    (t) async {
      var broken = false;
      var calls = 0;
      await open(
        t,
        load: () async {
          if (broken) throw StateError('Receipt removed');
          return const PreparedReceipt([1], [Text('Old receipt')]);
        },
        send: (_) async {
          calls++;
          return null;
        },
      );
      broken = true;
      await t.tap(find.text('Print'));
      await t.pumpAndSettle();
      expect(calls, 0);
      await t.tap(find.byTooltip('Close'));
      await t.pumpAndSettle();
      expect(find.byType(ReceiptPreviewSheet), findsNothing);
      expect(calls, 0);
    },
  );
}
