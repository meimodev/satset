import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/localization/report_copy.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/data/models/visit_expense_dto.dart';
import 'package:satset/data/repositories/visit_expense_repository.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/send_queue_service.dart';
import 'package:satset/data/services/settlement_sync.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/proof_photo.dart';
import 'package:satset/ui/core/widgets/sat_button.dart';
import 'package:satset/ui/core/widgets/sat_chip.dart';
import 'package:satset/ui/core/widgets/sat_field.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/ui/core/widgets/sat_sheet_header.dart';
import 'package:satset/ui/core/widgets/sat_spinner.dart';

/// Record a **[[Pengeluaran kunjungan]]** against the visit being served
/// (ADR-0130).
///
/// Opened from the [[Visit]]'s surfaces — table detail's context sheet and the
/// [[Cashier]] bill overlay — never from a table tile, so a [[Kedai]] venue
/// with no floor still reaches it.
///
/// Three things this sheet must keep being:
///
/// - **capped, visibly.** The room left is on screen before the refusal fires,
///   not after — a waiter who has already spent the money cannot act on a
///   surprise.
/// - **photo-mandatory.** No skip affordance, and a denied camera permission is
///   a blocking error rather than a bypass (ADR-0130). Softening it here is how
///   "mandatory" quietly becomes "optional" in the one case where it bites.
/// - **silent about the bill.** Nothing here moves a total, an outstanding or a
///   receipt. If a number on the settle pane moved, this is wrong.
Future<bool?> showVisitExpenseSheet(
  BuildContext context, {
  required String visitId,
  String? tableId,
}) => showSatSheet<bool>(
  context,
  builder: (_) => _VisitExpenseSheet(visitId: visitId, tableId: tableId),
);

class _VisitExpenseSheet extends ConsumerStatefulWidget {
  final String visitId;
  final String? tableId;
  const _VisitExpenseSheet({required this.visitId, this.tableId});

  @override
  ConsumerState<_VisitExpenseSheet> createState() => _VisitExpenseSheetState();
}

