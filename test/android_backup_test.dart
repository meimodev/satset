// The host tablet's data directory is the venue — the Drift database with
// every bill, the JWT signing secret, the staff PIN hashes, the TLS key. A
// default-on Android backup copies all of it somewhere nobody at the venue
// chose.
//
// Two attributes, because one stopped being enough: `allowBackup` shuts the
// cloud and adb door, and from API 31 device-to-device transfer moved into its
// own rules file. The app targets 36, so both apply.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final rules = File(
    'android/app/src/main/res/xml/data_extraction_rules.xml',
  );

  test('the app refuses cloud and adb backup', () {
    expect(
      manifest,
      contains('android:allowBackup="false"'),
      reason: 'omitting it means true — the default is the bug',
    );
  });

  test('the app refuses device-to-device transfer', () {
    expect(manifest, contains('android:dataExtractionRules='));
    expect(
      rules.existsSync(),
      isTrue,
      reason: 'the manifest points at a file that has to be there',
    );
  });

  test('the rules exclude everything, in both directions', () {
    final xml = rules.readAsStringSync();
    for (final section in ['cloud-backup', 'device-transfer']) {
      final body = xml.split('<$section>')[1].split('</$section>')[0];
      for (final domain in [
        'root',
        'file',
        'database',
        'sharedpref',
        'external',
      ]) {
        expect(
          body,
          contains('domain="$domain"'),
          reason: '$section leaves $domain extractable',
        );
      }
      expect(
        body,
        isNot(contains('<include')),
        reason: 'an allowlist is the shape that gains a hole silently',
      );
    }
  });
}
