import 'package:satset/core/time/sat_clock.dart';

enum TableStatus { available, occupied, pending, ready }

class VenueTable {
  final String id;
  final String zoneId;
  final String? label;
  final int pax;
  final int capacity;
  final bool active;

  final TableStatus status;
  final String? elapsed;
  final int openAmount;
  final int readyCount;
  final String? lastActorId;
  final String? lockedBy;
  final String? lockedByName;
  final DateTime? lockedAt;
  final DateTime? lockExpiresAt;
  final DateTime? openedAt;
  final String? guestName;
  final String? guestNotes;
  final String? reservationId;

  /// Stable id of the visit currently seated at this table, or null when kosong.
  /// The key the live-ticket cache resolves a dine-in table's lines through —
  /// a `tableId` is reused across visits, so lines hang off the visit, never the
  /// table. See ADR-0034 / ADR-0024.
  final String? currentVisitId;

  /// The current visit's bill has been closed (Lunas) by the cashier while the
  /// table is still occupied — drives the floor's Lunas pill. See ADR-0024.
  final bool billClosed;

  /// Live settlement state of the current visit: `partial` | `paid` | null.
  /// With [openAmount] (outstanding) drives the floor money badge. ADR-0024.
  final String? moneyState;

  const VenueTable({
    required this.id,
    required this.zoneId,
    this.label,
    this.pax = 2,
    this.capacity = 2,
    this.active = true,
    this.status = TableStatus.available,
    this.elapsed,
    this.openAmount = 0,
    this.readyCount = 0,
    this.lastActorId,
    this.lockedBy,
    this.lockedByName,
    this.lockedAt,
    this.lockExpiresAt,
    this.openedAt,
    this.guestName,
    this.guestNotes,
    this.reservationId,
    this.currentVisitId,
    this.billClosed = false,
    this.moneyState,
  });

  /// True when [lockedBy] is set, not equal to [userId], and the lease has
  /// not expired. Server is authoritative; this is a UI gating helper only.
  bool isLockedByOther(String? userId, {DateTime? now}) {
    if (lockedBy == null || lockedBy!.isEmpty) return false;
    if (userId != null && lockedBy == userId) return false;
    final exp = lockExpiresAt;
    if (exp == null) return false;
    return exp.isAfter(now ?? SatClock.now());
  }

  String get displayName =>
      (label != null && label!.trim().isNotEmpty) ? label! : id;

  VenueTable copyWith({
    String? zoneId,
    String? label,
    int? pax,
    int? capacity,
    bool? active,
    TableStatus? status,
    String? elapsed,
    int? openAmount,
    int? readyCount,
    String? lastActorId,
    String? lockedBy,
    String? lockedByName,
    DateTime? lockedAt,
    DateTime? lockExpiresAt,
    DateTime? openedAt,
    String? guestName,
    String? guestNotes,
    String? reservationId,
    String? currentVisitId,
  }) {
    return VenueTable(
      id: id,
      zoneId: zoneId ?? this.zoneId,
      label: label ?? this.label,
      pax: pax ?? this.pax,
      capacity: capacity ?? this.capacity,
      active: active ?? this.active,
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      openAmount: openAmount ?? this.openAmount,
      readyCount: readyCount ?? this.readyCount,
      lastActorId: lastActorId ?? this.lastActorId,
      lockedBy: lockedBy ?? this.lockedBy,
      lockedByName: lockedByName ?? this.lockedByName,
      lockedAt: lockedAt ?? this.lockedAt,
      lockExpiresAt: lockExpiresAt ?? this.lockExpiresAt,
      openedAt: openedAt ?? this.openedAt,
      guestName: guestName ?? this.guestName,
      guestNotes: guestNotes ?? this.guestNotes,
      reservationId: reservationId ?? this.reservationId,
      currentVisitId: currentVisitId ?? this.currentVisitId,
    );
  }
}
