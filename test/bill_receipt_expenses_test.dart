import 'dart:convert';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/core/printing/bill_struk_builder.dart';
import 'package:satset/core/printing/bill_struk_renderer.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/models/visit_expense_dto.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/features/printing/receipt_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'bill expenses match preview and print without changing money',
    () async {
      final at = DateTime(2026, 9, 22, 12);
      final profile = await CapabilityProfile.load();
      for (final locale in ['en', 'id']) {
        final l = await AppL10n.delegate.load(Locale(locale));
        for (final paid in [false, true]) {
          final raw = <String, dynamic>{
            'visitId': 'v1',
            'tableId': 't1',
            'tableLabel': 'A1',
            'pax': 2,
            'subtotal': 100000,
            'discountAmount': 10000,
            'serviceAmount': 9000,
            'taxAmount': 10890,
            'total': 109890,
            'paidAmount': paid ? 109890 : 0,
            'outstanding': paid ? 0 : 109890,
            'lines': [
              {
                'ticketId': 't1',
                'name': 'Lunch',
                'qty': 1,
                'lineTotal': 100000,
                'status': 'sent',
              },
            ],
            'receipts': [
              {
                'id': 'r1',
                'label': 'A',
                'mode': 'even',
                'total': 109890,
                'lines': [],
                'payments': [
                  if (paid)
                    {'method': 'tunai', 'amount': 109890, 'tendered': 120000},
                ],
              },
            ],
          };
          final bill = Bill.fromJson(raw);
          for (final summary in [
            const VisitExpenseSummaryDto(),
            const VisitExpenseSummaryDto(
              total: 15000,
              expenses: [
                VisitExpenseDto(
                  id: 'e1',
                  visitId: 'v1',
                  categoryId: 'c1',
                  categoryName: 'Tissues',
                  note: 'Bought next door',
                  amount: 15000,
                ),
              ],
            ),
            const VisitExpenseSummaryDto(total: 5000, offline: true),
          ]) {
            final client = BillStrukBuilder.fromBill(
              l: l,
              bill: bill,
              venue: const VenueSettingsDto(displayName: 'Cafe'),
              expenses: summary,
            );
            final server = BillStrukBuilder.fromServerMap(
              l: l,
              bill: raw,
              venueName: 'Cafe',
              expenses: summary,
            );
            for (final data in [client, server]) {
              expect(data.total, 109890);
              expect(data.outstanding, paid ? 0 : 109890);
              expect(data.paidNet, paid ? 109890 : 0);
              expect(data.discountAmount, 10000);
              expect(data.serviceAmount, 9000);
              expect(data.taxAmount, 10890);
              final generator = ReceiptPreviewGenerator(
                PaperSize.mm58,
                profile,
              );
              final bytes = await BillStrukRenderer.render(
                l,
                data,
                generator: generator,
                printedAt: at,
              );
              expect(
                bytes,
                await BillStrukRenderer.render(l, data, printedAt: at),
              );
              final printed = latin1.decode(bytes);
              final text = generator.children
                  .whereType<Text>()
                  .map((w) => w.data)
                  .join('\n');
              if (summary.expenses.isNotEmpty) {
                for (final value in [
                  'Tissues',
                  'Bought next door',
                  'Rp 15.000',
                ]) {
                  expect(text, contains(value));
                  expect(printed, contains(value));
                }
              } else if (!summary.offline) {
                expect(text, isNot(contains(l.rptSecPengeluaran)));
              }
              expect(
                text.contains(l.prnPreviewOffline.replaceAll('—', '-')),
                summary.offline,
              );
            }
            final share = BillStrukBuilder.fromBill(
              l: l,
              bill: bill,
              receipt: bill.receipts.first,
              venue: const VenueSettingsDto(),
              expenses: summary,
            );
            expect(share.expenses, isEmpty);
            expect(share.expenseTotal, 0);
          }
        }
      }
    },
  );
}
