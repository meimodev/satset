import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/member_dto.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/features/cashier/member_panel.dart'
    show MemberLookupSheet;
import 'package:satset/ui/features/cashier/widgets/cash_pad.dart';
import 'package:satset/ui/features/cashier/widgets/pay_method_picker.dart';

/// A [[Diskon (discount)]] the [[Cashier]] has put on a line that no receipt
/// owns yet (ADR-0126).
///
/// Held here rather than written because a line discount needs a receipt to
/// hang on, and the pane mints at confirm — so a selection the cashier tries
/// and abandons leaves nothing behind, the same contract the rest of this pane
/// keeps. [amount] is the pick-time preview; the server re-resolves it.
class PendingLineDiscount {
  final String presetId;
  final String label;
  final int amount;

  /// Collected when the picker ran, spent at confirm. The step-up belongs to
  /// the discount the manager actually looked at, not to the batch.
  final String? approverPin;

  const PendingLineDiscount({
    required this.presetId,
    required this.label,
    required this.amount,
    required this.approverPin,
  });
}

/// How the next payment carves up what is left. Chosen **per payment**, not per
/// bill (ADR-0067) — a table where two friends go halves and a third pays for
/// his own steak switches between these without anything being reset.
enum SettleMode {
  penuh(Icons.receipt_long_rounded),
  perItem(Icons.checklist_rounded),
  bagiRata(Icons.groups_rounded);

  final IconData icon;
  const SettleMode(this.icon);

  String label(AppL10n l10n) => switch (this) {
    SettleMode.penuh => l10n.stlModePenuh,
    SettleMode.perItem => l10n.stlModePerItem,
    SettleMode.bagiRata => l10n.stlModeBagiRata,
  };
}

/// The right-hand pane of the bill (ADR-0066): pick how much, then either
/// review an itemized receipt or pick how it was paid and confirm.
///
/// It mints the receipt at confirm time rather than up front, so a mode the
/// cashier tries and abandons leaves nothing behind on the bill.
class SettlePane extends StatefulWidget {
  final Bill bill;
  final SettlementRepository repo;

  /// Runs a mutation and surfaces failures on the parent's error line.
  final Future<void> Function(Future<Bill> Function()) run;

  /// Selected units per ticket, owned by the parent because the *lines* pane
  /// draws the selection and this pane prices it.
  final Map<String, int> selection;
  final SettleMode mode;
  final ValueChanged<SettleMode> onMode;
  final VoidCallback onClearSelection;

  /// ticketId → the line discount waiting for a receipt to exist (ADR-0126).
  /// Owned by the parent for the same reason [selection] is: the *lines* pane
  /// draws it and this pane spends it.
  final Map<String, PendingLineDiscount> pendingDiscounts;
  final VoidCallback onClearPending;

  /// Print the selection as a provisional [[Rincian pilihan]] slip before any
  /// money moves (ADR-0122). Nothing is minted — the guest checks the lines,
  /// then the cashier mints the same selection for discount review.
  final VoidCallback onPrintSelection;

  /// Whether the venue runs tabs at all (ADR-0098). Passed rather than watched
  /// because this pane holds no `WidgetRef`, and the parent already has one.
  final bool debtEnabled;

  const SettlePane({
    super.key,
    required this.bill,
    required this.repo,
    required this.run,
    required this.selection,
    required this.mode,
    required this.onMode,
    required this.onClearSelection,
    required this.pendingDiscounts,
    required this.onClearPending,
    required this.onPrintSelection,
    this.debtEnabled = false,
  });

  @override
  State<SettlePane> createState() => _SettlePaneState();
}

class _SettlePaneState extends State<SettlePane> {
  PayMethod _method = PayMethod.tunai;
  int _tender = 0;
  Uint8List? _proof;
  int _splitN = 2;
  bool _busy = false;

  /// The [[Pelanggan (member)]] who has accepted this `piutang` leg (ADR-0125).
  ///
  /// Not derived from the lines' [[Pemilik tiket]]: eating a dish is not
  /// agreeing to owe for it. The owner is only *suggested* — see
  /// [_suggestedDebtor] — and the cashier still confirms them through the
  /// lookup, which is also where the credit headroom comes from.
  MemberDto? _debtor;

