import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/device_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';

final devicesStatusProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncValue.data(null),
);

class DevicesRepository extends StateNotifier<List<DeviceDto>> {
  DevicesRepository({required this.ref}) : super(const <DeviceDto>[]) {
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(devicesStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
      return;
    }
    ref.read(devicesStatusProvider.notifier).state = const AsyncValue.loading();
    await _refetch();
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      // device.paired carries a partial row + sessionActive is missing, so
      // refetch the full list rather than guessing. Same for revoke/expire.
      if (ev.type == WsEventTypes.devicePaired ||
          ev.type == WsEventTypes.deviceRevoked ||
          ev.type == WsEventTypes.sessionExpired) {
        unawaited(_refetch());
      }
    });
  }

  Future<void> _refetch() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final raw = await ref.read(apiClientProvider).getJson('/devices') as List;
      state = [
        for (final e in raw)
          DeviceDto.fromJson((e as Map).cast<String, dynamic>()),
      ];
      ref.read(devicesStatusProvider.notifier).state = const AsyncValue.data(
        null,
      );
    } catch (e, st) {
      SatLog.repo('devices.fetch fail $e');
      ref.read(devicesStatusProvider.notifier).state = AsyncValue.error(e, st);
    }
  }

  Future<void> revoke(String id) async {
    try {
      await ref
          .read(apiClientProvider)
          .postJson('/devices/$id/revoke', const <String, dynamic>{});
    } catch (e) {
      SatLog.repo('devices.revoke fail $e');
    }
  }

  Future<void> refresh() => _refetch();

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}

final devicesRepositoryProvider =
    StateNotifierProvider<DevicesRepository, List<DeviceDto>>(
      (ref) => DevicesRepository(ref: ref),
    );
