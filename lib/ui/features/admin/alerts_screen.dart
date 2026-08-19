import 'package:satset/core/localization/labels.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:satset/ui/core/widgets/sat_icon_button.dart';
import 'package:satset/ui/core/widgets/sat_toggle.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/domain/models/alert_sound.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import '_common.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/widgets/sat_overlay.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/l10n/app_localizations.dart';

/// Everything that decides whether the floor beeps, in one destination.
///
/// Grouped by *scope*, not by event: venue-wide thresholds, then venue-wide
/// sounds, then this handset's mute list. Scope is what gets misread ("I muted
/// it, why does the waiter still hear it"), so it is the top-level split and
/// every block says out loud who it applies to.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(venueSettingsProvider);
    final wide = context.layout.useTabletShell;
    return AdminPage(
      title: context.l10n.alertsTitle,
      sub: alertsSummary(context.l10n, s),
      children: [
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _ThresholdCard()),
                const SizedBox(width: Sp.s3h),
                Expanded(child: _SoundCard()),
              ],
            ),
          )
        else ...[
          _ThresholdCard(),
          const SizedBox(height: Sp.s3h),
          _SoundCard(),
        ],
        const SizedBox(height: Sp.s3h),
        const _DeviceMuteCard(),
      ],
    );
  }
}

/// The one place an [AlertEvent] is named for a human.
///
/// Was two static const tables — one on the sound card, one on the device mute
/// card — which agreed only by luck. Localising them made that duplication a
/// real hazard, since a translator would have had to find both. ADR-0083.
String alertEventLabel(AppL10n l10n, AlertEvent e) => switch (e) {
  AlertEvent.newOrder => l10n.venueSettingsSoundNewOrder,
  AlertEvent.orderReady => l10n.venueSettingsSoundReady,
  AlertEvent.voided => l10n.venueSettingsSoundVoid,
  AlertEvent.overdue => l10n.venueSettingsSoundOverdue,
  AlertEvent.ungreeted => l10n.venueSettingsSoundUngreeted,
  AlertEvent.pickup => l10n.venueSettingsSoundPickup,
  AlertEvent.guestPending => l10n.venueSettingsSoundGuestPending,
};

/// Same summary the hub tile badge shows — the two thresholds an owner tunes
/// most.
String alertsSummary(AppL10n l10n, VenueSettingsDto s) =>
    l10n.alertsThresholdLine(s.prepTargetMins, s.ungreetedMins);

/// Card chrome shared by the three scope blocks. [scope] is never optional:
/// a block that does not say who it applies to is the bug this screen exists
/// to fix.
class _ScopeCard extends StatelessWidget {
  const _ScopeCard({
    required this.title,
    required this.scope,
    required this.deviceScoped,
    required this.child,
    this.hint,
  });

  final String title;
  final String scope;
  final bool deviceScoped;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    return Container(
      padding: const EdgeInsets.all(Sp.s5),
      decoration: SatBox.d(
        // Device-local config sits on a different surface so it never reads as
        // "one more venue setting".
        color: deviceScoped ? sc.bg1 : sc.bg2,
        border: SatB.all(color: deviceScoped ? sc.border1 : sc.border0),
        borderRadius: SatR.a(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: SatType.labelL(color: sc.textHi)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.s2,
                  vertical: Sp.s1,
                ),
                decoration: SatBox.d(
                  color: deviceScoped ? sc.bg3 : sc.bg1,
                  border: SatB.all(color: sc.border0),
                  borderRadius: SatR.a(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      deviceScoped
                          ? Icons.phone_android_rounded
                          : Icons.storefront_outlined,
                      size: 11,
                      color: sc.textLo,
                    ),
                    const SizedBox(width: Sp.s1),
                    Text(
                      scope.toUpperCase(),
                      style: SatType.caption(color: sc.textLo),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: Sp.s1h),
            Text(hint!, style: SatType.bodyS(color: sc.textLo)),
          ],
          const SizedBox(height: Sp.s3),
          child,
        ],
      ),
    );
  }
}

