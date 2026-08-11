import 'dart:convert';

// `isNull`/`isNotNull` exist in both drift and matcher; we want the matcher.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/domain/models/audit_entry.dart' show AuditType;
import 'package:satset/domain/models/audit_kind.dart';
import 'package:satset/data/models/auth_dto.dart';
import 'package:satset/server/audit_log.dart';
import 'package:satset/server/auth.dart';
import 'package:satset/server/routes/auth_routes.dart';
import 'package:satset/server/db/database.dart';
import 'package:satset/server/routes/reports_routes.dart';
import 'package:satset/server/shift.dart';

/// A shift *is* the signed-in session (ADR-0097), and it is recorded rather
/// than derived. Two things are worth pinning: that a sign-in never resumes —
/// the gap between two shifts is the thing the hours report exists to show —
/// and that a forgotten sign-out is retired at the business-day boundary
/// without its fabricated length reaching the hours total.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    for (final (id, name) in [('maya', 'Maya'), ('adi', 'Adi')]) {
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              name: name,
              initials: name.substring(0, 2).toUpperCase(),
              roleId: 'role-waiter',
              pinHash: 'x',
            ),
          );
    }
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

  Future<List<Shift>> rowsOf(String userId) =>
      (db.select(db.shifts)
            ..where((s) => s.userId.equals(userId))
            ..orderBy([(s) => OrderingTerm.asc(s.startedAt)]))
          .get();

  // Every test that shifts the clock must put it back; the offset is global.
  tearDown(() => SatClock.adopt(Duration.zero));

  test('a fresh sign-in opens a shift', () async {
    expect(await openShiftOf(db, 'maya'), isNull);
    final started = await openShift(db, 'maya');
    expect(await openShiftOf(db, 'maya'), started);
    expect(await rowsOf('maya'), hasLength(1));
  });

  test('signing back in opens a second shift, it does not resume', () async {
    final first = await openShift(db, 'maya');
    await endShift(db, 'maya');
    // Stamps are second-precision, so move the clock on to tell a genuinely
    // new shift apart from a resumed one.
    SatClock.adopt(const Duration(seconds: 90));
    final second = await openShift(db, 'maya');

    expect(second, isNot(first));
    final rows = await rowsOf('maya');
    expect(rows, hasLength(2), reason: 'the gap between them is the point');
    expect(rows.first.endedBy, ShiftEnd.manual.name);
    expect(rows.last.endedAt, isNull);
  });

  test('signing out stamps the row manual, and closing again is a no-op', () async {
    await openShift(db, 'maya');
    SatClock.adopt(const Duration(minutes: 45));
    await endShift(db, 'maya');
    await endShift(db, 'maya');

    final rows = await rowsOf('maya');
    expect(rows, hasLength(1));
    expect(rows.single.endedBy, ShiftEnd.manual.name);
    expect(rows.single.endedAt!.difference(rows.single.startedAt).inMinutes, 45);
  });

  test(
    'a shift left open overnight is retired at its own rollover, not at now',
    () async {
      await setRolloverHour(4);
      final start = DateTime(2026, 7, 29, 18);
      await openShift(db, 'maya', at: start);
      // A void at 22:10 — the last thing they actually did.
      await writeAudit(
        db,
        type: AuditType.voidItem,
        kind: AuditKind.voidItem,
        actorUserId: 'maya',
        at: DateTime(2026, 7, 29, 22, 10),
      );
      // Read on the 31st: two days late, and the row still ends on the 30th.
      SatClock.adopt(DateTime(2026, 7, 31, 9).difference(DateTime.now()));

      expect(
        await openShiftOf(db, 'maya'),
        isNull,
        reason: "yesterday's row must not hand today a 39-hour clock",
      );
      final row = (await rowsOf('maya')).single;
      expect(row.endedBy, ShiftEnd.rollover.name);
      expect(row.endedAt, DateTime(2026, 7, 30, 4));
      expect(
        row.lastActivityAt,
        DateTime(2026, 7, 29, 22, 10),
        reason: 'the owner needs roughly when they really stopped',
      );
    },
  );

  test('before the rollover hour, last night\'s shift is still running', () async {
    await setRolloverHour(4);
    // Opened 23:00, read at 02:00 — same business day, so a waiter working
    // past midnight keeps one continuous shift.
    final start = DateTime(2026, 7, 29, 23);
    await openShift(db, 'maya', at: start);
    SatClock.adopt(DateTime(2026, 7, 30, 2).difference(DateTime.now()));

    expect(await openShiftOf(db, 'maya'), start);
  });

  test('a rollover shift contributes no hours, only a flag', () async {
    await setRolloverHour(4);
    // Maya: two clean shifts on the 29th, 3h and 2h.
    await openShift(db, 'maya', at: DateTime(2026, 7, 29, 11));
    await endShift(db, 'maya', at: DateTime(2026, 7, 29, 14));
    await openShift(db, 'maya', at: DateTime(2026, 7, 29, 17));
    await endShift(db, 'maya', at: DateTime(2026, 7, 29, 19));
    // Adi: one shift on the 29th he never signed out of.
    await openShift(db, 'adi', at: DateTime(2026, 7, 29, 11));
    SatClock.adopt(DateTime(2026, 7, 31, 9).difference(DateTime.now()));
    // Retire it the way a later sign-in does.
    await openShiftOf(db, 'adi');

    final section = await shiftReportSection(
      db,
      from: DateTime(2026, 7, 29, 4),
      to: DateTime(2026, 7, 30, 4),
    );
    final byId = {
      for (final r in section['staff'] as List) (r as Map)['id']: r,
    };

    expect(byId['maya']!['minutes'], 5 * 60);
    expect(byId['maya']!['shifts'], 2);
    expect(byId['maya']!['days'], 1, reason: 'two shifts, one day');
    expect(byId['maya']!['unclosed'], 0);
    // 11:00 on an 04:00 venue = 420 minutes past the rollover.
    expect(byId['maya']!['medianFirstIn'], 420);

    expect(
      byId['adi']!['minutes'],
      0,
      reason: 'a boundary-imposed length is not a measurement',
    );
    expect(byId['adi']!['unclosed'], 1);
    expect(section['unclosed'], 1);
    expect(section['dayStartHour'], 4);
  });

  test('an open shift not yet past its rollover is left out of hours', () async {
    await setRolloverHour(4);
    await openShift(db, 'maya', at: DateTime(2026, 7, 29, 11));
    SatClock.adopt(DateTime(2026, 7, 29, 15).difference(DateTime.now()));

    final section = await shiftReportSection(
      db,
      from: DateTime(2026, 7, 29, 4),
      to: DateTime(2026, 7, 30, 4),
    );
    final row = (section['staff'] as List).single as Map;
    expect(row['shifts'], 1);
    expect(
      row['minutes'],
      0,
      reason: 'counting to now would move the report while it is read',
    );
    expect(row['unclosed'], 0, reason: 'still on shift is not a missed sign-out');
  });

  test('a database stamped 52 without the table repairs itself at 53', () async {
    // Exactly what a device that ran the intermediate build presents: the
    // current-ish version, and no `shifts` in it. Left unrepaired, every read
    // of the table 500s forever, because no version arm is left to run.
    await db.customStatement('DROP TABLE shifts');
    await db.migration.onUpgrade(db.createMigrator(), 52, 53);

    expect(await rowsOf('maya'), isEmpty);
    await openShift(db, 'maya');
    expect(await rowsOf('maya'), hasLength(1));
  });

  test('upgrading from 51 carries an open shiftStartedAt into a row', () async {
    // Rewind to the v51 shape: the stamp on `users`, no `shifts` table.
    await db.customStatement('DROP TABLE shifts');
    await db.customStatement('ALTER TABLE users ADD COLUMN shift_started_at INTEGER');
    final started = DateTime(2026, 7, 29, 18);
    await db.customStatement(
      'UPDATE users SET shift_started_at = ? WHERE id = ?',
      [started.millisecondsSinceEpoch ~/ 1000, 'maya'],
    );
    await db.migration.onUpgrade(db.createMigrator(), 51, 53);

    final row = (await rowsOf('maya')).single;
    expect(row.startedAt, started, reason: 'mid-shift at upgrade keeps its clock');
    expect(row.endedAt, isNull);
    expect(await rowsOf('adi'), isEmpty, reason: 'a null stamp is not a shift');
    // The stamp is gone, so there is only one place a shift clock lives.
    final cols = await db.customSelect("PRAGMA table_info('users')").get();
    expect(
      cols.map((r) => r.read<String>('name')),
      isNot(contains('shift_started_at')),
    );
  });

  test('"hari ini" read at 00:40 is the day that is still running', () async {
    // Found on a tablet at 00:40: the snapshot anchored "today" on the calendar
    // date, so the window opened at 04:00 — three hours in the *future*. The
    // shift that had just started showed nowhere, and so did the evening's
    // sales, which sat in "Kemarin".
    await setRolloverHour(4);
    SatClock.adopt(DateTime(2026, 8, 11, 0, 40).difference(DateTime.now()));
    await openShift(db, 'maya', at: DateTime(2026, 8, 11, 0, 40));

    final res = await reportsRoutes(db).call(
      Request('GET', Uri.parse('http://x/reports/snapshot?range=today')),
    );
    final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
    final staff = (body['jamKerja'] as Map)['staff'] as List;

    expect(staff, hasLength(1), reason: 'the open shift is inside the window');
    expect((staff.single as Map)['id'], 'maya');
  });

  test('the in-process admin sign-in opens a shift too', () async {
    // The host signs in with email + password and never touches
    // `POST /auth/login`, so for a while their session opened no row — the one
    // person the owner cannot check up on being the owner. Worse, the app bar
    // counted up anyway off a local fallback stamp, so nothing looked wrong.
    final auth = ServerAuth(db, secret: 'test-secret');
    await auth.mintSession(userId: 'maya', deviceId: 'dev-1');

    expect(await openShiftOf(db, 'maya'), isNotNull);
    expect(await rowsOf('maya'), hasLength(1));
  });

  test('a retired shift reads as no shift, not as a legacy host', () async {
    // The bug this pins: `/auth/me` returning null was indistinguishable from
    // a host too old to have the field, so the client fell back to its own
    // `loginAt` and the app bar counted up all day against a row closed at
    // 04:00. `shiftTracked` is what makes the null an answer.
    await setRolloverHour(4);
    final auth = ServerAuth(db, secret: 'test-secret');
    final s = await auth.mintSession(userId: 'maya', deviceId: 'dev-1');

    Future<Map<String, dynamic>> me() async => jsonDecode(
      await (await authRoutes(auth).call(
        Request(
          'GET',
          Uri.parse('http://x/auth/me'),
          headers: {'authorization': 'Bearer ${s.token}'},
        ),
      )).readAsString(),
    ) as Map<String, dynamic>;

    final live = await me();
    expect(live['shiftTracked'], isTrue);
    expect(live['shiftStartedAt'], isNotNull);

    // Past the shift's own rollover: `/auth/me` retires it and reports null.
    SatClock.adopt(const Duration(days: 1));
    final after = await me();
    expect(after['shiftStartedAt'], isNull);
    expect(
      after['shiftTracked'],
      isTrue,
      reason: 'null must still read as an answer, or the client invents one',
    );
    expect((await rowsOf('maya')).single.endedBy, ShiftEnd.rollover.name);
  });

  test('a host that omits the flag leaves the client its fallback', () {
    // The fallback still has a job: a client on a newer build talking to a
    // server that predates the field must not lose its shift clock.
    expect(
      MeDto.fromJson({
        'userId': 'maya',
        'name': 'Maya',
        'initials': 'MA',
        'roleId': 'role-waiter',
        'zoneAssigned': null,
        'capabilities': <String>[],
      }).shiftTracked,
      isFalse,
    );
  });

  test('businessDayStart anchors to the previous day before the rollover', () {
    expect(businessDayStart(DateTime(2026, 7, 30, 2), 4), DateTime(2026, 7, 29, 4));
    expect(businessDayStart(DateTime(2026, 7, 30, 10), 4), DateTime(2026, 7, 30, 4));
  });

  test('the audit window spans a whole business day, not one shift', () async {
    await setRolloverHour(4);
    // Two shifts either side of a break, an auditable act in each.
    await openShift(db, 'maya', at: DateTime(2026, 7, 29, 11));
    await writeAudit(
      db,
      type: AuditType.voidItem,
      kind: AuditKind.voidItem,
      actorUserId: 'maya',
      at: DateTime(2026, 7, 29, 12),
    );
    await endShift(db, 'maya', at: DateTime(2026, 7, 29, 14));
    await openShift(db, 'maya', at: DateTime(2026, 7, 29, 17));
    await writeAudit(
      db,
      type: AuditType.voidItem,
      kind: AuditKind.voidItem,
      actorUserId: 'maya',
      at: DateTime(2026, 7, 29, 18),
    );

    // The window GET /audit uses, read mid-second-shift.
    final since = businessDayStart(DateTime(2026, 7, 29, 19), 4);
    final visible = await (db.select(db.auditEntries)
          ..where(
            (a) => a.actorUserId.equals('maya') & a.at.isBiggerOrEqualValue(since),
          ))
        .get();

    expect(
      visible,
      hasLength(2),
      reason: 'signing out for a break must not empty the Saya tab',
    );
  });
}
