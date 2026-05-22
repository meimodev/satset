import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dummy_data.dart';
import '../models/venue_table.dart';

class TablesNotifier extends StateNotifier<List<VenueTable>> {
  TablesNotifier() : super(List.of(DummyData.tables));

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
}

final tablesProvider =
    StateNotifierProvider<TablesNotifier, List<VenueTable>>((ref) => TablesNotifier());

final totalReadyCountProvider = Provider<int>((ref) {
  final tables = ref.watch(tablesProvider);
  return tables.fold<int>(
    0,
    (s, t) => s + (t.status == TableStatus.ready ? (t.readyCount > 0 ? t.readyCount : 1) : 0),
  );
});