  @override
  void didUpdateWidget(SettlePane old) {
    super.didUpdateWidget(old);
    // A new amount means the counted cash no longer refers to anything, and a
    // guest picked for a per-item share does not carry over to Bagi rata.
    if (old.mode != widget.mode) {
      setState(() {
        _tender = 0;
        _debtor = null;
      });
    }
  }

  Bill get _bill => widget.bill;

  /// What this payment will be recorded as. There is no lock to override it
  /// any more (ADR-0121) — every method is live on every payment.
  PayMethod get _pay => _method;

  /// The one [[Pemilik tiket]] every line about to be charged shares, or null
  /// when they differ or any is unowned. A suggestion for the debtor picker,
  /// never the debtor itself (ADR-0126).
  BillLine? get _suggestedDebtor {
    final ids = <String>{};
    BillLine? first;
    for (final l in _bill.lines) {
      if (widget.mode == SettleMode.perItem &&
          (widget.selection[l.ticketId] ?? 0) == 0) {
        continue;
      }
      if (l.memberId == null) return null;
      ids.add(l.memberId!);
      first ??= l;
    }
    return ids.length == 1 ? first : null;
  }

  /// Amount receipts already minted and still owing — Bagi rata pays the next
  /// one rather than re-splitting.
  List<BillReceipt> get _openShares => [
    for (final r in _bill.receipts)
      if (r.mode == 'even' && r.paidNet < r.total) r,
  ];

  /// The already-minted receipt **Penuh** will pay instead of minting a new
  /// one, or null when it mints.
  ///
  /// A reopened receipt still claims every line, so there is nothing left to
  /// mint from and `Penuh` used to sit at "nothing to charge" while the bill
  /// plainly owed money — the only way through was the struk row's own Bayar.
  /// One open receipt is an unambiguous target; two or more is a split, and a
  /// split is settled per struk by design.
  BillReceipt? get _penuhTarget {
    if (_remainder > 0) return null;
    final open = [
      for (final r in _bill.receipts)
        if (r.outstanding > 0) r,
    ];
    return open.length == 1 ? open.first : null;
  }

  /// What no receipt has claimed yet. Amount receipts are cut from this, never
  /// from the whole bill (ADR-0068).
  int get _remainder {
    final claimed = _bill.receipts.fold<int>(0, (a, r) => a + r.total);
    final left = _bill.total - claimed;
    return left < 0 ? 0 : left;
  }

  /// Gross value of the tapped units, before service, tax and any pending
  /// line discount.
  int get _selectionGross {
    var sum = 0;
    for (final l in _bill.lines) {
      final units = widget.selection[l.ticketId] ?? 0;
      sum += l.unitPrice * units;
    }
    return sum;
  }

  /// Pending line discounts on the tapped lines, previewed (ADR-0126). Clamped
  /// per line the way `recomputeBill` clamps the stack, so the pane can never
  /// quote a negative share.
  int get _pendingDiscount {
    var sum = 0;
    for (final l in _bill.lines) {
      final units = widget.selection[l.ticketId] ?? 0;
      if (units == 0) continue;
      final d = widget.pendingDiscounts[l.ticketId];
      if (d == null) continue;
      final base = l.unitPrice * units;
      sum += d.amount > base ? base : d.amount;
    }
    return sum;
  }

  /// What the tapped units are worth once the pending give-backs come off.
  int get _selectionSubtotal => _selectionGross - _pendingDiscount;

  /// The number the confirm button is about to take.
  int get _amount => switch (widget.mode) {
    // The whole remainder, capped by what is actually still owed — or the one
    // open receipt's own outstanding when nothing is left to mint from.
    SettleMode.penuh =>
      _penuhTarget?.outstanding ??
          (_bill.outstanding < _remainder ? _bill.outstanding : _remainder),
    // Priced at confirm by the server; this is the honest preview — the tapped
    // units plus their proportional share of service and tax.
    SettleMode.perItem => _grossUp(_selectionSubtotal),
    SettleMode.bagiRata =>
      _openShares.isNotEmpty ? _openShares.first.outstanding : _perHead,
  };

