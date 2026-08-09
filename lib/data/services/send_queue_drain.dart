import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/models/ws_event_dto.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/services/send_queue_service.dart';
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
  final sub = ref.watch(wsClientProvider).events.listen((ev) async {
    if (ev.type != WsEventTypes.connected) return;
    if (ref.read(sendQueueProvider).isEmpty) return;
    final report = await ref.read(sendQueueProvider.notifier).drain();
    if (report.isEmpty) return;
    // Re-pull rather than patch: one drain can have created lines across
    // several visits, and the authoritative list is a single GET away. The
    // repositories' own `connected` resync already ran — before these orders
    // existed — so without this the board would show the world as it was a
    // moment before the backlog landed.
    await ref.read(ticketsProvider.notifier).resyncNow();
    ref.read(sendReportProvider.notifier).state = report;
  });
  ref.onDispose(sub.cancel);
});
