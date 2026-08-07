enum ReservationStatus { pending, seated, noShow, cancelled }

String reservationStatusKey(ReservationStatus s) => switch (s) {
  ReservationStatus.pending => 'pending',
  ReservationStatus.seated => 'seated',
  ReservationStatus.noShow => 'noShow',
  ReservationStatus.cancelled => 'cancelled',
};

ReservationStatus reservationStatusFromKey(String key) => switch (key) {
  'seated' => ReservationStatus.seated,
  'noShow' => ReservationStatus.noShow,
  'cancelled' => ReservationStatus.cancelled,
  _ => ReservationStatus.pending,
};

class Reservation {
  final String id;
  final String name;
  final String? phone;
  final int partySize;
  final DateTime expectedAt;
  final ReservationStatus status;
  final String? zoneId;
  final String? tableId;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Reservation({
    required this.id,
    required this.name,
    this.phone,
    required this.partySize,
    required this.expectedAt,
    required this.status,
    this.zoneId,
    this.tableId,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Reservation copyWith({
    String? id,
    String? name,
    Object? phone = _unset,
    int? partySize,
    DateTime? expectedAt,
    ReservationStatus? status,
    Object? zoneId = _unset,
    Object? tableId = _unset,
    Object? notes = _unset,
    DateTime? createdAt,
    Object? updatedAt = _unset,
  }) => Reservation(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: identical(phone, _unset) ? this.phone : phone as String?,
    partySize: partySize ?? this.partySize,
    expectedAt: expectedAt ?? this.expectedAt,
    status: status ?? this.status,
    zoneId: identical(zoneId, _unset) ? this.zoneId : zoneId as String?,
    tableId: identical(tableId, _unset) ? this.tableId : tableId as String?,
    notes: identical(notes, _unset) ? this.notes : notes as String?,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: identical(updatedAt, _unset)
        ? this.updatedAt
        : updatedAt as DateTime?,
  );
}

const Object _unset = Object();
