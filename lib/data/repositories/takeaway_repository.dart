import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';

/// One active takeaway (Bawa pulang) visit, for the Floor strip + detail.
/// A live visit row with `kind == takeaway`; the lines themselves live in the
/// tickets repository keyed by [id]. See ADR-0026.
class TakeawayVisit {
  final String id;
  final String? tableLabel;
  final String? guestName;
  final String? guestNotes;
  final DateTime? openedAt;

  /// Handover ("Serahkan") timestamp — the first axis (≙ table-close). Non-null
  /// ⇒ already handed to the guest, bill may still be open on the cashier.
  final DateTime? handedOverAt;
  final DateTime? billClosedAt;

  const TakeawayVisit({
    required this.id,
    this.tableLabel,
    this.guestName,
    this.guestNotes,
    this.openedAt,
    this.handedOverAt,
    this.billClosedAt,
  });

  bool get handedOver => handedOverAt != null;
  bool get billClosed => billClosedAt != null;
  String get label =>
      (tableLabel != null && tableLabel!.trim().isNotEmpty)
          ? tableLabel!
          : 'Bawa pulang';

  factory TakeawayVisit.fromJson(Map<String, dynamic> j) => TakeawayVisit(
        id: j['id'] as String,
        tableLabel: j['tableLabel'] as String?,
        guestName: j['guestName'] as String?,
        guestNotes: j['guestNotes'] as String?,
        openedAt: DateTime.tryParse(j['openedAt'] as String? ?? ''),
        handedOverAt: DateTime.tryParse(j['tableFreedAt'] as String? ?? ''),
        billClosedAt: DateTime.tryParse(j['billClosedAt'] as String? ?? ''),
      );
}

final takeawayStatusProvider =
    StateProvider<AsyncValue<void>>((_) => const AsyncValue.data(null));

/// Live list of active takeaway visits. Cheap to re-fetch, so any ticket / bill
/// / session-close event triggers a refetch (membership changes when a takeaway
/// is created, handed over, or snapshotted). See ADR-0026 / ADR-0021.
class TakeawayRepository extends StateNotifier<List<TakeawayVisit>> {
  TakeawayRepository({required this.ref}) : super(const []) {
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;
  bool _refetching = false;

  Future<void> _bootstrap() async {
    final cfg = ref.read(apiConfigProvider);
    if (cfg == null) {
      ref.read(takeawayStatusProvider.notifier).state =
          const AsyncValue.data(null);
      return;
    }
    ref.read(takeawayStatusProvider.notifier).state =
        const AsyncValue.loading();
    try {
      await _refetch();
      ref.read(takeawayStatusProvider.notifier).state =
          const AsyncValue.data(null);
    } catch (e, st) {
      ref.read(takeawayStatusProvider.notifier).state =
          AsyncValue.error(e, st);
    }
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      switch (ev.type) {
        case WsEventTypes.connected:
        case WsEventTypes.billUpdated:
        case WsEventTypes.ticketCreated:
        case WsEventTypes.ticketUpdated:
        case WsEventTypes.tableSessionClosed:
          unawaited(_refetch());
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> refresh() => _refetch();

  Future<void> _refetch() async {
    if (_refetching) return;
    _refetching = true;
    try {
      final cfg = ref.read(apiConfigProvider);
      if (cfg == null) return;
      final raw = await ref
          .read(apiClientProvider)
          .getJson('/takeaway/visits') as List;
      state = [
        for (final e in raw)
          TakeawayVisit.fromJson((e as Map).cast<String, dynamic>())
      ];
      SatLog.repo('takeaway.visits n=${state.length}');
    } catch (e) {
      SatLog.repo('takeaway.visits fail $e');
      rethrow;
    } finally {
      _refetching = false;
    }
  }
}

final takeawayVisitsProvider =
    StateNotifierProvider<TakeawayRepository, List<TakeawayVisit>>((ref) {
  ref.watch(apiConfigProvider);
  return TakeawayRepository(ref: ref);
});
