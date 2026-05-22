import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:satset/data/services/dummy_data_service.dart';
import 'package:satset/domain/models/zone.dart';

const _uuid = Uuid();

class ZonesRepository extends StateNotifier<List<Zone>> {
  ZonesRepository(DummyDataService seed) : super(seed.initialZones());

  String? add(String name, {Color? color, IconData? icon}) {
    final n = name.trim();
    if (n.isEmpty) return null;
    final short = _shortFor(n);
    final id = _uuid.v4();
    state = [
      ...state,
      Zone(
        id: id,
        name: n,
        short: short,
        color: color ?? ZonePresets.colors.first,
        icon: icon ?? ZonePresets.icons.first,
      ),
    ];
    return id;
  }

  void rename(String id, String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    state = [
      for (final z in state)
        if (z.id == id) z.copyWith(name: n, short: _shortFor(n)) else z,
    ];
  }

  void update(
    String id, {
    String? name,
    Color? color,
    IconData? icon,
  }) {
    state = [
      for (final z in state)
        if (z.id == id)
          z.copyWith(
            name: name?.trim().isNotEmpty == true ? name!.trim() : null,
            short: name?.trim().isNotEmpty == true ? _shortFor(name!) : null,
            color: color,
            icon: icon,
          )
        else
          z,
    ];
  }

  void remove(String id) {
    state = state.where((z) => z.id != id).toList();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = List.of(state);
    if (newIndex > oldIndex) newIndex -= 1;
    list.insert(newIndex, list.removeAt(oldIndex));
    state = list;
  }

  String _shortFor(String name) {
    final n = name.trim();
    return n.length <= 3 ? n : n.substring(0, 3);
  }
}

final zonesProvider = StateNotifierProvider<ZonesRepository, List<Zone>>(
    (ref) => ZonesRepository(ref.watch(dummyDataServiceProvider)));
