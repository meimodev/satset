import 'package:flutter_test/flutter_test.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/features/admin/kitchen/kitchen_order.dart';

final _t0 = DateTime(2026, 7, 29, 12);

Ticket _line({
  required TicketStatus status,
  Duration sent = Duration.zero,
  Duration? fired,
  Duration? ready,
  String itemId = 'i',
}) => Ticket(
  id: 's$sent$status$itemId',
  itemId: itemId,
  name: 'Nasi Goreng',
  course: CourseId.mains,
  price: 25000,
  status: status,
  sentAt: '12:00',
  sentAtTime: _t0.add(sent),
  firedAtTime: fired == null ? null : _t0.add(fired),
  readyAtTime: ready == null ? null : _t0.add(ready),
);

KitchenOrder _order(
  List<Ticket> tickets,
  Duration nowOffset, {
  DateTime? fb,
  int venueTargetMins = 10,
  Map<String, int?> prepByItem = const {},
}) => KitchenOrder.resolve(
  tableId: 'T1',
  sentAt: '12:00',
  tickets: tickets,
  now: _t0.add(nowOffset),
  venueTargetMins: venueTargetMins,
  prepByItem: prepByItem,
  fallbackFreeze: fb,
);

void main() {
  test('complete batch freezes at its last ready stamp', () {
    final o = _order([
      _line(status: TicketStatus.ready, ready: const Duration(minutes: 6)),
      _line(status: TicketStatus.served, ready: const Duration(minutes: 14)),
    ], const Duration(minutes: 40));

    expect(o.complete, isTrue);
    expect(o.age, const Duration(minutes: 14));
    // 14m is past the 10m target, but a finished batch is not work.
    expect(o.late, isFalse);
    expect(o.warn, isFalse);
  });

  group('the target is the venue setting, resolved per line (ADR-0043)', () {
    test('a batch of inherit-only lines uses the venue default', () {
      final lines = [_line(status: TicketStatus.prep)];
      expect(_order(lines, const Duration(minutes: 12)).targetMins, 10);
      // Move the venue knob and the board moves with it — the whole point of
      // the setting, and what the old hardcoded 10 ignored.
      expect(
        _order(lines, const Duration(minutes: 12), venueTargetMins: 20).late,
        isFalse,
      );
    });

    test("a batch of fast items is late on its own clock, not the venue's", () {
      final o = _order(
        [_line(status: TicketStatus.prep, itemId: 'teh')],
        const Duration(minutes: 6),
        venueTargetMins: 15,
        prepByItem: const {'teh': 5},
      );

      expect(o.targetMins, 5);
      expect(o.late, isTrue, reason: 'a 6-minute-old 5-minute drink is late');
    });

    test('the slowest line paces the batch', () {
      final o = _order(
        [
          _line(status: TicketStatus.prep, itemId: 'teh'),
          _line(status: TicketStatus.prep, itemId: 'iga'),
        ],
        const Duration(minutes: 20),
        venueTargetMins: 15,
        prepByItem: const {'teh': 5, 'iga': 40},
      );

      expect(o.targetMins, 40);
      expect(
        o.late,
        isFalse,
        reason: 'the drink must not drag the grill order into red',
      );
    });

    test('an item with no override inherits inside a mixed batch', () {
      final o = _order(
        [
          _line(status: TicketStatus.prep, itemId: 'teh'),
          _line(status: TicketStatus.prep, itemId: 'nasi'),
        ],
        const Duration(minutes: 1),
        venueTargetMins: 15,
        prepByItem: const {'teh': 5, 'nasi': null},
      );

      expect(o.targetMins, 15);
    });

    test('warn is 0.7 of the batch target, not a second constant', () {
      final lines = [_line(status: TicketStatus.prep, itemId: 'iga')];
      const prep = {'iga': 40};

      expect(
        _order(
          lines,
          const Duration(minutes: 28),
          prepByItem: prep,
        ).warn,
        isTrue,
      );
      expect(
        _order(
          lines,
          const Duration(minutes: 27),
          prepByItem: prep,
        ).warn,
        isFalse,
      );
      // Late outranks warn — they never both read true.
      final red = _order(lines, const Duration(minutes: 41), prepByItem: prep);
      expect(red.late, isTrue);
      expect(red.warn, isFalse);
    });
  });

  test('incomplete batch runs live and can be late', () {
    final o = _order([
      _line(status: TicketStatus.ready, ready: const Duration(minutes: 3)),
      _line(status: TicketStatus.prep),
    ], const Duration(minutes: 12));

    expect(o.complete, isFalse);
    expect(o.age, const Duration(minutes: 12));
    expect(o.late, isTrue);
  });

  test('complete batch missing a stamp keeps ticking until one is supplied', () {
    final lines = [_line(status: TicketStatus.cooked)];

    final live = _order(lines, const Duration(minutes: 9));
    expect(live.needsFallbackFreeze, isTrue);
    expect(live.age, const Duration(minutes: 9));

    final frozen = _order(
      lines,
      const Duration(minutes: 30),
      fb: _t0.add(const Duration(minutes: 9)),
    );
    expect(frozen.age, const Duration(minutes: 9));
  });

  test('held course measures from its fire, not from the guest order', () {
    final o = _order([
      _line(
        status: TicketStatus.prep,
        fired: const Duration(minutes: 20),
      ),
    ], const Duration(minutes: 24));

    expect(o.clockStart, _t0.add(const Duration(minutes: 20)));
    expect(o.age, const Duration(minutes: 4));
    expect(o.late, isFalse, reason: 'a fired course is not born overdue');
  });
}