/// Every service threshold in one named place (ADR-0043/0044). Thresholds
/// decide *when* a cue fires; the sound card decides *what it sounds like*;
/// the device mute card decides whether this handset plays it at all. Three
/// orthogonal axes, deliberately not merged.
class _ThresholdCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final s = ref.watch(venueSettingsProvider);
    final n = ref.read(venueSettingsProvider.notifier);
    return _ScopeCard(
      title: context.l10n.alertsSectionThresholds,
      scope: context.l10n.alertsScopeVenue,
      deviceScoped: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MinutesRow(
            label: context.l10n.venueSettingsTimingPrepTarget,
            hint: context.l10n.venueSettingsTimingPrepTargetHint,
            value: s.prepTargetMins,
            min: 5,
            max: 60,
            onChanged: (v) => n.patch(prepTargetMins: v),
          ),
          _rule(sc),
          _MinutesRow(
            label: context.l10n.venueSettingsTimingPickup,
            hint: context.l10n.venueSettingsTimingPickupHint,
            value: s.pickupTargetMins,
            min: 1,
            max: 30,
            step: 1,
            onChanged: (v) => n.patch(pickupTargetMins: v),
            enabled: s.pickupAlertEnabled,
            onEnabledChanged: (v) => n.patch(pickupAlertEnabled: v),
          ),
          _rule(sc),
          _MinutesRow(
            label: context.l10n.venueSettingsTimingUngreeted,
            hint: context.l10n.venueSettingsTimingUngreetedHint,
            value: s.ungreetedMins,
            min: 1,
            max: 30,
            step: 1,
            onChanged: (v) => n.patch(ungreetedMins: v),
            enabled: s.ungreetedAlertEnabled,
            onEnabledChanged: (v) => n.patch(ungreetedAlertEnabled: v),
          ),
          _MinutesRow(
            label: context.l10n.venueSettingsTimingUngreetedEscalate,
            hint: context.l10n.venueSettingsTimingUngreetedEscalateHint,
            value: s.ungreetedEscalateMins,
            min: 1,
            max: 30,
            step: 1,
            onChanged: (v) => n.patch(ungreetedEscalateMins: v),
          ),
          _rule(sc),
          _MinutesRow(
            label: context.l10n.venueSettingsTimingLongStay,
            hint: context.l10n.venueSettingsTimingLongStayHint,
            value: s.longStayMins,
            min: 15,
            max: 240,
            step: 15,
            onChanged: (v) => n.patch(longStayMins: v),
          ),
          _MinutesRow(
            label: context.l10n.venueSettingsTimingIdle,
            hint: context.l10n.venueSettingsTimingIdleHint,
            value: s.idleTableMins,
            min: 5,
            max: 120,
            onChanged: (v) => n.patch(idleTableMins: v),
          ),
          _rule(sc),
          _MinutesRow(
            label: context.l10n.venueSettingsTimingReservationGrace,
            hint: context.l10n.venueSettingsTimingReservationGraceHint,
            value: s.reservationGraceMins,
            min: 0,
            max: 120,
            onChanged: (v) => n.patch(reservationGraceMins: v),
          ),
        ],
      ),
    );
  }

  Widget _rule(SatColors sc) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Sp.s3h),
    child: Divider(height: 1, color: sc.border0),
  );
}

