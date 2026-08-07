/// The letter a [[Split bill]] receipt is known by — `A`, `B`, `C` — and how
/// that label reads as prose.
///
/// The letter is **persisted** in `Receipt.label`, not derived from list
/// position, so deleting a receipt leaves a gap instead of re-lettering a
/// guest who already holds a printed slip. Labels that are not a single
/// letter pass through untouched: `Tagihan` (the undivided whole-bill case),
/// `1/3` (an even share), and legacy `Tamu 1`. See ADR-0063.
///
/// Plain Dart, no Flutter — the printed slip and the server read this too, and
/// none of them holds an `AppL10n`. Turning a label into words is therefore
/// **not** here: `receiptTitle` lives in `core/localization/labels.dart`.
/// The hue that dresses a letter lives in `ui/core/design/receipt_visuals.dart`.
library;

/// Whether [label] is a receipt letter — the only shape that earns a badge.
bool isReceiptLetter(String label) {
  if (label.length != 1) return false;
  final c = label.codeUnitAt(0);
  return c >= 0x41 && c <= 0x5A; // A–Z
}

/// The `(index, count)` of an even share, or null if [label] is not one.
///
/// Parts are stored as the bare spec `1/3`. They used to be stored as the
/// finished sentence `Bagian 1/3`, which no reader could re-render in another
/// language — ADR-0085. Legacy rows still holding that sentence fail this test
/// and fall through to being displayed verbatim, which is what they are.
(String, String)? receiptPartOf(String label) {
  final m = RegExp(r'^(\d+)/(\d+)$').firstMatch(label.trim());
  return m == null ? null : (m.group(1)!, m.group(2)!);
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
