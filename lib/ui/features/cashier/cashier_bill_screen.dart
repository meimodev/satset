import 'dart:convert';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_icon_button.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/ui/core/design/skin.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/cashier/discount_sheet.dart';
import 'package:satset/ui/features/printing/printer_picker.dart';
import 'package:satset/ui/core/widgets/anim.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

const _methodLabels = {
  'tunai': 'Tunai',
  'kartu': 'Kartu',
  'qris': 'QRIS',
  'transfer': 'Transfer',
  'lainnya': 'Lainnya',
};

/// Settle one [[Visit]]'s [[Bill]]: assign lines to receipts (itemized), split
/// evenly, record payments/refunds, reopen, and — bill close (Tutup tagihan,
/// Lunas or tak tertagih). Freeing the floor table is the WAITER's separate
/// act, not here. See ADR-0024 and CONTEXT.md (Bill close / Settlement).
class CashierBillScreen extends ConsumerWidget {
  final String visitId;
  final String tableId;
  const CashierBillScreen({
    super.key,
    required this.visitId,
    required this.tableId,
  });

  SettlementRepository _repo(WidgetRef ref) =>
      ref.read(settlementProvider.notifier);

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<Bill> Function() op,
  ) async {
    try {
      await op();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_msg(e))));
      }
    } finally {
      ref.invalidate(billDetailProvider(visitId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final billAsync = ref.watch(billDetailProvider(visitId));

    return Scaffold(
      backgroundColor: sc.bg0,
      appBar: AppBar(
        backgroundColor: sc.bg1,
        title: billAsync.maybeWhen(
          data: (b) => Text(
            'Tagihan · Meja ${b.tableLabel ?? ''}'.trim(),
            style: SatType.labelL(color: sc.textHi),
          ),
          orElse: () =>
              Text('Tagihan', style: SatType.labelL(color: sc.textHi)),
        ),
        actions: [
          IconButton(
            tooltip: 'Riwayat tagihan meja',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PastBillsScreen(
                  tableId: tableId,
                  tableLabel: billAsync.asData?.value.tableLabel,
                ),
              ),
            ),
          ),
        ],
      ),
      body: billAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Gagal memuat tagihan.',
            style: SatType.bodyM(color: sc.textLo),
          ),
        ),
        data: (bill) => _BillBody(
          bill: bill,
          run: (op) => _run(context, ref, op),
          repo: _repo(ref),
          canRefund: ref.watch(authStateProvider).has(Capability.refund),
          onCloseBill: () => _closeBill(context, ref, bill),
          printDoc: (r) => printBillStruk(
            context: context,
            ref: ref,
            bill: bill,
            receipt: r,
          ),
        ),
      ),
    );
  }

  Future<void> _closeBill(
    BuildContext context,
    WidgetRef ref,
    Bill bill,
  ) async {
    final writeOff = !bill.fullySettled;
    String? reason;
    if (writeOff) {
      reason = await _askWriteOffReason(context, bill.outstanding);
      if (reason == null) return; // cancelled
    } else {
      final ok = await showSatDialog<bool>(
        context,
        builder: (c) => AlertDialog(
          title: const Text('Tutup tagihan'),
          content: Text(
            'Kunci tagihan Meja ${bill.tableLabel ?? ''} sebagai lunas? '
            'Tindakan ini mengakhiri tagihan.',
          ),
          actions: [
            SatButton.ghost(
              label: AppStrings.cancel,
              onTap: () => Navigator.pop(c, false),
            ),
            SatButton.primary(
              label: 'Tutup tagihan',
              onTap: () => Navigator.pop(c, true),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await ref
          .read(settlementProvider.notifier)
          .closeBill(bill.visitId, writeOff: writeOff, reason: reason);
      if (context.mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_msg(e))));
      }
    }
  }

  Future<String?> _askWriteOffReason(BuildContext context, int outstanding) {
    final ctrl = TextEditingController();
    return showSatDialog<String>(
      context,
      builder: (c) => AlertDialog(
        title: const Text('Tutup tagihan — tak tertagih'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sisa ${formatIDR(outstanding)} akan dicatat sebagai '
              'kerugian (tak tertagih). Perlu persetujuan manajer.',
            ),
            const SizedBox(height: Sp.s3),
            SatField.text(
              controller: ctrl,
              label: 'Alasan (wajib)',
              hint: 'mis. tamu pergi tanpa bayar',
              autofocus: true,
            ),
          ],
        ),
        actions: [
          SatButton.ghost(
            label: AppStrings.cancel,
            onTap: () => Navigator.pop(c),
          ),
          SatButton.danger(
            label: 'Catat kerugian',
            onTap: () {
              final t = ctrl.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(c, t);
            },
          ),
        ],
      ),
    );
  }

  static String _msg(ApiException e) => switch (e.code) {
    'over_assign' => 'Unit melebihi yang tersedia.',
    'receipt_paid' => 'Buka ulang struk sebelum mengubahnya.',
    'not_settled' => 'Tagihan belum lunas.',
    'bill_locked' => 'Tagihan sudah ditutup — buka ulang dulu.',
    'forbidden' => 'Perlu persetujuan manajer (tak tertagih).',
    'reason_required' => 'Alasan tak tertagih wajib diisi.',
    'no_lines' => 'Meja tidak punya pesanan.',
    _ => 'Operasi gagal (${e.code ?? e.statusCode}).',
  };
}

class _BillBody extends StatelessWidget {
  final Bill bill;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;
  final bool canRefund;
  final VoidCallback onCloseBill;
  final Future<void> Function(BillReceipt?) printDoc;

  const _BillBody({
    required this.bill,
    required this.run,
    required this.repo,
    required this.canRefund,
    required this.onCloseBill,
    required this.printDoc,
  });

