import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ticket_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/app_mode.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/core/state/ready_alert_view_model.dart';

/// The three semantic audio cues. See ADR-0007 and CONTEXT.md "Audio alert".
enum AlertCue { ding, chime, alert }

const _cueAsset = <AlertCue, String>{
  AlertCue.ding: 'sounds/ding.wav',
  AlertCue.chime: 'sounds/chime.wav',
  AlertCue.alert: 'sounds/alert.wav',
};

/// Overdue line shared with the KDS age pill (`kitchen_screen.dart`).
const _overdueMinutes = 10;

/// Burst-coalescing window: bunched events of one cue collapse to a single
/// play (a fired course = one ding, not eight).
const _debounce = Duration(milliseconds: 500);

/// Listens to WS ticket events and plays role-appropriate cues. Routing is by
/// device app mode, not by active screen — a waiter still hears "ready" deep
/// in the menu flow; the kitchen still hears "new order" while on reports.
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
  // One preloaded player per cue so distinct cues never cut each other off.
  // Default (media-player) mode — lowLatency/SoundPool hangs on seek(), which
  // we need to rewind a preloaded source for replay. Falls back to a one-shot
  // player if preload hasn't finished.
  final Map<AlertCue, AudioPlayer> _players = {};
  bool _ready = false;
  StreamSubscription? _wsSub;
  Timer? _overdueTimer;

  Future<void> _initPlayers() async {
    try {
      for (final e in _cueAsset.entries) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource(e.value));
        _players[e.key] = p;
      }
      _ready = true;
      SatLog.vm('alert.players preloaded n=${_players.length}');
    } catch (e, st) {
      SatLog.err('alert preload', e, st);
    }
  }

  final Map<String, TicketStatus> _lastStatus = {};
  final Set<String> _overdueAlerted = {};
  final Set<AlertCue> _cooling = {};

  AppMode get _mode =>
      ref.read(prefsServiceProvider).valueOrNull?.appMode() ?? AppMode.unset;

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
        // alert.wav (not ding) — kitchen needs a loud, unmissable new-order cue.
        if (mode == AppMode.server) _play(AlertCue.alert);
      case TicketStatus.ready:
        if (mode == AppMode.client) {
          _play(AlertCue.chime);
          _raiseReadyAlert(dto);
        }
      case TicketStatus.voided:
        if (mode == AppMode.server) {
          _play(AlertCue.alert); // Kitchen recall.
        } else if (mode == AppMode.client && _isMyTable(dto.tableId)) {
          _play(AlertCue.alert); // Targeted void/comp for the responsible waiter.
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
    final zone = table == null
        ? ''
        : (ref
                .read(zonesProvider)
                .where((z) => z.id == table.zoneId)
                .firstOrNull
                ?.name ??
            '');
    ref.read(readyAlertProvider.notifier).state = ReadyAlert(
      tableId: table?.displayName ?? dto.tableId,
      zone: zone,
      what: '${dto.qty} ${dto.name}',
    );
  }

  void _scanOverdue() {
    final byTable = ref.read(ticketsProvider);
    final now = DateTime.now();
    for (final list in byTable.values) {
      for (final t in list) {
        final kitchenActive = t.status == TicketStatus.sent ||
            t.status == TicketStatus.prep ||
            t.status == TicketStatus.cooked;
        if (!kitchenActive) continue;
        if (_overdueAlerted.contains(t.id)) continue;
        if (_ageMinutes(t.sentAt, now) >= _overdueMinutes) {
          _overdueAlerted.add(t.id);
          _play(AlertCue.alert);
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

  void _play(AlertCue cue) {
    if (!(ref.read(prefsServiceProvider).valueOrNull?.audioAlertEnabled() ??
        true)) {
      SatLog.vm('alert.skip ${cue.name} (muted)');
      return;
    }
    if (_cooling.contains(cue)) return; // Leading-edge throttle: collapse bursts.
    _cooling.add(cue);
    Timer(_debounce, () => _cooling.remove(cue));
    if (_mode == AppMode.client) {
      HapticFeedback.mediumImpact();
    }
    SatLog.vm('alert.play ${cue.name} ready=$_ready');
    unawaited(_emit(cue));
  }

  Future<void> _emit(AlertCue cue) async {
    try {
      final p = _players[cue];
      if (_ready && p != null) {
        await p.seek(Duration.zero);
        await p.resume();
      } else {
        // Preload not finished yet — one-shot fallback.
        await AudioPlayer().play(AssetSource(_cueAsset[cue]!));
      }
    } catch (e, st) {
      SatLog.err('alert play ${cue.name}', e, st);
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
