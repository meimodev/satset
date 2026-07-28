import 'dart:async';
import 'package:satset/core/time/sat_clock.dart';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/table_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/venue_table.dart';

/// Outcome of a [TablesRepository.acquireLock] call. Mutually exclusive:
/// either [acquired] holds the post-write table snapshot, or [conflict] holds
/// the current (other-user) lock state from the server.
class TableLockResult {
  final VenueTable? acquired;
  final VenueTable? conflict;
  const TableLockResult._({this.acquired, this.conflict});
  factory TableLockResult.acquired(VenueTable t) =>
      TableLockResult._(acquired: t);
  factory TableLockResult.conflict(VenueTable t) =>
      TableLockResult._(conflict: t);
  bool get isAcquired => acquired != null;
}

const _uuid = Uuid();

/// Surfaces bootstrap progress for the tables list. UIs can show a spinner
/// while [AsyncValue.isLoading], or an inline retry banner on [hasError].
final tablesStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

class TablesRepository extends StateNotifier<List<VenueTable>> {
  TablesRepository({required this.ref}) : super(const <VenueTable>[]) {
    // Defer to a microtask: Riverpod forbids mutating other providers
    // (tablesStatusProvider) during this notifier's own initialization.
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;
  bool _resyncing = false;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      // Pre-pairing / dev fallback. Seed already loaded; mark ready.
      ref.read(tablesStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
      return;
    }
    // Clear stale dummy rows when bootstrapping a real LAN session.
    state = const <VenueTable>[];
    ref.read(tablesStatusProvider.notifier).state = const AsyncValue.loading();
    try {
      await _refetch();
      ref.read(tablesStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
    } catch (e, st) {
      // Surface — do NOT fall back to dummy data when the LAN is supposed
      // to be authoritative. The WS-reconnect resync (below) recovers when
      // the socket next reaches `open` (e.g. once the admin token lands).
      ref.read(tablesStatusProvider.notifier).state = AsyncValue.error(e, st);
    }
    // Wire WS even if the bootstrap GET failed: the `connected` resync is the
    // recovery path for an empty/401 bootstrap. See ADR-0021.
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type == WsEventTypes.connected) {
        unawaited(_resync());
      } else if (ev.type == WsEventTypes.tableUpdated) {
        final d = TableDto.fromJson(ev.payload);
        SatLog.repo(
          'tables.ws update id=${d.id.substring(0, d.id.length.clamp(0, 6))} status=${d.status}',
        );
        final exists = state.any((t) => t.id == d.id);
        state = exists
            ? [
                for (final t in state)
                  if (t.id == d.id) _toDomain(d) else t,
              ]
            : [...state, _toDomain(d)];
      } else if (ev.type == WsEventTypes.tableCreated) {
        final d = TableDto.fromJson(ev.payload);
        if (state.any((t) => t.id == d.id)) return;
        SatLog.repo(
          'tables.ws create id=${d.id.substring(0, d.id.length.clamp(0, 6))}',
        );
        state = [...state, _toDomain(d)];
      } else if (ev.type == WsEventTypes.tableDeleted) {
        final id = ev.payload['id'] as String?;
        if (id == null) return;
        SatLog.repo(
          'tables.ws delete id=${id.substring(0, id.length.clamp(0, 6))}',
        );
        state = [
          for (final t in state)
            if (t.id != id) t,
        ];
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  /// Pull the authoritative table list and replace state. Shared by the
  /// initial [_bootstrap] and the WS-reconnect [_resync].
  Future<void> _refetch() async {
    final api = ref.read(apiClientProvider);
    final raw = await api.getJson('/tables') as List;
    final dtos = raw
        .map((e) => TableDto.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    state = [for (final d in dtos) _toDomain(d)];
    SatLog.repo('tables.loaded n=${state.length}');
  }

  /// Full-resync triggered by [WsEventTypes.connected] on every socket
  /// (re)connect. Incremental table events are lossy — a table that mutated
  /// while we were down (or before our bootstrap GET succeeded) would never
  /// otherwise appear. Guarded so overlapping connects don't stampede; never
  /// throws (a transient failure simply waits for the next connect). ADR-0021.
  Future<void> _resync() async {
    if (_resyncing) return;
    _resyncing = true;
    try {
      await _refetch();
      SatLog.repo('tables.resync ok');
    } catch (e) {
      SatLog.repo('tables.resync fail $e');
    } finally {
      _resyncing = false;
    }
  }

  VenueTable _toDomain(TableDto d) {
    return VenueTable(
      id: d.id,
      zoneId: d.zoneId,
      label: d.label,
      pax: d.pax,
      capacity: d.capacity,
      active: d.active,
      status: TableStatus.values.firstWhere(
        (s) => s.name == d.status,
        orElse: () => TableStatus.available,
      ),
      openAmount: d.openAmount,
      readyCount: d.readyCount,
      lastActorId: d.lastActorId,
      lockedBy: d.lockedBy,
      lockedByName: d.lockedByName,
      lockedAt: d.lockedAt,
      lockExpiresAt: d.lockExpiresAt,
      openedAt: d.openedAt,
      elapsed: d.openedAt == null ? null : _elapsedStr(d.openedAt!),
      guestName: d.guestName,
      guestNotes: d.guestNotes,
      reservationId: d.reservationId,
      currentVisitId: d.currentVisitId,
      billClosed: d.billClosedAt != null,
      moneyState: d.moneyState,
      guestOrderingEnabled: d.guestOrderingEnabled,
    );
  }

  static String _elapsedStr(DateTime openedAt) {
    final d = SatClock.now().difference(openedAt).abs();
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0
        ? '$h:${m.toString().padLeft(2, '0')}'
        : '0:${m.toString().padLeft(2, '0')}';
  }

  /// Apply a server-returned [TableDto] to local state. Used both by
  /// REST callers (after a 2xx mutation) and the optimistic-rollback path.
  void _mergeDto(TableDto d) {
    final merged = _toDomain(d);
    state = [
      for (final t in state)
        if (t.id == d.id) merged else t,
    ];
  }

  /// Replace one table by id with [next]. Used for optimistic updates and
  /// for rolling back when the server rejects a mutation.
  void _replace(String id, VenueTable next) {
    state = [
      for (final t in state)
        if (t.id == id) next else t,
    ];
  }

  /// Seed a table's [currentVisitId] from an order response, before the
  /// `tableUpdated` WS echo lands. Lets the sending device resolve its
  /// just-sent lines immediately (the live-ticket cache keys by visit). No-op
  /// if the table is unknown or already on this visit. See ADR-0034.
  void seedCurrentVisit(String tableId, String? visitId) {
    if (visitId == null || visitId.isEmpty) return;
    final cur = state.where((t) => t.id == tableId).firstOrNull;
    if (cur == null || cur.currentVisitId == visitId) return;
    _replace(tableId, cur.copyWith(currentVisitId: visitId));
  }

  /// Seat a table at [id]: marks occupied, sets pax, attaches guest info.
  /// When [acquireLock] is true, the server atomically also writes the lock
  /// fields for [userId] — used by the reservation seat flow which lacks an
  /// already-open table_detail screen to auto-acquire after the WS broadcast.
  /// Walk-in seat (caller already on table_detail) omits the flag and lets
  /// the screen's existing auto-acquire timer claim the lock.
  ///
  /// Server returns 409 `already_seated` if the table is no longer
  /// `available`; this method rolls back the optimistic update and rethrows
  /// the [ApiException] so the caller can surface a toast.
  Future<void> seat(
    String id, {
    required int pax,
    String? guestName,
    String? guestNotes,
    String? reservationId,
    String? userId,
    String? userName,
    bool acquireLock = false,
  }) async {
    SatLog.repo(
      'tables.seat id=${id.substring(0, id.length.clamp(0, 6))} pax=$pax acquireLock=$acquireLock',
    );
    final prev = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (prev != null) {
      final now = SatClock.now();
      _replace(
        id,
        prev.copyWith(
          status: TableStatus.occupied,
          pax: pax.clamp(0, prev.capacity < 1 ? 1 : prev.capacity),
          openedAt: prev.openedAt ?? now,
          elapsed: prev.elapsed ?? _elapsedStr(prev.openedAt ?? now),
          mine: true,
          lastActorId: userId ?? prev.lastActorId,
          guestName: guestName,
          guestNotes: guestNotes,
          reservationId: reservationId,
          lockedBy: acquireLock && userId != null ? userId : prev.lockedBy,
          lockedByName: acquireLock && userId != null
              ? userName
              : prev.lockedByName,
          lockedAt: acquireLock && userId != null ? now : prev.lockedAt,
          lockExpiresAt: acquireLock && userId != null
              ? now.add(const Duration(seconds: 7))
              : prev.lockExpiresAt,
        ),
      );
    }
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final raw = await ref
          .read(apiClientProvider)
          .postJson('/tables/$id/seat', {
            'pax': pax,
            'actorId': ?userId,
            'actorName': ?userName,
            'guestName': ?guestName,
            'guestNotes': ?guestNotes,
            'reservationId': ?reservationId,
            if (acquireLock) 'acquireLock': true,
          });
      _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
    } on ApiException catch (e) {
      // Rollback optimistic mutation. On a 409 the server payload carries the
      // current table row — merge it so the UI shows accurate state behind
      // the toast.
      if (prev != null) _replace(id, prev);
      if (e.statusCode == 409 && e.code == 'already_seated') {
        try {
          final body = jsonDecode(e.body) as Map<String, dynamic>;
          final t = body['table'];
          if (t is Map) {
            _mergeDto(TableDto.fromJson(t.cast<String, dynamic>()));
          }
        } catch (_) {}
      }
      rethrow;
    } catch (_) {
      if (prev != null) _replace(id, prev);
      rethrow;
    }
  }

  Future<void> markPending(String id, {String? userId}) async {
    SatLog.repo(
      'tables.markPending id=${id.substring(0, id.length.clamp(0, 6))}',
    );
    final prev = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (prev != null) {
      final now = SatClock.now();
      _replace(
        id,
        prev.copyWith(
          status: TableStatus.pending,
          openedAt: prev.openedAt ?? now,
          elapsed: prev.elapsed ?? _elapsedStr(prev.openedAt ?? now),
          mine: true,
          lastActorId: userId ?? prev.lastActorId,
        ),
      );
    }
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final raw = await ref.read(apiClientProvider).postJson(
        '/tables/$id/pending',
        {'actorId': ?userId},
      );
      _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
    } catch (_) {
      if (prev != null) _replace(id, prev);
      rethrow;
    }
  }

  /// Clearing a ready plate does **not** claim the table — the runner is doing
  /// the handler a favour, and `lastActorId` now scopes the Pesanan board.
  /// See ADR-0056.
  Future<void> decrementReady(String id) async {
    SatLog.repo('tables.decReady id=${id.substring(0, id.length.clamp(0, 6))}');
    final prev = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (prev != null) {
      _replace(
        id,
        prev.readyCount <= 1
            ? prev.copyWith(status: TableStatus.occupied, readyCount: 0)
            : prev.copyWith(readyCount: prev.readyCount - 1),
      );
    }
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final raw = await ref
          .read(apiClientProvider)
          .postJson('/tables/$id/ready/decrement', const {});
      _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
    } catch (_) {
      if (prev != null) _replace(id, prev);
      rethrow;
    }
  }

