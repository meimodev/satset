import 'package:flutter/material.dart';

import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/data/models/bill_dto.dart';
import 'package:satset/data/models/member_dto.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/ui/core/widgets/sat_dropdown.dart';

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

  IconData get icon => switch (this) {
    PayMethod.tunai => Icons.payments_outlined,
    PayMethod.qris => Icons.qr_code_2_rounded,
    PayMethod.kartu => Icons.credit_card_rounded,
    PayMethod.transfer => Icons.account_balance_rounded,
    PayMethod.lainnya => Icons.more_horiz_rounded,
    PayMethod.piutang => Icons.account_circle_outlined,
  };

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

  static PayMethod? byId(String id) {
    for (final m in PayMethod.values) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// Whose tab a `piutang` payment on [receipt] would charge: the
/// [[Pemilik struk]], falling back to the [[Pemilik tagihan]] (ADR-0120).
///
/// The same subtraction `memberUnitsOf` and `pointsBaseByMember` make on the
/// server. It lives here rather than in each caller because the till gates the
/// dropdown on this member's headroom and the server charges this member — two
/// copies of one rule is how the option goes live for a tab the server refuses.
MemberDto? debtorFor(Bill bill, {MemberDto? receiptMember}) =>
    receiptMember ?? bill.member;

/// Why the Piutang option is off, or null when it is live. A reason on screen
/// beats a missing option without explanation — Principle 3.
String? piutangOffReason(AppL10n l10n, MemberDto? debtor) {
  if (debtor == null) return l10n.stlPiutangNoMember;
  if (debtor.debtHeadroom <= 0) return l10n.stlPiutangNoRoom;
  return null;
}

/// The payment method picker dropdown, shared by the settle pane and the
/// per-struk pay sheet.
///
/// **There is no lock.** A bill-wide one used to collapse this dropdown to whatever
/// method paid first; `CONTEXT.md` has always described a struk holding part
/// Tunai part Kartu, the lock made that unreachable, and it is gone (ADR-0121).
/// Two copies of the dropdown is how one surface keeps a rule the other dropped,
/// which is why this is a widget rather than a method on each screen.
class PayMethodPicker extends StatelessWidget {
  final PayMethod selected;
  final ValueChanged<PayMethod> onPick;

  /// Whether the venue runs tabs at all (ADR-0098). When false the Piutang
  /// option is absent rather than disabled — there is nothing to explain.
  final bool debtEnabled;

  /// Whose tab this payment would charge, from [debtorFor].
  final MemberDto? debtor;

  /// Sits above the field, in caps — same treatment as [SatField]'s.
  final String? label;

  const PayMethodPicker({
    super.key,
    required this.selected,
    required this.onPick,
    required this.debtEnabled,
    required this.debtor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final l10n = context.l10n;
    final offReason = piutangOffReason(l10n, debtor);
    final includePiutang =
        debtEnabled && (offReason == null || selected == PayMethod.piutang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SatDropdown<PayMethod>(
          key: ValueKey(selected),
          value: selected,
          label: label,
          options: [
            for (final m in PayMethod.values)
              if (m != PayMethod.piutang || includePiutang)
                SatOption(
                  m,
                  m.label(l10n),
                  icon: m.icon,
                  iconColor: m == PayMethod.tunai
                      ? sc.success
                      : (m == PayMethod.piutang ? sc.warn : sc.accentText),
                ),
          ],
          onChanged: (m) {
            if (m != null) onPick(m);
          },
        ),
        if (debtEnabled && offReason != null) ...[
          const SizedBox(height: Sp.s2),
          Text(offReason, style: SatType.bodyS(color: sc.textLo)),
        ],
      ],
    );
  }
}
