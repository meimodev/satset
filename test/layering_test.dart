import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The layer rule, enforced rather than described (ADR-0104).
///
/// `ui/` → `domain/` → `data/` is how the code is *meant* to point, and
/// `CLAUDE.md` said so for a long time while four files pointed the other way.
/// A claim nobody checks decays; this is the check.
///
/// Each ban carries an allowlist of the files that already break it. The lists
/// are frozen: an entry may be **removed** when the import goes away, never
/// added. A new violation fails here with the file named.
void main() {
  /// Every `.dart` file under [dir], excluding generated output.
  List<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where(
        (f) =>
            !f.path.endsWith('.g.dart') &&
            !f.path.endsWith('.freezed.dart') &&
            !f.path.contains('/l10n/'),
      )
      .toList();

  List<String> offenders(String dir, String forbidden, Set<String> allowed) {
    final bad = <String>[];
    for (final f in dartFiles(dir)) {
      final rel = f.path.replaceFirst('${Directory.current.path}/', '');
      if (allowed.contains(rel)) continue;
      final src = f.readAsStringSync();
      for (final line in src.split('\n')) {
        final t = line.trimLeft();
        if (!t.startsWith('import ') && !t.startsWith('export ')) continue;
        if (t.contains(forbidden)) {
          bad.add('$rel  →  $forbidden');
          break;
        }
      }
    }
    return bad;
  }

  test('domain does not import Flutter', () {
    // Three use cases are Riverpod providers, which drags `flutter_riverpod`
    // in. They are the boundary cases the layer rule was always fudging; see
    // ADR-0104 for why they are tolerated rather than moved.
    expect(
      offenders('lib/domain', 'package:flutter', {
        'lib/domain/use_cases/advance_ticket_status_use_case.dart',
        'lib/domain/use_cases/fire_course_use_case.dart',
        'lib/domain/use_cases/submit_order_use_case.dart',
      }),
      isEmpty,
    );
  });

  test('domain does not import data', () {
    // The same three: a use case orchestrates repositories, so it reaches
    // *down* into `data/`. Every model under `lib/domain/models/` is clean,
    // and that is the part of the rule worth defending.
    expect(
      offenders('lib/domain', 'package:satset/data/', {
        'lib/domain/use_cases/advance_ticket_status_use_case.dart',
        'lib/domain/use_cases/fire_course_use_case.dart',
        'lib/domain/use_cases/submit_order_use_case.dart',
      }),
      isEmpty,
    );
  });

  test('data does not import ui', () {
    // `alert_sound_service` reads the ready-alert view model to decide what to
    // play. The wrong direction, and the one on this list most worth undoing.
    expect(
      offenders('lib/data', 'package:satset/ui/', {
        'lib/data/services/alert_sound_service.dart',
      }),
      isEmpty,
    );
  });

  test('domain models are pure — no Flutter, no data, no server', () {
    for (final forbidden in [
      'package:flutter',
      'package:satset/data/',
      'package:satset/ui/',
      'package:satset/server/',
    ]) {
      expect(
        offenders('lib/domain/models', forbidden, const {}),
        isEmpty,
        reason: 'lib/domain/models must not reach $forbidden',
      );
    }
  });

  test('the server does not import ui', () {
    expect(offenders('lib/server', 'package:satset/ui/', const {}), isEmpty);
  });
}
