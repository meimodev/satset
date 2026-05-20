import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dummy_data.dart';
import '../models/venue_table.dart';

class TablesNotifier extends StateNotifier<List<VenueTable>> {
  TablesNotifier() : super(List.of(DummyData.tables));

  void markPending(String id) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(
            status: TableStatus.pending,
            elapsed: t.elapsed ?? '0:01',
            mine: true,
          )
        else
          t,
    ];
  }

  void decrementReady(String id) {
    state = [
      for (final t in state)
        if (t.id == id)
          (t.readyCount <= 1)
              ? t.copyWith(status: TableStatus.occupied, readyCount: 0)
              : t.copyWith(readyCount: t.readyCount - 1)
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
