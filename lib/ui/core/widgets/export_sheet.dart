import 'package:satset/ui/core/design/skin.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/export/accounting_exporter.dart';
import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/order_history_exporter.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/core/export/reports_exporter.dart';
import 'package:satset/core/export/staff_report_exporter.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/data/repositories/accounting_report_repository.dart';
import 'package:satset/data/repositories/order_history_repository.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/data/repositories/staff_report_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/motion.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

/// What an export covers. All kinds share one sheet and one **Ekspor** entry
/// (ADR-0030 / ADR-0031 / ADR-0032); the user picks the kind via the **Jenis**
/// selector. `laporan` needs the in-memory report snapshot; the rest fetch
/// their own purpose-built window payload on demand and work without one.
enum _ExportKind {
  laporan('laporan'),
  pesanan('riwayat-pesanan'),
  staf('laporan-staf'),
  akuntansi('akuntansi');

  const _ExportKind(this.fileKind);

  /// Only `laporan` reads the in-memory snapshot; the others fetch on demand.
  bool get needsSnapshot => this == _ExportKind.laporan;

  /// `kind` slug threaded into the export filename. Stays Indonesian in both
  /// languages: it is part of a filename a venue may already be filing by, and
  /// a download whose name changes with a device setting is not the same
  /// download.
  final String fileKind;

  /// Selector chip label.
  String label(AppL10n l) => switch (this) {
    _ExportKind.laporan => l.exportKindReport,
    _ExportKind.pesanan => l.exportKindOrders,
    _ExportKind.staf => l.exportKindStaff,
    _ExportKind.akuntansi => l.exportKindAccounting,
  };

