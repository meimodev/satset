import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/reservation.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/l10n/app_localizations.dart';

/// Everything the floor card reads that is *derived* rather than stored.
///
/// Nothing here is persisted, and deliberately so (ADR-0048): a reservation
/// hold, a table's lateness and a card's staleness are all functions of the
/// clock over data the repos already hold. Writing them down would mean a
/// server-side state machine that has to be kept true as the clock moves, and
/// a stale row is worse than a recomputed one.

/// Silent floor states from ADR-0044. Derived, never stored.
enum ServiceState {
  none,

  /// Seated, nothing sent yet, past `ungreetedMins`. The audible cue lives in
  /// `AlertSoundService`; the card carries the standing state so a one-shot cue
  /// that was missed is still visible.
  ungreeted,

  /// Everything ordered is served and nothing has moved for `idleTableMins` —
  /// probably wants dessert or the bill.
  idle,
}

ServiceState serviceStateFor(
  VenueTable table,
  List<Ticket> lines,
  VenueSettingsDto s,
  DateTime now,
) {
  if (table.status == TableStatus.available) return ServiceState.none;
  final openedAt = table.openedAt;
  if (openedAt == null) return ServiceState.none;

  final live = lines.where((t) => t.status != TicketStatus.voided).toList();
  if (live.isEmpty) {
    return now.difference(openedAt) >= Duration(minutes: s.ungreetedMins)
        ? ServiceState.ungreeted
        : ServiceState.none;
  }

  // Idle needs *everything* terminal, and a last-activity stamp to measure
  // from. A line still in the kitchen means the visit is plainly not idle.
  if (live.any((t) => t.status != TicketStatus.served)) {
    return ServiceState.none;
  }
  DateTime? lastServed;
  for (final t in live) {
    final at = t.servedAtTime;
    if (at == null) return ServiceState.none; // Can't date it — stay silent.
    if (lastServed == null || at.isAfter(lastServed)) lastServed = at;
  }
  if (lastServed == null) return ServiceState.none;
  return now.difference(lastServed) >= Duration(minutes: s.idleTableMins)
      ? ServiceState.idle
      : ServiceState.none;
}

/// How long a table may be held for an upcoming booking before the booking is
/// just "later today". Past this the card shows a `nextResv` footnote instead
/// of reading as reserved, so a 21:00 booking does not grey out a 18:00 walk-in.
// ponytail: one constant, not a venue setting — no evidence yet that anyone
// wants to tune it. Promote to `venue_settings` if a venue asks.
const Duration kReservationHoldWindow = Duration(minutes: 60);

enum StaleSeverity { warn, crit }

/// A table that has been stuck in one condition too long. At most one per card:
/// the worst one wins, so the banner always names the thing to do next.
class TableStale {
  final StaleSeverity severity;
  final String label;
  const TableStale(this.severity, this.label);
}

/// Start of the current business day — the floor's "today". Service that runs
/// past midnight belongs to the night it started, so a 00:30 booking is still
/// part of the 27th's service when the day starts at 04:00.
DateTime businessDayStart(DateTime now, int startHour) {
  final todayStart = DateTime(now.year, now.month, now.day, startHour);
  return now.isBefore(todayStart)
      ? todayStart.subtract(const Duration(days: 1))
      : todayStart;
}

/// The booking currently holding a table, if any. A table is *reserved* when it
/// is free, a pending booking names it, and that booking falls between the start
/// of today's service and [kReservationHoldWindow] from now.
///
/// The lower bound matters: a `pending` booking is only ever cleared by hand, so
/// without it one forgotten no-show from last week would hold a table forever.
/// A booking that has aged out of today stops holding the table and simply
/// stays in the book as unresolved.
Reservation? reservationHoldFor(
  VenueTable table,
  List<Reservation> reservations,
  DateTime now, {
  required DateTime dayStart,
}) {
  if (table.status != TableStatus.available) return null;
  final held =
      reservations
          .where(
            (r) =>
                r.tableId == table.id &&
                r.status == ReservationStatus.pending &&
                !r.expectedAt.isBefore(dayStart) &&
                r.expectedAt.isBefore(now.add(kReservationHoldWindow)),
          )
          .toList()
        ..sort((a, b) => a.expectedAt.compareTo(b.expectedAt));
  return held.firstOrNull;
}

