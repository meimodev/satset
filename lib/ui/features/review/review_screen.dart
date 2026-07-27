import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/core/localization/app_strings.dart';
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
import 'package:satset/domain/use_cases/bill_math.dart';
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
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text('Gagal kirim: ${next.error}')));
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
        ? 'Layanan'
        : 'Layanan · ${_fmtPct(venue.serviceRateBps)}';
    final taxLabel = 'Pajak · ${_fmtPct(venue.taxRateBps)}';
    final tagsById = ref.watch(menuTagsByIdProvider);
    final allergens = <String>{};
    for (final c in cart) {
      allergens.addAll(c.allergens);
    }
    final kitchenCt = cart.fold<int>(0, (s, c) => s + c.qty);
    final barCt = 0;

    String sendTarget;
    if (kitchenCt > 0 && barCt > 0) {
      sendTarget = 'dapur + bar';
    } else if (kitchenCt > 0) {
      sendTarget = 'dapur';
    } else {
      sendTarget = 'bar';
    }

    return Scaffold(
      backgroundColor: sc.bg0,
      body: Stack(
        children: [
          Column(
            children: [
              SatAppBar(
                onBack: () => safePop(context, fallback: backFallback),
                title: tableless
                    ? (_isTakeaway
                          ? 'Tinjau · Bawa pulang'
                          : 'Tinjau · Pesanan baru')
                    : 'Tinjau · Meja ${table!.displayName}',
                crumbs: tableless
                    ? (_isTakeaway
                          ? const ['Bawa pulang', 'Tinjau']
                          : const ['Pesanan baru', 'Tinjau'])
                    : ['Meja', table!.displayName, 'Tinjau'],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tinjau pesanan',
                      style: SatType.sans(
                        size: 30,
                        weight: FontWeight.w600,
                        letterSpacing: -0.6,
                        height: 1.05,
                        color: sc.textHi,
                      ),
                    ),
                    const SizedBox(height: Sp.s1),
                    Text(
                      tableless
                          ? (_isTakeaway
                                ? 'BAWA PULANG · ${cart.fold<int>(0, (s, c) => s + c.qty)} ITEM'
                                : 'TANPA MEJA · ${cart.fold<int>(0, (s, c) => s + c.qty)} ITEM · PILIH MEJA SAAT KIRIM')
                          : 'MEJA ${table!.displayName} · ${table.pax} TAMU · ${cart.fold<int>(0, (s, c) => s + c.qty)} ITEM',
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
                        label: 'Dapur × $kitchenCt',
                        size: SatChipSize.sm,
                      ),
                    if (barCt > 0)
                      SatChip.tag(
                        icon: Icons.local_bar,
                        label: 'Bar × $barCt',
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
                        for (final cid in [
                          CourseId.drinksNow,
                          CourseId.starters,
                          CourseId.mains,
                          CourseId.sides,
                          CourseId.desserts,
                          CourseId.fireNow,
                        ])
                          if (grouped[cid] != null && grouped[cid]!.isNotEmpty)
                            _CourseBlock(
                              course: Courses.byId(cid),
                              items: grouped[cid]!,
                              onRemove: (id) => ref
                                  .read(cartProvider(tableId).notifier)
                                  .remove(id),
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
                                  label: 'Subtotal',
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
                                    label: 'Total perkiraan',
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
                            'PEMBAYARAN DITANGANI DI LUAR SATSET · BILL DICETAK DARI POS SAAT DISAJIKAN',
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
                    ? 'Mengirim…'
                    : _isTakeaway
                    ? 'Tambah ke pesanan'
                    : tableless
                    ? 'Kirim pesanan'
                    : 'Kirim ke $sendTarget',
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
                          return;
                        }

                        // Table-less menu-first: choose dine-in (assign a table)
                        // or Bawa pulang (takeaway). See ADR-0026.
                        if (tableless) {
                          final choice = await _chooseCommit(context);
                          if (choice == null || !context.mounted) return;
                          if (choice == _Commit.takeaway) {
                            final guest = await _askGuestName(context);
                            if (guest == null || !context.mounted) return;
                            final vid = await vm.submitTakeaway(
                              cart,
                              guestName: guest,
                              actorId: actorId,
                            );
                            if (vid == null || vid.isEmpty) return;
                            ref.read(cartProvider(tableId).notifier).clear();
                            if (context.mounted) context.go('/takeaway/$vid');
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
                                        ? 'Meja keburu terisi. Pilih meja lain.'
                                        : 'Gagal menempati meja: ${e.code ?? e.statusCode}',
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
  return showModalBottomSheet<_Commit>(
    context: context,
    useRootNavigator: true,
    backgroundColor: sc.bg1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: SatR.c(24)),
    ),
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
            Text(
              'Kirim pesanan ke',
              style: SatType.sans(
                size: 18,
                weight: FontWeight.w600,
                color: sc.textHi,
              ),
            ),
            const SizedBox(height: Sp.s4),
            _CommitTile(
              icon: Icons.table_restaurant_rounded,
              title: 'Meja (dine-in)',
              sub: 'Tetapkan ke meja kosong',
              onTap: () => Navigator.of(ctx).pop(_Commit.dineIn),
            ),
            const SizedBox(height: Sp.s2h),
            _CommitTile(
              icon: Icons.shopping_bag_rounded,
              title: 'Bawa pulang',
              sub: 'Takeaway tanpa meja',
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
                    Text(
                      title,
                      style: SatType.sans(
                        size: 15,
                        weight: FontWeight.w600,
                        color: sc.textHi,
                      ),
                    ),
                    const SizedBox(height: Sp.sHair),
                    Text(sub, style: SatType.sans(size: 12, color: sc.textMd)),
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

/// Prompt for the guest name (the takeaway visit's only handle). Required.
Future<String?> _askGuestName(BuildContext context) {
  final sc = context.sat;
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: sc.bg1,
      title: Text('Nama tamu', style: SatType.sans(color: sc.textHi)),
      content: SatField.text(
        controller: ctrl,
        hint: 'mis. Budi',
        autofocus: true,
        capitalization: TextCapitalization.words,
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) Navigator.of(ctx).pop(v.trim());
        },
      ),
      actions: [
        SatButton.ghost(
          label: AppStrings.cancel,
          onTap: () => Navigator.of(ctx).pop(),
        ),
        SatButton.primary(
          label: 'Lanjut',
          onTap: () {
            final v = ctrl.text.trim();
            if (v.isNotEmpty) Navigator.of(ctx).pop(v);
          },
        ),
      ],
    ),
  );
}

class _CourseBlock extends StatelessWidget {
  final Course course;
  final List<CartItem> items;
  final void Function(String) onRemove;
  const _CourseBlock({
    required this.course,
    required this.items,
    required this.onRemove,
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
                  course.name.toUpperCase(),
                  style: SatType.caption(color: sc.textMd),
                ),
                const Spacer(),
                Text(
                  auto ? 'auto-bakar' : 'ditahan sampai dibakar',
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '×${c.qty}',
                        style: SatType.monoM(color: sc.textMd),
                      ),
                    ),
                    const SizedBox(width: Sp.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name +
                                (c.variantName.isEmpty
                                    ? ''
                                    : ' · ${c.variantName}'),
                            style: SatType.sans(
                              size: 14,
                              weight: FontWeight.w500,
                              letterSpacing: -0.14,
                              color: sc.textHi,
                            ),
                          ),
                          MenuTagBadges(itemId: c.itemId),
                          if (c.modifiers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                c.modifiers.join(' · '),
                                style: SatType.sans(
                                  size: 12,
                                  color: sc.textMd,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          if (c.note.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: Sp.s1),
                              child: NoteLine(
                                label: 'Instruksi khusus',
                                text: c.note,
                              ),
                            ),
                          const SizedBox(height: Sp.s2),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => onRemove(c.id),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 12,
                                      color: sc.urgent,
                                    ),
                                    const SizedBox(width: Sp.s1),
                                    Text(
                                      'Hapus',
                                      style: SatType.sans(
                                        size: 12,
                                        color: sc.urgent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                formatIDR(c.unitPrice * c.qty),
                                style: SatType.monoM(color: sc.textMd),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
              style: SatType.sans(
                size: isTotal ? 16 : 13,
                weight: isTotal ? FontWeight.w600 : FontWeight.w400,
                color: isTotal ? sc.textHi : sc.textMd,
              ),
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
