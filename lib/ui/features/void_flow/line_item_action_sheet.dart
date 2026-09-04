import 'package:flutter/material.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/core/localization/report_copy.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/send_queue_service.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/cart_item.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/ticket_transitions.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/ui/features/menu/modifier_sheet.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/use_cases/advance_ticket_status_use_case.dart';
import 'package:satset/ui/core/widgets/status_chip.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';

// Canonical reason codes — must match the server taxonomy in
// reports_routes.dart and the void_reason_code DB column (see ADR-0006).
// Codes only. The words come from `voidReasonLabel`/`voidReasonDesc` at build
// time, so the same code reads Indonesian on one device and English on the
// next, and a report renders a void with the words the waiter picked
// (ADR-0085).
const _voidReasons = <String>[
  'wrongOrder',
  'customerChange',
  'outOfStock',
  'kitchenError',
  'other',
];

/// Offered only on an already-served line, which is exactly when voiding
/// requires `compItem` rather than `voidItem` (ADR-0006). Without a button of
/// its own a comp was only recorded as one if someone happened to type the
/// word into free text — so the venue log counted giveaways as cancellations.
const _compReason = 'comp';

/// The terminal-view inset, shared by the two full-sheet outcomes so the
/// confirmation and the refusal sit on exactly the same optical centre — and
/// so the ratchet in `design_tokens_test.dart` counts one literal, not two.
const _outcomePadding = EdgeInsets.fromLTRB(28, 28, 28, 32);

void showLineItemActionSheet({
  required BuildContext context,
  required String tableId,
  required Ticket ticket,
  // Optional pre-resolved header label. Takeaway lines have no table row, so the
  // caller passes the visit label; dine-in leaves it null and the sheet resolves
  // the table's displayName from [tableId]. See ADR-0026.
  String? displayName,
}) {
  showSatSheet(
    context,
    bare: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scroll) => _SheetBody(
        tableId: tableId,
        ticket: ticket,
        displayName: displayName,
        scrollController: scroll,
      ),
    ),
  );
}

enum _Step { actions, voidReason, confirmed, failed }

/// Why the void did not happen, as a code the sheet can render (ADR-0085).
///
/// The sheet, not the server, decides between the two 403 flavours: the host
/// answers a bare `forbidden` for both, and only the caller knows the line was
/// already served — which is the difference between "your role cannot do this"
/// and "this one needs a manager".
String voidFailCode(Object e, TicketStatus status) {
  if (e is IllegalTicketTransition) return 'illegal_transition';
  if (e is SendQueueFull) return 'send_queue_full';
  if (e is ApiException) {
    if (e.statusCode == 403) {
      return status == TicketStatus.served ? 'forbidden_comp' : 'forbidden';
    }
    return e.code ?? 'other';
  }
  return 'other';
}

class _SheetBody extends ConsumerStatefulWidget {
  final String tableId;
  final Ticket ticket;
  final String? displayName;
  final ScrollController scrollController;
  const _SheetBody({
    required this.tableId,
    required this.ticket,
    required this.displayName,
    required this.scrollController,
  });