/// Label + hint on the left, a −/value/+ stepper on the right, and (for the
/// two audible cues) a venue-wide on/off. "Off" is this switch, never a
/// degenerate threshold — a disabled cue and a mistyped one must stay
/// distinguishable (ADR-0044).
///
/// The switch silences the **sound** only. The threshold keeps driving the
/// floor card's standing state and the report SLA, so the stepper stays live
/// when the switch is off — locking it implied the number had stopped
/// mattering, which was never true.
class _MinutesRow extends StatelessWidget {
  const _MinutesRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 5,
    this.enabled,
    this.onEnabledChanged,
  });

  final String label;
  final String hint;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final bool? enabled;
  final ValueChanged<bool>? onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final on = enabled ?? true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.s1h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SatType.bodyM(color: sc.textMd)),
                const SizedBox(height: Sp.sHair),
                Text(hint, style: SatType.bodyS(color: sc.textLo)),
              ],
            ),
          ),
          if (onEnabledChanged != null) ...[
            SatToggle(
              value: on,
              semanticLabel: label,
              onChanged: (v) => onEnabledChanged!(v),
            ),
            const SizedBox(width: Sp.s1),
          ],
          _step(
            context,
            sc,
            Icons.remove,
            value > min ? () => onChanged(value - step) : null,
          ),
          const SizedBox(width: Sp.s2),
          SizedBox(
            width: 66,
            child: Text(
              context.l10n.altMinutes(value),
              textAlign: TextAlign.center,
              style: SatType.monoM(color: sc.textHi),
            ),
          ),
          const SizedBox(width: Sp.s2),
          _step(
            context,
            sc,
            Icons.add,
            value < max ? () => onChanged(value + step) : null,
          ),
        ],
      ),
    );
  }

  /// Delegates to [SatIconButton]: an icon-only target needs a tooltip, and
  /// deriving it from the glyph is how every one of these gets named without
  /// the call sites repeating it.
  Widget _step(
    BuildContext context,
    SatColors sc,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return SatIconButton.outline(
      icon: icon,
      tooltip: icon == Icons.add
          ? context.l10n.stepperIncrease
          : context.l10n.stepperDecrease,
      size: 34,
      onTap: onTap,
    );
  }
}

/// Venue-wide alert sound chooser (ADR-0035). Picks a preset per [AlertEvent];
/// the choice rides [VenueSettingsDto] to every paired device. Stateful only to
/// own a one-shot preview player.
class _SoundCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SoundCard> createState() => _SoundCardState();
}

class _SoundCardState extends ConsumerState<_SoundCard> {
  final _preview = AudioPlayer();

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  Future<void> _playPreset(String? asset) async {
    if (asset == null) return; // 'none' — nothing to hear.
    try {
      await _preview.stop();
      await _preview.play(AssetSource(asset));
    } catch (_) {
      // Missing/bad clip — swallow; the picker still works.
    }
  }

  /// Display order only — the labels come from [alertEventLabel]. This used to
  /// be a `(AlertEvent, String)` table alongside a second, identical map on
  /// `_DeviceMuteCard`; localising them made the duplication load-bearing, so
  /// there is now one order and one naming function.
  static const _events = <AlertEvent>[
    AlertEvent.newOrder,
    AlertEvent.orderReady,
    AlertEvent.voided,
    AlertEvent.overdue,
    AlertEvent.ungreeted,
    AlertEvent.pickup,
    AlertEvent.guestPending,
  ];

  String _currentId(VenueSettingsDto s, AlertEvent e) => switch (e) {
    AlertEvent.newOrder => s.soundNewOrder,
    AlertEvent.orderReady => s.soundReady,
    AlertEvent.voided => s.soundVoid,
    AlertEvent.overdue => s.soundOverdue,
    AlertEvent.ungreeted => s.soundUngreeted,
    AlertEvent.pickup => s.soundPickup,
    AlertEvent.guestPending => s.soundGuestPending,
  };

