import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/cashier/cashier_bill_screen.dart';

/// Venue-wide cashier surface (`/kasir`): every payable table with its live
/// bill total and outstanding balance. Tap a table to settle its bill. Gated
/// by `Capability.settleBill`. See ADR-0023.
class CashierScreen extends ConsumerWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final bills = ref.watch(settlementProvider);
    final status = ref.watch(settlementStatusProvider);

    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(settlementProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text('Kasir',
                      style: SatType.sans(
                          size: 26,
                          weight: FontWeight.w700,
                          color: sc.textHi)),
                ),
              ),
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
                      text: 'Gagal memuat tagihan.\nTarik untuk coba lagi.'),
                )
              else if (bills.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Empty(
                      icon: Icons.receipt_long_outlined,
                      text: 'Belum ada meja yang siap dibayar.'),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  sliver: SliverList.separated(
                    itemCount: bills.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _PayableTile(bills[i]),
                  ),
                ),
            ],
          ),
        ),
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
    return Material(
      color: sc.bg1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CashierBillScreen(tableId: b.tableId),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: sc.bg3,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(b.tableLabel ?? '—',
                    style: SatType.mono(
                        size: 15, weight: FontWeight.w700, color: sc.textHi)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.guestName?.trim().isNotEmpty == true
                        ? b.guestName!
                        : 'Meja ${b.tableLabel ?? ''}'.trim(),
                        style: SatType.sans(
                            size: 14,
                            weight: FontWeight.w600,
                            color: sc.textHi)),
                    const SizedBox(height: 3),
                    Text(
                        '${b.pax} tamu · ${b.receiptCount} struk'
                        '${b.mode == 'even' ? ' · rata' : ''}',
                        style: SatType.sans(size: 11.5, color: sc.textLo)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatIDR(b.outstanding),
                      style: SatType.mono(
                          size: 15,
                          weight: FontWeight.w700,
                          color: settled ? sc.textLo : sc.textHi)),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(badgeText,
                        style: SatType.sans(
                            size: 10,
                            weight: FontWeight.w600,
                            color: badgeColor)),
                  ),
                ],
              ),
            ],
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
        const SizedBox(height: 12),
        Text(text,
            textAlign: TextAlign.center,
            style: SatType.sans(size: 13, color: sc.textLo)),
      ],
    );
  }
}

/// Whether the signed-in account can open the cashier surface.
bool canSettle(WidgetRef ref) =>
    ref.watch(authStateProvider).has(Capability.settleBill);

/// Shared helper for closing a fully-settled table from the cashier screen
/// (the convenience affordance — still calls the gated close). See ADR-0023.
Future<void> closeFromCashier(WidgetRef ref, String tableId) async {
  final actor = ref.read(authStateProvider).user?.id;
  await ref.read(tablesProvider.notifier).closeTable(tableId, actorId: actor);
}
