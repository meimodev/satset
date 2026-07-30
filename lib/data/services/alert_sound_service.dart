import 'dart:async';
import 'package:satset/core/time/sat_clock.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ticket_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/menu_repository.dart';
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
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/service_timing.dart';
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
    // Routing is by device role (ADR-0007): the kitchen owns the overdue
    // sweep, waiters own the table cues.
    if (_mode == AppMode.server) {
      _overdueTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _scanCourseOverdue(),
      );
    }
    if (_mode == AppMode.client) {
      _tableTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        _scanPickup();
        unawaited(_refreshOnline());
        _scanUngreeted();
      });
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
  Timer? _tableTimer;

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

  /// One-shot ledgers. Cues never loop or demand acknowledgement — the
  /// escalation *is* the second chance (ADR-0044).
  final Set<String> _overdueAlerted = {};
  final Set<String> _pickupAlerted = {};
  final Set<String> _ungreetedAlerted = {};

  /// User ids with a live staff session, refreshed on the table-scan tick.
  /// Null until the first successful fetch — distinct from "nobody is online",
  /// because an unknown set must not be read as "everyone is signed out"
  /// (that would fire every table floor-wide the moment the network hiccups).
  Set<String>? _onlineUserIds;

  Future<void> _refreshOnline() async {
    try {
      final raw = await ref.read(apiClientProvider).getJson('/auth/online');
      final ids = ((raw as Map)['userIds'] as List).cast<String>();
      _onlineUserIds = ids.toSet();
    } catch (e) {
      // Keep the last known set rather than dropping to "nobody online".
      SatLog.vm('alert.online refresh failed $e');
    }
  }

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
      AlertEvent.ungreeted => s.soundUngreeted,
      AlertEvent.pickup => s.soundPickup,
      AlertEvent.guestPending => s.soundGuestPending,
    };
    return resolveSoundId(event, stored);
  }

  void _onEvent(WsEventDto ev) {
    // A guest order does not fire to the kitchen — it waits on a waiter to
    // approve it, so the cue goes to waiter devices at submit, not to the
    // pass. Without it the review queue was a passive badge (ADR-0064).
    if (ev.type == WsEventTypes.guestOrderSubmitted) {
      if (_mode == AppMode.client) _play(AlertEvent.guestPending);
      return;
    }
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
          _play(
            AlertEvent.voided,
          ); // Targeted void/comp for responsible waiter.
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

  /// Kitchen cue. The unit of "late" is the **course**, not the line: a
  /// course's target is the `max` of its lines' resolved targets, so a
  /// "Bersama Utama" side is not flagged for correctly waiting on its mains.
  /// One-shot per course (ADR-0043/0044).
  void _scanCourseOverdue() {
    final byVisit = ref.read(ticketsProvider);
    final settings = ref.read(venueSettingsProvider);
    final prepByItem = {
      for (final i in ref.read(menuItemsProvider)) i.id: i.prepTime,
    };
    final now = SatClock.now();

    final lines = <TimedLine>[];
    for (final entry in byVisit.entries) {
      for (final t in entry.value) {
        if (t.status == TicketStatus.voided) continue;
        if (t.status == TicketStatus.held) continue; // Not the kitchen's yet.
        lines.add(
          TimedLine(
            visitKey: entry.key,
            course: t.course.name,
            start: t.kitchenClockStart,
            readyAt: t.readyAtTime,
            targetMins: resolvePrepMins(
              prepByItem[t.itemId],
              settings.prepTargetMins,
            ),
          ),
        );
      }
    }

    for (final c in rollUpCourses(lines)) {
      final key =
          '${c.visitKey}:${c.course}:'
          '${c.firedAt.millisecondsSinceEpoch}';
      if (_overdueAlerted.contains(key)) continue;
      if (c.isOverdueAt(now)) {
        _overdueAlerted.add(key);
        _play(AlertEvent.overdue);
      }
    }
  }

  /// Waiter cue: food is sitting at the pass going cold (`readyAt → servedAt`).
  /// One-shot per line.
  void _scanPickup() {
    final settings = ref.read(venueSettingsProvider);
    if (!settings.pickupAlertEnabled) return;
    final limit = Duration(minutes: settings.pickupTargetMins);
    final now = SatClock.now();
    for (final list in ref.read(ticketsProvider).values) {
      for (final t in list) {
        if (t.status != TicketStatus.ready) continue;
        final readyAt = t.readyAtTime;
        if (readyAt == null) continue;
        if (_pickupAlerted.contains(t.id)) continue;
        if (now.difference(readyAt) >= limit) {
          _pickupAlerted.add(t.id);
          _play(AlertEvent.pickup);
        }
      }
    }
  }

  /// Waiter cue: a seated table with nothing sent yet. Escalates — the seating
  /// waiter is cued first, then the whole floor `ungreetedEscalateMins` later,
  /// so one busy or signed-out waiter cannot swallow it (ADR-0044).
  void _scanUngreeted() {
    final settings = ref.read(venueSettingsProvider);
    if (!settings.ungreetedAlertEnabled) return;
    final tables = ref.read(tablesProvider);
    final byVisit = ref.read(ticketsProvider);
    final me = ref.read(authStateProvider).user?.id;
    final now = SatClock.now();

    for (final t in tables) {
      if (t.status == TableStatus.available) continue;
      final openedAt = t.openedAt;
      if (openedAt == null) continue;
      // Any line at all — held included — means someone took the order.
      final visitId = t.currentVisitId;
      final ordered =
          visitId != null && (byVisit[visitId]?.isNotEmpty ?? false);
      if (ordered) continue;

      final cue = ungreetedCueFor(
        age: now.difference(openedAt),
        ungreetedMins: settings.ungreetedMins,
        escalateMins: settings.ungreetedEscalateMins,
        seaterId: t.lastActorId,
        myUserId: me,
        onlineUserIds: _onlineUserIds,
      );
      // Stage keys dedup independently, and a short-circuited stage one uses
      // the floor-wide key so the scheduled escalation cannot re-fire it.
      switch (cue) {
        case UngreetedCue.none:
          break;
        case UngreetedCue.seatingWaiter:
          if (_ungreetedAlerted.add('${t.id}:1')) _play(AlertEvent.ungreeted);
        case UngreetedCue.floorWide:
          if (_ungreetedAlerted.add('${t.id}:2')) _play(AlertEvent.ungreeted);
      }
    }
  }

  void _play(AlertEvent event) {
    final prefs = ref.read(prefsServiceProvider).valueOrNull;
    // Device-local per-event mute, the only device-level axis — one annoying
    // cue never costs the operator every other cue (ADR-0044).
    if (prefs?.mutedAlerts().contains(event) ?? false) {
      SatLog.vm('alert.skip ${event.name} (event muted)');
      return;
    }
    final soundId = _soundIdFor(event);
    if (soundId == kNoneSoundId) {
      SatLog.vm('alert.skip ${event.name} (none)');
      return;
    }
    if (_cooling.contains(event)) {
      return; // Leading-edge throttle: collapse bursts.
    }
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
    _tableTimer?.cancel();
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
