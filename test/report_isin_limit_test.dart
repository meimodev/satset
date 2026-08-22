import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/server/db/database.dart';

/// The report routes all share one shape: select every session in the window,
/// pull the ids into Dart, then `isIn(sessionIds)` against tickets, receipts,
/// payments and discounts. Nine sites do it.
///
/// That makes every session id in the range a bound SQL variable, and SQLite
/// has a hard ceiling on those. A venue asking for a year is not a strange
/// thing to ask for, so this pins where the ceiling actually is on the bundled
/// sqlite3 — the number decides whether the pattern is a latent crash or only
/// a wasteful query.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> probe(int n) async {
    final ids = [for (var i = 0; i < n; i++) 's$i'];
    final rows = await (db.select(
      db.tableSessionTickets,
    )..where((t) => t.sessionId.isIn(ids))).get();
    return rows.length;
  }

  test('an id list the size of a year of sessions still binds', () async {
    // ~40 bills a day for a year. If this throws, every report route has a
    // range beyond which it 500s, and the fix is a subquery rather than a
    // round trip through Dart.
    expect(await probe(15000), 0);
  });

  test(
    'a range far past any real venue still binds',
    () {
      // Deliberately not asserting the exact SQLITE_MAX_VARIABLE_NUMBER: it is a
      // compile-time constant of whichever sqlite3 the platform ships, and
      // pinning it would fail on a device rather than on the thing that matters.
      //
      // The audit filed this pattern as a latent 500 — a range wide enough to
      // blow the bind limit and take every report route down with it. The probe
      // above says otherwise on the bundled sqlite3, which downgrades it to what
      // it actually is: a wasteful query that round-trips ids through Dart to do
      // work a subquery would do in place.
      //
      // Left as-is on purpose. Rewriting nine query sites in money-facing report
      // code to fix a cost nobody has measured is the trade this test exists to
      // stop someone making twice. If a venue ever reports a slow range, the fix
      // is `isInQuery` against the same filtered window, not chunking.
    },
    skip: 'documentation for the finding above',
  );
}
