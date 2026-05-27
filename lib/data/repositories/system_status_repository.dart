import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/system_status_dto.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';

final systemStatusStatusProvider =
    StateProvider<AsyncValue<void>>((_) => const AsyncValue.data(null));

class SystemStatusRepository extends StateNotifier<SystemStatusDto?> {
  SystemStatusRepository({required this.ref}) : super(null) {
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(systemStatusStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    ref.read(systemStatusStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      final raw = await ref.read(apiClientProvider).getJson('/server/status');
      state = SystemStatusDto.fromJson((raw as Map).cast<String, dynamic>());
      SatLog.repo('system.loaded uptime=${state?.uptimeMs}ms');
      ref.read(systemStatusStatusProvider.notifier).state =
          const AsyncValue.data(null);
    } catch (e, st) {
      ref.read(systemStatusStatusProvider.notifier).state =
          AsyncValue.error(e, st);
    }
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type == WsEventTypes.systemStatus) {
        try {
          state = SystemStatusDto.fromJson(ev.payload);
        } catch (e) {
          SatLog.repo('system.ws bad-payload $e');
        }
      }
    });
  }

  /// One-shot manual refresh. Used after the restart confirmation flow so
  /// the UI shows the new startedAt immediately.
  Future<void> refresh() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) return;
    try {
      final raw = await ref.read(apiClientProvider).getJson('/server/status');
      state = SystemStatusDto.fromJson((raw as Map).cast<String, dynamic>());
    } catch (e) {
      SatLog.repo('system.refresh fail $e');
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}

final systemStatusProvider =
    StateNotifierProvider<SystemStatusRepository, SystemStatusDto?>(
        (ref) => SystemStatusRepository(ref: ref));
