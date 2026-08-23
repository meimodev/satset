import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:satset/core/localization/labels.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/cash_repository.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/cash_entry.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/payment_proof_thumb.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';
import '_common.dart';
import 'package:satset/core/time/sat_clock.dart';

/// "Kas kecil" — the petty cash box (§Kas kecil).
///
/// One append-only ledger and the balance it derives. Not the drawer: nothing
/// on this screen touches a bill, a payment or revenue (ADR-0089).
///
/// Tablet only, like the venue log and for the same reason: the value of a
/// ledger is reading a column of movements against each other, and a phone can
/// show a row or a balance but not the shape of the week.
class KasScreen extends ConsumerStatefulWidget {
  const KasScreen({super.key});

  @override
  ConsumerState<KasScreen> createState() => _KasScreenState();
}

class _KasScreenState extends ConsumerState<KasScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 400) {
      ref.read(cashProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.layout.useTabletShell) return const _KasPhoneNotice();

    final l10n = context.l10n;
    final state = ref.watch(cashProvider);
    final auth = ref.watch(authStateProvider);
    final canSpend = auth.has(Capability.manageCash);
    final canFund = auth.has(Capability.editSettings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminEmbeddedStrip(
          title: l10n.kasTitle,
          sub: _countLine(l10n, state),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canFund)
                SatButton.outline(
                  label: l10n.kasActionTopUp,
                  icon: Icons.add_rounded,
                  size: SatButtonSize.sm,
                  onTap: () => _post(CashEntryKind.topUp),
                ),
              if (canSpend) ...[
                const SizedBox(width: Sp.s2),
                SatButton.outline(
                  label: l10n.kasActionExpense,
                  icon: Icons.receipt_long_outlined,
                  size: SatButtonSize.sm,
                  onTap: () => _post(CashEntryKind.expense),
                ),
              ],
              if (canFund) ...[
                const SizedBox(width: Sp.s2),
                SatButton.primary(
                  label: l10n.kasActionCount,
                  icon: Icons.savings_outlined,
                  size: SatButtonSize.sm,
                  onTap: () => _post(CashEntryKind.count),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref.read(cashProvider.notifier).refresh,
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Sp.s7,
                      Sp.s6,
                      Sp.s7,
                      Sp.s4,
                    ),
                    child: _BalanceHero(balance: state.balance),
                  ),
                ),
                if (state.entries.isEmpty && !state.loading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(Sp.s7),
                      child: SatEmpty(
                        icon: Icons.savings_outlined,
                        title: l10n.kasEmptyTitle,
                        body: l10n.kasEmptyBody,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(Sp.s7, 0, Sp.s7, Sp.s7),
                    sliver: SliverList.separated(
                      itemCount: state.entries.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: Sp.s1h),
                      itemBuilder: (_, i) => _KasRow(
                        entry: state.entries[i],
                        onTap: () => _detail(state.entries[i]),
                      ),
                    ),
                  ),
                if (state.capped)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sp.s7,
                        vertical: Sp.s4,
                      ),
                      child: Text(
                        l10n.logCapNotice(kCashMaxLoaded),
                        textAlign: TextAlign.center,
                        style: SatType.caption(color: context.sat.textDim),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The strip's second line: how stale the count is. The balance is on the
  /// hero; what a manager cannot see from the number is when anyone last
  /// checked it against the notes in the box.
  String _countLine(AppL10n l10n, CashState state) {
    final at = state.lastCountAt;
    if (at == null) return l10n.kasNeverCounted;
    return l10n.kasLastCount(
      formatElapsed(l10n, SatClock.now().difference(at)),
    );
  }

  Future<void> _post(CashEntryKind kind, {CashEntry? target}) =>
      showSatSheet<void>(
        context,
        builder: (_) => _PostSheet(kind: kind, target: target),
      );

  Future<void> _detail(CashEntry entry) => showSatSheet<void>(
    context,
    builder: (_) => _DetailSheet(
      entry: entry,
      onReverse: () => _post(CashEntryKind.reversal, target: entry),
    ),
  );
}

