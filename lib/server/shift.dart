/// A **shift** is one staff member's signed-in stretch of work, and every
/// sign-out ends it (ADR-0096, superseding ADR-0065).
///
/// The earlier design kept a shift running across sign-outs so a shared handset
/// could change hands without stopping anyone's clock. That made a shift the
/// honest unit of *presence* but an unreadable one: a waiter who disappeared for
/// three hours produced the same single row as one who did not. Making the
/// sign-out the boundary fragments a day into several rows, and those gaps are
/// the whole point of the hours report.
///
/// This file is **the** writer for `shifts`, the same one-writer rule
/// `writeAudit`, `cash.dart` and `members.dart` hold. It owns two invariants: a
/// user has at most one open row at a time, and a row's end is either an
/// explicit sign-out or the business-day rollover — never nothing.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/server/db/database.dart';

const _uuid = Uuid();

/// How a shift ended. **The names are persisted** in `shifts.ended_by` and ride
/// the report payload as keys (ADR-0085) — renaming one orphans every row
/// already written under the old spelling.
enum ShiftEnd {
  /// The staff member signed out.
  manual,

  /// Nobody signed out; the business-day boundary retired the shift.
  rollover,
}

ShiftEnd? shiftEndFromName(String? name) {
  for (final v in ShiftEnd.values) {
    if (v.name == name) return v;
  }
  return null;
}

/// Start of the business day containing [now], per the venue's configured
/// rollover hour — the same anchor reports bucket "today" on and takeaway
/// numbering resets on.
DateTime businessDayStart(DateTime now, int hour) {
  final bod = DateTime(now.year, now.month, now.day, hour);
  return now.isBefore(bod) ? bod.subtract(const Duration(days: 1)) : bod;
}

/// The rollover that closes a shift started at [startedAt] — the end of its own
/// business day, not today's. A shift opened on Tuesday and never signed out
/// ends at Wednesday's rollover even if nobody looks until Friday.
DateTime rolloverEndOf(DateTime startedAt, int hour) =>
    businessDayStart(startedAt, hour).add(const Duration(days: 1));

Future<int> _dayStartHour(AppDatabase db) async {
  final s = await (db.select(
    db.venueSettings,
  )..where((x) => x.id.equals('default'))).getSingleOrNull();
  return s?.businessDayStartHour ?? 4;
}

/// When [shift] actually ended, or null while it is genuinely still running.
///
/// The one rule, shared by the closer and the report, so a stale row that no
/// login has visited yet still reads as ended rather than as open forever.
DateTime? effectiveEnd(Shift shift, int dayStartHour, DateTime now) {
  if (shift.endedAt != null) return shift.endedAt;
  final rollover = rolloverEndOf(shift.startedAt, dayStartHour);
  return now.isBefore(rollover) ? null : rollover;
}

