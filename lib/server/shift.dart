/// A **shift** is one staff member's stretch of work, and it deliberately
/// outlives the staff session that opened it (ADR-0065).
///
/// Plain "Keluar" drops the session and leaves `Users.shiftStartedAt` set, so
/// the next PIN sign-in *resumes* the same shift instead of restarting the
/// clock — that is what lets a waiter hand a shared handset over, or pick up a
/// different one, without losing their shift. Only two things end a shift: the
/// explicit "Akhiri shift & keluar", and the business-day boundary.
///
/// The server owns this rather than the client, because the whole point is that
/// it survives a device change, and device-local storage cannot.
library;

import 'package:drift/drift.dart' show Value;

import 'package:satset/core/time/sat_clock.dart';
import 'package:satset/server/db/database.dart';

/// Start of the business day containing [now], per the venue's configured
/// rollover hour — the same anchor reports bucket "today" on and takeaway
/// numbering resets on.
DateTime businessDayStart(DateTime now, int hour) {
  final bod = DateTime(now.year, now.month, now.day, hour);
  return now.isBefore(bod) ? bod.subtract(const Duration(days: 1)) : bod;
}

Future<DateTime> _dayStart(AppDatabase db) async {
  final s = await (db.select(
    db.venueSettings,
  )..where((x) => x.id.equals('default'))).getSingleOrNull();
  return businessDayStart(SatClock.now(), s?.businessDayStartHour ?? 4);
}

/// [userId]'s open shift start, or null when they have none.
///
/// **Read-only** — a stamp from before today's rollover reports as null but is
/// left in place. That guard is what stops a forgotten "Akhiri shift" from
/// leaking a shift forever: a token that survives overnight would otherwise
/// hand the client yesterday's start and a 14-hour elapsed clock.
Future<DateTime?> openShiftOf(AppDatabase db, String userId) async {
  final row = await (db.select(
    db.users,
  )..where((u) => u.id.equals(userId))).getSingleOrNull();
  final prev = row?.shiftStartedAt;
  if (prev == null) return null;
  return prev.isBefore(await _dayStart(db)) ? null : prev;
}

/// Open — or resume — [userId]'s shift, returning its start. Called only on
/// sign-in: a mere profile read must never start a shift.
Future<DateTime> resumeOrOpenShift(AppDatabase db, String userId) async {
  final existing = await openShiftOf(db, userId);
  if (existing != null) return existing;
  // Truncate to whole seconds before writing: Drift persists DateTime at second
  // precision, so returning `now` unrounded would hand the caller a value that
  // never matches what a subsequent read gives back — the login response and
  // the next `/auth/me` would disagree by up to a second.
  final raw = SatClock.now();
  final now = DateTime.fromMillisecondsSinceEpoch(
    (raw.millisecondsSinceEpoch ~/ 1000) * 1000,
  );
  await (db.update(db.users)..where((u) => u.id.equals(userId))).write(
    UsersCompanion(shiftStartedAt: Value(now)),
  );
  return now;
}

/// Close [userId]'s shift — the "Akhiri shift" half of sign-out. Afterwards
/// [resumeOrOpenShift] starts a fresh one and `GET /audit` reports no shift
/// activity.
Future<void> endShift(AppDatabase db, String userId) =>
    (db.update(db.users)..where((u) => u.id.equals(userId))).write(
      const UsersCompanion(shiftStartedAt: Value(null)),
    );
