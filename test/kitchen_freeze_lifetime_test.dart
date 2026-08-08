// A batch whose lines carry no `readyAt` stamp freezes its counter at the
// moment the board first saw it finished. That memory used to live in
// KitchenScreen's State, and `/kitchen` sits under a plain ShellRoute with no
// state retention — so switching tab and coming back re-froze the batch at the
// new now, and the card reported a few seconds for work that took ten minutes.
//
// CONTEXT.md §Batch says the frozen number is the batch's real time-to-pass.
// This test is what keeps that true across a tab switch.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/features/admin/kitchen/view_models/kitchen_orders.dart';

final _t0 = DateTime(2026, 7, 29, 12);

/// A finished line with no readyAt — the only shape that needs a fallback.
Ticket _doneLineWithoutStamp() => Ticket(
  id: 'x',
  itemId: 'i',
  name: 'Nasi Goreng',
  course: CourseId.mains,
  price: 25000,
  status: TicketStatus.cooked,
  tableId: 'T1',
  sentAt: '12:00',
  sentAtTime: _t0,
);

void main() {
  test('the freeze point survives the screen being disposed', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final byVisit = {
      'v1': [_doneLineWithoutStamp()],
    };

    // Hold the queue open the way a mounted KitchenScreen does. The queue
    // provider is autoDispose; the freeze map it reads must not be.
    final sub = container.listen(
      kitchenOrdersProvider,
      (_, _) {},
      fireImmediately: true,
    );
    final freeze = container.read(kitchenFallbackFreezeProvider);

    // First look: the batch is complete with no stamp, so it freezes at now.
    final first = buildKitchenOrders(
      byVisit,
      showCompleted: true,
      now: _t0.add(const Duration(minutes: 10)),
      fallbackFreeze: freeze,
      venueTargetMins: 15,
      prepByItem: const {},
    );
    expect(first.single.age, const Duration(minutes: 10));

    // The cook switches tab: the screen unmounts, its listeners go, and
    // Riverpod runs a real disposal pass. kitchenOrdersProvider is autoDispose
    // and goes with it. The freeze map must not.
    sub.close();
    await container.pump();

    final freezeAfterTabSwitch = container.read(kitchenFallbackFreezeProvider);
    expect(
      identical(freeze, freezeAfterTabSwitch),
      isTrue,
      reason: 'the freeze map was disposed with the screen',
    );

    // Back on the board five minutes later. The batch did no more work, so its
    // counter must still read the ten minutes it actually took.
    final second = buildKitchenOrders(
      byVisit,
      showCompleted: true,
      now: _t0.add(const Duration(minutes: 15)),
      fallbackFreeze: freezeAfterTabSwitch,
      venueTargetMins: 15,
      prepByItem: const {},
    );
    expect(
      second.single.age,
      const Duration(minutes: 10),
      reason:
          'the batch re-froze at the new now — the card is now claiming a '
          'time-to-pass the kitchen never took',
    );
  });
}
