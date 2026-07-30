import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/export/audit_exporter.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/data/repositories/venue_audit_repository.dart';
import 'package:satset/data/services/error_bus_service.dart';
import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/ui/core/design/audit_visuals.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import '_common.dart';

/// The venue-wide integrity log (ADR-0067).
///
/// Tablet only, deliberately: six columns side by side is what lets a manager
/// scan forty rows for the one that looks wrong, and a phone cannot show them
/// without becoming a different, worse screen. The phone path says so rather
/// than degrading silently.
class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final repo = ref.read(venueAuditProvider.notifier);
    // "At the head" is a band, not a pixel: a manager resting a few rows down
    // still expects new voids to land, and only a deliberate scroll into
    // history should hold them back.
    repo.setAtHead(_scroll.offset <= 48);
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 600) repo.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.layout.useTabletShell) return const _AuditPhoneNotice();

    final state = ref.watch(venueAuditProvider);
    final repo = ref.read(venueAuditProvider.notifier);
    final total = state.summary.values.fold<int>(0, (a, t) => a + t.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminEmbeddedStrip(
          title: AppStrings.auditTitle,
          sub: state.loading
              ? AppStrings.auditSubtitle
              : '${AppStrings.auditEventCount(total)} · '
                    '${_windowLabel(state.filters.window)}',
          trailing: _AuditToolbar(state: state, repo: repo),
        ),
        Expanded(
          child: Stack(
            children: [
              CustomScrollView(
                controller: _scroll,
                slivers: [
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(Sp.s7, Sp.s6, Sp.s7, 0),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Sp.s7,
                        Sp.s6,
                        Sp.s7,
                        Sp.s4,
                      ),
                      child: _AuditTiles(summary: state.summary),
                    ),
                  ),
                  if (state.items.isEmpty && !state.loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.all(Sp.s7),
                        child: SatEmpty(
                          icon: Icons.history,
                          title: AppStrings.auditEmpty,
                          body: AppStrings.auditEmptyBody,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        Sp.s7,
                        0,
                        Sp.s7,
                        Sp.s7,
                      ),
                      sliver: _AuditTable(
                        items: state.items,
                        loadingMore: state.loadingMore,
                      ),
                    ),
                ],
              ),
              if (state.pending.isNotEmpty)
                Positioned(
                  top: Sp.s3,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _NewRowsButton(
                      count: state.pending.length,
                      onTap: () {
                        repo.flushPending();
                        _scroll.animateTo(
                          0,
                          duration: satMotion(context, 240),
                          curve: satEaseOut,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _windowLabel(AuditWindow w) => switch (w) {
  AuditWindow.today => AppStrings.auditWindowToday,
  AuditWindow.yesterday => AppStrings.auditWindowYesterday,
  AuditWindow.week => AppStrings.auditWindowWeek,
  AuditWindow.all => AppStrings.auditWindowAll,
};

class _AuditToolbar extends ConsumerStatefulWidget {
  final VenueAuditState state;
  final VenueAuditRepository repo;
  const _AuditToolbar({required this.state, required this.repo});

  @override
  ConsumerState<_AuditToolbar> createState() => _AuditToolbarState();
}

class _AuditToolbarState extends ConsumerState<_AuditToolbar> {
  bool _exporting = false;

  VenueAuditState get state => widget.state;
  VenueAuditRepository get repo => widget.repo;

  @override
  Widget build(BuildContext context) {
    final f = state.filters;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150,
          child: SatDropdown<AuditWindow>(
            value: f.window,
            options: [
              for (final w in AuditWindow.values) SatOption(w, _windowLabel(w)),
            ],
            onChanged: (w) =>
                w == null ? null : repo.setFilters(f.copyWith(window: w)),
          ),
        ),
        const SizedBox(width: Sp.s2),
        SizedBox(
          width: 170,
          child: SatDropdown<AuditType?>(
            value: f.types.length == 1 ? f.types.first : null,
            options: [
              const SatOption(null, AppStrings.auditTypeAll),
              for (final t in auditSummaryTypes)
                SatOption(t, auditTypeLabel(t)),
            ],
            onChanged: (t) => repo.setFilters(
              f.copyWith(types: t == null ? <AuditType>{} : {t}),
            ),
          ),
        ),
        const SizedBox(width: Sp.s2),
        SatButton.outline(
          label: AppStrings.auditExport,
          icon: Icons.download_outlined,
          size: SatButtonSize.sm,
          busy: _exporting,
          onTap: state.items.isEmpty ? null : _export,
        ),
      ],
    );
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      // The path carries the active filters, so the file always matches what
      // is on screen — and it is unpaged, so it matches the whole window
      // rather than the rows scrolled so far.
      await exportAuditCsv(ref, path: repo.csvPath());
    } catch (_) {
      if (mounted) {
        ref.read(errorBusServiceProvider).push('Gagal mengekspor audit');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _AuditTiles extends StatelessWidget {
  final Map<AuditType, AuditTally> summary;
  const _AuditTiles({required this.summary});

  static const _labels = <AuditType, String>{
    AuditType.voidItem: AppStrings.auditTileVoid,
    AuditType.comp: AppStrings.auditTileComp,
    AuditType.discountApplied: AppStrings.auditTileDiscount,
    AuditType.refund: AppStrings.auditTileRefund,
    AuditType.menuKilled: AppStrings.auditTileKilled,
    AuditType.modify: AppStrings.auditTileModify,
  };

  /// Types whose tile carries rupiah. The rest count occurrences — an 86 has
  /// no amount, and inventing one would be a number with nothing behind it.
  static const _money = <AuditType>{
    AuditType.voidItem,
    AuditType.comp,
    AuditType.discountApplied,
    AuditType.refund,
  };

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return LayoutBuilder(
      builder: (context, c) {
        const gap = Sp.s3;
        final columns = c.maxWidth >= 1100 ? 6 : 3;
        final width = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in auditSummaryTypes)
              SizedBox(
                width: width,
                child: TabletStatTile(
                  value: '${summary[t]?.count ?? 0}',
                  label: _money.contains(t)
                      ? '${_labels[t]} · ${formatIDR(summary[t]?.amount ?? 0)}'
                      : _labels[t]!,
                  valueColor: (summary[t]?.count ?? 0) > 0
                      ? auditTone(t, sc).fg
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AuditTable extends StatelessWidget {
  final List<AuditEntry> items;
  final bool loadingMore;
  const _AuditTable({required this.items, required this.loadingMore});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: SatBox.d(
              color: sc.bg2,
              border: SatB.all(color: sc.border0),
              borderRadius: BorderRadius.vertical(top: SatR.c(Sp.s3h)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.s4,
              vertical: Sp.s3,
            ),
            child: const _AuditRowLayout(
              time: Text(AppStrings.auditColTime),
              type: Text(AppStrings.auditColType),
              user: Text(AppStrings.auditColUser),
              event: Text(AppStrings.auditColEvent),
              amount: Text(AppStrings.auditColAmount),
              reason: Text(AppStrings.auditColReason),
              header: true,
            ),
          ),
        ),
        SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, i) => _AuditLogRow(
            entry: items[i],
            last: i == items.length - 1 && !loadingMore,
          ),
        ),
        if (loadingMore)
          SliverToBoxAdapter(
            child: Container(
              decoration: SatBox.d(
                color: sc.bg2,
                border: SatB.all(color: sc.border0),
              ),
              padding: const EdgeInsets.symmetric(vertical: Sp.s5),
              alignment: Alignment.center,
              child: const SizedBox(
                width: Sp.s4h,
                height: Sp.s4h,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _AuditLogRow extends StatelessWidget {
  final AuditEntry entry;
  final bool last;
  const _AuditLogRow({required this.entry, required this.last});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final tone = auditTone(entry.type, sc);
    return Container(
      decoration: SatBox.d(
        color: sc.bg2,
        border: SatB.all(color: sc.border0),
        borderRadius: last
            ? BorderRadius.vertical(bottom: SatR.c(Sp.s3h))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: Sp.s4, vertical: Sp.s3),
      child: _AuditRowLayout(
        time: Text(
          formatClockId(entry.when),
          style: SatType.mono(color: sc.textMd),
        ),
        type: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: SatBox.d(color: tone.bg, borderRadius: SatR.a(6)),
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.s2,
              vertical: Sp.sHair,
            ),
            child: Text(
              auditTypeLabel(entry.type),
              style: SatType.labelS(color: tone.fg),
            ),
          ),
        ),
        user: Text(
          entry.actorName ?? AppStrings.auditSystemActor,
          style: SatType.bodyS(
            color: entry.actorName == null ? sc.textDim : sc.textHi,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        event: Text(
          entry.title,
          style: SatType.bodyS(color: sc.textHi),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        amount: Text(
          entry.amountCents == null ? '—' : formatIDR(entry.amountCents!),
          style: SatType.mono(
            color: entry.amountCents == null ? sc.textDim : sc.textMd,
          ),
        ),
        reason: Text(
          entry.reason ?? '—',
          style: SatType.bodyS(color: sc.textMd),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// One column geometry for the header and every row — they must not drift
/// apart, and two hand-tuned `Row`s always eventually do.
class _AuditRowLayout extends StatelessWidget {
  final Widget time;
  final Widget type;
  final Widget user;
  final Widget event;
  final Widget amount;
  final Widget reason;
  final bool header;

  const _AuditRowLayout({
    required this.time,
    required this.type,
    required this.user,
    required this.event,
    required this.amount,
    required this.reason,
    this.header = false,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 64, child: time),
        const SizedBox(width: Sp.s3),
        SizedBox(width: 92, child: type),
        const SizedBox(width: Sp.s3),
        SizedBox(width: 132, child: user),
        const SizedBox(width: Sp.s3),
        Expanded(flex: 3, child: event),
        const SizedBox(width: Sp.s3),
        SizedBox(width: 110, child: amount),
        const SizedBox(width: Sp.s3),
        Expanded(flex: 2, child: reason),
      ],
    );
    if (!header) return row;
    return DefaultTextStyle.merge(
      style: SatType.labelS(color: sc.textDim),
      child: row,
    );
  }
}

/// "N baru" — the held-back rows, offered rather than inserted.
///
/// A plain [SatButton]: it is a button, and redrawing one here would drift
/// from the shared control the first time the accent fill changes.
class _NewRowsButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NewRowsButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) => SatButton.primary(
    label: AppStrings.auditNewRows(count),
    icon: Icons.arrow_upward_rounded,
    size: SatButtonSize.sm,
    onTap: onTap,
  );
}

class _AuditPhoneNotice extends StatelessWidget {
  const _AuditPhoneNotice();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(Sp.s5),
    child: Center(
      child: SatEmpty(
        icon: Icons.tablet_mac_outlined,
        title: AppStrings.auditTabletOnly,
        body: AppStrings.auditTabletOnlyBody,
      ),
    ),
  );
}
