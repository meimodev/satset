import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:satset/data/models/bill_dto.dart';
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
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/features/cashier/widgets/cash_pad.dart';

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

/// Payment methods, and what the cashier has to produce for each.
enum PayMethod {
  tunai('tunai'),
  qris('qris'),
  kartu('kartu'),
  transfer('transfer'),
  lainnya('lainnya'),

  /// Not money — the receipt's claim moves to the member's [[Piutang]] ledger
  /// (ADR-0098). No proof photo exists for a promise, and nothing is tendered.
  piutang('piutang');

  final String id;
  const PayMethod(this.id);

  bool get needsProof => this != PayMethod.tunai && this != PayMethod.piutang;

  String label(AppL10n l10n) => switch (this) {
    PayMethod.tunai => l10n.stlPayTunai,
    PayMethod.qris => l10n.stlPayQris,
    PayMethod.kartu => l10n.stlPayKartu,
    PayMethod.transfer => l10n.stlPayTransfer,
    PayMethod.lainnya => l10n.stlPayLainnya,
    PayMethod.piutang => l10n.payMethodOnAccount,
  };

  /// What the cashier has to produce for this method. It earns its line: it
  /// says *why* the proof block below is blocking the confirm.
  String proofHint(AppL10n l10n) => switch (this) {
    PayMethod.tunai => l10n.stlProofTunai,
    PayMethod.qris => l10n.stlProofQris,
    PayMethod.kartu => l10n.stlProofKartu,
    PayMethod.transfer => l10n.stlProofTransfer,
    PayMethod.lainnya => l10n.stlProofLainnya,
    PayMethod.piutang => l10n.stlPiutangHint,
  };
}

/// The method every later payment on this bill is bound to, or null while
/// nobody has paid. The first tender sets the rule for the rest of the bill:
/// a guest who pays half in cash and half by card can't be settled at this
/// till, which is the point — a split-tender bill reconciles against neither
/// drawer nor statement cleanly.
///
/// Read across every receipt, not just one: each mode mints its own receipt
/// (ADR-0067), so a per-receipt reading would almost never fire. Refunds carry
/// a method too and are skipped — giving money back doesn't decide how the next
/// lot comes in.
///
/// Piutang sits outside the rule entirely — it is not money and reconciles
/// against no drawer and no statement, so it neither sets the lock nor is
/// stopped by one. Part cash, part tab is the case the feature exists for.
///
/// Top-level because the per-receipt pay sheet on the bill screen has to answer
/// the same question: a lock the settle pane enforces and the sheet ignores is
/// no lock, just a longer way round it.
PayMethod? lockedMethodFor(Bill bill) {
  BillPayment? latest;
  for (final r in bill.receipts) {
    for (final p in r.payments) {
      if (p.isRefund || p.method == PayMethod.piutang.id) continue;
      if (latest == null || p.at.isAfter(latest.at)) latest = p;
    }
  }
  if (latest == null) return null;
  for (final m in PayMethod.values) {
    if (m.id == latest.method) return m;
  }
  // A string the enum doesn't know can only come from a server that has moved
  // on. Fail open rather than lock the cashier out of a method that isn't even
  // on screen.
  return null;
}

