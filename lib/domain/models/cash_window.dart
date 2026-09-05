/// The [[Jendela kas]] — the span of time the ledger screen is showing, and the
/// span its export files (ADR-0136).
///
/// One concept, two surfaces: the chips on `/kas` and the file that leaves it
/// cover exactly the same rows, because the export takes its window from the
/// screen rather than asking again. That is the whole reason this is a type and
/// not a pair of loose `DateTime?`s threaded through a query map.
///
/// **A window narrows the list, never the balance.** A box's balance is
/// `SUM(delta)` over all time (ADR-0088) and a windowed one reconciles against
/// nothing anybody can count. What a window *does* produce is movement —
/// masuk / keluar / selisih — and the server sums that, because a client holds
/// a page (ADR-0136).
///
/// Plain Dart, no Flutter and no codegen, like the rest of `domain/models`.
library;

/// Which span the reader picked.
///
/// **[all] is the default**, and deliberately so: it is the behaviour `/kas` has
/// always had — the latest rows, no window — so adding the chips changes nothing
/// for a venue that never touches them. A tin can go a fortnight without a
/// movement, and a 30-day default would open empty on a quiet box.
enum CashWindowKind {
  all,
  d30,
  d90,
  d365,
  custom;

  /// Days back for the fixed arms; null where the span is not a rolling one.
  int? get days => switch (this) {
    CashWindowKind.d30 => 30,
    CashWindowKind.d90 => 90,
    CashWindowKind.d365 => 365,
    CashWindowKind.all || CashWindowKind.custom => null,
  };
}

/// A resolved span, half-open at the top (`from <= at < to`) like every other
/// window in this codebase.
///
/// Both bounds are nullable and mean *unbounded on that side*. The rolling arms
/// leave [to] null on purpose rather than pinning it to "now": an open top is
/// what lets a movement arriving over the socket land in the window the reader
/// is looking at, which is the common case and would otherwise need the screen
/// to re-resolve its own window on every frame.
class CashWindow {
  final CashWindowKind kind;

  /// Inclusive lower bound, or null for "since the box was opened".
  final DateTime? from;

  /// Exclusive upper bound, or null for "up to whatever happens next".
  final DateTime? to;

  const CashWindow._(this.kind, this.from, this.to);

  /// Every row there has ever been — what the screen opens on.
  static const all = CashWindow._(CashWindowKind.all, null, null);

  /// A rolling window, snapped to midnight at the bottom and open at the top.
  ///
  /// Snapped deliberately, the same reason `opnameRange` is: an unsnapped bound
  /// built from `DateTime.now()` is a new value on every frame, and a provider
  /// keyed on it refetches forever.
  factory CashWindow.rolling(CashWindowKind kind, {required DateTime now}) {
    final days = kind.days;
    if (days == null) return all;
    final midnight = DateTime(now.year, now.month, now.day);
    return CashWindow._(kind, midnight.subtract(Duration(days: days)), null);
  }

  /// A committed custom span. [from] and [to] are the inclusive calendar dates
  /// the reader picked; the upper bound is pushed to the following midnight so
  /// the last day is whole.
  factory CashWindow.custom(DateTime from, DateTime to) => CashWindow._(
    CashWindowKind.custom,
    DateTime(from.year, from.month, from.day),
    DateTime(to.year, to.month, to.day).add(const Duration(days: 1)),
  );

  /// Whether a movement stamped [at] belongs in this window.
  ///
  /// The socket asks this before prepending: an entry arriving live is always
  /// stamped *now*, so it belongs in every open-topped window and in none of the
  /// closed ones. A row from today appearing in a June ledger is the same lie as
  /// a windowed balance.
  bool admits(DateTime at) =>
      (from == null || !at.isBefore(from!)) &&
      (to == null || at.isBefore(to!));

  /// Query parameters for `GET /cash`. Absent bounds are simply not sent, which
  /// is what the route reads as the **Semua** arm.
  Map<String, String> get query => {
    if (from != null) 'from': from!.toIso8601String(),
    if (to != null) 'to': to!.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is CashWindow &&
      other.kind == kind &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(kind, from, to);
}

/// Movement over one [[Jendela kas]] (ADR-0136).
///
/// **Always from the server.** The ledger list is paged, so a client summing
/// what it holds sums the pages it happened to scroll — the same class of error
/// as a windowed balance, and the reason this arrives beside the entries rather
/// than being derived from them.
///
/// A cash count's delta is a *finding*, not money moving (ADR-0089), so it lands
/// in [variance] and never in [inflow] or [outflow]: a shortfall found at the
/// count must not read as a purchase.
class CashWindowTotals {
  /// Money into the box(es) over the window — top-ups, and a transfer's in-leg.
  final int inflow;

  /// Money out, as a positive number.
  final int outflow;

  /// What counting found, signed: negative is short, positive is over.
  final int variance;

  const CashWindowTotals({
    this.inflow = 0,
    this.outflow = 0,
    this.variance = 0,
  });

  factory CashWindowTotals.fromJson(Map<String, dynamic> j) => CashWindowTotals(
    inflow: (j['inflow'] as num?)?.toInt() ?? 0,
    outflow: (j['outflow'] as num?)?.toInt() ?? 0,
    variance: (j['variance'] as num?)?.toInt() ?? 0,
  );

  /// Whether the window saw anything at all. An empty window draws no strip —
  /// three zeroes say less than the absence of the row does.
  bool get isEmpty => inflow == 0 && outflow == 0 && variance == 0;
}
