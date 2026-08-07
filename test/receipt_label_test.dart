import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/core/localization/labels.dart';
import 'package:satset/domain/models/receipt_label.dart';
import 'package:satset/l10n/app_localizations.dart';

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

  group('receiptPartOf', () {
    test('reads an even share back out of its stored spec', () {
      expect(receiptPartOf('1/3'), ('1', '3'));
      expect(receiptPartOf(' 12/12 '), ('12', '12'));
    });

    test('rejects anything that is not a bare spec', () {
      // The pre-ADR-0085 sentence is deliberately NOT parsed back: it stays a
      // sentence, in the language it was written in.
      expect(receiptPartOf('Bagian 1/3'), isNull);
      expect(receiptPartOf('A'), isNull);
      expect(receiptPartOf('Tagihan'), isNull);
    });
  });

  group('receiptTitle', () {
    final id = lookupAppL10n(const Locale('id'));
    final en = lookupAppL10n(const Locale('en'));

    test("reads a letter as a guest, in the reader's language", () {
      expect(receiptTitle(id, 'A'), 'Tamu A');
      expect(receiptTitle(id, ' C '), 'Tamu C');
      expect(receiptTitle(en, 'A'), 'Guest A');
    });

    test('composes an even share at read time (ADR-0085)', () {
      expect(receiptTitle(id, '1/3'), 'Bagian 1/3');
      expect(receiptTitle(en, '1/3'), 'Part 1/3');
    });

    test('passes anything else through untouched', () {
      // A row written before ADR-0085 holds the finished sentence. It renders
      // as recorded — Indonesian even for an English reader — because that is
      // genuinely what was stored.
      expect(receiptTitle(en, 'Bagian 1/3'), 'Bagian 1/3');
      expect(receiptTitle(id, 'Tagihan'), 'Tagihan');
      expect(receiptTitle(id, 'Tamu 1'), 'Tamu 1'); // legacy, no migration
    });

    test('falls back rather than rendering an empty title', () {
      expect(receiptTitle(id, ''), 'Struk');
      expect(receiptTitle(en, '   '), 'Receipt');
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
