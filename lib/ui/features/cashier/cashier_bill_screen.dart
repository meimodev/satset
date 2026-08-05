import 'dart:convert';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_icon_button.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_card.dart';
import 'package:satset/ui/core/widgets/sat_app_bar.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';
import 'package:satset/ui/core/widgets/sat_stepper.dart';
import 'package:satset/ui/core/widgets/payment_proof_thumb.dart';
import 'package:satset/ui/core/design/layout.dart';
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
import 'package:satset/ui/core/design/receipt_visuals.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/features/cashier/discount_sheet.dart';
import 'package:satset/ui/features/cashier/receipt_badge.dart';
import 'package:satset/ui/features/cashier/widgets/settle_pane.dart';
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

/// Opens the bill surface. Hardware decides, as everywhere else (ADR-0049):
///
/// - **Tablet** — a full-screen two-pane page on the root navigator (ADR-0066).
///   The settle side carries a mode row, four methods, a seven-note cash pad,
///   a tender row, a running tally, a change fold and a proof block; that is
///   not a drawer's worth of content, and the one thing that must not scroll
///   while a cashier counts notes is the tally beside them.
/// - **Phone** — the tall sheet ADR-0064 specified, unchanged. A side panel on
///   a 360dp handset would be the whole screen anyway, so the drawer never had
///   anything to offer here.
///
/// Both are root-navigator by construction, so the floating phone tab bar still
/// cannot float over the confirm button.
Future<void> openCashierBill(
  BuildContext context, {
  required String visitId,
}) {
  if (!context.layout.useTabletShell) {
    return showSatSheet<void>(
      context,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: SafeArea(child: CashierBillView(visitId: visitId)),
      ),
    );
  }
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CashierBillPage(visitId: visitId),
    ),
  );
}

/// The tablet container for [CashierBillView] — a page, not an overlay
/// (ADR-0066). Content-only body, same as the phone sheet gets; this supplies
/// the scaffold, the bar and the way out.
///
/// The bar is the container's job, exactly as ADR-0066 prescribes — the view
/// stays chrome-free so the phone sheet can keep its own header. It watches
/// the bill only to name the table in the trail; the provider is the same one
/// the view reads, so this costs a listener, not a fetch.
class CashierBillPage extends ConsumerWidget {
  final String visitId;
  const CashierBillPage({super.key, required this.visitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final billAsync = ref.watch(billDetailProvider(visitId));
    return Scaffold(
      backgroundColor: sc.bg0,
      body: SafeArea(
        child: Column(
          children: [
            SatAppBar(
              onBack: () => Navigator.of(context).pop(),
              crumbs: billAsync.maybeWhen(
                data: (b) => ['Kasir', b.tableLabel ?? 'Tagihan'],
                orElse: () => const ['Kasir', 'Tagihan'],
              ),
              showAvatar: false,
            ),
            Expanded(child: CashierBillView(visitId: visitId)),
          ],
        ),
      ),
    );
  }
}

/// Settle one [[Visit]]'s [[Bill]]: assign lines to receipts (itemized), split
/// evenly, record payments/refunds, reopen, and — bill close (Tutup tagihan,
/// Lunas or tak tertagih). Freeing the floor table is the WAITER's separate
/// act, not here. See ADR-0024 and CONTEXT.md (Bill close / Settlement).
///
/// Content only — no `Scaffold`, no `AppBar`. [openCashierBill] supplies the
/// container. Per-table history is not reachable from here; the venue-wide
/// Riwayat tab filters by table (ADR-0064).
class CashierBillView extends ConsumerStatefulWidget {
  final String visitId;
  const CashierBillView({super.key, required this.visitId});

  @override
  ConsumerState<CashierBillView> createState() => _CashierBillViewState();
}

class _CashierBillViewState extends ConsumerState<CashierBillView> {
  /// Last failed operation, shown inline under the header. A `SnackBar` here
  /// would render in the root `Scaffold` *underneath* the modal barrier — on
  /// the money path an error must not be something you have to dismiss the
  /// bill to read (ADR-0064).
  String? _error;

  SettlementRepository get _repo => ref.read(settlementProvider.notifier);

