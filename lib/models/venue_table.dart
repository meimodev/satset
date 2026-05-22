enum TableStatus { available, occupied, pending, ready }

class VenueTable {
  final String id;
  final String zoneId;
  final int pax;
  final TableStatus status;
  final String? elapsed;
  final bool mine;
  final int openAmount;
  final int readyCount;
  final String? lastActorId;

  const VenueTable({
    required this.id,
    required this.zoneId,
    this.pax = 2,
    this.status = TableStatus.available,
    this.elapsed,
    this.mine = false,
    this.openAmount = 0,
    this.readyCount = 0,
    this.lastActorId,
  });

  VenueTable copyWith({
    int? pax,
    TableStatus? status,
    String? elapsed,
    bool? mine,
    int? openAmount,
    int? readyCount,
    String? lastActorId,
  }) {
    return VenueTable(
      id: id,
      zoneId: zoneId,
      pax: pax ?? this.pax,
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      mine: mine ?? this.mine,
      openAmount: openAmount ?? this.openAmount,
      readyCount: readyCount ?? this.readyCount,
      lastActorId: lastActorId ?? this.lastActorId,
    );
  }
}
