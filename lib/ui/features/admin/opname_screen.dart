import 'dart:typed_data';
import 'package:satset/ui/core/design/shell_inset.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/export/export_share.dart';
import 'package:satset/core/export/opname_exporter.dart';
import 'package:satset/core/export/pdf_theme.dart';
import 'package:satset/core/localization/labels.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/repositories/stock_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/models/stock_count.dart';
import 'package:satset/domain/models/stock_unit.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import '_common.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';

/// The stok opname archive (ADR-0096).
///
/// Counting happens on the Stok screen; this is where the sessions are filed
/// and read back. A session is a document: who counted, when, blind or
/// sighted, menyeluruh or sebagian, and every line — including the ones found
/// correct, which a ledger of `adjust` movements can never show.
///
/// Tablet only, like the venue log and the cash box, for the reason those are:
/// the value of a count is reading its lines against each other, and a phone
/// shows one row at a time.
/// The `from`/`to` pair the archive list is keyed on, snapped to midnight at
/// both ends.
///
/// Snapped deliberately, and pulled out here so it can be tested: this is a
/// **family key**. A range built straight from `DateTime.now()` is a new key on
/// every frame — the provider refetches, the rebuild moves the clock, and the
/// screen spins forever against a server answering 200 every 30ms. A day
/// boundary is also the only precision an archive of weekly counts can use.
(String, String) opnameRange(int days, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? SatClock.now());
  return (
    today.subtract(Duration(days: days)).toIso8601String(),
    today.add(const Duration(days: 1)).toIso8601String(),
  );
}

class OpnameScreen extends ConsumerStatefulWidget {
  const OpnameScreen({super.key});

  @override
  ConsumerState<OpnameScreen> createState() => _OpnameScreenState();
}

class _OpnameScreenState extends ConsumerState<OpnameScreen> {
  /// Days back the list covers. A pantry is counted weekly at most, so the
  /// default reaches back over several of them.
  int _days = 90;
  String? _selectedId;

  (String, String) get _range => opnameRange(_days);

