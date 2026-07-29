import 'package:flutter_test/flutter_test.dart';

import 'package:satset/domain/models/receipt_label.dart';

/// The rule ADR-0063 actually rests on: a receipt's letter is a property of the
/// receipt, not of its position — because that letter is already printed on a
/// guest's slip by the time anyone deletes a sibling.
void main() {
  group('nextReceiptLetter', () {
    test('starts at A and walks forward', () {
      expect(nextReceiptLetter(const []), 'A');
      expect(nextReceiptLetter(const ['A']), 'B');
      expect(nextReceiptLetter(const ['A', 'B', 'C']), 'D');
    });

    test('refills a gap instead of shuffling the survivors along', () {
      // B was deleted. C keeps its slip; the next add takes B back.
      expect(nextReceiptLetter(const ['A', 'C']), 'B');
    });

    test('ignores labels that are not letters', () {
      // Legacy 'Tamu 1', the whole-bill 'Tagihan', and even shares must not
      // consume a letter or crash the scan.
      expect(nextReceiptLetter(const ['Tamu 1', 'Bagian 1/3', 'Tagihan']), 'A');
      expect(nextReceiptLetter(const ['A', 'Tagihan']), 'B');
    });
  });

  group('receiptTitle', () {
    test('reads a letter as a guest', () {
      expect(receiptTitle('A'), 'Tamu A');
      expect(receiptTitle(' C '), 'Tamu C');
    });

    test('passes non-letters through untouched', () {
      expect(receiptTitle('Bagian 1/3'), 'Bagian 1/3');
      expect(receiptTitle('Tagihan'), 'Tagihan');
      expect(receiptTitle('Tamu 1'), 'Tamu 1'); // legacy, no migration
    });

    test('falls back rather than rendering an empty title', () {
      expect(receiptTitle(''), 'Struk');
      expect(receiptTitle('   '), 'Struk');
    });
  });

  group('isReceiptLetter', () {
    test('accepts exactly one capital A–Z', () {
      expect(isReceiptLetter('A'), isTrue);
      expect(isReceiptLetter('Z'), isTrue);
      expect(isReceiptLetter('a'), isFalse);
      expect(isReceiptLetter('AB'), isFalse);
      expect(isReceiptLetter('1'), isFalse);
      expect(isReceiptLetter(''), isFalse);
    });
  });
}
