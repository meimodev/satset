import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Auto-loaded by `flutter test` for every suite in this directory.
///
/// Exists to retire a hack. `format.dart` used to carry hand-rolled
/// `_idShortDays` / `_idShortMonths` arrays purely so a widget test could mount
/// the top bar or a shell banner without throwing `LocaleDataException` — the
/// real app loads symbols in `main()`, but a widget test never runs `main()`.
///
/// Once dates had to localise (ADR-0084) that hack could not survive: a second
/// pair of English arrays would have been the same bug twice, and it printed
/// `Sab` inside an English shell. Loading the symbols here instead means the
/// production formatters are the ones under test.
///
/// `Intl.defaultLocale` is pinned to the app's own default, so a test that does
/// not say otherwise formats exactly as a fresh install does.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting('id_ID');
  await initializeDateFormatting('en_US');
  Intl.defaultLocale = 'id_ID';
  await testMain();
}