  /// Correcting a headcount does **not** claim the table. See ADR-0056.
  Future<void> setPax(String id, int pax) async {
    SatLog.repo(
      'tables.setPax id=${id.substring(0, id.length.clamp(0, 6))} pax=$pax',
    );
    final prev = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (prev != null) {
      _replace(id, prev.copyWith(pax: pax));
    }
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final raw = await ref.read(apiClientProvider).patchJson('/tables/$id/pax', {
        'pax': pax,
      });
      _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
    } catch (_) {
      if (prev != null) _replace(id, prev);
      rethrow;
    }
  }

  /// Per-table opt-in for guest self-ordering (ADR-0027/0028). Optimistic;
  /// rolls back on failure. Goes through the generic `PATCH /tables/<id>`.
  Future<void> setGuestOrdering(String id, bool enabled) async {
    SatLog.repo(
      'tables.setGuestOrdering id=${id.substring(0, id.length.clamp(0, 6))} on=$enabled',
    );
    final prev = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (prev != null) {
      _replace(id, prev.copyWith(guestOrderingEnabled: enabled));
    }
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final raw = await ref.read(apiClientProvider).patchJson('/tables/$id', {
        'guestOrderingEnabled': enabled,
      });
      _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
    } catch (_) {
      if (prev != null) _replace(id, prev);
      rethrow;
    }
  }

  Future<void> setHandler(String id, String userId) async {
    SatLog.repo(
      'tables.setHandler id=${id.substring(0, id.length.clamp(0, 6))} user=${userId.substring(0, userId.length.clamp(0, 6))}',
    );
    final prev = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (prev != null) {
      _replace(id, prev.copyWith(lastActorId: userId));
    }
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final raw = await ref.read(apiClientProvider).patchJson(
        '/tables/$id/handler',
        {'userId': userId},
      );
      _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
    } catch (_) {
      if (prev != null) _replace(id, prev);
      rethrow;
    }
  }

  void recordHandler(String id, String userId) {
    // Fire-and-forget; rollback on failure handled inside setHandler.
    unawaited(setHandler(id, userId));
  }

  Future<void> incrementPax(String id) async {
    final cur = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (cur == null || cur.pax >= cur.capacity) return;
    await setPax(id, cur.pax + 1);
  }

  Future<void> decrementPax(String id) async {
    final cur = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (cur == null || cur.pax <= 0) return;
    await setPax(id, cur.pax - 1);
  }

  // --- Floor configuration (local-only; no LAN endpoint yet) ---

  String addTable({
    required String zoneId,
    required String label,
    int capacity = 2,
  }) {
    SatLog.repo(
      'tables.add zone=${zoneId.substring(0, zoneId.length.clamp(0, 6))} label=$label',
    );
    final id = _uuid.v4();
    final cap = capacity < 1 ? 1 : capacity;
    final next = VenueTable(
      id: id,
      zoneId: zoneId,
      label: label.trim().isEmpty ? null : label.trim(),
      pax: 0, // empty until waiter seats guests.
      capacity: cap,
    );
    state = [...state, next];
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return id;
    unawaited(_postCreate(next));
    return id;
  }

  Future<void> _postCreate(VenueTable t) async {
    try {
      final raw = await ref.read(apiClientProvider).postJson('/tables', {
        'id': t.id,
        'zoneId': t.zoneId,
        'label': t.label,
        'pax': t.pax,
        'capacity': t.capacity,
        'active': t.active,
      });
      _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
    } catch (e) {
      SatLog.repo('tables.create fail $e');
      state = state.where((x) => x.id != t.id).toList();
    }
  }

  void removeTable(String id) {
    SatLog.repo('tables.remove id=${id.substring(0, id.length.clamp(0, 6))}');
    final prev = state;
    state = state.where((t) => t.id != id).toList();
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    unawaited(() async {
      try {
        await ref.read(apiClientProvider).deleteJson('/tables/$id');
      } catch (e) {
        SatLog.repo('tables.delete fail $e');
        state = prev;
      }
    }());
  }

  /// Reorders tables within a single zone. Indices are relative to that
  /// zone's filtered sublist; the surrounding zone slots stay put.
  void reorderTable(String zoneId, int oldIndex, int newIndex) {
    final zoneTables = state.where((t) => t.zoneId == zoneId).toList();
    if (newIndex > oldIndex) newIndex -= 1;
    zoneTables.insert(newIndex, zoneTables.removeAt(oldIndex));
    var k = 0;
    state = [
      for (final t in state)
        if (t.zoneId == zoneId) zoneTables[k++] else t,
    ];
  }

  /// Acquire (or refresh own) lock on [id]. The server is authoritative;
  /// on 409 returns a [TableLockResult.conflict] carrying the current holder
  /// state so the UI can show a read-only banner.
  Future<TableLockResult> acquireLock(
    String id, {
    required String userId,
    required String userName,
    int ttlSeconds = 7,
  }) async {
    SatLog.repo(
      'tables.lock.acquire id=${id.substring(0, id.length.clamp(0, 6))} user=${userId.substring(0, userId.length.clamp(0, 6))}',
    );
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      final cur = state
          .where((t) => t.id == id)
          .cast<VenueTable?>()
          .firstOrNull;
      if (cur == null) throw StateError('table not found: $id');
      return TableLockResult.acquired(cur);
    }
    try {
      final raw = await ref.read(apiClientProvider).postJson(
        '/tables/$id/lock',
        {'userId': userId, 'userName': userName, 'ttlSeconds': ttlSeconds},
      );
      final dto = TableDto.fromJson((raw as Map).cast<String, dynamic>());
      _mergeDto(dto);
      return TableLockResult.acquired(_toDomain(dto));
    } on ApiException catch (e) {
      if (e.statusCode == 409 && e.code == 'table_locked') {
        try {
          final body = jsonDecode(e.body) as Map<String, dynamic>;
          final tableJson = (body['table'] as Map).cast<String, dynamic>();
          final dto = TableDto.fromJson(tableJson);
          _mergeDto(dto);
          return TableLockResult.conflict(_toDomain(dto));
        } catch (_) {
          // Fall through if the server didn't include a payload.
        }
      }
      rethrow;
    }
  }

  /// Refresh the lease. Returns true while the caller is still the holder,
  /// false on 409 (another user took the table or the lease expired).
  Future<bool> heartbeatLock(
    String id, {
    required String userId,
    int ttlSeconds = 7,
  }) async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return true;
    try {
      final raw = await ref.read(apiClientProvider).postJson(
        '/tables/$id/lock/heartbeat',
        {'userId': userId, 'ttlSeconds': ttlSeconds},
      );
      _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        try {
          final body = jsonDecode(e.body) as Map<String, dynamic>;
          final t = body['table'];
          if (t is Map) {
            _mergeDto(TableDto.fromJson(t.cast<String, dynamic>()));
          }
        } catch (_) {}
        return false;
      }
      rethrow;
    }
  }

  /// Best-effort release. Safe to call from dispose paths — swallows
  /// network errors. The server treats DELETE as idempotent.
  Future<void> releaseLock(String id) async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final raw = await ref
          .read(apiClientProvider)
          .deleteJson('/tables/$id/lock');
      if (raw is Map) {
        _mergeDto(TableDto.fromJson(raw.cast<String, dynamic>()));
      }
    } catch (e) {
      SatLog.repo('tables.lock.release fail $e');
    }
  }

  /// Close + settle the table. Clears lock and resets status to `available`.
  /// UI gates this behind "no live tickets"; server also rejects 409
  /// (no_tickets | tickets_not_terminal) if the bill isn't fully terminal.
  Future<void> closeTable(String id, {String? actorId}) async {
    SatLog.repo('tables.close id=${id.substring(0, id.length.clamp(0, 6))}');
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      final prev = state
          .where((t) => t.id == id)
          .cast<VenueTable?>()
          .firstOrNull;
      if (prev != null) {
        _replace(
          id,
          prev.copyWith(
            status: TableStatus.available,
            readyCount: 0,
            openAmount: 0,
            pax: 0,
          ),
        );
      }
      return;
    }
    final raw = await ref.read(apiClientProvider).postJson(
      '/tables/$id/close',
      {'actorId': ?actorId},
    );
    _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
  }

  /// Return a seated table to `available` without settling a session. Used
  /// when a guest leaves before placing any order (no tickets to record).
  Future<void> releaseTable(String id, {String? actorId}) async {
    SatLog.repo('tables.release id=${id.substring(0, id.length.clamp(0, 6))}');
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      final prev = state
          .where((t) => t.id == id)
          .cast<VenueTable?>()
          .firstOrNull;
      if (prev != null) {
        _replace(
          id,
          prev.copyWith(
            status: TableStatus.available,
            readyCount: 0,
            openAmount: 0,
            pax: 0,
          ),
        );
      }
      return;
    }
    final raw = await ref.read(apiClientProvider).postJson(
      '/tables/$id/release',
      {'actorId': ?actorId},
    );
    _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
  }

  /// Pindah meja: transfer the whole live session from [id] onto the empty
  /// [targetId]. The server re-points tickets, copies the session, wipes the
  /// source, and hands the lock to the mover (ADR-0019). Returns the merged
  /// target row; the source update arrives over WS. Throws [ApiException] on
  /// rejection (e.g. 409 target_unavailable / table_locked) so the caller can
  /// surface a toast.
  Future<void> moveTable(
    String id, {
    required String targetId,
    String? actorId,
    String? actorName,
  }) async {
    SatLog.repo(
      'tables.move src=${id.substring(0, id.length.clamp(0, 6))} dst=${targetId.substring(0, targetId.length.clamp(0, 6))}',
    );
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      // Dev / no-LAN fallback: emulate the transfer locally so the UI flows.
      final src = state
          .where((t) => t.id == id)
          .cast<VenueTable?>()
          .firstOrNull;
      final tgt = state
          .where((t) => t.id == targetId)
          .cast<VenueTable?>()
          .firstOrNull;
      if (src == null || tgt == null) return;
      _replace(
        targetId,
        tgt.copyWith(
          status: src.status,
          pax: src.pax,
          openAmount: src.openAmount,
          readyCount: src.readyCount,
          openedAt: src.openedAt,
          lastActorId: src.lastActorId,
          guestName: src.guestName,
          guestNotes: src.guestNotes,
          reservationId: src.reservationId,
        ),
      );
      _replace(
        id,
        src.copyWith(
          status: TableStatus.available,
          pax: 0,
          openAmount: 0,
          readyCount: 0,
        ),
      );
      return;
    }
    final raw = await ref.read(apiClientProvider).postJson('/tables/$id/move', {
      'targetId': targetId,
      'actorId': ?actorId,
      'actorName': ?actorName,
    });
    _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
  }

  void configureTable(
    String id, {
    String? label,
    int? capacity,
    String? zoneId,
    bool? active,
  }) {
    final prev = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    state = [
      for (final t in state)
        if (t.id == id)
          () {
            final nextCap = capacity == null
                ? t.capacity
                : (capacity < 1 ? 1 : capacity);
            // Shrinking capacity below current pax drags pax down so the
            // optimistic state never violates pax <= capacity.
            final nextPax = t.pax > nextCap ? nextCap : t.pax;
            return t.copyWith(
              label: label,
              capacity: nextCap,
              pax: nextPax,
              zoneId: zoneId,
              active: active,
            );
          }()
        else
          t,
    ];
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    unawaited(() async {
      try {
        final body = <String, dynamic>{
          'label': ?label,
          'capacity': ?capacity,
          'zoneId': ?zoneId,
          'active': ?active,
        };
        final raw = await ref
            .read(apiClientProvider)
            .patchJson('/tables/$id', body);
        _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
      } catch (e) {
        SatLog.repo('tables.configure fail $e');
        if (prev != null) _replace(id, prev);
      }
    }());
  }
}

final tablesProvider =
    StateNotifierProvider<TablesRepository, List<VenueTable>>((ref) {
      ref.watch(apiConfigProvider);
      return TablesRepository(ref: ref);
    });

final totalReadyCountProvider = Provider<int>((ref) {
  final tables = ref.watch(tablesProvider);
  return tables.fold<int>(
    0,
    (s, t) =>
        s +
        (t.status == TableStatus.ready
            ? (t.readyCount > 0 ? t.readyCount : 1)
            : 0),
  );
});
