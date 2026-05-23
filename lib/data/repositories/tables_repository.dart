import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:satset/data/models/table_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/dummy_data_service.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/venue_table.dart';

const _uuid = Uuid();

/// Surfaces bootstrap progress for the tables list. UIs can show a spinner
/// while [AsyncValue.isLoading], or an inline retry banner on [hasError].
final tablesStatusProvider =
    StateProvider<AsyncValue<void>>((_) => const AsyncValue.data(null));

class TablesRepository extends StateNotifier<List<VenueTable>> {
  TablesRepository({required this.ref, required DummyDataService seed})
      : super(seed.initialTables()) {
    _bootstrap();
  }

  final Ref ref;
  StreamSubscription? _wsSub;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      // Pre-pairing / dev fallback. Seed already loaded; mark ready.
      ref.read(tablesStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    // Clear stale dummy rows when bootstrapping a real LAN session.
    state = const <VenueTable>[];
    ref.read(tablesStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      final raw = await api.getJson('/tables') as List;
      final dtos = raw
          .map((e) => TableDto.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      state = [for (final d in dtos) _toDomain(d)];
      ref.read(tablesStatusProvider.notifier).state =
          const AsyncValue.data(null);
    } catch (e, st) {
      // Surface — do NOT fall back to dummy data when the LAN is supposed
      // to be authoritative.
      ref.read(tablesStatusProvider.notifier).state =
          AsyncValue.error(e, st);
    }
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type == WsEventTypes.tableUpdated) {
        final d = TableDto.fromJson(ev.payload);
        state = [
          for (final t in state)
            if (t.id == d.id) _toDomain(d) else t,
        ];
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  VenueTable _toDomain(TableDto d) {
    return VenueTable(
      id: d.id,
      zoneId: d.zoneId,
      label: d.label,
      pax: d.pax,
      active: d.active,
      status: TableStatus.values.firstWhere(
        (s) => s.name == d.status,
        orElse: () => TableStatus.available,
      ),
      openAmount: d.openAmount,
      readyCount: d.readyCount,
      lastActorId: d.lastActorId,
    );
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

  Future<void> markPending(String id, {String? userId}) async {
    final prev = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (prev != null) {
      _replace(
        id,
        prev.copyWith(
          status: TableStatus.pending,
          elapsed: prev.elapsed ?? '0:01',
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

  Future<void> decrementReady(String id, {String? userId}) async {
    final prev = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (prev != null) {
      _replace(
        id,
        prev.readyCount <= 1
            ? prev.copyWith(
                status: TableStatus.occupied,
                readyCount: 0,
                lastActorId: userId ?? prev.lastActorId,
              )
            : prev.copyWith(
                readyCount: prev.readyCount - 1,
                lastActorId: userId ?? prev.lastActorId,
              ),
      );
    }
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final raw = await ref.read(apiClientProvider).postJson(
        '/tables/$id/ready/decrement',
        {'actorId': ?userId},
      );
      _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
    } catch (_) {
      if (prev != null) _replace(id, prev);
      rethrow;
    }
  }

  Future<void> setPax(String id, int pax, {String? userId}) async {
    final prev = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (prev != null) {
      _replace(
        id,
        prev.copyWith(pax: pax, lastActorId: userId ?? prev.lastActorId),
      );
    }
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final raw = await ref.read(apiClientProvider).patchJson(
        '/tables/$id/pax',
        {'pax': pax, 'actorId': ?userId},
      );
      _mergeDto(TableDto.fromJson((raw as Map).cast<String, dynamic>()));
    } catch (_) {
      if (prev != null) _replace(id, prev);
      rethrow;
    }
  }

  Future<void> setHandler(String id, String userId) async {
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

  Future<void> incrementPax(String id, {String? userId}) async {
    final cur = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (cur == null || cur.pax >= 12) return;
    await setPax(id, cur.pax + 1, userId: userId);
  }

  Future<void> decrementPax(String id, {String? userId}) async {
    final cur = state.where((t) => t.id == id).cast<VenueTable?>().firstOrNull;
    if (cur == null || cur.pax <= 1) return;
    await setPax(id, cur.pax - 1, userId: userId);
  }

  // --- Floor configuration (local-only; no LAN endpoint yet) ---

  String addTable({
    required String zoneId,
    required String label,
    int pax = 2,
  }) {
    final id = _uuid.v4();
    state = [
      ...state,
      VenueTable(
        id: id,
        zoneId: zoneId,
        label: label.trim().isEmpty ? null : label.trim(),
        pax: pax,
      ),
    ];
    return id;
  }

  void removeTable(String id) {
    state = state.where((t) => t.id != id).toList();
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

  void configureTable(
    String id, {
    String? label,
    int? pax,
    String? zoneId,
    bool? active,
  }) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(
            label: label,
            pax: pax,
            zoneId: zoneId,
            active: active,
          )
        else
          t,
    ];
  }
}

final tablesProvider =
    StateNotifierProvider<TablesRepository, List<VenueTable>>(
        (ref) => TablesRepository(
              ref: ref,
              seed: ref.watch(dummyDataServiceProvider),
            ));

final totalReadyCountProvider = Provider<int>((ref) {
  final tables = ref.watch(tablesProvider);
  return tables.fold<int>(
    0,
    (s, t) => s + (t.status == TableStatus.ready ? (t.readyCount > 0 ? t.readyCount : 1) : 0),
  );
});