  @override
  ConsumerState<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends ConsumerState<_SheetBody> {
  _Step _step = _Step.actions;
  String? _reason;
  String _reasonText = '';

  /// Set when the host refused. A void that fails silently is the bug this
  /// sheet shipped with: the await threw, the step never advanced, and the
  /// waiter was left looking at a reason list that had stopped responding.
  String? _failCode;

  /// The void was captured on the queue, not delivered. Same confirmation,
  /// one different sentence — the kitchen has not heard it and may still plate
  /// the dish.
  bool _queued = false;

  bool _committing = false;

  // Re-resolves the ticket from live state each build so kitchen status
  // changes (sent → prep → ready …) refresh the sheet's chip + action list.
  // Falls back to the open-time snapshot if the line is gone (e.g. removed
  // after void), keeping the confirmed view intact.
  Ticket get _live {
    final list = ref.watch(ticketsForTableProvider(widget.tableId));
    for (final t in list) {
      if (t.id == widget.ticket.id) return t;
    }
    return widget.ticket;
  }

  Future<void> _pickAction(String id) async {
    final t = _live;
    final notifier = ref.read(ticketsProvider.notifier);
    final useCase = ref.read(advanceTicketStatusUseCaseProvider);
    switch (id) {
      case 'fire':
        await notifier.fireCourse(widget.tableId, t.course);
        if (mounted) Navigator.of(context).pop();
        break;
      case 'serve':
        await useCase.call(widget.tableId, t.id, TicketStatus.served);
        if (mounted) Navigator.of(context).pop();
        break;
      case 'unserve':
        // served → ready is the canonical undo path (see _allowedTransitions
        // in lib/server/routes/tickets_routes.dart).
        await useCase.call(widget.tableId, t.id, TicketStatus.ready);
        if (mounted) Navigator.of(context).pop();
        break;
      case 'modify':
        await _modify(t);
        break;
      case 'void':
        setState(() => _step = _Step.voidReason);
        break;
    }
  }

  /// Reopen the item configurator over a line that is already sent but still
  /// held. The sheet already knows how to edit (ADR-0060) — it is handed the
  /// line as a [CartItem] and gives back the edited one, so the modifier
  /// rendering, the price math and the required-group validation stay in the
  /// one place that owns them.
  Future<void> _modify(Ticket t) async {
    final item = ref
        .read(menuItemsProvider)
        .where((m) => m.id == t.itemId)
        .firstOrNull;
    if (item == null) return;
    final nav = Navigator.of(context);
    await showModifierSheet(
      context: context,
      item: item,
      editing: CartItem(
        id: t.id,
        itemId: t.itemId,
        name: t.name,
        // A ticket freezes the variant *name*, not its id (ADR-0011), so the
        // id is resolved against the menu as it reads now — the same thing the
        // server does at send. An empty fallback lets the sheet seed on its
        // default variant rather than refusing to open.
        variantId:
            item.variants
                .where((v) => v.name == t.variantName)
                .map((v) => v.id)
                .firstOrNull ??
            (item.variants.isNotEmpty ? item.variants.first.id : ''),
        variantName: t.variantName,
        selectedModifiers: t.modifiers,
        note: t.note ?? '',
        course: t.course,
        qty: t.qty,
        unitPrice: t.price,
      ),
      onAdd: (edited) async {
        await ref
            .read(ticketsProvider.notifier)
            .modifyLine(
              widget.tableId,
              t.id,
              qty: edited.qty,
              note: edited.note.isEmpty ? null : edited.note,
              modifiers: edited.selectedModifiers,
              unitPrice: edited.unitPrice,
            );
        if (nav.canPop()) nav.pop();
      },
    );
  }

  Future<void> _commitVoid() async {
    final t = _live;
    final reason = _reason!;
    setState(() => _committing = true);
    final bool queued;
    try {
      // Free text rides only for `other`. A fixed reason stores nothing but
      // its code — the label it used to store was whichever language the
      // waiter's phone happened to be in, frozen into the row. The server
      // composes the words from the code at read time (ADR-0085) and requires
      // text only for `other`.
      //
      // `actorId` names the waiter who voided, which matters only on a replay:
      // a drain runs under whoever is signed in then, and ADR-0006's whole
      // deterrent is that a void carries the name of whoever made it.
      queued = await ref
          .read(advanceTicketStatusUseCaseProvider)
          .call(
            widget.tableId,
            t.id,
            TicketStatus.voided,
            voidReason: _reasonText.trim(),
            voidReasonCode: reason,
            actorId: ref.read(authStateProvider).user?.id,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _committing = false;
        _failCode = voidFailCode(e, t.status);
        _step = _Step.failed;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _committing = false;
      _queued = queued;
      _step = _Step.confirmed;
    });
    // A queued void stays up longer: it says something the waiter has to
    // carry to the kitchen themselves.
    Future.delayed(Duration(milliseconds: queued ? 2600 : 1500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final ticket = _live;
    return Container(
      decoration: SatBox.d(
        color: sc.bg1,
        borderRadius: BorderRadius.vertical(top: SatR.c(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
            child: Container(
              width: 38,
              height: 4,
              decoration: SatBox.d(color: sc.textDim, borderRadius: SatR.a(4)),
            ),
          ),
          _LineActionHead(
            ticket: ticket,
            tableName:
                widget.displayName ??
                ref
                    .watch(tablesProvider)
                    .where((t) => t.id == widget.tableId)
                    .map((t) => t.displayName)
                    .firstOrNull ??
                widget.tableId,
            onClose: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: switch (_step) {
                _Step.actions => _ActionList(
                  ticket: ticket,
                  onPick: _pickAction,
                ),
                _Step.voidReason => _VoidReasonList(
                  canComp: ticket.status == TicketStatus.served,
                  busy: _committing,
                  onPick: (r, text) {
                    _reason = r;
                    _reasonText = text;
                    _commitVoid();
                  },
                ),
                _Step.confirmed => _ConfirmedView(
                  ticket: ticket,
                  queued: _queued,
                ),
                _Step.failed => _FailedView(
                  code: _failCode,
                  onBack: () => setState(() => _step = _Step.voidReason),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LineActionHead extends StatelessWidget {
  final Ticket ticket;
  final String tableName;
  final VoidCallback onClose;
  const _LineActionHead({
    required this.ticket,
    required this.tableName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return SatSheetHeader(
      onClose: onClose,
      padding: const EdgeInsets.fromLTRB(Sp.s4, Sp.s1h, Sp.s2, Sp.s3h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(status: ticket.status),
              const SizedBox(width: Sp.s2),
              Flexible(
                child: Text(
                  context.l10n.liaTableAt(tableName, ticket.sentAt),
                  style: SatType.monoS(color: sc.textLo),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s1h),
          Text(
            '×${ticket.qty} ${ticket.name}${ticket.variantName.isEmpty ? '' : ' · ${ticket.variantName}'}',
            style: SatType.h3(color: sc.textHi),
          ),
          if (ticket.modifiers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Sp.s1),
              child: Text(
                ticket.modifiers.map((m) => m.display).join(' · '),
                style: SatType.bodyS(color: sc.textMd),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionList extends ConsumerWidget {
  final Ticket ticket;
  final ValueChanged<String> onPick;
  const _ActionList({required this.ticket, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final rows = <_ActionItem>[];
    // A void is the only act here the [[Antrean kirim]] can carry (ADR-0114),
    // so it is the only one offered while terputus — the rule of ADR-0116, held
    // in the sheet as well as on the card behind it. Firing, editing and
    // serving all announce a kitchen fact and have nowhere to queue.
    final offline = ref.watch(wsConnStateProvider) != WsConnState.open;
    if (!offline && ticket.status == TicketStatus.held) {
      rows.add(
        _ActionItem(
          id: 'fire',
          icon: Icons.local_fire_department,
          title: context.l10n.liaFireNow,
          desc: context.l10n.liaFireDesc,
          tone: _Tone.accent,
        ),
      );
      // Editing is offered only here, and only here it is safe: once the line
      // is fired the kitchen owns it and the sole remedy is a void
      // (ADR-0071). The server enforces the same rule with a 409.
      //
      // `modifyOrder`, not `takeOrder`: `PATCH /tickets/<id>` costs the former
      // and the two are granted separately, so a venue that revoked amendment
      // from its floor got the row anyway and a 403 on tap (ADR-0132). Every
      // seeded role holding one holds the other, so this bites exactly the
      // venue that meant it.
      if (ref.watch(authStateProvider).has(Capability.modifyOrder)) {
        rows.add(
          _ActionItem(
            id: 'modify',
            icon: Icons.edit_outlined,
            title: context.l10n.liaEditItem,
            desc: context.l10n.liaEditDesc,
            tone: _Tone.normal,
          ),
        );
      }
    }
    if (!offline && ticket.status == TicketStatus.ready) {
      rows.add(
        _ActionItem(
          id: 'serve',
          icon: Icons.check,
          title: context.l10n.olcMarkServed,
          desc: context.l10n.liaServeDesc,
          tone: _Tone.success,
        ),
      );
    }
    if (!offline && ticket.status == TicketStatus.served) {
      rows.add(
        _ActionItem(
          id: 'unserve',
          icon: Icons.undo,
          title: context.l10n.liaUnserve,
          desc: context.l10n.liaUnserveDesc,
          tone: _Tone.normal,
        ),
      );
    }
    if (ticket.status != TicketStatus.voided) {
      // The graph names the capability this particular void costs — `voidItem`
      // pre-serve, `compItem` once the plate is down (ADR-0101). Read it here
      // rather than offering a button whose only outcome is a 403: the client
      // gate decides what to *offer*, the server still decides what is
      // allowed. Shown disabled with the reason rather than hidden, because a
      // button that vanished teaches nobody why.
      final needed = capabilityForTransition(
        ticket.status,
        TicketStatus.voided,
      );
      final allowed =
          needed != null && ref.watch(authStateProvider).has(needed);
      rows.add(
        _ActionItem(
          id: 'void',
          icon: Icons.delete_outline,
          title: context.l10n.liaVoidItem,
          desc: allowed
              ? context.l10n.liaVoidDesc
              : needed == Capability.compItem
              ? context.l10n.liaVoidNeedsManager
              : context.l10n.liaVoidNoCap,
          tone: _Tone.danger,
          enabled: allowed,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        children: [
          for (final r in rows) ...[
            _ActionRow(item: r, onTap: () => onPick(r.id)),
            const SizedBox(height: Sp.s1h),
          ],
          const SizedBox(height: 60),
          Text(
            context.l10n.liaTapOutside,
            style: SatType.bodyS(color: sc.textLo),
          ),
        ],
      ),
    );
  }
}

enum _Tone { normal, accent, warn, success, danger }

class _ActionItem {
  final String id;
  final IconData icon;
  final String title;
  final String desc;
  final _Tone tone;

  /// False renders the row dimmed and inert. [desc] then carries the reason —
  /// a disabled row that does not say why is a support call.
  final bool enabled;
  _ActionItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.desc,
    required this.tone,
    this.enabled = true,
  });
}

class _ActionRow extends StatelessWidget {
  final _ActionItem item;
  final VoidCallback onTap;
  const _ActionRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    Color border = sc.border0;
    Color iconBg = sc.bg3;
    Color iconFg = sc.textMd;
    Color titleColor = sc.textHi;
    switch (item.tone) {
      case _Tone.danger:
        border = sc.urgent.withValues(alpha: 0.2);
        iconBg = sc.urgentSoft;
        iconFg = sc.urgent;
        titleColor = sc.urgent;
        break;
      case _Tone.accent:
        border = sc.accentBorder;
        iconBg = sc.accentSoft;
        iconFg = sc.accentText;
        break;
      case _Tone.warn:
        border = sc.warn.withValues(alpha: 0.25);
        iconBg = sc.warnSoft;
        iconFg = sc.warn;
        break;
      case _Tone.success:
        border = sc.success.withValues(alpha: 0.25);
        iconBg = sc.successSoft;
        iconFg = sc.success;
        break;
      case _Tone.normal:
        break;
    }
    if (!item.enabled) {
      // Dim the whole row rather than only the label: a red icon over grey
      // text reads as an available danger action at arm's length, which is
      // the one glance this screen is designed for.
      border = sc.border0;
      iconBg = sc.bg3;
      iconFg = sc.textLo;
      titleColor = sc.textLo;
    }
    return Material(
      color: sc.bg2,
      borderRadius: SatR.a(14),
      child: InkWell(
        onTap: item.enabled ? onTap : null,
        borderRadius: SatR.a(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.s3h,
            vertical: Sp.s3,
          ),
          decoration: SatBox.d(
            borderRadius: SatR.a(14),
            border: SatB.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: SatBox.d(color: iconBg, borderRadius: SatR.a(10)),
                alignment: Alignment.center,
                child: Icon(item.icon, size: 18, color: iconFg),
              ),
              const SizedBox(width: Sp.s3h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: SatType.labelM(color: titleColor)),
                    const SizedBox(height: Sp.sHair),
                    Text(item.desc, style: SatType.bodyS(color: sc.textMd)),
                  ],
                ),
              ),
              Icon(
                item.enabled ? Icons.chevron_right : Icons.lock_outline,
                size: 16,
                color: sc.textLo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoidReasonList extends StatefulWidget {
  final void Function(String reasonCode, String text) onPick;

  /// The commit is in flight. The button goes inert rather than firing a
  /// second void at a host that is merely slow.
  final bool busy;

  /// Whether the line has already been served — the case that requires
  /// `compItem` rather than `voidItem`, and the only one where "gratis" is a
  /// real answer rather than a way to lose money quietly.
  final bool canComp;
  const _VoidReasonList({
    required this.onPick,
    required this.canComp,
    this.busy = false,
  });

  @override
  State<_VoidReasonList> createState() => _VoidReasonListState();
}

class _VoidReasonListState extends State<_VoidReasonList> {
  String? _pickedId;
  String _other = '';

  List<String> get _reasons => [
    ..._voidReasons.where((r) => r != 'other'),
    if (widget.canComp) _compReason,
    ..._voidReasons.where((r) => r == 'other'),
  ];

  bool get _canContinue =>
      !widget.busy &&
      _pickedId != null &&
      (_pickedId != 'other' || _other.trim().length >= 3);

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: Sp.s3h),
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.s3,
              vertical: Sp.s2h,
            ),
            decoration: SatBox.d(
              color: sc.bg2,
              borderRadius: SatR.a(12),
              border: SatB.all(color: sc.border0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: sc.warn),
                const SizedBox(width: Sp.s2),
                Expanded(
                  child: Text(
                    context.l10n.liaVoidWarning,
                    style: SatType.bodyS(color: sc.textMd),
                  ),
                ),
              ],
            ),
          ),
          for (final r in _reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s1h),
              child: Material(
                color: _pickedId == r ? sc.accentSoft : sc.bg2,
                borderRadius: SatR.a(14),
                child: InkWell(
                  onTap: () => setState(() => _pickedId = r),
                  borderRadius: SatR.a(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sp.s3h,
                      vertical: Sp.s3,
                    ),
                    decoration: SatBox.d(
                      borderRadius: SatR.a(14),
                      border: SatB.all(
                        color: _pickedId == r ? sc.accentBorder : sc.border0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: SatBox.d(
                            color: _pickedId == r
                                ? sc.accent
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: SatB.all(
                              color: _pickedId == r ? sc.accent : sc.border2,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: _pickedId == r
                              ? Icon(Icons.check, size: 14, color: sc.accentInk)
                              : null,
                        ),
                        const SizedBox(width: Sp.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r == _compReason
                                    ? context.l10n.vrsComp
                                    : voidReasonLabel(context.l10n, r),
                                style: SatType.bodyM(color: sc.textHi),
                              ),
                              const SizedBox(height: Sp.sHair),
                              Text(
                                r == _compReason
                                    ? context.l10n.vrsCompDesc
                                    : voidReasonDesc(context.l10n, r),
                                style: SatType.bodyS(color: sc.textMd),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_pickedId == 'other')
            Padding(
              padding: const EdgeInsets.only(top: Sp.s1),
              child: SatField.text(
                hint: context.l10n.liaVoidReasonHint,
                maxLength: 120,
                // Red before it is wrong: the reason gates the void, so the
                // field wears the same border it would on rejection.
                hasError: _other.trim().isEmpty,
                onChanged: (v) => setState(() => _other = v),
              ),
            ),
          const SizedBox(height: Sp.s4),
          SizedBox(
            width: double.infinity,
            child: SatButton.primary(
              label: context.l10n.liaVoidItem,
              icon: Icons.delete_outline,
              size: SatButtonSize.lg,
              onTap: _canContinue
                  ? () {
                      widget.onPick(
                        _pickedId!,
                        _pickedId == 'other' ? _other.trim() : '',
                      );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmedView extends StatelessWidget {
  final Ticket ticket;

  /// The host has not heard this yet — it is on the device's [[Antrean kirim]]
  /// (ADR-0090). Same view, one honest extra sentence: the kitchen may still
  /// be cooking the dish.
  final bool queued;
  const _ConfirmedView({required this.ticket, this.queued = false});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: _outcomePadding,
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: SatBox.d(
              shape: BoxShape.circle,
              color: sc.urgent.withValues(alpha: 0.16),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.delete_outline, size: 46, color: sc.urgent),
          ),
          const SizedBox(height: Sp.s4),
          Text(context.l10n.liaVoided, style: SatType.h2(color: sc.textHi)),
          const SizedBox(height: Sp.s2),
          Text(
            queued
                ? context.l10n.liaVoidedQueued(ticket.qty, ticket.name)
                : context.l10n.liaVoidedNote(ticket.qty, ticket.name),
            textAlign: TextAlign.center,
            style: SatType.bodyM(color: queued ? sc.warn : sc.textMd),
          ),
        ],
      ),
    );
  }
}

/// Why the void did not happen, and the way back to the reason list.
///
/// Inline rather than a snackbar behind a dismissed sheet: the waiter is
/// standing in the sheet that just refused them, and half of these are
/// recoverable by picking a different reason or handing the phone to someone
/// who holds `compItem`.
class _FailedView extends StatelessWidget {
  final String? code;
  final VoidCallback onBack;
  const _FailedView({required this.code, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Padding(
      padding: _outcomePadding,
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: SatBox.d(
              shape: BoxShape.circle,
              color: sc.warn.withValues(alpha: 0.16),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.error_outline, size: 46, color: sc.warn),
          ),
          const SizedBox(height: Sp.s4),
          Text(context.l10n.liaVoidFailed, style: SatType.h2(color: sc.textHi)),
          const SizedBox(height: Sp.s2),
          Text(
            voidFailureText(context.l10n, code),
            textAlign: TextAlign.center,
            style: SatType.bodyM(color: sc.textMd),
          ),
          const SizedBox(height: Sp.s4),
          SizedBox(
            width: double.infinity,
            child: SatButton.neutral(
              label: context.l10n.back,
              size: SatButtonSize.lg,
              onTap: onBack,
            ),
          ),
        ],
      ),
    );
  }
}
