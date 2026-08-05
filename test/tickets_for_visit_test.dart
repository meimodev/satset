// ticketsProvider holds every visit's lines in one map and replaces it
// wholesale on each ticket event. Widgets showing a single visit go through
// ticketsForVisitProvider so that a line sent at another table does not rebuild
// them — the map is new, but the untouched groups' List instances are not, and
// Riverpod's `!=` check stops there.
//
// The empty case is the one that is easy to get wrong: returning a fresh `[]`
// per read would defeat the whole thing for every table without live lines,
// which on a quiet floor is most of them. `const []` is canonicalised, so the
// identity holds.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/data/repositories/tickets_repository.dart';

void main() {
  test('an empty visit yields the identical list every read', () {
    // Unpaired container: apiConfigProvider is null, so TicketsRepository
    // bootstraps to an empty map without touching the network.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final a = container.read(ticketsForVisitProvider('v-none'));
    final b = container.read(ticketsForVisitProvider('v-none'));
    final c = container.read(ticketsForVisitProvider('v-other'));

    expect(a, isEmpty);
    expect(
      identical(a, b),
      isTrue,
      reason: 'a fresh [] per read would rebuild every card with no live lines',
    );
    expect(identical(a, c), isTrue);
  });
}
