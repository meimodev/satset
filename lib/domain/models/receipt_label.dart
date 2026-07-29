/// The letter a [[Split bill]] receipt is known by — `A`, `B`, `C` — and how
/// that label reads as prose.
///
/// The letter is **persisted** in `Receipt.label`, not derived from list
/// position, so deleting a receipt leaves a gap instead of re-lettering a
/// guest who already holds a printed slip. Labels that are not a single
/// letter pass through untouched: `Tagihan` (the undivided whole-bill case),
/// `Bagian 1/3` (an even share), and legacy `Tamu 1`. See ADR-0063.
///
/// Plain Dart, no Flutter — the printed slip and the server read this too.
/// The hue that dresses a letter lives in `ui/core/design/receipt_visuals.dart`.
library;

/// Whether [label] is a receipt letter — the only shape that earns a badge.
bool isReceiptLetter(String label) {
  if (label.length != 1) return false;
  final c = label.codeUnitAt(0);
  return c >= 0x41 && c <= 0x5A; // A–Z
}

/// Prose form of a receipt label, for card titles, confirm dialogs, the assign
/// sheet, the discount sheet, and the printed slip's meta line. A letter reads
/// as a guest; anything else already reads as itself.
String receiptTitle(String label) {
  final t = label.trim();
  if (t.isEmpty) return 'Struk';
  return isReceiptLetter(t) ? 'Tamu $t' : t;
}

/// The lowest letter not already spoken for, so a delete leaves a reusable
/// gap (A, C → next is B) instead of shuffling everyone along.
///
/// ponytail: 26 letters, then it repeats from A. A 27-way split at one table
/// is not a real service; if it ever is, this needs a second character.
String nextReceiptLetter(Iterable<String> taken) {
  final used = {
    for (final l in taken)
      if (isReceiptLetter(l.trim())) l.trim(),
  };
  for (var c = 0x41; c <= 0x5A; c++) {
    final letter = String.fromCharCode(c);
    if (!used.contains(letter)) return letter;
  }
  return 'A';
}
