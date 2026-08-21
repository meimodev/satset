import 'package:flutter/material.dart';
import 'package:satset/core/localization/labels.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';
import 'package:satset/ui/core/design/channel_visuals.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/ui/core/widgets/note_line.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/ui/core/design/course_visuals.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/ui/features/cashier/cashier_bill_screen.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/ui/features/menu/cart_line_actions.dart';
import 'package:satset/ui/features/menu/view_models/cart_view_model.dart';
import 'package:satset/ui/features/review/view_models/review_view_model.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart';
import 'package:satset/ui/core/widgets/tag_badge_row.dart';
import 'package:satset/ui/features/tables/widgets/assign_table_sheet.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';

class ReviewScreen extends ConsumerWidget {
  final String tableId;

  /// Table-less menu-first draft: [tableId] is a draft id and the destination
  /// is chosen here (dine-in table or Bawa pulang) before submit.
  final bool tableless;

  /// Set when reviewing items to APPEND to an existing takeaway visit:
  /// [tableId] is the takeaway visit id. See ADR-0026.
  final String? takeawayVisitId;
  const ReviewScreen({
    super.key,
    required this.tableId,
    this.tableless = false,
    this.takeawayVisitId,
  });

  bool get _isTakeaway => takeawayVisitId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l = context.layout;
    final cart = ref.watch(cartProvider(tableId));
    final tables = ref.watch(tablesProvider);
    final table = tableless
        ? null
        : tables.firstWhere(
            (t) => t.id == tableId,
            orElse: () => tables.isEmpty
                ? VenueTable(id: tableId, zoneId: '')
                : tables.first,
          );
    final backFallback = _isTakeaway
        ? '/takeaway/$takeawayVisitId'
        : tableless
        ? '/tables'
        : '/table/$tableId';
    final reviewState = ref.watch(reviewViewModelProvider);
    ref.listen<ReviewState>(reviewViewModelProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(context.l10n.revSendFailed('${next.error}'))),
        );
      }
    });

    final grouped = <CourseId, List<CartItem>>{};
    for (final c in cart) {
      grouped.putIfAbsent(c.course, () => []).add(c);
    }
    final subtotal = cart.fold<int>(0, (s, c) => s + c.unitPrice * c.qty);
    final venue = ref.watch(venueSettingsProvider);
    final breakdown = computeBreakdown(subtotal, venue.toTaxServiceConfig());
    final serviceAmount = breakdown.serviceAmount;
    final taxAmount = breakdown.taxAmount;
    final grandTotal = breakdown.total;
    final serviceLabel = venue.serviceMode == 'fixed'
        ? context.l10n.cshService
        : context.l10n.mnuServicePct(_fmtPct(venue.serviceRateBps));
    final taxLabel = context.l10n.mnuTaxPct(_fmtPct(venue.taxRateBps));
    final tagsById = ref.watch(menuTagsByIdProvider);
    final allergens = <String>{};
    for (final c in cart) {
      allergens.addAll(c.allergens);
    }
    final kitchenCt = cart.fold<int>(0, (s, c) => s + c.qty);
    final barCt = 0;

    String sendTarget;
    if (kitchenCt > 0 && barCt > 0) {
      sendTarget = context.l10n.mnuTargetKitchenBar;
    } else if (kitchenCt > 0) {
      sendTarget = context.l10n.mnuTargetKitchen;
    } else {
      sendTarget = context.l10n.mnuTargetBar;
    }

    return Scaffold(
      backgroundColor: sc.bg0,
      body: Stack(
        children: [
          Column(
            children: [
              SatAppBar(
                onBack: () => safePop(context, fallback: backFallback),
                crumbs: tableless
                    ? (_isTakeaway
                          ? [
                              context.l10n.crumbBawaPulang,
                              context.l10n.crumbTinjau,
                            ]
                          : [
                              context.l10n.crumbPesananBaru,
                              context.l10n.crumbTinjau,
                            ])
                    : [table!.displayName, context.l10n.crumbTinjau],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.revTitle,
                      style: SatType.h1(color: sc.textHi),
                    ),
                    const SizedBox(height: Sp.s1),
                    Text(
                      tableless
                          ? (_isTakeaway
                                ? context.l10n.revHeadTakeaway(kitchenCt)
                                : context.l10n.revHeadTableless(kitchenCt))
                          : context.l10n.revHeadTable(
                              table!.displayName,
                              table.pax,
                              kitchenCt,
                            ),
                      style: SatType.monoS(color: sc.textLo),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (kitchenCt > 0)
                      SatChip.tag(
                        icon: Icons.local_fire_department,
                        label: context.l10n.mnuKitchenCount(kitchenCt),
                        size: SatChipSize.sm,
                      ),
                    if (barCt > 0)
                      SatChip.tag(
                        icon: Icons.local_bar,
                        label: context.l10n.mnuBarCount(barCt),
                        size: SatChipSize.sm,
                      ),
                    if (allergens.isNotEmpty)
                      SatChip.tag(
                        icon: Icons.warning_amber_rounded,
                        label: allergens
                            .map((a) => tagsById[a]?.name ?? '')
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        hue: SatChipHue.urgent,
                        size: SatChipSize.sm,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: l.contentMaxWidth),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        0,
                        0,
                        l.bottomInset + 100,
                      ),
                      children: [
                        for (final cid in Courses.all.map((c) => c.id))
                          if (grouped[cid] != null && grouped[cid]!.isNotEmpty)
                            _ReviewCourseBlock(
                              course: Courses.byId(cid),
                              items: grouped[cid]!,
                              tableId: tableId,
                            ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Sp.s4h,
                              vertical: Sp.s4,
                            ),
                            decoration: SatBox.d(
                              color: sc.bg2,
                              borderRadius: SatR.a(18),
                              border: SatB.all(color: sc.border0),
                            ),
                            child: Column(
                              children: [
                                _TotalsRow(
                                  label: context.l10n.cshSubtotal,
                                  value: formatIDR(subtotal),
                                ),
                                if (venue.serviceEnabled)
                                  _TotalsRow(
                                    label: serviceLabel,
                                    value: formatIDR(serviceAmount),
                                  ),
                                if (venue.taxEnabled)
                                  _TotalsRow(
                                    label: taxLabel,
                                    value: formatIDR(taxAmount),
                                  ),
                                Container(
                                  margin: const EdgeInsets.only(top: Sp.s2),
                                  padding: const EdgeInsets.only(top: Sp.s3),
                                  decoration: SatBox.d(
                                    border: Border(
                                      top: SatB.side(color: sc.border0),
                                    ),
                                  ),
                                  child: _TotalsRow(
                                    label: context.l10n.revEstimatedTotal,
                                    value: formatIDR(grandTotal),
                                    isTotal: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                          child: Text(
                            context.l10n.revPaymentNote,
                            style: SatType.monoS(color: sc.textLo),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 16 + l.padding.left,
            right: 16 + l.padding.right,
            bottom: l.useSideRail
                ? 16 + l.padding.bottom
                : 92 + l.padding.bottom,
            child: SizedBox(
              width: double.infinity,
              child: SatButton.primary(
                label: reviewState.busy
                    ? context.l10n.revSending
                    : _isTakeaway
                    ? context.l10n.revAddToOrder
                    : tableless
                    ? context.l10n.revSendOrder
                    : context.l10n.revSendTo(sendTarget),
                icon: Icons.auto_awesome,
                busy: reviewState.busy,
                size: SatButtonSize.lg,
                trailingValue: formatIDR(subtotal),
                onTap: cart.isEmpty || reviewState.busy
                    ? null
                    : () async {
                        final vm = ref.read(reviewViewModelProvider.notifier);
                        final user = ref.read(authStateProvider).user;
                        final actorId = user?.id;
                        final stations = <String>{
                          if (kitchenCt > 0) 'Dapur',
                          if (barCt > 0) 'Bar',
                        }.join(',');

                        // Takeaway add-items: append to the existing visit.
                        if (_isTakeaway) {
                          final vid = await vm.submitTakeaway(
                            cart,
                            existingVisitId: takeawayVisitId,
                            actorId: actorId,
                          );
                          if (vid == null) return;
                          ref.read(cartProvider(tableId).notifier).clear();
                          if (context.mounted) {
                            context.go('/takeaway/$takeawayVisitId');
                          }
                          if (context.mounted) {
                            await _settleAfterSend(context, ref, vid);
                          }
                          return;
                        }

                        // Table-less menu-first: choose dine-in (assign a table)
                        // or Bawa pulang (takeaway). See ADR-0026.
                        if (tableless) {
                          final choice = await _chooseCommit(context);
                          if (choice == null || !context.mounted) return;
                          if (choice == _Commit.takeaway) {
                            final ta = await askTakeawayDetails(
                              context,
                              nameOptional: ref
                                  .read(venueSettingsProvider)
                                  .counterOn(counterAnonTakeaway),
                            );
                            if (ta == null || !context.mounted) return;
                            final vid = await vm.submitTakeaway(
                              cart,
                              guestName: ta.guestName,
                              channel: ta.channel,
                              prepaid: ta.prepaid,
                              actorId: actorId,
                            );
                            if (vid == null || vid.isEmpty) return;
                            ref.read(cartProvider(tableId).notifier).clear();
                            if (context.mounted) context.go('/takeaway/$vid');
                            if (context.mounted) {
                              await _settleAfterSend(context, ref, vid);
                            }
                            return;
                          }
                          // Dine-in: pick the destination table, seat it, then
                          // submit the draft cart against it.
                          final pick = await showAssignTableSheet(
                            context: context,
                          );
                          if (pick == null || !context.mounted) return;
                          try {
                            await ref
                                .read(tablesProvider.notifier)
                                .seat(
                                  pick.tableId,
                                  pax: pick.pax,
                                  guestName: pick.guestName,
                                  userId: actorId,
                                  userName: user?.name,
                                  acquireLock: true,
                                );
                          } on ApiException catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.code == 'already_seated'
                                        ? context.l10n.revTableTaken
                                        : context.l10n.revSeatFailed(
                                            '${e.code ?? e.statusCode}',
                                          ),
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          await vm.submit(pick.tableId, cart, actorId: actorId);
                          final s = ref.read(reviewViewModelProvider);
                          if (s.error != null || s.submittedTicketIds == null) {
                            return;
                          }
                          ref
                              .read(tablesProvider.notifier)
                              .markPending(pick.tableId, userId: actorId);
                          ref.read(cartProvider(tableId).notifier).clear();
                          if (context.mounted) {
                            // go (not push): drops the draft menu/review stack
                            // and lands on the freshly-seated table detail with
                            // the sent confirmation on top.
                            context.go(
                              '/table/${pick.tableId}/sent?stations=$stations',
                            );
                          }
                          if (context.mounted) {
                            await _settleAfterSend(
                              context,
                              ref,
                              _visitOf(ref, pick.tableId),
                            );
                          }
                          return;
                        }

                        await vm.submit(tableId, cart, actorId: actorId);
                        final s = ref.read(reviewViewModelProvider);
                        if (s.error != null || s.submittedTicketIds == null) {
                          return;
                        }
                        ref
                            .read(tablesProvider.notifier)
                            .markPending(tableId, userId: actorId);
                        ref.read(cartProvider(tableId).notifier).clear();
                        if (context.mounted) {
                          context.push(
                            '/table/$tableId/sent?stations=$stations',
                          );
                        }
                        if (context.mounted) {
                          await _settleAfterSend(
                            context,
                            ref,
                            _visitOf(ref, tableId),
                          );
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Commit { dineIn, takeaway }

/// Menu-first commit chooser: dine-in (assign a table) vs Bawa pulang
/// (takeaway). See ADR-0026.
Future<_Commit?> _chooseCommit(BuildContext context) {
  final sc = context.sat;
  return showSatSheet<_Commit>(
    context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: SatBox.d(
                  color: sc.border1,
                  borderRadius: SatR.a(2),
                ),
              ),
            ),
            const SizedBox(height: Sp.s4h),
            Text(ctx.l10n.revCommitTitle, style: SatType.h3(color: sc.textHi)),
            const SizedBox(height: Sp.s4),
            _CommitTile(
              icon: Icons.table_restaurant_rounded,
              title: ctx.l10n.revCommitDineIn,
              sub: ctx.l10n.revCommitDineInSub,
              onTap: () => Navigator.of(ctx).pop(_Commit.dineIn),
            ),
            const SizedBox(height: Sp.s2h),
            _CommitTile(
              icon: Icons.shopping_bag_rounded,
              title: ctx.l10n.revCommitTakeaway,
              sub: ctx.l10n.revCommitTakeawaySub,
              onTap: () => Navigator.of(ctx).pop(_Commit.takeaway),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CommitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _CommitTile({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Material(
      color: sc.bg2,
      borderRadius: SatR.a(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: SatR.a(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s4,
            vertical: Sp.s3h,
          ),
          decoration: SatBox.d(
            border: SatB.all(color: sc.border0),
            borderRadius: SatR.a(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: sc.accentText),
              const SizedBox(width: Sp.s3h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SatType.labelL(color: sc.textHi)),
                    const SizedBox(height: Sp.sHair),
                    Text(sub, style: SatType.bodyS(color: sc.textMd)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: sc.textLo),
            ],
          ),
        ),
      ),
    );
  }
}

/// The [[Kedai]] switch `settleAfterSend` (ADR-0109): a counter takes the money
/// as part of ordering, so committing opens the bill instead of ending at the
/// sent confirmation.
///
/// It **pushes over** the destination rather than replacing it. Closing the pane
/// leaves the user exactly where an unswitched venue would have landed, so the
/// switch changes what happens next and never what is reachable — and a cashier
/// who decides mid-tap that this one pays later just backs out.
///
/// Gated on [Capability.settleBill] as well as the switch: a waiter who cannot
/// settle must not be handed a pane whose every button would 403. Silent when
/// [visitId] is null — a visit the floor cache has not caught up with yet is a
/// reason to skip the pane, never to block the order that was already written.
Future<void> _settleAfterSend(
  BuildContext context,
  WidgetRef ref,
  String? visitId,
) async {
  if (!shouldSettleAfterSend(
    visitId: visitId,
    settleOn: ref.read(venueSettingsProvider).counterOn(counterSettleAfterSend),
    canSettle: ref.read(authStateProvider).has(Capability.settleBill),
  )) {
    return;
  }
  await openCashierBill(context, visitId: visitId!);
}

/// The three things that must all be true before the pane opens — pulled out
/// of [_settleAfterSend] so the rule can be read (and held) without a screen.
@visibleForTesting
bool shouldSettleAfterSend({
  required String? visitId,
  required bool settleOn,
  required bool canSettle,
}) => visitId != null && visitId.isNotEmpty && settleOn && canSettle;

/// The visit currently seated at [tableId], or null if the floor cache has not
/// seen it yet. Read, never awaited — see [_settleAfterSend].
String? _visitOf(WidgetRef ref, String tableId) {
  for (final t in ref.read(tablesProvider)) {
    if (t.id == tableId) return t.currentVisitId;
  }
  return null;
}

/// What the takeaway prompt collects: the guest name (the visit's handle when
/// it has one) plus how the order reached us and whether it is already paid.
typedef TakeawayDetails = ({String guestName, String channel, bool prepaid});

/// Prompt for the guest name and the [[Kanal (channel)]] (ADR-0066).
///
/// The channel is asked here rather than left to default because the cashier
/// cannot infer it later: a GoFood order and a walk-in bungkus look identical
/// on the bill, and only one of them has money still to collect. Prepaid is
/// offered only for the aggregator channels — a walk-in cannot have prepaid,
/// and an aggregator order can still be cash-on-delivery, so it is a separate
/// question rather than derived.
///
/// [nameOptional] is the [[Kedai]] switch `anonTakeaway` (ADR-0109). A counter
/// shop calls a number, not a name, so demanding one is a keystroke per order
/// that buys nothing. It relaxes the gate rather than hiding the field: an
/// aggregator courier still turns up with a name worth typing, and the same
/// venue takes both kinds of order across one shift.
@visibleForTesting
Future<TakeawayDetails?> askTakeawayDetails(
  BuildContext context, {
  bool nameOptional = false,
}) {
  final sc = context.sat;
  final ctrl = TextEditingController();
  var channel = SatChannel.bungkus;
  var prepaid = false;
  return showSatDialog<TakeawayDetails>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final aggregator =
            channel == SatChannel.gofood || channel == SatChannel.grab;
        return AlertDialog(
          backgroundColor: sc.bg1,
          title: Text(
            ctx.l10n.revCommitTakeaway,
            style: SatType.bodyM(color: sc.textHi),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctx.l10n.revChannel,
                style: SatType.labelS(color: sc.textLo),
              ),
              const SizedBox(height: Sp.s2),
              Wrap(
                spacing: Sp.s2,
                runSpacing: Sp.s2,
                children: [
                  for (final c in SatChannel.values)
                    SatChip.select(
                      label: c.label,
                      selected: channel == c,
                      onTap: () => setState(() {
                        channel = c;
                        // A walk-in cannot be prepaid; clear it rather than
                        // carry a stale yes onto the new channel.
                        if (c != SatChannel.gofood && c != SatChannel.grab) {
                          prepaid = false;
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: Sp.s3h),
              Text(
                ctx.l10n.revGuestOrCourier,
                style: SatType.labelS(color: sc.textLo),
              ),
              const SizedBox(height: Sp.s2),
              SatField.text(
                controller: ctrl,
                hint: ctx.l10n.revGuestHint,
                autofocus: true,
                capitalization: TextCapitalization.words,
              ),
              if (aggregator) ...[
                const SizedBox(height: Sp.s2h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ctx.l10n.revPrepaid,
                        style: SatType.bodyS(color: sc.textHi),
                      ),
                    ),
                    SatToggle(
                      value: prepaid,
                      semanticLabel: ctx.l10n.revPrepaid,
                      onChanged: (v) => setState(() => prepaid = v),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            SatButton.ghost(
              label: ctx.l10n.cancel,
              onTap: () => Navigator.of(ctx).pop(),
            ),
            SatButton.primary(
              label: ctx.l10n.revContinue,
              onTap: () {
                final v = ctrl.text.trim();
                if (v.isEmpty && !nameOptional) return;
                Navigator.of(
                  ctx,
                ).pop((guestName: v, channel: channel.id, prepaid: prepaid));
              },
            ),
          ],
        );
      },
    ),
  );
}

class _ReviewCourseBlock extends StatelessWidget {
  final Course course;
  final List<CartItem> items;

  /// Cart key — [CartLineActions] reaches the notifier itself rather than
  /// threading one callback per verb through this widget.
  final String tableId;

  const _ReviewCourseBlock({
    required this.course,
    required this.items,
    required this.tableId,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final auto =
        course.id == CourseId.fireNow || course.id == CourseId.drinksNow;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: SatBox.d(
                    shape: BoxShape.circle,
                    color: course.color(sc),
                  ),
                ),
                const SizedBox(width: Sp.s2h),
                Text(
                  courseLabel(context.l10n, course.serialId).toUpperCase(),
                  style: SatType.caption(color: sc.textMd),
                ),
                const Spacer(),
                Text(
                  auto
                      ? context.l10n.revAutoFire
                      : context.l10n.revHeldUntilFired,
                  style: SatType.monoS(color: sc.textLo),
                ),
              ],
            ),
          ),
          for (final c in items)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s1h),
              child: Container(
                padding: const EdgeInsets.all(Sp.s3h),
                decoration: SatBox.d(
                  color: sc.bg2,
                  borderRadius: SatR.a(14),
                  border: SatB.all(color: sc.border0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            c.name +
                                (c.variantName.isEmpty
                                    ? ''
                                    : ' · ${c.variantName}'),
                            style: SatType.bodyM(color: sc.textHi),
                          ),
                        ),
                        const SizedBox(width: Sp.s3),
                        // Price moved off the action row: the stepper now
                        // carries the quantity, and the two together did not
                        // fit the 380-wide tablet pane.
                        Text(
                          formatIDR(c.unitPrice * c.qty),
                          style: SatType.monoM(color: sc.textMd),
                        ),
                      ],
                    ),
                    MenuTagBadges(itemId: c.itemId),
                    if (c.modifiers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: Sp.s1),
                        child: Text(
                          c.modifiers.join(' · '),
                          style: SatType.bodyS(color: sc.textMd),
                        ),
                      ),
                    if (c.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: Sp.s1),
                        child: NoteLine(
                          label: context.l10n.tblSpecialInstruction,
                          text: c.note,
                        ),
                      ),
                    const SizedBox(height: Sp.s2),
                    CartLineActions(tableId: tableId, line: c),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  const _TotalsRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.s1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: (isTotal
                  ? SatType.labelL(color: isTotal ? sc.textHi : sc.textMd)
                  : SatType.bodyM(color: isTotal ? sc.textHi : sc.textMd)),
            ),
          ),
          Text(
            value,
            style: isTotal
                ? SatType.monoL(color: sc.textHi)
                : SatType.monoM(color: sc.textHi),
          ),
        ],
      ),
    );
  }
}

String _fmtPct(int bps) {
  final v = bps / 100.0;
  return '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}%';
}
