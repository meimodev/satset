// The Piutang option's gate, which had a deadlock in the settle pane.
//
// The settle pane picks the debtor *after* the method (ADR-0125) and only
// draws the debtor row once Piutang is selected — so gating the option on a
// known debtor made Piutang unreachable there for good, with no error to see.
// The per-struk pay sheet keeps the old gate: its debtor comes off the receipt
// or the bill, so "nobody to charge" is a real answer there.
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/member_dto.dart';
import 'package:satset/domain/models/member.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/ui/features/cashier/widgets/pay_method_picker.dart';

MemberDto _member({required int limit, int debt = 0}) => MemberDto(
  member: Member(
    id: 'm1',
    name: 'Budi',
    phone: '08',
    joinedAt: DateTime(2026),
    debt: debt,
    debtLimit: limit,
  ),
);

void main() {
  late AppL10n l10n;

  setUpAll(() async {
    l10n = await AppL10n.delegate.load(const Locale('id'));
  });

  test('settle pane: no debtor yet is not a reason to hide Piutang', () {
    expect(piutangOffReason(l10n, null, pickable: true), isNull);
  });

  test('pay sheet: no debtor still hides it, with a reason', () {
    expect(piutangOffReason(l10n, null), isNotNull);
  });

  test('no credit left blocks either way', () {
    final broke = _member(limit: 0);
    expect(piutangOffReason(l10n, broke, pickable: true), isNotNull);
    expect(piutangOffReason(l10n, broke), isNotNull);
  });

  test('headroom left is live', () {
    final ok = _member(limit: 500000, debt: 100000);
    expect(piutangOffReason(l10n, ok, pickable: true), isNull);
    expect(piutangOffReason(l10n, ok), isNull);
  });
}
