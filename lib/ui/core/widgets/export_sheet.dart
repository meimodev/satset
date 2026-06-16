import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/order_history_exporter.dart';
import 'package:satset/core/export/reports_exporter.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/data/repositories/order_history_repository.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';

/// What an export covers. Both kinds share one sheet and one **Ekspor** entry
/// (ADR-0030 / ADR-0031); the user picks the kind via the **Jenis** selector.
/// `laporan` needs an in-memory report snapshot; `pesanan` fetches history on
/// demand and works without one.
enum _ExportKind {
  laporan('Umum', 'Ekspor laporan', 'laporan'),
  pesanan('Pesanan', 'Ekspor pesanan', 'riwayat-pesanan');

  const _ExportKind(this.label, this.title, this.fileKind);

  /// Selector chip label.
  final String label;

  /// Sheet header + share subject prefix.
  final String title;

  /// `kind` slug threaded into the export filename.
  final String fileKind;
}

/// Single export sheet for the Reports screen. Range is fixed to whatever is
/// active on screen (incl. custom from/to) — no separate picker. The user
/// picks the **Jenis** (report vs order history) and CSV vs PDF. `snapshot` is
/// the in-memory report; when null, the **Laporan** kind is disabled and the
/// sheet opens on **Pesanan**.
Future<void> showExportSheet(
  BuildContext context,
  WidgetRef ref, {
  required ReportsQuery query,
  ReportsSnapshotDto? snapshot,
}) {
  final sc = context.sat;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: sc.bg1,
    builder: (_) => _ExportSheet(
      query: query,
      reportsSnapshot: snapshot,
    ),
  );
}

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet({
    required this.query,
    this.reportsSnapshot,
  });

  /// Active report query — supplies the range and (for custom) the from/to.
  final ReportsQuery query;
  final ReportsSnapshotDto? reportsSnapshot;

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  ExportFormat _format = ExportFormat.pdf;
  bool _busy = false;
  String? _error;

  /// Default to report export when a snapshot is loaded, else order history.
  late _ExportKind _kind = widget.reportsSnapshot != null
      ? _ExportKind.laporan
      : _ExportKind.pesanan;

  ReportRange get _range => widget.query.range;
  DateTime? get _from => widget.query.customFrom;
  DateTime? get _to => widget.query.customTo;

  bool get _isReports => _kind == _ExportKind.laporan;

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final Uint8List bytes;
      if (_isReports) {
        final snap = widget.reportsSnapshot!;
        bytes = _format == ExportFormat.pdf
            ? await buildReportsPdf(snap, _range, from: _from, to: _to)
            : _csvBytes(buildReportsCsv(snap, _range, from: _from, to: _to));
      } else {
        final fetch = ref.read(orderHistoryFetcherProvider);
        final history = await fetch(widget.query);
        if (_format == ExportFormat.pdf) {
          // Pull proof photos on demand (ADR-0031); failures skip gracefully.
          final photos =
              await ref.read(orderHistoryPhotosFetcherProvider)(history);
          bytes = await buildOrderHistoryPdf(history, _range,
              photos: photos, from: _from, to: _to);
        } else {
          bytes = _csvBytes(
              buildOrderHistoryCsv(history, _range, from: _from, to: _to));
        }
      }

      await shareExportBytes(
        filename: exportFilename(
          kind: _kind.fileKind,
          range: _range,
          format: _format,
          from: _from,
          to: _to,
        ),
        bytes: bytes,
        mime: _format.mime,
        subject:
            '${_kind.title} · ${rangeLabelId(_range, from: _from, to: _to)}',
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      SatLog.repo('export.fail kind=${_kind.fileKind} $e');
      SatLog.repo('$st');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Gagal mengekspor. Coba lagi.';
        });
      }
    }
  }

  /// UTF-8 with BOM so Excel opens Indonesian text and Rupiah correctly.
  Uint8List _csvBytes(String csv) =>
      Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _kind.title.toUpperCase(),
              style: SatType.mono(
                size: 11,
                weight: FontWeight.w600,
                letterSpacing: 1.0,
                color: sc.textLo,
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'Jenis'),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final k in _ExportKind.values) ...[
                  _kindPill(context, k),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            if (widget.reportsSnapshot == null) ...[
              const SizedBox(height: 8),
              Text('Laporan belum siap — buka laporan dulu agar bisa diekspor.',
                  style: SatType.sans(size: 11.5, color: sc.textLo)),
            ],
            const SizedBox(height: 18),
            _label(context, 'Periode'),
            const SizedBox(height: 8),
            _periodPill(context),
            const SizedBox(height: 18),
            _label(context, 'Format'),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final f in ExportFormat.values) ...[
                  _pill(
                    context,
                    f.label,
                    on: _format == f,
                    onTap: _busy ? null : () => setState(() => _format = f),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!,
                  style: SatType.sans(size: 12, color: sc.urgent)),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: _exportButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportButton(BuildContext context) {
    final sc = context.sat;
    return GestureDetector(
      onTap: _busy ? null : _run,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _busy ? sc.accentSoft : sc.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: _busy
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(sc.accent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Menyiapkan…',
                      style: SatType.sans(
                          size: 14,
                          weight: FontWeight.w600,
                          color: sc.accent)),
                ],
              )
            : Text('Ekspor ${_format.label}',
                style: SatType.sans(
                  size: 15,
                  weight: FontWeight.w700,
                  color: sc.accentInk,
                )),
      ),
    );
  }

  /// Read-only pill echoing the active timeline chip — the export inherits the
  /// Reports screen's range, so there's nothing to pick here.
  Widget _periodPill(BuildContext context) {
    final sc = context.sat;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: sc.accentSoft,
        border: Border.all(color: sc.accentBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        rangeLabelId(_range, from: _from, to: _to),
        style: SatType.sans(
            size: 13, weight: FontWeight.w600, color: sc.accent),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: SatType.sans(
            size: 12, weight: FontWeight.w600, color: context.sat.textMd),
      );

  /// Disabled when [enabled] is false: greyed out and inert.
  Widget _kindPill(BuildContext context, _ExportKind k) {
    final disabled =
        k == _ExportKind.laporan && widget.reportsSnapshot == null;
    return _pill(
      context,
      k.label,
      on: _kind == k,
      enabled: !disabled,
      onTap: (_busy || disabled) ? null : () => setState(() => _kind = k),
    );
  }

  Widget _pill(BuildContext context, String text,
      {required bool on, VoidCallback? onTap, bool enabled = true}) {
    final sc = context.sat;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? sc.accentSoft : sc.bg3,
            border: Border.all(color: on ? sc.accentBorder : sc.border1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: SatType.sans(
              size: 13,
              weight: on ? FontWeight.w600 : FontWeight.w500,
              color: on ? sc.accent : sc.textMd,
            ),
          ),
        ),
      ),
    );
  }
}
