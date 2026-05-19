enum TableStatus { empty, ordering, waiting, ready }

class VenueTable {
  final String id;
  final String zoneId;
  final String label;
  final int capacity;
  final TableStatus status;
  final int? guestCount;
  final bool isBooth;

  const VenueTable({
    required this.id,
    required this.zoneId,
    required this.label,
    this.capacity = 4,
    this.status = TableStatus.empty,
    this.guestCount,
    this.isBooth = false,
  });

  VenueTable copyWith({
    String? id,
    String? zoneId,
    String? label,
    int? capacity,
    TableStatus? status,
    int? guestCount,
    bool? isBooth,
  }) {
    return VenueTable(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      label: label ?? this.label,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      guestCount: guestCount ?? this.guestCount,
      isBooth: isBooth ?? this.isBooth,
    );
  }
}
