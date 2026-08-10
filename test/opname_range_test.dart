import 'package:flutter_test/flutter_test.dart';

import 'package:satset/ui/features/admin/opname_screen.dart';

void main() {
  test('the archive range is stable across a day', () {
    // The range is a provider family key. Built from a live clock it changes
    // every frame, and the screen refetches itself into an infinite spinner —
    // which is exactly what shipped before this snapped to midnight.
    final morning = opnameRange(90, now: DateTime(2026, 8, 10, 7, 14, 3));
    final night = opnameRange(90, now: DateTime(2026, 8, 10, 23, 59, 59));
    expect(morning, night);
  });

  test('the range covers today and reaches back the asked-for days', () {
    final (from, to) = opnameRange(30, now: DateTime(2026, 8, 10, 12));
    expect(DateTime.parse(from), DateTime(2026, 7, 11));
    // Exclusive upper bound at tomorrow's midnight, so a count closed at 22:30
    // tonight is inside the window rather than a day late.
    expect(DateTime.parse(to), DateTime(2026, 8, 11));
  });

  test('a different span is a different key', () {
    final now = DateTime(2026, 8, 10, 12);
    expect(opnameRange(30, now: now), isNot(opnameRange(90, now: now)));
  });
}
