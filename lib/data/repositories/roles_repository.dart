import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/data/services/dummy_data_service.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/role.dart';
import 'package:uuid/uuid.dart';

class RolesRepository extends StateNotifier<List<Role>> {
  RolesRepository(DummyDataService seed) : super(seed.initialRoles());

  static const _palette = <int>[
    0xFFC08AFF,
    0xFF6DB5FF,
    0xFF4DD487,
    0xFFFF9233,
    0xFFFFC04D,
    0xFFFF5C5C,
  ];

  Role? byId(String? id) {
    if (id == null) return null;
    for (final r in state) {
      if (r.id == id) return r;
    }
    return null;
  }

  Role create(String name) {
    final colorHex = _palette[state.length % _palette.length];
    final role = Role(id: const Uuid().v4(), name: name, colorHex: colorHex);
    state = [...state, role];
    return role;
  }

  void rename(String id, String name) {
    state = [
      for (final r in state) r.id == id ? r.copyWith(name: name) : r,
    ];
  }

  void setColor(String id, int colorHex) {
    state = [
      for (final r in state)
        r.id == id ? r.copyWith(colorHex: colorHex) : r,
    ];
  }

  void setCapability(String roleId, Capability c, bool on) {
    state = [
      for (final r in state)
        if (r.id == roleId)
          r.copyWith(capabilities: {
            ...r.capabilities,
            if (on) c,
          }..removeWhere((x) => !on && x == c))
        else
          r,
    ];
  }

  void delete(String id) {
    state = [
      for (final r in state)
        if (r.id != id) r,
    ];
  }

  /// Count roles holding [c]. Used by last-admin guard.
  int capabilityHolders(Capability c) =>
      state.where((r) => r.has(c)).length;
}

final rolesRepositoryProvider =
    StateNotifierProvider<RolesRepository, List<Role>>(
        (ref) => RolesRepository(ref.watch(dummyDataServiceProvider)));
