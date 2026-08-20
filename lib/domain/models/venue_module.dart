/// **[[Modul]]** — a slice of the app a venue holds à la carte, beside its plan
/// (ADR-0107).
///
/// Pure vocabulary, and here rather than in `server/` or `data/` because all
/// three layers need the same words: the fleet console writes them, the mirror
/// carries them, the embedded server gates on them and the Venue hub draws a
/// locked tile from them.
///
/// These keys are **persisted** — in `venues/{vid}.addOns` and in
/// `venue_settings.modules` — under the same rule as an `AuditKind`. Renaming
/// one un-entitles every venue holding it. Must stay equal to `MODULES` in
/// `functions/index.js`.
library;

const moduleMembers = 'members';
const moduleSelfOrder = 'selfOrder';

const venueModuleKeys = <String>[moduleMembers, moduleSelfOrder];

/// Comma-joined at rest, a set in use. Empty and whitespace-only both mean "no
/// modules" — which is also what a device that has never seen its venue doc
/// holds, since the mirror is the only thing that fills the column.
Set<String> splitModules(String? raw) => {
  for (final m in (raw ?? '').split(','))
    if (m.trim().isNotEmpty) m.trim(),
};

/// Sorted, so a mirror's diff-guard compares two stable strings and a re-order
/// never reads as a change.
String joinModules(Iterable<String> keys) =>
    (keys.map((k) => k.trim()).where((k) => k.isNotEmpty).toSet().toList()
          ..sort())
        .join(',');
