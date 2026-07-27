import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/repositories/takeaway_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/use_cases/advance_ticket_status_use_case.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/order_line_card.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/widgets/satset_top_bar.dart';
import 'package:satset/ui/features/printing/printer_picker.dart';
import 'package:satset/ui/features/void_flow/line_item_action_sheet.dart';
import 'package:satset/ui/core/design/spacing.dart';

/// Takeaway (Bawa pulang) detail — the visit-keyed home for one takeaway order.
/// Mirrors the table detail minus lock/seat: shows lines, lets the waiter add
/// items, hand the order over ("Serahkan"), and print the money doc. The bill
/// itself is settled on the cashier. See ADR-0026.
class TakeawayDetailScreen extends ConsumerStatefulWidget {
  final String visitId;
  const TakeawayDetailScreen({super.key, required this.visitId});

  @override
  ConsumerState<TakeawayDetailScreen> createState() =>
      _TakeawayDetailScreenState();
}

class _TakeawayDetailScreenState extends ConsumerState<TakeawayDetailScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final visits = ref.watch(takeawayVisitsProvider);
    final visit = visits
        .where((v) => v.id == widget.visitId)
        .cast<TakeawayVisit?>()
        .firstOrNull;
    final tickets = ref.watch(ticketsProvider)[widget.visitId] ?? const [];
    final live = tickets
        .where(
          (t) =>
              t.status != TicketStatus.served &&
              t.status != TicketStatus.voided,
        )
        .toList();
    final active = tickets
        .where((t) => t.status != TicketStatus.voided)
        .toList();
    final total = active.fold<int>(0, (s, t) => s + t.price * t.qty);
    final label = visit?.label ?? 'Bawa pulang';
    final guest = visit?.guestName;
    final handedOver = visit?.handedOver ?? false;
    // Can hand over once there are lines and none are still in flight.
    final canHandover =
        !handedOver && tickets.isNotEmpty && live.isEmpty && !_busy;

    return Scaffold(
      backgroundColor: sc.bg0,
      body: Column(
        children: [
          SatAppBar(
            onBack: () => safePop(context, fallback: '/tables'),
            title: label,
            crumbs: ['Bawa pulang', ?guest],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
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
                  [
                    if (guest != null && guest.isNotEmpty) guest.toUpperCase(),
                    '${active.length} ITEM',
                    if (handedOver) 'SUDAH DISERAHKAN',
                  ].join(' · '),
                  style: SatType.monoS(color: sc.textLo),
                ),
              ],
            ),
          ),
          Expanded(
            child: tickets.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada item.',
                      style: SatType.sans(size: 13, color: sc.textLo),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      // Same line card as the table detail (modifiers, note,
                      // allergen badges, orderer, serve, tap→void/comp). No lock
                      // gating — takeaway holds no table lock. See ADR-0026.
                      for (final t in tickets)
                        OrderLineCard(
                          ticket: t,
                          onTap: () => _openAction(t, label),
                          onMarkServed: _markServed,
                          readOnly: handedOver,
                        ),
                    ],
                  ),
          ),
          _Footer(
            sc: sc,
            total: total,
            handedOver: handedOver,
            canHandover: canHandover,
            busy: _busy,
            onAddItems: () => context.push('/takeaway/${widget.visitId}/menu'),
            onPrint: _busy ? null : _printBill,
            onHandover: canHandover ? _handover : null,
          ),
        ],
      ),
    );
  }

  Future<void> _markServed(String ticketId) async {
    try {
      await ref
          .read(advanceTicketStatusUseCaseProvider)
          .call(widget.visitId, ticketId, TicketStatus.served);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal sajikan: $e')));
    }
  }

  void _openAction(Ticket t, String label) {
    showLineItemActionSheet(
      context: context,
      tableId: widget.visitId,
      ticket: t,
      displayName: label,
    );
  }

  Future<void> _printBill() async {
    try {
      final bill = await ref
          .read(settlementProvider.notifier)
          .fetchBill(widget.visitId);
      if (!mounted) return;
      await printBillStruk(context: context, ref: ref, bill: bill);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat tagihan: $e')));
      }
    }
  }

  Future<void> _handover() async {
    setState(() => _busy = true);
    try {
      await ref.read(settlementProvider.notifier).handover(widget.visitId);
      if (mounted) context.go('/tables');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      final msg = switch (e.code) {
        'tickets_not_terminal' =>
          'Masih ada item yang dimasak — tunggu siap dulu.',
        'no_tickets' => 'Belum ada item untuk diserahkan.',
        _ => 'Gagal menyerahkan: ${e.code ?? e.statusCode}',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyerahkan: $e')));
    }
  }
}

class _Footer extends StatelessWidget {
  final SatColors sc;
  final int total;
  final bool handedOver;
  final bool canHandover;
  final bool busy;
  final VoidCallback onAddItems;
  final VoidCallback? onPrint;
  final VoidCallback? onHandover;
  const _Footer({
    required this.sc,
    required this.total,
    required this.handedOver,
    required this.canHandover,
    required this.busy,
    required this.onAddItems,
    required this.onPrint,
    required this.onHandover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: SatBox.d(
        color: sc.bg1,
        border: Border(top: SatB.side(color: sc.border0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Total', style: SatType.sans(size: 13, color: sc.textMd)),
              const Spacer(),
              Text(formatIDR(total), style: SatType.monoM(color: sc.textHi)),
            ],
          ),
          const SizedBox(height: Sp.s3),
          Row(
            children: [
              if (!handedOver)
                Expanded(
                  child: SatButton.outline(
                    label: 'Tambah item',
                    icon: Icons.add_rounded,
                    onTap: busy ? null : onAddItems,
                  ),
                ),
              if (!handedOver) const SizedBox(width: Sp.s2h),
              Expanded(
                child: SatButton.outline(
                  label: 'Tagihan',
                  icon: Icons.receipt_long_rounded,
                  onTap: onPrint,
                ),
              ),
            ],
          ),
          if (!handedOver) ...[
            const SizedBox(height: Sp.s2h),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: SatButton.primary(
                label: 'Serahkan',
                icon: Icons.shopping_bag_rounded,
                busy: busy,
                size: SatButtonSize.lg,
                onTap: onHandover,
              ),
            ),
            if (onHandover == null && !busy)
              Padding(
                padding: const EdgeInsets.only(top: Sp.s2),
                child: Text(
                  'Bisa diserahkan setelah semua item siap/disajikan.',
                  textAlign: TextAlign.center,
                  style: SatType.monoS(color: sc.textLo),
                ),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: Sp.s1),
              child: Text(
                'Sudah diserahkan ke tamu.',
                style: SatType.sans(size: 12, color: sc.textMd),
              ),
            ),
        ],
      ),
    );
  }
}
