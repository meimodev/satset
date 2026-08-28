import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/repositories/members_repository.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';
import 'package:satset/ui/features/admin/members_screen.dart';
import 'package:satset/ui/features/cashier/widgets/settle_pane.dart';
import 'package:satset/ui/features/printing/printer_picker.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';

/// Take money against a [[Piutang]] tab (ADR-0098).
///
/// The one collection surface that starts from nobody's bill: a member may walk
/// in only to settle up, with nothing seated and nothing open. So it opens on
/// the debtor list rather than a search box — who owes is the question, and the
/// venue already knows the answer.
Future<void> showDebtCollectSheet(BuildContext context) =>
    showSatSheet<void>(context, builder: (_) => const _DebtCollectSheet());

class _DebtCollectSheet extends ConsumerStatefulWidget {
  const _DebtCollectSheet();

  @override
  ConsumerState<_DebtCollectSheet> createState() => _DebtCollectSheetState();
}

class _DebtCollectSheetState extends ConsumerState<_DebtCollectSheet> {
  Debtor? _who;

  @override
  Widget build(BuildContext context) => _who == null
      ? _DebtorPicker(onPick: (d) => setState(() => _who = d))
      : _CollectForm(debtor: _who!, onBack: () => setState(() => _who = null));
}

/// Everyone who owes, largest first. A prefix search sits on top for the venue
/// whose list has outgrown one screen.
class _DebtorPicker extends ConsumerStatefulWidget {
  final ValueChanged<Debtor> onPick;
  const _DebtorPicker({required this.onPick});

  @override
  ConsumerState<_DebtorPicker> createState() => _DebtorPickerState();
}

class _DebtorPickerState extends ConsumerState<_DebtorPicker> {
  final _q = TextEditingController();
  Future<List<Debtor>>? _load;

  @override
  void initState() {
    super.initState();
    _load = ref.read(membersProvider.notifier).debtors();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<Debtor> _filter(List<Debtor> all) {
    final q = _q.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final d in all)
        if (d.name.toLowerCase().contains(q) || d.phone.contains(q)) d,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Sp.s5,
          0,
          Sp.s5,
          MediaQuery.of(context).viewInsets.bottom + Sp.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SatSheetHeader(
              padding: const EdgeInsets.fromLTRB(0, Sp.s3, 0, Sp.s2),
              onClose: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cshDebtCollect,
                style: SatType.h3(color: sc.textHi),
              ),
            ),
            SatField.search(
              controller: _q,
              hint: l10n.memSearchHint,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Sp.s3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: FutureBuilder<List<Debtor>>(
                future: _load,
                builder: (_, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: SatSpinner(size: SatSpinnerSize.md),
                    );
                  }
                  final rows = _filter(snap.data ?? const []);
                  if (rows.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.cshDebtNobody,
                        style: SatType.bodyS(color: sc.textLo),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Sp.s1h),
                    itemBuilder: (_, i) => SatButton.outline(
                      label: '${rows[i].name} · ${formatIDR(rows[i].balance)}',
                      onTap: () => widget.onPick(rows[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How much, how, and the proof. Deliberately the same vocabulary as the settle
/// pane — a cashier who can take a bill can take a tab payment without learning
/// a second form.
class _CollectForm extends ConsumerStatefulWidget {
  final Debtor debtor;
  final VoidCallback onBack;
  const _CollectForm({required this.debtor, required this.onBack});

  @override
  ConsumerState<_CollectForm> createState() => _CollectFormState();
}

class _CollectFormState extends ConsumerState<_CollectForm> {
  late final TextEditingController _amount = TextEditingController(
    text: groupRupiah(widget.debtor.balance),
  );
  final _note = TextEditingController();
  PayMethod _method = PayMethod.tunai;
  Uint8List? _proof;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _value =>
      int.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String? get _blocker {
    final l10n = context.l10n;
    if (_value <= 0) return l10n.stlBlkNothingToCharge;
    if (_value > widget.debtor.balance) return l10n.cshDebtOver;
    if (_method.needsProof && _proof == null) return l10n.stlBlkAttachProof;
    return null;
  }

  Future<void> _shoot() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (mounted) setState(() => _proof = bytes);
  }

  Future<void> _submit() async {
    if (_blocker != null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final amount = _value;
    try {
      final after = await ref
          .read(membersProvider.notifier)
          .payDebt(
            id: widget.debtor.memberId,
            amount: amount,
            method: _method.id,
            photoBase64: _proof == null ? null : base64Encode(_proof!),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      // The slip is the guest's only evidence — no bill, nothing on a table.
      // Offered after the money is booked, so a dismissed preview cannot undo
      // a collection that already happened.
      await printDebtSlip(
        context: context,
        ref: ref,
        memberName: widget.debtor.name,
        amount: amount,
        method: _method.id,
        balanceAfter: after.balance,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = memberErrorText(context.l10n, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final blocker = _blocker;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Sp.s5,
          0,
          Sp.s5,
          MediaQuery.of(context).viewInsets.bottom + Sp.s5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SatSheetHeader(
                padding: const EdgeInsets.fromLTRB(0, Sp.s3, 0, Sp.s2),
                onClose: widget.onBack,
                child: Text(
                  widget.debtor.name,
                  style: SatType.h3(color: sc.textHi),
                ),
              ),
              Text(
                l10n.cshDebtOwes(formatIDR(widget.debtor.balance)),
                style: SatType.monoL(color: sc.warn),
              ),
              const SizedBox(height: Sp.s4),
              SatField.money(
                controller: _amount,
                label: l10n.cshDebtAmount,
                hint: '0',
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Sp.s3),
              Text(l10n.stlMethod, style: SatType.labelS(color: sc.textLo)),
              const SizedBox(height: Sp.s2),
              Wrap(
                spacing: Sp.s2,
                runSpacing: Sp.s2,
                children: [
                  for (final m in PayMethod.values)
                    // A tab cannot pay a tab.
                    if (m != PayMethod.piutang)
                      SatChip.select(
                        label: m.label(l10n),
                        selected: _method == m,
                        onTap: () => setState(() {
                          _method = m;
                          _proof = null;
                        }),
                      ),
                ],
              ),
              if (_method.needsProof) ...[
                const SizedBox(height: Sp.s3),
                SatButton.outline(
                  label: _proof == null
                      ? _method.proofHint(l10n)
                      : l10n.stlProofAttached,
                  icon: Icons.photo_camera_rounded,
                  onTap: _shoot,
                ),
              ],
              const SizedBox(height: Sp.s3),
              SatField.text(
                controller: _note,
                label: l10n.cshDebtNote,
                hint: '',
              ),
              if (_error != null) ...[
                const SizedBox(height: Sp.s3),
                Text(_error!, style: SatType.bodyS(color: sc.urgent)),
              ],
              const SizedBox(height: Sp.s4),
              SatButton.primary(
                label: blocker ?? l10n.cshDebtTake(formatIDR(_value)),
                icon: Icons.payments_rounded,
                onTap: blocker != null || _busy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
