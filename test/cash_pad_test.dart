import 'package:flutter_test/flutter_test.dart';
import 'package:satset/ui/features/cashier/widgets/cash_pad.dart';

void main() {
  test('cash fold includes rupiah coin denominations', () {
    expect(noteFold(800), [(500, 1), (200, 1), (100, 1)]);
  });
}
