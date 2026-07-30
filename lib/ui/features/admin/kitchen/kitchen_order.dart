import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/service_timing.dart';

/// The tier below late, as a fraction of the batch's own target — far enough
/// out that a cook can still save the ticket, close enough that the warning
/// means something.
const double kKitchenWarnFraction = 0.7;

bool kitchenLineDone(TicketStatus s) =>
    s == TicketStatus.cooked ||
    s == TicketStatus.ready ||
    s == TicketStatus.served;

/// One kitchen order card: the kitchen-station tickets a table sent together.
///
/// The age is **resolved once, at build**, not read live off the clock — a
/// batch whose every line is done has stopped being work, so its counter
/// freezes at the time-to-pass it actually took and it can never be late.
/// See CONTEXT.md › Batch (kitchen order).
class KitchenOrder {
  final String tableId;
  final String sentAt;

  /// Full-precision send time of the earliest ticket. The queue sort key and
  /// the "masuk HH:mm" label — *not* the prep clock. See ADR-0008.
  final DateTime sentAtTime;

  /// Where the prep clock starts: `firedAtTime ?? sentAtTime`, earliest across
  /// the batch. A held course counts from its fire, so it is not born overdue
  /// (ADR-0043).
  final DateTime clockStart;

  final List<Ticket> tickets;

  /// Live while the batch has work left; frozen once it does not.
  final Duration age;

  /// Every line cooked, ready or served.
  final bool complete;

  /// How long this batch may take before it is late, in minutes. The `max` of
  /// its lines' resolved targets (`item.prepTime ?? venue.prepTargetMins`), so
  /// the slowest dish paces the batch and a 3-minute drink riding along with a
  /// grill order is not judged on the grill's clock. See ADR-0043.
  final int targetMins;

  const KitchenOrder({
    required this.tableId,
    required this.sentAt,
    required this.sentAtTime,
    required this.clockStart,
    required this.tickets,
    required this.age,
    required this.complete,
    required this.targetMins,
  });

  /// Resolves the batch's clock against [now].
  ///
  /// A complete batch freezes at its last line's `readyAtTime`. If any done
  /// line is missing that stamp — reachable only from seeded/demo data, since
  /// `toggleCooked` always advances through `ready` — it freezes at
  /// [fallbackFreeze] instead. ponytail: the caller stamps that once and keeps
  /// it for the life of the screen; leaving and returning re-freezes higher.
  /// [venueTargetMins] is `VenueSettings.prepTargetMins`; [prepByItem] carries
  /// each menu item's own `Waktu siap` override (absent / null ⇒ inherit).
  factory KitchenOrder.resolve({
    required String tableId,
    required String sentAt,
    required List<Ticket> tickets,
    required DateTime now,
    required int venueTargetMins,
    Map<String, int?> prepByItem = const {},
    DateTime? fallbackFreeze,
  }) {
    final sentAtTime = tickets
        .map((t) => t.sentAtTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final clockStart = tickets
        .map((t) => t.kitchenClockStart)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final complete =
        tickets.isNotEmpty && tickets.every((t) => kitchenLineDone(t.status));

    final end = complete ? (_lastReady(tickets) ?? fallbackFreeze ?? now) : now;
    final d = end.difference(clockStart);

    // The slowest line paces the batch — the same `max` rule ADR-0043 uses to
    // roll a course up for the audible overdue cue.
    // Starts at the first line, not at the venue default: a batch of nothing
    // but 5-minute drinks must be late at 5, not at the venue's 15.
    var target = tickets.isEmpty
        ? venueTargetMins
        : resolvePrepMins(prepByItem[tickets.first.itemId], venueTargetMins);
    for (final t in tickets.skip(1)) {
      final resolved = resolvePrepMins(prepByItem[t.itemId], venueTargetMins);
      if (resolved > target) target = resolved;
    }

    return KitchenOrder(
      tableId: tableId,
      sentAt: sentAt,
      sentAtTime: sentAtTime,
      clockStart: clockStart,
      tickets: tickets,
      age: d.isNegative ? Duration.zero : d,
      complete: complete,
      targetMins: target,
    );
  }

  /// The batch is ready when its *last* line is — the same rule ADR-0043 uses
  /// for a course. Null if any line never got stamped.
  static DateTime? _lastReady(List<Ticket> tickets) {
    DateTime? last;
    for (final t in tickets) {
      final r = t.readyAtTime;
      if (r == null) return null;
      if (last == null || r.isAfter(last)) last = r;
    }
    return last;
  }

  /// True while this batch still holds no stamps to freeze against — the
  /// caller uses it to decide whether to remember a fallback freeze point.
  bool get needsFallbackFreeze => complete && _lastReady(tickets) == null;

  int get total => tickets.length;
  int get done => tickets.where((t) => kitchenLineDone(t.status)).length;

  /// The tier below late, derived from this batch's own target.
  int get warnMins => (targetMins * kKitchenWarnFraction).round();

  /// A finished batch is never late: it is not work, so it earns neither the
  /// chip, the red card, nor a slot in the header tally.
  bool get late => !complete && age.inMinutes >= targetMins;
  bool get warn => !complete && !late && age.inMinutes >= warnMins;

  /// The distinct courses in this group, in station order. Usually one — the
  /// source's ticket *is* a course — but the app groups by send, and a waiter
  /// who fires drinks and mains together makes one card carry both.
  List<Course> get courses {
    final seen = tickets.map((t) => t.course).toSet();
    return [
      for (final c in Courses.all)
        if (seen.contains(c.id)) c,
    ];
  }
}