/// The balance, at the size a number this consequential deserves. Never summed
/// client-side — see [CashState.balance].
class _BalanceHero extends StatelessWidget {
  final int balance;
  const _BalanceHero({required this.balance});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.all(Sp.s5),
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: SatR.a(14),
        border: SatB.all(color: sc.border1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Sp.s3),
            decoration: SatBox.d(color: sc.infoSoft, shape: BoxShape.circle),
            child: Icon(Icons.savings_outlined, color: sc.info),
          ),
          const SizedBox(width: Sp.s4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.kasBalance.toUpperCase(),
                style: SatType.monoS(color: sc.textLo),
              ),
              const SizedBox(height: Sp.s1),
              Text(
                formatIDR(balance),
                style: SatType.h1(
                  // A box that has gone negative is a bookkeeping error, not a
                  // shortfall — ADR-0088 forbids it, so red here means a bug
                  // upstream and should look like one.
                  color: balance < 0 ? sc.urgent : sc.textHi,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One movement. Reads left to right the way it is questioned: when, what kind,
/// how much, why, who.
class _KasRow extends StatelessWidget {
  final CashEntry entry;
  final VoidCallback onTap;
  const _KasRow({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final reversed = entry.reversedById != null;
    return Semantics(
      button: true,
      label: l10n.kasDetailTitle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s4,
            vertical: Sp.s3,
          ),
          decoration: SatBox.d(
            color: sc.bg1,
            borderRadius: SatR.a(10),
            border: SatB.all(color: sc.border0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 116,
                child: Text(
                  formatBarClockId(entry.at),
                  style: SatType.mono(color: sc.textLo),
                ),
              ),
              const SizedBox(width: Sp.s3),
              SizedBox(
                width: 124,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SatChip.tag(
                    label: cashEntryKindLabel(l10n, entry.kind),
                    hue: _hue(entry.kind),
                    size: SatChipSize.sm,
                  ),
                ),
              ),
              const SizedBox(width: Sp.s3),
              SizedBox(width: 140, child: _amount(context)),
              const SizedBox(width: Sp.s3),
              Expanded(child: _why(context)),
              if (entry.hasPhoto) ...[
                const SizedBox(width: Sp.s2),
                Icon(
                  Icons.photo_camera_back_outlined,
                  size: Sp.s4,
                  color: sc.textLo,
                ),
              ],
              const SizedBox(width: Sp.s3),
              SizedBox(
                width: 132,
                child: Text(
                  entry.actorName ?? l10n.kasActorUnknown,
                  style: SatType.bodyS(color: sc.textMd),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Sp.s2),
              SizedBox(
                width: 108,
                child: reversed
                    ? Text(
                        l10n.kasReversed,
                        style: SatType.labelS(color: sc.urgent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Signed money, struck through once the row has been reversed — the row
  /// stays (append-only), so its arithmetic has to stop looking live.
  Widget _amount(BuildContext context) {
    final sc = context.sat;
    if (entry.delta == 0) {
      return Text('—', style: SatType.mono(color: sc.textDim));
    }
    return Text(
      formatIDR(entry.delta),
      style:
          SatType.mono(
            color: entry.reversedById != null
                ? sc.textDim
                : (entry.delta > 0 ? sc.success : sc.textHi),
          ).copyWith(
            decoration: entry.reversedById != null
                ? TextDecoration.lineThrough
                : null,
          ),
    );
  }

  Widget _why(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final parts = <String>[
      if (entry.category != null) cashCategoryLabel(l10n, entry.category!),
      if (entry.kind == CashEntryKind.count && entry.countedAmount != null)
        l10n.kasCounted(formatIDR(entry.countedAmount!)),
      if (entry.kind == CashEntryKind.reversal) l10n.kasIsReversal,
      if (entry.note != null) entry.note!,
    ];
    return Text(
      parts.isEmpty ? '—' : parts.join(' · '),
      style: SatType.bodyS(color: sc.textMd),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

SatChipHue _hue(CashEntryKind kind) => switch (kind) {
  CashEntryKind.topUp => SatChipHue.success,
  CashEntryKind.expense => SatChipHue.warn,
  CashEntryKind.count => SatChipHue.info,
  CashEntryKind.reversal => SatChipHue.neutral,
};

/// One movement in full, and the only door to reversing it.
class _DetailSheet extends ConsumerWidget {
  final CashEntry entry;
  final VoidCallback onReverse;
  const _DetailSheet({required this.entry, required this.onReverse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l10n = context.l10n;
    final auth = ref.watch(authStateProvider);
    // Either authority may take back a movement — the same split the routes
    // enforce, mirrored here only so a button that would 403 is not offered.
    final canReverse =
        entry.canReverse &&
        (auth.has(Capability.manageCash) || auth.has(Capability.editSettings));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.s5, 0, Sp.s5, Sp.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SatSheetHeader(
              padding: const EdgeInsets.fromLTRB(0, Sp.s3, 0, Sp.s2),
              onClose: () => Navigator.of(context).pop(),
              child: Text(
                l10n.kasDetailTitle,
                style: SatType.h3(color: sc.textHi),
              ),
            ),
            Row(
              children: [
                SatChip.tag(
                  label: cashEntryKindLabel(l10n, entry.kind),
                  hue: _hue(entry.kind),
                ),
                const SizedBox(width: Sp.s2),
                Text(
                  entry.delta == 0 ? '—' : formatIDR(entry.delta),
                  style: SatType.h3(color: sc.textHi),
                ),
              ],
            ),
            const SizedBox(height: Sp.s3),
            _Line(label: l10n.auditColTime, value: formatBarClockId(entry.at)),
            _Line(label: l10n.kasFieldNote, value: entry.note ?? '—'),
            if (entry.category != null)
              _Line(
                label: l10n.kasFieldCategory,
                value: cashCategoryLabel(l10n, entry.category!),
              ),
            if (entry.countedAmount != null)
              _Line(
                label: l10n.kasFieldCounted,
                value: formatIDR(entry.countedAmount!),
              ),
            _Line(
              label: l10n.kasBy(entry.actorName ?? l10n.kasActorUnknown),
              value: '',
            ),
            if (entry.hasPhoto) ...[
              const SizedBox(height: Sp.s3),
              Text(
                l10n.kasPhotoAdd.toUpperCase(),
                style: SatType.monoS(color: sc.textLo),
              ),
              const SizedBox(height: Sp.s2),
              PaymentProofThumb(paymentId: entry.id, scope: ProofScope.cash),
            ],
            if (entry.reversedById != null) ...[
              const SizedBox(height: Sp.s3),
              Text(l10n.kasReversed, style: SatType.labelM(color: sc.urgent)),
            ],
            if (canReverse) ...[
              const SizedBox(height: Sp.s4),
              SatButton.danger(
                label: l10n.kasReverse,
                icon: Icons.undo_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  onReverse();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  const _Line({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s1h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: Text(label, style: SatType.bodyS(color: sc.textLo)),
          ),
          Expanded(
            child: Text(value, style: SatType.bodyS(color: sc.textHi)),
          ),
        ],
      ),
    );
  }
}

/// The one posting sheet, in four modes.
///
/// Four near-identical forms as four widgets is how the note field ends up
/// trimmed on three of them and not the fourth. The differences are which
/// fields show and which repository call fires; everything else — the busy
/// latch, the error line, the mapping from a server code to a sentence — is
/// shared on purpose.
class _PostSheet extends ConsumerStatefulWidget {
  final CashEntryKind kind;

  /// The row being undone. Set only for [CashEntryKind.reversal].
  final CashEntry? target;
  const _PostSheet({required this.kind, this.target});

  @override
  ConsumerState<_PostSheet> createState() => _PostSheetState();
}

class _PostSheetState extends ConsumerState<_PostSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  CashCategory _category = CashCategory.ingredients;
  Uint8List? _photo;
  bool _busy = false;
  String? _error;

  CashEntryKind get _kind => widget.kind;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _value =>
      int.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  /// Any edit rebuilds (the confirm button enables off the field) **and** drops
  /// a standing refusal: "Saldo kas cuma Rp. 480.000" stops being true the
  /// moment the supervisor types a smaller number, and leaving it under the
  /// button reads as "still refused".
  void _touch() => setState(() => _error = null);

  bool get _ready => switch (_kind) {
    CashEntryKind.topUp || CashEntryKind.expense => _value > 0,
    // A count of zero is a real finding — an empty box — so only a blank field
    // blocks, not a zero.
    CashEntryKind.count => _amount.text.trim().isNotEmpty,
    CashEntryKind.reversal => _note.text.trim().isNotEmpty,
  };

  Future<void> _shoot() async {
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
      if (mounted) setState(() => _photo = bytes);
    } catch (e) {
      if (mounted) setState(() => _error = l10n.kasErrFailed('$e'));
    }
  }

  Future<void> _submit() async {
    if (!_ready || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(cashProvider.notifier);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    try {
      switch (_kind) {
        case CashEntryKind.topUp:
          await repo.topUp(amount: _value, note: note);
        case CashEntryKind.expense:
          await repo.spend(
            amount: _value,
            category: _category,
            note: note,
            photoBase64: _photo == null ? null : base64Encode(_photo!),
          );
        case CashEntryKind.count:
          await repo.count(counted: _value, note: note);
        case CashEntryKind.reversal:
          await repo.reverse(id: widget.target!.id, note: note ?? '');
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = cashErrorText(context.l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final balance = ref.watch(cashProvider).balance;
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
                onClose: () => Navigator.of(context).pop(),
                child: Text(_title(l10n), style: SatType.h3(color: sc.textHi)),
              ),
              ..._fields(context, balance),
              if (_error != null) ...[
                const SizedBox(height: Sp.s3),
                Text(_error!, style: SatType.bodyS(color: sc.urgent)),
              ],
              const SizedBox(height: Sp.s4),
              SatButton.primary(
                label: _confirmLabel(l10n),
                busy: _busy,
                onTap: _ready ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(AppL10n l10n) => switch (_kind) {
    CashEntryKind.topUp => l10n.kasSheetTopUpTitle,
    CashEntryKind.expense => l10n.kasSheetExpenseTitle,
    CashEntryKind.count => l10n.kasSheetCountTitle,
    CashEntryKind.reversal => l10n.kasReverseTitle,
  };

  String _confirmLabel(AppL10n l10n) => switch (_kind) {
    CashEntryKind.topUp => l10n.kasActionTopUp,
    CashEntryKind.expense => l10n.kasActionExpense,
    CashEntryKind.count => l10n.kasActionCount,
    CashEntryKind.reversal => l10n.kasReverse,
  };

  List<Widget> _fields(BuildContext context, int balance) {
    final sc = context.sat;
    final l10n = context.l10n;
    return switch (_kind) {
      CashEntryKind.topUp => [
        SatField.money(
          controller: _amount,
          label: l10n.kasFieldAmount,
          hint: '',
          autofocus: true,
          onChanged: (_) => _touch(),
        ),
        const SizedBox(height: Sp.s3),
        SatField.text(controller: _note, label: l10n.kasFieldNote, hint: ''),
      ],
      CashEntryKind.expense => [
        SatField.money(
          controller: _amount,
          label: l10n.kasFieldAmount,
          hint: '',
          autofocus: true,
          helperText: l10n.kasLedgerSays(formatIDR(balance)),
          onChanged: (_) => _touch(),
        ),
        const SizedBox(height: Sp.s3),
        SatDropdown<CashCategory>(
          value: _category,
          label: l10n.kasFieldCategory,
          options: [
            for (final c in CashCategory.values)
              SatOption(c, cashCategoryLabel(l10n, c)),
          ],
          onChanged: (c) => setState(() => _category = c ?? _category),
        ),
        const SizedBox(height: Sp.s3),
        SatField.text(controller: _note, label: l10n.kasFieldNote, hint: ''),
        const SizedBox(height: Sp.s3),
        Row(
          children: [
            if (_photo != null) ...[
              PaymentProofThumb(paymentId: null, previewBytes: _photo),
              const SizedBox(width: Sp.s3),
            ],
            Expanded(
              child: SatButton.outline(
                label: l10n.kasPhotoAdd,
                icon: Icons.photo_camera_rounded,
                onTap: _shoot,
              ),
            ),
          ],
        ),
      ],
      CashEntryKind.count => [
        SatField.money(
          controller: _amount,
          label: l10n.kasFieldCounted,
          hint: '',
          autofocus: true,
          helperText: l10n.kasLedgerSays(formatIDR(balance)),
          onChanged: (_) => _touch(),
        ),
        const SizedBox(height: Sp.s2),
        // The variance is the whole point of a count, so it is shown before the
        // count is filed rather than discovered in the ledger afterwards.
        Text(
          l10n.kasVariance(formatIDR(_value - balance)),
          style: SatType.labelM(color: _value == balance ? sc.textMd : sc.warn),
        ),
        const SizedBox(height: Sp.s3),
        SatField.text(controller: _note, label: l10n.kasFieldNote, hint: ''),
      ],
      CashEntryKind.reversal => [
        Text(l10n.kasReverseBody, style: SatType.bodyS(color: sc.textMd)),
        const SizedBox(height: Sp.s3),
        SatField.text(
          controller: _note,
          label: l10n.kasFieldReason,
          hint: '',
          autofocus: true,
          onChanged: (_) => _touch(),
        ),
      ],
    };
  }
}

/// A server refusal, as a sentence. Codes cross the layer, never words
/// (ADR-0085); an unknown code still prints itself rather than nothing.
String cashErrorText(AppL10n l10n, Object error) {
  final err = cashErrorOf(error);
  return switch (err?.code) {
    'insufficient_cash' => l10n.kasErrInsufficient(
      formatIDR(err?.balance ?? 0),
    ),
    'note_required' => l10n.kasErrReasonRequired,
    'already_reversed' => l10n.kasErrAlreadyReversed,
    'not_reversible' => l10n.kasErrNotReversible,
    'invalid_amount' => l10n.kasErrInvalidAmount,
    final code? => l10n.kasErrFailed(code),
    null => l10n.kasErrFailed('$error'),
  };
}

class _KasPhoneNotice extends StatelessWidget {
  const _KasPhoneNotice();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Sp.s5),
    child: Center(
      child: SatEmpty(
        icon: Icons.tablet_mac_outlined,
        title: context.l10n.kasTitle,
        body: context.l10n.kasPhoneOnly,
      ),
    ),
  );
}