  @override
  Widget build(BuildContext context) {
    if (!context.layout.useTabletShell) return const _OpnamePhoneNotice();

    final l10n = context.l10n;
    final sc = context.sat;
    final async = ref.watch(stockCountsProvider(_range));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminEmbeddedStrip(
          title: l10n.opnTitle,
          sub: l10n.opnSub,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final d in const [30, 90, 365])
                Padding(
                  padding: const EdgeInsets.only(left: Sp.s1h),
                  child: SatChip.select(
                    label: l10n.opnRangeDays(d),
                    selected: _days == d,
                    onTap: () => setState(() => _days = d),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () =>
                const Center(child: SatSpinner(size: SatSpinnerSize.md)),
            error: (e, _) => Center(
              child: SatEmpty(
                icon: Icons.error_outline,
                title: l10n.opnTitle,
                body: '$e',
              ),
            ),
            data: (data) {
              if (data.counts.isEmpty && data.open == null) {
                return Center(
                  child: SatEmpty(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.opnEmptyTitle,
                    body: l10n.opnEmptyBody,
                  ),
                );
              }
              // Two panes: sessions on the left, the selected document on the
              // right. A count is read against its own lines, which is what
              // the wide pane is for.
              final selected =
                  data.counts.where((c) => c.id == _selectedId).firstOrNull ??
                  data.counts.firstOrNull;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 340,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(Sp.s4, Sp.s4, Sp.s4, Sp.s4 + context.shellInset),
                      children: [
                        if (data.open != null) ...[
                          _OpenBanner(session: data.open!),
                          const SizedBox(height: Sp.s3),
                        ],
                        for (final c in data.counts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Sp.s2),
                            child: _CountTile(
                              count: c,
                              selected: c.id == selected?.id,
                              onTap: () => setState(() => _selectedId = c.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(width: 1, color: sc.border1),
                  Expanded(
                    child: selected == null
                        ? Center(
                            child: SatEmpty(
                              icon: Icons.description_outlined,
                              title: l10n.opnPickTitle,
                              body: l10n.opnPickBody,
                            ),
                          )
                        : _Document(countId: selected.id),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The walk somebody is in the middle of. It carries no variance figure on
/// purpose — nothing is decided until the session closes.
class _OpenBanner extends StatelessWidget {
  const _OpenBanner({required this.session});
  final StockCount session;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.all(Sp.s3),
      decoration: SatBox.d(
        color: sc.accentSoft,
        borderRadius: SatR.card,
        border: SatB.all(color: sc.accentBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note_rounded, size: 20, color: sc.accentText),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.opnOpenTitle,
                  style: SatType.labelM(color: sc.accentText),
                ),
                const SizedBox(height: Sp.sHair),
                Text(
                  context.l10n.opnOpenBody(session.lineCount),
                  style: SatType.bodyS(color: sc.textMd),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final StockCount count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    // `warn` on a shortfall, `success` on a surplus, neutral on nothing found:
    // a variance is a discrepancy to look at, never an emergency.
    final color = count.varianceValue == 0
        ? sc.textMd
        : count.varianceValue > 0
        ? sc.success
        : sc.warn;

    return SatCard.tappable(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(Sp.s3h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _stamp(count.startedAt),
                  style: SatType.labelM(color: sc.textHi),
                ),
              ),
              Text(
                formatIDR(count.varianceValue),
                style: SatType.monoM(color: color),
              ),
            ],
          ),
          const SizedBox(height: Sp.s1h),
          Row(
            children: [
              _OpnTag(text: stockCountScopeLabel(l10n, count.scope)),
              const SizedBox(width: Sp.s1),
              // A sighted count is weaker evidence and says so on its own
              // tile, rather than in a footnote nobody reads.
              _OpnTag(
                text: count.blind ? l10n.opnTagBlind : l10n.opnTagSighted,
                muted: !count.blind,
              ),
              const Spacer(),
              Text(
                l10n.opnLineCount(count.lineCount),
                style: SatType.caption(color: sc.textLo),
              ),
            ],
          ),
          const SizedBox(height: Sp.s1),
          // Attribution on the tile, not only inside the document: the archive
          // is scanned to find *whose* count is being argued about.
          Text(
            stockCountActorLine(l10n, count),
            style: SatType.caption(color: sc.textLo),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


class _OpnTag extends StatelessWidget {
  const _OpnTag({required this.text, this.muted = false});
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sp.s1h,
        vertical: Sp.sHair,
      ),
      decoration: SatBox.d(
        color: muted ? sc.bg3 : sc.infoSoft,
        borderRadius: SatR.pill,
      ),
      child: Text(
        text,
        style: SatType.caption(color: muted ? sc.textLo : sc.info),
      ),
    );
  }
}

/// One session, line by line — including every bahan found correct.
class _Document extends ConsumerWidget {
  const _Document({required this.countId});
  final String countId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l10n = context.l10n;
    final async = ref.watch(stockCountProvider(countId));

    return async.when(
      loading: () => const Center(child: SatSpinner(size: SatSpinnerSize.md)),
      error: (e, _) => Center(
        child: SatEmpty(
          icon: Icons.error_outline,
          title: l10n.opnTitle,
          body: '$e',
        ),
      ),
      data: (count) {
        final exact = count.lines.where((l) => l.variance == 0).length;
        return ListView(
          padding: EdgeInsets.fromLTRB(Sp.s5, Sp.s5, Sp.s5, Sp.s5 + context.shellInset),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _stamp(count.startedAt),
                    style: SatType.h3(color: sc.textHi),
                  ),
                ),
                // Both flavours in the open rather than behind a picker: the
                // sheet in `export_sheet.dart` earns its picker by also
                // choosing a range and a kind, and a session has neither.
                for (final f in ExportFormat.values)
                  Padding(
                    padding: const EdgeInsets.only(left: Sp.s1h),
                    child: SatButton.outline(
                      label: f.label,
                      icon: Icons.ios_share_rounded,
                      size: SatButtonSize.sm,
                      onTap: () => _export(context, ref, count, f),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Sp.s1),
            Text(
              l10n.opnDocSub(
                stockCountScopeLabel(l10n, count.scope),
                count.blind ? l10n.opnTagBlind : l10n.opnTagSighted,
              ),
              style: SatType.bodyS(color: sc.textLo),
            ),
            const SizedBox(height: Sp.sHair),
            Text(
              stockCountActorLine(l10n, count),
              style: SatType.bodyS(color: sc.textMd),
            ),
            const SizedBox(height: Sp.s4),
            Row(
              children: [
                _OpnKpi(
                  label: l10n.opnKpiLines,
                  value: '${count.lines.length}',
                  color: sc.textHi,
                ),
                const SizedBox(width: Sp.s2),
                _OpnKpi(
                  label: l10n.opnKpiExact,
                  value: '$exact',
                  color: sc.success,
                ),
                const SizedBox(width: Sp.s2),
                _OpnKpi(
                  label: l10n.opnKpiVariance,
                  value: formatIDR(count.varianceValue),
                  color: count.varianceValue == 0 ? sc.textMd : sc.warn,
                ),
              ],
            ),
            if (count.note != null && count.note!.isNotEmpty) ...[
              const SizedBox(height: Sp.s3),
              Text(count.note!, style: SatType.bodyS(color: sc.textMd)),
            ],
            const SizedBox(height: Sp.s4),
            const _LineHead(),
            for (final line in count.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Sp.s1),
                child: _LineRow(line: line),
              ),
          ],
        );
      },
    );
  }
}

class _LineHead extends StatelessWidget {
  const _LineHead();

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final s = SatType.caption(color: sc.textLo);
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s1h),
      child: Row(
        children: [
          Expanded(child: Text(l10n.opnColItem, style: s)),
          SizedBox(
            width: 100,
            child: Text(
              l10n.opnColExpected,
              textAlign: TextAlign.right,
              style: s,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              l10n.opnColCounted,
              textAlign: TextAlign.right,
              style: s,
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              l10n.opnColVariance,
              textAlign: TextAlign.right,
              style: s,
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(l10n.opnColValue, textAlign: TextAlign.right, style: s),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});
  final StockCountLine line;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final unit = stockUnitFromKey(line.unit ?? StockUnit.pcs.name);
    final exact = line.variance == 0;
    final color = exact
        ? sc.textLo
        : line.variance > 0
        ? sc.success
        : sc.warn;

    return Row(
      children: [
        Expanded(
          child: Text(
            line.name ?? line.ingredientId,
            style: SatType.bodyM(color: sc.textHi),
          ),
        ),
        // Expected and found sit side by side: "2 kg down" means nothing
        // without the number it was down from.
        SizedBox(
          width: 100,
          child: Text(
            formatQty(line.expectedQty, unit),
            textAlign: TextAlign.right,
            style: SatType.monoS(color: sc.textLo),
          ),
        ),
        SizedBox(
          width: 100,
          child: Text(
            formatQty(line.countedQty, unit),
            textAlign: TextAlign.right,
            style: SatType.monoS(color: sc.textMd),
          ),
        ),
        SizedBox(
          width: 110,
          child: Text(
            exact
                ? l10n.opnExact
                : '${line.variance > 0 ? '+' : ''}'
                      '${formatQty(line.variance, unit)}',
            textAlign: TextAlign.right,
            style: SatType.monoS(color: color),
          ),
        ),
        SizedBox(
          width: 110,
          child: Text(
            exact ? '' : formatIDR(line.value),
            textAlign: TextAlign.right,
            style: SatType.caption(color: color),
          ),
        ),
      ],
    );
  }
}

class _OpnKpi extends StatelessWidget {
  const _OpnKpi({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2),
        decoration: SatBox.d(
          color: sc.bg2,
          borderRadius: SatR.card,
          border: SatB.all(color: sc.border1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: SatType.caption(color: sc.textLo)),
            const SizedBox(height: Sp.sHair),
            Text(value, style: SatType.labelM(color: color)),
          ],
        ),
      ),
    );
  }
}

