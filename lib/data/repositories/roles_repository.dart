import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/role.dart';

const _uuid = Uuid();

/// Surfaces bootstrap progress for the roles list.
final rolesStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

class RolesRepository extends StateNotifier<List<Role>> {
  RolesRepository({required this.ref}) : super(const <Role>[]) {
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;

  static const _palette = <int>[
    0xFFC08AFF,
    0xFF6DB5FF,
    0xFF4DD487,
    0xFFFF9233,
    0xFFFFC04D,
    0xFFFF5C5C,
  ];

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(rolesStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
      return;
    }
    ref.read(rolesStatusProvider.notifier).state = const AsyncValue.loading();
    try {
      await _refetch();
      ref.read(rolesStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
      _wireWs();
    } catch (e, st) {
      SatLog.repo('roles.bootstrap fail $e');
      ref.read(rolesStatusProvider.notifier).state = AsyncValue.error(e, st);
    }
  }

  Future<void> _refetch() async {
    final api = ref.read(apiClientProvider);
    final raw = await api.getJson('/roles') as List;
    state = [
      for (final e in raw) _fromJson((e as Map).cast<String, dynamic>()),
    ];
    SatLog.repo('roles.loaded n=${state.length}');
  }

  void _wireWs() {
    if (_wsSub != null) return;
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type != WsEventTypes.rolesUpdated) return;
      // Both upsert and delete arrive on the same event; refetch keeps the
      // capabilities set canonical without duplicating parse logic here.
      unawaited(_refetch());
    });
  }

  Role _fromJson(Map<String, dynamic> j) {
    final caps = <Capability>{
      for (final c in (j['capabilities'] as List? ?? const []))
        if (capabilityFromKey(c as String) != null)
          capabilityFromKey(c) as Capability,
    };
    return Role(
      id: j['id'] as String,
      name: j['name'] as String,
      colorHex: _parseColor(j['colorHex'] as String?),
      capabilities: caps,
    );
  }

  int _parseColor(String? s) {
    if (s == null || s.isEmpty) return 0xFFC08AFF;
    final hex = s.startsWith('#') ? s.substring(1) : s;
    final v = int.tryParse(hex, radix: 16);
    if (v == null) return 0xFFC08AFF;
    return hex.length == 6 ? (0xFF000000 | v) : v;
  }

  String _hexString(int v) =>
      '#${v.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  Role? byId(String? id) {
    if (id == null) return null;
    for (final r in state) {
      if (r.id == id) return r;
    }
    return null;
  }

  Role create(String name) {
    SatLog.repo('roles.create name=$name');
    final colorHex = _palette[state.length % _palette.length];
    final role = Role(id: _uuid.v4(), name: name, colorHex: colorHex);
    state = [...state, role];
    unawaited(_post(role));
    return role;
  }

  Future<void> _post(Role r) async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      await ref.read(apiClientProvider).postJson('/roles', _toBody(r));
    } catch (e) {
      SatLog.repo('roles.create fail $e');
      state = state.where((x) => x.id != r.id).toList();
    }
  }

  void rename(String id, String name) {
    SatLog.repo(
      'roles.rename id=${id.substring(0, id.length.clamp(0, 6))} → $name',
    );
    _mutate(id, (r) => r.copyWith(name: name));
    _patch(id, {'name': name});
  }

  void setColor(String id, int colorHex) {
    SatLog.repo('roles.setColor id=${id.substring(0, id.length.clamp(0, 6))}');
    _mutate(id, (r) => r.copyWith(colorHex: colorHex));
    _patch(id, {'colorHex': _hexString(colorHex)});
  }

  void setCapability(String roleId, Capability c, bool on) {
    SatLog.repo(
      'roles.setCap role=${roleId.substring(0, roleId.length.clamp(0, 6))} cap=${c.name} on=$on',
    );
    Role? snapshot;
    _mutate(roleId, (r) {
      snapshot = r;
      final next = {...r.capabilities};
      on ? next.add(c) : next.remove(c);
      return r.copyWith(capabilities: next);
    });
    final after = byId(roleId);
    if (after == null) return;
    _patch(roleId, {
      'capabilities': [for (final cap in after.capabilities) cap.name],
    }, onFail: snapshot == null ? null : (prev) => snapshot);
  }

  void delete(String id) {
    SatLog.repo('roles.delete id=${id.substring(0, id.length.clamp(0, 6))}');
    final prev = state;
    state = [
      for (final r in state)
        if (r.id != id) r,
    ];
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    unawaited(() async {
      try {
        await ref.read(apiClientProvider).deleteJson('/roles/$id');
      } catch (e) {
        SatLog.repo('roles.delete fail $e');
        state = prev;
      }
    }());
  }

  /// Count roles holding [c]. Used by last-admin guard.
  int capabilityHolders(Capability c) => state.where((r) => r.has(c)).length;

  // ---- helpers ----

  void _mutate(String id, Role Function(Role) f) {
    state = [for (final r in state) r.id == id ? f(r) : r];
  }

  Map<String, dynamic> _toBody(Role r) => {
    'id': r.id,
    'name': r.name,
    'colorHex': _hexString(r.colorHex),
    'capabilities': [for (final c in r.capabilities) c.name],
  };

  void _patch(
    String id,
    Map<String, dynamic> body, {
    Role? Function(Role)? onFail,
  }) {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    final prev = byId(id);
    unawaited(() async {
      try {
        await ref.read(apiClientProvider).patchJson('/roles/$id', body);
      } catch (e) {
        SatLog.repo('roles.patch fail $e');
        if (prev != null) {
          state = [
            for (final r in state) r.id == id ? (onFail?.call(r) ?? prev) : r,
          ];
        }
      }
    }());
  }
}

final rolesRepositoryProvider =
    StateNotifierProvider<RolesRepository, List<Role>>((ref) {
      ref.watch(apiConfigProvider);
      return RolesRepository(ref: ref);
    });
