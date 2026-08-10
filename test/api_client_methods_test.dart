import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // `putJson` existed for months with no `PUT` arm in `_send`'s switch, so
  // every caller died on `Bad state: Unsupported method PUT` — at runtime, on
  // device, in a snackbar. The verb a helper names and the verbs the sender
  // knows are two lists nothing kept in step; this is that check.
  test('every verb _send is asked for has a switch arm', () {
    final src = File(
      'lib/data/services/api_client.dart',
    ).readAsStringSync();

    final asked = RegExp(r"_send\(\s*'([A-Z]+)'")
        .allMatches(src)
        .map((m) => m.group(1)!)
        .toSet();
    final handled = RegExp(r"'([A-Z]+)'\s*=>\s*_inner\.")
        .allMatches(src)
        .map((m) => m.group(1)!)
        .toSet();

    expect(asked, isNotEmpty, reason: 'the regex stopped matching, not the code');
    expect(asked.difference(handled), isEmpty);
  });
}
