import 'package:flutter/material.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/cashier/cashier_bill_screen.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/design/spacing.dart';

enum _CashierTab { aktif, riwayat }

/// Venue-wide cashier surface (`/kasir`). Two tabs off one segmented toggle:
/// **Aktif** — every payable visit with its live total/outstanding (tap to
/// settle); **Riwayat** — venue-wide [[Past bills]], last 7 days, filterable by
/// table. Gated by `Capability.settleBill`. See ADR-0023 / ADR-0024.
class CashierScreen extends ConsumerStatefulWidget {
  const CashierScreen({super.key});

  @override
  ConsumerState<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends ConsumerState<CashierScreen> {
  _CashierTab _tab = _CashierTab.aktif;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Row(
                children: [
                  Text('Kasir', style: SatType.h2(color: sc.textHi)),
                  const Spacer(),
                  _TabToggle(
                    tab: _tab,
                    onChanged: (t) => setState(() => _tab = t),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: Duration(
                  milliseconds: motionEnabled(context) ? 220 : 0,
                ),
                switchInCurve: satEaseOut,
                switchOutCurve: satEaseOut,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: KeyedSubtree(
                  key: ValueKey(_tab),
                  child: _tab == _CashierTab.aktif
                      ? const _PayableList()
                      : const VenueHistoryView(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style two-segment pill switching the cashier between live bills and
/// history. Chrome, not a CTA — the selected segment reads as a raised tile
/// rather than an accent button.
class _TabToggle extends StatelessWidget {
  final _CashierTab tab;
  final ValueChanged<_CashierTab> onChanged;
  const _TabToggle({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    Widget seg(_CashierTab t, String label) {
      final active = tab == t;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(t),
        child: AnimatedContainer(
          duration: satMotion(context, 180),
          curve: satEaseOut,
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s4,
            vertical: Sp.s2,
          ),
          decoration: SatBox.d(
            color: active ? sc.bg0 : Colors.transparent,
            borderRadius: SatR.a(9),
          ),
          child: Text(
            label,
            style: SatType.labelM(color: active ? sc.textHi : sc.textLo),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Sp.s1),
      decoration: SatBox.d(color: sc.bg2, borderRadius: SatR.a(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(_CashierTab.aktif, 'Aktif'),
          seg(_CashierTab.riwayat, 'Riwayat'),
        ],
      ),
    );
  }
}

/// The Aktif tab: live payable visits, pull-to-refresh.
class _PayableList extends ConsumerWidget {
  const _PayableList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(settlementProvider);
    final status = ref.watch(settlementStatusProvider);
    return RefreshIndicator(
      onRefresh: () => ref.read(settlementProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          if (status.isLoading && bills.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (status.hasError && bills.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _Empty(
                icon: Icons.cloud_off_rounded,
                text: 'Gagal memuat tagihan.\nTarik untuk coba lagi.',
              ),
            )
          else if (bills.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _Empty(
                icon: Icons.receipt_long_outlined,
                text: 'Belum ada meja yang siap dibayar.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              sliver: SliverList.separated(
                itemCount: bills.length,
                separatorBuilder: (_, _) => const SizedBox(height: Sp.s2),
                itemBuilder: (_, i) =>
                    Reveal(index: i, child: _PayableTile(bills[i])),
              ),
            ),
        ],
      ),
    );
  }
}

class _PayableTile extends StatelessWidget {
  final BillSummary b;
  const _PayableTile(this.b);

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final settled = b.fullySettled;
    final partial = !settled && b.paidAmount > 0;
    final (badgeColor, badgeText) = settled
        ? (sc.success, 'Lunas')
        : partial
        ? (sc.warn, 'Sebagian')
        : (sc.textLo, 'Belum bayar');
    return PressScale(
      child: Material(
        color: sc.bg1,
        borderRadius: SatR.a(16),
        child: InkWell(
          borderRadius: SatR.a(16),
          // Root navigator: the bill is a full page with its own AppBar and a
          // bottom CTA. Pushed on the shell's navigator instead, the floating
          // phone tab bar floats *over* it and swallows "Tutup tagihan". Same
          // treatment as the table flow, which is also outside the shell.
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) =>
                  CashierBillScreen(visitId: b.visitId, tableId: b.tableId),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Sp.s3h),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: SatBox.d(
                    color: b.isTakeaway
                        ? sc.accentSoft
                        : (b.detached ? sc.warnSoft : sc.bg3),
                    borderRadius: SatR.a(12),
                  ),
                  alignment: Alignment.center,
                  child: b.isTakeaway
                      ? Icon(
                          Icons.shopping_bag_rounded,
                          size: 20,
                          color: sc.accentText,
                        )
                      : Text(
                          b.tableLabel ?? '—',
                          style: SatType.monoM(
                            color: b.detached ? sc.warn : sc.textHi,
                          ),
                        ),
                ),
                const SizedBox(width: Sp.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.isTakeaway
                            ? (b.guestName?.trim().isNotEmpty == true
                                  ? '${b.tableLabel ?? 'Bawa pulang'} · ${b.guestName}'
                                  : (b.tableLabel ?? 'Bawa pulang'))
                            : (b.guestName?.trim().isNotEmpty == true
                                  ? b.guestName!
                                  : 'Meja ${b.tableLabel ?? ''}'.trim()),
                        style: SatType.labelM(color: sc.textHi),
                      ),
                      const SizedBox(height: Sp.s1),
                      Text(
                        b.isTakeaway
                            ? (b.detached
                                  ? 'Bawa pulang · sudah diserahkan'
                                  : 'Bawa pulang · belum diserahkan')
                            : (b.detached
                                  ? 'Meja sudah ditutup · belum lunas'
                                  : '${b.pax} tamu · ${b.receiptCount} struk'
                                        '${b.mode == 'even' ? ' · rata' : ''}'),
                        style: ((b.detached || b.isTakeaway)
                            ? SatType.labelS(
                                color: b.isTakeaway
                                    ? sc.accentText
                                    : (b.detached ? sc.warn : sc.textLo),
                              )
                            : SatType.bodyS(
                                color: b.isTakeaway
                                    ? sc.accentText
                                    : (b.detached ? sc.warn : sc.textLo),
                              )),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatIDR(b.outstanding),
                      style: SatType.monoM(
                        color: settled ? sc.textLo : sc.textHi,
                      ),
                    ),
                    const SizedBox(height: Sp.s1h),
                    AnimatedContainer(
                      duration: satMotion(context, 240),
                      curve: satEaseOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sp.s2,
                        vertical: Sp.sHair,
                      ),
                      decoration: SatBox.d(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: SatR.a(6),
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: satMotion(context, 240),
                        curve: satEaseOut,
                        style: SatType.labelS(color: badgeColor),
                        child: Text(badgeText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 44, color: sc.textLo),
        const SizedBox(height: Sp.s3),
        Text(
          text,
          textAlign: TextAlign.center,
          style: SatType.bodyM(color: sc.textLo),
        ),
      ],
    );
  }
}

/// Whether the signed-in account can open the cashier surface.
bool canSettle(WidgetRef ref) =>
    ref.watch(authStateProvider).has(Capability.settleBill);
