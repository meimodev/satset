import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/venue_module.dart';
import 'package:satset/l10n/app_localizations.dart';

/// ADR-0127. The [[Kata layanan]] switch has exactly two moving parts: a
/// fail-closed read of a mode key, and a locale that resolves to the variant
/// ARB. Both are one-liners, and both are the kind of one-liner that fails
/// silently — a fail-open read renames every unmirrored restaurant's floor, and
/// a locale that misses its variant renders the restaurant word at a salon with
/// nothing in the logs.
void main() {
  test('the mode key fails closed', () {
    // Never mirrored. A sellable module would read this as entitled; a mode
    // must not.
    expect(const VenueSettingsDto().serviceTerm, isFalse);
    expect(const VenueSettingsDto(modules: []).serviceTerm, isFalse);
    expect(
      const VenueSettingsDto(modules: [moduleMembers]).serviceTerm,
      isFalse,
    );
    expect(
      const VenueSettingsDto(modules: [modeServiceTerm]).serviceTerm,
      isTrue,
    );
  });

  test('it is independent of the other mode keys', () {
    const dto = VenueSettingsDto(modules: [modeServiceTerm]);
    expect(dto.counterMode, isFalse);
    expect(dto.bypassKds, isFalse);
  });

  test('the variant locale swaps the noun and inherits the rest', () {
    final id = lookupAppL10n(const Locale('id'));
    final idSv = lookupAppL10n(const Locale('id', 'SV'));
    final en = lookupAppL10n(const Locale('en'));
    final enSv = lookupAppL10n(const Locale('en', 'SV'));

    expect(id.tabMeja, 'Meja');
    expect(idSv.tabMeja, 'Layanan');
    expect(en.tabMeja, 'Floor');
    expect(enSv.tabMeja, 'Services');

    // Inherited: a string that never names a table is not duplicated.
    expect(idSv.cancel, id.cancel);
    expect(enSv.cancel, en.cancel);

    // The service *charge* is renamed in every venue, both modes, so the word
    // "Layanan" means one thing on a receipt.
    expect(id.strukService, 'Biaya layanan');
    expect(idSv.strukService, 'Biaya layanan');
    expect(en.strukService, 'Service charge');
  });
}
