// The `demo_states` row is one row read four ways, and three of the readings
// were wrong (ADR-0073 addendum):
//
//   - a **skip** writes the same row `begin` does, so `complete` falls to its
//     column default of false — `isIncomplete` must key off a job having
//     actually started, or the first-run prompt fires forever on a venue that
//     declined it;
//   - a **clear** must not drop the row, because `promptAnswered` is the
//     venue's answer to a question it has already been asked;
//   - a **failed** job is not merely an interrupted one, and the verdict has
//     to outlive the process that formed it.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/seed_job.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('a skip is answered and not incomplete', () async {
    await SeedJob.markSkipped(db);
    expect(await SeedJob.promptAnswered(db), isTrue);
    expect(await SeedJob.isIncomplete(db), isFalse);
  });

  test('a started job that never finished is incomplete', () async {
    await SeedJob.begin(db, daysTotal: 30);
    expect(await SeedJob.isIncomplete(db), isTrue);
    await SeedJob.markComplete(db);
    expect(await SeedJob.isIncomplete(db), isFalse);
    expect(await SeedJob.promptAnswered(db), isTrue);
  });

  test('a clear keeps the answer and drops the job', () async {
    await SeedJob.begin(db, daysTotal: 30);
    await SeedJob.markComplete(db);
    await SeedJob.clear(db);
    // The venue said "load" once; clearing the data does not un-ask it.
    expect(await SeedJob.promptAnswered(db), isTrue);
    expect(await SeedJob.isIncomplete(db), isFalse);
    expect(await SeedJob.progressOf(db), (0, 0));
  });

  test('a clear on a never-prompted venue leaves it unanswered', () async {
    await SeedJob.clear(db);
    expect(await SeedJob.promptAnswered(db), isFalse);
    expect(await SeedJob.isIncomplete(db), isFalse);
  });

  test('a failed verdict persists and every fresh attempt clears it', () async {
    await SeedJob.begin(db, daysTotal: 30);
    expect(await SeedJob.hasFailed(db), isFalse);
    await SeedJob.markFailed(db);
    expect(await SeedJob.hasFailed(db), isTrue);
    // Still incomplete: a crash and an interruption recover the same way.
    expect(await SeedJob.isIncomplete(db), isTrue);

    // A retry must not render the last attempt's verdict.
    await SeedJob.begin(db, daysTotal: 30);
    expect(await SeedJob.hasFailed(db), isFalse);

    await SeedJob.markFailed(db);
    await SeedJob.clear(db);
    expect(await SeedJob.hasFailed(db), isFalse);
  });
}
