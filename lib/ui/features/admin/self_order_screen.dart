import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/data/models/self_order_dto.dart';
import 'package:satset/data/repositories/self_order_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';
import '_common.dart';
import 'package:satset/data/models/venue_settings_dto.dart';

/// **[[Pesan mandiri]]** — the guest-order queue (ADR-0105, ADR-0106).
///
/// A nav destination of its own on both form factors, not a hub child: the
/// person who accepts a guest order is a waiter, the Venue hub is
/// `manageStaff`, and before this the queue was unreachable on a tablet by
/// exactly the role it was built for. Gated `takeOrder`, and everything an
/// owner configures — codes, guest menu, rules — is a different screen behind
/// `editSettings` ([[SelfOrderAdminScreen]]).
class SelfOrderScreen extends ConsumerWidget {
  const SelfOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final st = ref.watch(selfOrderProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminEmbeddedStrip(title: l10n.soTitle, sub: l10n.soSub),
        Expanded(child: _QueueTab(state: st)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// tab 1 — the queue
// ---------------------------------------------------------------------------

/// The queue's status filter. Applied **client-side** to the snapshot already
/// in hand rather than through `GET /selforder?status=`: the payload carries
/// the whole day, the counts on the hero are derived from all of it, and a
/// round trip per pill would make the numbers and the list disagree mid-flight.
enum _QueueFilter { all, pending, accepted, rejected }

class _QueueTab extends ConsumerStatefulWidget {
  final SelfOrderState state;
  const _QueueTab({required this.state});

  @override
  ConsumerState<_QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends ConsumerState<_QueueTab> {
  _QueueFilter _filter = _QueueFilter.all;

  String _filterLabel(AppL10n l10n, _QueueFilter f) => switch (f) {
    _QueueFilter.pending => l10n.soFilterPending,
    _QueueFilter.accepted => l10n.soFilterAccepted,
    _QueueFilter.rejected => l10n.soFilterRejected,
    _QueueFilter.all => l10n.soFilterAll,
  };

  /// A guest's own cancellation files under "ditolak" rather than earning a
  /// fifth pill: from the floor's side both mean the food is not happening,
  /// and the card still says which it was.
  bool _matches(_QueueFilter f, String status) => switch (f) {
    _QueueFilter.all => true,
    _QueueFilter.pending => status == 'pending',
    _QueueFilter.accepted => status == 'accepted',
    _QueueFilter.rejected => status == 'rejected' || status == 'cancelled',
  };

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l10n = context.l10n;
    final venue = ref.watch(venueSettingsProvider);
    final pending = [
      for (final o in state.pending)
        if (_matches(_filter, o.status)) o,
    ];
    final zoneOf = {for (final t in state.tables) t.id: t.zoneName};
    final alcoholIds = {
      for (final i in state.menu)
        if (i.alcohol) i.id,
    };
    final decided = [
      for (final o in state.orders)
        if (o.status != 'pending' && _matches(_filter, o.status)) o,
    ];

    if (!venue.guestOrderingOn && state.orders.isEmpty) {
      return Center(
        child: SatEmpty(
          icon: Icons.qr_code_2_outlined,
          title: l10n.soOffTitle,
          body: l10n.soOffBody,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(Sp.s4),
      children: [
        SetHero(
          label: l10n.soHeroLabel,
          value: l10n.soHeroValue(state.stats.total),
          desc: l10n.soHeroDesc(
            state.stats.accepted,
            state.stats.rejected,
            formatIDR(state.stats.value),
          ),
          // Unfiltered on purpose: the hero says what the day looks like, and
          // filtering the list to "Ditolak" must not make a queue with orders
          // still waiting in it read as calm.
          warn: state.pending.isNotEmpty,
        ),
        const SizedBox(height: Sp.s3),
        Row(
          children: [
            Expanded(
              child: SetTile(
                label: l10n.soStatPending,
                value: '${state.stats.pending}',
              ),
            ),
            const SizedBox(width: Sp.s3),
            Expanded(
              child: SetTile(
                label: l10n.soStatWait,
                value: l10n.soWaitSecs(state.stats.medianWaitSecs),
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.s4),
        Wrap(
          spacing: Sp.s2,
          runSpacing: Sp.s2,
          children: [
            for (final f in _QueueFilter.values)
              SatChip.select(
                label: _filterLabel(l10n, f),
                selected: _filter == f,
                onTap: () => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: Sp.s4),
        if (pending.isEmpty && decided.isEmpty)
          SatEmpty(
            icon: Icons.qr_code_2_outlined,
            // A filter hiding everything is not the same fact as an empty
            // day, and offering the way back beats leaving the owner to
            // wonder where their orders went.
            title: _filter == _QueueFilter.all
                ? l10n.soQueueEmptyTitle
                : l10n.soQueueEmptyFilteredTitle,
            body: _filter == _QueueFilter.all
                ? l10n.soQueueEmptyBody
                : l10n.soQueueEmptyFiltered,
            action: _filter == _QueueFilter.all
                ? null
                : SatButton.outline(
                    label: l10n.soFilterAll,
                    onTap: () => setState(() => _filter = _QueueFilter.all),
                  ),
          ),
        if (pending.isNotEmpty) ...[
          Row(
            children: [
              Expanded(child: SatSectionLabel(l10n.soTabQueue)),
              SatButton.primary(
                label: l10n.soAcceptAll,
                size: SatButtonSize.sm,
                onTap: () => _acceptAll(context, ref),
              ),
            ],
          ),
          const SizedBox(height: Sp.s2),
          for (final o in pending)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s3),
              child: _GuestOrderCard(
                order: o,
                actionable: true,
                zoneName: zoneOf[o.tableId] ?? '',
                alcoholIds: alcoholIds,
              ),
            ),
        ],
        if (decided.isNotEmpty) ...[
          const SizedBox(height: Sp.s4),
          SatSectionLabel(l10n.soSectionDecided),
          const SizedBox(height: Sp.s2),
          for (final o in decided)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s2),
              child: _GuestOrderCard(
                order: o,
                actionable: false,
                zoneName: zoneOf[o.tableId] ?? '',
                alcoholIds: alcoholIds,
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _acceptAll(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(selfOrderProvider.notifier).acceptAll();
    final left = ref.read(selfOrderProvider).pending.length;
    if (left > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.soAcceptFailed(left))),
      );
    }
  }
}

String _statusLabel(BuildContext context, String status) => switch (status) {
  'accepted' => context.l10n.soStatusAccepted,
  'rejected' => context.l10n.soStatusRejected,
  'cancelled' => context.l10n.soStatusCancelled,
  // Falls through to the raw code rather than blank, like every other
  // resolver: an older row or a newer server must still render (ADR-0085).
  'pending' => context.l10n.soStatusPending,
  _ => status,
};

/// The rejection reasons, as codes. Shared by the sheet that writes one and the
/// card that reads one back.
const _rejectReasons = ['out_of_stock', 'menu_changed', 'closed', 'other'];

String _reasonLabel(BuildContext context, String code) => switch (code) {
  'out_of_stock' => context.l10n.soReasonHabis,
  'menu_changed' => context.l10n.soReasonGantiMenu,
  'closed' => context.l10n.soReasonTutup,
  'other' => context.l10n.soReasonOther,
  _ => code,
};

class _GuestOrderCard extends ConsumerWidget {
  final GuestOrderDto order;
  final bool actionable;

  /// Which zone the table sits in, and which item ids need an ID checked.
  /// Both are resolved by the tab from the one payload it already holds —
  /// an order carries a table id and item ids, and asking the server to
  /// repeat the zone and the alcohol flag on every line would be a second
  /// copy of two facts already on this screen.
  final String zoneName;
  final Set<String> alcoholIds;

  const _GuestOrderCard({
    required this.order,
    required this.actionable,
    this.zoneName = '',
    this.alcoholIds = const {},
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l10n = context.l10n;
    final hue = switch (order.status) {
      'accepted' => SatChipHue.success,
      // A guest withdrawing their own order is not a failure — `urgent` is the
      // scarce signal, and spending it here teaches the room to ignore red.
      // Only a rejection is something the venue did.
      'rejected' => SatChipHue.urgent,
      'cancelled' => SatChipHue.neutral,
      _ => SatChipHue.warn,
    };
    final hasAlcohol = order.lines.any((x) => alcoholIds.contains(x.itemId));
    final meta = [
      if (zoneName.isNotEmpty) zoneName,
      formatClockId(order.submittedAt.toIso8601String()),
      l10n.soLines(order.lines.length),
      formatIDR(order.subtotal),
    ].join(' · ');
    return SatCard.plain(
      padding: const EdgeInsets.all(Sp.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  // A counter order has no table and so no label — the word
                  // for "the counter" is composed here, like every other code
                  // that crosses the layer (ADR-0085, ADR-0109).
                  order.counter
                      ? context.l10n.soCounterLabel
                      : (order.tableLabel ?? order.tableId),
                  style: SatType.labelL(color: sc.textHi),
                ),
              ),
              SatChip.tag(label: _statusLabel(context, order.status), hue: hue),
            ],
          ),
          const SizedBox(height: Sp.s1),
          Text(meta, style: SatType.monoS(color: sc.textLo)),
          if (hasAlcohol) ...[
            const SizedBox(height: Sp.s2),
            // Loud on purpose. Self-order can take the order; it cannot look
            // at a face, and this is the one line on the card that is about
            // the law rather than the food.
            Text(l10n.soAlcoholWarn, style: SatType.bodyS(color: sc.warn)),
          ],
          const SizedBox(height: Sp.s3),
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s1h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: Sp.s12,
                    child: Text(
                      '${line.qty}×',
                      style: SatType.monoM(color: sc.textMd),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.variantName.isEmpty
                              ? line.name
                              : '${line.name} · ${line.variantName}',
                          style: SatType.bodyM(color: sc.textHi),
                        ),
                        if (line.modifiers.isNotEmpty)
                          Text(
                            [
                              for (final m in line.modifiers) m.label,
                            ].join(' · '),
                            style: SatType.bodyS(color: sc.textMd),
                          ),
                        if ((line.note ?? '').isNotEmpty)
                          Text(
                            line.note!,
                            style: SatType.bodyS(color: sc.textLo),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    formatIDR(line.unitPrice * line.qty),
                    style: SatType.monoM(color: sc.textMd),
                  ),
                ],
              ),
            ),
          if ((order.rejectReasonCode ?? '').isNotEmpty) ...[
            const SizedBox(height: Sp.s2),
            Text(
              _reasonLabel(context, order.rejectReasonCode!),
              style: SatType.bodyS(color: sc.urgent),
            ),
          ],
          if ((order.decidedBy ?? '').isNotEmpty) ...[
            const SizedBox(height: Sp.s1),
            Text(
              l10n.soDecidedBy(order.decidedBy!),
              style: SatType.bodyS(color: sc.textLo),
            ),
          ],
          if (actionable) ...[
            const SizedBox(height: Sp.s3),
            Row(
              children: [
                Expanded(
                  child: SatButton.primary(
                    label: l10n.soAccept,
                    icon: Icons.check_rounded,
                    onTap: () =>
                        ref.read(selfOrderProvider.notifier).accept(order.id),
                  ),
                ),
                const SizedBox(width: Sp.s2),
                Expanded(
                  child: SatButton.outline(
                    label: l10n.soReject,
                    onTap: () => _reject(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final code = await showSatSheet<String>(
      context,
      builder: (c) => _ReasonSheet(),
    );
    if (code == null) return;
    await ref.read(selfOrderProvider.notifier).reject(order.id, code);
  }
}

class _ReasonSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SatSheetHeader(
            onClose: () => Navigator.of(context).pop(),
            child: Text(
              context.l10n.soRejectTitle,
              style: SatType.labelL(color: sc.textHi),
            ),
          ),
          for (final code in _rejectReasons)
            Padding(
              padding: const EdgeInsets.only(
                left: Sp.s4,
                right: Sp.s4,
                bottom: Sp.s2,
              ),
              child: SatButton.outline(
                label: _reasonLabel(context, code),
                onTap: () => Navigator.of(context).pop(code),
              ),
            ),
          const SizedBox(height: Sp.s3),
        ],
      ),
    );
  }
}
