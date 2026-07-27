import 'package:audioplayers/audioplayers.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/core/localization/app_strings.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/domain/models/alert_sound.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/layout.dart';
import 'package:satset/ui/core/design/typography.dart';
import '_common.dart';

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
      title: AppStrings.alertsTitle,
      sub: alertsSummary(s),
      children: [
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _ThresholdCard()),
                const SizedBox(width: 14),
                Expanded(child: _SoundCard()),
              ],
            ),
          )
        else ...[
          _ThresholdCard(),
          const SizedBox(height: 14),
          _SoundCard(),
        ],
        const SizedBox(height: 14),
        const _DeviceMuteCard(),
      ],
    );
  }
}

/// Same summary the hub tile badge shows — the two thresholds an owner tunes
/// most.
String alertsSummary(VenueSettingsDto s) =>
    'Siap ${s.prepTargetMins}m · belum dilayani ${s.ungreetedMins}m';

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
      padding: const EdgeInsets.all(20),
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
                child: Text(
                  title,
                  style: SatType.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: sc.textHi,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    const SizedBox(width: 4),
                    Text(
                      scope.toUpperCase(),
                      style: SatType.mono(
                        size: 9,
                        weight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: sc.textLo,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: SatType.sans(size: 12, color: sc.textLo, height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
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
      title: AppStrings.alertsSectionThresholds,
      scope: AppStrings.alertsScopeVenue,
      deviceScoped: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MinutesRow(
            label: AppStrings.venueSettingsTimingPrepTarget,
            hint: AppStrings.venueSettingsTimingPrepTargetHint,
            value: s.prepTargetMins,
            min: 5,
            max: 60,
            onChanged: (v) => n.patch(prepTargetMins: v),
          ),
          _rule(sc),
          _MinutesRow(
            label: AppStrings.venueSettingsTimingPickup,
            hint: AppStrings.venueSettingsTimingPickupHint,
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
            label: AppStrings.venueSettingsTimingUngreeted,
            hint: AppStrings.venueSettingsTimingUngreetedHint,
            value: s.ungreetedMins,
            min: 1,
            max: 30,
            step: 1,
            onChanged: (v) => n.patch(ungreetedMins: v),
            enabled: s.ungreetedAlertEnabled,
            onEnabledChanged: (v) => n.patch(ungreetedAlertEnabled: v),
          ),
          _MinutesRow(
            label: AppStrings.venueSettingsTimingUngreetedEscalate,
            hint: AppStrings.venueSettingsTimingUngreetedEscalateHint,
            value: s.ungreetedEscalateMins,
            min: 1,
            max: 30,
            step: 1,
            onChanged: (v) => n.patch(ungreetedEscalateMins: v),
          ),
          _rule(sc),
          _MinutesRow(
            label: AppStrings.venueSettingsTimingLongStay,
            hint: AppStrings.venueSettingsTimingLongStayHint,
            value: s.longStayMins,
            min: 15,
            max: 240,
            step: 15,
            onChanged: (v) => n.patch(longStayMins: v),
          ),
          _MinutesRow(
            label: AppStrings.venueSettingsTimingIdle,
            hint: AppStrings.venueSettingsTimingIdleHint,
            value: s.idleTableMins,
            min: 5,
            max: 120,
            onChanged: (v) => n.patch(idleTableMins: v),
          ),
          _rule(sc),
          _MinutesRow(
            label: AppStrings.venueSettingsTimingReservationGrace,
            hint: AppStrings.venueSettingsTimingReservationGraceHint,
            value: s.reservationGraceMins,
            min: 0,
            max: 120,
            onChanged: (v) => n.patch(reservationGraceMins: v),
          ),
          _MinutesRow(
            label: AppStrings.venueSettingsTimingPendingReview,
            hint: AppStrings.venueSettingsTimingPendingReviewHint,
            value: s.pendingReviewMins,
            min: 1,
            max: 60,
            onChanged: (v) => n.patch(pendingReviewMins: v),
          ),
        ],
      ),
    );
  }

  Widget _rule(SatColors sc) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Divider(height: 1, color: sc.border0),
      );
}

