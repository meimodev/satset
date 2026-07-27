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
    // missing is the button *role*, not a name. The remaining 29 are all admin
    // surfaces in that shape; the icon-only ones, which announced nothing at
    // all, are fixed. Wrapping `adminPill`/`adminToggle` in `_common.dart`
    // would clear most of the rest in one change.
    //
    // It also cannot see a `Semantics` applied at `return` to a widget built
    // into a local (table_card, me_screen, table_detail do this), so a handful
    // of counted sites are already correct.
    const baseline = 29;
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

  // Reduced motion. A ban, not a baseline — every `AnimatedFoo` in lib/ui now
  // takes its duration from `satMotion(context, ms)`, which collapses to zero
  // when the platform asks for it.
  //
  // This is an accessibility rule, not a stylistic one: a raw `duration:` keeps
  // animating for a user who has explicitly asked the OS to stop, and it fails
  // silently — nothing in review shows it, because the reviewer has motion on.
  // A hand-rolled `reduced ? Duration.zero : …` ternary passes too; the point
  // is that the decision is visible in the argument.
  test('every animation respects reduced motion', () {
    final animated = RegExp(
      r'\b(?:AnimatedContainer|AnimatedOpacity|AnimatedSwitcher|AnimatedAlign'
      r'|AnimatedPadding|AnimatedPositioned|AnimatedScale|AnimatedSlide'
      r'|AnimatedSize|AnimatedRotation|AnimatedDefaultTextStyle'
      r'|TweenAnimationBuilder(?:<[^>]*>)?|AnimatedCrossFade)\(',
    );
    final durationArg = RegExp(
      r'^\s*(?:reverse)?[Dd]uration:\s*(.*)$',
      dotAll: true,
    );
    final guarded = RegExp(r'satMotion|Duration\.zero|motionEnabled|reduce');
    // `duration: xfade` is fine when `xfade` itself was computed from the
    // reduced-motion flag, and a widget that early-returns its child under
    // reduced motion has already answered the question for its whole build.
    final bareName = RegExp(r'^\w+$');
    final earlyReturn = RegExp(
      r'(?:disableAnimationsOf|!\s*motionEnabled)\([^)]*\)\)?\s*\)?\s*return',
    );
    final hits = <String>[];
    for (final file in files) {
      final src = file.readAsStringSync();
      for (final m in animated.allMatches(src)) {
        final body = _callBody(src, m.end - 1);
        if (body.length < 2) continue;
        final before = src.substring(
          (m.start - 900).clamp(0, m.start),
          m.start,
        );
        if (earlyReturn.hasMatch(before)) continue;
        for (final arg in _splitArgs(body.substring(1, body.length - 1))) {
          final am = durationArg.firstMatch(arg);
          if (am == null) continue;
          if (guarded.hasMatch(arg)) continue;
          final value = am.group(1)!.trim();
          if (bareName.hasMatch(value)) {
            final assign = RegExp(
              '(?:final|var|Duration)\\s+$value\\s*=([^;]*);',
            ).firstMatch(src);
            if (assign != null && guarded.hasMatch(assign.group(1)!)) continue;
            // A widget field named `duration` is the caller's decision to make.
            if (RegExp('final Duration $value;').hasMatch(src)) continue;
          }
          hits.add('${file.path}:${_lineOf(src, m.start)}  ${arg.trim()}');
        }
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'Animation ignores reduced motion. Take the duration from '
          'satMotion(context, ms) — design/motion.dart.\n${hits.join('\n')}',
    );
  });

  // Spacing. The scale now carries half-steps (6/10/14/18) and a 2px hair gap,
  // because those were already in the code 428 times before they had names —
  // so every value a component legitimately wants has a token, and a raw number
  // here is drift rather than a gap in the scale.
  //
  // Counts whole-argument literals only: `EdgeInsets.only(top: 6)` is spacing,
  // but the `6` inside `EdgeInsets.only(bottom: inset * 6)` is arithmetic. An
  // earlier regex version did not draw that line and rewrote layout dimensions
  // (a 560px panel width became 48) — hence the argument parser.
  test('no new: raw spacing literal', () {
    const baseline = 181;
    final hits = <String>[];
    for (final file in files) {
      final src = file.readAsStringSync();
      for (final m in RegExp(
        r'EdgeInsets\.(?:all|symmetric|only)\(',
      ).allMatches(src)) {
        final body = _callBody(src, m.start);
        if (body.length < 2) continue;
        for (final arg in _splitArgs(body.substring(1, body.length - 1))) {
          if (_bareNumberArg.hasMatch(arg)) {
            hits.add('${file.path}:${_lineOf(src, m.start)}  ${arg.trim()}');
          }
        }
      }
      for (final m in RegExp(
        r'SizedBox\(\s*(?:width|height):\s*(\d+)\s*[,)]',
      ).allMatches(src)) {
        hits.add('${file.path}:${_lineOf(src, m.start)}  ${m.group(1)}');
      }
    }
    if (hits.length > baseline) {
      fail(
        'raw spacing literals: ${hits.length}, baseline $baseline '
        '(+${hits.length - baseline} new).\nUse Sp — design/spacing.dart '
        '(2/4/6/8/10/12/14/16/18/20/24/32/40/48).\n\n${hits.join('\n')}',
      );
    }
    if (hits.length < baseline) {
      fail('dropped to ${hits.length} — set baseline to ${hits.length}.');
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

/// An argument that is *entirely* a number — `12` or `top: 12`, but not
/// `top: inset * 12` and not `top: kPad`.
final _bareNumberArg = RegExp(r'^\s*(?:[A-Za-z_]\w*\s*:\s*)?\d+\s*$');

/// Top-level comma split of a call body, ignoring commas nested inside
/// brackets or string literals.
List<String> _splitArgs(String body) {
  final parts = <String>[];
  var depth = 0;
  String? inString;
  final buf = StringBuffer();
  for (final ch in body.split('')) {
    if (inString != null) {
      buf.write(ch);
      if (ch == inString) inString = null;
      continue;
    }
    if (ch == '"' || ch == "'") {
      inString = ch;
      buf.write(ch);
      continue;
    }
    if (ch == '(' || ch == '[' || ch == '{') depth++;
    if (ch == ')' || ch == ']' || ch == '}') depth--;
    if (ch == ',' && depth == 0) {
      parts.add(buf.toString());
      buf.clear();
      continue;
    }
    buf.write(ch);
  }
  if (buf.toString().trim().isNotEmpty) parts.add(buf.toString());
  return parts;
}

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
