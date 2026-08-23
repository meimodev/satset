@Tags(['bench'])
library;

import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/server/db/database.dart';

/// Throwaway measurement, not an assertion about wall-clock time.
///
/// The seed's own test runs against an in-memory database, where a write costs
/// no fsync and batching is invisible. A device runs a file. This pins the gap
/// between the two write patterns on the storage the seed actually uses, so
/// "one transaction per seeded day" is a number rather than a belief.
///
/// Tagged `bench` and skipped by default: it is timing, and timing on CI is
/// noise. Run it with `flutter test --tags bench --run-skipped`.
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('satset-bench'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<AppDatabase> open(String name) async =>
      AppDatabase(NativeDatabase(File('${dir.path}/$name.sqlite')));

  /// Rows shaped like a seeded day: a table row per bill, nothing clever.
  Future<void> write(AppDatabase db, {required bool batched}) async {
    final rng = Random(7);
    Future<void> day(int d) async {
      for (var i = 0; i < 40; i++) {
        await db
            .into(db.venueTables)
            .insert(
              VenueTablesCompanion.insert(
                id: 'bench-$d-$i-${rng.nextInt(1 << 30)}',
                zoneId: 'z',
                label: Value('$i'),
              ),
            );
      }
    }

    for (var d = 0; d < 10; d++) {
      if (batched) {
        await db.transaction(() => day(d));
      } else {
        await day(d);
      }
    }
  }

  test('per-day transactions beat a fsync per insert on a real file', () async {
    final loose = await open('loose');
    final sw1 = Stopwatch()..start();
    await write(loose, batched: false);
    sw1.stop();
    await loose.close();

    final batched = await open('batched');
    final sw2 = Stopwatch()..start();
    await write(batched, batched: true);
    sw2.stop();
    await batched.close();

    // ignore: avoid_print
    print(
      'unbatched ${sw1.elapsedMilliseconds}ms  '
      'batched ${sw2.elapsedMilliseconds}ms',
    );
    expect(sw2.elapsed, lessThan(sw1.elapsed));
  });
}
