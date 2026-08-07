// The KDS queue's grouping pass, now a plain function rather than a body of
// the screen's build (ADR-0081).
//
// The property that made lifting it out of a 1s setState safe is the one
// asserted here: which batches exist, which lines they hold and what order
// they sit in are functions of the tickets alone. Only the ages resolved inside
// KitchenOrder depend on `now`. If that ever stops being true, the queue would
// need to recompute every second again and this test is what says so.
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/features/admin/kitchen/view_models/kitchen_orders.dart';

final _t0 = DateTime(2026, 7, 29, 12);

Ticket _line({
  required TicketStatus status,
  required String sentAt,
  Duration sent = Duration.zero,
  String itemId = 'i',
  String tableId = 'T1',
}) => Ticket(
  id: '$tableId$sentAt$itemId$status',
  itemId: itemId,
  name: 'Nasi Goreng',
  course: CourseId.mains,
  price: 25000,
  status: status,
  tableId: tableId,
  sentAt: sentAt,
  sentAtTime: _t0.add(sent),
);

void main() {
  // Two sends at one table, plus an older send at another — enough to exercise
  // grouping by (table, sentAt) and the oldest-fire-first sort across tables.
  final byVisit = {
    'v1': [
      _line(
        status: TicketStatus.sent,
        sentAt: '12:10',
        sent: const Duration(minutes: 10),
      ),
      _line(
        status: TicketStatus.prep,
        sentAt: '12:10',
        sent: const Duration(minutes: 10),
        itemId: 'i2',
      ),
      _line(
        status: TicketStatus.sent,
        sentAt: '12:20',
        sent: const Duration(minutes: 20),
      ),
    ],
    'v2': [_line(status: TicketStatus.sent, sentAt: '12:00', tableId: 'T2')],
  };

  List<String> keysAt(Duration nowOffset) => buildKitchenOrders(
    byVisit,
    showCompleted: false,
    now: _t0.add(nowOffset),
    fallbackFreeze: {},
    venueTargetMins: 15,
    prepByItem: const {},
  ).map((o) => '${o.tableId}|${o.sentAt}|${o.total}').toList();

  test('grouping and sort do not move with the clock', () {
    // A minute in and two hours in must produce the identical queue. Ages
    // differ; the shape does not.
    expect(keysAt(const Duration(minutes: 21)), [
      'T2|12:00|1',
      'T1|12:10|2',
      'T1|12:20|1',
    ]);
    expect(
      keysAt(const Duration(hours: 2)),
      keysAt(const Duration(minutes: 21)),
    );
  });

  test('a finished batch leaves the default view but not the filtered one', () {
    final done = {
      'v1': [_line(status: TicketStatus.ready, sentAt: '12:00')],
    };
    expect(
      buildKitchenOrders(
        done,
        showCompleted: false,
        now: _t0,
        fallbackFreeze: {},
        venueTargetMins: 15,
        prepByItem: const {},
      ),
      isEmpty,
    );
    expect(
      buildKitchenOrders(
        done,
        showCompleted: true,
        now: _t0,
        fallbackFreeze: {},
        venueTargetMins: 15,
        prepByItem: const {},
      ),
      hasLength(1),
    );
  });

  test('the freeze map is pruned to batches still in the queue', () {
    final freeze = <String, DateTime>{'T9|09:00': _t0};
    buildKitchenOrders(
      byVisit,
      showCompleted: false,
      now: _t0.add(const Duration(minutes: 21)),
      fallbackFreeze: freeze,
      venueTargetMins: 15,
      prepByItem: const {},
    );
    expect(
      freeze.containsKey('T9|09:00'),
      isFalse,
      reason:
          'a batch that left the queue must not keep its entry, or the map '
          'grows for the length of a service',
    );
  });
}