/// The right-hand pane of the bill (ADR-0066): pick how much, pick how it was
/// paid, prove it, confirm.
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

  @override
  void didUpdateWidget(SettlePane old) {
    super.didUpdateWidget(old);
    // A new amount means the counted cash no longer refers to anything.
    if (old.mode != widget.mode) setState(() => _tender = 0);
  }

  Bill get _bill => widget.bill;

  PayMethod? get _lockedMethod => lockedMethodFor(_bill);

  /// What this payment will actually be recorded as — the lock if there is one,
  /// otherwise whatever the cashier tapped.
  PayMethod get _pay =>
      _method == PayMethod.piutang ? _method : (_lockedMethod ?? _method);

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

  /// Gross value of the tapped units, before service and tax.
  int get _selectionSubtotal {
    var sum = 0;
    for (final l in _bill.lines) {
      final units = widget.selection[l.ticketId] ?? 0;
      sum += l.unitPrice * units;
    }
    return sum;
  }

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

  /// Apply the bill's own effective service+tax rate to a raw subtotal. Derived
  /// from the bill rather than re-read from settings, so a preview can never
  /// disagree with the total printed above it.
  int _grossUp(int subtotal) {
    if (subtotal <= 0) return 0;
    final base = _bill.subtotal;
    if (base <= 0) return subtotal;
    return (subtotal * _bill.total / base).round();
  }

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
    if (_pay == PayMethod.piutang && _amount > _headroom) {
      return l10n.stlBlkOverCredit;
    }
    return null;
  }

  /// What may still go on this member's tab, resolved server-side and carried
  /// on the bill. Zero when there is no member, or no credit left.
  int get _headroom => _bill.member?.debtHeadroom ?? 0;

  /// Why the Piutang chip is off, or null when it is live. A reason on screen
  /// beats a greyed-out chip — Principle 3.
  String? _piutangOff(AppL10n l10n) {
    if (_bill.member == null) return l10n.stlPiutangNoMember;
    if (_headroom <= 0) return l10n.stlPiutangNoRoom;
    return null;
  }

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

  /// Mint the receipt this mode implies, then pay it. Two calls, but the mint
  /// is transactional server-side (`createReceipt(lines:)`), so a failure can
  /// never leave a half-assigned receipt on the bill.
  Future<void> _confirm() async {
    if (_blocker != null || _busy) return;
    setState(() => _busy = true);
    final amount = _amount;
    final tender = _pay == PayMethod.tunai ? _tender : null;
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
        return widget.repo.recordPayment(
          receiptId,
          method: _pay.id,
          amount: amount,
          tendered: tender,
          photoBase64: _proof == null ? null : base64Encode(_proof!),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _tender = 0;
          _proof = null;
        });
        widget.onClearSelection();
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

  /// Three options that all fit, so a chip row rather than a bespoke control
  /// (`CATALOG.md`). The selected fill is `SatChip.select`'s own, which
  /// ADR-0051 already settled as the app's selection grammar.
  Widget _modeRow(SatColors sc) => Wrap(
    spacing: Sp.s2,
    runSpacing: Sp.s2,
    children: [
      for (final m in SettleMode.values)
        SatChip.select(
          label: m.label(context.l10n),
          icon: m.icon,
          selected: widget.mode == m,
          onTap: () => widget.onMode(m),
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
                  formatIDR(_selectionSubtotal),
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

  /// Once the bill is part-paid the row collapses to the one method that is
  /// still allowed, rather than greying the other four. A chip that looks
  /// tappable and swallows the tap is how a cashier mid-rush decides the app
  /// has frozen; a row with one chip in it explains itself.
  Widget _methodRow(SatColors sc) {
    final l10n = context.l10n;
    final locked = _lockedMethod;
    final offReason = _piutangOff(l10n);
    // The money methods, then the tab. A lock hides the money ones it excludes;
    // Piutang stands apart from the lock, and shows disabled with its reason
    // rather than vanishing — a cashier who cannot find the chip cannot learn
    // why it is unavailable.
    final money = [
      for (final m in PayMethod.values)
        if (m != PayMethod.piutang && (locked == null || m == locked)) m,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.stlMethod, style: SatType.labelS(color: sc.textLo)),
        const SizedBox(height: Sp.s2),
        Wrap(
          spacing: Sp.s2,
          runSpacing: Sp.s2,
          children: [
            for (final m in money)
              SatChip.select(
                label: m.label(l10n),
                selected: _pay == m,
                onTap: locked != null ? null : () => _pick(m),
              ),
            if (widget.debtEnabled)
              SatChip.select(
                label: PayMethod.piutang.label(l10n),
                selected: _pay == PayMethod.piutang,
                onTap: offReason != null
                    ? null
                    : () => _pick(PayMethod.piutang),
              ),
          ],
        ),
        if (locked != null) ...[
          const SizedBox(height: Sp.s2),
          Text(
            l10n.stlLockedTo(locked.label(l10n)),
            style: SatType.bodyS(color: sc.textLo),
          ),
        ],
        if (widget.debtEnabled && offReason != null) ...[
          const SizedBox(height: Sp.s2),
          Text(offReason, style: SatType.bodyS(color: sc.textLo)),
        ],
      ],
    );
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
