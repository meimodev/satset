import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/data/repositories/visit_expense_repository.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/ui/features/_book/book_stubs.dart';

void main() {
  test('expense cap follows every sent item across order changes', () {
    final lines = StateProvider<List<Ticket>>((ref) => []);
    final container = ProviderContainer(
      overrides: [
        ticketsForVisitProvider(
          'visit',
        ).overrideWith((ref) => ref.watch(lines)),
      ],
    );
    addTearDown(container.dispose);
    final cap = visitExpenseLocalCapProvider('visit');

    expect(container.read(cap), (hasTickets: false, cap: 0));

    final first = BookStubs.ticket(name: 'First order', price: 12000, qty: 2);
    final second = BookStubs.ticket(
      name: 'Second order',
      price: 9000,
      status: TicketStatus.served,
    );
    final draft = BookStubs.ticket(
      name: 'Cart draft',
      price: 50000,
      status: TicketStatus.draft,
    );
    container.read(lines.notifier).state = [first, second, draft];
    expect(container.read(cap), (hasTickets: true, cap: 33000));

    final third = BookStubs.ticket(name: 'Third order', price: 7000);
    container.read(lines.notifier).state = [first, second, draft, third];
    expect(container.read(cap), (hasTickets: true, cap: 40000));

    container.read(lines.notifier).state = [
      first.copyWith(status: TicketStatus.voided),
      second,
      draft,
      third,
    ];
    expect(container.read(cap), (hasTickets: true, cap: 16000));
  });
}
