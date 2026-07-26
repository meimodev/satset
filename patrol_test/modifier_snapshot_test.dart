// Patrol end-to-end test: the KDS renders a single-select add-on label —
// the user-facing symptom of the regression where single-select add-ons
// showed blank on the kitchen screen. See
// docs/adr/0011-ticket-modifier-snapshot.md. The submit-path half (the cause)
// is covered by modifier_sheet_test.dart.
//
// One patrolTest per file by convention — multiple patrolTests in one file
// race the PatrolAppService request/execute handshake (500). Like the other
// patrol tests we don't boot the real `main()` (Server mode stands up the
// embedded shelf server, which collides with Patrol's on-device service — see
// app_boot_test.dart / menu_categories_test.dart). We mount the real
// KitchenScreen with provider overrides whose only fake is the network tail.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:satset/data/repositories/tables_repository.dart';
import 'package:satset/data/repositories/tickets_repository.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/ticket_modifier.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/core/design/theme.dart';
import 'package:satset/ui/core/design/sat_theme.dart';
import 'package:satset/ui/features/admin/kitchen_screen.dart';

/// Seeds [ticketsProvider] directly. apiConfig is null in the test scope, so
/// super's `_bootstrap` returns before clearing state — this seed survives.
class _FakeTicketsRepo extends TicketsRepository {
  _FakeTicketsRepo(Ref ref, Map<String, List<Ticket>> seed) : super(ref: ref) {
    state = seed;
  }
}

class _FakeTablesRepo extends TablesRepository {
  _FakeTablesRepo(Ref ref, List<VenueTable> seed) : super(ref: ref) {
    state = seed;
  }
}

Widget _kdsHarness() {
  final ticket = Ticket(
    id: 't1',
    itemId: 'i1',
    name: 'Nasi Goreng',
    course: CourseId.mains,
    qty: 1,
    modifiers: const [
      // The single-select add-on that used to vanish.
      TicketModifier(
          groupId: 'spice', optionId: 'hot', label: 'Pedas', priceDelta: 0),
    ],
    price: 25000,
    status: TicketStatus.sent,
    sentAt: '12:00',
    sentAtTime: DateTime.now(),
  );
  return ProviderScope(
    overrides: [
      ticketsProvider.overrideWith(
          (ref) => _FakeTicketsRepo(ref, {'tbl1': [ticket]})),
      tablesProvider.overrideWith((ref) => _FakeTablesRepo(
          ref, const [VenueTable(id: 'tbl1', zoneId: 'z1')])),
    ],
    child: MaterialApp(
      theme: satTheme(SatTheme.amberTerang),
      home: const Scaffold(body: KitchenScreen()),
    ),
  );
}

void main() {
  // Fixed pumps — pumpAndSettle can stall on google_fonts' first-launch fetch
  // (see app_boot_test.dart).
  Future<void> settle(PatrolIntegrationTester $) async {
    for (var i = 0; i < 5; i++) {
      await $.pump(const Duration(milliseconds: 400));
    }
  }

  patrolTest('KDS shows a single-select add-on label', ($) async {
    await $.pumpWidget(_kdsHarness());
    await settle($);

    expect($('Nasi Goreng'), findsOneWidget);
    // The add-on label renders — not blank.
    expect($('Pedas'), findsOneWidget);
  });
}
