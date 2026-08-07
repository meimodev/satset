import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:satset/l10n/app_localizations.dart';
import 'package:satset/data/models/venue_settings_dto.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/reservation.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/ui/features/tables/view_models/floor_signals.dart';

/// ADR-0048. The banner exists to name the *worst* overrun, so the two things
/// worth pinning are the thresholds (they must come from settings, never a
/// constant) and the precedence (crit before warn, and the most actionable
/// crit first).
void main() {
  final now = DateTime(2026, 7, 27, 19, 0);
  const s = VenueSettingsDto();
  final dayStart = businessDayStart(now, s.businessDayStartHour);
  // The banner's wording is the ARB's business; this file pins thresholds
  // and precedence, so it runs in the default locale. ADR-0083.
  final l10n = lookupAppL10n(const Locale('id'));

  VenueTable table({
    TableStatus status = TableStatus.occupied,
    DateTime? openedAt,
    String id = 'T1',
  }) => VenueTable(
    id: id,
    zoneId: 'terrace',
    status: status,
    openedAt: openedAt,
    currentVisitId: 'v1',
  );

  Ticket line({
    required TicketStatus status,
    DateTime? readyAt,
    DateTime? servedAt,
    DateTime? sentAt,
  }) => Ticket(
    id: 't1',
    itemId: 'i1',
    name: 'Nasi Goreng',
    course: CourseId.mains,
    price: 45000,
    status: status,
    sentAt: '18:00',
    sentAtTime: sentAt ?? now.subtract(const Duration(minutes: 30)),
    readyAtTime: readyAt,
    servedAtTime: servedAt,
  );

  Reservation booking(DateTime at, {String table = 'T1'}) => Reservation(
    id: 'r1',
    name: 'Budi',
    partySize: 2,
    expectedAt: at,
    status: ReservationStatus.pending,
    tableId: table,
    createdAt: at,
  );

  group('staleFor', () {
    test('a quiet occupied table is not stale', () {
      final out = staleFor(
        table: table(openedAt: now.subtract(const Duration(minutes: 20))),
        lines: [line(status: TicketStatus.sent)],
        hold: null,
        service: ServiceState.none,
        s: s,
        now: now,
        l10n: l10n,
      );
      expect(out, isNull);
    });

    test('ready past twice pickupTargetMins goes crit', () {
      // pickupTargetMins defaults to 4, so the banner waits for 8.
      final justUnder = staleFor(
        table: table(status: TableStatus.ready),
        lines: [
          line(
            status: TicketStatus.ready,
            readyAt: now.subtract(const Duration(minutes: 7)),
          ),
        ],
        hold: null,
        service: ServiceState.none,
        s: s,
        now: now,
        l10n: l10n,
      );
      expect(justUnder, isNull);

      final over = staleFor(
        table: table(status: TableStatus.ready),
        lines: [
          line(
            status: TicketStatus.ready,
            readyAt: now.subtract(const Duration(minutes: 12)),
          ),
        ],
        hold: null,
        service: ServiceState.none,
        s: s,
        now: now,
        l10n: l10n,
      );
      expect(over!.severity, StaleSeverity.crit);
      expect(over.label, contains('12'));
    });

    test('thresholds come from settings, not constants', () {
      final t = table(openedAt: now.subtract(const Duration(minutes: 100)));
      final atDefault = staleFor(
        table: t,
        lines: const [],
        hold: null,
        service: ServiceState.none,
        s: s, // longStayMins 90 → 100 minutes is over
        now: now,
        l10n: l10n,
      );
      expect(atDefault!.severity, StaleSeverity.warn);

      final relaxed = staleFor(
        table: t,
        lines: const [],
        hold: null,
        service: ServiceState.none,
        s: s.copyWith(longStayMins: 180),
        now: now,
        l10n: l10n,
      );
      expect(relaxed, isNull);
    });

    test('a silenced cue still leaves its banner standing', () {
      // ADR-0044 as amended: the venue enable flags govern the *sound*. The
      // threshold keeps driving the card, so an owner who quietens a noisy
      // room does not also blind the floor.
      final quiet = s.copyWith(
        ungreetedAlertEnabled: false,
        pickupAlertEnabled: false,
      );

      final ungreeted = staleFor(
        table: table(openedAt: now.subtract(const Duration(minutes: 20))),
        lines: const [],
        hold: null,
        service: ServiceState.ungreeted,
        s: quiet,
        now: now,
        l10n: l10n,
      );
      expect(ungreeted?.severity, StaleSeverity.crit);

      final uncollected = staleFor(
        table: table(status: TableStatus.ready),
        lines: [
          line(
            status: TicketStatus.ready,
            readyAt: now.subtract(const Duration(minutes: 20)),
          ),
        ],
        hold: null,
        service: ServiceState.none,
        s: quiet,
        now: now,
        l10n: l10n,
      );
      expect(uncollected?.severity, StaleSeverity.crit);
    });

    test('crit outranks warn on the same table', () {
      // Both apply at 120 minutes open: long-stay (warn, past longStayMins 90)
      // and an escalated ungreeted table (crit). The crit must win.
      final out = staleFor(
        table: table(openedAt: now.subtract(const Duration(minutes: 120))),
        lines: [
          line(
            status: TicketStatus.sent,
            sentAt: now.subtract(const Duration(minutes: 30)),
          ),
        ],
        hold: null,
        service: ServiceState.ungreeted,
        s: s,
        now: now,
        l10n: l10n,
      );
      expect(out!.severity, StaleSeverity.crit);
      expect(out.label, contains('disapa'));
    });

    test('a booking past its grace releases a crit on the held table', () {
      final out = staleFor(
        table: table(status: TableStatus.available),
        lines: const [],
        // reservationGraceMins defaults to 15.
        hold: booking(now.subtract(const Duration(minutes: 25))),
        service: ServiceState.none,
        s: s,
        now: now,
        l10n: l10n,
      );
      expect(out!.severity, StaleSeverity.crit);
      expect(out.label, contains('telat'));
    });
  });

  group('reservationHoldFor', () {
    test('holds a free table for a booking inside the window', () {
      final hold = reservationHoldFor(
        table(status: TableStatus.available),
        [booking(now.add(const Duration(minutes: 30)))],
        now,
        dayStart: dayStart,
      );
      expect(hold, isNotNull);
    });

    test('does not hold a table that is already occupied', () {
      final hold = reservationHoldFor(
        table(status: TableStatus.occupied),
        [booking(now.add(const Duration(minutes: 30)))],
        now,
        dayStart: dayStart,
      );
      expect(hold, isNull);
    });

    test('a booking beyond the window is a footnote, not a hold', () {
      final free = table(status: TableStatus.available);
      final later = booking(now.add(const Duration(minutes: 180)));
      expect(
        reservationHoldFor(free, [later], now, dayStart: dayStart),
        isNull,
      );
      expect(nextReservationFor(free, [later], now), isNotNull);
    });

    test('a forgotten booking from a past day stops holding the table', () {
      // `pending` is only ever cleared by hand, so without a lower bound one
      // un-marked no-show would hold a table indefinitely.
      final free = table(status: TableStatus.available);
      final yesterday = booking(now.subtract(const Duration(days: 1)));
      expect(
        reservationHoldFor(free, [yesterday], now, dayStart: dayStart),
        isNull,
      );
    });

    test('the holding booking is not repeated as the next one', () {
      final free = table(status: TableStatus.available);
      final soon = booking(now.add(const Duration(minutes: 20)));
      expect(
        reservationHoldFor(free, [soon], now, dayStart: dayStart),
        isNotNull,
      );
      expect(nextReservationFor(free, [soon], now), isNull);
    });
  });
}
