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
/// True when a bare literal is small enough to be spacing rather than a
/// dimension. The scale tops out at 48; above that a number is a panel width
/// or a tile height and belongs at its call site.
bool _isSpacing(String arg) {
  final m = RegExp(r'(\d+(?:\.\d+)?)\s*$').firstMatch(arg.trim());
  if (m == null) return false;
  return (double.tryParse(m.group(1)!) ?? 999) <= 48;
}

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
      // Reached 0. The last two cases were real design decisions wearing a
      // literal — the QR quiet zone and the payment-proof lightbox — so they
      // became tokens (satQrQuiet, satMediaChrome/satMediaInk) rather than a
      // file exemption. A colour that must ignore the palette still deserves
      // a name saying so.
      name: 'Colors.white / Colors.black',
      baseline: 0,
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

  // A ban from the day it landed (ADR-0055). Every raw Material button in a
  // feature screen was converted in the same pass, so there is no debt to
  // ratchet down — the count starts at zero and stays there.
  //
  // `core/widgets/` builds SatButton out of these and `core/design/theme.dart`
  // themes them for the stock widgets that still reach for them; both are
  // outside the scan. `_book` renders raw states on purpose, so it is exempt
  // by name below.
  test('no raw Material buttons outside core/widgets', () {
    final hits = <String>[];
    for (final file in files) {
      if (file.path.contains('/features/_book/')) continue;
      if (file.path.contains('/core/widgets/')) continue;
      final src = file.readAsStringSync();
      for (final m in RegExp(
        r'\b(FilledButton|OutlinedButton|TextButton|ElevatedButton)\s*[.(]',
      ).allMatches(src)) {
        hits.add('${file.path}:${_lineOf(src, m.start)} ${m.group(1)}');
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'Use SatButton — core/widgets/sat_button.dart. Named constructors '
          '(.primary/.neutral/.outline/.ghost/.success/.danger) carry the '
          'intent; size/icon/busy/trailingValue are the only open axes. An '
          'icon-only target is SatIconButton, which requires a tooltip.\n'
          '${hits.join('\n')}',
    );
  });

  // The Material bans above only catch a screen that *names* FilledButton or
  // TextField. They said nothing about a private `_FilledBtn` drawing the same
  // pill out of a Container — which is how five of them survived the first
  // sweep. A widget whose name claims to be a control has to be built on one.
  test('no private lookalikes of a shared control', () {
    final claims = RegExp(
      r'^class (_\w*(?:Btn|Button|Chip|Pill|Badge|Field|Toggle|Switch|Stepper)) ',
      multiLine: true,
    );
    final delegates = RegExp(
      r'\bSat(Button|IconButton|Chip|Field|Dropdown|Toggle|Stepper|Card)\b',
    );
    // Named, with the reason. Each is chip- or button-*shaped* but is not one
    // of the shared controls, and forcing it onto one would cost more than the
    // duplication saves. Named individually so a new lookalike still trips.
    const shapedButNot = {
      // Pulsing dot + elapsed + sent-at, three scales in one pill.
      '_AgePill',
      // A spinner or a check circle where a dot would go.
      '_StationChip',
      // 44x44 squares leading a history row — avatars, not chips.
      '_TableChip', '_TakeawayChip',
      // 9pt micro-badges with brutal's hard shadow; SatChip's floor is 12pt.
      '_OwnerChip', '_StatePill',
      // A glow-shadowed status dot with no container at all.
      '_ServerReachabilityPill',
      // A solid count badge riding a tab, not a labelled chip.
      '_Badge',
      // Same case as _AgePill: a *pulsing* dot on a solid semantic fill. The
      // blip is what carries a stuck zone across the room, and SatChip's `dot`
      // is static — and its tag hues are tints, where this has to be solid.
      '_ZoneAlarmBadge',
      // A solid urgent tally with a pulsing dot; SatChip.tag is a soft fill.
      '_LateTally',
      // Icon over label, stacked — SatButton is a horizontal row.
      '_BigBtn',
      // A circular target carrying an overflow badge.
      '_ContextTriggerBtn',
      // A colour swatch in a ring; the glyph *is* the value.
      '_ThemeIconButton',
      // Animated availability pill that cross-fades success<->urgent on tap.
      '_StatusToggle',
      // A cash-pad key: two lines (denomination over a ×N count) whose fill is
      // driven by the running tally, in a fixed 7-key grid. SatButton is a
      // single-label horizontal row with no count and no per-key state.
      '_NoteButton',
    };
    final hits = <String>[];
    for (final file in files) {
      if (file.path.contains('/features/_book/')) continue;
      if (file.path.contains('/core/widgets/')) continue;
      final src = file.readAsStringSync();
      for (final m in claims.allMatches(src)) {
        if (shapedButNot.contains(m.group(1))) continue;
        final body = _classBody(src, m.start);
        // Composition is the point (ADR-0051): a thin wrapper adding domain
        // meaning on top of a shared control is exactly right.
        if (delegates.hasMatch(body)) continue;
        // Paints nothing — a layout holder or a callback bag, not a control.
        if (!body.contains('SatBox.d(') &&
            !body.contains('BoxDecoration(') &&
            !body.contains('Material(')) {
          continue;
        }
        hits.add('${file.path}:${_lineOf(src, m.start)} ${m.group(1)}');
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'A private widget named like a control must be built on the shared '
          'one — wrap SatButton / SatChip / SatField / SatToggle / SatStepper '
          'rather than redrawing it. If it is genuinely something else, name '
          'it for what it is.\n${hits.join('\n')}',
    );
  });

  test('no literal type sizes outside core/design', () {
    final hits = <String>[];
    for (final file in files) {
      if (file.path.contains('/features/_book/')) continue;
      // Renders what a thermal printer will emit, not app chrome — its sizes
      // are the paper's, not the design system's.
      if (file.path.endsWith('receipt_preview.dart')) continue;
      // The rail label is tuned per skin to fit a 56px tile — 'MANDIRI' at
      // caption's tracking wrapped to two lines and overflowed the column.
      // Named here rather than exempted by shape, so any *other* literal in
      // the file still trips.
      if (file.path.endsWith('tablet_chrome.dart')) continue;
      final src = file.readAsStringSync();
      for (final m in RegExp(
        r'SatType\.(sans|mono|display)\(',
      ).allMatches(src)) {
        // A glyph sized off its own container — an avatar's initials, a
        // stepper's numeral — scales with the thing it sits in and has no
        // fixed role. It is the *literal* that is banned, not the call.
        final body = _callBody(src, m.start);
        if (!RegExp(r'size:\s*[\d.]').hasMatch(body)) continue;
        hits.add('${file.path}:${_lineOf(src, m.start)}');
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'Use a named role — SatType.h1/h2/h3, bodyL/M/S, labelL/M/S, '
          'monoDisplay54/monoDisplay/monoL/monoM/monoS, caption. Size and '
          'weight belong to the role; only colour varies per call site. '
          'Reaching for sans()/mono()/display() directly is how five weights '
          'across 827 sites happened.\n'
          '${hits.join('\n')}',
    );
  });

  test('no raw text inputs or dropdowns outside core/widgets', () {
    final hits = <String>[];
    for (final file in files) {
      if (file.path.contains('/features/_book/')) continue;
      if (file.path.contains('/core/widgets/')) continue;
      final src = file.readAsStringSync();
      for (final m in RegExp(
        r'\b(TextField|TextFormField|InputDecoration|DropdownButton|'
        r'DropdownButtonFormField)\s*[.(<]',
      ).allMatches(src)) {
        hits.add('${file.path}:${_lineOf(src, m.start)} ${m.group(1)}');
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'Use SatField — core/widgets/sat_field.dart. The constructor names '
          'what the field accepts (.text/.number/.money/.decimal/.search/'
          '.pin/.inline) and carries the keyboard, formatters and affix that '
          'go with it. A neighbour that Material dresses with an '
          'InputDecoration calls satInputDecoration() so it matches exactly. '
          'A closed list of choices is SatDropdown — or, where they all fit on '
          'screen, a row of SatChip.select.\n'
          '${hits.join('\n')}',
    );
  });

  // Scans all of lib/, not just lib/ui/ — a route pushed from a router
  // redirect or a service would land under the shell just the same.
  test('no raw overlay outside sat_overlay.dart', () {
    final hits = <String>[];
    for (final file in _allLibDart()) {
      if (file.path.endsWith('/core/widgets/sat_overlay.dart')) continue;
      final src = file.readAsStringSync();
      for (final m in RegExp(
        r'\b(showModalBottomSheet|showDialog|showGeneralDialog)\s*[(<]',
      ).allMatches(src)) {
        hits.add('${file.path}:${_lineOf(src, m.start)} ${m.group(1)}');
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'Use showSatSheet / showSatDialog / showSatDrawer — '
          'core/widgets/sat_overlay.dart (ADR-0061). All three of these '
          'default to useRootNavigator: false, which puts the overlay on the '
          "shell navigator — and AppShell paints that under the phone's "
          'floating tab bar, so the sheet renders behind the bar and the bar '
          'keeps taking taps through the barrier. That is the bug this ban '
          'exists to make unwritable. If the helper cannot express what you '
          'need, give the helper the parameter.\n'
          '${hits.join('\n')}',
    );
  });

  // Accessibility rules need the whole constructor call, not one line: the
  // `tooltip:` that names a button sits several lines below `IconButton(`.
  // Balanced-paren scan instead of a line regex.
  // ADR-0083. Started life as a ratchet — 304 literals were sitting in widgets
  // when `AppStrings` was deleted and gen-l10n landed. The sweep finished, so
  // this is now a ban like everything else in this file: user-facing text lives
  // in `lib/l10n/*.arb` and is read through `context.l10n`, or it is invisible
  // to a translator and renders Indonesian in an English build.
  test('no hardcoded user-facing copy in a Text()', () {
    // The wordmark. A brand name is not translated in either language.
    const brand = {'satset'};
    final hits = <String>[];
    final pattern = RegExp(r"""Text\(\s*(?:const\s+)?'((?:[^'\\]|\\.)*)'""");
    for (final file in files) {
      // The widget book is debug-only scaffolding over stub data (ADR-0054):
      // its strings are sample dishes and English state names, never shipped
      // copy.
      if (file.path.contains('/_book/')) continue;
      final src = file.readAsStringSync();
      for (final m in pattern.allMatches(src)) {
        final raw = m.group(1)!;
        // A literal whose `${…}` holds its own quote (`${x.isEmpty ? '' : y}`)
        // ends the regex early, so the capture is a fragment of an expression
        // rather than a string. Unbalanced braces are the tell.
        if (RegExp(r'\$\{').allMatches(raw).length !=
            RegExp(r'\}').allMatches(raw).length) {
          continue;
        }
        if (brand.contains(raw)) continue;
        // Strip interpolations: `Text('$count')` and `Text('${l.qty}×')` are
        // data, not copy, and hoisting them to ARB would be noise. What is
        // left has to contain two consecutive letters to count as a word.
        final bare = raw.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
        if (!RegExp(r'[A-Za-z]{2}').hasMatch(bare)) continue;
        hits.add('${file.path}:${_lineOf(src, m.start)}  $raw');
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'User-facing text belongs in lib/l10n/app_id.arb + app_en.arb, read '
          'via context.l10n (ADR-0083).\n${hits.join('\n')}',
    );
  });

  // The sibling of the ban above. A `Text()` is only half the copy in this
  // codebase: the shared vocabulary takes its words as named params, so
  // `SatButton.primary(label: 'Simpan')` renders Indonesian in an English
  // build just as loudly as a `Text` would, and the `Text` regex never sees it.
  test('no hardcoded user-facing copy in a named param', () {
    // `satset` is the wordmark. `Book` names the debug widget book (ADR-0054),
    // which never ships to a venue. `GL` is a sample three-letter tag code in
    // a field whose input is a code, not a word.
    const allow = {'satset', 'Book', 'GL'};
    final hits = <String>[];
    final pattern = RegExp(
      r"\b(?:label|title|subtitle|hint|hintText|labelText|tooltip|helperText"
      r"|semanticLabel|confirmLabel|header|sub|message|body|placeholder|text)"
      r":\s*(?:const\s+)?'((?:[^'\\]|\\.)*)'",
    );
    for (final file in files) {
      if (file.path.contains('/_book/')) continue;
      final src = file.readAsStringSync();
      for (final m in pattern.allMatches(src)) {
        final raw = m.group(1)!;
        // Same escape hatch as the `Text` ban: a literal whose `${…}` holds its
        // own quote truncates the capture, leaving an expression fragment.
        if (RegExp(r'\$\{').allMatches(raw).length !=
            RegExp(r'\}').allMatches(raw).length) {
          continue;
        }
        if (allow.contains(raw)) continue;
        final bare = raw.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
        if (!RegExp(r'[A-Za-z]{2}').hasMatch(bare)) continue;
        hits.add('${file.path}:${_lineOf(src, m.start)}  $raw');
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'Copy passed to a widget by name is still copy. Move it to '
          'lib/l10n/app_id.arb + app_en.arb (ADR-0083).\n${hits.join('\n')}',
    );
  });

  // The two bans above are shape-based, and shape is what the last of the
  // sweep hid behind: a switch arm, a `const` list of preset reasons, a
  // positional argument, a `return`. So this one is language-based instead —
  // Indonesian is the source language, so an Indonesian word in a Dart string
  // under `ui/` or `domain/` is copy that never reached the ARB, whatever
  // syntax it is sitting in.
  //
  // Scans `lib/domain/` too: enums used to carry their own display labels
  // (`Capability`, `TicketStatus`, `StockReason`, `AlertSoundPreset`), which is
  // the same bug one layer down — the words are now resolved from the enum name
  // in `core/localization/labels.dart`.
  test('no Indonesian copy left in a Dart literal', () {
    // Deliberately narrow: common function words plus the domain nouns from
    // CONTEXT.md. Catches a sentence, ignores a `dapur` station code — those
    // are exempted by the data-shape rules below, not by the word list.
    final words = RegExp(
      r'(?:^|[^A-Za-z])('
      r'dan|atau|tidak|belum|sudah|akan|bisa|untuk|dari|dengan|pada|yang|ada'
      r'|masuk|keluar|meja|pesanan|gagal|coba|lagi|semua|pilih|hari|nama'
      r'|wajib|kosong|terisi|siap|catatan|jumlah|harga|stok|laporan|tagihan'
      r'|struk|staf|pelayan|dapur|kirim|hapus|simpan|ubah|tambah|batal|lewat'
      r'|sekarang|dulu|salah|habis|rusak|lama|bagian|kembali|diambil|dikirim'
      r'|diatur|dilayani|terhubung|berjalan|diketahui|permanen|dibatalkan'
      r'|kategori|bahan|perhatian|pajak|aktif|lokal|layanan|zona|resep'
      r'|opname|diskon|antrian|kasir|buka|tutup'
      r')(?:[^A-Za-z]|$)',
      caseSensitive: false,
    );
    // A venue's own words, not the app's: a role named "Dapur" or a station
    // code on a query string is data this build must not translate.
    const dataShaped = {
      'Dapur', // station code, order-taking → SentScreen (see report_copy)
      'dapur', // legacy-role name matching in staff_screen
      'semua',
      'laporan',
      'riwayat-pesanan',
      'laporan-staf', // export filename slugs
      'kasir', // rail destination id + '/kasir' route, not a label
      'bahan', // report section id + its ValueKey
    };
    final literal = RegExp(r"'((?:[^'\\\n]|\\.)*)'");
    final hits = <String>[];
    final targets = [
      ...files,
      ...Directory('lib/domain')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
    ];
    for (final file in targets) {
      if (file.path.contains('/_book/')) continue;
      final src = file.readAsStringSync();
      final lines = src.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        // Prose in a doc comment is documentation, and a log line is for
        // whoever reads `adb logcat`, not for a waiter.
        if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;
        if (line.contains('SatLog')) continue;
        for (final m in literal.allMatches(line)) {
          final raw = m.group(1)!;
          // Route paths and package URIs are addresses, not words.
          if (raw.startsWith('/') || raw.startsWith('package:')) continue;
          if (dataShaped.contains(raw)) continue;
          if (!words.hasMatch(raw)) continue;
          hits.add('${file.path}:${i + 1}  $raw');
        }
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'Indonesian in a Dart literal is copy that skipped the ARB — a '
          'switch arm and a preset list translate no better than a Text() '
          'does (ADR-0083). Emit a code and render it through '
          'core/localization/ instead.\n${hits.join('\n')}',
    );
  });

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

  // A ban since the whole shared-widget sweep: SatButton, SatIconButton,
  // SatChip and SatToggle each carry their own role, and the tap targets left
  // in feature code were wrapped one by one.
  //
  // Scans the whole enclosing method rather than a fixed lookback — three
  // widgets (table_card, me_screen, table_detail) apply Semantics at `return`
  // to a card built into a local, which a 320-char window could not see and
  // which was the only reason this stayed a baseline.
  test('every tap target carries a role', () {
    final hits = <String>[];
    for (final file in files) {
      final src = file.readAsStringSync();
      final methods = RegExp(
        r'^\s*(?:@override\s*\n\s*)?\w[\w<>, ?]*\s+\w+\([^;]*?\)\s*(?:\{|=>)',
        multiLine: true,
      ).allMatches(src).map((m) => m.start).toList();
      for (final m in RegExp(
        r'\b(GestureDetector|InkWell)\(',
      ).allMatches(src)) {
        final body = _callBody(src, m.start);
        if (RegExp(r'Text\(|SatType\.|label:').hasMatch(body)) continue;
        // The enclosing method: from the last declaration at or before the
        // tap target, to the next one after it.
        final startIdx = methods.lastWhere(
          (i) => i <= m.start,
          orElse: () => 0,
        );
        final endIdx = methods.firstWhere(
          (i) => i > m.start,
          orElse: () => src.length,
        );
        if (src.substring(startIdx, endIdx).contains('Semantics(')) continue;
        hits.add('${file.path}:${_lineOf(src, m.start)}');
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'A GestureDetector or InkWell with no text child announces nothing '
          'to TalkBack. Reach for SatButton / SatIconButton / SatChip / '
          'SatToggle, which carry their own role, or wrap it in '
          'Semantics(button: true, label: …).\n${hits.join('\n')}',
    );
  });

  // The clutter guard. A widget class name declared in more than one file is
  // the fingerprint of "rebuilt it because I couldn't see the existing one" —
  // it is what produced three `_StatusChip`s, two `_EntranceFade`s and two
  // different `Reveal`s. Catalogued shared widgets are unique by construction,
  // so this only ever fires on a genuine second copy.
  //
  // A ban since the sweep. The real copies were merged — two pulse dots, two
  // empty states, two section labels, two sheet headers, and a second Reveal
  // that had drifted to its own timing. The rest were generic names over
  // unrelated widgets (`_Header` three times, `_Footer`, `_Section`), which
  // merging would have turned into one widget with the union of both APIs and
  // the shape of neither; those were renamed for what they actually are.
  //
  // The rule outlives the cleanup: a name colliding again is still the
  // fingerprint of "rebuilt it because I couldn't see the existing one".
  test('no widget class name declared in 2+ files', () {
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
    expect(
      dupes,
      isEmpty,
      reason:
          'Check lib/ui/core/widgets/CATALOG.md before writing a new widget — '
          'if something there is close, extend it. If the two really are '
          'different things, name them for what they are.\n\n$report',
    );
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
  //
  // A ban since the scale grew s7/s9 and every value under it was snapped.
  // Numbers above the scale's 48 ceiling are dimensions — a 560px panel, a
  // 110px thumbnail — not spacing, and are not counted: naming them would
  // only invite the wrong one to be reached for.
  test('no raw spacing literal', () {
    final hits = <String>[];
    for (final file in files) {
      final src = file.readAsStringSync();
      // Mocks a 58mm thermal receipt; its paddings are the paper's, not the
      // design system's — same reasoning as its type sizes.
      if (file.path.endsWith('receipt_preview.dart')) continue;
      for (final m in RegExp(
        r'EdgeInsets\.(?:all|symmetric|only)\(',
      ).allMatches(src)) {
        final body = _callBody(src, m.start);
        if (body.length < 2) continue;
        for (final arg in _splitArgs(body.substring(1, body.length - 1))) {
          final g = _bareNumberArg.firstMatch(arg);
          if (g != null && _isSpacing(arg)) {
            hits.add('${file.path}:${_lineOf(src, m.start)}  ${arg.trim()}');
          }
        }
      }
      for (final m in RegExp(
        r'SizedBox\(\s*(?:width|height):\s*(\d+(?:\.\d+)?)\s*[,)]',
      ).allMatches(src)) {
        if (!_isSpacing(m.group(1)!)) continue;
        hits.add('${file.path}:${_lineOf(src, m.start)}  ${m.group(1)}');
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'Use Sp — design/spacing.dart '
          '(2/4/6/8/10/12/14/16/18/20/24/28/32/36/40/48).\n'
          '${hits.join('\n')}',
    );
  });

  // `fromLTRB` was the hole in the rule above, and it was not a small one: the
  // ban lists `all`/`symmetric`/`only` and stops there, so the sign-in screen
  // passed a clean run while every panel inset on it was a bare literal.
  //
  // A ratchet rather than a ban because it lands at 159 call sites across 121
  // files, and a ban would mean either a green test nobody can reach or 121
  // files in one commit. Same contract as the `rules` list: it can fall, never
  // climb.
  //
  // The baseline counts **arguments**, not call sites, because that is what the
  // rule above it counts — one `fromLTRB(12, 0, 12, 12)` is three hits, not
  // one. So the number here is ~4× the site count and moves in steps of up to
  // four when a site is fixed.
  //
  // Not counted alongside it: `Container(width:/height:)`. The widened matcher
  // caught 101 of those too, but they are *sizing* — a 22px spinner, a 44px
  // brand mark — and folding them into the padding scale would be the wrong
  // fix. `SatSize` is where the ones above the scale belong.
  const fromLtrbBaseline = 659;
  test('no new: raw EdgeInsets.fromLTRB spacing', () {
    final hits = <String>[];
    for (final file in files) {
      final src = file.readAsStringSync();
      if (file.path.endsWith('receipt_preview.dart')) continue;
      for (final m in RegExp(r'EdgeInsets\.fromLTRB\(').allMatches(src)) {
        final body = _callBody(src, m.start);
        if (body.length < 2) continue;
        for (final arg in _splitArgs(body.substring(1, body.length - 1))) {
          final g = _bareNumberArg.firstMatch(arg);
          if (g != null && _isSpacing(arg)) {
            hits.add('${file.path}:${_lineOf(src, m.start)}  ${arg.trim()}');
          }
        }
      }
    }
    if (hits.length > fromLtrbBaseline) {
      fail(
        'raw EdgeInsets.fromLTRB: ${hits.length} occurrences, baseline '
        '$fromLtrbBaseline (+${hits.length - fromLtrbBaseline} new).\n'
        'Fix: use Sp — design/spacing.dart.\n\n${hits.join('\n')}',
      );
    }
    if (hits.length < fromLtrbBaseline) {
      fail(
        'raw EdgeInsets.fromLTRB dropped to ${hits.length} (baseline '
        '$fromLtrbBaseline). Good — now set fromLtrbBaseline to ${hits.length} '
        'in test/design_tokens_test.dart so it cannot climb back.',
      );
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

/// Every `.dart` file under `lib/`, generated output included — a `.g.dart`
/// has no business pushing a route either.
List<File> _allLibDart() {
  final root = Directory('lib');
  if (!root.existsSync()) return const [];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
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

/// Source of the class declaration starting at [start], to the next
/// column-zero `}`. Good enough for a scan: Dart formats every top-level
/// closing brace there.
String _classBody(String src, int start) {
  final end = RegExp(r'^\}', multiLine: true).firstMatch(src.substring(start));
  return end == null
      ? src.substring(start)
      : src.substring(start, start + end.end);
}
