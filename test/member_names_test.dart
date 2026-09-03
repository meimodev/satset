import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/repositories/member_names_repository.dart';

void main() {
  group('namesFrom', () {
    test('names the ids it asked for', () {
      final got = namesFrom([
        {'id': 'm1', 'name': 'Ani', 'phone': '•••• 1234'},
      ], {'m1'});
      expect(got, {'m1': 'Ani'});
    });

    test('records an unnamed id as a miss, not as absent', () {
      // A member since deleted (ADR-0092). The key must exist so the card can
      // tell "deleted" from "not asked yet".
      final got = namesFrom([], {'m1'});
      expect(got.containsKey('m1'), isTrue);
      expect(got['m1'], isNull);
    });

    test('drops rows it did not ask for', () {
      // An older host does not know `ids` and answers the unfiltered first
      // page of the directory. Matching on position would pin Budi's name
      // onto Ani's line.
      final got = namesFrom([
        {'id': 'm9', 'name': 'Budi'},
        {'id': 'm1', 'name': 'Ani'},
      ], {'m1'});
      expect(got, {'m1': 'Ani'});
    });
  });
}
