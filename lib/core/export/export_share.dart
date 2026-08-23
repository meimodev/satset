import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/core/time/sat_clock.dart';

/// File flavour the user picks in the export sheet (ADR-0030).
enum ExportFormat { csv, pdf }

extension ExportFormatX on ExportFormat {
  String get ext => switch (this) {
    ExportFormat.csv => 'csv',
    ExportFormat.pdf => 'pdf',
  };
  String get mime => switch (this) {
    ExportFormat.csv => 'text/csv',
    ExportFormat.pdf => 'application/pdf',
  };
  String get label => switch (this) {
    ExportFormat.csv => 'CSV',
    ExportFormat.pdf => 'PDF',
  };
}

/// Short span for a committed custom window, e.g. `12 Jun – 15 Jun`.
/// [from]/[to] are inclusive calendar dates.
///
/// A span is a **date**, so it localises (ADR-0084) — this used to index a
/// hand-rolled Indonesian month array, the same shortcut `format.dart` carried
/// and for the same reason. Built per call so the format never freezes on
/// whichever locale happened to be active the first time a report was opened.
String customRangeLabel(DateTime from, DateTime to) {
  final d = DateFormat('d MMM');
  return '${d.format(from)} – ${d.format(to)}';
}

/// Range label, reused on the timeline chips, in filenames and in document
/// headers. For [ReportRange.custom], pass the inclusive [from]/[to] to render
/// the span; without them it falls back to a generic "Khusus".
String rangeLabel(
  AppL10n l10n,
  ReportRange r, {
  DateTime? from,
  DateTime? to,
}) => switch (r) {
  ReportRange.today => l10n.rangeToday,
  ReportRange.yesterday => l10n.rangeYesterday,
  ReportRange.d7 => l10n.rangeD7,
  ReportRange.d30 => l10n.rangeD30,
  ReportRange.month => l10n.rangeMonth,
  ReportRange.custom =>
    (from != null && to != null)
        ? customRangeLabel(from, to)
        : l10n.rangeCustom,
};

String _rangeSlug(ReportRange r, {DateTime? from, DateTime? to}) {
  String two(int n) => n.toString().padLeft(2, '0');
  String stamp(DateTime t) => '${t.year}${two(t.month)}${two(t.day)}';
  return switch (r) {
    ReportRange.today => 'hari-ini',
    ReportRange.yesterday => 'kemarin',
    ReportRange.d7 => '7-hari',
    ReportRange.d30 => '30-hari',
    ReportRange.month => 'bulan-ini',
    ReportRange.custom =>
      (from != null && to != null)
          ? 'khusus-${stamp(from)}-${stamp(to)}'
          : 'khusus',
  };
}

/// `satset-laporan-7-hari-20260615-1432.csv`
String exportFilename({
  required String kind,
  required ReportRange range,
  required ExportFormat format,
  DateTime? at,
  DateTime? from,
  DateTime? to,
}) {
  final t = at ?? SatClock.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final stamp =
      '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}';
  return 'satset-$kind-${_rangeSlug(range, from: from, to: to)}-$stamp.${format.ext}';
}

/// Write [bytes] to a temp file and hand it to the Android share sheet. The
/// only egress path for exports — the app is Android-only and on-device.
Future<void> shareExportBytes({
  required String filename,
  required Uint8List bytes,
  required String mime,
  required String subject,
  String? text,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  // share_plus 13 replaced the static `Share.shareXFiles` helpers with one
  // `SharePlus.instance.share(ShareParams(...))` call. Same sheet, same file,
  // one entry point instead of six overloads.
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: mime, name: filename)],
      subject: subject,
      text: text,
    ),
  );
}

/// UTF-8 with a BOM, so Excel opens Indonesian text and Rupiah correctly
/// instead of mojibake. Every CSV export goes out through this — a file that
/// opens wrong is a file the venue does not trust.
Uint8List csvBytes(String csv) =>
    Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);

/// RFC-4180 cell escaping: wrap in quotes when the value carries a comma,
/// quote, or newline; double any embedded quotes.
String csvCell(Object? value) {
  final s = value?.toString() ?? '';
  if (s.contains(RegExp('[",\n\r]'))) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

/// Join one CSV row, then the builders concatenate rows with `\r\n`.
String csvRow(List<Object?> cells) => cells.map(csvCell).join(',');
