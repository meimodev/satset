import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/labels.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/models/member_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/members_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_empty.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';
import '_common.dart';

/// "Pelanggan" — the [[Pelanggan (member)]] directory (ADR-0091).
///
/// The keeper's surface: enrol, correct, merge two records that turned out to
/// be one person, hand-adjust a balance, and read a member's [[Poin]] ledger.
/// Spending points happens at the till, not here — a directory that could
/// change what a guest owes would be a second till (ADR-0093).
///
/// Tablet only, like the venue log and the cash box: the value of a directory
/// is reading rows against each other, and a phone shows one row.
class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  /// ponytail: filters the loaded page rather than asking the server, because
  /// the authoritative "who owes" list is the collection sheet's `/debtors`.
  /// A venue past 100 members needs a server-side flag here.
  bool _debtOnly = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(ref.read(membersProvider.notifier).refresh);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// The search runs server-side, so it is debounced rather than fired per
  /// keystroke — a directory-keeper types a whole name.
  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) ref.read(membersProvider.notifier).search(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!context.layout.useTabletShell) return const _MembersPhoneNotice();

    final l10n = context.l10n;
    final state = ref.watch(membersProvider);
    final month = state.birthdayMonth;
    final debtOn = ref.watch(
      venueSettingsProvider.select((v) => v.memberDebtEnabled),
    );
    final rows = _debtOnly
        ? [
            for (final m in state.members)
              if (m.debt > 0) m,
          ]
        : state.members;

    if (!state.enabled) {
      return Padding(
        padding: const EdgeInsets.all(Sp.s5),
        child: Center(
          child: SatEmpty(
            icon: Icons.badge_outlined,
            title: l10n.memOffTitle,
            body: l10n.memOffBody,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminEmbeddedStrip(
          title: l10n.memTitle,
          sub: l10n.memCount(state.members.length),
          trailing: SatButton.primary(
            label: l10n.memActionAdd,
            icon: Icons.person_add_alt_1_rounded,
            size: SatButtonSize.sm,
            onTap: () => _form(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.s7, Sp.s4, Sp.s7, Sp.s3),
          child: Row(
            children: [
              Expanded(
                child: SatField.search(
                  controller: _search,
                  hint: l10n.memSearchHint,
                  onChanged: _onQuery,
                ),
              ),
              const SizedBox(width: Sp.s3),
              SatChip.select(
                label: l10n.memBirthdayFilter,
                selected: month != null,
                onTap: () => ref
                    .read(membersProvider.notifier)
                    .filterByBirthdayMonth(
                      month == null ? DateTime.now().month : null,
                    ),
              ),
              if (debtOn) ...[
                const SizedBox(width: Sp.s2),
                SatChip.select(
                  label: l10n.memDebtFilter,
                  selected: _debtOnly,
                  onTap: () => setState(() => _debtOnly = !_debtOnly),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref.read(membersProvider.notifier).refresh,
            child: rows.isEmpty && !state.loading
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(Sp.s7),
                        child: SatEmpty(
                          icon: Icons.badge_outlined,
                          title: l10n.memEmptyTitle,
                          body: l10n.memEmptyBody,
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(Sp.s7, 0, Sp.s7, Sp.s7),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Sp.s1h),
                    itemBuilder: (_, i) => _MemberRow(
                      member: rows[i],
                      onTap: () => _detail(rows[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _form([MemberDto? existing]) => showSatSheet<void>(
    context,
    builder: (_) => MemberFormSheet(existing: existing),
  );

  Future<void> _detail(MemberDto member) => showSatSheet<void>(
    context,
    builder: (_) => _MemberDetailSheet(member: member),
  );
}

/// One member, read the way they are asked after: who, which number, what they
/// have banked, how often they come.
class _MemberRow extends ConsumerWidget {
  final MemberDto member;
  final VoidCallback onTap;
  const _MemberRow({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final l10n = context.l10n;
    final cfg = ref.watch(venueSettingsProvider);
    final last = member.member.lastVisitAt;
    return Semantics(
      button: true,
      label: member.name,
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
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  member.name,
                  style: SatType.labelM(color: sc.textHi),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Sp.s3),
              SizedBox(
                width: 148,
                child: Text(
                  member.phone,
                  style: SatType.mono(color: sc.textMd),
                ),
              ),
              const SizedBox(width: Sp.s3),
              if (cfg.memberPointsEnabled)
                SizedBox(
                  width: 110,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SatChip.tag(
                      label: l10n.memPoints(member.points),
                      hue: SatChipHue.accent,
                      size: SatChipSize.sm,
                    ),
                  ),
                ),
              if (member.punchTarget > 0) ...[
                const SizedBox(width: Sp.s2),
                SizedBox(
                  width: 132,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SatChip.tag(
                      label: member.punchRewardDue
                          ? l10n.memRewardDue
                          : l10n.memPunch(
                              member.member.punchProgress,
                              member.punchTarget,
                            ),
                      hue: member.punchRewardDue
                          ? SatChipHue.success
                          : SatChipHue.neutral,
                      size: SatChipSize.sm,
                    ),
                  ),
                ),
              ],
              if (cfg.memberDebtEnabled) ...[
                const SizedBox(width: Sp.s2),
                SizedBox(
                  width: 128,
                  child: member.debt > 0
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: SatChip.tag(
                            label: formatIDR(member.debt),
                            hue: SatChipHue.warn,
                            size: SatChipSize.sm,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
              const SizedBox(width: Sp.s3),
              SizedBox(
                width: 116,
                child: Text(
                  l10n.memVisits(member.member.visitCount),
                  style: SatType.bodyS(color: sc.textMd),
                ),
              ),
              SizedBox(
                width: 132,
                child: Text(
                  last == null ? '—' : formatShortDateId(last),
                  style: SatType.bodyS(color: sc.textLo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One member in full: the record, the punch card, the ledger, and every act
/// the directory-keeper has over them.
class _MemberDetailSheet extends ConsumerStatefulWidget {
  final MemberDto member;
  const _MemberDetailSheet({required this.member});

  @override
  ConsumerState<_MemberDetailSheet> createState() => _MemberDetailSheetState();
}

class _MemberDetailSheetState extends ConsumerState<_MemberDetailSheet> {
  late Future<MemberDetail> _load;

  /// The [[Piutang]] standing, read separately because it is a separate ledger
  /// with its own gate — a venue running points but no tabs asks for nothing.
  Future<MemberDebt>? _debt;

  String? _deleteError;

  @override
  void initState() {
    super.initState();
    _load = ref.read(membersProvider.notifier).detail(widget.member.id);
    if (ref.read(venueSettingsProvider).memberDebtEnabled) _loadDebt();
  }

  void _loadDebt() =>
      _debt = ref.read(membersProvider.notifier).debt(widget.member.id);

  void _reload() => setState(() {
    // A collection or a write-off is exactly what clears `has_outstanding_debt`,
    // so the old refusal must not outlive the balance it was about.
    _deleteError = null;
    _load = ref.read(membersProvider.notifier).detail(widget.member.id);
    if (ref.read(venueSettingsProvider).memberDebtEnabled) _loadDebt();
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final cfg = ref.watch(venueSettingsProvider);
    final canRefund = ref.watch(authStateProvider).has(Capability.refund);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.s5, 0, Sp.s5, Sp.s5),
        child: FutureBuilder<MemberDetail>(
          future: _load,
          builder: (context, snap) {
            final detail = snap.data;
            final m = detail?.member ?? widget.member;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SatSheetHeader(
                    padding: const EdgeInsets.fromLTRB(0, Sp.s3, 0, Sp.s2),
                    onClose: () => Navigator.of(context).pop(),
                    child: Text(m.name, style: SatType.h3(color: sc.textHi)),
                  ),
                  Row(
                    children: [
                      Text(m.phone, style: SatType.mono(color: sc.textMd)),
                      if (m.member.code.isNotEmpty) ...[
                        const SizedBox(width: Sp.s3),
                        SatChip.tag(
                          label: m.member.code,
                          hue: SatChipHue.neutral,
                          size: SatChipSize.sm,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Sp.s4),
                  if (cfg.memberPointsEnabled)
                    _FactLine(
                      label: l10n.memColPoints,
                      value: l10n.memPoints(m.points),
                    ),
                  if (m.punchTarget > 0)
                    _FactLine(
                      label: l10n.memColPunch,
                      value: m.punchRewardDue
                          ? l10n.memRewardDue
                          : l10n.memPunch(
                              m.member.punchProgress,
                              m.punchTarget,
                            ),
                    ),
                  _FactLine(
                    label: l10n.memColVisits,
                    value: '${m.member.visitCount}',
                  ),
                  _FactLine(
                    label: l10n.memColLifetime,
                    value: formatIDR(m.member.lifetimeSpend),
                  ),
                  _FactLine(
                    label: l10n.memColJoined,
                    value: formatShortDateId(m.member.joinedAt),
                  ),
                  if (m.member.birthday != null)
                    _FactLine(
                      label: l10n.memFieldBirthday,
                      value: formatShortDateId(m.member.birthday!),
                    ),
                  if ((m.member.note ?? '').isNotEmpty)
                    _FactLine(label: l10n.memFieldNote, value: m.member.note!),
                  const SizedBox(height: Sp.s4),
                  Wrap(
                    spacing: Sp.s2,
                    runSpacing: Sp.s2,
                    children: [
                      SatButton.outline(
                        label: l10n.memActionEdit,
                        icon: Icons.edit_outlined,
                        size: SatButtonSize.sm,
                        onTap: () async {
                          await showSatSheet<void>(
                            context,
                            builder: (_) => MemberFormSheet(existing: m),
                          );
                          if (mounted) _reload();
                        },
                      ),
                      if (cfg.memberPointsEnabled)
                        SatButton.outline(
                          label: l10n.memActionAdjust,
                          icon: Icons.tune_rounded,
                          size: SatButtonSize.sm,
                          onTap: () async {
                            await showSatSheet<void>(
                              context,
                              builder: (_) => _AdjustSheet(member: m),
                            );
                            if (mounted) _reload();
                          },
                        ),
                      SatButton.outline(
                        label: l10n.memActionMerge,
                        icon: Icons.merge_rounded,
                        size: SatButtonSize.sm,
                        onTap: () async {
                          final done = await showSatSheet<bool>(
                            context,
                            builder: (_) => _MergeSheet(member: m),
                          );
                          if (done == true && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      if (cfg.memberDebtEnabled && canRefund) ...[
                        SatButton.outline(
                          label: l10n.memActionDebtAdjust,
                          icon: Icons.rule_rounded,
                          size: SatButtonSize.sm,
                          onTap: () => _debtSheet(m, writeOff: false),
                        ),
                        SatButton.outline(
                          label: l10n.memActionWriteOff,
                          icon: Icons.money_off_rounded,
                          size: SatButtonSize.sm,
                          onTap: () => _debtSheet(m, writeOff: true),
                        ),
                      ],
                      SatButton.danger(
                        label: l10n.memActionDelete,
                        icon: Icons.person_remove_outlined,
                        size: SatButtonSize.sm,
                        onTap: _confirmDelete,
                      ),
                    ],
                  ),
                  if (_deleteError != null) ...[
                    const SizedBox(height: Sp.s2),
                    Text(_deleteError!, style: SatType.bodyS(color: sc.urgent)),
                  ],
                  if (cfg.memberDebtEnabled) _debtBlock(sc, l10n),
                  if (cfg.memberPointsEnabled) ...[
                    const SizedBox(height: Sp.s5),
                    Text(
                      l10n.memLedgerTitle.toUpperCase(),
                      style: SatType.monoS(color: sc.textLo),
                    ),
                    const SizedBox(height: Sp.s2),
                    if (detail == null)
                      Text(
                        l10n.memLedgerLoading,
                        style: SatType.bodyS(color: sc.textLo),
                      )
                    else if (detail.ledger.isEmpty)
                      Text(
                        l10n.memLedgerEmpty,
                        style: SatType.bodyS(color: sc.textLo),
                      )
                    else
                      for (final e in detail.ledger) _LedgerRow(entry: e.entry),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Balance, resolved limit, then the ledger. The limit is shown even at zero:
  /// "no tab" is a standing decision about this person, not a missing value.
  Widget _debtBlock(SatColors sc, AppL10n l10n) => FutureBuilder<MemberDebt>(
    future: _debt,
    builder: (_, snap) {
      final d = snap.data;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Sp.s5),
          Text(
            l10n.memDebtTitle.toUpperCase(),
            style: SatType.monoS(color: sc.textLo),
          ),
          const SizedBox(height: Sp.s2),
          if (d == null)
            Text(l10n.memLedgerLoading, style: SatType.bodyS(color: sc.textLo))
          else ...[
            _FactLine(label: l10n.memColDebt, value: formatIDR(d.balance)),
            _FactLine(
              label: l10n.memColDebtLimit,
              value: d.ownLimit == null
                  ? l10n.memDebtLimitVenue(formatIDR(d.limit))
                  : formatIDR(d.limit),
            ),
            const SizedBox(height: Sp.s2),
            if (d.entries.isEmpty)
              Text(
                l10n.memDebtLedgerEmpty,
                style: SatType.bodyS(color: sc.textLo),
              )
            else
              for (final e in d.entries) _DebtLedgerRow(entry: e),
          ],
        ],
      );
    },
  );

  Future<void> _debtSheet(MemberDto m, {required bool writeOff}) async {
    await showSatSheet<void>(
      context,
      builder: (_) => _DebtActionSheet(member: m, writeOff: writeOff),
    );
    if (mounted) _reload();
  }

  /// Deleting a member **anonymises** them — the person and their ledger go,
  /// the trade they did stays counted (ADR-0092). Said plainly, because it is
  /// the one act here that cannot be undone.
  Future<void> _confirmDelete() async {
    final l10n = context.l10n;
    final ok = await showSatDialog<bool>(
      context,
      builder: (dc) => _ConfirmDialog(
        title: l10n.memDeleteTitle,
        body: l10n.memDeleteBody(widget.member.name),
        confirm: l10n.memActionDelete,
        onConfirm: () => Navigator.of(dc).pop(true),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(membersProvider.notifier).remove(widget.member.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // A delete can be refused — `has_outstanding_debt` while the member still
      // owes (ADR-0098). Swallowing it left the sheet open with no reason.
      if (mounted) setState(() => _deleteError = memberErrorText(l10n, e));
    }
  }
}

class _LedgerRow extends StatelessWidget {
  final MemberPointEntry entry;
  const _LedgerRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s1h),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            child: Text(
              formatShortDateId(entry.at),
              style: SatType.mono(color: sc.textLo),
            ),
          ),
          SizedBox(
            width: 108,
            child: SatChip.tag(
              label: memberPointKindLabel(l10n, entry.kind),
              hue: _kindHue(entry.kind),
              size: SatChipSize.sm,
            ),
          ),
          const SizedBox(width: Sp.s2),
          SizedBox(
            width: 84,
            child: Text(
              // Signed, because a ledger that hides direction is a list.
              '${entry.delta > 0 ? '+' : ''}${entry.delta}',
              style: SatType.mono(
                color: entry.delta > 0 ? sc.success : sc.textHi,
              ),
            ),
          ),
          Expanded(
            child: Text(
              entry.note ?? entry.actorName ?? '—',
              style: SatType.bodyS(color: sc.textMd),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// One [[Piutang]] movement. Money, so the delta is rupiah and signed — a
/// charge reads `+`, a collection reads `−`, and the direction is the point.
class _DebtLedgerRow extends StatelessWidget {
  final MemberDebtEntry entry;
  const _DebtLedgerRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final detail = entry.method != null
        ? paymentMethodLabel(l10n, entry.method!)
        : (entry.note ?? entry.billLabel);
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s1h),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            child: Text(
              formatShortDateId(entry.at),
              style: SatType.mono(color: sc.textLo),
            ),
          ),
          SizedBox(
            width: 116,
            child: SatChip.tag(
              label: memberDebtKindLabel(l10n, entry.kind),
              hue: _debtKindHue(entry.kind),
              size: SatChipSize.sm,
            ),
          ),
          const SizedBox(width: Sp.s2),
          SizedBox(
            width: 132,
            child: Text(
              '${entry.delta > 0 ? '+' : '−'}${formatIDR(entry.delta.abs())}',
              style: SatType.mono(
                color: entry.delta > 0 ? sc.warn : sc.success,
              ),
            ),
          ),
          Expanded(
            child: Text(
              detail.isEmpty ? (entry.actorName ?? '—') : detail,
              style: SatType.bodyS(color: sc.textMd),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

SatChipHue _debtKindHue(MemberDebtKind kind) => switch (kind) {
  MemberDebtKind.charge => SatChipHue.warn,
  MemberDebtKind.payment => SatChipHue.success,
  MemberDebtKind.reversal => SatChipHue.neutral,
  MemberDebtKind.writeOff => SatChipHue.urgent,
  MemberDebtKind.adjust => SatChipHue.accent,
};

/// Write off what will not be collected, or correct what was mistyped. One
/// sheet, two verbs, because they differ only in sign and in what the bad-debt
/// figure is allowed to mean (ADR-0098) — a correction is not a loss.
class _DebtActionSheet extends ConsumerStatefulWidget {
  final MemberDto member;
  final bool writeOff;
  const _DebtActionSheet({required this.member, required this.writeOff});

  @override
  ConsumerState<_DebtActionSheet> createState() => _DebtActionSheetState();
}

class _DebtActionSheetState extends ConsumerState<_DebtActionSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _negative = false;
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

  Future<void> _submit() async {
    if (_value <= 0 || _note.text.trim().isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(membersProvider.notifier);
    try {
      if (widget.writeOff) {
        await repo.writeOffDebt(
          id: widget.member.id,
          amount: _value,
          note: _note.text.trim(),
        );
      } else {
        await repo.adjustDebt(
          id: widget.member.id,
          delta: _negative ? -_value : _value,
          note: _note.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Sp.s5,
          0,
          Sp.s5,
          MediaQuery.of(context).viewInsets.bottom + Sp.s5,
        ),
        // Scrolls: the money field autofocuses, and the number pad leaves a
        // tablet ~180pt — the confirm button fell off the bottom without it.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SatSheetHeader(
                padding: const EdgeInsets.fromLTRB(0, Sp.s3, 0, Sp.s2),
                onClose: () => Navigator.of(context).pop(),
                child: Text(
                  widget.writeOff
                      ? l10n.memActionWriteOff
                      : l10n.memActionDebtAdjust,
                  style: SatType.h3(color: sc.textHi),
                ),
              ),
              Text(
                widget.writeOff ? l10n.memWriteOffBody : l10n.memDebtAdjustBody,
                style: SatType.bodyS(color: sc.textLo),
              ),
              const SizedBox(height: Sp.s4),
              if (!widget.writeOff) ...[
                Wrap(
                  spacing: Sp.s2,
                  children: [
                    SatChip.select(
                      label: l10n.memDebtAdjustUp,
                      selected: !_negative,
                      onTap: () => setState(() => _negative = false),
                    ),
                    SatChip.select(
                      label: l10n.memDebtAdjustDown,
                      selected: _negative,
                      onTap: () => setState(() => _negative = true),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.s3),
              ],
              SatField.money(
                controller: _amount,
                label: l10n.memDebtAmount,
                hint: '0',
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Sp.s3),
              SatField.text(
                controller: _note,
                label: l10n.memDebtReason,
                hint: '',
                onChanged: (_) => setState(() {}),
              ),
              if (_error != null) ...[
                const SizedBox(height: Sp.s3),
                Text(_error!, style: SatType.bodyS(color: sc.urgent)),
              ],
              const SizedBox(height: Sp.s4),
              SatButton.primary(
                label: widget.writeOff
                    ? l10n.memActionWriteOff
                    : l10n.memActionDebtAdjust,
                onTap: _value > 0 && _note.text.trim().isNotEmpty && !_busy
                    ? _submit
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

SatChipHue _kindHue(MemberPointKind kind) => switch (kind) {
  MemberPointKind.earn => SatChipHue.success,
  MemberPointKind.redeem => SatChipHue.accent,
  MemberPointKind.adjust => SatChipHue.warn,
  MemberPointKind.reversal => SatChipHue.neutral,
};

/// Enrol or correct. One sheet for both, for the reason the cash box keeps one
/// posting sheet: two near-identical forms is how the phone ends up normalised
/// on one path and not the other.
///
/// Public because the till enrols from the bill overlay through the same form —
/// a second enrolment surface would be a second set of rules.
class MemberFormSheet extends ConsumerStatefulWidget {
  final MemberDto? existing;

  /// Prefilled when the till already typed a number into the lookup.
  final String? initialPhone;
  const MemberFormSheet({super.key, this.existing, this.initialPhone});

  @override
  ConsumerState<MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends ConsumerState<MemberFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _note;

  /// Empty means "whatever the venue allows", which is not the same as a zero
  /// limit — so it is seeded from the member's *own* limit, never the resolved
  /// one (ADR-0098).
  late final TextEditingController _limit;
  DateTime? _birthday;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? widget.initialPhone ?? '');
    _note = TextEditingController(text: e?.member.note ?? '');
    final own = e?.member.ownDebtLimit;
    _limit = TextEditingController(text: own == null ? '' : groupRupiah(own));
    _birthday = e?.member.birthday;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    _limit.dispose();
    super.dispose();
  }

  /// Null when the field is empty — the member falls back to the venue default.
  int? get _limitValue {
    final digits = _limit.text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }

  bool get _ready =>
      _name.text.trim().isNotEmpty &&
      normalizePhone(_phone.text).length >= 6 &&
      !_busy;

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => _birthday = picked);
  }

  Future<void> _submit() async {
    if (!_ready) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(membersProvider.notifier);
    try {
      final saved = widget.existing == null
          ? await repo.enrol(
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              birthday: _birthday,
            )
          : await repo.edit(
              id: widget.existing!.id,
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              note: _note.text.trim(),
              birthday: _birthday,
              clearBirthday: _birthday == null,
              debtLimit: _limitValue,
              clearDebtLimit: _limitValue == null,
            );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = memberErrorText(context.l10n, e);
      });
    }
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SatSheetHeader(
                padding: const EdgeInsets.fromLTRB(0, Sp.s3, 0, Sp.s2),
                onClose: () => Navigator.of(context).pop(),
                child: Text(
                  widget.existing == null
                      ? l10n.memSheetAddTitle
                      : l10n.memSheetEditTitle,
                  style: SatType.h3(color: sc.textHi),
                ),
              ),
              SatField.text(
                controller: _name,
                label: l10n.memFieldName,
                hint: '',
                autofocus: true,
                capitalization: TextCapitalization.words,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: Sp.s3),
              SatField.number(
                controller: _phone,
                label: l10n.memFieldPhone,
                hint: '',
                // The number is the identity, so the rule it is normalised by
                // is stated under the field rather than discovered on refusal.
                helperText: l10n.memPhoneHelp,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: Sp.s3),
              SatButton.outline(
                label: _birthday == null
                    ? l10n.memPickBirthday
                    : formatShortDateId(_birthday!),
                icon: Icons.cake_outlined,
                size: SatButtonSize.sm,
                onTap: _pickBirthday,
              ),
              const SizedBox(height: Sp.s3),
              SatField.text(
                controller: _note,
                label: l10n.memFieldNote,
                hint: '',
              ),
              // Enrolment cannot set a limit: the PATCH route owns it, and a
              // tab is a decision about someone you already know.
              if (widget.existing != null &&
                  ref.watch(venueSettingsProvider).memberDebtEnabled) ...[
                const SizedBox(height: Sp.s3),
                SatField.money(
                  controller: _limit,
                  label: l10n.memFieldDebtLimit,
                  hint: '',
                  helperText: l10n.memFieldDebtLimitHelp,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: Sp.s3),
                Text(_error!, style: SatType.bodyS(color: sc.urgent)),
              ],
              const SizedBox(height: Sp.s4),
              SatButton.primary(
                label: l10n.memSave,
                busy: _busy,
                onTap: _ready ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A hand correction. Mandatory reason, always audited — the only movement of
/// points with no bill behind it.
class _AdjustSheet extends ConsumerStatefulWidget {
  final MemberDto member;
  const _AdjustSheet({required this.member});

  @override
  ConsumerState<_AdjustSheet> createState() => _AdjustSheetState();
}

class _AdjustSheetState extends ConsumerState<_AdjustSheet> {
  final _delta = TextEditingController();
  final _note = TextEditingController();
  bool _add = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _delta.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _value =>
      int.tryParse(_delta.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  bool get _ready => _value > 0 && _note.text.trim().isNotEmpty && !_busy;

  Future<void> _submit() async {
    if (!_ready) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(membersProvider.notifier)
          .adjustPoints(
            id: widget.member.id,
            delta: _add ? _value : -_value,
            note: _note.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = memberErrorText(context.l10n, e);
      });
    }
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SatSheetHeader(
                padding: const EdgeInsets.fromLTRB(0, Sp.s3, 0, Sp.s2),
                onClose: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.memAdjustTitle,
                  style: SatType.h3(color: sc.textHi),
                ),
              ),
              Text(
                l10n.memPoints(widget.member.points),
                style: SatType.labelM(color: sc.textMd),
              ),
              const SizedBox(height: Sp.s3),
              Row(
                children: [
                  SatChip.select(
                    label: l10n.memAdjustAdd,
                    selected: _add,
                    onTap: () => setState(() => _add = true),
                  ),
                  const SizedBox(width: Sp.s2),
                  SatChip.select(
                    label: l10n.memAdjustSubtract,
                    selected: !_add,
                    onTap: () => setState(() => _add = false),
                  ),
                ],
              ),
              const SizedBox(height: Sp.s3),
              SatField.number(
                controller: _delta,
                label: l10n.memFieldDelta,
                hint: '',
                autofocus: true,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: Sp.s3),
              SatField.text(
                controller: _note,
                label: l10n.memFieldReason,
                hint: '',
                onChanged: (_) => setState(() => _error = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: Sp.s3),
                Text(_error!, style: SatType.bodyS(color: sc.urgent)),
              ],
              const SizedBox(height: Sp.s4),
              SatButton.primary(
                label: l10n.memSave,
                busy: _busy,
                onTap: _ready ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fold this member into another. The one on screen is absorbed; the one picked
/// here survives, and takes the ledger and the history with it.
class _MergeSheet extends ConsumerStatefulWidget {
  final MemberDto member;
  const _MergeSheet({required this.member});

  @override
  ConsumerState<_MergeSheet> createState() => _MergeSheetState();
}

class _MergeSheetState extends ConsumerState<_MergeSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _merge(MemberDto into) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(membersProvider.notifier)
          .merge(id: widget.member.id, intoId: into.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = memberErrorText(context.l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final others = [
      for (final m in ref.watch(membersProvider).members)
        if (m.id != widget.member.id) m,
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.s5, 0, Sp.s5, Sp.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SatSheetHeader(
              padding: const EdgeInsets.fromLTRB(0, Sp.s3, 0, Sp.s2),
              onClose: () => Navigator.of(context).pop(),
              child: Text(
                l10n.memMergeTitle,
                style: SatType.h3(color: sc.textHi),
              ),
            ),
            Text(
              l10n.memMergeBody(widget.member.name),
              style: SatType.bodyS(color: sc.textMd),
            ),
            if (_error != null) ...[
              const SizedBox(height: Sp.s3),
              Text(_error!, style: SatType.bodyS(color: sc.urgent)),
            ],
            const SizedBox(height: Sp.s3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: others.length,
                separatorBuilder: (_, _) => const SizedBox(height: Sp.s1h),
                itemBuilder: (_, i) => SatButton.outline(
                  label: '${others[i].name} · ${others[i].phone}',
                  onTap: _busy ? null : () => _merge(others[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirm;
  final VoidCallback onConfirm;
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirm,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    // `showSatDialog` hands the builder's widget straight to `showDialog`, so a
    // bare body has no surface and no width: it painted full-bleed over the
    // member sheet underneath, title across the app bar and buttons adrift.
    // `Dialog` is what supplies both, from `dialogTheme`.
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(Sp.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: SatType.h3(color: sc.textHi)),
              const SizedBox(height: Sp.s2),
              Text(body, style: SatType.bodyS(color: sc.textMd)),
              const SizedBox(height: Sp.s4),
              Row(
                children: [
                  Expanded(
                    child: SatButton.ghost(
                      label: context.l10n.cancel,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: Sp.s2),
                  Expanded(
                    child: SatButton.danger(label: confirm, onTap: onConfirm),
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

class _FactLine extends StatelessWidget {
  final String label;
  final String value;
  const _FactLine({required this.label, required this.value});

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

/// A server refusal, as a sentence. Codes cross the layer, never words
/// (ADR-0085); an unknown code still prints itself rather than nothing.
String memberErrorText(AppL10n l10n, Object error) {
  final err = memberErrorOf(error);
  return switch (err?.code) {
    'name_required' => l10n.memErrNameRequired,
    'phone_required' => l10n.memErrPhoneRequired,
    'phone_taken' => l10n.memErrPhoneTaken,
    'not_found' => l10n.memErrNotFound,
    'same_member' => l10n.memErrSameMember,
    'note_required' => l10n.memErrReasonRequired,
    'invalid_amount' => l10n.memErrInvalidAmount,
    'points_disabled' => l10n.memErrPointsOff,
    'members_disabled' => l10n.memOffTitle,
    'below_minimum' => l10n.memErrBelowMin(err?.points ?? 0),
    'insufficient_points' => l10n.memErrInsufficient(err?.points ?? 0),
    'exceeds_bill' => l10n.memErrExceedsBill(err?.points ?? 0),
    'redeem_exists' => l10n.memErrRedeemExists,
    'has_outstanding_debt' => l10n.memErrHasDebt,
    'debt_limit_exceeded' => l10n.memErrDebtLimit,
    'overpayment' => l10n.memErrOverpayment,
    'debt_disabled' => l10n.memErrDebtOff,
    final code? => l10n.memErrFailed(code),
    null => l10n.memErrFailed('$error'),
  };
}

class _MembersPhoneNotice extends StatelessWidget {
  const _MembersPhoneNotice();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Sp.s5),
    child: Center(
      child: SatEmpty(
        icon: Icons.tablet_mac_outlined,
        title: context.l10n.memTitle,
        body: context.l10n.memPhoneOnly,
      ),
    ),
  );
}
