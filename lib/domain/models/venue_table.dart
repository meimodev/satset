enum TableStatus { available, occupied, pending, ready }

class VenueTable {
  final String id;
  final String zoneId;
  final String? label;
  final int pax;
  final bool active;

  final TableStatus status;
  final String? elapsed;
  final bool mine;
  final int openAmount;
  final int readyCount;
  final String? lastActorId;

  const VenueTable({
    required this.id,
    required this.zoneId,
    this.label,
    this.pax = 2,
    this.active = true,
    this.status = TableStatus.available,
    this.elapsed,
    this.mine = false,
    this.openAmount = 0,
    this.readyCount = 0,
    this.lastActorId,
  });

  String get displayName => (label != null && label!.trim().isNotEmpty) ? label! : id;

  VenueTable copyWith({
    String? zoneId,
    String? label,
    int? pax,
    bool? active,
    TableStatus? status,
    String? elapsed,
    bool? mine,
    int? openAmount,
    int? readyCount,
    String? lastActorId,
  }) {
    return VenueTable(
      id: id,
      zoneId: zoneId ?? this.zoneId,
      label: label ?? this.label,
      pax: pax ?? this.pax,
      active: active ?? this.active,
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      mine: mine ?? this.mine,
      openAmount: openAmount ?? this.openAmount,
      readyCount: readyCount ?? this.readyCount,
      lastActorId: lastActorId ?? this.lastActorId,
    );
  }
}
