import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satset/core/log/sat_log.dart';
import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/ws_client.dart';

/// One line within a pending guest self-order batch.
class GuestOrderLine {
  const GuestOrderLine({
    required this.id,
    required this.name,
    required this.variantName,
    required this.qty,
    required this.note,
    required this.modifierLabels,
  });
  final String id;
  final String name;
  final String variantName;
  final int qty;
  final String note;
  final List<String> modifierLabels;
}

/// A pending guest self-order awaiting staff approval (ADR-0028), keyed by the
/// visit it hangs off. The unit a waiter Approves/Rejects from the queue.
class GuestOrderBatch {
  const GuestOrderBatch({
    required this.visitId,
    required this.tableId,
    required this.tableLabel,
    required this.submittedAt,
    required this.lines,
  });
  final String visitId;
  final String tableId;
  final String tableLabel;
  final DateTime submittedAt;
  final List<GuestOrderLine> lines;
}

/// Live feed of pending guest self-order batches for the staff review queue.
/// Bootstraps from `GET /guest-orders`, then refetches whenever a
/// `guestOrder.submitted` WS event fires (debounced by a simple reload).
class GuestOrdersRepository extends StateNotifier<List<GuestOrderBatch>> {
  GuestOrdersRepository({required this.ref}) : super(const []) {
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  StreamSubscription? _wsSub;

  Future<void> _bootstrap() async {
    if (ref.read(apiConfigProvider) == null) return;
    await refresh();
    _wsSub = ref.read(wsClientProvider).events.listen((ev) {
      if (ev.type == WsEventTypes.guestOrderSubmitted) {
        SatLog.repo('guestOrders.ws submitted — refetch');
        refresh();
      }
    });
  }

  Future<void> refresh() async {
    try {
      final api = ref.read(apiClientProvider);
      final raw = await api.getJson('/guest-orders') as Map;
      final batches = <GuestOrderBatch>[];
      for (final b in (raw['batches'] as List? ?? const [])) {
        final m = (b as Map).cast<String, dynamic>();
        batches.add(
          GuestOrderBatch(
            visitId: m['visitId'] as String? ?? '',
            tableId: m['tableId'] as String? ?? '',
            tableLabel: m['tableLabel'] as String? ?? '',
            submittedAt:
                DateTime.tryParse(m['submittedAt'] as String? ?? '') ??
                DateTime.now(),
            lines: [
              for (final l in (m['lines'] as List? ?? const []))
                _line((l as Map).cast<String, dynamic>()),
            ],
          ),
        );
      }
      state = batches;
      SatLog.repo('guestOrders.loaded batches=${batches.length}');
    } catch (e) {
      SatLog.repo('guestOrders.refresh fail $e');
    }
  }

  GuestOrderLine _line(Map<String, dynamic> m) {
    final mods = <String>[];
    for (final x in (m['modifiers'] as List? ?? const [])) {
      final lbl = (x as Map)['label'];
      if (lbl is String && lbl.trim().isNotEmpty) mods.add(lbl.trim());
    }
    return GuestOrderLine(
      id: m['id'] as String? ?? '',
      name: m['name'] as String? ?? '',
      variantName: m['variantName'] as String? ?? '',
      qty: (m['qty'] as num?)?.toInt() ?? 1,
      note: (m['note'] as String? ?? '').trim(),
      modifierLabels: mods,
    );
  }

  /// Approve a batch → fires its lines to the kitchen. Optimistically drops it
  /// from the queue; a failure refetches to restore truth.
  Future<bool> approve(String visitId) => _act(visitId, 'approve');

  /// Reject a batch → voids its lines.
  Future<bool> reject(String visitId) => _act(visitId, 'reject');

  Future<bool> _act(String visitId, String verb) async {
    final prev = state;
    state = [
      for (final b in state)
        if (b.visitId != visitId) b,
    ];
    try {
      await ref
          .read(apiClientProvider)
          .postJson('/guest-orders/$visitId/$verb', const {});
      return true;
    } catch (e) {
      SatLog.repo('guestOrders.$verb fail $e');
      state = prev;
      await refresh();
      return false;
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}

final guestOrdersProvider =
    StateNotifierProvider<GuestOrdersRepository, List<GuestOrderBatch>>(
      (ref) => GuestOrdersRepository(ref: ref),
    );