/// [userId]'s open shift row, if they have one — including a stale one that
/// nobody has retired yet.
Future<Shift?> _openRow(AppDatabase db, String userId) =>
    (db.select(db.shifts)
          ..where((s) => s.userId.equals(userId) & s.endedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
          ..limit(1))
        .getSingleOrNull();

/// [userId]'s open shift start, or null when they have none.
///
/// **Retires a forgotten shift as a side effect.** A row left open past its own
/// rollover is closed here, at that rollover, with [ShiftEnd.rollover] — this is
/// the only place that happens, and it runs on every `/auth/me`. Without it one
/// missed sign-out leaks a shift forever and hands the client a 14-hour clock.
Future<DateTime?> openShiftOf(AppDatabase db, String userId) async {
  final row = await _openRow(db, userId);
  if (row == null) return null;
  final hour = await _dayStartHour(db);
  final end = effectiveEnd(row, hour, SatClock.now());
  if (end == null) return row.startedAt;
  await _close(db, row, at: end, by: ShiftEnd.rollover);
  return null;
}

/// Open [userId]'s shift, returning its start. Called only on sign-in: a mere
/// profile read must never start a shift.
///
/// Always a new row — there is no resume. Signing back in after a sign-out is a
/// second shift, which is what makes the gap between them visible.
Future<DateTime> openShift(
  AppDatabase db,
  String userId, {
  DateTime? at,
  String? idPrefix,
}) async {
  // Any row still open belongs to a previous stretch — close it before opening
  // the next, or the at-most-one-open invariant breaks and every later read
  // picks an arbitrary winner.
  final stale = await _openRow(db, userId);
  if (stale != null) {
    final hour = await _dayStartHour(db);
    await _close(
      db,
      stale,
      at: effectiveEnd(stale, hour, at ?? SatClock.now()) ??
          rolloverEndOf(stale.startedAt, hour),
      by: ShiftEnd.rollover,
    );
  }
  // Truncate to whole seconds before writing: Drift persists DateTime at second
  // precision, so returning `now` unrounded would hand the caller a value that
  // never matches what a subsequent read gives back — the login response and
  // the next `/auth/me` would disagree by up to a second.
  final raw = at ?? SatClock.now();
  final now = DateTime.fromMillisecondsSinceEpoch(
    (raw.millisecondsSinceEpoch ~/ 1000) * 1000,
  );
  await db
      .into(db.shifts)
      .insert(
        ShiftsCompanion.insert(
          id: '${idPrefix ?? ''}${_uuid.v4()}',
          userId: userId,
          startedAt: now,
        ),
      );
  return now;
}

/// Close [userId]'s shift — every sign-out does this. A no-op when they have no
/// open row, which is what an already-expired session looks like.
Future<void> endShift(AppDatabase db, String userId, {DateTime? at}) async {
  final row = await _openRow(db, userId);
  if (row == null) return;
  await _close(db, row, at: at ?? SatClock.now(), by: ShiftEnd.manual);
}

/// Per-staff attendance over a range — the Jam kerja block in Laporan.
///
/// Reads shifts by **start**, not by overlap: a shift belongs to the day it
/// opened, which is the same reading `businessDayStart` gives everything else
/// and keeps a shift that crosses midnight out of two buckets at once.
///
/// **A rollover shift contributes no hours.** Nobody signed out, so its length
/// is an artefact of the boundary rather than a measurement; counting it would
/// report a forgotten sign-out as a sixteen-hour day. It is surfaced as its own
/// count instead, with the last thing that shift actually did, so the owner can
/// see both that it happened and roughly when the person really stopped.
Future<Map<String, dynamic>> shiftReportSection(
  AppDatabase db, {
  required DateTime from,
  required DateTime to,
}) async {
  final hour = await _dayStartHour(db);
  final now = SatClock.now();
  final rows =
      await (db.select(db.shifts)..where(
            (s) =>
                s.startedAt.isBiggerOrEqualValue(from) &
                s.startedAt.isSmallerThanValue(to),
          ))
          .get();
  final users = {for (final u in await db.select(db.users).get()) u.id: u};

  final minutesBy = <String, int>{};
  final shiftsBy = <String, int>{};
  final daysBy = <String, Set<DateTime>>{};
  final unclosedBy = <String, int>{};
  // Per person, per day, the earliest start — not every start. A shift opened
  // at 17:00 after a break is a return, not an arrival, and counting it as one
  // makes the waiter who hands their handset over look like the late one.
  final firstInBy = <String, Map<DateTime, int>>{};
  final lastSeenBy = <String, DateTime?>{};

  for (final row in rows) {
    final id = row.userId;
    shiftsBy[id] = (shiftsBy[id] ?? 0) + 1;
    final day = businessDayStart(row.startedAt, hour);
    (daysBy[id] ??= <DateTime>{}).add(day);
    // Minutes past the rollover, so a 05:30 start on a 04:00 venue reads as 90
    // rather than as 330 — the number the owner compares is "how long after the
    // day opened", not a wall clock that means different things per venue.
    final since = row.startedAt.difference(day).inMinutes;
    final firstIns = firstInBy[id] ??= <DateTime, int>{};
    final prev = firstIns[day];
    if (prev == null || since < prev) firstIns[day] = since;

    final unclosed =
        row.endedBy == ShiftEnd.rollover.name ||
        (row.endedAt == null && effectiveEnd(row, hour, now) != null);
    if (unclosed) {
      unclosedBy[id] = (unclosedBy[id] ?? 0) + 1;
      final seen = row.lastActivityAt;
      if (seen != null) {
        final prev = lastSeenBy[id];
        if (prev == null || seen.isAfter(prev)) lastSeenBy[id] = seen;
      }
      continue;
    }
    final end = row.endedAt;
    // An open row that has not reached its rollover is someone on shift right
    // now. Counting it to `now` would make the report move while it is read.
    if (end == null) continue;
    minutesBy[id] = (minutesBy[id] ?? 0) + end.difference(row.startedAt).inMinutes;
  }

  final staff = <Map<String, dynamic>>[];
  for (final id in {...shiftsBy.keys}) {
    final sorted = [...?firstInBy[id]?.values]..sort();
    staff.add({
      'id': id,
      'name': users[id]?.name ?? id,
      'minutes': minutesBy[id] ?? 0,
      'shifts': shiftsBy[id] ?? 0,
      'days': daysBy[id]?.length ?? 0,
      'unclosed': unclosedBy[id] ?? 0,
      // Median, not mean: one 03:00 stock delivery should not move a month of
      // punctual starts.
      'medianFirstIn': sorted.isEmpty ? null : sorted[sorted.length ~/ 2],
      'lastSeen': lastSeenBy[id]?.toIso8601String(),
    });
  }
  staff.sort((a, b) => (b['minutes'] as int).compareTo(a['minutes'] as int));
  return {
    'staff': staff,
    'dayStartHour': hour,
    'unclosed': unclosedBy.values.fold<int>(0, (a, b) => a + b),
  };
}

Future<void> _close(
  AppDatabase db,
  Shift row, {
  required DateTime at,
  required ShiftEnd by,
}) async {
  // Read activity at close time rather than tracking it live: stamping a column
  // on every authenticated request would be a write per call, to answer a
  // question only an unclosed shift ever asks.
  final t = db.auditEntries;
  final last =
      await (db.selectOnly(t)
            ..addColumns([t.at.max()])
            ..where(
              t.actorUserId.equals(row.userId) &
                  t.at.isBiggerOrEqualValue(row.startedAt) &
                  t.at.isSmallerOrEqualValue(at),
            ))
          .getSingleOrNull();
  await (db.update(db.shifts)..where((s) => s.id.equals(row.id))).write(
    ShiftsCompanion(
      endedAt: Value(at.isBefore(row.startedAt) ? row.startedAt : at),
      endedBy: Value(by.name),
      lastActivityAt: Value(last?.read(t.at.max())),
    ),
  );
}
