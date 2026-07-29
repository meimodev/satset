/// The hue a [[Split bill]] receipt letter wears.
///
/// The letter itself — and the rule that it is persisted rather than
/// positional — lives in `domain/models/receipt_label.dart`, which the printed
/// slip and the server also read. This file is only the colour, and is
/// re-exported alongside it so a UI call site needs one import.
///
/// Sits beside `course_visuals.dart` / `zone_visuals.dart` for the same
/// reason: the domain holds a plain label, the UI layer decides how it looks.
/// See ADR-0063.
library;

import 'package:flutter/material.dart';

export 'package:satset/domain/models/receipt_label.dart';

import 'package:satset/domain/models/receipt_label.dart';

/// The receipt ramp — drawn from `ZonePresets.colorHexes`, minus its green
/// (`0xFF4DD487`) and red (`0xFFFF5C5C`) entries, which read as "paid" and
/// "urgent" against the semantic palette this badge sits next to. Ordered so
/// the first four guests get unmistakably different hues.
///
/// Declared literally rather than indexed out of `ZonePresets` so reordering
/// the zone picker cannot silently re-colour a bill.
const _ramp = <int>[
  0xFF6DB5FF, // A · blue
  0xFFC08AFF, // B · violet
  0xFF7ED6C4, // C · teal
  0xFFE48BB7, // D · pink
  0xFFFFC04D, // E · gold
  0xFFFF9233, // F · amber
];

/// Ink for a letter sitting on a *filled* badge. Fixed rather than themed
/// because the badge paints its own surface: every hue in [_ramp] is a light
/// pastel, so dark ink is the legible choice under both Gelap and Terang. A
/// theme token would flip to near-white in the dark palette and vanish.
const receiptInk = Color(0xFF16181C);

/// The hue for a receipt letter. Wraps every 6 letters; past that the letter
/// itself is the disambiguator, which it always was — colour is the scan aid,
/// never the sole signal.
Color receiptHue(String label) {
  if (!isReceiptLetter(label)) return Color(_ramp[0]);
  return Color(_ramp[(label.codeUnitAt(0) - 0x41) % _ramp.length]);
}
