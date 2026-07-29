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
}) => Ticket(
  id: 's$sent$status',
  itemId: 'i',
  name: 'Nasi Goreng',
  course: CourseId.mains,
  price: 25000,
  status: status,
  sentAt: '12:00',
  sentAtTime: _t0.add(sent),
  firedAtTime: fired == null ? null : _t0.add(fired),
  readyAtTime: ready == null ? null : _t0.add(ready),
);

KitchenOrder _order(List<Ticket> tickets, Duration nowOffset, {DateTime? fb}) =>
    KitchenOrder.resolve(
      tableId: 'T1',
      sentAt: '12:00',
      tickets: tickets,
      now: _t0.add(nowOffset),
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
    // 14m is past the 10m threshold, but a finished batch is not work.
    expect(o.late, isFalse);
    expect(o.warn, isFalse);
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