  void _patch(AlertEvent e, String id) {
    final n = ref.read(venueSettingsProvider.notifier);
    switch (e) {
      case AlertEvent.newOrder:
        n.patch(soundNewOrder: id);
      case AlertEvent.orderReady:
        n.patch(soundReady: id);
      case AlertEvent.voided:
        n.patch(soundVoid: id);
      case AlertEvent.overdue:
        n.patch(soundOverdue: id);
      case AlertEvent.ungreeted:
        n.patch(soundUngreeted: id);
      case AlertEvent.pickup:
        n.patch(soundPickup: id);
      case AlertEvent.guestPending:
        n.patch(soundGuestPending: id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final s = ref.watch(venueSettingsProvider);
    return _ScopeCard(
      title: context.l10n.venueSettingsSectionSound,
      scope: context.l10n.alertsScopeVenue,
      deviceScoped: false,
      hint: context.l10n.alertsSoundHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final event in _events)
            _row(sc, s, event, alertEventLabel(context.l10n, event)),
        ],
      ),
    );
  }

  Widget _row(
    SatColors sc,
    VenueSettingsDto s,
    AlertEvent event,
    String label,
  ) {
    final id = resolveSoundId(event, _currentId(s, event));
    final preset = presetForId(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: SatType.bodyM(color: sc.textHi)),
          ),
          GestureDetector(
            onTap: () => _openPicker(sc, event),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.s3,
                vertical: Sp.s2,
              ),
              decoration: SatBox.d(
                color: sc.bg1,
                border: SatB.all(color: sc.border0),
                borderRadius: SatR.a(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    preset == null
                        ? id
                        : alertSoundLabel(context.l10n, preset.id),
                    style: SatType.bodyM(color: sc.textHi),
                  ),
                  const SizedBox(width: Sp.s1h),
                  Icon(Icons.expand_more, size: 16, color: sc.textLo),
                ],
              ),
            ),
          ),
          const SizedBox(width: Sp.s1h),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: preset == null || preset.isSilent
                ? null
                : () => _playPreset(preset.asset),
            icon: Icon(
              preset != null && preset.isSilent
                  ? Icons.volume_off
                  : Icons.play_circle_outline,
              size: 22,
              color: preset == null || preset.isSilent
                  ? sc.textDim
                  : sc.accentText,
            ),
            tooltip: context.l10n.venueSettingsSoundPreview,
          ),
        ],
      ),
    );
  }

  void _openPicker(SatColors sc, AlertEvent event) {
    final selected = resolveSoundId(
      event,
      _currentId(ref.read(venueSettingsProvider), event),
    );
    showSatSheet<void>(
      context,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: Sp.s2),
            children: [
              for (final preset in alertSoundPresets)
                ListTile(
                  onTap: () {
                    _patch(event, preset.id);
                    Navigator.of(ctx).pop();
                  },
                  leading: Icon(
                    preset.id == selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: preset.id == selected ? sc.accentText : sc.textLo,
                  ),
                  title: Text(
                    alertSoundLabel(context.l10n, preset.id),
                    style: SatType.bodyM(color: sc.textHi),
                  ),
                  trailing: IconButton(
                    tooltip: preset.isSilent
                        ? context.l10n.a11ySoundSilent
                        : context.l10n.a11ySoundPreview,
                    onPressed: preset.isSilent
                        ? null
                        : () => _playPreset(preset.asset),
                    icon: Icon(
                      preset.isSilent
                          ? Icons.volume_off
                          : Icons.play_circle_outline,
                      color: preset.isSilent ? sc.textDim : sc.accentText,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Device-local per-event mute. Lists only the cues this device's role can
/// actually receive, so a waiter is never offered a switch for a kitchen cue.
class _DeviceMuteCard extends ConsumerWidget {
  const _DeviceMuteCard();

  /// Mirrors the routing in `AlertSoundService`: the kitchen (Server mode)
  /// hears the kitchen cues, waiters hear the guest-facing ones.
  static const _kitchen = {
    AlertEvent.newOrder,
    AlertEvent.overdue,
    AlertEvent.voided,
  };
  static const _waiter = {
    AlertEvent.orderReady,
    AlertEvent.voided,
    AlertEvent.ungreeted,
    AlertEvent.pickup,
    AlertEvent.guestPending,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final muted = ref.watch(mutedAlertsProvider);
    final mode = ref.watch(prefsServiceProvider).valueOrNull?.appMode();
    final visible = (mode == AppMode.server ? _kitchen : _waiter).toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return _ScopeCard(
      title: context.l10n.venueSettingsTimingMuteTitle,
      scope: context.l10n.alertsScopeDevice,
      deviceScoped: true,
      hint: context.l10n.venueSettingsTimingMuteHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in visible)
            Row(
              children: [
                Expanded(
                  child: Text(
                    alertEventLabel(context.l10n, e),
                    style: SatType.bodyM(color: sc.textMd),
                  ),
                ),
                SatToggle(
                  value: !muted.contains(e),
                  semanticLabel: alertEventLabel(context.l10n, e),
                  onChanged: (v) async {
                    final prefs = ref.read(prefsServiceProvider).valueOrNull;
                    if (prefs == null) return;
                    await prefs.setAlertMuted(e, !v);
                    ref.invalidate(prefsServiceProvider);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
