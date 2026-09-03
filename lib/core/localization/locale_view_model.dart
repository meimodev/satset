import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/l10n/app_localizations.dart';

/// The two locales SatSet ships. Indonesian is first because it is the default
/// and the language the copy is authored in, not merely the first alphabetically.
const List<Locale> satSupportedLocales = [Locale('id'), Locale('en')];

/// The hard default (ADR-0083). Deliberately **not** resolved from the platform:
/// the tablets a small Indonesian venue actually buys ship with system locale
/// `en_US` untouched, so following the system would boot a warung's till into
/// English on first run — a worse first five minutes than one setting can be.
const Locale satDefaultLocale = Locale('id');

/// The **[[Kata layanan]]** country subtag (ADR-0127).
///
/// Not a country: `SV` is borrowed as a *variant* marker, because gen-l10n
/// resolves `app_id_SV.arb` from `Locale('id', 'SV')` and nothing else in the
/// app resolves a locale from the platform — the language is picked on `/me`
/// and this half is picked by the venue. Borrowing the region slot is what
/// lets one ARB file override ~120 strings and inherit the other ~3900,
/// instead of a second generator or 120 branches at call sites.
const String serviceTermSubtag = 'SV';

Locale _localeFromTag(String? tag, {required bool serviceTerm}) {
  final lang = switch (tag) {
    'en' => 'en',
    'id' => 'id',
    _ => satDefaultLocale.languageCode,
  };
  return Locale(lang, serviceTerm ? serviceTermSubtag : null);
}

/// Device-local language selection (ADR-0083).
///
/// Mirrors `SatThemeNotifier` deliberately — same scope, same seeding, same
/// write-through. A device that has chosen English swaps to it as soon as prefs
/// resolve; until then the default renders, so the first frame never waits on
/// disk.
/// The active strings, reachable from code that has **neither** a
/// `BuildContext` nor a `Ref`: the ESC/POS renderers and the CSV/PDF exporters.
///
/// Those run inside the embedded server (`lib/server/routes/`), which is
/// constructed from a Drift database and a `WsHub` and never sees Riverpod. A
/// receipt is rendered by whichever device holds the printer, so "the language
/// of this device" — exactly what the picker sets — is the right answer for it.
///
/// Kept in step by [SatLocaleNotifier] the same way, and for the same reason,
/// as `Intl.defaultLocale` beside it: one process-wide switch is cheaper than
/// threading a locale through every formatter and byte-builder in the app.
/// Prefer `context.l10n` or [l10nProvider] wherever either is in reach.
AppL10n satL10n = lookupAppL10n(satDefaultLocale);

class SatLocaleNotifier extends StateNotifier<Locale> {
  SatLocaleNotifier(this._prefs, this._serviceTerm)
    : super(_localeFromTag(_prefs?.localeTag(), serviceTerm: _serviceTerm)) {
    _sync(state);
  }

  final PrefsService? _prefs;

  /// Whether this venue calls a table a **Layanan · Service** (ADR-0127). Not
  /// a device setting and not on the picker: it arrives with the venue's own
  /// shape and the device has no say, which is why only the language half is
  /// written back to prefs.
  final bool _serviceTerm;

  /// `format.dart` builds its `DateFormat`s against `Intl.defaultLocale`, which
  /// is how a date follows the picker without every widget threading a locale
  /// into a formatter. Money does **not** read this — `formatIDR` and
  /// `groupRupiah` name `id_ID` explicitly, in both languages (ADR-0084).
  static void _sync(Locale l) {
    Intl.defaultLocale = l.languageCode == 'en' ? 'en_US' : 'id_ID';
    satL10n = lookupAppL10n(l);
  }

  Future<void> select(Locale l) async {
    final next = _localeFromTag(l.languageCode, serviceTerm: _serviceTerm);
    if (state == next) return;
    SatLog.vm('Locale select ${next.languageCode}${next.countryCode ?? ''}');
    state = next;
    _sync(next);
    await _prefs?.setLocaleTag(next.languageCode);
  }
}

/// Language from the device, vocabulary from the venue (ADR-0083 + ADR-0127).
///
/// The venue half is watched rather than read once, so a fleet toggle lands
/// when the settings mirror does instead of waiting for a cold boot — and
/// because `VenueSettingsRepository` paints its cached shape before the fetch,
/// a handset that boots away from its host still opens in the right words.
final satLocaleProvider = StateNotifierProvider<SatLocaleNotifier, Locale>((
  ref,
) {
  final prefs = ref.watch(prefsServiceProvider).valueOrNull;
  final serviceTerm = ref.watch(
    venueSettingsProvider.select((s) => s.serviceTerm),
  );
  return SatLocaleNotifier(prefs, serviceTerm);
});

/// The strings, reachable **without a `BuildContext`**.
///
/// This is what lets the exporters, `auth_error.dart` and every other
/// non-widget caller read copy — `AppL10n.of(context)` cannot serve them, and
/// threading a context down into a CSV writer to fetch a column header would be
/// worse than the problem. `lookupAppL10n` is a generated top-level function,
/// so nothing here depends on the widget tree.
final l10nProvider = Provider<AppL10n>(
  (ref) => lookupAppL10n(ref.watch(satLocaleProvider)),
);

/// The strings, for widgets. `context.l10n.cancel` reads like the
/// `AppStrings.cancel` it replaces.
///
/// Prefer this over [l10nProvider] anywhere a `BuildContext` is in hand: it is
/// an inherited-widget lookup rather than a provider subscription, and
/// `MaterialApp.locale` is driven from [satLocaleProvider], so the two can
/// never disagree.
extension L10nContext on BuildContext {
  AppL10n get l10n => AppL10n.of(this);
}