  int get _perHead {
    final shares = distributeEvenRounded(_remainder, _splitN);
    return shares.isEmpty ? 0 : shares.first;
  }

  /// Apply the bill's own effective service+tax rate to a raw subtotal. The
  /// rule lives on [Bill] so the printed [[Rincian pilihan]] slip cannot state
  /// a different figure from the button beneath it.
  int _grossUp(int subtotal) => _bill.prorate(subtotal);

  String? get _blocker {
    final l10n = context.l10n;
    if (_bill.lines.isEmpty) return l10n.stlBlkNoLines;
    if (_bill.outstanding == 0) return l10n.stlBlkNothingLeft;
    if (widget.mode == SettleMode.perItem && widget.selection.isEmpty) {
      return l10n.stlBlkPickItems;
    }
    if (_amount <= 0) return l10n.stlBlkNothingToCharge;
    if (_pay == PayMethod.tunai && _tender < _amount) {
      return l10n.stlBlkTapCash;
    }
    if (_pay.needsProof && _proof == null) {
      return l10n.stlBlkAttachProof;
    }
    if (_pay == PayMethod.piutang && _debtor == null) {
      return l10n.stlBlkPickDebtor;
    }
    if (_pay == PayMethod.piutang && _amount > _headroom) {
      return l10n.stlBlkOverCredit;
    }
    return null;
  }

  /// What may still go on the tab this payment would charge, resolved
  /// server-side and carried on the member. Zero when there is nobody to
  /// charge, or no credit left.
  int get _headroom => _debtor?.debtHeadroom ?? 0;

