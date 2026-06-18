import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ticket_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/takeaway_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/alert_sound.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/core/state/ready_alert_view_model.dart';

/// Burst-coalescing window: bunched events of one kind collapse to a single
/// play (a fired course = one cue, not eight).
const _debounce = Duration(milliseconds: 500);

/// Listens to WS ticket events and plays role-appropriate cues. Routing is by
/// device app mode, not by active screen — a waiter still hears "ready" deep
/// in the menu flow; the kitchen still hears "new order" while on reports.
///
/// *Which clip* plays for each [AlertEvent] is the venue's selectable choice
/// ([VenueSettingsDto.soundNewOrder] etc.) resolved at play time — see ADR-0035.
class AlertSoundService {
  AlertSoundService(this.ref) {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return; // Idle until paired; provider re-creates us later.
    unawaited(_initPlayers());
    _wsSub = ref.read(wsClientProvider).events.listen(_onEvent);
    if (_mode == AppMode.server) {
      _overdueTimer =
          Timer.periodic(const Duration(seconds: 20), (_) => _scanOverdue());
    }
    SatLog.vm('alert.service started mode=${_mode.name}');
  }

  final Ref ref;
  // One preloaded player per non-silent preset, keyed by preset id, so any
  // event can map to any clip without a reload and distinct cues never cut each
  // other off. Default (media-player) mode — lowLatency/SoundPool hangs on
  // seek(), which we need to rewind a preloaded source for replay. Falls back to
  // a one-shot player if preload hasn't finished.
  final Map<String, AudioPlayer> _players = {};
  bool _ready = false;
  StreamSubscription? _wsSub;
  Timer? _overdueTimer;

