import 'package:drift/drift.dart';

import 'db/database.dart';

/// Host-side state of the sample-data seed: whether a job is running, how far
/// it got, and whether the admin has answered the first-run prompt (ADR-0073).
///
/// Replaces the demo clock of ADR-0053. That clock existed to hold a **live**
/// snapshot at the age it was authored for; ADR-0073 drops the live half, so
/// there is nothing left to hold and every timestamp is passed explicitly into
/// the write path instead. `SatClock` survives as the seam, permanently at
/// offset zero on the host.
class SeedJob {
  SeedJob._();

  /// Mark a job as started. `complete` stays false until [markComplete], so an
  /// interrupted run leaves a venue whose only offer is to clear and retry.
  static Future<void> begin(AppDatabase db, {required int daysTotal}) async {
    await db
        .into(db.demoStates)
        .insertOnConflictUpdate(
          DemoStatesCompanion.insert(
            id: const Value('default'),
            complete: const Value(false),
            daysDone: const Value(0),
            daysTotal: Value(daysTotal),
            // A new attempt never inherits the last one's verdict; without
            // this a successful retry still renders the failed dialog.
            failed: const Value(false),
          ),
        );
  }

  static Future<void> progress(AppDatabase db, int daysDone) async {
    await (db.update(db.demoStates)..where((d) => d.id.equals('default')))
        .write(DemoStatesCompanion(daysDone: Value(daysDone)));
  }

  /// Finish the job. This is also where the prompt is recorded as answered:
  /// loading the data *is* an answer, and a job that never reached here left
  /// the question open (ADR-0073).
  static Future<void> markComplete(AppDatabase db) async {
    await (db.update(
      db.demoStates,
    )..where((d) => d.id.equals('default'))).write(
      const DemoStatesCompanion(
        complete: Value(true),
        promptAnswered: Value(true),
        failed: Value(false),
      ),
    );
  }

  /// The admin declined. The prompt never fires again; Admin → Settings stays
  /// as the deliberate way back in.
  static Future<void> markSkipped(AppDatabase db) async {
    await db
        .into(db.demoStates)
        .insertOnConflictUpdate(
          DemoStatesCompanion.insert(
            id: const Value('default'),
            promptAnswered: const Value(true),
          ),
        );
  }

  /// Reset the job — the venue no longer holds sample data.
  ///
  /// An **update**, not a delete: `promptAnswered` is the venue's answer to a
  /// question it has already been asked, and dropping the row silently
  /// un-answers it, so clearing from Admin → Sistem re-arms the first-run
  /// prompt on a venue whose admin already decided. The job fields go back to
  /// zero, which is what makes [isIncomplete] false again.
  ///
  /// Writes the row if none exists, so a clear on a never-prompted venue is
  /// still a no-op rather than a crash — `promptAnswered` then falls to its
  /// column default of false, which is the honest answer there.
  static Future<void> clear(AppDatabase db) async {
    await db
        .into(db.demoStates)
        .insertOnConflictUpdate(
          DemoStatesCompanion.insert(
            id: const Value('default'),
            complete: const Value(false),
            daysDone: const Value(0),
            daysTotal: const Value(0),
            failed: const Value(false),
          ),
        );
  }

  static Future<DemoState?> _row(AppDatabase db) => (db.select(
    db.demoStates,
  )..where((d) => d.id.equals('default'))).getSingleOrNull();

  /// Whether a seed job started and never finished.
  ///
  /// `daysTotal > 0` is what says a job actually *began*: [markSkipped] writes
  /// the same row to record the answer, and `complete` falls to its column
  /// default of false there — without this the prompt read every skip as an
  /// interrupted job and fired again forever.
  static Future<bool> isIncomplete(AppDatabase db) async {
    final row = await _row(db);
    return row != null && row.daysTotal > 0 && !row.complete;
  }

  /// Whether the admin has already answered the first-run prompt.
  static Future<bool> promptAnswered(AppDatabase db) async {
    final row = await _row(db);
    return row?.promptAnswered ?? false;
  }

  /// The job threw. Persisted because the live `seed.progress` broadcast is
  /// otherwise the only carrier, and a relaunched app would read a crashed
  /// job as merely interrupted — same recovery, wrong sentence.
  static Future<void> markFailed(AppDatabase db) async {
    await (db.update(db.demoStates)..where((d) => d.id.equals('default')))
        .write(const DemoStatesCompanion(failed: Value(true)));
  }

  /// Whether the last job ended in an error rather than an interruption.
  static Future<bool> hasFailed(AppDatabase db) async {
    final row = await _row(db);
    return row?.failed ?? false;
  }

  /// Progress of the running job, for `/seed/state`.
  static Future<(int done, int total)> progressOf(AppDatabase db) async {
    final row = await _row(db);
    if (row == null || row.complete) return (0, 0);
    return (row.daysDone, row.daysTotal);
  }
}