class _OpnamePhoneNotice extends StatelessWidget {
  const _OpnamePhoneNotice();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Sp.s5),
    child: Center(
      child: SatEmpty(
        icon: Icons.tablet_mac_outlined,
        title: context.l10n.opnTitle,
        body: context.l10n.opnPhoneOnly,
      ),
    ),
  );
}

/// Hand one session to the Android share sheet (ADR-0096). Rendered here, not
/// on the server: the document in hand is already the whole session.
Future<void> _export(
  BuildContext context,
  WidgetRef ref,
  StockCount count,
  ExportFormat format,
) async {
  // Captured before the first await — reading `context.l10n` after one is the
  // lint this dodges, and the messenger outlives this widget either way.
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final Uint8List bytes;
    if (format == ExportFormat.pdf) {
      final v = ref.read(venueSettingsProvider);
      Uint8List? logo;
      try {
        logo = await ref.read(venueLogoBytesProvider(v.logoRev).future);
      } catch (_) {
        // Letterhead is a nicety; a document that refuses to render because a
        // logo would not load is not.
        logo = null;
      }
      bytes = await buildOpnamePdf(
        l,
        count,
        branding: PdfBranding(
          logoBytes: logo,
          venueName: v.displayName,
          address: v.address,
          phone: v.phone,
        ),
      );
    } else {
      bytes = csvBytes(buildOpnameCsv(l, count));
    }
    await shareExportBytes(
      filename: opnameFilename(count, format),
      bytes: bytes,
      mime: format.mime,
      subject: l.opnExportSubject,
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('$e')));
  }
}

/// Date + clock for a session header. Dates localise, money does not
/// (ADR-0084).
String _stamp(DateTime at) =>
    '${formatShortDateId(at)} · ${formatClockId(at.toIso8601String())}';
