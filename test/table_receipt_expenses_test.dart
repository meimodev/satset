import 'dart:convert';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/core/printing/struk_builder.dart';
import 'package:satset/core/printing/struk_renderer.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/models/visit_expense_dto.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/features/printing/receipt_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'table expenses appear identically in preview and printed slip',
    () async {
      final at = DateTime(2026, 9, 22, 12);
      final profile = await CapabilityProfile.load();
      for (final locale in ['en', 'id']) {
        final l = await AppL10n.delegate.load(Locale(locale));
        for (final summary in [
          const VisitExpenseSummaryDto(),
          const VisitExpenseSummaryDto(
            total: 17000,
            expenses: [
              VisitExpenseDto(
                id: 'e1',
                visitId: 'v1',
                categoryId: 'c1',
                categoryName: 'Tissues',
                note: 'Bought next door',
                amount: 12000,
              ),
              VisitExpenseDto(
                id: 'e2',
                visitId: 'v1',
                categoryId: 'c2',
                categoryName: 'Errand',
                amount: 5000,
              ),
            ],
          ),
          const VisitExpenseSummaryDto(total: 5000, offline: true),
        ]) {
          final data = StrukBuilder.fromTable(
            venue: const VenueSettingsDto(),
            tableLabel: 'A1',
            pax: 2,
            tickets: const [],
            at: at,
            expenses: summary,
          );
          final g = ReceiptPreviewGenerator(PaperSize.mm58, profile);
          final previewBytes = await StrukRenderer.render(
            l,
            data,
            generator: g,
            printedAt: at,
          );
          final printedBytes = await StrukRenderer.render(
            l,
            data,
            printedAt: at,
          );
          expect(previewBytes, printedBytes);
          final text = g.children
              .whereType<Text>()
              .map((w) => w.data)
              .join('\n');
          final printed = latin1.decode(printedBytes, allowInvalid: true);
          if (summary.expenses.isNotEmpty) {
            for (final value in [
              'Tissues',
              'Bought next door',
              'Errand',
              'Rp 12.000',
              'Rp 5.000',
              'Rp 17.000',
            ]) {
              expect(text, contains(value));
              expect(printed, contains(value));
            }
            expect(text, contains(l.rptSecPengeluaran));
          } else if (!summary.offline) {
            expect(text, isNot(contains(l.rptSecPengeluaran)));
          }
          expect(
            text.contains(l.prnPreviewOffline.replaceAll('—', '-')),
            summary.offline,
          );
          expect(text, isNot(contains(l.strukBillTotal)));
        }
      }
    },
  );
}