  Future<void> _run(Future<Bill> Function() op) async {
    try {
      await op();
      if (mounted) setState(() => _error = null);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _msg(e));
    } finally {
      ref.invalidate(billDetailProvider(widget.visitId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final billAsync = ref.watch(billDetailProvider(widget.visitId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone only. The tablet container carries a `SatAppBar` whose crumbs
        // already name the table and whose back arrow is the way out — two bars
        // stacked would say the same thing twice.
        if (!context.layout.useTabletShell)
          SatSheetHeader(
            onClose: () => Navigator.of(context).pop(),
            child: Text(
              billAsync.maybeWhen(
                data: (b) => 'Tagihan · Meja ${b.tableLabel ?? ''}'.trim(),
                orElse: () => 'Tagihan',
              ),
              style: SatType.labelL(color: sc.textHi),
            ),
          ),
        if (_error != null)
          _ErrorLine(
            message: _error!,
            onDismiss: () => setState(() => _error = null),
          ),
        Expanded(
          child: billAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Gagal memuat tagihan.',
                style: SatType.bodyM(color: sc.textLo),
              ),
            ),
            data: (bill) => _BillBody(
              bill: bill,
              run: _run,
              repo: _repo,
              canRefund: ref.watch(authStateProvider).has(Capability.refund),
              onCloseBill: () => _closeBill(context, ref, bill),
              onReopenBill: () => _reopenBill(bill),
              printDoc: (r) => printBillStruk(
                context: context,
                ref: ref,
                bill: bill,
                receipt: r,
              ),
            ),
          ),
        ),
      ],
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
      if (mounted) setState(() => _error = _msg(e));
    }
  }

