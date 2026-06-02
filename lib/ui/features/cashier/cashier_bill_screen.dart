import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/cashier/cashier_screen.dart';
import 'package:satset/ui/features/printing/printer_picker.dart';

const _methodLabels = {
  'tunai': 'Tunai',
  'kartu': 'Kartu',
  'qris': 'QRIS',
  'transfer': 'Transfer',
  'lainnya': 'Lainnya',
};

/// Settle one table's [[Bill]]: assign lines to receipts (itemized), split
/// evenly, record payments/refunds, reopen, and — once fully settled — close
/// the table. See ADR-0023 and CONTEXT.md (Settlement / Split bill / Payment).
class CashierBillScreen extends ConsumerWidget {
  final String tableId;
  const CashierBillScreen({super.key, required this.tableId});

  SettlementRepository _repo(WidgetRef ref) =>
      ref.read(settlementProvider.notifier);

  Future<void> _run(
      BuildContext context, WidgetRef ref, Future<Bill> Function() op) async {
    try {
      await op();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_msg(e))));
      }
    } finally {
      ref.invalidate(billDetailProvider(tableId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final billAsync = ref.watch(billDetailProvider(tableId));

    return Scaffold(
      backgroundColor: sc.bg0,
      appBar: AppBar(
        backgroundColor: sc.bg1,
        title: billAsync.maybeWhen(
          data: (b) => Text('Tagihan · Meja ${b.tableLabel ?? ''}'.trim(),
              style: SatType.sans(
                  size: 16, weight: FontWeight.w600, color: sc.textHi)),
          orElse: () => Text('Tagihan',
              style: SatType.sans(
                  size: 16, weight: FontWeight.w600, color: sc.textHi)),
        ),
      ),
      body: billAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Gagal memuat tagihan.',
                style: SatType.sans(size: 13, color: sc.textLo))),
        data: (bill) => _BillBody(
          bill: bill,
          tableId: tableId,
          run: (op) => _run(context, ref, op),
          repo: _repo(ref),
          canRefund: ref.watch(authStateProvider).has(Capability.refund),
          printDoc: (r) =>
              printBillStruk(context: context, ref: ref, bill: bill, receipt: r),
        ),
      ),
    );
  }

  static String _msg(ApiException e) => switch (e.code) {
        'over_assign' => 'Unit melebihi yang tersedia.',
        'receipt_paid' => 'Buka ulang struk sebelum mengubahnya.',
        'tickets_not_terminal' =>
          'Masih ada makanan belum tersaji — tidak bisa tutup meja.',
        'no_tickets' => 'Meja tidak punya pesanan.',
        _ => 'Operasi gagal (${e.code ?? e.statusCode}).',
      };
}

class _BillBody extends StatelessWidget {
  final Bill bill;
  final String tableId;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;
  final bool canRefund;
  final Future<void> Function(BillReceipt?) printDoc;

  const _BillBody({
    required this.bill,
    required this.tableId,
    required this.run,
    required this.repo,
    required this.canRefund,
    required this.printDoc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              _TotalsCard(bill),
              const SizedBox(height: 8),
              _PrintBillButton(bill: bill, printDoc: printDoc),
              const SizedBox(height: 14),
              if (bill.receipts.isEmpty) _ModeChooser(bill: bill, run: run, repo: repo),
              _LinesSection(bill: bill, run: run, repo: repo),
              const SizedBox(height: 14),
              ...bill.receipts.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReceiptCard(
                      bill: bill,
                      receipt: r,
                      run: run,
                      repo: repo,
                      canRefund: canRefund,
                      printDoc: printDoc,
                    ),
                  )),
              if (bill.receipts.isNotEmpty) _AddReceiptButton(bill: bill, run: run, repo: repo),
            ],
          ),
        ),
        if (bill.fullySettled)
          _CloseBar(tableId: tableId),
      ],
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
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(k,
                  style: SatType.sans(
                      size: strong ? 14 : 12.5,
                      weight: strong ? FontWeight.w700 : FontWeight.w400,
                      color: strong ? sc.textHi : sc.textLo)),
              Text(formatIDR(v),
                  style: SatType.mono(
                      size: strong ? 15 : 12.5,
                      weight: strong ? FontWeight.w700 : FontWeight.w500,
                      color: color ?? (strong ? sc.textHi : sc.textHi))),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: sc.bg1, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          row('Subtotal', bill.subtotal),
          if (bill.serviceAmount > 0) row('Layanan', bill.serviceAmount),
          if (bill.taxAmount > 0) row('Pajak', bill.taxAmount),
          Divider(color: sc.border0, height: 16),
          row('Total', bill.total, strong: true),
          row('Terbayar', bill.paidAmount, color: sc.success),
          row('Sisa', bill.outstanding,
              color: bill.outstanding > 0 ? sc.warn : sc.success),
        ],
      ),
    );
  }
}

