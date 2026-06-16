import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:satset/data/repositories/reports_repository.dart';

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

const _idMonthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Short Indonesian span for a committed custom window, e.g. `12 Jun – 15 Jun`.
/// [from]/[to] are inclusive calendar dates.
String customRangeLabel(DateTime from, DateTime to) {
  String d(DateTime t) => '${t.day} ${_idMonthsShort[t.month - 1]}';
  return '${d(from)} – ${d(to)}';
}

/// Indonesian range label, reused in filenames and document headers. For
/// [ReportRange.custom], pass the inclusive [from]/[to] to render the span;
/// without them it falls back to a generic "Khusus".
String rangeLabelId(ReportRange r, {DateTime? from, DateTime? to}) =>
    switch (r) {
      ReportRange.today => 'Hari ini',
      ReportRange.yesterday => 'Kemarin',
      ReportRange.d7 => '7 hari',
      ReportRange.d30 => '30 hari',
      ReportRange.month => 'Bulan ini',
      ReportRange.custom =>
        (from != null && to != null) ? customRangeLabel(from, to) : 'Khusus',
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
    ReportRange.custom => (from != null && to != null)
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
  final t = at ?? DateTime.now();
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
  await Share.shareXFiles(
    [XFile(file.path, mimeType: mime, name: filename)],
    subject: subject,
    text: text,
  );
}

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