  Future<void> _shootProof() async {
    final l10n = context.l10n;
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (mounted) setState(() => _proof = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.stlPhotoFailed('$e'))));
      }
    }
  }

  /// Mint the receipt this mode implies, hang the pending line discounts on
  /// it, then pay it.
  ///
  /// A chain of calls rather than one fat endpoint, because every id it names
  /// is minted here (ADR-0123) — so each step can name the row the step before
  /// it made, online and captured alike, and the [[Antrean setelmen]] replays
  /// the same sequence with no new event kind.
  ///
  /// ponytail: not atomic. A refused discount (preset deleted, PIN rejected)
  /// leaves the receipt standing unpaid and visible in the struk list, which
  /// the cashier can pay or delete. Fold the discounts into `mintReceipt` if
  /// that refusal ever turns out to be common.
  Future<void> _confirm() async {
    if (_blocker != null || _busy) return;
    setState(() => _busy = true);
    final tender = _pay == PayMethod.tunai ? _tender : null;
    final fallback = _amount;
    try {
      await widget.run(() async {
        final receiptId = switch (widget.mode) {
          SettleMode.penuh =>
            _penuhTarget?.id ??
                (await widget.repo.mintReceipt(
                  _bill.visitId,
                  assignAll: true,
                )).receiptId,
          SettleMode.perItem => (await widget.repo.mintReceipt(
            _bill.visitId,
            lines: [
              for (final e in widget.selection.entries)
                BillReceiptLine(e.key, e.value),
            ],
          )).receiptId,
          SettleMode.bagiRata => await _nextShareId(),
        };
        // An even share owns no lines, so a line discount has nothing to hang
        // on — the server refuses one, and the picker never offers it there.
        var bill = _bill;
        if (widget.mode != SettleMode.bagiRata) {
          for (final e in widget.pendingDiscounts.entries) {
            if (widget.mode == SettleMode.perItem &&
                (widget.selection[e.key] ?? 0) == 0) {
              continue;
            }
            bill = await widget.repo.applyDiscount(
              receiptId,
              presetId: e.value.presetId,
              ticketId: e.key,
              approverPin: e.value.approverPin,
            );
          }
        }
        // Pay what the receipt actually came to, not the preview: the give-back
        // has landed by now and both sides run the same `recomputeBill`, so the
        // two agree — but the receipt is the one that decides.
        final rec = bill.receipts.where((r) => r.id == receiptId).firstOrNull;
        final amount = rec?.outstanding ?? fallback;
        return widget.repo.recordPayment(
          receiptId,
          method: _pay.id,
          amount: amount,
          tendered: tender,
          photoBase64: _proof == null ? null : base64Encode(_proof!),
          memberId: _pay == PayMethod.piutang ? _debtor?.id : null,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _tender = 0;
          _proof = null;
          _debtor = null;
        });
        widget.onClearSelection();
        widget.onClearPending();
      }
    }
  }

  /// The next unpaid share, splitting the remainder first if none exists yet.
  Future<String> _nextShareId() async {
    final open = _openShares;
    if (open.isNotEmpty) return open.first.id;
    final bill = await widget.repo.splitEven(_bill.visitId, _splitN);
    final minted = [
      for (final r in bill.receipts)
        if (r.mode == 'even' && r.paidNet < r.total) r,
    ];
    return minted.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _head(sc),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            children: [
              _modeRow(sc),
              const SizedBox(height: Sp.s3h),
              _modeBlock(sc),
              if (_pay == PayMethod.piutang) ...[
                const SizedBox(height: Sp.s3h),
                _debtorRow(sc),
              ],
              const SizedBox(height: Sp.s3h),
              _methodRow(sc),
              const SizedBox(height: Sp.s3),
              if (_pay == PayMethod.tunai)
                CashPad(
                  amount: _amount,
                  tender: _tender,
                  onTender: (v) => setState(() => _tender = v),
                )
              else if (_pay == PayMethod.piutang)
                _piutangBlock(sc)
              else
                _proofBlock(sc),
            ],
          ),
        ),
        _foot(sc),
      ],
    );
  }

  Widget _head(SatColors sc) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, Sp.s3h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.stlTitle, style: SatType.labelS(color: sc.textLo)),
        const SizedBox(height: Sp.s1),
        Text(formatIDR(_bill.outstanding), style: SatType.h2(color: sc.textHi)),
        const SizedBox(height: Sp.sHair),
        Text(
          context.l10n.stlOutstandingHint,
          style: SatType.bodyS(color: sc.textLo),
        ),
      ],
    ),
  );

  Widget _modeRow(SatColors sc) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(context.l10n.fltModes, style: SatType.labelS(color: sc.textLo)),
      const SizedBox(height: Sp.s2),
      SatDropdown<SettleMode>(
        key: ValueKey(widget.mode),
        value: widget.mode,
        fillColor: sc.bg1,
        options: [
          for (final m in SettleMode.values)
            SatOption(
              m,
              m.label(context.l10n),
              icon: m.icon,
              iconColor: sc.textHi,
            ),
        ],
        onChanged: (m) {
          if (m != null) widget.onMode(m);
        },
      ),
    ],
  );

  Widget _modeBlock(SatColors sc) {
    final l10n = context.l10n;
    Widget row(String l, String v, {bool strong = false}) => Padding(
      padding: const EdgeInsets.only(bottom: Sp.s1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l,
              style: strong
                  ? SatType.labelM(color: sc.textHi)
                  : SatType.bodyS(color: sc.textLo),
            ),
          ),
          Text(
            v,
            style: strong
                ? SatType.monoM(color: sc.textHi)
                : SatType.monoS(color: sc.textMd),
          ),
        ],
      ),
    );

    final children = switch (widget.mode) {
      SettleMode.penuh => [
        row(l10n.stlRowTotal, formatIDR(_bill.total)),
        if (_bill.paidAmount > 0)
          row(l10n.stlRowAlreadyPaid, '− ${formatIDR(_bill.paidAmount)}'),
        row(l10n.stlRowReceivingNow, formatIDR(_amount), strong: true),
      ],
      SettleMode.perItem =>
        widget.selection.isEmpty
            ? [
                Text(
                  l10n.stlPerItemEmpty,
                  style: SatType.bodyS(color: sc.textLo),
                ),
              ]
            : [
                row(
                  l10n.stlRowNItems(widget.selection.length),
                  formatIDR(_selectionGross),
                ),
                // Stated as its own line rather than folded into the subtotal:
                // the guest is being told what came off, and a quote that just
                // looks cheap is the one they query at the till (ADR-0126).
                if (_pendingDiscount > 0)
                  row(
                    l10n.stlRowLineDiscounts,
                    '-${formatIDR(_pendingDiscount)}',
                  ),
                row(
                  l10n.stlRowServiceTax,
                  formatIDR(_amount - _selectionSubtotal),
                ),
                row(l10n.stlRowPayingNow, formatIDR(_amount), strong: true),
                row(
                  l10n.stlRowRemainderAfter,
                  formatIDR(
                    (_bill.outstanding - _amount).clamp(0, _bill.outstanding),
                  ),
                ),
                const SizedBox(height: Sp.s2h),
                // Hand the guest the lines before taking their money. The slip
                // mints nothing, so the selection survives the print and the
                // confirm below charges exactly what was on the paper.
                SatButton.ghost(
                  label: l10n.stlPrintSelection,
                  icon: Icons.print_rounded,
                  onTap: widget.onPrintSelection,
                ),
              ],
      SettleMode.bagiRata => [
        if (_openShares.isEmpty) ...[
          _splitStepper(sc),
          const SizedBox(height: Sp.s2h),
          row(l10n.stlRowPerHead, formatIDR(_perHead)),
        ] else
          row(
            l10n.stlRowOpenShares(_openShares.length),
            _openShares.first.label,
          ),
        row(l10n.stlRowChargeNow, formatIDR(_amount), strong: true),
        row(
          l10n.stlRowRemainderAfter,
          formatIDR((_bill.outstanding - _amount).clamp(0, _bill.outstanding)),
        ),
      ],
    };

    return Container(
      padding: const EdgeInsets.all(Sp.s3),
      decoration: SatBox.d(color: sc.bg2, borderRadius: SatR.a(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _splitStepper(SatColors sc) => Row(
    children: [
      Expanded(
        child: Text(
          context.l10n.stlSplitFor,
          style: SatType.bodyS(color: sc.textLo),
        ),
      ),
      SatButton.outline(
        label: '−',
        size: SatButtonSize.sm,
        onTap: _splitN <= 2 ? null : () => setState(() => _splitN--),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.s3),
        child: Text('$_splitN', style: SatType.monoM(color: sc.textHi)),
      ),
      SatButton.outline(
        label: '+',
        size: SatButtonSize.sm,
        onTap: _splitN >= 12 ? null : () => setState(() => _splitN++),
      ),
    ],
  );

  /// Every method, on every payment. The bill-wide tender lock that used to
  /// collapse this row is gone (ADR-0121) — the row itself lives in
  /// [PayMethodPicker], shared with the per-struk pay sheet so the two cannot
  /// offer different methods for the same act.
  Widget _methodRow(SatColors sc) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(context.l10n.stlMethod, style: SatType.labelS(color: sc.textLo)),
      const SizedBox(height: Sp.s2),
      PayMethodPicker(
        selected: _pay,
        onPick: _pick,
        debtEnabled: widget.debtEnabled,
        debtor: _debtor,
        debtorPickable: true,
      ),
    ],
  );

  /// Who has taken this `piutang` leg on their tab (ADR-0125).
  ///
  /// When every line about to be charged belongs to one [[Pemilik tiket]] the
  /// row offers them as a suggestion — one tap into a pre-filtered lookup, not
  /// a silent fill. Debt follows the person who agrees to owe, so it is always
  /// confirmed; the lookup is also where the credit headroom comes from.
  Widget _debtorRow(SatColors sc) {
    final l10n = context.l10n;
    final suggestion = _debtor == null ? _suggestedDebtor : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.stlDebtor, style: SatType.labelS(color: sc.textLo)),
        const SizedBox(height: Sp.s2),
        Row(
          children: [
            Expanded(
              child: Text(
                _debtor?.name ?? l10n.stlDebtorUnset,
                style: SatType.bodyM(
                  color: _debtor == null ? sc.textLo : sc.textHi,
                ),
              ),
            ),
            const SizedBox(width: Sp.s2),
            SatButton.outline(
              size: SatButtonSize.sm,
              label: l10n.cshMemberFind,
              onTap: () => _pickDebtor(),
            ),
            if (_debtor != null) ...[
              const SizedBox(width: Sp.s2),
              SatButton.neutral(
                size: SatButtonSize.sm,
                label: l10n.cshMemberDetach,
                onTap: () => setState(() {
                  _debtor = null;
                  // The tab may have been reachable only through them.
                  _method = PayMethod.tunai;
                }),
              ),
            ],
          ],
        ),
        if (suggestion?.memberName != null) ...[
          const SizedBox(height: Sp.s2),
          SatButton.ghost(
            size: SatButtonSize.sm,
            icon: Icons.badge_outlined,
            label: l10n.stlDebtorSuggest(suggestion!.memberName!),
            onTap: () => _pickDebtor(query: suggestion.memberName),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDebtor({String? query}) async {
    final picked = await showSatSheet<MemberDto>(
      context,
      builder: (_) => MemberLookupSheet(initialQuery: query),
    );
    if (picked == null || !mounted) return;
    setState(() => _debtor = picked);
  }

  void _pick(PayMethod m) => setState(() {
    _method = m;
    _tender = 0;
    _proof = null;
  });

  /// No pad, no camera — a tab takes neither. The credit left is the one number
  /// that decides whether this goes through, so it is the one on screen.
  Widget _piutangBlock(SatColors sc) => Container(
    padding: const EdgeInsets.all(Sp.s3),
    decoration: SatBox.d(color: sc.bg2, borderRadius: SatR.a(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.stlPiutangHint,
          style: SatType.bodyS(color: sc.textLo),
        ),
        const SizedBox(height: Sp.s2),
        Text(
          context.l10n.stlPiutangLeft(formatIDR(_headroom)),
          style: SatType.mono(color: _amount > _headroom ? sc.warn : sc.textHi),
        ),
      ],
    ),
  );

  Widget _proofBlock(SatColors sc) => Container(
    padding: const EdgeInsets.all(Sp.s3),
    decoration: SatBox.d(color: sc.bg2, borderRadius: SatR.a(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _method.proofHint(context.l10n),
          style: SatType.bodyS(color: sc.textLo),
        ),
        const SizedBox(height: Sp.s2h),
        if (_proof != null) ...[
          Row(
            children: [
              ClipRRect(
                borderRadius: SatR.a(8),
                child: Image.memory(
                  _proof!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: Sp.s3),
              Expanded(
                child: Text(
                  context.l10n.stlProofAttached,
                  style: SatType.labelM(color: sc.textHi),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s2h),
          SatButton.outline(
            label: context.l10n.stlRetakePhoto,
            icon: Icons.photo_camera_rounded,
            onTap: _shootProof,
          ),
        ] else
          SatButton.outline(
            label: context.l10n.stlTakePhoto,
            icon: Icons.photo_camera_rounded,
            onTap: _shootProof,
          ),
      ],
    ),
  );

  /// One primary, and a line saying why it is disabled. The hint is the whole
  /// point: a greyed button with no reason is the commonest way a cashier gets
  /// stuck mid-transaction.
  Widget _foot(SatColors sc) {
    final blocker = _blocker;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: SatBox.d(
        color: sc.bg1,
        border: Border(top: SatB.side(color: sc.border0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SatButton.primary(
            label: switch (widget.mode) {
              SettleMode.perItem => context.l10n.stlConfirmItems(
                widget.selection.length,
                formatIDR(_amount),
              ),
              SettleMode.bagiRata => context.l10n.stlConfirmShare(
                formatIDR(_amount),
              ),
              SettleMode.penuh => context.l10n.stlConfirmFull(
                formatIDR(_amount),
              ),
            },
            icon: Icons.check_rounded,
            busy: _busy,
            onTap: blocker == null ? _confirm : null,
          ),
          const SizedBox(height: Sp.s1h),
          Text(
            blocker ?? context.l10n.stlAutoPrintHint,
            style: SatType.labelS(color: blocker == null ? sc.textLo : sc.warn),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
