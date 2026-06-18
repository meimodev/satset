# Selectable per-event alert sounds (venue-synced)

[ADR-0007](0007-audio-alert-routing.md) fixed *who hears what*: cues are routed by device role, and each of the three semantic cues (ding / chime / alert) was hard-wired to a single bundled clip. Admins asked to **choose the sound** for each moment ("make 'new order' louder", "I want a softer 'ready'"). This ADR decouples the **sound** from the **cue** and makes the sound an admin-chosen, **venue-wide** setting — routing is untouched.

## Decision

- **Per event, not per cue.** The admin picks a sound for each of four **alert events** — *pesanan baru* (new order), *pesanan siap* (ready), *void*, *lewat waktu* (overdue) — matching the moments staff actually recognise. The old `AlertCue {ding, chime, alert}` enum (which conflated *meaning* and *file*) is replaced by an `AlertEvent` enum plus a separate **preset** registry of selectable clips.
- **Presets only, no upload.** A small fixed library of bundled `.wav` clips (`assets/sounds/`), each `{id, label, asset}`, plus **`none`** (silent for that event). No server-side audio storage, no LAN binary sync, works offline. Custom upload is explicitly deferred.
- **Venue-synced, shared by every device.** The four choices live on `VenueSettingsDto` (Drift single-row `venue_settings`, pushed over WS like every other venue setting). One admin sets them; every paired device obeys. A given device still only *plays* the events its role triggers ([ADR-0007] routing) — it just resolves each event to the venue-chosen clip.
- **Mute stays device-local.** The existing per-device "Alert audio" toggle (`audioAlertEnabled`, SharedPreferences) is unchanged and orthogonal: it silences a device entirely, regardless of the venue's sound choices.
- **Backward-compatible defaults.** New `VenueSettingsDto` fields carry `@Default`s that reproduce today's behaviour exactly (newOrder=alert, ready=chime, void=alert, overdue=alert). Old servers that omit the columns fall through to the same defaults, and the Drift schema bump (33→34) is an additive `_safeAddColumnOn` — no data migration.

## Consequences

- Four new TEXT columns on `venue_settings` + four `VenueSettingsDto` fields, threaded through the GET/PATCH route and the repo's patch body. The DTO field semantics are now load-bearing (a typo in a stored preset id must degrade gracefully) — `AlertSoundService` resolves an unknown/missing id back to the default clip rather than throwing or going silent.
- `AlertSoundService` preloads one `AudioPlayer` **per preset** (not per cue) so any event can map to any clip without a reload; it watches `venueSettingsRepositoryProvider` and re-resolves event→clip on change. `none` short-circuits before playback.
- The venue settings screen gains a **"Suara"** section with a per-event picker and a **preview** button (a shared one-shot player) so the admin hears a clip before saving.
- Sound choice is venue-wide on purpose: a device-local override was rejected because it contradicts placing the control on the *venue* settings screen and would let the same event mean different things to different staff. Accepted cost: a device cannot pick its own sounds (it can only mute).
- Adding a preset later = drop a `.wav` in `assets/sounds/` + one registry row; removing one needs a fallback for venues still pointing at it (handled by the same unknown-id→default rule).
