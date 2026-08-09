/// Start of the current business day — the venue's "today". Service that runs
/// past midnight belongs to the night it started, so a 00:30 booking is still
/// part of the 27th's service when the day starts at 04:00.
///
/// Lives here rather than beside any one caller because three unrelated things
/// now bucket on this boundary: the floor's staleness signals, the [[Shift]]
/// that a forgotten sign-out must not leak past, and the expiry of a terputus
/// handset's send queue (ADR-0090). The server keeps its own copy in
/// `lib/server/shift.dart`; that one runs against the DB and does not cross
/// into client code.
DateTime businessDayStart(DateTime now, int startHour) {
  final todayStart = DateTime(now.year, now.month, now.day, startHour);
  return now.isBefore(todayStart)
      ? todayStart.subtract(const Duration(days: 1))
      : todayStart;
}
