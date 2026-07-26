/// Selectable alert sounds (ADR-0035). Decouples *which clip plays* from the
/// *meaning* of an [AlertEvent] (see CONTEXT.md "Audio alert" / "Alert sound").
///
/// Pure Dart — no Flutter imports. The admin picks one preset per event on the
/// venue settings "Suara" section; the choice is venue-wide ([VenueSettingsDto]).
library;

/// The moments that can sound a cue. Routing (who hears each) stays a
/// per-device-role decision in `AlertSoundService` — see ADR-0007.
///
/// [ungreeted] and [pickup] were added by ADR-0044. The other table states
/// ("Meja lama", "Meja selesai makan") are deliberately **visual only** and so
/// are absent here — a cue a waiter cannot discharge is noise that devalues
/// every other cue.
enum AlertEvent { newOrder, orderReady, voided, overdue, ungreeted, pickup }

/// A selectable bundled clip. [asset] is null for the silent "none" preset.
class AlertSoundPreset {
  const AlertSoundPreset(this.id, this.label, this.asset);

  final String id;
  final String label;
  final String? asset;

  bool get isSilent => asset == null;
}

/// Sentinel id for "no sound for this event".
const kNoneSoundId = 'none';

/// Fixed preset library. To add one: drop a `.wav` in `assets/sounds/` and add
/// a row here. Removing a row is safe — venues still pointing at it fall back to
/// the per-event default via [resolveSoundId].
const alertSoundPresets = <AlertSoundPreset>[
  AlertSoundPreset(kNoneSoundId, 'Senyap', null),
  AlertSoundPreset('alarm', 'Alarm', 'sounds/alarm.wav'),
  AlertSoundPreset('alert', 'Alert', 'sounds/alert.wav'),
  AlertSoundPreset('beep', 'Beep', 'sounds/beep.wav'),
  AlertSoundPreset('bell', 'Bel', 'sounds/bell.wav'),
  AlertSoundPreset('chime', 'Chime', 'sounds/chime.wav'),
  AlertSoundPreset('click', 'Klik', 'sounds/click.wav'),
  AlertSoundPreset('critical_alarm', 'Alarm Kritis', 'sounds/critical_alarm.wav'),
  AlertSoundPreset('ding', 'Ding', 'sounds/ding.wav'),
  AlertSoundPreset('doorbell', 'Bel Pintu', 'sounds/doorbell.wav'),
  AlertSoundPreset('facility_alarm', 'Alarm Fasilitas', 'sounds/facility_alarm.wav'),
  AlertSoundPreset('game_alarm', 'Alarm Game', 'sounds/game_alarm.wav'),
  AlertSoundPreset('happy_bell', 'Lonceng Ceria', 'sounds/happy_bell.wav'),
  AlertSoundPreset('harp', 'Harpa', 'sounds/harp.wav'),
  AlertSoundPreset('marimba', 'Marimba', 'sounds/marimba.wav'),
  AlertSoundPreset('pop', 'Pop', 'sounds/pop.wav'),
  AlertSoundPreset('remove', 'Hapus', 'sounds/remove.wav'),
  AlertSoundPreset('reward', 'Reward', 'sounds/reward.wav'),
  AlertSoundPreset('short_alarm', 'Alarm Pendek', 'sounds/short_alarm.wav'),
  AlertSoundPreset('start', 'Mulai', 'sounds/start.wav'),
  AlertSoundPreset('ting', 'Ting', 'sounds/ting.wav'),
];

/// Per-event factory default — reproduces ADR-0007's original fixed cues.
const alertEventDefaults = <AlertEvent, String>{
  AlertEvent.newOrder: 'alert',
  AlertEvent.orderReady: 'chime',
  AlertEvent.voided: 'alert',
  AlertEvent.overdue: 'alert',
  AlertEvent.ungreeted: 'chime',
  AlertEvent.pickup: 'chime',
};

/// Preset for [id], or null if [id] is unknown (e.g. a removed preset).
AlertSoundPreset? presetForId(String id) {
  for (final p in alertSoundPresets) {
    if (p.id == id) return p;
  }
  return null;
}

/// Resolve a stored id for [event] to a valid preset id: unknown/removed ids
/// degrade to the event's default rather than going silent or throwing.
String resolveSoundId(AlertEvent event, String storedId) {
  if (presetForId(storedId) != null) return storedId;
  return alertEventDefaults[event]!;
}