class _VisitExpenseSheetState extends ConsumerState<_VisitExpenseSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _categoryId;
  Uint8List? _photo;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  /// Why the button is off, in the order a person fills the form in.
  String? _blocker(AppL10n l10n, int remaining) {
    if (_value <= 0) return l10n.tableExpBlkAmount;
    if (_categoryId == null) return l10n.tableExpBlkCategory;
    if (_photo == null) return l10n.tableExpBlkPhoto;
    if (_value > remaining) {
      return l10n.tableExpBlkOverCap(formatIDR(remaining));
    }
    return null;
  }

  Future<void> _shoot() async {
    final l10n = context.l10n;
    try {
      final bytes = await shootProofPhoto();
      if (bytes == null) return;
      if (mounted) setState(() => _photo = bytes);
    } catch (e) {
      // Surfaced, never swallowed: with the photo mandatory, a silent failure
      // leaves the waiter tapping a disabled button with no reason given.
      if (mounted) setState(() => _error = l10n.tableExpPhotoFailed('$e'));
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final id = newExpenseId();
    // Client-minted online too, and the same key either way (ADR-0123): the
    // capture that goes straight to the host and the one that is queued are the
    // same act, so a retry after a lost reply must not become a second expense.
    try {
      // The socket is the test, not the last request: a handset that has lost
      // the host queues rather than waiting out a timeout the waiter is stood
      // there for (ADR-0090).
      if (ref.read(wsConnStateProvider) != WsConnState.open) {
        await _queue(id);
      } else {
        await ref
            .read(apiClientProvider)
            .postJson('/visits/${widget.visitId}/expenses', {
              'id': id,
              'amount': _value,
              'categoryId': _categoryId,
              'note': _note.text.trim(),
              'photoBase64': base64Encode(_photo!),
            }, idempotencyKey: id);
      }
      ref.invalidate(visitExpensesProvider(widget.visitId));
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = visitExpenseErrorText(context.l10n, _codeOf(e));
      });
    } catch (e) {
      // Transport: the host was there a moment ago and is not now. Capture it
      // rather than losing it — the waiter has already spent the money.
      try {
        await _queue(id);
        ref.invalidate(visitExpensesProvider(widget.visitId));
        if (mounted) Navigator.of(context).pop(true);
        return;
      } catch (_) {
        // fall through to the original failure, which is the honest one
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  /// Park the act in the [[Antrean kirim]] and its photo in the client
  /// database, keyed the same way. The queue is a prefs blob and cannot hold
  /// the bytes (ADR-0130).
  Future<void> _queue(String id) async {
    await ref
        .read(settlementJournalProvider.notifier)
        .parkExpensePhoto(id, _photo!);
    await ref
        .read(sendQueueProvider.notifier)
        .enqueue(
          id: id,
          kind: SendIntentKind.tableExpense,
          // The queue keys intents by table; the route is addressed by visit,
          // so the visit rides the payload and the table stays the queue's own
          // handle on where this happened.
          tableId: widget.tableId ?? '',
          actorId: ref.read(authStateProvider).user?.id ?? '',
          expectedVisitId: widget.visitId,
          payload: {
            'visitId': widget.visitId,
            'amount': _value,
            'categoryId': _categoryId,
            'note': _note.text.trim(),
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final cats = ref.watch(expenseCategoriesRepositoryProvider);
    final summary = ref.watch(visitExpensesProvider(widget.visitId));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: Sp.s4,
          right: Sp.s4,
          bottom: Sp.s4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SatSheetHeader(
              padding: const EdgeInsets.only(top: Sp.s3, bottom: Sp.s2),
              onClose: () => Navigator.of(context).pop(),
              child: Text(
                l10n.tableExpTitle,
                style: SatType.h3(color: sc.textHi),
              ),
            ),
            summary.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: Sp.s6),
                child: Center(child: SatSpinner()),
              ),
              // No cached bill means no cap, and an uncapped capture is a cap
              // you defeat by turning off Wi-Fi (ADR-0130). Refuse, and say why.
              error: (_, _) => Text(
                l10n.tableExpOffline,
                style: SatType.bodyM(color: sc.warn),
              ),
              data: (s) => _form(context, sc, l10n, cats, s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(
    BuildContext context,
    SatColors sc,
    AppL10n l10n,
    List<VisitExpenseCategoryDto> cats,
    VisitExpenseSummaryDto summary,
  ) {
    final pickable = ref
        .read(expenseCategoriesRepositoryProvider.notifier)
        .pickable;
    final remaining = summary.remaining;
    final blocker = _blocker(l10n, remaining);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The two numbers together: what the visit is worth, and what is left
        // of it. Either alone cannot say the sentence that matters.
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.tableExpCap(formatIDR(summary.cap)),
                style: SatType.monoS(color: sc.textLo),
              ),
            ),
            Text(
              l10n.tableExpRemaining(formatIDR(remaining)),
              style: SatType.monoL(
                color: remaining > 0 ? sc.accent : sc.urgent,
              ),
            ),
          ],
        ),
        if (summary.offline) ...[
          const SizedBox(height: Sp.s1),
          Text(
            l10n.tableExpProvisional,
            style: SatType.bodyS(color: sc.warn),
          ),
        ],
        if (summary.total > 0) ...[
          const SizedBox(height: Sp.s1),
          Text(
            l10n.tableExpSpent(formatIDR(summary.total)),
            style: SatType.bodyS(color: sc.textDim),
          ),
        ],
        const SizedBox(height: Sp.s4),
        SatField.money(
          controller: _amount,
          label: l10n.tableExpAmount,
          hint: '0',
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Sp.s3),
        Text(l10n.tableExpCategory, style: SatType.labelS(color: sc.textLo)),
        const SizedBox(height: Sp.s2),
        if (pickable.isEmpty)
          Text(
            l10n.tableExpNoCategories,
            style: SatType.bodyS(color: sc.textDim),
          )
        else
          Wrap(
            spacing: Sp.s2,
            runSpacing: Sp.s2,
            children: [
              for (final c in pickable)
                SatChip.select(
                  // Venue-authored content, so it is ARB-exempt — like a menu
                  // item's name.
                  label: c.name,
                  selected: _categoryId == c.id,
                  onTap: () => setState(() => _categoryId = c.id),
                ),
            ],
          ),
        const SizedBox(height: Sp.s3),
        SatButton.outline(
          label: _photo == null
              ? l10n.tableExpPhoto
              : l10n.tableExpPhotoAttached,
          icon: Icons.photo_camera_rounded,
          onTap: _shoot,
        ),
        const SizedBox(height: Sp.s3),
        SatField.text(
          controller: _note,
          label: l10n.tableExpNote,
          hint: '',
        ),
        if (_error != null) ...[
          const SizedBox(height: Sp.s3),
          Text(_error!, style: SatType.bodyS(color: sc.urgent)),
        ],
        const SizedBox(height: Sp.s4),
        SatButton.primary(
          label: blocker ?? l10n.tableExpSubmit(formatIDR(_value)),
          icon: Icons.receipt_long_rounded,
          onTap: blocker != null || _busy ? null : _submit,
        ),
      ],
    );
  }
}

/// The server sends a code, never a sentence (ADR-0085).
String _codeOf(ApiException e) {
  if (e.code != null && e.code!.isNotEmpty) return e.code!;
  try {
    final body = jsonDecode(e.body);
    if (body is Map && body['code'] is String) return body['code'] as String;
  } catch (_) {}
  return '${e.statusCode}';
}