  @override
  Widget build(BuildContext context) {
    // Page-load choreography: each section reveals in sequence top-to-bottom.
    var i = 0;
    Widget rv(Widget child) => Reveal(index: i++, child: child);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              rv(_TotalsCard(bill)),
              const SizedBox(height: Sp.s2),
              rv(
                _TopActions(
                  bill: bill,
                  canRefund: canRefund,
                  printDoc: printDoc,
                  onWriteOff: onCloseBill,
                ),
              ),
              if (bill.detached) ...[
                const SizedBox(height: Sp.s2h),
                rv(const _DetachedBanner()),
              ],
              const SizedBox(height: Sp.s3h),
              if (bill.receipts.isEmpty)
                rv(_ModeChooser(bill: bill, run: run, repo: repo)),
              if (bill.mode == 'itemized' &&
                  bill.receipts.isNotEmpty &&
                  !bill.fullyAssigned) ...[
                rv(_UnassignedBanner(bill: bill)),
                const SizedBox(height: Sp.s2h),
              ],
              rv(_LinesSection(bill: bill, run: run, repo: repo)),
              const SizedBox(height: Sp.s3h),
              ...bill.receipts.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: Sp.s2h),
                  child: rv(
                    _ReceiptCard(
                      bill: bill,
                      receipt: r,
                      run: run,
                      repo: repo,
                      canRefund: canRefund,
                      printDoc: printDoc,
                    ),
                  ),
                ),
              ),
              if (bill.receipts.isNotEmpty)
                rv(_AddReceiptButton(bill: bill, run: run, repo: repo)),
              if (bill.receipts.isNotEmpty && bill.paidAmount == 0)
                rv(_ResetMethodButton(bill: bill, run: run, repo: repo)),
            ],
          ),
        ),
        // Bottom CTA only for the happy path: a fully-settled bill ready to
        // lock as Lunas. The tak-tertagih write-off moved up to _TopActions.
        if (bill.fullySettled) _CloseBar(bill: bill, onClose: onCloseBill),
      ],
    );
  }
}

