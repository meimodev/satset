import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/use_cases/advance_ticket_status_use_case.dart';
import 'package:satset/domain/use_cases/fire_course_use_case.dart';

class TableDetailState {
  final VenueTable? table;
  final List<Ticket> tickets;
  final int readyCount;
  const TableDetailState({
    required this.table,
    required this.tickets,
    required this.readyCount,
  });
}

class TableDetailViewModel extends StateNotifier<TableDetailState> {
  TableDetailViewModel(this.ref, this.tableId)
      : super(const TableDetailState(table: null, tickets: [], readyCount: 0)) {
    _recompute();
    ref.listen(tablesProvider, (_, next) => _recompute(tables: next));
    ref.listen(ticketsProvider, (_, next) => _recompute(byTable: next));
  }

  final Ref ref;
  final String tableId;

  void _recompute({
    List<VenueTable>? tables,
    Map<String, List<Ticket>>? byTable,
  }) {
    final List<VenueTable> ts = tables ?? ref.read(tablesProvider);
    final Map<String, List<Ticket>> by = byTable ?? ref.read(ticketsProvider);
    final VenueTable? table = ts.where((t) => t.id == tableId).firstOrNull;
    // Groups are keyed by visitId (ADR-0034); resolve through the table's
    // current visit so a reseat never inherits the prior visit's lines.
    final String? vid = table?.currentVisitId;
    final List<Ticket> list = (vid != null && vid.isNotEmpty)
        ? (by[vid] ?? const <Ticket>[])
        : (by[tableId] ?? const <Ticket>[]);
    state = TableDetailState(
      table: table,
      tickets: list,
      readyCount: list.where((t) => t.status == TicketStatus.ready).length,
    );
  }

  Future<void> markServed(String ticketId) => ref
      .read(advanceTicketStatusUseCaseProvider)
      .call(tableId, ticketId, TicketStatus.served);

  Future<void> fire(CourseId course) =>
      ref.read(fireCourseUseCaseProvider).call(tableId, course);
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

final tableDetailViewModelProvider = StateNotifierProvider.autoDispose
    .family<TableDetailViewModel, TableDetailState, String>(
        (ref, id) => TableDetailViewModel(ref, id));
