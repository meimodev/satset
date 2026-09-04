import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/venue_module.dart';

/// ADR-0130. The [[Pengeluaran kunjungan]] gate has two moving parts, and both
/// are the kind of one-liner that fails silently: a fail-**closed** read of a
/// mode key, and the AND with the owner's own switch.
///
/// The direction matters more here than for the other four mode keys. A
/// fail-open read of `members` costs a venue a feature it paid for; a fail-open
/// read of this one hands a revenue-reducing write to the floor of every venue
/// that has never phoned home.
void main() {
  test('the mode key fails closed', () {
    // Never mirrored. `hasModule` would read this as entitled — a mode must not.
    expect(
      const VenueSettingsDto(tableExpenseEnabled: true).tableExpenseOn,
      isFalse,
    );
    expect(
      const VenueSettingsDto(
        tableExpenseEnabled: true,
        modules: [],
      ).tableExpenseOn,
      isFalse,
    );
    expect(
      const VenueSettingsDto(
        tableExpenseEnabled: true,
        modules: [moduleMembers],
      ).tableExpenseOn,
      isFalse,
    );
    expect(
      const VenueSettingsDto(
        tableExpenseEnabled: true,
        modules: [modeTableExpense],
      ).tableExpenseOn,
      isTrue,
    );
  });

  test('the entitlement alone does not open it', () {
    // The owner's switch is the other half. Holding the key while the owner has
    // not opted in is the "they can" / "they want" pair ADR-0107 keeps apart.
    expect(
      const VenueSettingsDto(modules: [modeTableExpense]).tableExpenseOn,
      isFalse,
    );
    expect(const VenueSettingsDto().tableExpenseEnabled, isFalse);
  });

  test('it is independent of the other mode keys', () {
    const dto = VenueSettingsDto(
      tableExpenseEnabled: true,
      modules: [modeTableExpense],
    );
    expect(dto.counterMode, isFalse);
    expect(dto.bypassKds, isFalse);
    expect(dto.serviceTerm, isFalse);
    expect(dto.memberSplitOn, isFalse);

    // And the traffic runs the other way too: a counter shop is not opted in.
    const kedai = VenueSettingsDto(modules: [modeCounterService]);
    expect(kedai.tableExpenseOn, isFalse);
  });

  /// The two lists are declared in two languages and the comment in each file
  /// says they must stay equal. Nothing enforced it until now — and the cost of
  /// a drift is silent: the console writes an `addOns` key the client has never
  /// heard of, or refuses one it needs, with no error either way.
  test('venueModeKeys equals MODE_MODULES in functions/index.js', () {
    final src = File('functions/index.js').readAsStringSync();
    for (final (dart, jsName) in [
      (venueModuleKeys, 'MODULES'),
      (venueModeKeys, 'MODE_MODULES'),
    ]) {
      final m = RegExp('const $jsName = (\\[[^\\]]*\\]);').firstMatch(src);
      expect(
        m,
        isNotNull,
        reason: 'could not find $jsName in functions/index.js',
      );
      // Quoted strings only: the JS literal is prettier-wrapped and carries a
      // trailing comma, which is legal there and not in JSON.
      final js = RegExp('"([^"]+)"')
          .allMatches(m!.group(1)!)
          .map((q) => q.group(1)!)
          .toList();
      expect(
        js,
        dart,
        reason:
            '$jsName has drifted from its Dart twin. These are persisted keys '
            '(ADR-0107): the console writes them and the mirror carries them '
            'down, so a key on one side only is silently un-entitled.',
      );
    }
  });
}
