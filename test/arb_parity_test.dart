import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ADR-0083. `flutter gen-l10n` only **warns** when a key is missing from a
/// locale, and a warning scrolling past in CI is how a half-translated release
/// ships. These fail instead.
///
/// The literal ban that keeps new copy out of the widgets lives in
/// `design_tokens_test.dart`, beside the other bans.
void main() {
  final dir = Directory('lib/l10n');

  Map<String, dynamic> load(String name) =>
      jsonDecode(File('${dir.path}/$name').readAsStringSync())
          as Map<String, dynamic>;

  /// Message keys only — `@@locale` and the `@key` metadata blocks are not
  /// translatable content and are allowed to differ (the template carries the
  /// placeholder declarations; the other locales inherit them).
  Set<String> messages(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  late Map<String, dynamic> id;
  late Map<String, dynamic> en;

  setUpAll(() {
    id = load('app_id.arb');
    en = load('app_en.arb');
  });

  test('every locale carries exactly the same message keys', () {
    final a = messages(id);
    final b = messages(en);
    expect(
      a.difference(b),
      isEmpty,
      reason:
          'missing from app_en.arb — an English build would show these '
          'keys untranslated or blank',
    );
    expect(
      b.difference(a),
      isEmpty,
      reason:
          'present in app_en.arb but not in the app_id.arb template — '
          'gen-l10n generates from the template, so these are dead',
    );
  });

  test('no message is left empty', () {
    for (final arb in [id, en]) {
      final locale = arb['@@locale'];
      for (final k in messages(arb)) {
        expect(
          (arb[k] as String).trim(),
          isNotEmpty,
          reason:
              '$locale/$k is blank — a blank string renders as a gap, '
              'which reads as a layout bug rather than a missing translation',
        );
      }
    }
  });

  test('a placeholder used in one locale exists in the other', () {
    final ph = RegExp(r'\{(\w+)[,}]');
    for (final k in messages(id)) {
      final a = ph.allMatches(id[k] as String).map((m) => m[1]).toSet();
      final b = ph.allMatches(en[k] as String).map((m) => m[1]).toSet();
      expect(
        b,
        a,
        reason:
            '$k: placeholders disagree between locales. A placeholder '
            'present in one and absent in the other either drops data on '
            'screen or fails to compile.',
      );
    }
  });

  test('an ICU plural in the template is a plural in every locale', () {
    for (final k in messages(id)) {
      final templateIsPlural = (id[k] as String).contains(', plural,');
      final targetIsPlural = (en[k] as String).contains(', plural,');
      expect(
        targetIsPlural,
        templateIsPlural,
        reason:
            '$k: gen-l10n derives the method signature from the template, '
            'so a locale that disagrees about being a plural will not build.',
      );
    }
  });

  test('an English count reads right at one', () {
    // Indonesian does not mark plurals, so copy authored in the template and
    // then translated arrives as "1 items" unless the English entry is an ICU
    // plural. The template cannot catch this — only the target can.
    final counted = RegExp(r'\{(\w+)\}\s+(?:[a-z]+\s+)?([a-z]+s)\b');
    // Words that end in `s` without being a plural, or that never inflect.
    const invariant = {'ms', 'status', 'is', 'was', 'has', 'less', 'across'};
    // Placeholders that are not counts at all, so the noun after them never
    // agrees with them: a money amount, a venue's own name.
    const notACount = {'cshWrittenOffBody', 'ordTitleVenue'};
    final offenders = <String>[];
    for (final k in messages(id)) {
      final v = en[k] as String;
      if (v.contains(', plural,') || notACount.contains(k)) continue;
      for (final m in counted.allMatches(v)) {
        if (invariant.contains(m[2])) continue;
        offenders.add('$k: "${m[0]}"');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'an English count needs an ICU plural, or it renders "1 items". '
          'Write {n, plural, =1{1 item} other{{n} items}} and mirror it in '
          'the template with an `other` arm only.',
    );
  });
}
