// Four hot surfaces used to watch a whole collection or a whole `AuthState`
// to read one field out of it. The shell wraps every screen; a KDS card is one
// of thirty on a board nobody touches; the table detail screen is open for the
// length of a sitting. Watching whole meant a pax edit two rooms away rebuilt
// all of them.
//
// What is pinned here is the part that is easy to get wrong: a `.select` only
// narrows if what it returns has **value** equality. `VenueTable` and `Zone`
// have none — selecting the row would re-fire on every emission and narrow
// nothing, which is why these select a `String?`, a `bool` or a record.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/domain/models/venue_table.dart';

class _Tables extends StateNotifier<List<VenueTable>> {
  _Tables() : super(const []);
  void put(List<VenueTable> v) => state = v;
}

final _tablesProvider = StateNotifierProvider<_Tables, List<VenueTable>>(
  (ref) => _Tables(),
);

void main() {
  VenueTable t(String id, {String? label, int pax = 0}) =>
      VenueTable(id: id, zoneId: 'z1', label: label, pax: pax);

  testWidgets('a label select ignores every change that is not the label', (
    tester,
  ) async {
    var builds = 0;
    String? seen;

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (_, ref, _) {
            builds++;
            seen = ref.watch(
              _tablesProvider.select(
                (l) => l.where((x) => x.id == 't1').firstOrNull?.displayName,
              ),
            );
            return const SizedBox();
          },
        ),
      ),
    );

    final notifier = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    ).read(_tablesProvider.notifier);

    notifier.put([t('t1', label: 'T1'), t('t2', label: 'T2')]);
    await tester.pump();
    expect(seen, 'T1');
    final afterFirst = builds;

    // A different table changes. This is the emission the old code rebuilt on.
    notifier.put([t('t1', label: 'T1'), t('t2', label: 'T2', pax: 4)]);
    await tester.pump();
    expect(builds, afterFirst, reason: 'nothing this widget renders changed');

    // The same table changes something else.
    notifier.put([t('t1', label: 'T1', pax: 2), t('t2', label: 'T2', pax: 4)]);
    await tester.pump();
    expect(builds, afterFirst, reason: 'the card renders the label, not pax');

    // And the label itself. A narrowed watch that never fires is worse than a
    // wide one.
    notifier.put([t('t1', label: 'Meja 1'), t('t2', label: 'T2', pax: 4)]);
    await tester.pump();
    expect(seen, 'Meja 1');
    expect(builds, greaterThan(afterFirst));
  });

  testWidgets('selecting the row itself would not have narrowed anything', (
    tester,
  ) async {
    // The reason the selects above return a `String?`. `VenueTable` has no
    // `==`, so two rows carrying identical data are different values, and a
    // repository that rebuilds its list on every WS frame hands `.select` a
    // fresh object every time.
    expect(t('t1', label: 'T1') == t('t1', label: 'T1'), isFalse);

    var builds = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (_, ref, _) {
            builds++;
            ref.watch(
              _tablesProvider.select(
                (l) => l.where((x) => x.id == 't1').firstOrNull,
              ),
            );
            return const SizedBox();
          },
        ),
      ),
    );

    final notifier = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    ).read(_tablesProvider.notifier);
    notifier.put([t('t1', label: 'T1')]);
    await tester.pump();
    final before = builds;
    // Re-emitting the same data, as a full resync on reconnect does.
    notifier.put([t('t1', label: 'T1')]);
    await tester.pump();
    expect(
      builds,
      greaterThan(before),
      reason: 'identity equality: the select fires anyway',
    );
  });

  testWidgets('a record select narrows on the fields it names', (tester) async {
    // The shape the table detail screen uses for `(id, name, canTakeOrder)`:
    // records *do* have value equality, which is what makes selecting three
    // scalars at once legitimate.
    var builds = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (_, ref, _) {
            builds++;
            ref.watch(
              _tablesProvider.select(
                (l) => (count: l.length, first: l.firstOrNull?.displayName),
              ),
            );
            return const SizedBox();
          },
        ),
      ),
    );

    final notifier = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    ).read(_tablesProvider.notifier);
    notifier.put([t('t1', label: 'T1')]);
    await tester.pump();
    final before = builds;
    notifier.put([t('t1', label: 'T1', pax: 9)]);
    await tester.pump();
    expect(builds, before, reason: 'same count, same label, same record');
    notifier.put([t('t1', label: 'T1'), t('t2', label: 'T2')]);
    await tester.pump();
    expect(builds, greaterThan(before), reason: 'the count is in the record');
  });
}