class _ModeChooser extends StatelessWidget {
  final Bill bill;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;
  const _ModeChooser({required this.bill, required this.run, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: _BigBtn(
              icon: Icons.payments_outlined,
              label: 'Bayar penuh',
              filled: true,
              onTap: () async {
                await run(() => repo.createReceipt(bill.tableId,
                    mode: 'itemized', assignAll: true, label: 'Tagihan'));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BigBtn(
              icon: Icons.call_split_rounded,
              label: 'Split per item',
              onTap: () => run(() => repo.createReceipt(bill.tableId,
                  mode: 'itemized', label: 'Tamu 1')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BigBtn(
              icon: Icons.safety_divider_rounded,
              label: 'Split rata',
              onTap: () async {
                final n = await _askInt(context, 'Bagi rata berapa orang?',
                    initial: bill.pax > 1 ? bill.pax : 2);
                if (n != null) {
                  await run(() => repo.splitEven(bill.tableId, n));
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
  const _LinesSection({required this.bill, required this.run, required this.repo});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final assignable = bill.mode == 'itemized' && bill.receipts.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
          color: sc.bg1, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Item pesanan',
                    style: SatType.sans(
                        size: 12, weight: FontWeight.w600, color: sc.textLo)),
                if (!bill.fullyAssigned && assignable)
                  Text('Belum semua diatur',
                      style: SatType.sans(size: 10.5, color: sc.warn)),
              ],
            ),
          ),
          ...bill.lines.map((l) {
            final assigned = l.assignedUnits;
            return ListTile(
              dense: true,
              title: Text(
                  '${l.name}${l.variantName.isNotEmpty ? ' · ${l.variantName}' : ''}',
                  style: SatType.sans(size: 13, color: sc.textHi)),
              subtitle: Text(
                  '${l.qty} × ${formatIDR(l.unitPrice)}'
                  '${assignable ? '  ·  $assigned/${l.qty} diatur' : ''}',
                  style: SatType.sans(size: 11, color: sc.textLo)),
              trailing: assignable
                  ? TextButton(
                      onPressed: () => _assignSheet(context, l),
                      child: Text(assigned >= l.qty ? 'Ubah' : 'Atur'),
                    )
                  : Text(formatIDR(l.lineTotal),
                      style: SatType.mono(size: 12.5, color: sc.textHi)),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _assignSheet(BuildContext context, BillLine line) async {
    final sc = context.sat;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: sc.bg1,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            left: 16,
            right: 16,
            top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atur "${line.name}"',
                style: SatType.sans(
                    size: 15, weight: FontWeight.w600, color: sc.textHi)),
            const SizedBox(height: 4),
            Text('${line.qty} unit total · ${line.unassignedUnits} belum diatur',
                style: SatType.sans(size: 11.5, color: sc.textLo)),
            const SizedBox(height: 12),
            ...bill.receipts.where((r) => r.mode != 'even').map((r) {
              final current = r.lines
                  .where((x) => x.ticketId == line.ticketId)
                  .fold<int>(0, (a, b) => a + b.qtyUnits);
              final maxForThis = line.qty -
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
  const _AssignRow(
      {required this.label,
      required this.value,
      required this.max,
      required this.onChanged});
  @override
  State<_AssignRow> createState() => _AssignRowState();
}

class _AssignRowState extends State<_AssignRow> {
  late int v = widget.value;
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(widget.label,
                  style: SatType.sans(size: 13, color: sc.textHi))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 22),
            onPressed: v > 0 ? () => setState(() => v--) : null,
          ),
          Text('$v',
              style: SatType.mono(
                  size: 15, weight: FontWeight.w700, color: sc.textHi)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 22),
            onPressed: v < widget.max ? () => setState(() => v++) : null,
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: () => widget.onChanged(v),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final sc = context.sat;
    final r = receipt;
    final paid = r.isPaid;
    return Container(
      decoration: BoxDecoration(
        color: sc.bg1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: paid ? sc.success : sc.border0),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(r.label.isEmpty ? 'Struk' : r.label,
                    style: SatType.sans(
                        size: 14, weight: FontWeight.w600, color: sc.textHi)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (paid ? sc.success : sc.warn).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(paid ? 'Lunas' : 'Belum bayar',
                    style: SatType.sans(
                        size: 10,
                        weight: FontWeight.w600,
                        color: paid ? sc.success : sc.warn)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: SatType.sans(size: 12.5, color: sc.textLo)),
              Text(formatIDR(r.total),
                  style: SatType.mono(
                      size: 15, weight: FontWeight.w700, color: sc.textHi)),
            ],
          ),
          if (r.paidNet != 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Terbayar',
                      style: SatType.sans(size: 11.5, color: sc.textLo)),
                  Text(formatIDR(r.paidNet),
                      style: SatType.mono(size: 12, color: sc.success)),
                ],
              ),
            ),
          for (final p in r.payments)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(p.isRefund ? Icons.undo_rounded : Icons.check_circle,
                      size: 13,
                      color: p.isRefund ? sc.warn : sc.success),
                  const SizedBox(width: 6),
                  Text(_methodLabels[p.method] ?? p.method,
                      style: SatType.sans(size: 11, color: sc.textLo)),
                  const Spacer(),
                  Text(formatIDR(p.amount),
                      style: SatType.mono(
                          size: 11,
                          color: p.isRefund ? sc.warn : sc.textLo)),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (!paid && r.total > 0)
                _SmallBtn(
                  label: 'Bayar',
                  filled: true,
                  onTap: () => _paySheet(context, r),
                ),
              if (paid)
                _SmallBtn(
                  label: 'Buka ulang',
                  onTap: () => run(() => repo.reopen(r.id)),
                ),
              if (canRefund && r.paidNet > 0)
                _SmallBtn(
                  label: 'Refund',
                  onTap: () => _refundSheet(context, r),
                ),
              if (r.total > 0)
                _SmallBtn(
                  label: r.payments.isEmpty ? 'Cetak tagihan' : 'Cetak struk',
                  onTap: () => printDoc(r),
                ),
              if (!paid && r.mode != 'even')
                _SmallBtn(
                  label: 'Hapus',
                  onTap: () => run(() => repo.deleteReceipt(r.id)),
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

  Future<void> _moneySheet(BuildContext context, BillReceipt r,
      {required bool refund}) async {
    final sc = context.sat;
    final amountCtl = TextEditingController(
        text: groupRupiah(refund ? r.paidNet : r.outstanding));
    final tenderedCtl = TextEditingController();
    var method = 'tunai';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: sc.bg1,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          int parse(TextEditingController c) =>
              int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final amount = parse(amountCtl);
          final tendered = parse(tenderedCtl);
          final change = tendered - amount;
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(refund ? 'Refund ${r.label}' : 'Bayar ${r.label}',
                    style: SatType.sans(
                        size: 16, weight: FontWeight.w600, color: sc.textHi)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _methodLabels.entries
                      .map((e) => ChoiceChip(
                            label: Text(e.value),
                            selected: method == e.key,
                            onSelected: (_) => setState(() => method = e.key),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtl,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [RupiahInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      prefixText: 'Rp ', labelText: 'Jumlah'),
                ),
                if (!refund && method == 'tunai') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: tenderedCtl,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [RupiahInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        prefixText: 'Rp ', labelText: 'Uang diterima'),
                  ),
                  if (tendered > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                          change >= 0
                              ? 'Kembalian ${formatIDR(change)}'
                              : 'Kurang ${formatIDR(-change)}',
                          style: SatType.sans(
                              size: 13,
                              weight: FontWeight.w600,
                              color: change >= 0 ? sc.success : sc.warn)),
                    ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: amount <= 0
                        ? null
                        : () async {
                            Navigator.of(ctx).pop();
                            if (refund) {
                              await run(() => repo.refund(r.id,
                                  method: method, amount: amount));
                            } else {
                              await run(() => repo.recordPayment(r.id,
                                  method: method,
                                  amount: amount,
                                  tendered: method == 'tunai' && tendered > 0
                                      ? tendered
                                      : null));
                            }
                          },
                    child: Text(refund ? 'Catat refund' : 'Catat pembayaran'),
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

class _AddReceiptButton extends StatelessWidget {
  final Bill bill;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;
  const _AddReceiptButton(
      {required this.bill, required this.run, required this.repo});
  @override
  Widget build(BuildContext context) {
    if (bill.mode == 'even') return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => run(() => repo.createReceipt(bill.tableId,
            mode: 'itemized', label: 'Tamu ${bill.receipts.length + 1}')),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Tambah struk'),
      ),
    );
  }
}

class _CloseBar extends ConsumerWidget {
  final String tableId;
  const _CloseBar({required this.tableId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: sc.bg1,
        border: Border(top: BorderSide(color: sc.border0)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Lunas — Tutup meja'),
          onPressed: () async {
            await closeFromCashier(ref, tableId);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

/// Whole-bill print affordance under the totals card. Prints the Tagihan
/// (pre-payment) or Struk pembayaran (once any payment is recorded) for the
/// entire table — distinct from each receipt's own print button. See ADR-0023.
class _PrintBillButton extends StatelessWidget {
  final Bill bill;
  final Future<void> Function(BillReceipt?) printDoc;
  const _PrintBillButton({required this.bill, required this.printDoc});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final paid = bill.paidAmount > 0;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: sc.textHi,
          side: BorderSide(color: sc.border0),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.receipt_long_outlined, size: 18),
        label: Text(paid ? 'Cetak struk meja' : 'Cetak tagihan meja',
            style: SatType.sans(size: 13, weight: FontWeight.w600)),
        onPressed: () => printDoc(null),
      ),
    );
  }
}

// ── small shared widgets ──

class _BigBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _BigBtn(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.filled = false});
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Material(
      color: filled ? sc.accent : sc.bg3,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, size: 22, color: filled ? sc.accentInk : sc.textHi),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: SatType.sans(
                      size: 11,
                      weight: FontWeight.w600,
                      color: filled ? sc.accentInk : sc.textHi)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _SmallBtn(
      {required this.label, required this.onTap, this.filled = false});
  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Material(
      color: filled ? sc.accent : sc.bg3,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label,
              style: SatType.sans(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: filled ? sc.accentInk : sc.textHi)),
        ),
      ),
    );
  }
}

Future<int?> _askInt(BuildContext context, String title, {int initial = 2}) {
  final ctl = TextEditingController(text: '$initial');
  return showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctl,
        keyboardType: TextInputType.number,
        autofocus: true,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(
          onPressed: () =>
              Navigator.pop(ctx, int.tryParse(ctl.text).let((v) => v)),
          child: const Text('Bagi'),
        ),
      ],
    ),
  );
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