/// Label + hint on the left, a −/value/+ stepper on the right, and (for the
/// two audible cues) a venue-wide on/off. "Off" is this switch, never a
/// degenerate threshold — a disabled cue and a mistyped one must stay
/// distinguishable (ADR-0044).
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: SatType.sans(
                    size: 13,
                    color: on ? sc.textMd : sc.textLo,
                  ),
                ),
                const SizedBox(height: 2),
                Text(hint, style: SatType.sans(size: 11, color: sc.textLo)),
              ],
            ),
          ),
          if (onEnabledChanged != null) ...[
            Switch(
              value: on,
              onChanged: (v) => onEnabledChanged!(v),
            ),
            const SizedBox(width: 4),
          ],
          _step(sc, Icons.remove,
              on && value > min ? () => onChanged(value - step) : null),
          const SizedBox(width: 8),
          SizedBox(
            width: 66,
            child: Text(
              '$value min',
              textAlign: TextAlign.center,
              style: SatType.mono(
                size: 13,
                weight: FontWeight.w600,
                color: on ? sc.textHi : sc.textLo,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _step(sc, Icons.add,
              on && value < max ? () => onChanged(value + step) : null),
        ],
      ),
    );
  }

  Widget _step(SatColors sc, IconData icon, VoidCallback? onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: SatBox.d(
            color: onTap == null ? sc.bg2 : sc.bg3,
            border: SatB.all(color: sc.border1),
            borderRadius: SatR.a(9),
          ),
          child: Icon(
            icon,
            size: 17,
            color: onTap == null ? sc.textLo : sc.textHi,
          ),
        ),
      );
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

  static const _events = <(AlertEvent, String)>[
    (AlertEvent.newOrder, AppStrings.venueSettingsSoundNewOrder),
    (AlertEvent.orderReady, AppStrings.venueSettingsSoundReady),
    (AlertEvent.voided, AppStrings.venueSettingsSoundVoid),
    (AlertEvent.overdue, AppStrings.venueSettingsSoundOverdue),
    (AlertEvent.ungreeted, AppStrings.venueSettingsSoundUngreeted),
    (AlertEvent.pickup, AppStrings.venueSettingsSoundPickup),
  ];

  String _currentId(VenueSettingsDto s, AlertEvent e) => switch (e) {
    AlertEvent.newOrder => s.soundNewOrder,
    AlertEvent.orderReady => s.soundReady,
    AlertEvent.voided => s.soundVoid,
    AlertEvent.overdue => s.soundOverdue,
    AlertEvent.ungreeted => s.soundUngreeted,
    AlertEvent.pickup => s.soundPickup,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final s = ref.watch(venueSettingsProvider);
    return _ScopeCard(
      title: AppStrings.venueSettingsSectionSound,
      scope: AppStrings.alertsScopeVenue,
      deviceScoped: false,
      hint: 'Pilih nada untuk tiap kejadian. Pilihan ini berlaku untuk semua '
          'perangkat di venue.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (event, label) in _events) _row(sc, s, event, label),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: SatType.sans(size: 13, color: sc.textHi)),
          ),
          GestureDetector(
            onTap: () => _openPicker(sc, event),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: SatBox.d(
                color: sc.bg1,
                border: SatB.all(color: sc.border0),
                borderRadius: SatR.a(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    preset?.label ?? id,
                    style: SatType.sans(size: 12.5, color: sc.textHi),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.expand_more, size: 16, color: sc.textLo),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
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
              color: preset == null || preset.isSilent ? sc.textDim : sc.accentText,
            ),
            tooltip: AppStrings.venueSettingsSoundPreview,
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: sc.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: SatR.c(18)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                    preset.label,
                    style: SatType.sans(size: 14, color: sc.textHi),
                  ),
                  trailing: IconButton(
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

  static const _labels = <AlertEvent, String>{
    AlertEvent.newOrder: AppStrings.venueSettingsSoundNewOrder,
    AlertEvent.orderReady: AppStrings.venueSettingsSoundReady,
    AlertEvent.voided: AppStrings.venueSettingsSoundVoid,
    AlertEvent.overdue: AppStrings.venueSettingsSoundOverdue,
    AlertEvent.ungreeted: AppStrings.venueSettingsSoundUngreeted,
    AlertEvent.pickup: AppStrings.venueSettingsSoundPickup,
  };

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
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = context.sat;
    final muted = ref.watch(mutedAlertsProvider);
    final mode = ref.watch(prefsServiceProvider).valueOrNull?.appMode();
    final visible =
        (mode == AppMode.server ? _kitchen : _waiter).toList()
          ..sort((a, b) => a.index.compareTo(b.index));

    return _ScopeCard(
      title: AppStrings.venueSettingsTimingMuteTitle,
      scope: AppStrings.alertsScopeDevice,
      deviceScoped: true,
      hint: AppStrings.venueSettingsTimingMuteHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in visible)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _labels[e]!,
                    style: SatType.sans(size: 13, color: sc.textMd),
                  ),
                ),
                Switch(
                  value: !muted.contains(e),
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