  /// Unlock a bill that closed itself (ADR-0069). No confirm dialog: reopening
  /// is the *recovery* from a mis-tap, and putting a second decision in front of
  /// it is how a cashier ends up stuck. It is audited, and the money is
  /// untouched — only the lock comes off.
  Future<void> _reopenBill(Bill bill) async {
    try {
      await _repo.reopenBill(bill.visitId);
      ref.invalidate(billDetailProvider(bill.visitId));
      await ref.read(settlementProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _msg(e));
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

}

String _msg(ApiException e) => switch (e.code) {
  'over_assign' => 'Unit melebihi yang tersedia.',
  'receipt_paid' => 'Buka ulang struk sebelum mengubahnya.',
  'not_settled' => 'Tagihan belum lunas.',
  'bill_locked' => 'Tagihan sudah ditutup — buka ulang dulu.',
  'forbidden' => 'Perlu persetujuan manajer (tak tertagih).',
  'reason_required' => 'Alasan tak tertagih wajib diisi.',
  'no_lines' => 'Meja tidak punya pesanan.',
  _ => 'Operasi gagal (${e.code ?? e.statusCode}).',
};

/// The failed-operation line under the sheet header — warn-toned, dismissible,
/// and inside the surface that raised it.
class _ErrorLine extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorLine({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      margin: const EdgeInsets.fromLTRB(Sp.s3h, 0, Sp.s3h, Sp.s2),
      padding: const EdgeInsets.fromLTRB(Sp.s3, Sp.s2, Sp.s1h, Sp.s2),
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
            child: Text(message, style: SatType.labelM(color: sc.warn)),
          ),
          SatIconButton.plain(
            icon: Icons.close,
            tooltip: AppStrings.close,
            size: 32,
            onTap: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _BillBody extends StatefulWidget {
  final Bill bill;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;
  final bool canRefund;
  final VoidCallback onCloseBill;
  final VoidCallback onReopenBill;
  final Future<void> Function(BillReceipt?) printDoc;

  const _BillBody({
    required this.bill,
    required this.run,
    required this.repo,
    required this.canRefund,
    required this.onCloseBill,
    required this.onReopenBill,
    required this.printDoc,
  });

  @override
  State<_BillBody> createState() => _BillBodyState();
}

class _BillBodyState extends State<_BillBody> {
  SettleMode _mode = SettleMode.penuh;

  /// ticketId → units chosen for the payment about to be taken. Lives here
  /// because the lines pane draws it and the settle pane prices it.
  final Map<String, int> _selection = {};

  Bill get bill => widget.bill;

  void _toggle(BillLine l) {
    setState(() {
      if (_selection.containsKey(l.ticketId)) {
        _selection.remove(l.ticketId);
      } else {
        // Tap takes the whole line — the 95% case. ADR-0067.
        _selection[l.ticketId] = l.unassignedUnits;
      }
    });
  }

  void _setUnits(BillLine l, int units) {
    setState(() {
      if (units <= 0) {
        _selection.remove(l.ticketId);
      } else {
        _selection[l.ticketId] = units.clamp(1, l.unassignedUnits);
      }
    });
  }

  /// A payment landed, or the mode changed — the picks no longer refer to
  /// anything, and a stale selection is how a cashier double-charges an item.
  void _clearSelection() {
    if (_selection.isEmpty) return;
    setState(_selection.clear);
  }

  @override
  Widget build(BuildContext context) {
    final done = bill.billClosedAt != null || bill.fullySettled;
    if (context.layout.useTabletShell) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Two panes scrolling independently is the whole reason ADR-0066
          // chose a page over the drawer: the running cash tally must stay put
          // while the cashier scrolls a long bill.
          Expanded(flex: 3, child: _lines(context)),
          Container(width: 1, color: context.sat.border0),
          Expanded(flex: 2, child: _settle(context, done)),
        ],
      );
    }
    // Phone: one column, confirm bar pinned. A 360dp sheet has no room for two
    // panes, and stacking them is what the sheet already does well.
    return Column(
      children: [
        Expanded(child: _lines(context)),
        if (done)
          _donePane()
        else
          SizedBox(height: 420, child: _settle(context, done)),
      ],
    );
  }

  Widget _donePane() => _DonePane(
    bill: bill,
    onPrint: () => widget.printDoc(null),
    onReopen: widget.onReopenBill,
  );

  Widget _settle(BuildContext context, bool done) {
    if (done) return _donePane();
    return SettlePane(
      bill: bill,
      repo: widget.repo,
      run: widget.run,
      selection: _selection,
      mode: _mode,
      onMode: (m) {
        setState(() => _mode = m);
        _clearSelection();
      },
      onClearSelection: _clearSelection,
    );
  }

  Widget _lines(BuildContext context) {
    // Page-load choreography: each section reveals in sequence top-to-bottom.
    var i = 0;
    Widget rv(Widget child) => Reveal(index: i++, child: child);
    final picking = _mode == SettleMode.perItem;
    // Picking on a phone, the lines pane *is* the task: a 360dp sheet already
    // gives the settle pane 420dp, and totals + actions + Struk push the items
    // the cashier is trying to tap below the fold. Everything cut here comes
    // back one tap away — the mode row lives in the settle pane, always on
    // screen. The tablet's left pane is its own column with room to spare, so
    // it keeps the lot.
    final trim = picking && !context.layout.useTabletShell;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        if (!trim) ...[
          rv(_TotalsCard(bill)),
          const SizedBox(height: Sp.s2),
          rv(
            _TopActions(
              bill: bill,
              canRefund: widget.canRefund,
              printDoc: widget.printDoc,
              onWriteOff: widget.onCloseBill,
              run: widget.run,
              repo: widget.repo,
            ),
          ),
          if (bill.detached) ...[
            const SizedBox(height: Sp.s2h),
            rv(const _DetachedBanner()),
          ],
          const SizedBox(height: Sp.s3h),
        ],
        if (bill.mode == 'itemized' &&
            bill.receipts.isNotEmpty &&
            !bill.fullyAssigned) ...[
          rv(_UnassignedBanner(bill: bill)),
          const SizedBox(height: Sp.s2h),
        ],
        rv(
          _LinesSection(
            bill: bill,
            run: widget.run,
            repo: widget.repo,
            selectable: picking,
            selection: _selection,
            onToggle: _toggle,
            onUnits: _setUnits,
          ),
        ),
        if (!trim) ...[
          const SizedBox(height: Sp.s3h),
          // An even split's shares own no items and are interchangeable by
          // design, so N near-identical cards are scroll with no signal in it.
          // They collapse into one card of thin rows. ADR-0063.
          if (bill.mode == 'even' && bill.receipts.isNotEmpty)
            rv(
              _EvenSplitCard(
                bill: bill,
                run: widget.run,
                repo: widget.repo,
                canRefund: widget.canRefund,
                printDoc: widget.printDoc,
              ),
            )
          else if (bill.receipts.isNotEmpty)
            rv(
              SatCard.section(
                header: 'Struk',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final r in bill.receipts)
                      _ReceiptRow(
                        receipt: r,
                        onTap: () => showReceiptSheet(
                          context,
                          bill: bill,
                          receipt: r,
                          run: widget.run,
                          repo: widget.repo,
                          canRefund: widget.canRefund,
                          printDoc: widget.printDoc,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
        // Pre-assigning named slips before anyone pays is still a real
        // workflow, so it stays — just no longer the only way in. ADR-0067.
        if (!picking) rv(_AddReceiptButton(bill: bill, run: widget.run, repo: widget.repo)),
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
    return SatCard.plain(
      padding: const EdgeInsets.all(Sp.s3h),
      child: Column(
        children: [
          row('Subtotal', bill.subtotal),
          // The Diskon row's position follows the actual pipeline (ADR-0038),
          // matching the printed slip: above Layanan when the discount reduced
          // the base service and tax were computed on, below Pajak otherwise.
          if (bill.discountAmount > 0 && bill.taxAfterDiscount)
            row(
              // Named when the whole-bill promo is what the cut is; the generic
              // label stays for a total that aggregates several receipts'
              // discounts, where no single name would be honest. ADR-0070.
              bill.billDiscount?.name ?? 'Diskon',
              -bill.discountAmount,
              color: sc.warn,
            ),
          if (bill.serviceAmount > 0) row('Layanan', bill.serviceAmount),
          if (bill.taxAmount > 0) row('Pajak', bill.taxAmount),
          if (bill.discountAmount > 0 && !bill.taxAfterDiscount)
            row(
              // Named when the whole-bill promo is what the cut is; the generic
              // label stays for a total that aggregates several receipts'
              // discounts, where no single name would be honest. ADR-0070.
              bill.billDiscount?.name ?? 'Diskon',
              -bill.discountAmount,
              color: sc.warn,
            ),
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

// `_ModeChooser` is gone with ADR-0067. It asked, once and up front, how the
// whole table would pay — a prediction about people who had not reached for a
// wallet yet. The question is now asked per payment by `SettlePane`'s mode row,
// where the answer is known.

class _LinesSection extends StatelessWidget {
  final Bill bill;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;

  /// Per-item mode is active, so the list is a picker: tapping a line puts it
  /// on the receipt the settle pane is about to mint (ADR-0067).
  final bool selectable;

  /// ticketId → units chosen for the pending payment.
  final Map<String, int> selection;
  final void Function(BillLine)? onToggle;
  final void Function(BillLine, int)? onUnits;

  const _LinesSection({
    required this.bill,
    required this.run,
    required this.repo,
    this.selectable = false,
    this.selection = const {},
    this.onToggle,
    this.onUnits,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    // Pre-assignment (`Atur`) and tap-to-pick are the same act at different
    // speeds, so they never share a row: picking wins while it is on.
    final assignable =
        !selectable && bill.mode == 'itemized' && bill.receipts.isNotEmpty;

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

    final children = <Widget>[];
    var batchNo = 0;
    groups.forEach((key, lines) {
      batchNo++;
      if (multiBatch) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: Sp.s2, bottom: Sp.sHair),
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

    return SatCard.section(
      header: 'Item pesanan',
      headerTrailing: (!bill.fullyAssigned && assignable)
          ? Text('Belum semua diatur', style: SatType.bodyS(color: sc.warn))
          : null,
      padding: const EdgeInsets.fromLTRB(Sp.s3h, Sp.s3, Sp.s3h, Sp.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _lineTile(BuildContext context, BillLine l, bool assignable) {
    final sc = context.sat;
    final assigned = l.assignedUnits;
    final hasNote = l.note?.trim().isNotEmpty == true;
    final pending = assignable && l.unassignedUnits > 0;
    // Free units are what a picker can take; anything already owned by a
    // receipt is locked, and a fully-owned line cannot be picked at all.
    final free = l.unassignedUnits;
    final picked = selection[l.ticketId] ?? 0;
    final pickable = selectable && free > 0;
    return ListTile(
      dense: true,
      onTap: pickable ? () => onToggle?.call(l) : null,
      tileColor: picked > 0
          ? sc.accentSoft
          : pending
          ? sc.warn.withValues(alpha: 0.08)
          : null,
      shape: (pending || picked > 0)
          ? RoundedRectangleBorder(borderRadius: SatR.a(8))
          : null,
      leading: selectable
          ? Icon(
              picked > 0
                  ? Icons.check_circle_rounded
                  : free == 0
                  ? Icons.lock_rounded
                  : Icons.circle_outlined,
              size: 20,
              color: picked > 0
                  ? sc.accentText
                  : free == 0
                  ? sc.textDim
                  : sc.textLo,
            )
          : null,
      title: Text(
        '${l.name}${l.variantName.isNotEmpty ? ' · ${l.variantName}' : ''}',
        style: SatType.bodyM(color: sc.textHi),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l.qty} × ${formatIDR(l.unitPrice)}',
            style: (pending
                ? SatType.labelS(color: pending ? sc.warn : sc.textLo)
                : SatType.bodyS(color: pending ? sc.warn : sc.textLo)),
          ),
          // Where this dish's units went, not just how many are placed: a
          // "2/3 diatur" count never answered *whose*. One chip per owning
          // receipt, plus an amber `?` chip for units still free. ADR-0063.
          if (assignable) _ownerChips(context, l),
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
          // The partial case only. A line split between two guests is rare, so
          // it reveals a stepper rather than taxing the common whole-line tap
          // with one (ADR-0037 survives, the frequent gesture stays one tap).
          if (pickable && picked > 0 && free > 1)
            Padding(
              padding: const EdgeInsets.only(top: Sp.s1),
              child: Row(
                children: [
                  Text(
                    '$picked dari $free',
                    style: SatType.labelS(color: sc.accentText),
                  ),
                  const SizedBox(width: Sp.s2),
                  SatIconButton.plain(
                    icon: Icons.remove_rounded,
                    tooltip: 'Kurangi unit',
                    onTap: picked <= 1
                        ? null
                        : () => onUnits?.call(l, picked - 1),
                  ),
                  SatIconButton.plain(
                    icon: Icons.add_rounded,
                    tooltip: 'Tambah unit',
                    onTap: picked >= free
                        ? null
                        : () => onUnits?.call(l, picked + 1),
                  ),
                ],
              ),
            ),
        ],
      ),
      // ponytail: SatButton centers its content, so it eats every pixel of a
      // loose constraint — ListTile hands trailing the full tile width.
      trailing: assignable
          ? SizedBox(
              width: 84,
              child: SatButton.ghost(
                label: assigned >= l.qty ? 'Ubah' : 'Atur',
                onTap: () => _assignSheet(context, l),
              ),
            )
          : Text(
              formatIDR(l.lineTotal),
              style: SatType.monoM(color: sc.textHi),
            ),
    );
  }

  /// One badge per receipt owning units of [l], in bill order, trailed by the
  /// unassigned remainder. Even-mode receipts own no lines, so this row is
  /// empty for them and the caller's `assignable` gate already excludes it.
  Widget _ownerChips(BuildContext context, BillLine l) {
    final chips = <Widget>[];
    for (final r in bill.receipts) {
      final units = r.lines
          .where((x) => x.ticketId == l.ticketId)
          .fold<int>(0, (a, b) => a + b.qtyUnits);
      if (units == 0) continue;
      chips.add(
        isReceiptLetter(r.label.trim())
            ? ReceiptBadge(r.label.trim(), count: units, dense: true)
            : Text(
                '${receiptTitle(r.label)} ×$units',
                style: SatType.labelS(color: context.sat.textLo),
              ),
      );
    }
    if (l.unassignedUnits > 0) {
      chips.add(ReceiptBadge.unassigned(count: l.unassignedUnits));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Sp.s1),
      child: Wrap(spacing: Sp.s1, runSpacing: Sp.s1, children: chips),
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
                label: r.label,
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
          if (isReceiptLetter(widget.label.trim())) ...[
            ReceiptBadge(widget.label.trim()),
            const SizedBox(width: Sp.s2),
          ],
          Expanded(
            child: Text(
              receiptTitle(widget.label),
              style: SatType.bodyM(color: sc.textHi),
            ),
          ),
          SatStepper(
            value: v,
            max: widget.max,
            semanticLabel: widget.label,
            onChanged: (n) => setState(() => v = n),
          ),
          const SizedBox(width: Sp.s2),
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
    // 'Tagihan' (whole bill) and 'Bagian 1/3' (even share) are not letters and
    // wear no badge — there is no sibling guest to tell them apart from.
    final hasLetter = isReceiptLetter(r.label.trim());
    // Not SatCard.plain, unlike the totals and lines cards ADR-0064 folded:
    // this outline carries *identity*, not just chrome. ADR-0063 gives the
    // card its guest's hue so a scrolled-past receipt stays identifiable once
    // the header badge is off-screen, and settled always wins it (green ends
    // the conversation). SatCard owns its border and has no hue axis.
    return AnimatedContainer(
      duration: satMotion(context, 280),
      curve: satEaseOut,
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: SatR.a(14),
        border: SatB.all(
          color: paid
              ? sc.success
              : (hasLetter ? receiptHue(r.label.trim()) : sc.border0),
        ),
      ),
      padding: const EdgeInsets.all(Sp.s3h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasLetter) ...[
                ReceiptBadge(r.label.trim()),
                const SizedBox(width: Sp.s2),
              ],
              Expanded(
                child: Text(
                  receiptTitle(r.label),
                  style: SatType.labelM(color: sc.textHi),
                ),
              ),
              // Was a hand-drawn AnimatedContainer pill (ADR-0064). The card
              // outline says the same thing at a glance; the chip is what says
              // it in words.
              SatChip.tag(
                label: paid ? 'Lunas' : 'Belum bayar',
                hue: paid ? SatChipHue.success : SatChipHue.warn,
                size: SatChipSize.sm,
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
                    PaymentProofThumb(paymentId: p.id),
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
                          'Batalkan status lunas "${receiptTitle(r.label)}" '
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
                        title: receiptTitle(r.label),
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
                          'Hapus "${receiptTitle(r.label)}"? '
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
                  refund
                      ? 'Refund ${receiptTitle(r.label)}'
                      : 'Bayar ${receiptTitle(r.label)}',
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
                      // Tappable like every other proof: pre-submit is the one
                      // moment a blurry shot is still fixable, and `Ambil ulang`
                      // is right there. ADR-0082.
                      if (photoBytes != null)
                        PaymentProofThumb(
                          paymentId: null,
                          previewBytes: photoBytes,
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

/// The whole of an **even** [[Split bill]] in one card: the per-head amount,
/// a paid tally, and one thin row per share.
///
/// An even receipt owns no lines (ADR-0037), so there is nothing to tell one
/// share from another — rendering them as N full receipt cards implied a
/// per-guest identity the model does not have, and buried the only fact that
/// matters (how many are still owing) under a screen of scroll.
///
/// Every per-share act stays reachable: a row opens that share's own
/// [_ReceiptCard] in a sheet, so pay / reopen / refund / diskon / cetak run
/// through exactly one implementation. See ADR-0063.
class _EvenSplitCard extends StatelessWidget {
  final Bill bill;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;
  final bool canRefund;
  final Future<void> Function(BillReceipt?) printDoc;
  const _EvenSplitCard({
    required this.bill,
    required this.run,
    required this.repo,
    required this.canRefund,
    required this.printDoc,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final rs = bill.receipts;
    final paidCount = rs.where((r) => r.isPaid).length;
    final next = rs.indexWhere((r) => !r.isPaid);
    // Shares are computed to the rupiah server-side and can differ by one on
    // the remainder, so the headline quotes the first rather than dividing.
    final perHead = rs.isEmpty ? 0 : rs.first.total;
    return Container(
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: SatR.a(14),
        border: SatB.all(
          color: paidCount == rs.length ? sc.success : sc.border0,
        ),
      ),
      padding: const EdgeInsets.all(Sp.s3h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Split rata · ${rs.length} bagian',
                  style: SatType.labelM(color: sc.textHi),
                ),
              ),
              Text(
                '${formatIDR(perHead)} / orang',
                style: SatType.monoM(color: sc.textHi),
              ),
            ],
          ),
          const SizedBox(height: Sp.s1),
          Text(
            '$paidCount dari ${rs.length} lunas',
            style: SatType.bodyS(
              color: paidCount == rs.length ? sc.success : sc.textLo,
            ),
          ),
          const SizedBox(height: Sp.s2),
          Divider(height: 1, color: sc.border0),
          for (var i = 0; i < rs.length; i++)
            _EvenShareRow(
              index: i,
              receipt: rs[i],
              onTap: () => _shareSheet(context, rs[i]),
            ),
          if (next >= 0) ...[
            const SizedBox(height: Sp.s2h),
            SatButton.primary(
              size: SatButtonSize.sm,
              label: 'Bayar bagian ${next + 1}',
              onTap: () => _shareSheet(context, rs[next]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _shareSheet(BuildContext context, BillReceipt r) =>
      showReceiptSheet(
        context,
        bill: bill,
        receipt: r,
        run: run,
        repo: repo,
        canRefund: canRefund,
        printDoc: printDoc,
      );
}

/// One receipt's full card in a sheet — every per-receipt act (bayar, refund,
/// buka ulang, diskon, cetak) reached exactly one way (L2-17/18).
///
/// The list behind it stays thin rows: a bill with four receipts used to be a
/// screen of near-identical cards, and the fact a cashier is scanning for is
/// *which one is still owing*, which a row answers and a card buries. Same
/// reasoning ADR-0063 applied to even shares, now applied to both kinds.
///
/// `run` is wrapped to close the sheet first — the sheet holds a snapshot of
/// the receipt, so leaving it open after a mutation would show stale money.
Future<void> showReceiptSheet(
  BuildContext context, {
  required Bill bill,
  required BillReceipt receipt,
  required Future<void> Function(Future<Bill> Function()) run,
  required SettlementRepository repo,
  required bool canRefund,
  required Future<void> Function(BillReceipt?) printDoc,
}) => showSatSheet<void>(
  context,
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(ctx).viewInsets.bottom + Sp.s3,
      left: Sp.s3h,
      right: Sp.s3h,
      top: Sp.s3h,
    ),
    child: SingleChildScrollView(
      child: _ReceiptCard(
        bill: bill,
        receipt: receipt,
        run: (fn) async {
          Navigator.of(ctx).pop();
          await run(fn);
        },
        repo: repo,
        canRefund: canRefund,
        printDoc: printDoc,
      ),
    ),
  ),
);

/// One itemized receipt as a thin row: its letter, what it owns, what it owes,
/// and a chevron into [showReceiptSheet]. The letter is the identity (ADR-0063)
/// and the item count is what a cashier actually recognises a guest by.
class _ReceiptRow extends StatelessWidget {
  final BillReceipt receipt;
  final VoidCallback onTap;
  const _ReceiptRow({required this.receipt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final paid = receipt.isPaid;
    final items = receipt.lines.fold<int>(0, (a, l) => a + l.qtyUnits);
    return Semantics(
      button: true,
      label:
          '${receiptTitle(receipt.label)}, '
          '${paid ? 'lunas' : 'belum bayar'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: SatR.a(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.s2),
          child: Row(
            children: [
              ReceiptBadge(receipt.label.trim(), filled: paid, dense: true),
              const SizedBox(width: Sp.s2h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatIDR(receipt.total),
                      style: SatType.monoM(color: sc.textHi),
                    ),
                    Text(
                      '$items item',
                      style: SatType.labelS(color: sc.textLo),
                    ),
                  ],
                ),
              ),
              Text(
                paid ? 'Lunas' : 'Belum bayar',
                style: SatType.labelS(color: paid ? sc.success : sc.warn),
              ),
              const SizedBox(width: Sp.s1h),
              Icon(Icons.chevron_right_rounded, size: 18, color: sc.textDim),
            ],
          ),
        ),
      ),
    );
  }
}

/// One share inside [_EvenSplitCard] — position, amount, paid state, and a
/// chevron into its action sheet. Deliberately thin: an even share has no
/// items and no identity, so there is nothing else true to show.
class _EvenShareRow extends StatelessWidget {
  final int index;
  final BillReceipt receipt;
  final VoidCallback onTap;
  const _EvenShareRow({
    required this.index,
    required this.receipt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final paid = receipt.isPaid;
    return Semantics(
      button: true,
      label: 'Bagian ${index + 1}, ${paid ? 'lunas' : 'belum bayar'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: SatR.a(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.s2),
          child: Row(
            children: [
              SizedBox(
                width: Sp.s6,
                child: Text(
                  '${index + 1}',
                  style: SatType.monoM(color: sc.textLo),
                ),
              ),
              Expanded(
                child: Text(
                  formatIDR(receipt.total),
                  style: SatType.monoM(color: sc.textHi),
                ),
              ),
              Text(
                paid ? 'Lunas' : 'Belum bayar',
                style: SatType.labelS(color: paid ? sc.success : sc.warn),
              ),
              const SizedBox(width: Sp.s1h),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: sc.textDim,
              ),
            ],
          ),
        ),
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
            // Lowest unused letter, so deleting B and adding again refills B
            // rather than minting D. A guest's letter is persisted, never
            // positional. ADR-0063.
            label: nextReceiptLetter([for (final r in bill.receipts) r.label]),
          ),
        ),
      ),
    );
  }
}

// `_ResetMethodButton` is gone with ADR-0067. It existed to undo a mode the
// bill had been committed to; mode is now chosen per payment and nothing is
// minted until confirm, so there is no committed choice left to undo. Deleting
// one unpaid receipt is still available and is the whole of that story now.

/// the one act that recovers a mistake.
class _DonePane extends StatelessWidget {
  final Bill bill;
  final VoidCallback onPrint;
  final VoidCallback onReopen;
  const _DonePane({
    required this.bill,
    required this.onPrint,
    required this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final writeOff = bill.outstanding > 0;
    final parts = bill.receipts.length;
    return Container(
      // No bottom safe-area inset: the page/sheet container already wraps this
      // body in a SafeArea.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: SatBox.d(
        color: sc.bg1,
        border: Border(top: SatB.side(color: sc.border0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                writeOff
                    ? Icons.report_gmailerrorred_rounded
                    : Icons.check_circle_rounded,
                size: 28,
                color: writeOff ? sc.urgent : sc.success,
              ),
              const SizedBox(width: Sp.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      writeOff ? 'Tagihan tak tertagih' : 'Tagihan lunas',
                      style: SatType.labelL(color: sc.textHi),
                    ),
                    const SizedBox(height: Sp.sHair),
                    Text(
                      writeOff
                          ? '${formatIDR(bill.outstanding)} dicatat sebagai '
                                'kerugian.'
                          : '${formatIDR(bill.total)} diterima penuh'
                                '${parts > 1 ? ' dalam $parts bagian' : ''}.',
                      style: SatType.bodyS(color: sc.textLo),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s3h),
          SatButton.primary(
            label: writeOff ? 'Cetak tagihan' : 'Cetak struk lunas',
            icon: Icons.print_rounded,
            onTap: onPrint,
          ),
          const SizedBox(height: Sp.s2),
          SatButton.outline(
            label: 'Buka ulang',
            icon: Icons.lock_open_rounded,
            onTap: onReopen,
          ),
        ],
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
class _TopActions extends ConsumerWidget {
  final Bill bill;
  final bool canRefund;
  final Future<void> Function(BillReceipt?) printDoc;
  final VoidCallback onWriteOff;
  final Future<void> Function(Future<Bill> Function()) run;
  final SettlementRepository repo;
  const _TopActions({
    required this.bill,
    required this.canRefund,
    required this.printDoc,
    required this.onWriteOff,
    required this.run,
    required this.repo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paid = bill.paidAmount > 0;
    final canWriteOff = !bill.fullySettled && canRefund;
    final disc = bill.billDiscount;
    // A bill discount moves the bill total, and an amount receipt's claim is
    // frozen at mint time (ADR-0068) — so once money is in, it is the server's
    // no, not ours. Disabled here rather than failing there.
    final canDiscount = bill.billClosedAt == null && !paid;
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
        // The table-wide promo (ADR-0070). Named once applied, because a cut
        // with no name on it is the one a manager queries later.
        Expanded(
          child: SatButton.outline(
            label: disc?.name ?? 'Diskon',
            icon: Icons.local_offer_outlined,
            onTap: canDiscount
                ? () => disc == null
                      ? _apply(context, ref)
                      : _remove(context, ref, disc.id)
                : null,
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

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    final picked = await showDiscountSheet(
      context,
      ref,
      DiscountTarget.bill(base: bill.subtotal, title: 'Seluruh tagihan'),
    );
    if (picked == null) return;
    await run(
      () => repo.applyBillDiscount(
        bill.visitId,
        presetId: picked.presetId,
        approverPin: picked.approverPin,
      ),
    );
  }

  /// Confirm-guarded, like every other discount removal here. No PIN prompt:
  /// the server rejects a caller without the capability, and asking for one up
  /// front would claim an authority check the client does not do.
  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    String discountId,
  ) async {
    final disc = bill.billDiscount!;
    final ok = await _confirm(
      context,
      title: 'Hapus diskon tagihan',
      message:
          'Hapus "${disc.name}" (${formatIDR(disc.amount)}) '
          'dari seluruh tagihan?',
      confirmLabel: 'Ya, hapus',
    );
    if (!ok) return;
    await run(() => repo.removeBillDiscount(bill.visitId, discountId));
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

// `_askInt` went with `_ModeChooser` (ADR-0067). Asking "bagi rata berapa
// orang?" in a modal made sense when the split was a one-off commitment; the
// settle pane now carries a stepper beside the per-head figure it changes.

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

/// The venue-wide Past bills list used to live here as `VenueHistoryView`, the
/// body of a Riwayat tab. ADR-0069 made a settled bill close itself, so "already
/// paid" and "history" became the same set and the tab folded into the cashier
/// screen's **Lunas** segment — which renders a `BillCard` per closed bill, the
/// same card a live one gets. The row tile, its day grouping and its filter bar
/// went with it; the table filter survives as the segment's range + filter row.


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
      body: Column(
        children: [
          // No crumbs: this pushes on the shell navigator, so on a tablet the
          // shell's own bar sits right above with the venue → Kasir trail
          // already on it. The back arrow is what this bar is for. The phone
          // bar renders no crumbs at all, so there the name rides as a pill —
          // otherwise the screen would go unnamed.
          SatAppBar(
            onBack: () => Navigator.of(context).pop(),
            showAvatar: false,
            trailingPills: context.layout.useTabletShell
                ? const []
                : [
                    Text(
                      'Struk · Meja ${tableLabel ?? ''}'.trim(),
                      style: SatType.labelM(color: sc.textMd),
                    ),
                  ],
          ),
          Expanded(child: _body(context, sc, future)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, SatColors sc, Future<Bill> future) =>
      FutureBuilder<Bill>(
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
      );
}