/// The next booking on a table beyond the hold window — a footnote, not a state.
/// Shown on occupied tables too: "this one has to be turned by 20:30".
Reservation? nextReservationFor(
  VenueTable table,
  List<Reservation> reservations,
  DateTime now,
) {
  final upcoming =
      reservations
          .where(
            (r) =>
                r.tableId == table.id &&
                r.status == ReservationStatus.pending &&
                r.expectedAt.isAfter(now),
          )
          .toList()
        ..sort((a, b) => a.expectedAt.compareTo(b.expectedAt));
  final next = upcoming.firstOrNull;
  if (next == null) return null;
  // The holding booking is already the card's headline; don't repeat it.
  if (table.status == TableStatus.available &&
      next.expectedAt.isBefore(now.add(kReservationHoldWindow))) {
    return null;
  }
  return next;
}

/// The worst overrun on a table, or null. Ordered by severity, then by how
/// actionable it is — a guest waiting to be greeted outranks a table that has
/// merely sat a long time.
///
/// Every threshold comes from `venue_settings`; none are hardcoded here. The
/// two `crit` ready/ungreeted rules read a *second* window past the threshold
/// that already fired the audible cue — this banner is for cues that went
/// unanswered, so firing it at the same moment would say nothing new.
/// [l10n] is threaded in rather than read off a `BuildContext`: this is a pure
/// function in `view_models/`, and the banner it returns is already a finished
/// sentence by the time a widget sees it. ADR-0083.
TableStale? staleFor({
  required VenueTable table,
  required List<Ticket> lines,
  required Reservation? hold,
  required ServiceState service,
  required VenueSettingsDto s,
  required DateTime now,
  required AppL10n l10n,
}) {
  if (table.status == TableStatus.ready) {
    final readyAt = _earliestReadyAt(lines);
    if (readyAt != null) {
      final mins = now.difference(readyAt).inMinutes;
      if (mins > s.pickupTargetMins * 2) {
        return TableStale(StaleSeverity.crit, l10n.staleReadyUncollected(mins));
      }
    }
  }

  if (hold != null) {
    final lateBy = now.difference(hold.expectedAt).inMinutes;
    if (lateBy > s.reservationGraceMins) {
      return TableStale(StaleSeverity.crit, l10n.staleReservationLate(lateBy));
    }
  }

  final openedAt = table.openedAt;
  if (service == ServiceState.ungreeted && openedAt != null) {
    final mins = now.difference(openedAt).inMinutes;
    if (mins > s.ungreetedMins + s.ungreetedEscalateMins) {
      return TableStale(StaleSeverity.crit, l10n.staleUngreeted(mins));
    }
  }

  if (service == ServiceState.idle) {
    final lastServed = _latestServedAt(lines);
    if (lastServed != null) {
      final mins = now.difference(lastServed).inMinutes;
      if (mins > s.idleTableMins) {
        return TableStale(StaleSeverity.warn, l10n.staleIdle(mins));
      }
    }
  }

  if (table.status == TableStatus.occupied && openedAt != null) {
    final elapsed = now.difference(openedAt);
    if (elapsed > Duration(minutes: s.longStayMins)) {
      return TableStale(
        StaleSeverity.warn,
        l10n.staleLongStay(formatElapsed(l10n, elapsed)),
      );
    }
  }

  return null;
}

DateTime? _earliestReadyAt(List<Ticket> lines) {
  DateTime? out;
  for (final t in lines) {
    if (t.status != TicketStatus.ready) continue;
    final at = t.readyAtTime;
    if (at == null) continue;
    if (out == null || at.isBefore(out)) out = at;
  }
  return out;
}

DateTime? _latestServedAt(List<Ticket> lines) {
  DateTime? out;
  for (final t in lines) {
    final at = t.servedAtTime;
    if (at == null) continue;
    if (out == null || at.isAfter(out)) out = at;
  }
  return out;
}
