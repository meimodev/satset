import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/domain/use_cases/bill_math.dart';
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
  penuh('Penuh', Icons.receipt_long_rounded, 'Satu pembayaran untuk sisa'),
  perItem('Per item', Icons.checklist_rounded, 'Tamu bayar item yang dia pesan'),
  bagiRata('Bagi rata', Icons.groups_rounded, 'Sisa dibagi rata beberapa orang');

  final String label;
  final IconData icon;
  final String hint;
  const SettleMode(this.label, this.icon, this.hint);
}

/// Payment methods, and what the cashier has to produce for each. The hint is
/// the source's, and it earns its line: it says *why* the proof block below is
/// blocking the confirm.
enum PayMethod {
  tunai('tunai', 'Tunai', SatChipHue.success, 'Hitung uang tamu di papan pecahan'),
  qris('qris', 'QRIS', SatChipHue.accent, 'Screenshot konfirmasi QRIS wajib dilampirkan'),
  kartu('kartu', 'Kartu', SatChipHue.info, 'Foto slip EDC — approval code terlihat'),
  transfer('transfer', 'Transfer', SatChipHue.violet, 'Foto bukti transfer + nama pengirim'),
  lainnya('lainnya', 'Lainnya', SatChipHue.neutral, 'Foto bukti pembayaran');

  final String id;
  final String label;
  final SatChipHue hue;
  final String proofHint;
  const PayMethod(this.id, this.label, this.hue, this.proofHint);

  bool get needsProof => this != PayMethod.tunai;
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

  const SettlePane({
    super.key,
    required this.bill,
    required this.repo,
    required this.run,
    required this.selection,
    required this.mode,
    required this.onMode,
    required this.onClearSelection,
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

  /// Amount receipts already minted and still owing — Bagi rata pays the next
  /// one rather than re-splitting.
  List<BillReceipt> get _openShares => [
    for (final r in _bill.receipts)
      if (r.mode == 'even' && r.paidNet < r.total) r,
  ];

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
    // The whole remainder, capped by what is actually still owed.
    SettleMode.penuh =>
      _bill.outstanding < _remainder ? _bill.outstanding : _remainder,
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
    if (_bill.lines.isEmpty) return 'Tagihan belum punya item';
    if (_bill.outstanding == 0) return 'Tidak ada sisa untuk ditagih';
    if (widget.mode == SettleMode.perItem && widget.selection.isEmpty) {
      return 'Pilih item dari daftar';
    }
    if (_amount <= 0) return 'Tidak ada yang bisa ditagih';
    if (_method == PayMethod.tunai && _tender < _amount) {
      return 'Ketuk pecahan uang yang diterima';
    }
    if (_method.needsProof && _proof == null) {
      return 'Lampirkan foto bukti bayar dulu';
    }
    return null;
  }

  Future<void> _shootProof() async {
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
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
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
    final tender = _method == PayMethod.tunai ? _tender : null;
    try {
      await widget.run(() async {
        final receiptId = switch (widget.mode) {
          SettleMode.penuh => (await widget.repo.mintReceipt(
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
          method: _method.id,
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
              if (_method == PayMethod.tunai)
                CashPad(
                  amount: _amount,
                  tender: _tender,
                  onTender: (v) => setState(() => _tender = v),
                )
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
        Text('Penyelesaian', style: SatType.labelS(color: sc.textLo)),
        const SizedBox(height: Sp.s1),
        Text(formatIDR(_bill.outstanding), style: SatType.h2(color: sc.textHi)),
        const SizedBox(height: Sp.sHair),
        Text(
          'sisa yang harus ditagih',
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
          label: m.label,
          icon: m.icon,
          selected: widget.mode == m,
          onTap: () => widget.onMode(m),
        ),
    ],
  );

  Widget _modeBlock(SatColors sc) {
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
        row('Total tagihan', formatIDR(_bill.total)),
        if (_bill.paidAmount > 0)
          row('Sudah diterima', '− ${formatIDR(_bill.paidAmount)}'),
        row('Diterima sekarang', formatIDR(_amount), strong: true),
      ],
      SettleMode.perItem => widget.selection.isEmpty
          ? [
              Text(
                'Ketuk item yang dibayar tamu ini. Item yang sudah lunas '
                'terkunci.',
                style: SatType.bodyS(color: sc.textLo),
              ),
            ]
          : [
              row('${widget.selection.length} item', formatIDR(_selectionSubtotal)),
              row(
                'Layanan + pajak',
                formatIDR(_amount - _selectionSubtotal),
              ),
              row('Dibayar sekarang', formatIDR(_amount), strong: true),
              row(
                'Sisa setelah ini',
                formatIDR(
                  (_bill.outstanding - _amount).clamp(0, _bill.outstanding),
                ),
              ),
            ],
      SettleMode.bagiRata => [
        if (_openShares.isEmpty) ...[
          _splitStepper(sc),
          const SizedBox(height: Sp.s2h),
          row('Per orang (bulat 100)', formatIDR(_perHead)),
        ] else
          row(
            '${_openShares.length} bagian belum bayar',
            _openShares.first.label,
          ),
        row('Tagih sekarang', formatIDR(_amount), strong: true),
        row(
          'Sisa setelah ini',
          formatIDR((_bill.outstanding - _amount).clamp(0, _bill.outstanding)),
        ),
      ],
    };

    return Container(
      padding: const EdgeInsets.all(Sp.s3),
      decoration: SatBox.d(color: sc.bg2, borderRadius: SatR.a(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _splitStepper(SatColors sc) => Row(
    children: [
      Expanded(
        child: Text('Bagi untuk', style: SatType.bodyS(color: sc.textLo)),
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

  Widget _methodRow(SatColors sc) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Metode', style: SatType.labelS(color: sc.textLo)),
      const SizedBox(height: Sp.s2),
      Wrap(
        spacing: Sp.s2,
        runSpacing: Sp.s2,
        children: [
          for (final m in PayMethod.values)
            SatChip.select(
              label: m.label,
              selected: _method == m,
              onTap: () => setState(() {
                _method = m;
                _tender = 0;
                _proof = null;
              }),
            ),
        ],
      ),
    ],
  );

  Widget _proofBlock(SatColors sc) => Container(
    padding: const EdgeInsets.all(Sp.s3),
    decoration: SatBox.d(color: sc.bg2, borderRadius: SatR.a(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_method.proofHint, style: SatType.bodyS(color: sc.textLo)),
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
                  'Bukti terlampir',
                  style: SatType.labelM(color: sc.textHi),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s2h),
          SatButton.outline(
            label: 'Ambil ulang',
            icon: Icons.photo_camera_rounded,
            onTap: _shootProof,
          ),
        ] else
          SatButton.outline(
            label: 'Ambil foto bukti bayar',
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
              SettleMode.perItem =>
                'Terima ${widget.selection.length} item · ${formatIDR(_amount)}',
              SettleMode.bagiRata => 'Terima bagian · ${formatIDR(_amount)}',
              SettleMode.penuh => 'Terima ${formatIDR(_amount)}',
            },
            icon: Icons.check_rounded,
            busy: _busy,
            onTap: blocker == null ? _confirm : null,
          ),
          const SizedBox(height: Sp.s1h),
          Text(
            blocker ?? 'Struk tercetak otomatis setelah dikonfirmasi',
            style: SatType.labelS(
              color: blocker == null ? sc.textLo : sc.warn,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
