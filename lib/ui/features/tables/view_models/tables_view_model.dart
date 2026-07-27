import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/zones_repository.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/models/zone.dart';

class TablesScreenState {
  final List<Zone> zones;
  final List<VenueTable> tables;
  const TablesScreenState({required this.zones, required this.tables});
}

/// Read-only projection consumed by `TablesScreen`. Hides repository
/// providers from the view.
class TablesViewModel extends StateNotifier<TablesScreenState> {
  TablesViewModel(this.ref)
    : super(
        TablesScreenState(
          zones: ref.read(zonesProvider),
          tables: ref.read(tablesProvider),
        ),
      ) {
    ref.listen(zonesProvider, (_, next) {
      state = TablesScreenState(zones: next, tables: state.tables);
    });
    ref.listen(tablesProvider, (_, next) {
      state = TablesScreenState(zones: state.zones, tables: next);
    });
  }

  final Ref ref;

  Future<void> setPax(String tableId, int pax) =>
      ref.read(tablesProvider.notifier).setPax(tableId, pax);

  Future<void> setHandler(String tableId, String userId) =>
      ref.read(tablesProvider.notifier).setHandler(tableId, userId);
}

final tablesViewModelProvider =
    StateNotifierProvider.autoDispose<TablesViewModel, TablesScreenState>(
      (ref) => TablesViewModel(ref),
    );
