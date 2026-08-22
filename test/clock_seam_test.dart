import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `SatClock` is the app's clock seam, and a seam only holds while everything
/// goes through it. Before this test 32 call sites in 19 files read
/// `DateTime.now()` directly — elapsed pills, printed receipt stamps, export
/// filenames, the guest plane's service-hours check, and the auth clock.
///
/// Two of those are different bugs. A UI or domain site on the raw clock cannot
/// be time-travelled by a test, so anything about lateness, escalation or a
/// business day is untestable except by waiting. An **auth** site on the seam
/// is worse in the other direction: a rewound clock keeps tokens alive past
/// their stated lifetime, which is why `SatClock` documents that security reads
/// `realNow`.
///
/// So this bans the bare call outside a small allowlist, and separately pins
/// that the security files read `realNow` rather than `now`.
void main() {
  /// Files that may still say `DateTime.now()`, and why.
  ///
  /// `sat_clock.dart` **is** the seam. `_book/` is the debug widget book, whose
  /// stub data is not a domain fact and is compiled out of release. And
  /// `domain/models/**` is pure by the layering rule — it may not import
  /// `core/`, so a `fromJson` parse fallback there has no seam to reach for.
  /// That last one is a real exemption, not an oversight: the value is what a
  /// malformed wire row falls back to, never a timestamp anything writes.
  const allowed = [
    'lib/core/time/sat_clock.dart',
    'lib/ui/features/_book/',
    'lib/domain/models/',
  ];

  /// Security never reads the shiftable clock.
  const security = ['lib/server/auth.dart', 'lib/server/tls.dart'];

  Iterable<File> dartFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  /// Strips `//` comments so prose *about* the seam is not read as a use of it.
  String code(String src) => src
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('//'))
      .join('\n');

  test('nothing outside the allowlist reads the wall clock directly', () {
    final offenders = <String>[];
    for (final f in dartFiles()) {
      if (allowed.any(f.path.contains)) continue;
      if (code(f.readAsStringSync()).contains('DateTime.now()')) {
        offenders.add(f.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'read SatClock.now() instead — or SatClock.realNow() if this is '
          'auth, pairing or TLS, where a shifted clock is a security bug',
    );
  });

  test('the security files read the real clock, not the seam', () {
    for (final path in security) {
      final src = code(File(path).readAsStringSync());
      expect(
        src.contains('SatClock.now()'),
        isFalse,
        reason:
            '$path is on the security side of SatClock: a rewound clock here '
            'keeps a token alive past its stated lifetime',
      );
      expect(
        src.contains('SatClock.realNow()'),
        isTrue,
        reason: '$path should be timing off realNow',
      );
    }
  });
}
