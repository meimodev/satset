import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/settlement_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/services/api_client.dart';
import 'package:satset/data/services/send_queue_service.dart';
import 'package:satset/data/services/settlement_journal.dart';
import 'package:satset/data/services/settlement_sync.dart';
import 'package:satset/data/services/ws_client.dart';

/// Drains the **Antrean kirim** whenever the socket comes back.
///
/// Hangs off the same `connected` event the repositories resync on: by the time
/// it fires there is a live socket and a valid bearer, which are exactly the two
/// things a replay needs. Lives in its own file so the queue never has to know
/// what a ticket is — it delivers intents, and someone else decides what the
/// screen does about the answer. See ADR-0090.
///
/// Must be watched by a long-lived widget (the app shell); a provider nobody
/// holds is a provider that never subscribes.
final sendQueueDrainProvider = Provider<void>((ref) {
  // No host, no socket, nothing to drain. This is a `watch`, not a `read`, so
  // it re-runs the moment `apiConfigProvider` goes null — which is exactly what
  // an admin logout does while the shell is still mounted. `wsClientProvider`
  // throws rather than returning null there, and the throw surfaces as a red
  // frame in `AppShell.build` before the router redirects to `/pin`.
  if (ref.watch(apiConfigProvider) == null) return;
  final sub = ref.watch(wsClientProvider).events.listen((ev) async {
    if (ev.type != WsEventTypes.connected) return;
    await _drainOrders(ref);
    // Money **after** food, always (ADR-0123). A payment replayed ahead of the
    // order it pays for lands against a bill that does not yet hold the lines,
    // and the bill then reads short for no reason anybody can see. Only this
    // device's ordering is ours to fix — another handset's backlog lands when
    // it lands, which is what the staleness rule covers.
    await _drainSettlement(ref);
  });
  ref.onDispose(sub.cancel);
});

Future<void> _drainOrders(Ref ref) async {
  if (ref.read(sendQueueProvider).isEmpty) return;
  final report = await ref.read(sendQueueProvider.notifier).drain();
  if (report.isEmpty) return;
  // Re-pull rather than patch: one drain can have created lines across
  // several visits, and the authoritative list is a single GET away. The
  // repositories' own `connected` resync already ran — before these orders
  // existed — so without this the board would show the world as it was a
  // moment before the backlog landed.
  await ref.read(ticketsProvider.notifier).resyncNow();
  // The tables carry the other half of what a drain changed: a replayed seat
  // is a table fact, and a replayed order moves the tab.
  await ref.read(tablesProvider.notifier).resyncNow();
  ref.read(sendReportProvider.notifier).state = report;
}

/// Replay the [[Antrean setelmen]] (ADR-0123). Per visit, in capture order,
/// halting a visit on its first refusal; other visits keep draining.
Future<void> _drainSettlement(Ref ref) async {
  if (ref.read(settlementJournalProvider).pendingVisits.isEmpty) return;
  final report = await ref.read(settlementJournalProvider.notifier).drain();
  if (report.isEmpty) return;
  // Same reason the order drain re-pulls: the cashier list's own `connected`
  // resync ran before these payments existed.
  await ref.read(settlementProvider.notifier).refresh();
  if (report.failures.isNotEmpty) {
    ref.read(settlementReportProvider.notifier).state = report;
  }
}

/// The last drain that refused something. Read by the `/kasir` sheet, which
/// clears it when the cashier acknowledges (ADR-0123).
final settlementReportProvider = StateProvider<SettlementReport?>((_) => null);
