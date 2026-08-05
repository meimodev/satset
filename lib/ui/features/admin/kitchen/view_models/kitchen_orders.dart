import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/data/repositories/menu_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/repositories/venue_settings_repository.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/core/state/tickers.dart';
import 'package:satset/ui/features/admin/kitchen/kitchen_order.dart';

// `ready` stays in the active set so a just-cooked item (now servable)
// remains struck-through on the card instead of vanishing one-by-one. A
// fully-ready order still clears the default view via the `done == total`
// guard in [buildKitchenOrders].
const _kitchenInProgress = {
  TicketStatus.sent,
  TicketStatus.prep,
  TicketStatus.cooked,
  TicketStatus.ready,
};

// Served items only show under the "show completed" filter — once handed to
// the table they're done with the kitchen.
const _kitchenCompleted = {TicketStatus.ready, TicketStatus.served};

/// Whether the board shows finished batches. Screen-level filter state, lifted
/// out of the widget so [kitchenOrdersProvider] can depend on it.
final kitchenShowCompletedProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// When a complete batch carrying no `readyAt` stamps was first seen finished.
///
/// Deliberately **not** autoDispose. `/kitchen` sits under a plain `ShellRoute`
/// with no state retention, so this map used to die every time a cook switched
/// tab: a stamp-less batch re-froze at the new `now` and its card then claimed
/// a time-to-pass of a few seconds for work that took ten minutes. CONTEXT.md
/// §Batch says the frozen number is the batch's *real* time-to-pass, so the
/// reset was a wrong number on the pass, not merely a lost cache.
///
/// Growth is bounded by [buildKitchenOrders], which prunes every entry whose
/// batch has left the queue on each pass.
final kitchenFallbackFreezeProvider = Provider<Map<String, DateTime>>(
  (ref) => <String, DateTime>{},
);

/// The KDS queue: live tickets grouped into batches, oldest fire first.
///
/// Recomputes when its inputs change — tickets, the venue target, per-item
/// `Waktu siap`, the filter — and once a minute, because [KitchenOrder]
/// resolves `age`, `late` and `warn` against the clock at build time and those
/// are whole-minute comparisons.
///
/// It used to run inside the screen's `build` behind a 1s `setState`, which
/// re-grouped every live ticket and rebuilt the whole per-item prep map sixty
/// times a minute so that one station timer could advance a digit. The station
/// timers now tick on their own in the leaf that renders them (ADR-0081).
final kitchenOrdersProvider = Provider.autoDispose<List<KitchenOrder>>((ref) {
  final fallbackFreeze = ref.watch(kitchenFallbackFreezeProvider);

  ref.watch(minuteTickerProvider);
  return buildKitchenOrders(
    ref.watch(ticketsProvider),
    showCompleted: ref.watch(kitchenShowCompletedProvider),
    now: SatClock.now(),
    fallbackFreeze: fallbackFreeze,
    venueTargetMins: ref.watch(
      venueSettingsProvider.select((s) => s.prepTargetMins),
    ),
    prepByItem: ref.watch(prepTimeByItemProvider),
  );
});

/// [fallbackFreeze] is the board's memory of when a stamp-less complete batch
/// was first seen finished — read here, and written back for any batch that
/// needs one. Entries for batches that have left the queue are pruned so the
/// map cannot grow over a service.
///
/// Nothing here depends on [now] except the ages resolved inside
/// [KitchenOrder.resolve]: the grouping, the visibility filter and the sort are
/// all functions of the tickets alone.
List<KitchenOrder> buildKitchenOrders(
  Map<String, List<Ticket>> byTable, {
  required bool showCompleted,
  required DateTime now,
  required Map<String, DateTime> fallbackFreeze,
  required int venueTargetMins,
  required Map<String, int?> prepByItem,
}) {
  final visible = showCompleted
      ? {..._kitchenInProgress, ..._kitchenCompleted}
      : _kitchenInProgress;
  final out = <KitchenOrder>[];
  final seen = <String>{};
  byTable.forEach((tableId, list) {
    final groups = <String, List<Ticket>>{};
    for (final t in list) {
      if (!visible.contains(t.status)) continue;
      groups.putIfAbsent(t.sentAt, () => []).add(t);
    }
    groups.forEach((sentAt, tickets) {
      // Unfinished items rise to the top so the cook always sees what's left.
      tickets.sort((a, b) {
        final ac = kitchenLineDone(a.status) ? 1 : 0;
        final bc = kitchenLineDone(b.status) ? 1 : 0;
        return ac.compareTo(bc);
      });
      // `byTable` is keyed by visitId (ADR-0034); use the ticket's real
      // tableId so the card resolves a table name, not the raw visit id.
      // Falls back to the key for takeaway (no table).
      final resolvedId = tickets.first.tableId.isNotEmpty
          ? tickets.first.tableId
          : tableId;
      final key = '$resolvedId|$sentAt';
      var order = KitchenOrder.resolve(
        tableId: resolvedId,
        sentAt: sentAt,
        tickets: tickets,
        now: now,
        venueTargetMins: venueTargetMins,
        prepByItem: prepByItem,
        fallbackFreeze: fallbackFreeze[key],
      );
      if (order.needsFallbackFreeze && !fallbackFreeze.containsKey(key)) {
        fallbackFreeze[key] = now;
        order = KitchenOrder.resolve(
          tableId: resolvedId,
          sentAt: sentAt,
          tickets: tickets,
          now: now,
          venueTargetMins: venueTargetMins,
          prepByItem: prepByItem,
          fallbackFreeze: now,
        );
      }
      seen.add(key);
      if (!showCompleted && order.complete) return;
      out.add(order);
    });
  });
  fallbackFreeze.removeWhere((k, _) => !seen.contains(k));
  // Oldest fire first — most urgent at the top of the queue. Sorted on the
  // full timestamp, not the HH:mm grouping key: a service running past midnight
  // would otherwise sort 00:15 ahead of 23:50 and bury the oldest ticket.
  out.sort((a, b) => a.sentAtTime.compareTo(b.sentAtTime));
  return out;
}
