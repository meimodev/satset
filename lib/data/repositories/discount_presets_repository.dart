import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/discount_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/prefs_service.dart';
import 'package:satset/data/services/ws_client.dart';

/// The [[Preset diskon]] catalogue, cached on every paired device so the
/// cashier's picker opens without a round-trip mid-transaction.
///
/// Its own repository rather than riding the venue-settings payload (ADR-0037),
/// so it gets the standard collection treatment: a dedicated endpoint, its own
/// WS event, and a full resync on socket reconnect (ADR-0021).
final discountPresetsStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

class DiscountPresetsRepository extends StateNotifier<List<DiscountPresetDto>> {
  DiscountPresetsRepository({required this.ref})
    : super(const <DiscountPresetDto>[]) {
    // Synchronously: the picker can open on the same frame this is created.
    _paintCache();
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;

  /// Paint the last catalogue this device heard, then fetch over it (ADR-0128).
  ///
  /// Without it the picker is empty on any cold boot away from the host — and
  /// the picker opens mid-transaction, where "the venue has no promos" and
  /// "this handset has not asked yet" look identical to a cashier.
  void _paintCache() {
    final raw = ref
        .read(prefsServiceProvider)
        .valueOrNull
        ?.discountPresetsJson();
    if (raw == null) return;
    try {
      _adopt(jsonDecode(raw), persist: false);
    } catch (e) {
      SatLog.repo('discountPresets cache decode fail $e');
    }
  }

  void _persist() {
    final prefs = ref.read(prefsServiceProvider).valueOrNull;
    if (prefs == null) return;
    unawaited(
      prefs.setDiscountPresetsJson(
        jsonEncode([for (final p in state) p.toJson()]),
        fingerprint: ref.read(apiConfigProvider)?.trustedFingerprint,
      ),
    );
  }

  Future<void> _bootstrap() async {
    // Again, for the cold launch where prefs was still resolving in the
    // constructor — `prefsServiceProvider` is a `FutureProvider`.
    if (state.isEmpty) _paintCache();
    await refresh();
    // The fetch is an await gap, and a container can be torn down inside it —
    // a shell that unmounts while the first read is in flight. Subscribing
    // through a disposed ref throws where nobody is listening.
    if (!mounted) return;
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      switch (ev.type) {
        // A preset was created, edited, or deleted — the payload is the whole
        // list, so no merge logic is needed.
        case WsEventTypes.discountPresetsUpdated:
          _adopt(ev.payload['presets']);
        // Socket came back: refetch rather than trusting the cache, so a
        // preset edited while this device was offline is not missed.
        case WsEventTypes.connected:
          refresh();
      }
    });
  }

  void _adopt(Object? raw, {bool persist = true}) {
    if (raw is! List) return;
    try {
      state = [
        for (final e in raw)
          DiscountPresetDto.fromJson((e as Map).cast<String, dynamic>()),
      ];
      if (persist) _persist();
    } catch (e) {
      SatLog.repo('discountPresets decode fail $e');
    }
  }

  void _upsert(DiscountPresetDto preset) {
    final next =
        [
          for (final p in state)
            if (p.id != preset.id) p,
          preset,
        ]..sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
        });
    state = next;
  }

  Future<void> refresh() async {
    if (ref.read(apiConfigProvider) == null) {
      ref.read(discountPresetsStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    ref.read(discountPresetsStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      final raw =
          await ref.read(apiClientProvider).getJson('/venue/discount-presets')
              as Map;
      _adopt(raw['presets']);
      ref.read(discountPresetsStatusProvider.notifier).state =
          const AsyncValue.data(null);
    } catch (e, st) {
      SatLog.repo('discountPresets.refresh fail $e');
      ref.read(discountPresetsStatusProvider.notifier).state = AsyncValue.error(
        e,
        st,
      );
    }
  }

  /// Presets a cashier may apply to [scope] right now — active only, since an
  /// inactive preset is a seasonal one the owner has parked.
  List<DiscountPresetDto> forScope(String scope) =>
      state.where((p) => p.active && p.scope == scope).toList();

  Future<DiscountPresetDto?> create({
    required String name,
    required String scope,
    required String kind,
    required int value,
    bool active = true,
    int sortOrder = 0,
  }) async {
    final raw = await ref
        .read(apiClientProvider)
        .postJson('/venue/discount-presets', {
          'name': name,
          'scope': scope,
          'kind': kind,
          'value': value,
          'active': active,
          'sortOrder': sortOrder,
        });
    if (raw is! Map) return null;
    final preset = DiscountPresetDto.fromJson(raw.cast<String, dynamic>());
    _upsert(preset);
    return preset;
  }

  Future<DiscountPresetDto?> update(
    String id, {
    String? name,
    String? scope,
    String? kind,
    int? value,
    bool? active,
    int? sortOrder,
  }) async {
    final raw = await ref
        .read(apiClientProvider)
        .patchJson('/venue/discount-presets/$id', {
          'name': ?name,
          'scope': ?scope,
          'kind': ?kind,
          'value': ?value,
          'active': ?active,
          'sortOrder': ?sortOrder,
        });
    if (raw is! Map) return null;
    final preset = DiscountPresetDto.fromJson(raw.cast<String, dynamic>());
    _upsert(preset);
    return preset;
  }

  Future<void> remove(String id) async {
    await ref.read(apiClientProvider).deleteJson('/venue/discount-presets/$id');
    state = state.where((p) => p.id != id).toList();
    _persist();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}

final discountPresetsRepositoryProvider =
    StateNotifierProvider<DiscountPresetsRepository, List<DiscountPresetDto>>(
      (ref) => DiscountPresetsRepository(ref: ref),
    );