  Future<void> _initPlayers() async {
    // Per-preset try: a missing/bad clip skips only that preset (it falls back
    // to its event default at play time) instead of killing every sound.
    for (final preset in alertSoundPresets) {
      final asset = preset.asset;
      if (asset == null) continue; // 'none' has no clip.
      try {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource(asset));
        _players[preset.id] = p;
      } catch (e, st) {
        SatLog.err('alert preload ${preset.id}', e, st);
      }
    }
    _ready = true;
    SatLog.vm('alert.players preloaded n=${_players.length}');
  }

  final Map<String, TicketStatus> _lastStatus = {};
  final Set<String> _overdueAlerted = {};
  final Set<AlertEvent> _cooling = {};

  AppMode get _mode =>
      ref.read(prefsServiceProvider).valueOrNull?.appMode() ?? AppMode.unset;

  /// The venue-chosen preset id for [event], degraded to the event default if
  /// the stored id names a preset that no longer exists.
  String _soundIdFor(AlertEvent event) {
    final s = ref.read(venueSettingsProvider);
    final stored = switch (event) {
      AlertEvent.newOrder => s.soundNewOrder,
      AlertEvent.orderReady => s.soundReady,
      AlertEvent.voided => s.soundVoid,
      AlertEvent.overdue => s.soundOverdue,
    };
    return resolveSoundId(event, stored);
  }

  void _onEvent(WsEventDto ev) {
    if (ev.type != WsEventTypes.ticketCreated &&
        ev.type != WsEventTypes.ticketUpdated) {
      return;
    }
    final TicketDto dto;
    try {
      dto = TicketDto.fromJson(ev.payload);
    } catch (_) {
      return;
    }
    final to = ticketStatusFromKey(dto.status);
    final from = _lastStatus[dto.id];
    _lastStatus[dto.id] = to;
    if (from == to) return; // No transition — nothing to announce.

    final mode = _mode;
    SatLog.vm('alert.evt ${dto.status} (was ${from?.name}) mode=${mode.name}');
    switch (to) {
      case TicketStatus.sent:
        // New work reached the kitchen (sent, or a held course fired).
        if (mode == AppMode.server) _play(AlertEvent.newOrder);
      case TicketStatus.ready:
        if (mode == AppMode.client) {
          _play(AlertEvent.orderReady);
          _raiseReadyAlert(dto);
        }
      case TicketStatus.voided:
        if (mode == AppMode.server) {
          _play(AlertEvent.voided); // Kitchen recall.
        } else if (mode == AppMode.client && _isMyTable(dto.tableId)) {
          _play(AlertEvent.voided); // Targeted void/comp for responsible waiter.
        }
      default:
        break;
    }
  }

  bool _isMyTable(String tableId) {
    final myId = ref.read(authStateProvider).user?.id;
    if (myId == null) return false;
    final table = ref
        .read(tablesProvider)
        .where((t) => t.id == tableId)
        .cast<dynamic>()
        .firstOrNull;
    return table?.lastActorId == myId;
  }

  void _raiseReadyAlert(TicketDto dto) {
    final table = ref
        .read(tablesProvider)
        .where((t) => t.id == dto.tableId)
        .firstOrNull;
    // Table-less line ⇒ resolve the takeaway visit (ticket key == visitId) so
    // the toast shows the Bawa pulang label/guest, not a raw id, and "Ambil"
    // routes to the takeaway detail. See ADR-0026.
    if (table == null) {
      final visit = ref
          .read(takeawayVisitsProvider)
          .where((v) => v.id == dto.tableId)
          .firstOrNull;
      if (visit != null) {
        ref.read(readyAlertProvider.notifier).state = ReadyAlert(
          tableId: dto.tableId,
          tableLabel: visit.label,
          zone: visit.guestName ?? '',
          what: '${dto.qty} ${dto.name}',
          isTakeaway: true,
        );
        return;
      }
    }
    final zone = table == null
        ? ''
        : (ref
                .read(zonesProvider)
                .where((z) => z.id == table.zoneId)
                .firstOrNull
                ?.name ??
            '');
    ref.read(readyAlertProvider.notifier).state = ReadyAlert(
      tableId: dto.tableId,
      tableLabel: table?.displayName ?? dto.tableId,
      zone: zone,
      what: '${dto.qty} ${dto.name}',
    );
  }

  void _scanOverdue() {
    final byTable = ref.read(ticketsProvider);
    final now = DateTime.now();
    // Overdue line = the venue's configurable service target (ADR-0013).
    final overdueMinutes = ref.read(venueSettingsProvider).prepTargetMins;
    for (final list in byTable.values) {
      for (final t in list) {
        final kitchenActive = t.status == TicketStatus.sent ||
            t.status == TicketStatus.prep ||
            t.status == TicketStatus.cooked;
        if (!kitchenActive) continue;
        if (_overdueAlerted.contains(t.id)) continue;
        if (_ageMinutes(t.sentAt, now) >= overdueMinutes) {
          _overdueAlerted.add(t.id);
          _play(AlertEvent.overdue);
        }
      }
    }
  }

  /// Parses the domain `HH:mm` stamp into elapsed whole minutes.
  int _ageMinutes(String hhmm, DateTime now) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return 0;
    var sent = DateTime(now.year, now.month, now.day, h, m);
    if (sent.isAfter(now)) sent = sent.subtract(const Duration(days: 1));
    final diff = now.difference(sent).inMinutes;
    return diff < 0 ? 0 : diff;
  }

  void _play(AlertEvent event) {
    if (!(ref.read(prefsServiceProvider).valueOrNull?.audioAlertEnabled() ??
        true)) {
      SatLog.vm('alert.skip ${event.name} (muted)');
      return;
    }
    final soundId = _soundIdFor(event);
    if (soundId == kNoneSoundId) {
      SatLog.vm('alert.skip ${event.name} (none)');
      return;
    }
    if (_cooling.contains(event)) return; // Leading-edge throttle: collapse bursts.
    _cooling.add(event);
    Timer(_debounce, () => _cooling.remove(event));
    if (_mode == AppMode.client) {
      HapticFeedback.mediumImpact();
    }
    SatLog.vm('alert.play ${event.name}=$soundId ready=$_ready');
    unawaited(_emit(soundId));
  }

  Future<void> _emit(String soundId) async {
    try {
      final p = _players[soundId];
      if (_ready && p != null) {
        await p.seek(Duration.zero);
        await p.resume();
      } else {
        // Preload not finished yet — one-shot fallback.
        final asset = presetForId(soundId)?.asset;
        if (asset != null) await AudioPlayer().play(AssetSource(asset));
      }
    } catch (e, st) {
      SatLog.err('alert play $soundId', e, st);
    }
  }

  void dispose() {
    _wsSub?.cancel();
    _overdueTimer?.cancel();
    for (final p in _players.values) {
      p.dispose();
    }
  }
}

/// Keep-alive singleton. Re-created when [apiConfigProvider] flips (pair /
/// unpair). Mount [alertHostProvider]'s widget — or watch this directly — so it
/// stays instantiated regardless of which screen is foreground.
final alertSoundServiceProvider = Provider<AlertSoundService>((ref) {
  ref.watch(apiConfigProvider);
  final svc = AlertSoundService(ref);
  ref.onDispose(svc.dispose);
  return svc;
});
