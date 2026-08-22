import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/core/time/sat_clock.dart';

/// Hand the venue audit log to the Android share sheet as CSV.
///
/// Unlike the reports export there is no format picker: the log has one useful
/// shape, and a sheet asking "CSV or PDF?" with one answer is a step that buys
/// nothing. A 500-row PDF of an audit trail serves nobody.
///
/// The bytes are **rendered by the server** and fetched whole (ADR-0072). The
/// client holds only the pages it has scrolled, so exporting from local state
/// would produce a file that stops wherever the reader happened to stop —
/// a truncated record carrying the word "lengkap".
Future<void> exportAuditCsv(WidgetRef ref, {required String path}) async {
  final raw = await ref.read(apiClientProvider).getBytes(path);
  final stamp = SatClock.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final name =
      'satset-audit-${stamp.year}${two(stamp.month)}${two(stamp.day)}'
      '-${two(stamp.hour)}${two(stamp.minute)}.csv';
  await shareExportBytes(
    filename: name,
    // The server already emits UTF-8, so the bytes pass through untouched —
    // only the BOM is prepended, so Excel renders "Rp" and Indonesian names
    // instead of mojibake. Decoding to a String on the way past would mangle
    // every multi-byte character for no gain.
    bytes: Uint8List.fromList([0xEF, 0xBB, 0xBF, ...raw]),
    mime: ExportFormat.csv.mime,
    subject: ref.read(l10nProvider).expAuditSubject,
  );
}
