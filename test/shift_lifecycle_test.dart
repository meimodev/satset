// `isNull` exists in both drift and matcher; we want the matcher.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/shift.dart';

/// A shift outlives the staff session that opened it (ADR-0065), so the thing
/// worth pinning is *when it does not*: the business-day boundary, and an
/// explicit end. Get either wrong and a waiter either loses their shift on a
/// handset swap or inherits yesterday's 14-hour clock.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            id: 'maya',
            name: 'Maya',
            initials: 'MA',
            roleId: 'role-waiter',
            pinHash: 'x',
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> setRolloverHour(int h) => db
      .into(db.venueSettings)
      .insertOnConflictUpdate(
        VenueSettingsCompanion.insert(
          id: 'default',
          businessDayStartHour: Value(h),
        ),
      );

  Future<DateTime?> stampOf(String id) async {
    final row = await (db.select(
      db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
    return row?.shiftStartedAt;
  }

  // Every test that shifts the clock must put it back; the offset is global.
  tearDown(() => SatClock.adopt(Duration.zero));

  test('a fresh sign-in opens a shift', () async {
    expect(await openShiftOf(db, 'maya'), isNull);
    final started = await resumeOrOpenShift(db, 'maya');
    expect(await stampOf('maya'), started);
  });

  test('signing back in resumes the same shift, it does not restart it', () async {
    final first = await resumeOrOpenShift(db, 'maya');
    // Stand in for "signed out, handed the handset over, signed in again".
    final second = await resumeOrOpenShift(db, 'maya');
    expect(second, first, reason: 'a re-login inside the business day resumes');
  });

  test('ending a shift clears it, and the next sign-in starts a new one', () async {
    final first = await resumeOrOpenShift(db, 'maya');
    await endShift(db, 'maya');
    expect(await openShiftOf(db, 'maya'), isNull);
    expect(
      await stampOf('maya'),
      isNull,
      reason: 'GET /audit reads a cleared shift as "no activity"',
    );
    // Stamps are second-precision, so move the clock on to tell a genuinely
    // new shift apart from a resumed one.
    SatClock.adopt(const Duration(seconds: 90));
    final second = await resumeOrOpenShift(db, 'maya');
    expect(
      second,
      isNot(first),
      reason: 'after Akhiri shift, signing in starts a new shift',
    );
  });

  test('a shift left open overnight is retired by the business-day boundary', () async {
    await setRolloverHour(4);
    // Yesterday 18:00 — a forgotten "Akhiri shift" after evening service.
    final yesterdayEvening = DateTime.now().subtract(const Duration(days: 1));
    await (db.update(db.users)..where((u) => u.id.equals('maya'))).write(
      UsersCompanion(
        shiftStartedAt: Value(
          DateTime(
            yesterdayEvening.year,
            yesterdayEvening.month,
            yesterdayEvening.day,
            18,
          ),
        ),
      ),
    );
    // Read at 10:00 today, past the 04:00 rollover.
    final now = DateTime.now();
    SatClock.adopt(
      DateTime(
        now.year,
        now.month,
        now.day,
        10,
      ).difference(DateTime.now()),
    );

    expect(
      await openShiftOf(db, 'maya'),
      isNull,
      reason: 'yesterday\'s stamp must not hand today a 16-hour clock',
    );
    // ...and the next sign-in gets a genuinely new shift rather than resuming.
    final resumed = await resumeOrOpenShift(db, 'maya');
    expect(resumed.day, DateTime(now.year, now.month, now.day).day);
  });

  test('before the rollover hour, last night\'s shift is still running', () async {
    await setRolloverHour(4);
    // Opened 23:00 yesterday, read at 02:00 today — same business day, so a
    // waiter working past midnight keeps one continuous shift.
    final now = DateTime.now();
    final lastNight = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(hours: 1));
    await (db.update(db.users)..where((u) => u.id.equals('maya'))).write(
      UsersCompanion(shiftStartedAt: Value(lastNight)),
    );
    SatClock.adopt(
      DateTime(now.year, now.month, now.day, 2).difference(DateTime.now()),
    );

    expect(await openShiftOf(db, 'maya'), lastNight);
  });

  test('businessDayStart anchors to the previous day before the rollover', () {
    final beforeRollover = DateTime(2026, 7, 30, 2);
    expect(businessDayStart(beforeRollover, 4), DateTime(2026, 7, 29, 4));
    final afterRollover = DateTime(2026, 7, 30, 10);
    expect(businessDayStart(afterRollover, 4), DateTime(2026, 7, 30, 4));
  });
}
