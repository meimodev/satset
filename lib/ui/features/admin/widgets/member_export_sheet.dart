import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/member_exporter.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/repositories/member_report_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';

/// What the file covers. Two grains of one window (ADR-0137): everybody who
/// traded, or one person's bills and products.
enum _Kind { ranked, history }

/// Export sheet for the [[Laporan pelanggan]].
///
/// Its own sheet rather than a fifth **Jenis** on the Reports one, because the
/// two screens do not share a window: `/reports` renders `ReportRange` straight
/// from `.values`, and this screen runs on `MemberRange` — a different enum on
/// purpose, carrying an open-ended `Semua` arm the accounting export must never
/// be offered. Joining them would mean teaching the shared sheet a second range
/// or dropping the arm that makes this report what it is.
Future<void> showMemberExportSheet(
  BuildContext context, {
  required String windowLabel,
  required String sortLabel,
  required String query,
  required MemberSort sort,
  String? memberId,
}) => showSatSheet<void>(
  context,
  builder: (_) => _MemberExportSheet(
    windowLabel: windowLabel,
    sortLabel: sortLabel,
    query: query,
    sort: sort,
    memberId: memberId,
  ),
);

class _MemberExportSheet extends ConsumerStatefulWidget {
  const _MemberExportSheet({
    required this.windowLabel,
    required this.sortLabel,
    required this.query,
    required this.sort,
    this.memberId,
  });

  final String windowLabel;
  final String sortLabel;

  /// The search box and the sort as the list has them. Applied again to the
  /// **uncapped** rows through `rankedMemberRows`, so the file is what the
  /// reader is looking at rather than a differently-ordered superset.
  final String query;
  final MemberSort sort;

  /// The member selected in the right-hand pane, or null. Without one the
  /// history kind has nothing to be about, so it renders disabled.
  final String? memberId;

  @override
  ConsumerState<_MemberExportSheet> createState() => _MemberExportSheetState();
}

class _MemberExportSheetState extends ConsumerState<_MemberExportSheet> {
  late _Kind _kind = widget.memberId == null ? _Kind.ranked : _Kind.history;
  ExportFormat _format = ExportFormat.pdf;
  bool _busy = false;
  String? _error;

  bool get _historyReady => widget.memberId != null;

  String _kindLabel(AppL10n l, _Kind k) => switch (k) {
    _Kind.ranked => l.memExpKindRanked,
    _Kind.history => l.memExpHistTitle,
  };

  /// Letterhead subset for PDF exports (ADR-0033) — logo + venue identity only.
  /// A failed logo fetch falls back to text cleanly rather than failing the
  /// export; a document without its mark is still the document.
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
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final l = ref.read(l10nProvider);
      final state = ref.read(memberReportProvider);
      final csv = _format == ExportFormat.csv;

      late final String filename;
      late final Uint8List bytes;
      late final String subject;

      switch (_kind) {
        case _Kind.ranked:
          // The uncapped payload, then the screen's own filter-and-sort over
          // it. Both halves matter: the fetch is what makes the file complete,
          // `rankedMemberRows` is what makes it the list on screen.
          final report = await ref.read(memberReportExportFetcherProvider)(
            state,
          );
          final rows = rankedMemberRows(
            report,
            query: widget.query,
            sort: widget.sort,
          );
          subject = l.mrpTitle;
          filename = memberExportFilename(
            MemberExportKind.ranked,
            _format,
            rangeSlug: memberRangeSlug(
              state.range,
              from: state.customFrom,
              to: state.customTo,
            ),
          );
          bytes = csv
              ? csvBytes(
                  buildMemberRankedCsv(
                    l,
                    report,
                    rows,
                    windowLabel: widget.windowLabel,
                    sortLabel: widget.sortLabel,
                  ),
                )
              : await buildMemberRankedPdf(
                  l,
                  report,
                  rows,
                  windowLabel: widget.windowLabel,
                  sortLabel: widget.sortLabel,
                  branding: await _branding(),
                );

        case _Kind.history:
          final history = await ref.read(memberHistoryExportFetcherProvider)(
            state,
            widget.memberId!,
          );
          subject = l.memExpHistTitle;
          filename = memberExportFilename(
            MemberExportKind.history,
            _format,
            rangeSlug: memberRangeSlug(
              state.range,
              from: state.customFrom,
              to: state.customTo,
            ),
          );
          bytes = csv
              ? csvBytes(
                  buildMemberHistoryCsv(
                    l,
                    history,
                    windowLabel: widget.windowLabel,
                  ),
                )
              : await buildMemberHistoryPdf(
                  l,
                  history,
                  windowLabel: widget.windowLabel,
                  branding: await _branding(),
                );
      }

      await shareExportBytes(
        filename: filename,
        bytes: bytes,
        mime: _format.mime,
        subject: subject,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      SatLog.vm('member export failed: $e');
      if (!mounted) return;
      setState(() => _error = memberExportError(ref.read(l10nProvider), e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: Sp.s5,
          right: Sp.s5,
          bottom: Sp.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SatSheetHeader(
              padding: const EdgeInsets.only(top: Sp.s3, bottom: Sp.s2),
              onClose: () => Navigator.of(context).pop(),
              child: Text(
                l.memExpAction,
                style: SatType.h3(color: sc.textHi),
              ),
            ),
            // The window is inherited, never picked here: the file answers the
            // chip the reader already chose, and a second picker is how a file
            // ends up describing a window nobody was looking at.
            Text(
              '${l.memExpWindow}: ${widget.windowLabel}',
              style: SatType.bodyS(color: sc.textMd),
            ),
            const SizedBox(height: Sp.s4),
            Text(l.exportKindField, style: SatType.labelS(color: sc.textMd)),
            const SizedBox(height: Sp.s2),
            Wrap(
              spacing: Sp.s2,
              runSpacing: Sp.s2,
              children: [
                for (final k in _Kind.values)
                  Opacity(
                    opacity: (k == _Kind.history && !_historyReady) ? 0.4 : 1,
                    child: SatChip.select(
                      label: _kindLabel(l, k),
                      selected: _kind == k,
                      onTap: () {
                        if (_busy) return;
                        if (k == _Kind.history && !_historyReady) return;
                        setState(() => _kind = k);
                      },
                    ),
                  ),
              ],
            ),
            if (!_historyReady) ...[
              const SizedBox(height: Sp.s2),
              Text(
                l.memExpPickMember,
                style: SatType.bodyS(color: sc.textLo),
              ),
            ],
            const SizedBox(height: Sp.s4),
            Text(l.exportFormatField, style: SatType.labelS(color: sc.textMd)),
            const SizedBox(height: Sp.s2),
            Wrap(
              spacing: Sp.s2,
              runSpacing: Sp.s2,
              children: [
                for (final f in ExportFormat.values)
                  SatChip.select(
                    label: f.label,
                    selected: _format == f,
                    onTap: () {
                      if (_busy) return;
                      setState(() => _format = f);
                    },
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: Sp.s3),
              Text(_error!, style: SatType.bodyS(color: sc.urgent)),
            ],
            const SizedBox(height: Sp.s5),
            SizedBox(
              width: double.infinity,
              child: SatButton.primary(
                label: l.exportAction(_format.label),
                icon: Icons.download_rounded,
                busy: _busy,
                onTap: _run,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
