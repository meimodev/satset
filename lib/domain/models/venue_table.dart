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
  final bool mine;
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

  const VenueTable({
    required this.id,
    required this.zoneId,
    this.label,
    this.pax = 2,
    this.capacity = 2,
    this.active = true,
    this.status = TableStatus.available,
    this.elapsed,
    this.mine = false,
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
  });

  /// True when [lockedBy] is set, not equal to [userId], and the lease has
  /// not expired. Server is authoritative; this is a UI gating helper only.
  bool isLockedByOther(String? userId, {DateTime? now}) {
    if (lockedBy == null || lockedBy!.isEmpty) return false;
    if (userId != null && lockedBy == userId) return false;
    final exp = lockExpiresAt;
    if (exp == null) return false;
    return exp.isAfter(now ?? DateTime.now());
  }

  String get displayName => (label != null && label!.trim().isNotEmpty) ? label! : id;

  VenueTable copyWith({
    String? zoneId,
    String? label,
    int? pax,
    int? capacity,
    bool? active,
    TableStatus? status,
    String? elapsed,
    bool? mine,
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
      mine: mine ?? this.mine,
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
    );
  }
}