  /// Sheet header + share subject prefix.
  String title(AppL10n l) => switch (this) {
    _ExportKind.laporan => l.exportTitleReport,
    _ExportKind.pesanan => l.exportTitleOrders,
    _ExportKind.staf => l.exportTitleStaff,
    _ExportKind.akuntansi => l.exportTitleAccounting,
  };
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
  return showSatSheet<void>(
    context,
    builder: (_) => _ExportSheet(query: query, reportsSnapshot: snapshot),
  );
}

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet({required this.query, this.reportsSnapshot});

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

  /// Letterhead subset for PDF exports (ADR-0033) — logo + venue identity only,
  /// never the customer footer/tagline/QR. Logo fetch failures fall back to
  /// text-only cleanly.
  Future<PdfBranding> _branding() async {
    final v = ref.read(venueSettingsProvider);
    Uint8List? logo;
    try {
      logo = await ref.read(venueLogoBytesProvider(v.logoRev).future);
    } catch (_) {
      logo = null;
    }
    return PdfBranding(
      logoBytes: logo,
      venueName: v.displayName,
      address: v.address,
      phone: v.phone,
    );
  }

  Future<void> _run() async {
    // Captured before the first await: the sheet is torn down on success, and
    // reading `context.l10n` after an await is exactly the lint this dodges.
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final isPdf = _format == ExportFormat.pdf;
      final branding = isPdf ? await _branding() : null;
      final Uint8List bytes;
      switch (_kind) {
        case _ExportKind.laporan:
          final snap = widget.reportsSnapshot!;
          bytes = isPdf
              ? await buildReportsPdf(
                  l,
                  snap,
                  _range,
                  from: _from,
                  to: _to,
                  branding: branding,
                )
              : _csvBytes(
                  buildReportsCsv(l, snap, _range, from: _from, to: _to),
                );
        case _ExportKind.pesanan:
          final history = await ref.read(orderHistoryFetcherProvider)(
            widget.query,
          );
          if (isPdf) {
            // Pull proof photos on demand (ADR-0031); failures skip gracefully.
            final photos = await ref.read(orderHistoryPhotosFetcherProvider)(
              history,
            );
            bytes = await buildOrderHistoryPdf(
              l,
              history,
              _range,
              photos: photos,
              from: _from,
              to: _to,
              branding: branding,
            );
          } else {
            bytes = _csvBytes(
              buildOrderHistoryCsv(l, history, _range, from: _from, to: _to),
            );
          }
        case _ExportKind.staf:
          final staff = await ref.read(staffReportFetcherProvider)(
            widget.query,
          );
          bytes = isPdf
              ? await buildStaffPdf(l, staff, branding: branding)
              : _csvBytes(buildStaffCsv(l, staff));
        case _ExportKind.akuntansi:
          final acct = await ref.read(accountingReportFetcherProvider)(
            widget.query,
          );
          bytes = isPdf
              ? await buildAccountingPdf(l, acct, branding: branding)
              : _csvBytes(buildAccountingCsv(l, acct));
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
            '${_kind.title(l)} · ${rangeLabel(l, _range, from: _from, to: _to)}',
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      SatLog.repo('export.fail kind=${_kind.fileKind} $e');
      SatLog.repo('$st');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l.exportFailed;
        });
      }
    }
  }

  /// UTF-8 with BOM so Excel opens Indonesian text and Rupiah correctly.
  /// Shared with the audit export — see `csvBytes` in `export_share.dart`.
  Uint8List _csvBytes(String csv) => csvBytes(csv);

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
              _kind.title(context.l10n).toUpperCase(),
              style: SatType.caption(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s4),
            _label(context, context.l10n.exportKindField),
            const SizedBox(height: Sp.s2),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in _ExportKind.values) _kindPill(context, k),
              ],
            ),
            if (_kind.needsSnapshot && widget.reportsSnapshot == null) ...[
              const SizedBox(height: Sp.s2),
              Text(
                context.l10n.exportNoSnapshot,
                style: SatType.bodyS(color: sc.textLo),
              ),
            ],
            const SizedBox(height: Sp.s4h),
            _label(context, context.l10n.expPeriod),
            const SizedBox(height: Sp.s2),
            _periodPill(context),
            const SizedBox(height: Sp.s4h),
            _label(context, context.l10n.exportFormatField),
            const SizedBox(height: Sp.s2),
            Row(
              children: [
                for (final f in ExportFormat.values) ...[
                  _pill(
                    context,
                    f.label,
                    on: _format == f,
                    onTap: _busy ? null : () => setState(() => _format = f),
                  ),
                  const SizedBox(width: Sp.s2),
                ],
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: Sp.s3h),
              Text(_error!, style: SatType.bodyS(color: sc.urgent)),
            ],
            const SizedBox(height: Sp.s6),
            SizedBox(width: double.infinity, child: _exportButton(context)),
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
        decoration: SatBox.d(
          color: _busy ? sc.accentSoft : sc.accent,
          borderRadius: SatR.a(14),
        ),
        child: _busy
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: Sp.s4,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(sc.accentText),
                    ),
                  ),
                  const SizedBox(width: Sp.s2h),
                  Text(
                    context.l10n.exportPreparing,
                    style: SatType.labelM(color: sc.accentText),
                  ),
                ],
              )
            : Text(
                context.l10n.exportAction(_format.label),
                style: SatType.labelL(color: sc.accentInk),
              ),
      ),
    );
  }

  /// Read-only pill echoing the active timeline chip — the export inherits the
  /// Reports screen's range, so there's nothing to pick here.
  Widget _periodPill(BuildContext context) {
    final sc = context.sat;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: Sp.s4),
      alignment: Alignment.center,
      decoration: SatBox.d(
        color: sc.accentSoft,
        border: SatB.all(color: sc.accentBorder),
        borderRadius: SatR.a(999),
      ),
      child: Text(
        rangeLabel(context.l10n, _range, from: _from, to: _to),
        style: SatType.labelM(color: sc.accentText),
      ),
    );
  }

  Widget _label(BuildContext context, String text) =>
      Text(text, style: SatType.labelS(color: context.sat.textMd));

  /// Disabled when [enabled] is false: greyed out and inert.
  Widget _kindPill(BuildContext context, _ExportKind k) {
    final disabled = k == _ExportKind.laporan && widget.reportsSnapshot == null;
    return _pill(
      context,
      k.label(context.l10n),
      on: _kind == k,
      enabled: !disabled,
      onTap: (_busy || disabled) ? null : () => setState(() => _kind = k),
    );
  }

  Widget _pill(
    BuildContext context,
    String text, {
    required bool on,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final sc = context.sat;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: satMotion(context, 160),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: Sp.s4),
          alignment: Alignment.center,
          decoration: SatBox.d(
            color: on ? sc.accentSoft : sc.bg3,
            border: SatB.all(color: on ? sc.accentBorder : sc.border1),
            borderRadius: SatR.a(999),
          ),
          child: Text(
            text,
            style: (on
                ? SatType.labelM(color: on ? sc.accentText : sc.textMd)
                : SatType.bodyM(color: on ? sc.accentText : sc.textMd)),
          ),
        ),
      ),
    );
  }
}
