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

/// The **sellable** set — a thing a venue buys. Fails *open* when unknown, on
/// the reasoning in `server/modules.dart`.
const venueModuleKeys = <String>[moduleMembers, moduleSelfOrder];

/// **[[Kedai]] mode** (ADR-0109) — the one key that says this venue is a
/// counter shop rather than a restaurant. A key of a different kind: it does
/// not unlock a feature, it reshapes the app, so it fails **closed** and is
/// read through `venueHasMode`, never `venueHasModule`.
const modeCounterService = 'counterService';

/// **[[Tanpa antrian persiapan]]** (ADR-0115) — the venue has no prep queue at
/// all: whoever takes the order also makes it, so a sent line is born `ready`
/// and the [[KDS / Antrian Persiapan|KDS]] is not part of the venue's shape.
///
/// A mode key like [modeCounterService] and read the same way — closed when
/// unknown — but **independent of it**: a counter shop may still run a cook
/// line, and a small restaurant may have no queue. Neither implies the other,
/// which is why this is a mode of its own rather than a seventh
/// [counterSwitchKeys] entry.
///
/// It is the one key in this file that a *writer* reads (`submitOrder`), which
/// ADR-0115 permits a mode and still forbids a config switch.
const modeBypassKds = 'bypassKds';

/// Mode keys ride in the same `addOns` array and the same mirrored CSV as the
/// sellable ones — one transport, two readings. Kept apart here so the trial's
/// implicit grant and the fail-open resolver can each name the set they mean.
/// **[[Pemilik struk]]** (ADR-0118) — a [[Split bill]] may name a
/// [[Pelanggan (member)]] per receipt, so a party of regulars each earn
/// [[Poin]] on their own share instead of one of them earning on all of it.
///
/// A mode key rather than a sellable [[Modul]], read through [venueHasMode] so
/// it fails **closed**. The fail-open in `venueHasModule` protects a feature a
/// venue *paid for* from a cold boot; applied here it would offer a
/// per-receipt member picker at a venue that never mirrored, and a
/// wrongly-offered picker writes mis-attributed rows into a points ledger that
/// never expires. A missing button is one tick away from fixed; a wrong ledger
/// row is a reversal and a conversation.
///
/// Unlike [modeBypassKds] it branches no writer — it only decides whether a
/// receipt's `memberId` is offered, read and reported. Meaningless without
/// [moduleMembers] and the owner's own `membersEnabled`, so it is ANDed with
/// both **once**, in `MemberConfig.splitEnabled`, and never at a route.
const modeMemberSplit = 'memberSplit';

/// **[[Kata layanan]]** (ADR-0127) — the venue sells service, not seats, so
/// every user-facing "[[Meja]]" reads **Layanan · Service** instead.
///
/// A mode key, read through [venueHasMode] so it fails **closed**: the
/// fail-open that protects a paid [[Modul]] would rename the floor at every
/// restaurant that has not mirrored yet, and a cafe waking from a cold boot
/// calling its tables "Layanan" is a worse first minute than a salon waiting
/// one sign-in for its vocabulary.
///
/// It **branches no writer and gates nothing** — the floor, zones, capacity,
/// locks and moves are all still there, doing what they always did. It changes
/// the *words*, and does it the way ADR-0083 already resolves words: by
/// picking a locale. `Locale('id', 'SV')` / `Locale('en', 'SV')` resolve to
/// `app_id_SV.arb` / `app_en_SV.arb`, which override only the ~120 strings
/// that name a table and inherit the other ~3900. Nothing reads this key at a
/// call site; `SatLocaleNotifier` reads it once and the whole app — including
/// the ESC/POS struk and the CSV exporters, which read the process-wide
/// `satL10n` — follows.
///
/// Independent of [modeCounterService]: a salon is not a counter shop, and a
/// kedai still has meja.
const modeServiceTerm = 'serviceTerm';

const venueModeKeys = <String>[
  modeCounterService,
  modeBypassKds,
  modeMemberSplit,
  modeServiceTerm,
];

/// Everything the console may write to `addOns` and the mirror may carry down.
/// Must stay equal to `ALL_MODULES` in `functions/index.js`.
const venueEntitlementKeys = <String>[...venueModuleKeys, ...venueModeKeys];

/// The six switches [[Kedai]] mode is made of (ADR-0109 §3). The preset is a
/// *write* — ticking the module turns all six on and the operator unticks what
/// that venue does not want — so nothing anywhere computes "is this venue in
/// the preset". There is no preset state, only these.
///
/// Persisted strings, in `venues/{vid}.counterConfig` and in the mirrored
/// `venue_settings.counter_config` CSV. Unrenameable, same rule as the rest.
/// They are **config, not entitlement**: none of them decides whether a caller
/// may act, only what a screen defaults to. A switch read inside a writer is a
/// review finding.

/// The menu is the home tab; the [[Floor]] is hidden.
const counterMenuHome = 'menuHome';

/// `guestName` optional — the visit rides its `Bawa pulang #N` label.
const counterAnonTakeaway = 'anonTakeaway';

/// Commit opens the settle pane instead of returning to the floor.
const counterSettleAfterSend = 'settleAfterSend';

/// One queue on the KDS: no station split, no course fire.
const counterSimpleKds = 'simpleKds';

/// The venue-level [[Kode kedai]] QR.
const counterQr = 'counterQr';

/// The [[Ringkas]] one-page report.
const counterRingkasReport = 'ringkasReport';

const counterSwitchKeys = <String>[
  counterMenuHome,
  counterAnonTakeaway,
  counterSettleAfterSend,
  counterSimpleKds,
  counterQr,
  counterRingkasReport,
];

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
