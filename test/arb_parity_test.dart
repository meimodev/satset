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

  // --- [[Kata layanan]] variants (ADR-0127) -------------------------------
  //
  // `app_id_SV.arb` / `app_en_SV.arb` override only the strings that name a
  // [[Meja]] and inherit the rest, which is what keeps a vocabulary switch to
  // ~120 entries instead of 4000. The cost of inheritance is **silent drift**:
  // a new "Meja" string added to the template and forgotten here renders
  // "Meja" at a salon, and nothing at runtime says so. These fail instead.

  /// ICU spans masked, so the placeholder named `table` is never read as the
  /// word "table".
  String words(String v) =>
      v.replaceAll(RegExp(r'\{\w+[,}]'), ' ');

  late Map<String, dynamic> idSv;
  late Map<String, dynamic> enSv;

  setUpAll(() {
    idSv = load('app_id_SV.arb');
    enSv = load('app_en_SV.arb');
  });

  test('every string naming a table has a service-term override', () {
    for (final (base, variant, word, file) in [
      (id, () => idSv, RegExp(r'\bmeja\b', caseSensitive: false), 'app_id_SV.arb'),
      (en, () => enSv, RegExp(r'\btables?\b', caseSensitive: false), 'app_en_SV.arb'),
    ]) {
      final v = variant();
      final missing = [
        for (final k in messages(base))
          if (word.hasMatch(words(base[k] as String)) && !v.containsKey(k)) k,
      ];
      expect(
        missing,
        isEmpty,
        reason:
            'missing from $file — a venue in [[Kata layanan]] mode would read '
            'the table word on these. Add the override, or if the word is not '
            'the floor here, reword the template.',
      );
    }
  });

  test('a service-term override neither invents nor keeps the table word', () {
    for (final (base, variant, word, file) in [
      (id, () => idSv, RegExp(r'\bmeja\b', caseSensitive: false), 'app_id_SV.arb'),
      (en, () => enSv, RegExp(r'\btables?\b', caseSensitive: false), 'app_en_SV.arb'),
    ]) {
      final v = variant();
      expect(
        messages(v).difference(messages(base)),
        isEmpty,
        reason:
            '$file overrides a key its base locale does not have — gen-l10n '
            'generates from the template, so these are dead',
      );
      final leftovers = [
        for (final k in messages(v))
          if (word.hasMatch(words(v[k] as String))) k,
      ];
      expect(
        leftovers,
        isEmpty,
        reason: '$file still says the table word on these',
      );
    }
  });

  test('a service-term override keeps its base placeholders and plural', () {
    final ph = RegExp(r'\{(\w+)[,}]');
    for (final (base, variant, file) in [
      (id, () => idSv, 'app_id_SV.arb'),
      (en, () => enSv, 'app_en_SV.arb'),
    ]) {
      final v = variant();
      for (final k in messages(v)) {
        final a = ph.allMatches(base[k] as String).map((m) => m[1]).toSet();
        final b = ph.allMatches(v[k] as String).map((m) => m[1]).toSet();
        expect(
          b,
          a,
          reason:
              '$file/$k: placeholders disagree with the base locale. '
              'gen-l10n derives the signature from the template, so this '
              'will not build.',
        );
        expect(
          (v[k] as String).contains(', plural,'),
          (base[k] as String).contains(', plural,'),
          reason: '$file/$k: disagrees with the base about being a plural',
        );
      }
    }
  });
}