/// Prominent amber count of units not yet assigned to any receipt, shown only
/// in an itemized split that isn't fully assigned. Blocks nothing — it just
/// answers "what's left to place" at a glance (the lines list tints the same
/// units amber). Disappears once `bill.fullyAssigned`.
class _UnassignedBanner extends StatelessWidget {
  final Bill bill;
  const _UnassignedBanner({required this.bill});
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final n = bill.lines.fold<int>(0, (s, l) => s + l.unassignedUnits);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2h),
      decoration: SatBox.d(
        color: sc.warn.withValues(alpha: 0.12),
        borderRadius: SatR.a(10),
        border: SatB.all(color: sc.warn.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: sc.warn),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: Text(
              '$n item belum diatur ke struk',
              style: SatType.labelM(color: sc.warn),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final Bill bill;
  const _TotalsCard(this.bill);
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    Widget row(String k, int v, {bool strong = false, Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.s1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: (strong
                ? SatType.labelM(color: strong ? sc.textHi : sc.textLo)
                : SatType.bodyM(color: strong ? sc.textHi : sc.textLo)),
          ),
          AnimatedDefaultTextStyle(
            duration: satMotion(context, 260),
            curve: satEaseOut,
            // Both lines are monoM. The closed set has no weight step inside
            // the money ramp, so the grand total is marked by ink, not weight.
            style: SatType.monoM(color: color ?? sc.textHi),
            child: Text(formatIDR(v)),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(Sp.s3h),
      decoration: SatBox.d(color: sc.bg1, borderRadius: SatR.a(14)),
      child: Column(
        children: [
          row('Subtotal', bill.subtotal),
          // The Diskon row's position follows the actual pipeline (ADR-0038),
          // matching the printed slip: above Layanan when the discount reduced
          // the base service and tax were computed on, below Pajak otherwise.
          if (bill.discountAmount > 0 && bill.taxAfterDiscount)
            row('Diskon', -bill.discountAmount, color: sc.warn),
          if (bill.serviceAmount > 0) row('Layanan', bill.serviceAmount),
          if (bill.taxAmount > 0) row('Pajak', bill.taxAmount),
          if (bill.discountAmount > 0 && !bill.taxAfterDiscount)
            row('Diskon', -bill.discountAmount, color: sc.warn),
          Divider(color: sc.border0, height: 16),
          row('Total', bill.total, strong: true),
          row('Terbayar', bill.paidAmount, color: sc.success),
          row(
            'Sisa',
            bill.outstanding,
            color: bill.outstanding > 0 ? sc.warn : sc.success,
          ),
        ],
      ),
    );
  }
}

class _ModeChooser extends StatelessWidget {
  final Bill bill;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;
  const _ModeChooser({
    required this.bill,
    required this.run,
    required this.repo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s3h),
      child: Row(
        children: [
          Expanded(
            child: _BigBtn(
              icon: Icons.payments_outlined,
              label: 'Bayar penuh',
              onTap: () async {
                await run(
                  () => repo.createReceipt(
                    bill.visitId,
                    mode: 'itemized',
                    assignAll: true,
                    label: 'Tagihan',
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: _BigBtn(
              icon: Icons.call_split_rounded,
              label: 'Split per item',
              onTap: () => run(
                () => repo.createReceipt(
                  bill.visitId,
                  mode: 'itemized',
                  label: 'Tamu 1',
                ),
              ),
            ),
          ),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: _BigBtn(
              icon: Icons.safety_divider_rounded,
              label: 'Split rata',
              onTap: () async {
                // Switching to an even split rebuilds every receipt, taking
                // line discounts with them — an even receipt owns no lines to
                // carry one (ADR-0037). Warn before that is destroyed.
                final lineDiscounts = [
                  for (final rc in bill.receipts)
                    ...rc.discounts.where((d) => d.isLine),
                ];
                if (lineDiscounts.isNotEmpty) {
                  if (!await _confirm(
                    context,
                    title: 'Diskon per item akan hilang',
                    message:
                        'Split rata membagi total tanpa kepemilikan item, '
                        'jadi ${lineDiscounts.length} diskon per item akan '
                        'dihapus. Diskon seluruh pesanan bisa dipasang lagi '
                        'setelahnya.',
                    confirmLabel: 'Ya, lanjutkan',
                  )) {
                    return;
                  }
                }
                if (!context.mounted) return;
                final n = await _askInt(
                  context,
                  'Bagi rata berapa orang?',
                  initial: bill.pax > 1 ? bill.pax : 2,
                );
                if (n != null) {
                  await run(() => repo.splitEven(bill.visitId, n));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LinesSection extends StatelessWidget {
  final Bill bill;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;
  const _LinesSection({
    required this.bill,
    required this.run,
    required this.repo,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final assignable = bill.mode == 'itemized' && bill.receipts.isNotEmpty;

    // Group lines by their `(table, sentAt)` batch — same key the KDS uses
    // (HH:mm) — oldest-first. Headers only appear with 2+ batches; a single
    // send reads as a plain list. See CONTEXT.md › Batch.
    final sorted = [...bill.lines]
      ..sort((a, b) {
        final ax = a.sentAt, bx = b.sentAt;
        if (ax == null && bx == null) return 0;
        if (ax == null) return 1;
        if (bx == null) return -1;
        return ax.compareTo(bx);
      });
    final groups = <String, List<BillLine>>{};
    for (final l in sorted) {
      groups
          .putIfAbsent(l.sentAt != null ? _hhmm(l.sentAt!) : '—', () => [])
          .add(l);
    }
    final multiBatch = groups.length > 1;

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Item pesanan', style: SatType.labelS(color: sc.textLo)),
            if (!bill.fullyAssigned && assignable)
              Text('Belum semua diatur', style: SatType.bodyS(color: sc.warn)),
          ],
        ),
      ),
    ];
    var batchNo = 0;
    groups.forEach((key, lines) {
      batchNo++;
      if (multiBatch) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
            child: Text(
              'PESANAN $batchNo · $key',
              style: SatType.labelS(color: sc.textLo),
            ),
          ),
        );
      }
      for (final l in lines) {
        children.add(_lineTile(context, l, assignable));
      }
    });

    return Container(
      decoration: SatBox.d(color: sc.bg1, borderRadius: SatR.a(14)),
      padding: const EdgeInsets.symmetric(vertical: Sp.s1h),
      child: Column(children: children),
    );
  }

  Widget _lineTile(BuildContext context, BillLine l, bool assignable) {
    final sc = context.sat;
    final assigned = l.assignedUnits;
    final hasNote = l.note?.trim().isNotEmpty == true;
    final pending = assignable && l.unassignedUnits > 0;
    return ListTile(
      dense: true,
      tileColor: pending ? sc.warn.withValues(alpha: 0.08) : null,
      shape: pending ? RoundedRectangleBorder(borderRadius: SatR.a(8)) : null,
      title: Text(
        '${l.name}${l.variantName.isNotEmpty ? ' · ${l.variantName}' : ''}',
        style: SatType.bodyM(color: sc.textHi),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l.qty} × ${formatIDR(l.unitPrice)}'
            '${assignable ? '  ·  $assigned/${l.qty} diatur' : ''}',
            style: (pending
                ? SatType.labelS(color: pending ? sc.warn : sc.textLo)
                : SatType.bodyS(color: pending ? sc.warn : sc.textLo)),
          ),
          for (final m in l.modifiers)
            Text(
              '${m.display}'
              '${m.priceDelta != 0 ? ' (${m.priceDelta > 0 ? '+' : '−'}${groupRupiah(m.priceDelta.abs())})' : ''}',
              style: SatType.bodyS(color: sc.textLo),
            ),
          if (hasNote)
            Text(
              'Catatan: ${l.note!.trim()}',
              style: SatType.bodyS(color: sc.textLo),
            ),
        ],
      ),
      trailing: assignable
          ? SatButton.ghost(
              label: assigned >= l.qty ? 'Ubah' : 'Atur',
              onTap: () => _assignSheet(context, l),
            )
          : Text(
              formatIDR(l.lineTotal),
              style: SatType.monoM(color: sc.textHi),
            ),
    );
  }

  Future<void> _assignSheet(BuildContext context, BillLine line) async {
    final sc = context.sat;
    await showSatSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
          left: Sp.s4,
          right: Sp.s4,
          top: Sp.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Atur "${line.name}"',
              style: SatType.labelL(color: sc.textHi),
            ),
            const SizedBox(height: Sp.s1),
            Text(
              '${line.qty} unit total · ${line.unassignedUnits} belum diatur',
              style: SatType.bodyS(color: sc.textLo),
            ),
            const SizedBox(height: Sp.s3),
            ...bill.receipts.where((r) => r.mode != 'even').map((r) {
              final current = r.lines
                  .where((x) => x.ticketId == line.ticketId)
                  .fold<int>(0, (a, b) => a + b.qtyUnits);
              final maxForThis =
                  line.qty -
                  (line.assignedUnits - current); // free + already-here
              return _AssignRow(
                label: r.label.isEmpty ? 'Struk' : r.label,
                value: current,
                max: maxForThis,
                onChanged: (v) async {
                  Navigator.of(ctx).pop();
                  await run(() => repo.assignLine(r.id, line.ticketId, v));
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AssignRow extends StatefulWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  const _AssignRow({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });
  @override
  State<_AssignRow> createState() => _AssignRowState();
}

class _AssignRowState extends State<_AssignRow> {
  late int v = widget.value;
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.s1),
      child: Row(
        children: [
          Expanded(
            child: Text(widget.label, style: SatType.bodyM(color: sc.textHi)),
          ),
          IconButton(
            tooltip: AppStrings.a11yDecrease,
            icon: const Icon(Icons.remove_circle_outline, size: 22),
            onPressed: v > 0 ? () => setState(() => v--) : null,
          ),
          AnimatedSwitcher(
            duration: satMotion(context, 150),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
            child: Text(
              '$v',
              key: ValueKey(v),
              style: SatType.monoM(color: sc.textHi),
            ),
          ),
          IconButton(
            tooltip: AppStrings.a11yIncrease,
            icon: const Icon(Icons.add_circle_outline, size: 22),
            onPressed: v < widget.max ? () => setState(() => v++) : null,
          ),
          const SizedBox(width: Sp.s1),
          SatButton.primary(
            label: AppStrings.save,
            onTap: () => widget.onChanged(v),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends ConsumerWidget {
  final Bill bill;
  final BillReceipt receipt;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;
  final bool canRefund;
  final Future<void> Function(BillReceipt?) printDoc;
  const _ReceiptCard({
    required this.bill,
    required this.receipt,
    required this.run,
    required this.repo,
    required this.canRefund,
    required this.printDoc,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final r = receipt;
    final paid = r.isPaid;
    // Show each receipt's owned items so the cashier sees *who has what* at a
    // glance. Names joined from bill.lines by ticketId (BillReceiptLine carries
    // only ticketId + qtyUnits). Suppressed only for the degenerate whole-bill
    // case — a lone receipt that owns every line ("Bayar penuh") — since the
    // lines section above already itemizes it; any genuine split (incl. one
    // guest filled so far) shows its items. No per-item rupiah: modifiers would
    // make a naive qty×unitPrice lie; the server-computed Total is the truth.
    final lineByTicket = {for (final b in bill.lines) b.ticketId: b};
    final isWholeBill = bill.receipts.length == 1 && bill.fullyAssigned;
    final showItems = r.lines.isNotEmpty && !isWholeBill;
    return AnimatedContainer(
      duration: satMotion(context, 280),
      curve: satEaseOut,
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: SatR.a(14),
        border: SatB.all(color: paid ? sc.success : sc.border0),
      ),
      padding: const EdgeInsets.all(Sp.s3h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.label.isEmpty ? 'Struk' : r.label,
                  style: SatType.labelM(color: sc.textHi),
                ),
              ),
              AnimatedContainer(
                duration: satMotion(context, 280),
                curve: satEaseOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.s2,
                  vertical: Sp.sHair,
                ),
                decoration: SatBox.d(
                  color: (paid ? sc.success : sc.warn).withValues(alpha: 0.15),
                  borderRadius: SatR.a(6),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: satMotion(context, 280),
                  curve: satEaseOut,
                  style: SatType.labelS(color: paid ? sc.success : sc.warn),
                  child: Text(paid ? 'Lunas' : 'Belum bayar'),
                ),
              ),
            ],
          ),
          if (showItems) ...[
            const SizedBox(height: Sp.s2),
            for (final rl in r.lines)
              _ReceiptItemRow(
                receipt: r,
                line: lineByTicket[rl.ticketId],
                ticketId: rl.ticketId,
                qtyUnits: rl.qtyUnits,
                // Line discounts are itemized-only — an even receipt owns no
                // lines to attach one to (ADR-0037) — and are frozen once paid.
                canDiscount: !paid && r.mode != 'even',
                run: run,
                repo: repo,
              ),
            Padding(
              padding: const EdgeInsets.only(top: Sp.s1h),
              child: Divider(height: 1, color: sc.border0),
            ),
          ],
          const SizedBox(height: Sp.s2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: SatType.bodyM(color: sc.textLo)),
              Text(formatIDR(r.total), style: SatType.monoM(color: sc.textHi)),
            ],
          ),
          if (r.paidNet != 0)
            Padding(
              padding: const EdgeInsets.only(top: Sp.sHair),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Terbayar', style: SatType.bodyS(color: sc.textLo)),
                  Text(
                    formatIDR(r.paidNet),
                    style: SatType.monoM(color: sc.success),
                  ),
                ],
              ),
            ),
          for (final p in r.payments)
            Padding(
              padding: const EdgeInsets.only(top: Sp.s1),
              child: Row(
                children: [
                  Icon(
                    p.isRefund ? Icons.undo_rounded : Icons.check_circle,
                    size: 13,
                    color: p.isRefund ? sc.warn : sc.success,
                  ),
                  const SizedBox(width: Sp.s1h),
                  Text(
                    _methodLabels[p.method] ?? p.method,
                    style: SatType.bodyS(color: sc.textLo),
                  ),
                  if (p.hasPhoto) ...[
                    const SizedBox(width: Sp.s1h),
                    PaymentProofThumb(
                      paymentId: p.id,
                      history: false,
                      size: 22,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    formatIDR(p.amount),
                    style: SatType.monoS(
                      color: p.isRefund ? sc.warn : sc.textLo,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Sp.s2h),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (!paid && r.total > 0)
                SatButton.primary(
                  size: SatButtonSize.sm,
                  label: 'Bayar',
                  onTap: () => _paySheet(context, r),
                ),
              if (paid)
                SatButton.neutral(
                  size: SatButtonSize.sm,
                  label: 'Buka ulang',
                  onTap: () async {
                    if (await _confirm(
                      context,
                      title: 'Buka ulang struk',
                      message:
                          'Batalkan status lunas "${r.label.isEmpty ? 'Struk' : r.label}" '
                          'agar bisa diubah? Pembayaran tercatat tetap ada.',
                      confirmLabel: 'Ya, buka ulang',
                    )) {
                      await run(() => repo.reopen(r.id));
                    }
                  },
                ),
              if (canRefund && r.paidNet > 0)
                SatButton.neutral(
                  size: SatButtonSize.sm,
                  label: 'Refund',
                  onTap: () => _refundSheet(context, r),
                ),
              // Discounts are frozen once paid — reopen to correct a mistaken
              // settlement (ADR-0037), so the button hides on a paid receipt.
              if (!paid && r.subtotal > 0 && r.orderDiscount == null)
                SatButton.neutral(
                  size: SatButtonSize.sm,
                  label: 'Diskon',
                  onTap: () async {
                    final picked = await showDiscountSheet(
                      context,
                      ref,
                      DiscountTarget(
                        receipt: r,
                        ticketId: null,
                        base: r.subtotal,
                        title: r.label.isEmpty ? 'Struk' : r.label,
                      ),
                    );
                    if (picked == null) return;
                    await run(
                      () => repo.applyDiscount(
                        r.id,
                        presetId: picked.presetId,
                        approverPin: picked.approverPin,
                      ),
                    );
                  },
                ),
              if (!paid && r.orderDiscount != null)
                SatButton.neutral(
                  size: SatButtonSize.sm,
                  label: 'Hapus diskon',
                  onTap: () async {
                    final d = r.orderDiscount!;
                    if (await _confirm(
                      context,
                      title: 'Hapus diskon',
                      message:
                          'Hapus "${d.label}" (${formatIDR(d.amount)}) '
                          'dari struk ini?',
                      confirmLabel: 'Ya, hapus',
                    )) {
                      await run(() => repo.removeDiscount(r.id, d.id));
                    }
                  },
                ),
              if (r.total > 0)
                SatButton.neutral(
                  size: SatButtonSize.sm,
                  label: r.payments.isEmpty ? 'Cetak tagihan' : 'Cetak struk',
                  onTap: () => printDoc(r),
                ),
              if (!paid && r.mode != 'even')
                SatButton.neutral(
                  size: SatButtonSize.sm,
                  label: 'Hapus',
                  onTap: () async {
                    if (await _confirm(
                      context,
                      title: 'Hapus struk',
                      message:
                          'Hapus "${r.label.isEmpty ? 'Struk' : r.label}"? '
                          'Item yang sudah diatur ke struk ini akan kembali belum diatur.',
                      confirmLabel: 'Ya, hapus',
                      destructive: true,
                    )) {
                      await run(() => repo.deleteReceipt(r.id));
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _paySheet(BuildContext context, BillReceipt r) =>
      _moneySheet(context, r, refund: false);

  Future<void> _refundSheet(BuildContext context, BillReceipt r) =>
      _moneySheet(context, r, refund: true);

  Future<void> _moneySheet(
    BuildContext context,
    BillReceipt r, {
    required bool refund,
  }) async {
    final sc = context.sat;
    final amountCtl = TextEditingController(
      text: groupRupiah(refund ? r.paidNet : r.outstanding),
    );
    final tenderedCtl = TextEditingController();
    var method = 'tunai';
    Uint8List? photoBytes; // proof shot for a non-cash payment (ADR-0025)
    await showSatSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          int parse(TextEditingController c) =>
              int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final amount = parse(amountCtl);
          final tendered = parse(tenderedCtl);
          final change = tendered - amount;
          // Non-cash payments (not refunds) require a live proof photo.
          final needsPhoto = !refund && method != 'tunai';
          final photoMissing = needsPhoto && photoBytes == null;
          Future<void> shootPhoto() async {
            try {
              final x = await ImagePicker().pickImage(
                source: ImageSource.camera,
                maxWidth: 1080,
                maxHeight: 1080,
                imageQuality: 80,
              );
              if (x == null) return;
              final bytes = await x.readAsBytes();
              setState(() => photoBytes = bytes);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Gagal mengambil foto: $e')),
                );
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: Sp.s4,
              right: Sp.s4,
              top: Sp.s4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  refund ? 'Refund ${r.label}' : 'Bayar ${r.label}',
                  style: SatType.labelL(color: sc.textHi),
                ),
                const SizedBox(height: Sp.s3),
                Wrap(
                  spacing: 8,
                  children: _methodLabels.entries
                      .map(
                        (e) => SatChip.select(
                          label: e.value,
                          selected: method == e.key,
                          onTap: () => setState(() => method = e.key),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: Sp.s3),
                SatField.money(
                  controller: amountCtl,
                  label: 'Jumlah',
                  hint: '',
                  onChanged: (_) => setState(() {}),
                ),
                if (!refund && method == 'tunai') ...[
                  const SizedBox(height: Sp.s2),
                  SatField.money(
                    controller: tenderedCtl,
                    label: 'Uang diterima',
                    hint: '',
                    onChanged: (_) => setState(() {}),
                  ),
                  AnimatedSwitcher(
                    duration: satMotion(context, 200),
                    switchInCurve: satEaseOut,
                    switchOutCurve: satEaseOut,
                    transitionBuilder: (c, a) => FadeTransition(
                      opacity: a,
                      child: SizeTransition(
                        sizeFactor: a,
                        axisAlignment: -1,
                        child: c,
                      ),
                    ),
                    child: tendered > 0
                        ? Padding(
                            key: ValueKey(change >= 0),
                            padding: const EdgeInsets.only(top: Sp.s2),
                            child: Text(
                              change >= 0
                                  ? 'Kembalian ${formatIDR(change)}'
                                  : 'Kurang ${formatIDR(-change)}',
                              style: SatType.labelM(
                                color: change >= 0 ? sc.success : sc.warn,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
                if (needsPhoto) ...[
                  const SizedBox(height: Sp.s3),
                  Text(
                    'Foto bukti (wajib)',
                    style: SatType.labelS(color: sc.textLo),
                  ),
                  const SizedBox(height: Sp.s2),
                  Row(
                    children: [
                      if (photoBytes != null)
                        ClipRRect(
                          borderRadius: SatR.a(8),
                          child: Image.memory(
                            photoBytes!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (photoBytes != null) const SizedBox(width: Sp.s3),
                      Expanded(
                        child: SatButton.outline(
                          label: photoBytes == null
                              ? 'Ambil foto'
                              : 'Ambil ulang',
                          icon: Icons.photo_camera_rounded,
                          onTap: shootPhoto,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: Sp.s4),
                SizedBox(
                  width: double.infinity,
                  child: SatButton.primary(
                    label: refund ? 'Catat refund' : 'Catat pembayaran',
                    onTap: amount <= 0 || photoMissing
                        ? null
                        : () async {
                            Navigator.of(ctx).pop();
                            if (refund) {
                              await run(
                                () => repo.refund(
                                  r.id,
                                  method: method,
                                  amount: amount,
                                ),
                              );
                            } else {
                              await run(
                                () => repo.recordPayment(
                                  r.id,
                                  method: method,
                                  amount: amount,
                                  tendered: method == 'tunai' && tendered > 0
                                      ? tendered
                                      : null,
                                  photoBase64: needsPhoto && photoBytes != null
                                      ? base64Encode(photoBytes!)
                                      : null,
                                ),
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One owned item inside a receipt card, with its line [[Diskon (discount)]]
/// shown beneath — the same "indented under the item" grammar the printed slip
/// uses, so screen and paper agree.
class _ReceiptItemRow extends ConsumerWidget {
  final BillReceipt receipt;
  final BillLine? line;
  final String ticketId;
  final int qtyUnits;
  final bool canDiscount;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;

  const _ReceiptItemRow({
    required this.receipt,
    required this.line,
    required this.ticketId,
    required this.qtyUnits,
    required this.canDiscount,
    required this.run,
    required this.repo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l = line;
    final name = l?.name ?? 'Item';
    final variant = (l?.variantName.isNotEmpty ?? false)
        ? ' · ${l!.variantName}'
        : '';
    final existing = receipt.lineDiscount(ticketId);
    // The units THIS receipt owns — a qty:3 line split 2/1 discounts only its
    // own share. Preview only; the server re-resolves authoritatively.
    final base = (l?.unitPrice ?? 0) * qtyUnits;

    Future<void> onTap() async {
      if (!canDiscount) return;
      if (existing != null) {
        if (await _confirm(
          context,
          title: 'Hapus diskon item',
          message:
              'Hapus "${existing.label}" '
              '(${formatIDR(existing.amount)}) dari $name?',
          confirmLabel: 'Ya, hapus',
        )) {
          await run(() => repo.removeDiscount(receipt.id, existing.id));
        }
        return;
      }
      final picked = await showDiscountSheet(
        context,
        ref,
        DiscountTarget(
          receipt: receipt,
          ticketId: ticketId,
          base: base,
          title: name,
        ),
      );
      if (picked == null) return;
      await run(
        () => repo.applyDiscount(
          receipt.id,
          presetId: picked.presetId,
          ticketId: ticketId,
          approverPin: picked.approverPin,
        ),
      );
    }

    return InkWell(
      onTap: canDiscount ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.only(top: Sp.sHair),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$qtyUnits× $name$variant',
                    style: SatType.bodyS(color: sc.textHi),
                  ),
                ),
                if (canDiscount && existing == null)
                  Icon(Icons.sell_outlined, size: 14, color: sc.textLo),
              ],
            ),
            if (existing != null)
              Padding(
                padding: const EdgeInsets.only(left: Sp.s3, top: Sp.sHair),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        existing.label,
                        style: SatType.bodyS(color: sc.warn),
                      ),
                    ),
                    Text(
                      '-${formatIDR(existing.amount)}',
                      style: SatType.monoS(color: sc.warn),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddReceiptButton extends StatelessWidget {
  final Bill bill;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;
  const _AddReceiptButton({
    required this.bill,
    required this.run,
    required this.repo,
  });
  @override
  Widget build(BuildContext context) {
    if (bill.mode == 'even') return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: SatButton.ghost(
        label: 'Tambah struk',
        icon: Icons.add_rounded,
        onTap: () => run(
          () => repo.createReceipt(
            bill.visitId,
            mode: 'itemized',
            label: 'Tamu ${bill.receipts.length + 1}',
          ),
        ),
      ),
    );
  }
}

/// Undo the billing-method choice (Bayar penuh / Split per item / Split rata)
/// while **no payment has been recorded** — wipes every receipt so the bill
/// drops back to the [_ModeChooser]. Confirm-guarded; hidden the instant any
/// money lands (then a paid receipt must be reopened first). See ADR-0023.
class _ResetMethodButton extends StatelessWidget {
  final Bill bill;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;
  const _ResetMethodButton({
    required this.bill,
    required this.run,
    required this.repo,
  });
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SatButton.ghost(
        label: 'Ganti metode pembayaran',
        icon: Icons.refresh_rounded,
        onTap: () async {
          if (await _confirm(
            context,
            title: 'Ganti metode pembayaran',
            message:
                'Hapus semua struk dan pilih ulang cara penagihan? '
                'Belum ada pembayaran yang tercatat, jadi aman diulang.',
            confirmLabel: 'Ya, ganti',
          )) {
            await run(() => repo.resetBilling(bill));
          }
        },
      ),
    );
  }
}

/// Bill-close bar — the cashier's happy-path **Lunas** act (lock a fully-settled
/// bill). Only mounted when `bill.fullySettled`; the tak-tertagih write-off for
/// an unsettled bill lives in [_TopActions]. NOT table-freeing. See ADR-0024.
class _CloseBar extends StatelessWidget {
  final Bill bill;
  final VoidCallback onClose;
  const _CloseBar({required this.bill, required this.onClose});
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: SatBox.d(
        color: sc.bg1,
        border: Border(top: SatB.side(color: sc.border0)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: SatButton.primary(
          label: 'Tutup tagihan',
          icon: Icons.check_circle_outline,
          onTap: onClose,
        ),
      ),
    );
  }
}

/// Top action row under the totals card: the whole-bill print affordance
/// (Tagihan pre-payment / Struk pembayaran once any payment lands) inline with
/// an icon-only **tak tertagih** write-off. The write-off is destructive and
/// manager-approved, so it is demoted to a guarded icon — always shown but
/// disabled unless the bill is unsettled AND the cashier holds refund
/// authority. See ADR-0023 / ADR-0024.
class _TopActions extends StatelessWidget {
  final Bill bill;
  final bool canRefund;
  final Future<void> Function(BillReceipt?) printDoc;
  final VoidCallback onWriteOff;
  const _TopActions({
    required this.bill,
    required this.canRefund,
    required this.printDoc,
    required this.onWriteOff,
  });

  @override
  Widget build(BuildContext context) {
    final paid = bill.paidAmount > 0;
    final canWriteOff = !bill.fullySettled && canRefund;
    return Row(
      children: [
        Expanded(
          child: SatButton.outline(
            label: paid ? 'Cetak struk meja' : 'Cetak tagihan meja',
            icon: Icons.receipt_long_outlined,
            onTap: () => printDoc(null),
          ),
        ),
        const SizedBox(width: Sp.s2),
        SatIconButton.danger(
          icon: Icons.report_gmailerrorred_outlined,
          tooltip: 'Tutup tagihan — tak tertagih',
          size: 46,
          onTap: canWriteOff ? onWriteOff : null,
        ),
      ],
    );
  }
}

/// Reminds the cashier the table was already freed by the waiter while the bill
/// is still open (a walkout / lingering-guest detached visit). Plain warn
/// treatment — sits under [_TopActions]. See ADR-0024.
class _DetachedBanner extends StatelessWidget {
  const _DetachedBanner();
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s3, vertical: Sp.s2h),
      decoration: SatBox.d(
        color: sc.warn.withValues(alpha: 0.10),
        borderRadius: SatR.a(12),
      ),
      child: Row(
        children: [
          Icon(Icons.event_seat_outlined, size: 16, color: sc.warn),
          const SizedBox(width: Sp.s2),
          Expanded(
            child: Text(
              'Meja sudah ditutup waiter — tagihan belum lunas',
              style: SatType.labelS(color: sc.warn),
            ),
          ),
        ],
      ),
    );
  }
}

// ── small shared widgets ──

class _BigBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BigBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return PressScale(
      pressedScale: 0.96,
      child: Material(
        color: sc.bg3,
        borderRadius: SatR.a(12),
        child: InkWell(
          borderRadius: SatR.a(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Sp.s3h,
              horizontal: Sp.s1h,
            ),
            child: Column(
              children: [
                Icon(icon, size: 22, color: sc.textHi),
                const SizedBox(height: Sp.s1h),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: SatType.labelS(color: sc.textHi),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Accidental-press guard for one-tap money actions (Hapus / Buka ulang): a
/// simple confirm dialog. Returns true only on explicit confirm.
Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final ok = await showSatDialog<bool>(
    context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        SatButton.ghost(
          label: AppStrings.cancel,
          onTap: () => Navigator.pop(c, false),
        ),
        SatButton.danger(
          label: confirmLabel,
          onTap: () => Navigator.pop(c, true),
        ),
      ],
    ),
  );
  return ok == true;
}

Future<int?> _askInt(BuildContext context, String title, {int initial = 2}) {
  final ctl = TextEditingController(text: '$initial');
  return showSatDialog<int>(
    context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SatField.number(controller: ctl, hint: '', autofocus: true),
      actions: [
        SatButton.ghost(
          label: AppStrings.cancel,
          onTap: () => Navigator.pop(ctx),
        ),
        SatButton.primary(
          label: 'Bagi',
          onTap: () => Navigator.pop(ctx, int.tryParse(ctl.text).let((v) => v)),
        ),
      ],
    ),
  );
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

String _shortWhen(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)} ${two(l.hour)}:${two(l.minute)}';
}

/// `HH:mm` local — the batch (`sentAt`) grouping key, matching the KDS.
String _hhmm(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.hour)}:${two(l.minute)}';
}

/// Read-only batch-grouped line rows for the Struk pembayaran detail — same
/// grouping + modifier/note treatment as the live bill, minus the assign UI.
List<Widget> _pastLineWidgets(BuildContext context, Bill bill) {
  final sc = context.sat;
  final sorted = [...bill.lines]
    ..sort((a, b) {
      final ax = a.sentAt, bx = b.sentAt;
      if (ax == null && bx == null) return 0;
      if (ax == null) return 1;
      if (bx == null) return -1;
      return ax.compareTo(bx);
    });
  final groups = <String, List<BillLine>>{};
  for (final l in sorted) {
    groups
        .putIfAbsent(l.sentAt != null ? _hhmm(l.sentAt!) : '—', () => [])
        .add(l);
  }
  final multiBatch = groups.length > 1;
  final out = <Widget>[];
  var batchNo = 0;
  groups.forEach((key, lines) {
    batchNo++;
    if (multiBatch) {
      out.add(
        Padding(
          padding: const EdgeInsets.only(top: Sp.s1h, bottom: Sp.sHair),
          child: Text(
            'PESANAN $batchNo · $key',
            style: SatType.labelS(color: sc.textLo),
          ),
        ),
      );
    }
    for (final l in lines) {
      final hasNote = l.note?.trim().isNotEmpty == true;
      out.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.s1h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${l.qty}×', style: SatType.monoM(color: sc.textLo)),
                  const SizedBox(width: Sp.s2),
                  Expanded(
                    child: Text(
                      '${l.name}${l.variantName.isNotEmpty ? ' · ${l.variantName}' : ''}',
                      style: SatType.bodyM(color: sc.textHi),
                    ),
                  ),
                  Text(
                    formatIDR(l.lineTotal),
                    style: SatType.monoM(color: sc.textHi),
                  ),
                ],
              ),
              for (final m in l.modifiers)
                Padding(
                  padding: const EdgeInsets.only(left: Sp.s7, top: Sp.sHair),
                  child: Text(
                    '${m.display}'
                    '${m.priceDelta != 0 ? ' (${m.priceDelta > 0 ? '+' : '−'}${groupRupiah(m.priceDelta.abs())})' : ''}',
                    style: SatType.bodyS(color: sc.textLo),
                  ),
                ),
              if (hasNote)
                Padding(
                  padding: const EdgeInsets.only(left: Sp.s7, top: Sp.sHair),
                  child: Text(
                    'Catatan: ${l.note!.trim()}',
                    style: SatType.bodyS(color: sc.textLo),
                  ),
                ),
            ],
          ),
        ),
      );
    }
  });
  return out;
}

String _dayKey(DateTime d) {
  final l = d.toLocal();
  return '${l.year}-${l.month}-${l.day}';
}

String _dayLabel(DateTime d) {
  final l = d.toLocal();
  final now = SatClock.now();
  final diff = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(l.year, l.month, l.day)).inDays;
  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}';
}

/// The cashier's venue-wide Past bills list (last 7 days) — the body of the
/// Riwayat tab on the cashier screen. Newest-first, grouped by day, each row led
/// by its table. A table-filter chip narrows the list client-side (the rows are
/// already loaded); chips are derived from the rows themselves, so a
/// since-deleted table's history stays reachable. See ADR-0024.
class VenueHistoryView extends ConsumerStatefulWidget {
  const VenueHistoryView({super.key});
  @override
  ConsumerState<VenueHistoryView> createState() => _VenueHistoryViewState();
}

class _VenueHistoryViewState extends ConsumerState<VenueHistoryView> {
  String? _tableFilter; // tableId; null ⇒ all tables

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final async = ref.watch(venueHistoryProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text(
          'Gagal memuat riwayat.',
          style: SatType.bodyM(color: sc.textLo),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) return const _HistoryEmpty();
        // tableId → frozen label, in first-seen (newest-first) order, for chips.
        final tables = <String, String?>{};
        for (final r in rows) {
          tables.putIfAbsent(r.tableId, () => r.tableLabel);
        }
        // A filter that no longer matches any row (its table aged out) falls
        // back to "all" rather than showing an empty list.
        final active = _tableFilter != null && tables.containsKey(_tableFilter)
            ? _tableFilter
            : null;
        final filtered = active == null
            ? rows
            : [
                for (final r in rows)
                  if (r.tableId == active) r,
              ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FilterBar(
              tables: tables,
              selected: active,
              onSelect: (id) => setState(() => _tableFilter = id),
            ),
            Expanded(child: _DayGroupedList(rows: filtered)),
          ],
        );
      },
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 44, color: sc.textLo),
          const SizedBox(height: Sp.s3),
          Text(
            'Belum ada tagihan 7 hari terakhir.',
            textAlign: TextAlign.center,
            style: SatType.bodyM(color: sc.textLo),
          ),
        ],
      ),
    );
  }
}

/// Horizontal table-filter chips. Hidden when only one table is present
/// (nothing to narrow). "Semua" clears the filter.
class _FilterBar extends StatelessWidget {
  final Map<String, String?> tables;
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _FilterBar({
    required this.tables,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (tables.length <= 1) return const SizedBox(height: Sp.s1);
    final entries = tables.entries.toList()
      ..sort((a, b) => (a.value ?? '').compareTo(b.value ?? ''));
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        children: [
          SatChip.select(
            label: 'Semua',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(left: Sp.s2),
              child: SatChip.select(
                label: 'Meja ${e.value ?? '—'}',
                selected: selected == e.key,
                onTap: () => onSelect(e.key),
              ),
            ),
        ],
      ),
    );
  }
}

/// Newest-first rows with a day header inserted at each date boundary.
class _DayGroupedList extends StatelessWidget {
  final List<PastBillSummary> rows;
  const _DayGroupedList({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const _HistoryEmpty();
    final items = <Object>[]; // String header | PastBillSummary tile
    String? lastKey;
    for (final r in rows) {
      final key = _dayKey(r.closedAt);
      if (key != lastKey) {
        items.add(_dayLabel(r.closedAt));
        lastKey = key;
      }
      items.add(r);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        if (it is String) {
          return Reveal(
            index: i,
            child: _DayHeader(it, first: i == 0),
          );
        }
        return Reveal(
          index: i,
          child: Padding(
            padding: const EdgeInsets.only(bottom: Sp.s2),
            child: _PastBillTile(it as PastBillSummary, showTableChip: true),
          ),
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;
  final bool first;
  const _DayHeader(this.label, {required this.first});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, first ? 4 : 16, 4, 8),
      child: Text(label.toUpperCase(), style: SatType.labelS(color: sc.textLo)),
    );
  }
}

/// Square table-label badge leading a venue-wide history row.
class _TableChip extends StatelessWidget {
  final String? label;
  const _TableChip(this.label);

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      width: 44,
      height: 44,
      decoration: SatBox.d(color: sc.bg3, borderRadius: SatR.a(12)),
      alignment: Alignment.center,
      child: Text(label ?? '—', style: SatType.monoM(color: sc.textHi)),
    );
  }
}

/// Square Bawa pulang glyph leading a takeaway history row — mirrors the
/// Aktif tab's takeaway treatment (the long takeaway label rides the title,
/// not this chip). See ADR-0026.
class _TakeawayChip extends StatelessWidget {
  const _TakeawayChip();

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      width: 44,
      height: 44,
      decoration: SatBox.d(color: sc.accentSoft, borderRadius: SatR.a(12)),
      alignment: Alignment.center,
      child: Icon(Icons.shopping_bag_rounded, size: 20, color: sc.accentText),
    );
  }
}

/// Past bills for one physical table — last 7 days of closed bills (snapshotted
/// sessions). Tap one to view its Struk pembayaran detail. See ADR-0024.
class PastBillsScreen extends ConsumerWidget {
  final String tableId;
  final String? tableLabel;
  const PastBillsScreen({super.key, required this.tableId, this.tableLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final async = ref.watch(pastBillsProvider(tableId));
    return Scaffold(
      backgroundColor: sc.bg0,
      appBar: AppBar(
        backgroundColor: sc.bg1,
        title: Text(
          'Riwayat · Meja ${tableLabel ?? ''}'.trim(),
          style: SatType.labelL(color: sc.textHi),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Gagal memuat riwayat.',
            style: SatType.bodyM(color: sc.textLo),
          ),
        ),
        data: (rows) => rows.isEmpty
            ? Center(
                child: Text(
                  'Belum ada tagihan 7 hari terakhir.',
                  style: SatType.bodyM(color: sc.textLo),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: Sp.s2),
                itemBuilder: (_, i) =>
                    Reveal(index: i, child: _PastBillTile(rows[i])),
              ),
      ),
    );
  }
}

class _PastBillTile extends StatelessWidget {
  final PastBillSummary b;

  /// Lead the row with the table label — set in the venue-wide Riwayat list
  /// (rows span tables); left off the per-table view (every row is one table).
  final bool showTableChip;
  const _PastBillTile(this.b, {this.showTableChip = false});
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return PressScale(
      child: Material(
        color: sc.bg1,
        borderRadius: SatR.a(14),
        child: InkWell(
          borderRadius: SatR.a(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PastBillDetailScreen(
                sessionId: b.sessionId,
                tableLabel: b.tableLabel,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Sp.s3h),
            child: Row(
              children: [
                if (b.isTakeaway) ...[
                  const _TakeawayChip(),
                  const SizedBox(width: Sp.s3),
                ] else if (showTableChip) ...[
                  _TableChip(b.tableLabel),
                  const SizedBox(width: Sp.s3),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.isTakeaway
                            ? (b.tableLabel?.trim().isNotEmpty == true
                                  ? b.tableLabel!
                                  : 'Bawa pulang')
                            : _shortWhen(b.closedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SatType.labelM(color: sc.textHi),
                      ),
                      const SizedBox(height: Sp.s1),
                      Text(
                        b.isTakeaway
                            ? '${_shortWhen(b.closedAt)} · ${b.ticketCount} item'
                            : '${b.pax} tamu · ${b.ticketCount} item',
                        style: SatType.bodyS(color: sc.textLo),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatIDR(b.netTotal),
                      style: SatType.monoM(color: sc.textHi),
                    ),
                    if (b.isWriteOff) ...[
                      const SizedBox(height: Sp.s1),
                      Text(
                        'tak tertagih ${formatIDR(b.lossAmount)}',
                        style: SatType.labelS(color: sc.urgent),
                      ),
                    ],
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

/// Read-only Struk pembayaran detail for one closed (past) bill.
class PastBillDetailScreen extends ConsumerWidget {
  final String sessionId;
  final String? tableLabel;
  const PastBillDetailScreen({
    super.key,
    required this.sessionId,
    this.tableLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final future = ref
        .read(settlementProvider.notifier)
        .fetchSessionBill(sessionId);
    return Scaffold(
      backgroundColor: sc.bg0,
      appBar: AppBar(
        backgroundColor: sc.bg1,
        title: Text(
          'Struk · Meja ${tableLabel ?? ''}'.trim(),
          style: SatType.labelL(color: sc.textHi),
        ),
      ),
      body: FutureBuilder<Bill>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Text(
                'Gagal memuat struk.',
                style: SatType.bodyM(color: sc.textLo),
              ),
            );
          }
          final bill = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              _TotalsCard(bill),
              const SizedBox(height: Sp.s3h),
              ..._pastLineWidgets(context, bill),
              if (bill.receipts.isNotEmpty) ...[
                const SizedBox(height: Sp.s3h),
                ...bill.receipts
                    .expand((r) => r.payments)
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: Sp.s1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${p.isRefund ? 'Refund' : 'Bayar'} · '
                                  '${_methodLabels[p.method] ?? p.method}',
                                  style: SatType.bodyS(color: sc.textLo),
                                ),
                                if (p.hasPhoto) ...[
                                  const SizedBox(width: Sp.s2),
                                  PaymentProofThumb(
                                    paymentId: p.id,
                                    history: true,
                                    size: 26,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              formatIDR(p.amount),
                              style: SatType.monoM(color: sc.textHi),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Tappable proof-photo thumbnail for a non-cash payment (ADR-0025). Fetches the
/// JPEG over the pinned client; [history] reads the snapshotted blob (past bills
/// / report), otherwise the live payment blob. Tap opens a fullscreen viewer.
class PaymentProofThumb extends ConsumerWidget {
  final String paymentId;
  final bool history;
  final double size;
  const PaymentProofThumb({
    super.key,
    required this.paymentId,
    required this.history,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final future = ref
        .read(settlementProvider.notifier)
        .paymentPhoto(paymentId, history: history);
    return FutureBuilder<Uint8List>(
      future: future,
      builder: (context, snap) {
        final bytes = snap.data;
        return Semantics(
          button: true,
          enabled: bytes != null,
          label: AppStrings.a11yViewPhoto,
          child: GestureDetector(
            onTap: bytes == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => _ProofViewer(bytes),
                    ),
                  ),
            child: ClipRRect(
              borderRadius: SatR.a(6),
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                color: sc.bg1,
                child: bytes == null
                    ? Icon(
                        Icons.photo_rounded,
                        size: size * 0.5,
                        color: sc.textLo,
                      )
                    : Image.memory(bytes, fit: BoxFit.cover),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProofViewer extends StatelessWidget {
  final Uint8List bytes;
  const _ProofViewer(this.bytes);

  // A lightbox, not a themed screen — see satMediaChrome.
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: satMediaChrome,
    appBar: AppBar(
      backgroundColor: satMediaChrome,
      iconTheme: const IconThemeData(color: satMediaInk),
      title: Text(
        'Bukti pembayaran',
        style: SatType.labelL(color: satMediaInk),
      ),
    ),
    body: Center(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Image.memory(bytes),
      ),
    ),
  );
}
