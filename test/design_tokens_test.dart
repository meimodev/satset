import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Design-token guard.
///
/// Scans `lib/ui/` for hardcoded values that should come from
/// `lib/ui/core/design/` instead. Each rule carries a **baseline** — the count
/// that existed when the rule landed — and the test fails if a count goes up.
///
/// Ratchet, not a wall: the debt is too large to fix in one pass, but it can
/// never grow. When a consolidation pass (`/extract`, `/normalize`) drives a
/// count down, the test fails too and tells you the new number to write here.
/// Lower the baseline in the same commit — that is what locks the win in.
///
/// Goal for every baseline is 0. See `lib/ui/core/widgets/CATALOG.md`.
void main() {
  // ponytail: regex over source, not an analyzer plugin. A custom_lint package
  // would give IDE squiggles for ~300 lines of plumbing; this is 100 lines and
  // catches the same drift in CI. Upgrade if the false-positive rate bites.
  final rules = <_Rule>[
    _Rule(
      // Reached 0 — a ban now, not a baseline. The last three were all the
      // same ink-on-a-saturated-fill calculation; that lives in `onFill()`.
      name: 'hardcoded Color(0x...)',
      baseline: 0,
      pattern: RegExp(r'Color\(0x'),
      fix:
          'use context.sat — see design/colors.dart. Ink on a saturated fill '
          '(status pill, owner chip) is onFill(), not a literal.',
    ),
    _Rule(
      // The 6 left are two deliberate cases, both commented at the site: the
      // QR quiet zone in zone_admin (themed to charcoal it stops scanning) and
      // the payment-proof lightbox in cashier_bill (black chrome so the app's
      // palette does not tint a photo being read for an amount). Left as a
      // baseline rather than a file exemption, so genuine drift in those two
      // files still trips the rule.
      name: 'Colors.white / Colors.black',
      baseline: 6,
      pattern: RegExp(r'Colors\.(white|black)\b'),
      fix:
          'use context.sat neutral ramp (bg0-bg4, textHi-textDim), onFill() for '
          'ink on a saturated fill, or satBarrier/satMediaScrim/satShadowInk '
          'for dimming that must stay dark on every palette. '
          'Colors.transparent is allowed.',
    ),
    _Rule(
      name: 'off-scale spacing literal',
      // 654, not the 622 this rule used to report: the old per-line scan could
      // not see a call the formatter had wrapped, so 32 sites were invisible.
      baseline: 654,
      pattern: _offScaleSpacing,
      fix: 'use Sp.s1..Sp.s12 (4/8/12/16/20/24/32/40/48) — design/spacing.dart',
    ),
    _Rule(
      name: 'raw BorderRadius.circular(n)',
      baseline: 0,
      pattern: RegExp(r'BorderRadius\.circular\(\s*\d'),
      fix:
          'use SatR — design/skin.dart (ADR-0047). A literal radius ignores '
          'the active skin.',
    ),
  ];

  final files = _scanTargets();

  test('lib/ui/ is scannable', () {
    expect(files, isNotEmpty, reason: 'run from the repo root');
  });

  // Accessibility rules need the whole constructor call, not one line: the
  // `tooltip:` that names a button sits several lines below `IconButton(`.
  // Balanced-paren scan instead of a line regex.
  test('every IconButton names itself', () {
    final hits = <String>[];
    for (final file in files) {
      final src = file.readAsStringSync();
      for (final m in RegExp(r'\bIconButton\(').allMatches(src)) {
        final body = _callBody(src, m.start);
        if (body.contains('tooltip:') || body.contains('Semantics(')) continue;
        hits.add('${file.path}:${_lineOf(src, m.start)}');
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'An icon-only IconButton announces nothing to TalkBack. Add '
          'tooltip: (it doubles as the screen-reader name).\n${hits.join('\n')}',
    );
  });

  test('no new: icon-only tap target without a role', () {
    // Baseline, not a ban. The scan cannot see through a child widget's own
    // build, so a tap target wrapping `adminPill(context, '+ Add staff')`
    // counts here even though it announces that text fine — what those are
    // missing is the button *role*, not a name. The remaining 30 are all admin
    // surfaces in that shape; the icon-only ones, which announced nothing at
    // all, are fixed. Wrapping `adminPill`/`adminToggle` in `_common.dart`
    // would clear most of the rest in one change.
    //
    // It also cannot see a `Semantics` applied at `return` to a widget built
    // into a local (table_card, me_screen, table_detail do this), so a handful
    // of counted sites are already correct.
    const baseline = 30;
    final hits = <String>[];
    for (final file in files) {
      final src = file.readAsStringSync();
      for (final m in RegExp(
        r'\b(GestureDetector|InkWell)\(',
      ).allMatches(src)) {
        final body = _callBody(src, m.start);
        // The Semantics wrapper usually sits *above* the tap target, not
        // inside it, so the body alone is not enough — look back over the
        // enclosing widget too.
        final lookback = src.substring(
          (m.start - 320).clamp(0, m.start),
          m.start,
        );
        if (body.contains('Semantics(') ||
            lookback.contains('Semantics(') ||
            RegExp(r'Text\(|SatType\.|label:').hasMatch(body)) {
          continue;
        }
        hits.add('${file.path}:${_lineOf(src, m.start)}');
      }
    }
    if (hits.length > baseline) {
      fail(
        'icon-only tap targets without Semantics: ${hits.length}, baseline '
        '$baseline (+${hits.length - baseline} new).\nWrap in '
        'Semantics(button: true, label: …).\n\n${hits.join('\n')}',
      );
    }
    if (hits.length < baseline) {
      fail('dropped to ${hits.length} — set baseline to ${hits.length}.');
    }
  });

  // The clutter guard. A widget class name declared in more than one file is
  // the fingerprint of "rebuilt it because I couldn't see the existing one" —
  // it is what produced three `_StatusChip`s, two `_EntranceFade`s and two
  // different `Reveal`s. Catalogued shared widgets are unique by construction,
  // so this only ever fires on a genuine second copy.
  //
  // Not a ban. Most of the remaining 12 are same-name-different-thing —
  // `_Header`, `_Empty`, `_Section`, `_Footer` are generic names over unrelated
  // widgets, and merging them would yield a widget with the union of both APIs
  // and the shape of neither. Two are worth a look when someone next touches
  // them: `_CourseBlock` (table detail vs. review) and `_ZoneRow` (floor vs.
  // zone admin) may be real copies.
  test('no new: widget class name declared in 2+ files', () {
    const baseline = 12;
    final byName = <String, List<String>>{};
    for (final file in files) {
      final src = file.readAsStringSync();
      for (final m in RegExp(
        r'^class (\w+)',
        multiLine: true,
      ).allMatches(src)) {
        final name = m.group(1)!;
        // A State<T> class necessarily shares its widget's name.
        if (name.endsWith('State')) continue;
        (byName[name] ??= []).add(file.path);
      }
    }
    final dupes = byName.entries.where((e) => e.value.length > 1).toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final report = dupes
        .map((e) => '${e.key} (${e.value.length})\n  ${e.value.join('\n  ')}')
        .join('\n');
    if (dupes.length > baseline) {
      fail(
        'duplicated widget names: ${dupes.length}, baseline $baseline '
        '(+${dupes.length - baseline} new).\nCheck '
        'lib/ui/core/widgets/CATALOG.md before writing a new widget — if '
        'something there is close, extend it.\n\n$report',
      );
    }
    if (dupes.length < baseline) {
      fail('dropped to ${dupes.length} — set baseline to ${dupes.length}.');
    }
  });

  for (final rule in rules) {
    test('no new: ${rule.name}', () {
      final hits = <String>[];
      for (final file in files) {
        // Whole source, not line-by-line. `dart format` wraps a long argument
        // list across lines, and a per-line scan silently stops matching —
        // which reads as debt disappearing when only the line breaks moved.
        final src = file.readAsStringSync();
        for (final m in rule.pattern.allMatches(src)) {
          hits.add(
            '${file.path}:${_lineOf(src, m.start)}  '
            '${m.group(0)!.replaceAll(RegExp(r'\s+'), ' ')}',
          );
        }
      }

      if (hits.length > rule.baseline) {
        final fresh = hits.length - rule.baseline;
        fail(
          '${rule.name}: ${hits.length} occurrences, baseline ${rule.baseline} '
          '(+$fresh new).\nFix: ${rule.fix}\n\n${hits.join('\n')}',
        );
      }
      if (hits.length < rule.baseline) {
        fail(
          '${rule.name} dropped to ${hits.length} (baseline ${rule.baseline}). '
          'Good — now set baseline to ${hits.length} in '
          'test/design_tokens_test.dart so it cannot climb back.',
        );
      }
    });
  }
}

/// Spacing literals that are not on the `Sp` scale.
///
/// Matches the numeric argument of `SizedBox(width:/height:)` and any
/// `EdgeInsets.*`, then rejects only the off-scale values — on-scale literals
/// are still drift, but flagging all ~1100 of them makes the ratchet useless
/// as a signal. Off-scale (6, 10, 14, 18, 22...) is where the real damage is:
/// those cannot be expressed with a token at all.
final _offScaleSpacing = RegExp(
  r'(?:SizedBox\(\s*(?:width|height):\s*|EdgeInsets\.(?:all|symmetric|only)\('
  r'(?:[a-zA-Z]+:\s*)?)'
  r'(?!(?:4|8|12|16|20|24|32|40|48)\b)'
  r'\d+(?:\.\d+)?',
);

/// Files that legitimately own literal values. Keep this list short and make
/// every entry argue for itself — an exemption is permanent, a baseline is not.
const _exempt = <String>[
  // Simulates thermal paper: fixed ink-on-paper geometry that must look the
  // same in either app theme, so the design tokens genuinely do not apply.
  'features/admin/widgets/receipt_preview.dart',
];

/// Every `.dart` file under `lib/ui/`, excluding the token definitions
/// themselves — `design/` is where literal colors and numbers are supposed to
/// live.
List<File> _scanTargets() {
  final root = Directory('lib/ui');
  if (!root.existsSync()) return const [];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('/core/design/'))
      .where((f) => !_exempt.any(f.path.endsWith))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// The balanced `(...)` group that starts at the first `(` at or after [start].
/// Falls back to the rest of the file on an unbalanced source, which only
/// over-reports and never hides a violation.
String _callBody(String src, int start) {
  final open = src.indexOf('(', start);
  if (open < 0) return '';
  var depth = 0;
  for (var i = open; i < src.length; i++) {
    final c = src[i];
    if (c == '(') {
      depth++;
    } else if (c == ')') {
      depth--;
      if (depth == 0) return src.substring(open, i + 1);
    }
  }
  return src.substring(open);
}

int _lineOf(String src, int offset) =>
    '\n'.allMatches(src.substring(0, offset)).length + 1;

class _Rule {
  final String name;
  final int baseline;
  final RegExp pattern;
  final String fix;

  const _Rule({
    required this.name,
    required this.baseline,
    required this.pattern,
    required this.fix,
  });
}
