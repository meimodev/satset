import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:satset/data/services/dummy_data_service.dart';
import 'package:satset/domain/models/venue_table.dart';

const _uuid = Uuid();

class TablesRepository extends StateNotifier<List<VenueTable>> {
  TablesRepository(DummyDataService seed) : super(seed.initialTables());

  void markPending(String id, {String? userId}) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(
            status: TableStatus.pending,
            elapsed: t.elapsed ?? '0:01',
            mine: true,
            lastActorId: userId ?? t.lastActorId,
          )
        else
          t,
    ];
  }

  void decrementReady(String id, {String? userId}) {
    state = [
      for (final t in state)
        if (t.id == id)
          (t.readyCount <= 1)
              ? t.copyWith(
                  status: TableStatus.occupied,
                  readyCount: 0,
                  lastActorId: userId ?? t.lastActorId,
                )
              : t.copyWith(
                  readyCount: t.readyCount - 1,
                  lastActorId: userId ?? t.lastActorId,
                )
        else
          t,
    ];
  }

  void recordHandler(String id, String userId) {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(lastActorId: userId) else t,
    ];
  }

  void incrementPax(String id, {String? userId}) {
    state = [
      for (final t in state)
        if (t.id == id && t.pax < 12)
          t.copyWith(pax: t.pax + 1, lastActorId: userId ?? t.lastActorId)
        else
          t,
    ];
  }

  void decrementPax(String id, {String? userId}) {
    state = [
      for (final t in state)
        if (t.id == id && t.pax > 1)
          t.copyWith(pax: t.pax - 1, lastActorId: userId ?? t.lastActorId)
        else
          t,
    ];
  }

  // --- Floor configuration ---

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
        (ref) => TablesRepository(ref.watch(dummyDataServiceProvider)));

final totalReadyCountProvider = Provider<int>((ref) {
  final tables = ref.watch(tablesProvider);
  return tables.fold<int>(
    0,
    (s, t) => s + (t.status == TableStatus.ready ? (t.readyCount > 0 ? t.readyCount : 1) : 0),
  );
});
