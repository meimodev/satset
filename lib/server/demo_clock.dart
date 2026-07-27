import 'package:drift/drift.dart';

import 'package:satset/core/log/sat_log.dart';
import 'package:satset/core/time/sat_clock.dart';

import 'db/database.dart';

/// Host-side owner of the [[Demo clock]] (ADR-0053).
///
/// The offset is **server-authoritative**: the host computes it once at boot
/// and every paired device adopts the same number, because elapsed time is
/// rendered on whichever device is showing it and a host-only clock leaves the
/// KDS and the waiter's phone disagreeing about how late a course is.
class DemoClock {
  DemoClock._();

  /// Re-anchor the process clock against whatever demo state the DB holds.
  ///
  /// Called at server boot and after any demo seed/reset. A venue with no
  /// demo data — or one whose seed was interrupted and never completed —
  /// runs on real time.
  static Future<Duration> reanchor(AppDatabase db) async {
    final row = await (db.select(
      db.demoStates,
    )..where((d) => d.id.equals('default'))).getSingleOrNull();
    if (row == null || !row.complete) {
      SatClock.clear();
      return Duration.zero;
    }
    SatClock.anchorTo(row.anchorAt);
    SatLog.srv(
      'demo clock anchored ${row.anchorAt.toIso8601String()} '
      'offset=${SatClock.offset.inMinutes}m',
    );
    return SatClock.offset;
  }

  /// The offset to hand a client, in seconds. Zero means "run on real time".
  static int offsetSeconds() => SatClock.offset.inSeconds;

  /// Record the anchor for a seed job that is starting. `complete` stays false
  /// until [markComplete], so an interrupted job leaves a venue that can only
  /// be reset (ADR-0053 §9).
  static Future<void> begin(
    AppDatabase db, {
    required DateTime anchor,
    required int daysTotal,
  }) async {
    await db
        .into(db.demoStates)
        .insertOnConflictUpdate(
          DemoStatesCompanion.insert(
            id: const Value('default'),
            anchorAt: anchor,
            complete: const Value(false),
            daysDone: const Value(0),
            daysTotal: Value(daysTotal),
          ),
        );
  }

  static Future<void> progress(AppDatabase db, int daysDone) async {
    await (db.update(db.demoStates)..where((d) => d.id.equals('default')))
        .write(DemoStatesCompanion(daysDone: Value(daysDone)));
  }

  /// Finish the job and pin the anchor to **now**, not to when the job
  /// started. The live snapshot is authored last, so anchoring to the start of
  /// a multi-minute run leaves every staged state that much older than it was
  /// written to be.
  static Future<void> markComplete(AppDatabase db) async {
    await (db.update(db.demoStates)..where((d) => d.id.equals('default')))
        .write(
          DemoStatesCompanion(
            complete: const Value(true),
            anchorAt: Value(DateTime.now()),
          ),
        );
    await reanchor(db);
  }

  /// Drop the demo clock entirely — the venue no longer holds demo data.
  static Future<void> clear(AppDatabase db) async {
    await db.delete(db.demoStates).go();
    SatClock.clear();
  }

  /// Whether a seed job started and never finished.
  static Future<bool> isIncomplete(AppDatabase db) async {
    final row = await (db.select(
      db.demoStates,
    )..where((d) => d.id.equals('default'))).getSingleOrNull();
    return row != null && !row.complete;
  }
}
