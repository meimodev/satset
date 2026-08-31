// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_db.dart';

// ignore_for_file: type=lint
class $SettlementEventsTable extends SettlementEvents
    with TableInfo<$SettlementEventsTable, SettlementEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettlementEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _failCodeMeta = const VerificationMeta(
    'failCode',
  );
  @override
  late final GeneratedColumn<String> failCode = GeneratedColumn<String>(
    'fail_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitId,
    seq,
    kind,
    payloadJson,
    capturedAt,
    actorId,
    status,
    failCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settlement_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettlementEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('fail_code')) {
      context.handle(
        _failCodeMeta,
        failCode.isAcceptableOrUnknown(data['fail_code']!, _failCodeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettlementEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettlementEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      failCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fail_code'],
      ),
    );
  }

  @override
  $SettlementEventsTable createAlias(String alias) {
    return $SettlementEventsTable(attachedDatabase, alias);
  }
}

class SettlementEventRow extends DataClass
    implements Insertable<SettlementEventRow> {
  /// Also the idempotency key the replay carries, and the id of whatever row
  /// the act mints (ADR-0123 §ids). Stable across every retry.
  final String id;
  final String visitId;

  /// Order within the visit. Monotonic per visit, never reused.
  final int seq;

  /// A [SettlementEventKind] name. **Persisted** — never rename one, same rule
  /// as `AuditKind`.
  final String kind;
  final String payloadJson;

  /// When the cashier did it, not when it drained. The host honours this for
  /// the payment's `at`, the audit row and the business day it lands in.
  final DateTime capturedAt;
  final String actorId;

  /// `pending` — waiting to drain. `parked` — this visit's chain hit a refusal
  /// and everything from here on is untried (never "failed": the act happened,
  /// the host just has not taken it).
  final String status;

  /// The host's machine-readable refusal `code`, on the one event that was
  /// actually refused. A code crosses the layer, never a sentence (ADR-0085).
  final String? failCode;
  const SettlementEventRow({
    required this.id,
    required this.visitId,
    required this.seq,
    required this.kind,
    required this.payloadJson,
    required this.capturedAt,
    required this.actorId,
    required this.status,
    this.failCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visit_id'] = Variable<String>(visitId);
    map['seq'] = Variable<int>(seq);
    map['kind'] = Variable<String>(kind);
    map['payload_json'] = Variable<String>(payloadJson);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['actor_id'] = Variable<String>(actorId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || failCode != null) {
      map['fail_code'] = Variable<String>(failCode);
    }
    return map;
  }

  SettlementEventsCompanion toCompanion(bool nullToAbsent) {
    return SettlementEventsCompanion(
      id: Value(id),
      visitId: Value(visitId),
      seq: Value(seq),
      kind: Value(kind),
      payloadJson: Value(payloadJson),
      capturedAt: Value(capturedAt),
      actorId: Value(actorId),
      status: Value(status),
      failCode: failCode == null && nullToAbsent
          ? const Value.absent()
          : Value(failCode),
    );
  }

  factory SettlementEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettlementEventRow(
      id: serializer.fromJson<String>(json['id']),
      visitId: serializer.fromJson<String>(json['visitId']),
      seq: serializer.fromJson<int>(json['seq']),
      kind: serializer.fromJson<String>(json['kind']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      actorId: serializer.fromJson<String>(json['actorId']),
      status: serializer.fromJson<String>(json['status']),
      failCode: serializer.fromJson<String?>(json['failCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitId': serializer.toJson<String>(visitId),
      'seq': serializer.toJson<int>(seq),
      'kind': serializer.toJson<String>(kind),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'actorId': serializer.toJson<String>(actorId),
      'status': serializer.toJson<String>(status),
      'failCode': serializer.toJson<String?>(failCode),
    };
  }

  SettlementEventRow copyWith({
    String? id,
    String? visitId,
    int? seq,
    String? kind,
    String? payloadJson,
    DateTime? capturedAt,
    String? actorId,
    String? status,
    Value<String?> failCode = const Value.absent(),
  }) => SettlementEventRow(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    seq: seq ?? this.seq,
    kind: kind ?? this.kind,
    payloadJson: payloadJson ?? this.payloadJson,
    capturedAt: capturedAt ?? this.capturedAt,
    actorId: actorId ?? this.actorId,
    status: status ?? this.status,
    failCode: failCode.present ? failCode.value : this.failCode,
  );
  SettlementEventRow copyWithCompanion(SettlementEventsCompanion data) {
    return SettlementEventRow(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      seq: data.seq.present ? data.seq.value : this.seq,
      kind: data.kind.present ? data.kind.value : this.kind,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      status: data.status.present ? data.status.value : this.status,
      failCode: data.failCode.present ? data.failCode.value : this.failCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettlementEventRow(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('seq: $seq, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('actorId: $actorId, ')
          ..write('status: $status, ')
          ..write('failCode: $failCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitId,
    seq,
    kind,
    payloadJson,
    capturedAt,
    actorId,
    status,
    failCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettlementEventRow &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.seq == this.seq &&
          other.kind == this.kind &&
          other.payloadJson == this.payloadJson &&
          other.capturedAt == this.capturedAt &&
          other.actorId == this.actorId &&
          other.status == this.status &&
          other.failCode == this.failCode);
}

class SettlementEventsCompanion extends UpdateCompanion<SettlementEventRow> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<int> seq;
  final Value<String> kind;
  final Value<String> payloadJson;
  final Value<DateTime> capturedAt;
  final Value<String> actorId;
  final Value<String> status;
  final Value<String?> failCode;
  final Value<int> rowid;
  const SettlementEventsCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.seq = const Value.absent(),
    this.kind = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.actorId = const Value.absent(),
    this.status = const Value.absent(),
    this.failCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettlementEventsCompanion.insert({
    required String id,
    required String visitId,
    required int seq,
    required String kind,
    this.payloadJson = const Value.absent(),
    required DateTime capturedAt,
    this.actorId = const Value.absent(),
    this.status = const Value.absent(),
    this.failCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitId = Value(visitId),
       seq = Value(seq),
       kind = Value(kind),
       capturedAt = Value(capturedAt);
  static Insertable<SettlementEventRow> custom({
    Expression<String>? id,
    Expression<String>? visitId,
    Expression<int>? seq,
    Expression<String>? kind,
    Expression<String>? payloadJson,
    Expression<DateTime>? capturedAt,
    Expression<String>? actorId,
    Expression<String>? status,
    Expression<String>? failCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (seq != null) 'seq': seq,
      if (kind != null) 'kind': kind,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (actorId != null) 'actor_id': actorId,
      if (status != null) 'status': status,
      if (failCode != null) 'fail_code': failCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettlementEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? visitId,
    Value<int>? seq,
    Value<String>? kind,
    Value<String>? payloadJson,
    Value<DateTime>? capturedAt,
    Value<String>? actorId,
    Value<String>? status,
    Value<String?>? failCode,
    Value<int>? rowid,
  }) {
    return SettlementEventsCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      seq: seq ?? this.seq,
      kind: kind ?? this.kind,
      payloadJson: payloadJson ?? this.payloadJson,
      capturedAt: capturedAt ?? this.capturedAt,
      actorId: actorId ?? this.actorId,
      status: status ?? this.status,
      failCode: failCode ?? this.failCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (failCode.present) {
      map['fail_code'] = Variable<String>(failCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettlementEventsCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('seq: $seq, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('actorId: $actorId, ')
          ..write('status: $status, ')
          ..write('failCode: $failCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedBillsTable extends CachedBills
    with TableInfo<$CachedBillsTable, CachedBillRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedBillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billJsonMeta = const VerificationMeta(
    'billJson',
  );
  @override
  late final GeneratedColumn<String> billJson = GeneratedColumn<String>(
    'bill_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [visitId, billJson, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedBillRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('bill_json')) {
      context.handle(
        _billJsonMeta,
        billJson.isAcceptableOrUnknown(data['bill_json']!, _billJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_billJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {visitId};
  @override
  CachedBillRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedBillRow(
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      billJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedBillsTable createAlias(String alias) {
    return $CachedBillsTable(attachedDatabase, alias);
  }
}

class CachedBillRow extends DataClass implements Insertable<CachedBillRow> {
  final String visitId;

  /// The server's own bill JSON, stored whole. Kept as the wire shape rather
  /// than a parsed model so the projection can hand `Bill.fromJson` exactly
  /// what the host would have.
  final String billJson;
  final DateTime fetchedAt;
  const CachedBillRow({
    required this.visitId,
    required this.billJson,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['visit_id'] = Variable<String>(visitId);
    map['bill_json'] = Variable<String>(billJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CachedBillsCompanion toCompanion(bool nullToAbsent) {
    return CachedBillsCompanion(
      visitId: Value(visitId),
      billJson: Value(billJson),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedBillRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedBillRow(
      visitId: serializer.fromJson<String>(json['visitId']),
      billJson: serializer.fromJson<String>(json['billJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'visitId': serializer.toJson<String>(visitId),
      'billJson': serializer.toJson<String>(billJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CachedBillRow copyWith({
    String? visitId,
    String? billJson,
    DateTime? fetchedAt,
  }) => CachedBillRow(
    visitId: visitId ?? this.visitId,
    billJson: billJson ?? this.billJson,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedBillRow copyWithCompanion(CachedBillsCompanion data) {
    return CachedBillRow(
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      billJson: data.billJson.present ? data.billJson.value : this.billJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedBillRow(')
          ..write('visitId: $visitId, ')
          ..write('billJson: $billJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(visitId, billJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedBillRow &&
          other.visitId == this.visitId &&
          other.billJson == this.billJson &&
          other.fetchedAt == this.fetchedAt);
}

class CachedBillsCompanion extends UpdateCompanion<CachedBillRow> {
  final Value<String> visitId;
  final Value<String> billJson;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const CachedBillsCompanion({
    this.visitId = const Value.absent(),
    this.billJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedBillsCompanion.insert({
    required String visitId,
    required String billJson,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : visitId = Value(visitId),
       billJson = Value(billJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedBillRow> custom({
    Expression<String>? visitId,
    Expression<String>? billJson,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (visitId != null) 'visit_id': visitId,
      if (billJson != null) 'bill_json': billJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedBillsCompanion copyWith({
    Value<String>? visitId,
    Value<String>? billJson,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedBillsCompanion(
      visitId: visitId ?? this.visitId,
      billJson: billJson ?? this.billJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (billJson.present) {
      map['bill_json'] = Variable<String>(billJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedBillsCompanion(')
          ..write('visitId: $visitId, ')
          ..write('billJson: $billJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPayableTable extends CachedPayable
    with TableInfo<$CachedPayableTable, CachedPayableRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPayableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listJsonMeta = const VerificationMeta(
    'listJson',
  );
  @override
  late final GeneratedColumn<String> listJson = GeneratedColumn<String>(
    'list_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, listJson, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_payable';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPayableRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_json')) {
      context.handle(
        _listJsonMeta,
        listJson.isAcceptableOrUnknown(data['list_json']!, _listJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_listJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedPayableRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPayableRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedPayableTable createAlias(String alias) {
    return $CachedPayableTable(attachedDatabase, alias);
  }
}

class CachedPayableRow extends DataClass
    implements Insertable<CachedPayableRow> {
  /// Always [payableRowId]; this table holds one snapshot, not a history.
  final String id;

  /// The server's own `/settlement/payable` JSON array, stored whole, for the
  /// reason [CachedBills] stores the bill whole.
  final String listJson;
  final DateTime fetchedAt;
  const CachedPayableRow({
    required this.id,
    required this.listJson,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_json'] = Variable<String>(listJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CachedPayableCompanion toCompanion(bool nullToAbsent) {
    return CachedPayableCompanion(
      id: Value(id),
      listJson: Value(listJson),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedPayableRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPayableRow(
      id: serializer.fromJson<String>(json['id']),
      listJson: serializer.fromJson<String>(json['listJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listJson': serializer.toJson<String>(listJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CachedPayableRow copyWith({
    String? id,
    String? listJson,
    DateTime? fetchedAt,
  }) => CachedPayableRow(
    id: id ?? this.id,
    listJson: listJson ?? this.listJson,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedPayableRow copyWithCompanion(CachedPayableCompanion data) {
    return CachedPayableRow(
      id: data.id.present ? data.id.value : this.id,
      listJson: data.listJson.present ? data.listJson.value : this.listJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPayableRow(')
          ..write('id: $id, ')
          ..write('listJson: $listJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, listJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPayableRow &&
          other.id == this.id &&
          other.listJson == this.listJson &&
          other.fetchedAt == this.fetchedAt);
}

class CachedPayableCompanion extends UpdateCompanion<CachedPayableRow> {
  final Value<String> id;
  final Value<String> listJson;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const CachedPayableCompanion({
    this.id = const Value.absent(),
    this.listJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPayableCompanion.insert({
    required String id,
    required String listJson,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listJson = Value(listJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedPayableRow> custom({
    Expression<String>? id,
    Expression<String>? listJson,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listJson != null) 'list_json': listJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPayableCompanion copyWith({
    Value<String>? id,
    Value<String>? listJson,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedPayableCompanion(
      id: id ?? this.id,
      listJson: listJson ?? this.listJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listJson.present) {
      map['list_json'] = Variable<String>(listJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPayableCompanion(')
          ..write('id: $id, ')
          ..write('listJson: $listJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ClientDb extends GeneratedDatabase {
  _$ClientDb(QueryExecutor e) : super(e);
  $ClientDbManager get managers => $ClientDbManager(this);
  late final $SettlementEventsTable settlementEvents = $SettlementEventsTable(
    this,
  );
  late final $CachedBillsTable cachedBills = $CachedBillsTable(this);
  late final $CachedPayableTable cachedPayable = $CachedPayableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settlementEvents,
    cachedBills,
    cachedPayable,
  ];
}

typedef $$SettlementEventsTableCreateCompanionBuilder =
    SettlementEventsCompanion Function({
      required String id,
      required String visitId,
      required int seq,
      required String kind,
      Value<String> payloadJson,
      required DateTime capturedAt,
      Value<String> actorId,
      Value<String> status,
      Value<String?> failCode,
      Value<int> rowid,
    });
typedef $$SettlementEventsTableUpdateCompanionBuilder =
    SettlementEventsCompanion Function({
      Value<String> id,
      Value<String> visitId,
      Value<int> seq,
      Value<String> kind,
      Value<String> payloadJson,
      Value<DateTime> capturedAt,
      Value<String> actorId,
      Value<String> status,
      Value<String?> failCode,
      Value<int> rowid,
    });

class $$SettlementEventsTableFilterComposer
    extends Composer<_$ClientDb, $SettlementEventsTable> {
  $$SettlementEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitId => $composableBuilder(
    column: $table.visitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failCode => $composableBuilder(
    column: $table.failCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettlementEventsTableOrderingComposer
    extends Composer<_$ClientDb, $SettlementEventsTable> {
  $$SettlementEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitId => $composableBuilder(
    column: $table.visitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failCode => $composableBuilder(
    column: $table.failCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettlementEventsTableAnnotationComposer
    extends Composer<_$ClientDb, $SettlementEventsTable> {
  $$SettlementEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get visitId =>
      $composableBuilder(column: $table.visitId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get failCode =>
      $composableBuilder(column: $table.failCode, builder: (column) => column);
}

class $$SettlementEventsTableTableManager
    extends
        RootTableManager<
          _$ClientDb,
          $SettlementEventsTable,
          SettlementEventRow,
          $$SettlementEventsTableFilterComposer,
          $$SettlementEventsTableOrderingComposer,
          $$SettlementEventsTableAnnotationComposer,
          $$SettlementEventsTableCreateCompanionBuilder,
          $$SettlementEventsTableUpdateCompanionBuilder,
          (
            SettlementEventRow,
            BaseReferences<
              _$ClientDb,
              $SettlementEventsTable,
              SettlementEventRow
            >,
          ),
          SettlementEventRow,
          PrefetchHooks Function()
        > {
  $$SettlementEventsTableTableManager(
    _$ClientDb db,
    $SettlementEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettlementEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettlementEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettlementEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String> actorId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> failCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettlementEventsCompanion(
                id: id,
                visitId: visitId,
                seq: seq,
                kind: kind,
                payloadJson: payloadJson,
                capturedAt: capturedAt,
                actorId: actorId,
                status: status,
                failCode: failCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitId,
                required int seq,
                required String kind,
                Value<String> payloadJson = const Value.absent(),
                required DateTime capturedAt,
                Value<String> actorId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> failCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettlementEventsCompanion.insert(
                id: id,
                visitId: visitId,
                seq: seq,
                kind: kind,
                payloadJson: payloadJson,
                capturedAt: capturedAt,
                actorId: actorId,
                status: status,
                failCode: failCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettlementEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$ClientDb,
      $SettlementEventsTable,
      SettlementEventRow,
      $$SettlementEventsTableFilterComposer,
      $$SettlementEventsTableOrderingComposer,
      $$SettlementEventsTableAnnotationComposer,
      $$SettlementEventsTableCreateCompanionBuilder,
      $$SettlementEventsTableUpdateCompanionBuilder,
      (
        SettlementEventRow,
        BaseReferences<_$ClientDb, $SettlementEventsTable, SettlementEventRow>,
      ),
      SettlementEventRow,
      PrefetchHooks Function()
    >;
typedef $$CachedBillsTableCreateCompanionBuilder =
    CachedBillsCompanion Function({
      required String visitId,
      required String billJson,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedBillsTableUpdateCompanionBuilder =
    CachedBillsCompanion Function({
      Value<String> visitId,
      Value<String> billJson,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$CachedBillsTableFilterComposer
    extends Composer<_$ClientDb, $CachedBillsTable> {
  $$CachedBillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get visitId => $composableBuilder(
    column: $table.visitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billJson => $composableBuilder(
    column: $table.billJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedBillsTableOrderingComposer
    extends Composer<_$ClientDb, $CachedBillsTable> {
  $$CachedBillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get visitId => $composableBuilder(
    column: $table.visitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billJson => $composableBuilder(
    column: $table.billJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedBillsTableAnnotationComposer
    extends Composer<_$ClientDb, $CachedBillsTable> {
  $$CachedBillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get visitId =>
      $composableBuilder(column: $table.visitId, builder: (column) => column);

  GeneratedColumn<String> get billJson =>
      $composableBuilder(column: $table.billJson, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedBillsTableTableManager
    extends
        RootTableManager<
          _$ClientDb,
          $CachedBillsTable,
          CachedBillRow,
          $$CachedBillsTableFilterComposer,
          $$CachedBillsTableOrderingComposer,
          $$CachedBillsTableAnnotationComposer,
          $$CachedBillsTableCreateCompanionBuilder,
          $$CachedBillsTableUpdateCompanionBuilder,
          (
            CachedBillRow,
            BaseReferences<_$ClientDb, $CachedBillsTable, CachedBillRow>,
          ),
          CachedBillRow,
          PrefetchHooks Function()
        > {
  $$CachedBillsTableTableManager(_$ClientDb db, $CachedBillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedBillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedBillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedBillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> visitId = const Value.absent(),
                Value<String> billJson = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedBillsCompanion(
                visitId: visitId,
                billJson: billJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String visitId,
                required String billJson,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedBillsCompanion.insert(
                visitId: visitId,
                billJson: billJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedBillsTableProcessedTableManager =
    ProcessedTableManager<
      _$ClientDb,
      $CachedBillsTable,
      CachedBillRow,
      $$CachedBillsTableFilterComposer,
      $$CachedBillsTableOrderingComposer,
      $$CachedBillsTableAnnotationComposer,
      $$CachedBillsTableCreateCompanionBuilder,
      $$CachedBillsTableUpdateCompanionBuilder,
      (
        CachedBillRow,
        BaseReferences<_$ClientDb, $CachedBillsTable, CachedBillRow>,
      ),
      CachedBillRow,
      PrefetchHooks Function()
    >;
typedef $$CachedPayableTableCreateCompanionBuilder =
    CachedPayableCompanion Function({
      required String id,
      required String listJson,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedPayableTableUpdateCompanionBuilder =
    CachedPayableCompanion Function({
      Value<String> id,
      Value<String> listJson,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$CachedPayableTableFilterComposer
    extends Composer<_$ClientDb, $CachedPayableTable> {
  $$CachedPayableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listJson => $composableBuilder(
    column: $table.listJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPayableTableOrderingComposer
    extends Composer<_$ClientDb, $CachedPayableTable> {
  $$CachedPayableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listJson => $composableBuilder(
    column: $table.listJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPayableTableAnnotationComposer
    extends Composer<_$ClientDb, $CachedPayableTable> {
  $$CachedPayableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get listJson =>
      $composableBuilder(column: $table.listJson, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedPayableTableTableManager
    extends
        RootTableManager<
          _$ClientDb,
          $CachedPayableTable,
          CachedPayableRow,
          $$CachedPayableTableFilterComposer,
          $$CachedPayableTableOrderingComposer,
          $$CachedPayableTableAnnotationComposer,
          $$CachedPayableTableCreateCompanionBuilder,
          $$CachedPayableTableUpdateCompanionBuilder,
          (
            CachedPayableRow,
            BaseReferences<_$ClientDb, $CachedPayableTable, CachedPayableRow>,
          ),
          CachedPayableRow,
          PrefetchHooks Function()
        > {
  $$CachedPayableTableTableManager(_$ClientDb db, $CachedPayableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPayableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPayableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPayableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> listJson = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPayableCompanion(
                id: id,
                listJson: listJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String listJson,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedPayableCompanion.insert(
                id: id,
                listJson: listJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPayableTableProcessedTableManager =
    ProcessedTableManager<
      _$ClientDb,
      $CachedPayableTable,
      CachedPayableRow,
      $$CachedPayableTableFilterComposer,
      $$CachedPayableTableOrderingComposer,
      $$CachedPayableTableAnnotationComposer,
      $$CachedPayableTableCreateCompanionBuilder,
      $$CachedPayableTableUpdateCompanionBuilder,
      (
        CachedPayableRow,
        BaseReferences<_$ClientDb, $CachedPayableTable, CachedPayableRow>,
      ),
      CachedPayableRow,
      PrefetchHooks Function()
    >;

class $ClientDbManager {
  final _$ClientDb _db;
  $ClientDbManager(this._db);
  $$SettlementEventsTableTableManager get settlementEvents =>
      $$SettlementEventsTableTableManager(_db, _db.settlementEvents);
  $$CachedBillsTableTableManager get cachedBills =>
      $$CachedBillsTableTableManager(_db, _db.cachedBills);
  $$CachedPayableTableTableManager get cachedPayable =>
      $$CachedPayableTableTableManager(_db, _db.cachedPayable);
}
