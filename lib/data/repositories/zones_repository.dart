import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';
import 'package:satset/domain/models/zone.dart';

const _uuid = Uuid();

/// Surfaces bootstrap progress for the zones list. Symmetric with
/// `tablesStatusProvider` so the UI can render the same banners.
final zonesStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

class ZonesRepository extends StateNotifier<List<Zone>> {
  ZonesRepository({required this.ref}) : super(const <Zone>[]) {
    // Defer to a microtask: Riverpod forbids mutating other providers
    // (zonesStatusProvider) during this notifier's own initialization.
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;
  bool _resyncing = false;

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  void _wireWs() {
    if (_wsSub != null) return;
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      switch (ev.type) {
        case WsEventTypes.connected:
          // Full-resync on every socket (re)connect. Incremental zone events
          // are lossy — a zone created while we were down (or before our
          // bootstrap GET succeeded) would never otherwise appear. ADR-0021.
          unawaited(_resync());
        case WsEventTypes.zoneCreated:
          final z = _fromJson(ev.payload);
          if (state.any((x) => x.id == z.id)) return;
          state = [...state, z];
        case WsEventTypes.zoneUpdated:
          final z = _fromJson(ev.payload);
          state = [
            for (final x in state)
              if (x.id == z.id) z else x,
          ];
        case WsEventTypes.zoneDeleted:
          final id = ev.payload['id'] as String?;
          if (id == null) return;
          state = [
            for (final x in state)
              if (x.id != id) x,
          ];
      }
    });
  }

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(zonesStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
      return;
    }
    state = const <Zone>[];
    ref.read(zonesStatusProvider.notifier).state = const AsyncValue.loading();
    try {
      await _refetch();
      ref.read(zonesStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
    } catch (e, st) {
      SatLog.repo('zones.bootstrap fail $e');
      ref.read(zonesStatusProvider.notifier).state = AsyncValue.error(e, st);
    }
    // Wire WS even if the bootstrap GET failed: the `connected` resync is the
    // recovery path for an empty/401 bootstrap. See ADR-0021.
    _wireWs();
  }

  /// Pull the authoritative zone list and replace state. Shared by the initial
  /// [_bootstrap] and the WS-reconnect [_resync].
  Future<void> _refetch() async {
    final api = ref.read(apiClientProvider);
    final raw = await api.getJson('/zones') as List;
    state = [
      for (final e in raw) _fromJson((e as Map).cast<String, dynamic>()),
    ];
    SatLog.repo('zones.loaded n=${state.length}');
  }

  /// Full-resync on socket (re)connect. Guarded against overlap; never throws
  /// (a transient failure waits for the next connect). See ADR-0021.
  Future<void> _resync() async {
    if (_resyncing) return;
    _resyncing = true;
    try {
      await _refetch();
      SatLog.repo('zones.resync ok');
    } catch (e) {
      SatLog.repo('zones.resync fail $e');
    } finally {
      _resyncing = false;
    }
  }

  Zone _fromJson(Map<String, dynamic> j) {
    return Zone(
      id: j['id'] as String,
      name: j['name'] as String,
      short: (j['short'] as String?) ?? '',
      colorHex: _parseColor(j['colorHex'] as String?),
      iconKey: (j['iconKey'] as String?) ?? 'tableRestaurant',
    );
  }

  /// Server stores colors as `#AARRGGBB`. Fall back to the model's default
  /// when the value is missing or malformed instead of crashing the boot.
  int _parseColor(String? s) {
    if (s == null || s.isEmpty) return 0xFFFF9233;
    final hex = s.startsWith('#') ? s.substring(1) : s;
    final v = int.tryParse(hex, radix: 16);
    if (v == null) return 0xFFFF9233;
    return hex.length == 6 ? (0xFF000000 | v) : v;
  }

  String? add(String name, {int? colorHex, String? iconKey}) {
    SatLog.repo('zones.add name=$name');
    final n = name.trim();
    if (n.isEmpty) return null;
    final short = _shortFor(n);
    final id = _uuid.v4();
    final z = Zone(
      id: id,
      name: n,
      short: short,
      colorHex: colorHex ?? ZonePresets.colorHexes.first,
      iconKey: iconKey ?? ZonePresets.iconKeys.first,
    );
    state = [...state, z];
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return id;
    unawaited(() async {
      try {
        await ref.read(apiClientProvider).postJson('/zones', {
          'id': id,
          'name': n,
          'short': short,
          'colorHex': _hexString(z.colorHex),
          'iconKey': z.iconKey,
        });
      } catch (e) {
        SatLog.repo('zones.add fail $e');
        state = state.where((x) => x.id != id).toList();
      }
    }());
    return id;
  }

  /// Color int → `#AARRGGBB` for the server.
  String _hexString(int v) =>
      '#${v.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  void rename(String id, String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    state = [
      for (final z in state)
        if (z.id == id) z.copyWith(name: n, short: _shortFor(n)) else z,
    ];
  }

  void update(String id, {String? name, int? colorHex, String? iconKey}) {
    final trimmed = name?.trim();
    final hasName = trimmed != null && trimmed.isNotEmpty;
    final prev = state.where((z) => z.id == id).cast<Zone?>().firstOrNull;
    state = [
      for (final z in state)
        if (z.id == id)
          z.copyWith(
            name: hasName ? trimmed : z.name,
            short: hasName ? _shortFor(trimmed) : z.short,
            colorHex: colorHex ?? z.colorHex,
            iconKey: iconKey ?? z.iconKey,
          )
        else
          z,
    ];
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    unawaited(() async {
      try {
        final body = <String, dynamic>{
          if (hasName) 'name': trimmed,
          if (hasName) 'short': _shortFor(trimmed),
          'colorHex': ?(colorHex == null ? null : _hexString(colorHex)),
          'iconKey': ?iconKey,
        };
        await ref.read(apiClientProvider).patchJson('/zones/$id', body);
      } catch (e) {
        SatLog.repo('zones.update fail $e');
        if (prev != null) {
          state = [
            for (final z in state)
              if (z.id == id) prev else z,
          ];
        }
      }
    }());
  }

  void remove(String id) {
    SatLog.repo('zones.remove id=${id.substring(0, id.length.clamp(0, 6))}');
    final prev = state;
    state = state.where((z) => z.id != id).toList();
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    unawaited(() async {
      try {
        await ref.read(apiClientProvider).deleteJson('/zones/$id');
      } catch (e) {
        SatLog.repo('zones.remove fail $e');
        state = prev;
      }
    }());
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

final zonesProvider = StateNotifierProvider<ZonesRepository, List<Zone>>((ref) {
  ref.watch(apiConfigProvider);
  return ZonesRepository(ref: ref);
});
