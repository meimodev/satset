// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialsMeta = const VerificationMeta(
    'initials',
  );
  @override
  late final GeneratedColumn<String> initials = GeneratedColumn<String>(
    'initials',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
    'role_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zoneAssignedMeta = const VerificationMeta(
    'zoneAssigned',
  );
  @override
  late final GeneratedColumn<String> zoneAssigned = GeneratedColumn<String>(
    'zone_assigned',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onDutyMeta = const VerificationMeta('onDuty');
  @override
  late final GeneratedColumn<bool> onDuty = GeneratedColumn<bool>(
    'on_duty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("on_duty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _disabledMeta = const VerificationMeta(
    'disabled',
  );
  @override
  late final GeneratedColumn<bool> disabled = GeneratedColumn<bool>(
    'disabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("disabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _shiftStartedAtMeta = const VerificationMeta(
    'shiftStartedAt',
  );
  @override
  late final GeneratedColumn<DateTime> shiftStartedAt =
      GeneratedColumn<DateTime>(
        'shift_started_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    initials,
    roleId,
    zoneAssigned,
    pinHash,
    onDuty,
    disabled,
    shiftStartedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('initials')) {
      context.handle(
        _initialsMeta,
        initials.isAcceptableOrUnknown(data['initials']!, _initialsMeta),
      );
    } else if (isInserting) {
      context.missing(_initialsMeta);
    }
    if (data.containsKey('role_id')) {
      context.handle(
        _roleIdMeta,
        roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roleIdMeta);
    }
    if (data.containsKey('zone_assigned')) {
      context.handle(
        _zoneAssignedMeta,
        zoneAssigned.isAcceptableOrUnknown(
          data['zone_assigned']!,
          _zoneAssignedMeta,
        ),
      );
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    } else if (isInserting) {
      context.missing(_pinHashMeta);
    }
    if (data.containsKey('on_duty')) {
      context.handle(
        _onDutyMeta,
        onDuty.isAcceptableOrUnknown(data['on_duty']!, _onDutyMeta),
      );
    }
    if (data.containsKey('disabled')) {
      context.handle(
        _disabledMeta,
        disabled.isAcceptableOrUnknown(data['disabled']!, _disabledMeta),
      );
    }
    if (data.containsKey('shift_started_at')) {
      context.handle(
        _shiftStartedAtMeta,
        shiftStartedAt.isAcceptableOrUnknown(
          data['shift_started_at']!,
          _shiftStartedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      initials: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initials'],
      )!,
      roleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_id'],
      )!,
      zoneAssigned: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_assigned'],
      ),
      pinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_hash'],
      )!,
      onDuty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}on_duty'],
      )!,
      disabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}disabled'],
      )!,
      shiftStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}shift_started_at'],
      ),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String name;
  final String initials;
  final String roleId;
  final String? zoneAssigned;
  final String pinHash;
  final bool onDuty;
  final bool disabled;
  final DateTime? shiftStartedAt;
  const User({
    required this.id,
    required this.name,
    required this.initials,
    required this.roleId,
    this.zoneAssigned,
    required this.pinHash,
    required this.onDuty,
    required this.disabled,
    this.shiftStartedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['initials'] = Variable<String>(initials);
    map['role_id'] = Variable<String>(roleId);
    if (!nullToAbsent || zoneAssigned != null) {
      map['zone_assigned'] = Variable<String>(zoneAssigned);
    }
    map['pin_hash'] = Variable<String>(pinHash);
    map['on_duty'] = Variable<bool>(onDuty);
    map['disabled'] = Variable<bool>(disabled);
    if (!nullToAbsent || shiftStartedAt != null) {
      map['shift_started_at'] = Variable<DateTime>(shiftStartedAt);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      initials: Value(initials),
      roleId: Value(roleId),
      zoneAssigned: zoneAssigned == null && nullToAbsent
          ? const Value.absent()
          : Value(zoneAssigned),
      pinHash: Value(pinHash),
      onDuty: Value(onDuty),
      disabled: Value(disabled),
      shiftStartedAt: shiftStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftStartedAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      initials: serializer.fromJson<String>(json['initials']),
      roleId: serializer.fromJson<String>(json['roleId']),
      zoneAssigned: serializer.fromJson<String?>(json['zoneAssigned']),
      pinHash: serializer.fromJson<String>(json['pinHash']),
      onDuty: serializer.fromJson<bool>(json['onDuty']),
      disabled: serializer.fromJson<bool>(json['disabled']),
      shiftStartedAt: serializer.fromJson<DateTime?>(json['shiftStartedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'initials': serializer.toJson<String>(initials),
      'roleId': serializer.toJson<String>(roleId),
      'zoneAssigned': serializer.toJson<String?>(zoneAssigned),
      'pinHash': serializer.toJson<String>(pinHash),
      'onDuty': serializer.toJson<bool>(onDuty),
      'disabled': serializer.toJson<bool>(disabled),
      'shiftStartedAt': serializer.toJson<DateTime?>(shiftStartedAt),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? initials,
    String? roleId,
    Value<String?> zoneAssigned = const Value.absent(),
    String? pinHash,
    bool? onDuty,
    bool? disabled,
    Value<DateTime?> shiftStartedAt = const Value.absent(),
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    initials: initials ?? this.initials,
    roleId: roleId ?? this.roleId,
    zoneAssigned: zoneAssigned.present ? zoneAssigned.value : this.zoneAssigned,
    pinHash: pinHash ?? this.pinHash,
    onDuty: onDuty ?? this.onDuty,
    disabled: disabled ?? this.disabled,
    shiftStartedAt: shiftStartedAt.present
        ? shiftStartedAt.value
        : this.shiftStartedAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      initials: data.initials.present ? data.initials.value : this.initials,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      zoneAssigned: data.zoneAssigned.present
          ? data.zoneAssigned.value
          : this.zoneAssigned,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      onDuty: data.onDuty.present ? data.onDuty.value : this.onDuty,
      disabled: data.disabled.present ? data.disabled.value : this.disabled,
      shiftStartedAt: data.shiftStartedAt.present
          ? data.shiftStartedAt.value
          : this.shiftStartedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('initials: $initials, ')
          ..write('roleId: $roleId, ')
          ..write('zoneAssigned: $zoneAssigned, ')
          ..write('pinHash: $pinHash, ')
          ..write('onDuty: $onDuty, ')
          ..write('disabled: $disabled, ')
          ..write('shiftStartedAt: $shiftStartedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    initials,
    roleId,
    zoneAssigned,
    pinHash,
    onDuty,
    disabled,
    shiftStartedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.initials == this.initials &&
          other.roleId == this.roleId &&
          other.zoneAssigned == this.zoneAssigned &&
          other.pinHash == this.pinHash &&
          other.onDuty == this.onDuty &&
          other.disabled == this.disabled &&
          other.shiftStartedAt == this.shiftStartedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> initials;
  final Value<String> roleId;
  final Value<String?> zoneAssigned;
  final Value<String> pinHash;
  final Value<bool> onDuty;
  final Value<bool> disabled;
  final Value<DateTime?> shiftStartedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.initials = const Value.absent(),
    this.roleId = const Value.absent(),
    this.zoneAssigned = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.onDuty = const Value.absent(),
    this.disabled = const Value.absent(),
    this.shiftStartedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String name,
    required String initials,
    required String roleId,
    this.zoneAssigned = const Value.absent(),
    required String pinHash,
    this.onDuty = const Value.absent(),
    this.disabled = const Value.absent(),
    this.shiftStartedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       initials = Value(initials),
       roleId = Value(roleId),
       pinHash = Value(pinHash);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? initials,
    Expression<String>? roleId,
    Expression<String>? zoneAssigned,
    Expression<String>? pinHash,
    Expression<bool>? onDuty,
    Expression<bool>? disabled,
    Expression<DateTime>? shiftStartedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (initials != null) 'initials': initials,
      if (roleId != null) 'role_id': roleId,
      if (zoneAssigned != null) 'zone_assigned': zoneAssigned,
      if (pinHash != null) 'pin_hash': pinHash,
      if (onDuty != null) 'on_duty': onDuty,
      if (disabled != null) 'disabled': disabled,
      if (shiftStartedAt != null) 'shift_started_at': shiftStartedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? initials,
    Value<String>? roleId,
    Value<String?>? zoneAssigned,
    Value<String>? pinHash,
    Value<bool>? onDuty,
    Value<bool>? disabled,
    Value<DateTime?>? shiftStartedAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      roleId: roleId ?? this.roleId,
      zoneAssigned: zoneAssigned ?? this.zoneAssigned,
      pinHash: pinHash ?? this.pinHash,
      onDuty: onDuty ?? this.onDuty,
      disabled: disabled ?? this.disabled,
      shiftStartedAt: shiftStartedAt ?? this.shiftStartedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (initials.present) {
      map['initials'] = Variable<String>(initials.value);
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (zoneAssigned.present) {
      map['zone_assigned'] = Variable<String>(zoneAssigned.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (onDuty.present) {
      map['on_duty'] = Variable<bool>(onDuty.value);
    }
    if (disabled.present) {
      map['disabled'] = Variable<bool>(disabled.value);
    }
    if (shiftStartedAt.present) {
      map['shift_started_at'] = Variable<DateTime>(shiftStartedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('initials: $initials, ')
          ..write('roleId: $roleId, ')
          ..write('zoneAssigned: $zoneAssigned, ')
          ..write('pinHash: $pinHash, ')
          ..write('onDuty: $onDuty, ')
          ..write('disabled: $disabled, ')
          ..write('shiftStartedAt: $shiftStartedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RolesTable extends Roles with TableInfo<$RolesTable, Role> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RolesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#C08AFF'),
  );
  static const VerificationMeta _capabilitiesJsonMeta = const VerificationMeta(
    'capabilitiesJson',
  );
  @override
  late final GeneratedColumn<String> capabilitiesJson = GeneratedColumn<String>(
    'capabilities_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, colorHex, capabilitiesJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'roles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Role> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('capabilities_json')) {
      context.handle(
        _capabilitiesJsonMeta,
        capabilitiesJson.isAcceptableOrUnknown(
          data['capabilities_json']!,
          _capabilitiesJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Role map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Role(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      capabilitiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capabilities_json'],
      )!,
    );
  }

  @override
  $RolesTable createAlias(String alias) {
    return $RolesTable(attachedDatabase, alias);
  }
}

class Role extends DataClass implements Insertable<Role> {
  final String id;
  final String name;
  final String colorHex;

  /// JSON array of capability keys.
  final String capabilitiesJson;
  const Role({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.capabilitiesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color_hex'] = Variable<String>(colorHex);
    map['capabilities_json'] = Variable<String>(capabilitiesJson);
    return map;
  }

  RolesCompanion toCompanion(bool nullToAbsent) {
    return RolesCompanion(
      id: Value(id),
      name: Value(name),
      colorHex: Value(colorHex),
      capabilitiesJson: Value(capabilitiesJson),
    );
  }

  factory Role.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Role(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      capabilitiesJson: serializer.fromJson<String>(json['capabilitiesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String>(colorHex),
      'capabilitiesJson': serializer.toJson<String>(capabilitiesJson),
    };
  }

  Role copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? capabilitiesJson,
  }) => Role(
    id: id ?? this.id,
    name: name ?? this.name,
    colorHex: colorHex ?? this.colorHex,
    capabilitiesJson: capabilitiesJson ?? this.capabilitiesJson,
  );
  Role copyWithCompanion(RolesCompanion data) {
    return Role(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      capabilitiesJson: data.capabilitiesJson.present
          ? data.capabilitiesJson.value
          : this.capabilitiesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Role(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('capabilitiesJson: $capabilitiesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorHex, capabilitiesJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Role &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.capabilitiesJson == this.capabilitiesJson);
}

class RolesCompanion extends UpdateCompanion<Role> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> colorHex;
  final Value<String> capabilitiesJson;
  final Value<int> rowid;
  const RolesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.capabilitiesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RolesCompanion.insert({
    required String id,
    required String name,
    this.colorHex = const Value.absent(),
    this.capabilitiesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Role> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<String>? capabilitiesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (capabilitiesJson != null) 'capabilities_json': capabilitiesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RolesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? colorHex,
    Value<String>? capabilitiesJson,
    Value<int>? rowid,
  }) {
    return RolesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      capabilitiesJson: capabilitiesJson ?? this.capabilitiesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (capabilitiesJson.present) {
      map['capabilities_json'] = Variable<String>(capabilitiesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RolesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('capabilitiesJson: $capabilitiesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ZonesTable extends Zones with TableInfo<$ZonesTable, Zone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ZonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shortMeta = const VerificationMeta('short');
  @override
  late final GeneratedColumn<String> short = GeneratedColumn<String>(
    'short',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#FF9233'),
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('table_restaurant'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    short,
    colorHex,
    iconKey,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'zones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Zone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('short')) {
      context.handle(
        _shortMeta,
        short.isAcceptableOrUnknown(data['short']!, _shortMeta),
      );
    } else if (isInserting) {
      context.missing(_shortMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Zone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Zone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      short: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ZonesTable createAlias(String alias) {
    return $ZonesTable(attachedDatabase, alias);
  }
}

class Zone extends DataClass implements Insertable<Zone> {
  final String id;
  final String name;
  final String short;
  final String colorHex;
  final String iconKey;
  final int sortOrder;
  const Zone({
    required this.id,
    required this.name,
    required this.short,
    required this.colorHex,
    required this.iconKey,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['short'] = Variable<String>(short);
    map['color_hex'] = Variable<String>(colorHex);
    map['icon_key'] = Variable<String>(iconKey);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ZonesCompanion toCompanion(bool nullToAbsent) {
    return ZonesCompanion(
      id: Value(id),
      name: Value(name),
      short: Value(short),
      colorHex: Value(colorHex),
      iconKey: Value(iconKey),
      sortOrder: Value(sortOrder),
    );
  }

  factory Zone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Zone(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      short: serializer.fromJson<String>(json['short']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'short': serializer.toJson<String>(short),
      'colorHex': serializer.toJson<String>(colorHex),
      'iconKey': serializer.toJson<String>(iconKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Zone copyWith({
    String? id,
    String? name,
    String? short,
    String? colorHex,
    String? iconKey,
    int? sortOrder,
  }) => Zone(
    id: id ?? this.id,
    name: name ?? this.name,
    short: short ?? this.short,
    colorHex: colorHex ?? this.colorHex,
    iconKey: iconKey ?? this.iconKey,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Zone copyWithCompanion(ZonesCompanion data) {
    return Zone(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      short: data.short.present ? data.short.value : this.short,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Zone(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('short: $short, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, short, colorHex, iconKey, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Zone &&
          other.id == this.id &&
          other.name == this.name &&
          other.short == this.short &&
          other.colorHex == this.colorHex &&
          other.iconKey == this.iconKey &&
          other.sortOrder == this.sortOrder);
}

class ZonesCompanion extends UpdateCompanion<Zone> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> short;
  final Value<String> colorHex;
  final Value<String> iconKey;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ZonesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.short = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ZonesCompanion.insert({
    required String id,
    required String name,
    required String short,
    this.colorHex = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       short = Value(short);
  static Insertable<Zone> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? short,
    Expression<String>? colorHex,
    Expression<String>? iconKey,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (short != null) 'short': short,
      if (colorHex != null) 'color_hex': colorHex,
      if (iconKey != null) 'icon_key': iconKey,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ZonesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? short,
    Value<String>? colorHex,
    Value<String>? iconKey,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ZonesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      short: short ?? this.short,
      colorHex: colorHex ?? this.colorHex,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (short.present) {
      map['short'] = Variable<String>(short.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ZonesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('short: $short, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VenueTablesTable extends VenueTables
    with TableInfo<$VenueTablesTable, VenueTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VenueTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zoneIdMeta = const VerificationMeta('zoneId');
  @override
  late final GeneratedColumn<String> zoneId = GeneratedColumn<String>(
    'zone_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paxMeta = const VerificationMeta('pax');
  @override
  late final GeneratedColumn<int> pax = GeneratedColumn<int>(
    'pax',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('available'),
  );
  static const VerificationMeta _openAmountMeta = const VerificationMeta(
    'openAmount',
  );
  @override
  late final GeneratedColumn<int> openAmount = GeneratedColumn<int>(
    'open_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _readyCountMeta = const VerificationMeta(
    'readyCount',
  );
  @override
  late final GeneratedColumn<int> readyCount = GeneratedColumn<int>(
    'ready_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastActorIdMeta = const VerificationMeta(
    'lastActorId',
  );
  @override
  late final GeneratedColumn<String> lastActorId = GeneratedColumn<String>(
    'last_actor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    zoneId,
    label,
    pax,
    active,
    status,
    openAmount,
    readyCount,
    lastActorId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'venue_tables';
  @override
  VerificationContext validateIntegrity(
    Insertable<VenueTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('zone_id')) {
      context.handle(
        _zoneIdMeta,
        zoneId.isAcceptableOrUnknown(data['zone_id']!, _zoneIdMeta),
      );
    } else if (isInserting) {
      context.missing(_zoneIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('pax')) {
      context.handle(
        _paxMeta,
        pax.isAcceptableOrUnknown(data['pax']!, _paxMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('open_amount')) {
      context.handle(
        _openAmountMeta,
        openAmount.isAcceptableOrUnknown(data['open_amount']!, _openAmountMeta),
      );
    }
    if (data.containsKey('ready_count')) {
      context.handle(
        _readyCountMeta,
        readyCount.isAcceptableOrUnknown(data['ready_count']!, _readyCountMeta),
      );
    }
    if (data.containsKey('last_actor_id')) {
      context.handle(
        _lastActorIdMeta,
        lastActorId.isAcceptableOrUnknown(
          data['last_actor_id']!,
          _lastActorIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VenueTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VenueTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      zoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      pax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pax'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      openAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}open_amount'],
      )!,
      readyCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ready_count'],
      )!,
      lastActorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_actor_id'],
      ),
    );
  }

  @override
  $VenueTablesTable createAlias(String alias) {
    return $VenueTablesTable(attachedDatabase, alias);
  }
}

class VenueTable extends DataClass implements Insertable<VenueTable> {
  final String id;
  final String zoneId;
  final String? label;
  final int pax;
  final bool active;
  final String status;
  final int openAmount;
  final int readyCount;
  final String? lastActorId;
  const VenueTable({
    required this.id,
    required this.zoneId,
    this.label,
    required this.pax,
    required this.active,
    required this.status,
    required this.openAmount,
    required this.readyCount,
    this.lastActorId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['zone_id'] = Variable<String>(zoneId);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['pax'] = Variable<int>(pax);
    map['active'] = Variable<bool>(active);
    map['status'] = Variable<String>(status);
    map['open_amount'] = Variable<int>(openAmount);
    map['ready_count'] = Variable<int>(readyCount);
    if (!nullToAbsent || lastActorId != null) {
      map['last_actor_id'] = Variable<String>(lastActorId);
    }
    return map;
  }

  VenueTablesCompanion toCompanion(bool nullToAbsent) {
    return VenueTablesCompanion(
      id: Value(id),
      zoneId: Value(zoneId),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      pax: Value(pax),
      active: Value(active),
      status: Value(status),
      openAmount: Value(openAmount),
      readyCount: Value(readyCount),
      lastActorId: lastActorId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActorId),
    );
  }

  factory VenueTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VenueTable(
      id: serializer.fromJson<String>(json['id']),
      zoneId: serializer.fromJson<String>(json['zoneId']),
      label: serializer.fromJson<String?>(json['label']),
      pax: serializer.fromJson<int>(json['pax']),
      active: serializer.fromJson<bool>(json['active']),
      status: serializer.fromJson<String>(json['status']),
      openAmount: serializer.fromJson<int>(json['openAmount']),
      readyCount: serializer.fromJson<int>(json['readyCount']),
      lastActorId: serializer.fromJson<String?>(json['lastActorId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'zoneId': serializer.toJson<String>(zoneId),
      'label': serializer.toJson<String?>(label),
      'pax': serializer.toJson<int>(pax),
      'active': serializer.toJson<bool>(active),
      'status': serializer.toJson<String>(status),
      'openAmount': serializer.toJson<int>(openAmount),
      'readyCount': serializer.toJson<int>(readyCount),
      'lastActorId': serializer.toJson<String?>(lastActorId),
    };
  }

  VenueTable copyWith({
    String? id,
    String? zoneId,
    Value<String?> label = const Value.absent(),
    int? pax,
    bool? active,
    String? status,
    int? openAmount,
    int? readyCount,
    Value<String?> lastActorId = const Value.absent(),
  }) => VenueTable(
    id: id ?? this.id,
    zoneId: zoneId ?? this.zoneId,
    label: label.present ? label.value : this.label,
    pax: pax ?? this.pax,
    active: active ?? this.active,
    status: status ?? this.status,
    openAmount: openAmount ?? this.openAmount,
    readyCount: readyCount ?? this.readyCount,
    lastActorId: lastActorId.present ? lastActorId.value : this.lastActorId,
  );
  VenueTable copyWithCompanion(VenueTablesCompanion data) {
    return VenueTable(
      id: data.id.present ? data.id.value : this.id,
      zoneId: data.zoneId.present ? data.zoneId.value : this.zoneId,
      label: data.label.present ? data.label.value : this.label,
      pax: data.pax.present ? data.pax.value : this.pax,
      active: data.active.present ? data.active.value : this.active,
      status: data.status.present ? data.status.value : this.status,
      openAmount: data.openAmount.present
          ? data.openAmount.value
          : this.openAmount,
      readyCount: data.readyCount.present
          ? data.readyCount.value
          : this.readyCount,
      lastActorId: data.lastActorId.present
          ? data.lastActorId.value
          : this.lastActorId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VenueTable(')
          ..write('id: $id, ')
          ..write('zoneId: $zoneId, ')
          ..write('label: $label, ')
          ..write('pax: $pax, ')
          ..write('active: $active, ')
          ..write('status: $status, ')
          ..write('openAmount: $openAmount, ')
          ..write('readyCount: $readyCount, ')
          ..write('lastActorId: $lastActorId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    zoneId,
    label,
    pax,
    active,
    status,
    openAmount,
    readyCount,
    lastActorId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VenueTable &&
          other.id == this.id &&
          other.zoneId == this.zoneId &&
          other.label == this.label &&
          other.pax == this.pax &&
          other.active == this.active &&
          other.status == this.status &&
          other.openAmount == this.openAmount &&
          other.readyCount == this.readyCount &&
          other.lastActorId == this.lastActorId);
}

class VenueTablesCompanion extends UpdateCompanion<VenueTable> {
  final Value<String> id;
  final Value<String> zoneId;
  final Value<String?> label;
  final Value<int> pax;
  final Value<bool> active;
  final Value<String> status;
  final Value<int> openAmount;
  final Value<int> readyCount;
  final Value<String?> lastActorId;
  final Value<int> rowid;
  const VenueTablesCompanion({
    this.id = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.label = const Value.absent(),
    this.pax = const Value.absent(),
    this.active = const Value.absent(),
    this.status = const Value.absent(),
    this.openAmount = const Value.absent(),
    this.readyCount = const Value.absent(),
    this.lastActorId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VenueTablesCompanion.insert({
    required String id,
    required String zoneId,
    this.label = const Value.absent(),
    this.pax = const Value.absent(),
    this.active = const Value.absent(),
    this.status = const Value.absent(),
    this.openAmount = const Value.absent(),
    this.readyCount = const Value.absent(),
    this.lastActorId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       zoneId = Value(zoneId);
  static Insertable<VenueTable> custom({
    Expression<String>? id,
    Expression<String>? zoneId,
    Expression<String>? label,
    Expression<int>? pax,
    Expression<bool>? active,
    Expression<String>? status,
    Expression<int>? openAmount,
    Expression<int>? readyCount,
    Expression<String>? lastActorId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (zoneId != null) 'zone_id': zoneId,
      if (label != null) 'label': label,
      if (pax != null) 'pax': pax,
      if (active != null) 'active': active,
      if (status != null) 'status': status,
      if (openAmount != null) 'open_amount': openAmount,
      if (readyCount != null) 'ready_count': readyCount,
      if (lastActorId != null) 'last_actor_id': lastActorId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VenueTablesCompanion copyWith({
    Value<String>? id,
    Value<String>? zoneId,
    Value<String?>? label,
    Value<int>? pax,
    Value<bool>? active,
    Value<String>? status,
    Value<int>? openAmount,
    Value<int>? readyCount,
    Value<String?>? lastActorId,
    Value<int>? rowid,
  }) {
    return VenueTablesCompanion(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      label: label ?? this.label,
      pax: pax ?? this.pax,
      active: active ?? this.active,
      status: status ?? this.status,
      openAmount: openAmount ?? this.openAmount,
      readyCount: readyCount ?? this.readyCount,
      lastActorId: lastActorId ?? this.lastActorId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (zoneId.present) {
      map['zone_id'] = Variable<String>(zoneId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (pax.present) {
      map['pax'] = Variable<int>(pax.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (openAmount.present) {
      map['open_amount'] = Variable<int>(openAmount.value);
    }
    if (readyCount.present) {
      map['ready_count'] = Variable<int>(readyCount.value);
    }
    if (lastActorId.present) {
      map['last_actor_id'] = Variable<String>(lastActorId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VenueTablesCompanion(')
          ..write('id: $id, ')
          ..write('zoneId: $zoneId, ')
          ..write('label: $label, ')
          ..write('pax: $pax, ')
          ..write('active: $active, ')
          ..write('status: $status, ')
          ..write('openAmount: $openAmount, ')
          ..write('readyCount: $readyCount, ')
          ..write('lastActorId: $lastActorId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuCategoriesTable extends MenuCategories
    with TableInfo<$MenuCategoriesTable, MenuCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MenuCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $MenuCategoriesTable createAlias(String alias) {
    return $MenuCategoriesTable(attachedDatabase, alias);
  }
}

class MenuCategory extends DataClass implements Insertable<MenuCategory> {
  final String id;
  final String name;
  final int sortOrder;
  const MenuCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  MenuCategoriesCompanion toCompanion(bool nullToAbsent) {
    return MenuCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory MenuCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  MenuCategory copyWith({String? id, String? name, int? sortOrder}) =>
      MenuCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  MenuCategory copyWithCompanion(MenuCategoriesCompanion data) {
    return MenuCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class MenuCategoriesCompanion extends UpdateCompanion<MenuCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const MenuCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuCategoriesCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<MenuCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return MenuCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuItemsTable extends MenuItems
    with TableInfo<$MenuItemsTable, MenuItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stationMeta = const VerificationMeta(
    'station',
  );
  @override
  late final GeneratedColumn<String> station = GeneratedColumn<String>(
    'station',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _basePriceMeta = const VerificationMeta(
    'basePrice',
  );
  @override
  late final GeneratedColumn<int> basePrice = GeneratedColumn<int>(
    'base_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prepTimeMeta = const VerificationMeta(
    'prepTime',
  );
  @override
  late final GeneratedColumn<int> prepTime = GeneratedColumn<int>(
    'prep_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _variantsJsonMeta = const VerificationMeta(
    'variantsJson',
  );
  @override
  late final GeneratedColumn<String> variantsJson = GeneratedColumn<String>(
    'variants_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _modifierGroupIdsJsonMeta =
      const VerificationMeta('modifierGroupIdsJson');
  @override
  late final GeneratedColumn<String> modifierGroupIdsJson =
      GeneratedColumn<String>(
        'modifier_group_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _allergensJsonMeta = const VerificationMeta(
    'allergensJson',
  );
  @override
  late final GeneratedColumn<String> allergensJson = GeneratedColumn<String>(
    'allergens_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _dietaryJsonMeta = const VerificationMeta(
    'dietaryJson',
  );
  @override
  late final GeneratedColumn<String> dietaryJson = GeneratedColumn<String>(
    'dietary_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _unavailableMeta = const VerificationMeta(
    'unavailable',
  );
  @override
  late final GeneratedColumn<bool> unavailable = GeneratedColumn<bool>(
    'unavailable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("unavailable" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _stockCountMeta = const VerificationMeta(
    'stockCount',
  );
  @override
  late final GeneratedColumn<int> stockCount = GeneratedColumn<int>(
    'stock_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoEightySixAtZeroMeta =
      const VerificationMeta('autoEightySixAtZero');
  @override
  late final GeneratedColumn<bool> autoEightySixAtZero = GeneratedColumn<bool>(
    'auto_eighty_six_at_zero',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_eighty_six_at_zero" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    categoryId,
    station,
    description,
    basePrice,
    prepTime,
    variantsJson,
    modifierGroupIdsJson,
    allergensJson,
    dietaryJson,
    unavailable,
    stockCount,
    autoEightySixAtZero,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('station')) {
      context.handle(
        _stationMeta,
        station.isAcceptableOrUnknown(data['station']!, _stationMeta),
      );
    } else if (isInserting) {
      context.missing(_stationMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('base_price')) {
      context.handle(
        _basePriceMeta,
        basePrice.isAcceptableOrUnknown(data['base_price']!, _basePriceMeta),
      );
    } else if (isInserting) {
      context.missing(_basePriceMeta);
    }
    if (data.containsKey('prep_time')) {
      context.handle(
        _prepTimeMeta,
        prepTime.isAcceptableOrUnknown(data['prep_time']!, _prepTimeMeta),
      );
    }
    if (data.containsKey('variants_json')) {
      context.handle(
        _variantsJsonMeta,
        variantsJson.isAcceptableOrUnknown(
          data['variants_json']!,
          _variantsJsonMeta,
        ),
      );
    }
    if (data.containsKey('modifier_group_ids_json')) {
      context.handle(
        _modifierGroupIdsJsonMeta,
        modifierGroupIdsJson.isAcceptableOrUnknown(
          data['modifier_group_ids_json']!,
          _modifierGroupIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('allergens_json')) {
      context.handle(
        _allergensJsonMeta,
        allergensJson.isAcceptableOrUnknown(
          data['allergens_json']!,
          _allergensJsonMeta,
        ),
      );
    }
    if (data.containsKey('dietary_json')) {
      context.handle(
        _dietaryJsonMeta,
        dietaryJson.isAcceptableOrUnknown(
          data['dietary_json']!,
          _dietaryJsonMeta,
        ),
      );
    }
    if (data.containsKey('unavailable')) {
      context.handle(
        _unavailableMeta,
        unavailable.isAcceptableOrUnknown(
          data['unavailable']!,
          _unavailableMeta,
        ),
      );
    }
    if (data.containsKey('stock_count')) {
      context.handle(
        _stockCountMeta,
        stockCount.isAcceptableOrUnknown(data['stock_count']!, _stockCountMeta),
      );
    }
    if (data.containsKey('auto_eighty_six_at_zero')) {
      context.handle(
        _autoEightySixAtZeroMeta,
        autoEightySixAtZero.isAcceptableOrUnknown(
          data['auto_eighty_six_at_zero']!,
          _autoEightySixAtZeroMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MenuItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      station: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      basePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_price'],
      )!,
      prepTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prep_time'],
      )!,
      variantsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variants_json'],
      )!,
      modifierGroupIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modifier_group_ids_json'],
      )!,
      allergensJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergens_json'],
      )!,
      dietaryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dietary_json'],
      )!,
      unavailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}unavailable'],
      )!,
      stockCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_count'],
      ),
      autoEightySixAtZero: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_eighty_six_at_zero'],
      )!,
    );
  }

  @override
  $MenuItemsTable createAlias(String alias) {
    return $MenuItemsTable(attachedDatabase, alias);
  }
}

class MenuItem extends DataClass implements Insertable<MenuItem> {
  final String id;
  final String name;
  final String categoryId;
  final String station;
  final String description;
  final int basePrice;
  final int prepTime;
  final String variantsJson;
  final String modifierGroupIdsJson;
  final String allergensJson;
  final String dietaryJson;
  final bool unavailable;
  final int? stockCount;
  final bool autoEightySixAtZero;
  const MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.station,
    required this.description,
    required this.basePrice,
    required this.prepTime,
    required this.variantsJson,
    required this.modifierGroupIdsJson,
    required this.allergensJson,
    required this.dietaryJson,
    required this.unavailable,
    this.stockCount,
    required this.autoEightySixAtZero,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category_id'] = Variable<String>(categoryId);
    map['station'] = Variable<String>(station);
    map['description'] = Variable<String>(description);
    map['base_price'] = Variable<int>(basePrice);
    map['prep_time'] = Variable<int>(prepTime);
    map['variants_json'] = Variable<String>(variantsJson);
    map['modifier_group_ids_json'] = Variable<String>(modifierGroupIdsJson);
    map['allergens_json'] = Variable<String>(allergensJson);
    map['dietary_json'] = Variable<String>(dietaryJson);
    map['unavailable'] = Variable<bool>(unavailable);
    if (!nullToAbsent || stockCount != null) {
      map['stock_count'] = Variable<int>(stockCount);
    }
    map['auto_eighty_six_at_zero'] = Variable<bool>(autoEightySixAtZero);
    return map;
  }

  MenuItemsCompanion toCompanion(bool nullToAbsent) {
    return MenuItemsCompanion(
      id: Value(id),
      name: Value(name),
      categoryId: Value(categoryId),
      station: Value(station),
      description: Value(description),
      basePrice: Value(basePrice),
      prepTime: Value(prepTime),
      variantsJson: Value(variantsJson),
      modifierGroupIdsJson: Value(modifierGroupIdsJson),
      allergensJson: Value(allergensJson),
      dietaryJson: Value(dietaryJson),
      unavailable: Value(unavailable),
      stockCount: stockCount == null && nullToAbsent
          ? const Value.absent()
          : Value(stockCount),
      autoEightySixAtZero: Value(autoEightySixAtZero),
    );
  }

  factory MenuItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuItem(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      station: serializer.fromJson<String>(json['station']),
      description: serializer.fromJson<String>(json['description']),
      basePrice: serializer.fromJson<int>(json['basePrice']),
      prepTime: serializer.fromJson<int>(json['prepTime']),
      variantsJson: serializer.fromJson<String>(json['variantsJson']),
      modifierGroupIdsJson: serializer.fromJson<String>(
        json['modifierGroupIdsJson'],
      ),
      allergensJson: serializer.fromJson<String>(json['allergensJson']),
      dietaryJson: serializer.fromJson<String>(json['dietaryJson']),
      unavailable: serializer.fromJson<bool>(json['unavailable']),
      stockCount: serializer.fromJson<int?>(json['stockCount']),
      autoEightySixAtZero: serializer.fromJson<bool>(
        json['autoEightySixAtZero'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<String>(categoryId),
      'station': serializer.toJson<String>(station),
      'description': serializer.toJson<String>(description),
      'basePrice': serializer.toJson<int>(basePrice),
      'prepTime': serializer.toJson<int>(prepTime),
      'variantsJson': serializer.toJson<String>(variantsJson),
      'modifierGroupIdsJson': serializer.toJson<String>(modifierGroupIdsJson),
      'allergensJson': serializer.toJson<String>(allergensJson),
      'dietaryJson': serializer.toJson<String>(dietaryJson),
      'unavailable': serializer.toJson<bool>(unavailable),
      'stockCount': serializer.toJson<int?>(stockCount),
      'autoEightySixAtZero': serializer.toJson<bool>(autoEightySixAtZero),
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? station,
    String? description,
    int? basePrice,
    int? prepTime,
    String? variantsJson,
    String? modifierGroupIdsJson,
    String? allergensJson,
    String? dietaryJson,
    bool? unavailable,
    Value<int?> stockCount = const Value.absent(),
    bool? autoEightySixAtZero,
  }) => MenuItem(
    id: id ?? this.id,
    name: name ?? this.name,
    categoryId: categoryId ?? this.categoryId,
    station: station ?? this.station,
    description: description ?? this.description,
    basePrice: basePrice ?? this.basePrice,
    prepTime: prepTime ?? this.prepTime,
    variantsJson: variantsJson ?? this.variantsJson,
    modifierGroupIdsJson: modifierGroupIdsJson ?? this.modifierGroupIdsJson,
    allergensJson: allergensJson ?? this.allergensJson,
    dietaryJson: dietaryJson ?? this.dietaryJson,
    unavailable: unavailable ?? this.unavailable,
    stockCount: stockCount.present ? stockCount.value : this.stockCount,
    autoEightySixAtZero: autoEightySixAtZero ?? this.autoEightySixAtZero,
  );
  MenuItem copyWithCompanion(MenuItemsCompanion data) {
    return MenuItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      station: data.station.present ? data.station.value : this.station,
      description: data.description.present
          ? data.description.value
          : this.description,
      basePrice: data.basePrice.present ? data.basePrice.value : this.basePrice,
      prepTime: data.prepTime.present ? data.prepTime.value : this.prepTime,
      variantsJson: data.variantsJson.present
          ? data.variantsJson.value
          : this.variantsJson,
      modifierGroupIdsJson: data.modifierGroupIdsJson.present
          ? data.modifierGroupIdsJson.value
          : this.modifierGroupIdsJson,
      allergensJson: data.allergensJson.present
          ? data.allergensJson.value
          : this.allergensJson,
      dietaryJson: data.dietaryJson.present
          ? data.dietaryJson.value
          : this.dietaryJson,
      unavailable: data.unavailable.present
          ? data.unavailable.value
          : this.unavailable,
      stockCount: data.stockCount.present
          ? data.stockCount.value
          : this.stockCount,
      autoEightySixAtZero: data.autoEightySixAtZero.present
          ? data.autoEightySixAtZero.value
          : this.autoEightySixAtZero,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('station: $station, ')
          ..write('description: $description, ')
          ..write('basePrice: $basePrice, ')
          ..write('prepTime: $prepTime, ')
          ..write('variantsJson: $variantsJson, ')
          ..write('modifierGroupIdsJson: $modifierGroupIdsJson, ')
          ..write('allergensJson: $allergensJson, ')
          ..write('dietaryJson: $dietaryJson, ')
          ..write('unavailable: $unavailable, ')
          ..write('stockCount: $stockCount, ')
          ..write('autoEightySixAtZero: $autoEightySixAtZero')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    categoryId,
    station,
    description,
    basePrice,
    prepTime,
    variantsJson,
    modifierGroupIdsJson,
    allergensJson,
    dietaryJson,
    unavailable,
    stockCount,
    autoEightySixAtZero,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.station == this.station &&
          other.description == this.description &&
          other.basePrice == this.basePrice &&
          other.prepTime == this.prepTime &&
          other.variantsJson == this.variantsJson &&
          other.modifierGroupIdsJson == this.modifierGroupIdsJson &&
          other.allergensJson == this.allergensJson &&
          other.dietaryJson == this.dietaryJson &&
          other.unavailable == this.unavailable &&
          other.stockCount == this.stockCount &&
          other.autoEightySixAtZero == this.autoEightySixAtZero);
}

class MenuItemsCompanion extends UpdateCompanion<MenuItem> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> categoryId;
  final Value<String> station;
  final Value<String> description;
  final Value<int> basePrice;
  final Value<int> prepTime;
  final Value<String> variantsJson;
  final Value<String> modifierGroupIdsJson;
  final Value<String> allergensJson;
  final Value<String> dietaryJson;
  final Value<bool> unavailable;
  final Value<int?> stockCount;
  final Value<bool> autoEightySixAtZero;
  final Value<int> rowid;
  const MenuItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.station = const Value.absent(),
    this.description = const Value.absent(),
    this.basePrice = const Value.absent(),
    this.prepTime = const Value.absent(),
    this.variantsJson = const Value.absent(),
    this.modifierGroupIdsJson = const Value.absent(),
    this.allergensJson = const Value.absent(),
    this.dietaryJson = const Value.absent(),
    this.unavailable = const Value.absent(),
    this.stockCount = const Value.absent(),
    this.autoEightySixAtZero = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuItemsCompanion.insert({
    required String id,
    required String name,
    required String categoryId,
    required String station,
    this.description = const Value.absent(),
    required int basePrice,
    this.prepTime = const Value.absent(),
    this.variantsJson = const Value.absent(),
    this.modifierGroupIdsJson = const Value.absent(),
    this.allergensJson = const Value.absent(),
    this.dietaryJson = const Value.absent(),
    this.unavailable = const Value.absent(),
    this.stockCount = const Value.absent(),
    this.autoEightySixAtZero = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       categoryId = Value(categoryId),
       station = Value(station),
       basePrice = Value(basePrice);
  static Insertable<MenuItem> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? categoryId,
    Expression<String>? station,
    Expression<String>? description,
    Expression<int>? basePrice,
    Expression<int>? prepTime,
    Expression<String>? variantsJson,
    Expression<String>? modifierGroupIdsJson,
    Expression<String>? allergensJson,
    Expression<String>? dietaryJson,
    Expression<bool>? unavailable,
    Expression<int>? stockCount,
    Expression<bool>? autoEightySixAtZero,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (station != null) 'station': station,
      if (description != null) 'description': description,
      if (basePrice != null) 'base_price': basePrice,
      if (prepTime != null) 'prep_time': prepTime,
      if (variantsJson != null) 'variants_json': variantsJson,
      if (modifierGroupIdsJson != null)
        'modifier_group_ids_json': modifierGroupIdsJson,
      if (allergensJson != null) 'allergens_json': allergensJson,
      if (dietaryJson != null) 'dietary_json': dietaryJson,
      if (unavailable != null) 'unavailable': unavailable,
      if (stockCount != null) 'stock_count': stockCount,
      if (autoEightySixAtZero != null)
        'auto_eighty_six_at_zero': autoEightySixAtZero,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? categoryId,
    Value<String>? station,
    Value<String>? description,
    Value<int>? basePrice,
    Value<int>? prepTime,
    Value<String>? variantsJson,
    Value<String>? modifierGroupIdsJson,
    Value<String>? allergensJson,
    Value<String>? dietaryJson,
    Value<bool>? unavailable,
    Value<int?>? stockCount,
    Value<bool>? autoEightySixAtZero,
    Value<int>? rowid,
  }) {
    return MenuItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      station: station ?? this.station,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      prepTime: prepTime ?? this.prepTime,
      variantsJson: variantsJson ?? this.variantsJson,
      modifierGroupIdsJson: modifierGroupIdsJson ?? this.modifierGroupIdsJson,
      allergensJson: allergensJson ?? this.allergensJson,
      dietaryJson: dietaryJson ?? this.dietaryJson,
      unavailable: unavailable ?? this.unavailable,
      stockCount: stockCount ?? this.stockCount,
      autoEightySixAtZero: autoEightySixAtZero ?? this.autoEightySixAtZero,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (station.present) {
      map['station'] = Variable<String>(station.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (basePrice.present) {
      map['base_price'] = Variable<int>(basePrice.value);
    }
    if (prepTime.present) {
      map['prep_time'] = Variable<int>(prepTime.value);
    }
    if (variantsJson.present) {
      map['variants_json'] = Variable<String>(variantsJson.value);
    }
    if (modifierGroupIdsJson.present) {
      map['modifier_group_ids_json'] = Variable<String>(
        modifierGroupIdsJson.value,
      );
    }
    if (allergensJson.present) {
      map['allergens_json'] = Variable<String>(allergensJson.value);
    }
    if (dietaryJson.present) {
      map['dietary_json'] = Variable<String>(dietaryJson.value);
    }
    if (unavailable.present) {
      map['unavailable'] = Variable<bool>(unavailable.value);
    }
    if (stockCount.present) {
      map['stock_count'] = Variable<int>(stockCount.value);
    }
    if (autoEightySixAtZero.present) {
      map['auto_eighty_six_at_zero'] = Variable<bool>(
        autoEightySixAtZero.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('station: $station, ')
          ..write('description: $description, ')
          ..write('basePrice: $basePrice, ')
          ..write('prepTime: $prepTime, ')
          ..write('variantsJson: $variantsJson, ')
          ..write('modifierGroupIdsJson: $modifierGroupIdsJson, ')
          ..write('allergensJson: $allergensJson, ')
          ..write('dietaryJson: $dietaryJson, ')
          ..write('unavailable: $unavailable, ')
          ..write('stockCount: $stockCount, ')
          ..write('autoEightySixAtZero: $autoEightySixAtZero, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModifierGroupsTable extends ModifierGroups
    with TableInfo<$ModifierGroupsTable, ModifierGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModifierGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requiredMeta = const VerificationMeta(
    'required',
  );
  @override
  late final GeneratedColumn<bool> required = GeneratedColumn<bool>(
    'required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("required" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _multiMeta = const VerificationMeta('multi');
  @override
  late final GeneratedColumn<bool> multi = GeneratedColumn<bool>(
    'multi',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("multi" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    required,
    multi,
    optionsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'modifier_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModifierGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('required')) {
      context.handle(
        _requiredMeta,
        required.isAcceptableOrUnknown(data['required']!, _requiredMeta),
      );
    }
    if (data.containsKey('multi')) {
      context.handle(
        _multiMeta,
        multi.isAcceptableOrUnknown(data['multi']!, _multiMeta),
      );
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModifierGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModifierGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      required: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}required'],
      )!,
      multi: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}multi'],
      )!,
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
    );
  }

  @override
  $ModifierGroupsTable createAlias(String alias) {
    return $ModifierGroupsTable(attachedDatabase, alias);
  }
}

class ModifierGroup extends DataClass implements Insertable<ModifierGroup> {
  final String id;
  final String name;
  final bool required;
  final bool multi;
  final String optionsJson;
  const ModifierGroup({
    required this.id,
    required this.name,
    required this.required,
    required this.multi,
    required this.optionsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['required'] = Variable<bool>(required);
    map['multi'] = Variable<bool>(multi);
    map['options_json'] = Variable<String>(optionsJson);
    return map;
  }

  ModifierGroupsCompanion toCompanion(bool nullToAbsent) {
    return ModifierGroupsCompanion(
      id: Value(id),
      name: Value(name),
      required: Value(required),
      multi: Value(multi),
      optionsJson: Value(optionsJson),
    );
  }

  factory ModifierGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModifierGroup(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      required: serializer.fromJson<bool>(json['required']),
      multi: serializer.fromJson<bool>(json['multi']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'required': serializer.toJson<bool>(required),
      'multi': serializer.toJson<bool>(multi),
      'optionsJson': serializer.toJson<String>(optionsJson),
    };
  }

  ModifierGroup copyWith({
    String? id,
    String? name,
    bool? required,
    bool? multi,
    String? optionsJson,
  }) => ModifierGroup(
    id: id ?? this.id,
    name: name ?? this.name,
    required: required ?? this.required,
    multi: multi ?? this.multi,
    optionsJson: optionsJson ?? this.optionsJson,
  );
  ModifierGroup copyWithCompanion(ModifierGroupsCompanion data) {
    return ModifierGroup(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      required: data.required.present ? data.required.value : this.required,
      multi: data.multi.present ? data.multi.value : this.multi,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModifierGroup(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('required: $required, ')
          ..write('multi: $multi, ')
          ..write('optionsJson: $optionsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, required, multi, optionsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModifierGroup &&
          other.id == this.id &&
          other.name == this.name &&
          other.required == this.required &&
          other.multi == this.multi &&
          other.optionsJson == this.optionsJson);
}

class ModifierGroupsCompanion extends UpdateCompanion<ModifierGroup> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> required;
  final Value<bool> multi;
  final Value<String> optionsJson;
  final Value<int> rowid;
  const ModifierGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.required = const Value.absent(),
    this.multi = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModifierGroupsCompanion.insert({
    required String id,
    required String name,
    this.required = const Value.absent(),
    this.multi = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ModifierGroup> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? required,
    Expression<bool>? multi,
    Expression<String>? optionsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (required != null) 'required': required,
      if (multi != null) 'multi': multi,
      if (optionsJson != null) 'options_json': optionsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModifierGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? required,
    Value<bool>? multi,
    Value<String>? optionsJson,
    Value<int>? rowid,
  }) {
    return ModifierGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      required: required ?? this.required,
      multi: multi ?? this.multi,
      optionsJson: optionsJson ?? this.optionsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (required.present) {
      map['required'] = Variable<bool>(required.value);
    }
    if (multi.present) {
      map['multi'] = Variable<bool>(multi.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModifierGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('required: $required, ')
          ..write('multi: $multi, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TicketsTable extends Tickets with TableInfo<$TicketsTable, Ticket> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TicketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tableIdMeta = const VerificationMeta(
    'tableId',
  );
  @override
  late final GeneratedColumn<String> tableId = GeneratedColumn<String>(
    'table_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantNameMeta = const VerificationMeta(
    'variantName',
  );
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
    'variant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _courseMeta = const VerificationMeta('course');
  @override
  late final GeneratedColumn<String> course = GeneratedColumn<String>(
    'course',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stationMeta = const VerificationMeta(
    'station',
  );
  @override
  late final GeneratedColumn<String> station = GeneratedColumn<String>(
    'station',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _modifiersJsonMeta = const VerificationMeta(
    'modifiersJson',
  );
  @override
  late final GeneratedColumn<String> modifiersJson = GeneratedColumn<String>(
    'modifiers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _specialInstructionsMeta =
      const VerificationMeta('specialInstructions');
  @override
  late final GeneratedColumn<String> specialInstructions =
      GeneratedColumn<String>(
        'special_instructions',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voidReasonMeta = const VerificationMeta(
    'voidReason',
  );
  @override
  late final GeneratedColumn<String> voidReason = GeneratedColumn<String>(
    'void_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidApprovedByMeta = const VerificationMeta(
    'voidApprovedBy',
  );
  @override
  late final GeneratedColumn<String> voidApprovedBy = GeneratedColumn<String>(
    'void_approved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByUserIdMeta = const VerificationMeta(
    'createdByUserId',
  );
  @override
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
    'created_by_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tableId,
    itemId,
    name,
    variantName,
    course,
    station,
    qty,
    modifiersJson,
    specialInstructions,
    price,
    status,
    sentAt,
    voidReason,
    voidApprovedBy,
    createdByUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tickets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ticket> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('table_id')) {
      context.handle(
        _tableIdMeta,
        tableId.isAcceptableOrUnknown(data['table_id']!, _tableIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tableIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('variant_name')) {
      context.handle(
        _variantNameMeta,
        variantName.isAcceptableOrUnknown(
          data['variant_name']!,
          _variantNameMeta,
        ),
      );
    }
    if (data.containsKey('course')) {
      context.handle(
        _courseMeta,
        course.isAcceptableOrUnknown(data['course']!, _courseMeta),
      );
    } else if (isInserting) {
      context.missing(_courseMeta);
    }
    if (data.containsKey('station')) {
      context.handle(
        _stationMeta,
        station.isAcceptableOrUnknown(data['station']!, _stationMeta),
      );
    } else if (isInserting) {
      context.missing(_stationMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    }
    if (data.containsKey('modifiers_json')) {
      context.handle(
        _modifiersJsonMeta,
        modifiersJson.isAcceptableOrUnknown(
          data['modifiers_json']!,
          _modifiersJsonMeta,
        ),
      );
    }
    if (data.containsKey('special_instructions')) {
      context.handle(
        _specialInstructionsMeta,
        specialInstructions.isAcceptableOrUnknown(
          data['special_instructions']!,
          _specialInstructionsMeta,
        ),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('void_reason')) {
      context.handle(
        _voidReasonMeta,
        voidReason.isAcceptableOrUnknown(data['void_reason']!, _voidReasonMeta),
      );
    }
    if (data.containsKey('void_approved_by')) {
      context.handle(
        _voidApprovedByMeta,
        voidApprovedBy.isAcceptableOrUnknown(
          data['void_approved_by']!,
          _voidApprovedByMeta,
        ),
      );
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
        _createdByUserIdMeta,
        createdByUserId.isAcceptableOrUnknown(
          data['created_by_user_id']!,
          _createdByUserIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ticket map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ticket(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      variantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_name'],
      )!,
      course: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course'],
      )!,
      station: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      modifiersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modifiers_json'],
      )!,
      specialInstructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}special_instructions'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
      voidReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_reason'],
      ),
      voidApprovedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_approved_by'],
      ),
      createdByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_user_id'],
      ),
    );
  }

  @override
  $TicketsTable createAlias(String alias) {
    return $TicketsTable(attachedDatabase, alias);
  }
}

class Ticket extends DataClass implements Insertable<Ticket> {
  final String id;
  final String tableId;
  final String itemId;
  final String name;
  final String variantName;
  final String course;
  final String station;
  final int qty;
  final String modifiersJson;
  final String? specialInstructions;
  final int price;
  final String status;
  final DateTime sentAt;
  final String? voidReason;
  final String? voidApprovedBy;
  final String? createdByUserId;
  const Ticket({
    required this.id,
    required this.tableId,
    required this.itemId,
    required this.name,
    required this.variantName,
    required this.course,
    required this.station,
    required this.qty,
    required this.modifiersJson,
    this.specialInstructions,
    required this.price,
    required this.status,
    required this.sentAt,
    this.voidReason,
    this.voidApprovedBy,
    this.createdByUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['table_id'] = Variable<String>(tableId);
    map['item_id'] = Variable<String>(itemId);
    map['name'] = Variable<String>(name);
    map['variant_name'] = Variable<String>(variantName);
    map['course'] = Variable<String>(course);
    map['station'] = Variable<String>(station);
    map['qty'] = Variable<int>(qty);
    map['modifiers_json'] = Variable<String>(modifiersJson);
    if (!nullToAbsent || specialInstructions != null) {
      map['special_instructions'] = Variable<String>(specialInstructions);
    }
    map['price'] = Variable<int>(price);
    map['status'] = Variable<String>(status);
    map['sent_at'] = Variable<DateTime>(sentAt);
    if (!nullToAbsent || voidReason != null) {
      map['void_reason'] = Variable<String>(voidReason);
    }
    if (!nullToAbsent || voidApprovedBy != null) {
      map['void_approved_by'] = Variable<String>(voidApprovedBy);
    }
    if (!nullToAbsent || createdByUserId != null) {
      map['created_by_user_id'] = Variable<String>(createdByUserId);
    }
    return map;
  }

  TicketsCompanion toCompanion(bool nullToAbsent) {
    return TicketsCompanion(
      id: Value(id),
      tableId: Value(tableId),
      itemId: Value(itemId),
      name: Value(name),
      variantName: Value(variantName),
      course: Value(course),
      station: Value(station),
      qty: Value(qty),
      modifiersJson: Value(modifiersJson),
      specialInstructions: specialInstructions == null && nullToAbsent
          ? const Value.absent()
          : Value(specialInstructions),
      price: Value(price),
      status: Value(status),
      sentAt: Value(sentAt),
      voidReason: voidReason == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReason),
      voidApprovedBy: voidApprovedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(voidApprovedBy),
      createdByUserId: createdByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserId),
    );
  }

  factory Ticket.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ticket(
      id: serializer.fromJson<String>(json['id']),
      tableId: serializer.fromJson<String>(json['tableId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      name: serializer.fromJson<String>(json['name']),
      variantName: serializer.fromJson<String>(json['variantName']),
      course: serializer.fromJson<String>(json['course']),
      station: serializer.fromJson<String>(json['station']),
      qty: serializer.fromJson<int>(json['qty']),
      modifiersJson: serializer.fromJson<String>(json['modifiersJson']),
      specialInstructions: serializer.fromJson<String?>(
        json['specialInstructions'],
      ),
      price: serializer.fromJson<int>(json['price']),
      status: serializer.fromJson<String>(json['status']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      voidReason: serializer.fromJson<String?>(json['voidReason']),
      voidApprovedBy: serializer.fromJson<String?>(json['voidApprovedBy']),
      createdByUserId: serializer.fromJson<String?>(json['createdByUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tableId': serializer.toJson<String>(tableId),
      'itemId': serializer.toJson<String>(itemId),
      'name': serializer.toJson<String>(name),
      'variantName': serializer.toJson<String>(variantName),
      'course': serializer.toJson<String>(course),
      'station': serializer.toJson<String>(station),
      'qty': serializer.toJson<int>(qty),
      'modifiersJson': serializer.toJson<String>(modifiersJson),
      'specialInstructions': serializer.toJson<String?>(specialInstructions),
      'price': serializer.toJson<int>(price),
      'status': serializer.toJson<String>(status),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'voidReason': serializer.toJson<String?>(voidReason),
      'voidApprovedBy': serializer.toJson<String?>(voidApprovedBy),
      'createdByUserId': serializer.toJson<String?>(createdByUserId),
    };
  }

  Ticket copyWith({
    String? id,
    String? tableId,
    String? itemId,
    String? name,
    String? variantName,
    String? course,
    String? station,
    int? qty,
    String? modifiersJson,
    Value<String?> specialInstructions = const Value.absent(),
    int? price,
    String? status,
    DateTime? sentAt,
    Value<String?> voidReason = const Value.absent(),
    Value<String?> voidApprovedBy = const Value.absent(),
    Value<String?> createdByUserId = const Value.absent(),
  }) => Ticket(
    id: id ?? this.id,
    tableId: tableId ?? this.tableId,
    itemId: itemId ?? this.itemId,
    name: name ?? this.name,
    variantName: variantName ?? this.variantName,
    course: course ?? this.course,
    station: station ?? this.station,
    qty: qty ?? this.qty,
    modifiersJson: modifiersJson ?? this.modifiersJson,
    specialInstructions: specialInstructions.present
        ? specialInstructions.value
        : this.specialInstructions,
    price: price ?? this.price,
    status: status ?? this.status,
    sentAt: sentAt ?? this.sentAt,
    voidReason: voidReason.present ? voidReason.value : this.voidReason,
    voidApprovedBy: voidApprovedBy.present
        ? voidApprovedBy.value
        : this.voidApprovedBy,
    createdByUserId: createdByUserId.present
        ? createdByUserId.value
        : this.createdByUserId,
  );
  Ticket copyWithCompanion(TicketsCompanion data) {
    return Ticket(
      id: data.id.present ? data.id.value : this.id,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      name: data.name.present ? data.name.value : this.name,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      course: data.course.present ? data.course.value : this.course,
      station: data.station.present ? data.station.value : this.station,
      qty: data.qty.present ? data.qty.value : this.qty,
      modifiersJson: data.modifiersJson.present
          ? data.modifiersJson.value
          : this.modifiersJson,
      specialInstructions: data.specialInstructions.present
          ? data.specialInstructions.value
          : this.specialInstructions,
      price: data.price.present ? data.price.value : this.price,
      status: data.status.present ? data.status.value : this.status,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      voidReason: data.voidReason.present
          ? data.voidReason.value
          : this.voidReason,
      voidApprovedBy: data.voidApprovedBy.present
          ? data.voidApprovedBy.value
          : this.voidApprovedBy,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ticket(')
          ..write('id: $id, ')
          ..write('tableId: $tableId, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('variantName: $variantName, ')
          ..write('course: $course, ')
          ..write('station: $station, ')
          ..write('qty: $qty, ')
          ..write('modifiersJson: $modifiersJson, ')
          ..write('specialInstructions: $specialInstructions, ')
          ..write('price: $price, ')
          ..write('status: $status, ')
          ..write('sentAt: $sentAt, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidApprovedBy: $voidApprovedBy, ')
          ..write('createdByUserId: $createdByUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tableId,
    itemId,
    name,
    variantName,
    course,
    station,
    qty,
    modifiersJson,
    specialInstructions,
    price,
    status,
    sentAt,
    voidReason,
    voidApprovedBy,
    createdByUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ticket &&
          other.id == this.id &&
          other.tableId == this.tableId &&
          other.itemId == this.itemId &&
          other.name == this.name &&
          other.variantName == this.variantName &&
          other.course == this.course &&
          other.station == this.station &&
          other.qty == this.qty &&
          other.modifiersJson == this.modifiersJson &&
          other.specialInstructions == this.specialInstructions &&
          other.price == this.price &&
          other.status == this.status &&
          other.sentAt == this.sentAt &&
          other.voidReason == this.voidReason &&
          other.voidApprovedBy == this.voidApprovedBy &&
          other.createdByUserId == this.createdByUserId);
}

class TicketsCompanion extends UpdateCompanion<Ticket> {
  final Value<String> id;
  final Value<String> tableId;
  final Value<String> itemId;
  final Value<String> name;
  final Value<String> variantName;
  final Value<String> course;
  final Value<String> station;
  final Value<int> qty;
  final Value<String> modifiersJson;
  final Value<String?> specialInstructions;
  final Value<int> price;
  final Value<String> status;
  final Value<DateTime> sentAt;
  final Value<String?> voidReason;
  final Value<String?> voidApprovedBy;
  final Value<String?> createdByUserId;
  final Value<int> rowid;
  const TicketsCompanion({
    this.id = const Value.absent(),
    this.tableId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.name = const Value.absent(),
    this.variantName = const Value.absent(),
    this.course = const Value.absent(),
    this.station = const Value.absent(),
    this.qty = const Value.absent(),
    this.modifiersJson = const Value.absent(),
    this.specialInstructions = const Value.absent(),
    this.price = const Value.absent(),
    this.status = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidApprovedBy = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TicketsCompanion.insert({
    required String id,
    required String tableId,
    required String itemId,
    required String name,
    this.variantName = const Value.absent(),
    required String course,
    required String station,
    this.qty = const Value.absent(),
    this.modifiersJson = const Value.absent(),
    this.specialInstructions = const Value.absent(),
    required int price,
    required String status,
    required DateTime sentAt,
    this.voidReason = const Value.absent(),
    this.voidApprovedBy = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tableId = Value(tableId),
       itemId = Value(itemId),
       name = Value(name),
       course = Value(course),
       station = Value(station),
       price = Value(price),
       status = Value(status),
       sentAt = Value(sentAt);
  static Insertable<Ticket> custom({
    Expression<String>? id,
    Expression<String>? tableId,
    Expression<String>? itemId,
    Expression<String>? name,
    Expression<String>? variantName,
    Expression<String>? course,
    Expression<String>? station,
    Expression<int>? qty,
    Expression<String>? modifiersJson,
    Expression<String>? specialInstructions,
    Expression<int>? price,
    Expression<String>? status,
    Expression<DateTime>? sentAt,
    Expression<String>? voidReason,
    Expression<String>? voidApprovedBy,
    Expression<String>? createdByUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tableId != null) 'table_id': tableId,
      if (itemId != null) 'item_id': itemId,
      if (name != null) 'name': name,
      if (variantName != null) 'variant_name': variantName,
      if (course != null) 'course': course,
      if (station != null) 'station': station,
      if (qty != null) 'qty': qty,
      if (modifiersJson != null) 'modifiers_json': modifiersJson,
      if (specialInstructions != null)
        'special_instructions': specialInstructions,
      if (price != null) 'price': price,
      if (status != null) 'status': status,
      if (sentAt != null) 'sent_at': sentAt,
      if (voidReason != null) 'void_reason': voidReason,
      if (voidApprovedBy != null) 'void_approved_by': voidApprovedBy,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TicketsCompanion copyWith({
    Value<String>? id,
    Value<String>? tableId,
    Value<String>? itemId,
    Value<String>? name,
    Value<String>? variantName,
    Value<String>? course,
    Value<String>? station,
    Value<int>? qty,
    Value<String>? modifiersJson,
    Value<String?>? specialInstructions,
    Value<int>? price,
    Value<String>? status,
    Value<DateTime>? sentAt,
    Value<String?>? voidReason,
    Value<String?>? voidApprovedBy,
    Value<String?>? createdByUserId,
    Value<int>? rowid,
  }) {
    return TicketsCompanion(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      variantName: variantName ?? this.variantName,
      course: course ?? this.course,
      station: station ?? this.station,
      qty: qty ?? this.qty,
      modifiersJson: modifiersJson ?? this.modifiersJson,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      price: price ?? this.price,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      voidReason: voidReason ?? this.voidReason,
      voidApprovedBy: voidApprovedBy ?? this.voidApprovedBy,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tableId.present) {
      map['table_id'] = Variable<String>(tableId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (course.present) {
      map['course'] = Variable<String>(course.value);
    }
    if (station.present) {
      map['station'] = Variable<String>(station.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (modifiersJson.present) {
      map['modifiers_json'] = Variable<String>(modifiersJson.value);
    }
    if (specialInstructions.present) {
      map['special_instructions'] = Variable<String>(specialInstructions.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    if (voidApprovedBy.present) {
      map['void_approved_by'] = Variable<String>(voidApprovedBy.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TicketsCompanion(')
          ..write('id: $id, ')
          ..write('tableId: $tableId, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('variantName: $variantName, ')
          ..write('course: $course, ')
          ..write('station: $station, ')
          ..write('qty: $qty, ')
          ..write('modifiersJson: $modifiersJson, ')
          ..write('specialInstructions: $specialInstructions, ')
          ..write('price: $price, ')
          ..write('status: $status, ')
          ..write('sentAt: $sentAt, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidApprovedBy: $voidApprovedBy, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  @override
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issuedAtMeta = const VerificationMeta(
    'issuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> issuedAt = GeneratedColumn<DateTime>(
    'issued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    token,
    userId,
    deviceId,
    issuedAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_issuedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {token};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      issuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issued_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String token;
  final String userId;
  final String deviceId;
  final DateTime issuedAt;
  final DateTime expiresAt;
  const Session({
    required this.token,
    required this.userId,
    required this.deviceId,
    required this.issuedAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['token'] = Variable<String>(token);
    map['user_id'] = Variable<String>(userId);
    map['device_id'] = Variable<String>(deviceId);
    map['issued_at'] = Variable<DateTime>(issuedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      token: Value(token),
      userId: Value(userId),
      deviceId: Value(deviceId),
      issuedAt: Value(issuedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      token: serializer.fromJson<String>(json['token']),
      userId: serializer.fromJson<String>(json['userId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'token': serializer.toJson<String>(token),
      'userId': serializer.toJson<String>(userId),
      'deviceId': serializer.toJson<String>(deviceId),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  Session copyWith({
    String? token,
    String? userId,
    String? deviceId,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) => Session(
    token: token ?? this.token,
    userId: userId ?? this.userId,
    deviceId: deviceId ?? this.deviceId,
    issuedAt: issuedAt ?? this.issuedAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      token: data.token.present ? data.token.value : this.token,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('token: $token, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(token, userId, deviceId, issuedAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.token == this.token &&
          other.userId == this.userId &&
          other.deviceId == this.deviceId &&
          other.issuedAt == this.issuedAt &&
          other.expiresAt == this.expiresAt);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> token;
  final Value<String> userId;
  final Value<String> deviceId;
  final Value<DateTime> issuedAt;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const SessionsCompanion({
    this.token = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String token,
    required String userId,
    required String deviceId,
    required DateTime issuedAt,
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  }) : token = Value(token),
       userId = Value(userId),
       deviceId = Value(deviceId),
       issuedAt = Value(issuedAt),
       expiresAt = Value(expiresAt);
  static Insertable<Session> custom({
    Expression<String>? token,
    Expression<String>? userId,
    Expression<String>? deviceId,
    Expression<DateTime>? issuedAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (token != null) 'token': token,
      if (userId != null) 'user_id': userId,
      if (deviceId != null) 'device_id': deviceId,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? token,
    Value<String>? userId,
    Value<String>? deviceId,
    Value<DateTime>? issuedAt,
    Value<DateTime>? expiresAt,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('token: $token, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyPemMeta = const VerificationMeta(
    'publicKeyPem',
  );
  @override
  late final GeneratedColumn<String> publicKeyPem = GeneratedColumn<String>(
    'public_key_pem',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pairedAtMeta = const VerificationMeta(
    'pairedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pairedAt = GeneratedColumn<DateTime>(
    'paired_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revokedMeta = const VerificationMeta(
    'revoked',
  );
  @override
  late final GeneratedColumn<bool> revoked = GeneratedColumn<bool>(
    'revoked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("revoked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    publicKeyPem,
    pairedAt,
    revoked,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Device> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('public_key_pem')) {
      context.handle(
        _publicKeyPemMeta,
        publicKeyPem.isAcceptableOrUnknown(
          data['public_key_pem']!,
          _publicKeyPemMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicKeyPemMeta);
    }
    if (data.containsKey('paired_at')) {
      context.handle(
        _pairedAtMeta,
        pairedAt.isAcceptableOrUnknown(data['paired_at']!, _pairedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_pairedAtMeta);
    }
    if (data.containsKey('revoked')) {
      context.handle(
        _revokedMeta,
        revoked.isAcceptableOrUnknown(data['revoked']!, _revokedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      publicKeyPem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key_pem'],
      )!,
      pairedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paired_at'],
      )!,
      revoked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}revoked'],
      )!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final String id;
  final String label;
  final String publicKeyPem;
  final DateTime pairedAt;
  final bool revoked;
  const Device({
    required this.id,
    required this.label,
    required this.publicKeyPem,
    required this.pairedAt,
    required this.revoked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['public_key_pem'] = Variable<String>(publicKeyPem);
    map['paired_at'] = Variable<DateTime>(pairedAt);
    map['revoked'] = Variable<bool>(revoked);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      label: Value(label),
      publicKeyPem: Value(publicKeyPem),
      pairedAt: Value(pairedAt),
      revoked: Value(revoked),
    );
  }

  factory Device.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      publicKeyPem: serializer.fromJson<String>(json['publicKeyPem']),
      pairedAt: serializer.fromJson<DateTime>(json['pairedAt']),
      revoked: serializer.fromJson<bool>(json['revoked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'publicKeyPem': serializer.toJson<String>(publicKeyPem),
      'pairedAt': serializer.toJson<DateTime>(pairedAt),
      'revoked': serializer.toJson<bool>(revoked),
    };
  }

  Device copyWith({
    String? id,
    String? label,
    String? publicKeyPem,
    DateTime? pairedAt,
    bool? revoked,
  }) => Device(
    id: id ?? this.id,
    label: label ?? this.label,
    publicKeyPem: publicKeyPem ?? this.publicKeyPem,
    pairedAt: pairedAt ?? this.pairedAt,
    revoked: revoked ?? this.revoked,
  );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      publicKeyPem: data.publicKeyPem.present
          ? data.publicKeyPem.value
          : this.publicKeyPem,
      pairedAt: data.pairedAt.present ? data.pairedAt.value : this.pairedAt,
      revoked: data.revoked.present ? data.revoked.value : this.revoked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('publicKeyPem: $publicKeyPem, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('revoked: $revoked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, publicKeyPem, pairedAt, revoked);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.id == this.id &&
          other.label == this.label &&
          other.publicKeyPem == this.publicKeyPem &&
          other.pairedAt == this.pairedAt &&
          other.revoked == this.revoked);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> publicKeyPem;
  final Value<DateTime> pairedAt;
  final Value<bool> revoked;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.publicKeyPem = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.revoked = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    required String label,
    required String publicKeyPem,
    required DateTime pairedAt,
    this.revoked = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       publicKeyPem = Value(publicKeyPem),
       pairedAt = Value(pairedAt);
  static Insertable<Device> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? publicKeyPem,
    Expression<DateTime>? pairedAt,
    Expression<bool>? revoked,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (publicKeyPem != null) 'public_key_pem': publicKeyPem,
      if (pairedAt != null) 'paired_at': pairedAt,
      if (revoked != null) 'revoked': revoked,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String>? publicKeyPem,
    Value<DateTime>? pairedAt,
    Value<bool>? revoked,
    Value<int>? rowid,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      publicKeyPem: publicKeyPem ?? this.publicKeyPem,
      pairedAt: pairedAt ?? this.pairedAt,
      revoked: revoked ?? this.revoked,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (publicKeyPem.present) {
      map['public_key_pem'] = Variable<String>(publicKeyPem.value);
    }
    if (pairedAt.present) {
      map['paired_at'] = Variable<DateTime>(pairedAt.value);
    }
    if (revoked.present) {
      map['revoked'] = Variable<bool>(revoked.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('publicKeyPem: $publicKeyPem, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('revoked: $revoked, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PairTokensTable extends PairTokens
    with TableInfo<$PairTokensTable, PairToken> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PairTokensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  @override
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedMeta = const VerificationMeta('used');
  @override
  late final GeneratedColumn<bool> used = GeneratedColumn<bool>(
    'used',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("used" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _claimedByDeviceIdMeta = const VerificationMeta(
    'claimedByDeviceId',
  );
  @override
  late final GeneratedColumn<String> claimedByDeviceId =
      GeneratedColumn<String>(
        'claimed_by_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    token,
    createdAt,
    expiresAt,
    used,
    claimedByDeviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pair_tokens';
  @override
  VerificationContext validateIntegrity(
    Insertable<PairToken> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('used')) {
      context.handle(
        _usedMeta,
        used.isAcceptableOrUnknown(data['used']!, _usedMeta),
      );
    }
    if (data.containsKey('claimed_by_device_id')) {
      context.handle(
        _claimedByDeviceIdMeta,
        claimedByDeviceId.isAcceptableOrUnknown(
          data['claimed_by_device_id']!,
          _claimedByDeviceIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {token};
  @override
  PairToken map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PairToken(
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      used: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}used'],
      )!,
      claimedByDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claimed_by_device_id'],
      ),
    );
  }

  @override
  $PairTokensTable createAlias(String alias) {
    return $PairTokensTable(attachedDatabase, alias);
  }
}

class PairToken extends DataClass implements Insertable<PairToken> {
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool used;
  final String? claimedByDeviceId;
  const PairToken({
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    required this.used,
    this.claimedByDeviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['token'] = Variable<String>(token);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['used'] = Variable<bool>(used);
    if (!nullToAbsent || claimedByDeviceId != null) {
      map['claimed_by_device_id'] = Variable<String>(claimedByDeviceId);
    }
    return map;
  }

  PairTokensCompanion toCompanion(bool nullToAbsent) {
    return PairTokensCompanion(
      token: Value(token),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
      used: Value(used),
      claimedByDeviceId: claimedByDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(claimedByDeviceId),
    );
  }

  factory PairToken.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PairToken(
      token: serializer.fromJson<String>(json['token']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      used: serializer.fromJson<bool>(json['used']),
      claimedByDeviceId: serializer.fromJson<String?>(
        json['claimedByDeviceId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'token': serializer.toJson<String>(token),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'used': serializer.toJson<bool>(used),
      'claimedByDeviceId': serializer.toJson<String?>(claimedByDeviceId),
    };
  }

  PairToken copyWith({
    String? token,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? used,
    Value<String?> claimedByDeviceId = const Value.absent(),
  }) => PairToken(
    token: token ?? this.token,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    used: used ?? this.used,
    claimedByDeviceId: claimedByDeviceId.present
        ? claimedByDeviceId.value
        : this.claimedByDeviceId,
  );
  PairToken copyWithCompanion(PairTokensCompanion data) {
    return PairToken(
      token: data.token.present ? data.token.value : this.token,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      used: data.used.present ? data.used.value : this.used,
      claimedByDeviceId: data.claimedByDeviceId.present
          ? data.claimedByDeviceId.value
          : this.claimedByDeviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PairToken(')
          ..write('token: $token, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('used: $used, ')
          ..write('claimedByDeviceId: $claimedByDeviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(token, createdAt, expiresAt, used, claimedByDeviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PairToken &&
          other.token == this.token &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt &&
          other.used == this.used &&
          other.claimedByDeviceId == this.claimedByDeviceId);
}

class PairTokensCompanion extends UpdateCompanion<PairToken> {
  final Value<String> token;
  final Value<DateTime> createdAt;
  final Value<DateTime> expiresAt;
  final Value<bool> used;
  final Value<String?> claimedByDeviceId;
  final Value<int> rowid;
  const PairTokensCompanion({
    this.token = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.used = const Value.absent(),
    this.claimedByDeviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PairTokensCompanion.insert({
    required String token,
    required DateTime createdAt,
    required DateTime expiresAt,
    this.used = const Value.absent(),
    this.claimedByDeviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : token = Value(token),
       createdAt = Value(createdAt),
       expiresAt = Value(expiresAt);
  static Insertable<PairToken> custom({
    Expression<String>? token,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<bool>? used,
    Expression<String>? claimedByDeviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (token != null) 'token': token,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (used != null) 'used': used,
      if (claimedByDeviceId != null) 'claimed_by_device_id': claimedByDeviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PairTokensCompanion copyWith({
    Value<String>? token,
    Value<DateTime>? createdAt,
    Value<DateTime>? expiresAt,
    Value<bool>? used,
    Value<String?>? claimedByDeviceId,
    Value<int>? rowid,
  }) {
    return PairTokensCompanion(
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      used: used ?? this.used,
      claimedByDeviceId: claimedByDeviceId ?? this.claimedByDeviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (used.present) {
      map['used'] = Variable<bool>(used.value);
    }
    if (claimedByDeviceId.present) {
      map['claimed_by_device_id'] = Variable<String>(claimedByDeviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PairTokensCompanion(')
          ..write('token: $token, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('used: $used, ')
          ..write('claimedByDeviceId: $claimedByDeviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IdempotencyTable extends Idempotency
    with TableInfo<$IdempotencyTable, IdempotencyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdempotencyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseJsonMeta = const VerificationMeta(
    'responseJson',
  );
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
    'response_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, responseJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'idempotency';
  @override
  VerificationContext validateIntegrity(
    Insertable<IdempotencyData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('response_json')) {
      context.handle(
        _responseJsonMeta,
        responseJson.isAcceptableOrUnknown(
          data['response_json']!,
          _responseJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  IdempotencyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdempotencyData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      responseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IdempotencyTable createAlias(String alias) {
    return $IdempotencyTable(attachedDatabase, alias);
  }
}

class IdempotencyData extends DataClass implements Insertable<IdempotencyData> {
  final String key;

  /// JSON-serialised response body.
  final String responseJson;
  final DateTime createdAt;
  const IdempotencyData({
    required this.key,
    required this.responseJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['response_json'] = Variable<String>(responseJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IdempotencyCompanion toCompanion(bool nullToAbsent) {
    return IdempotencyCompanion(
      key: Value(key),
      responseJson: Value(responseJson),
      createdAt: Value(createdAt),
    );
  }

  factory IdempotencyData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdempotencyData(
      key: serializer.fromJson<String>(json['key']),
      responseJson: serializer.fromJson<String>(json['responseJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'responseJson': serializer.toJson<String>(responseJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  IdempotencyData copyWith({
    String? key,
    String? responseJson,
    DateTime? createdAt,
  }) => IdempotencyData(
    key: key ?? this.key,
    responseJson: responseJson ?? this.responseJson,
    createdAt: createdAt ?? this.createdAt,
  );
  IdempotencyData copyWithCompanion(IdempotencyCompanion data) {
    return IdempotencyData(
      key: data.key.present ? data.key.value : this.key,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdempotencyData(')
          ..write('key: $key, ')
          ..write('responseJson: $responseJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, responseJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdempotencyData &&
          other.key == this.key &&
          other.responseJson == this.responseJson &&
          other.createdAt == this.createdAt);
}

class IdempotencyCompanion extends UpdateCompanion<IdempotencyData> {
  final Value<String> key;
  final Value<String> responseJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const IdempotencyCompanion({
    this.key = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdempotencyCompanion.insert({
    required String key,
    required String responseJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       responseJson = Value(responseJson),
       createdAt = Value(createdAt);
  static Insertable<IdempotencyData> custom({
    Expression<String>? key,
    Expression<String>? responseJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (responseJson != null) 'response_json': responseJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdempotencyCompanion copyWith({
    Value<String>? key,
    Value<String>? responseJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return IdempotencyCompanion(
      key: key ?? this.key,
      responseJson: responseJson ?? this.responseJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdempotencyCompanion(')
          ..write('key: $key, ')
          ..write('responseJson: $responseJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditEntriesTable extends AuditEntries
    with TableInfo<$AuditEntriesTable, AuditEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tableIdMeta = const VerificationMeta(
    'tableId',
  );
  @override
  late final GeneratedColumn<String> tableId = GeneratedColumn<String>(
    'table_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _approvedByMeta = const VerificationMeta(
    'approvedBy',
  );
  @override
  late final GeneratedColumn<String> approvedBy = GeneratedColumn<String>(
    'approved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorUserIdMeta = const VerificationMeta(
    'actorUserId',
  );
  @override
  late final GeneratedColumn<String> actorUserId = GeneratedColumn<String>(
    'actor_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    tableId,
    at,
    approvedBy,
    reason,
    actorUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('table_id')) {
      context.handle(
        _tableIdMeta,
        tableId.isAcceptableOrUnknown(data['table_id']!, _tableIdMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('approved_by')) {
      context.handle(
        _approvedByMeta,
        approvedBy.isAcceptableOrUnknown(data['approved_by']!, _approvedByMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('actor_user_id')) {
      context.handle(
        _actorUserIdMeta,
        actorUserId.isAcceptableOrUnknown(
          data['actor_user_id']!,
          _actorUserIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_id'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      approvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      actorUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_user_id'],
      ),
    );
  }

  @override
  $AuditEntriesTable createAlias(String alias) {
    return $AuditEntriesTable(attachedDatabase, alias);
  }
}

class AuditEntry extends DataClass implements Insertable<AuditEntry> {
  final String id;
  final String type;
  final String title;
  final String? tableId;
  final DateTime at;
  final String? approvedBy;
  final String? reason;
  final String? actorUserId;
  const AuditEntry({
    required this.id,
    required this.type,
    required this.title,
    this.tableId,
    required this.at,
    this.approvedBy,
    this.reason,
    this.actorUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || tableId != null) {
      map['table_id'] = Variable<String>(tableId);
    }
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || approvedBy != null) {
      map['approved_by'] = Variable<String>(approvedBy);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || actorUserId != null) {
      map['actor_user_id'] = Variable<String>(actorUserId);
    }
    return map;
  }

  AuditEntriesCompanion toCompanion(bool nullToAbsent) {
    return AuditEntriesCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      tableId: tableId == null && nullToAbsent
          ? const Value.absent()
          : Value(tableId),
      at: Value(at),
      approvedBy: approvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedBy),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      actorUserId: actorUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorUserId),
    );
  }

  factory AuditEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditEntry(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      tableId: serializer.fromJson<String?>(json['tableId']),
      at: serializer.fromJson<DateTime>(json['at']),
      approvedBy: serializer.fromJson<String?>(json['approvedBy']),
      reason: serializer.fromJson<String?>(json['reason']),
      actorUserId: serializer.fromJson<String?>(json['actorUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'tableId': serializer.toJson<String?>(tableId),
      'at': serializer.toJson<DateTime>(at),
      'approvedBy': serializer.toJson<String?>(approvedBy),
      'reason': serializer.toJson<String?>(reason),
      'actorUserId': serializer.toJson<String?>(actorUserId),
    };
  }

  AuditEntry copyWith({
    String? id,
    String? type,
    String? title,
    Value<String?> tableId = const Value.absent(),
    DateTime? at,
    Value<String?> approvedBy = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    Value<String?> actorUserId = const Value.absent(),
  }) => AuditEntry(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    tableId: tableId.present ? tableId.value : this.tableId,
    at: at ?? this.at,
    approvedBy: approvedBy.present ? approvedBy.value : this.approvedBy,
    reason: reason.present ? reason.value : this.reason,
    actorUserId: actorUserId.present ? actorUserId.value : this.actorUserId,
  );
  AuditEntry copyWithCompanion(AuditEntriesCompanion data) {
    return AuditEntry(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      at: data.at.present ? data.at.value : this.at,
      approvedBy: data.approvedBy.present
          ? data.approvedBy.value
          : this.approvedBy,
      reason: data.reason.present ? data.reason.value : this.reason,
      actorUserId: data.actorUserId.present
          ? data.actorUserId.value
          : this.actorUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditEntry(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('tableId: $tableId, ')
          ..write('at: $at, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('reason: $reason, ')
          ..write('actorUserId: $actorUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    tableId,
    at,
    approvedBy,
    reason,
    actorUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditEntry &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.tableId == this.tableId &&
          other.at == this.at &&
          other.approvedBy == this.approvedBy &&
          other.reason == this.reason &&
          other.actorUserId == this.actorUserId);
}

class AuditEntriesCompanion extends UpdateCompanion<AuditEntry> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String?> tableId;
  final Value<DateTime> at;
  final Value<String?> approvedBy;
  final Value<String?> reason;
  final Value<String?> actorUserId;
  final Value<int> rowid;
  const AuditEntriesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.tableId = const Value.absent(),
    this.at = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.reason = const Value.absent(),
    this.actorUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditEntriesCompanion.insert({
    required String id,
    required String type,
    required String title,
    this.tableId = const Value.absent(),
    required DateTime at,
    this.approvedBy = const Value.absent(),
    this.reason = const Value.absent(),
    this.actorUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       title = Value(title),
       at = Value(at);
  static Insertable<AuditEntry> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? tableId,
    Expression<DateTime>? at,
    Expression<String>? approvedBy,
    Expression<String>? reason,
    Expression<String>? actorUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (tableId != null) 'table_id': tableId,
      if (at != null) 'at': at,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (reason != null) 'reason': reason,
      if (actorUserId != null) 'actor_user_id': actorUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? title,
    Value<String?>? tableId,
    Value<DateTime>? at,
    Value<String?>? approvedBy,
    Value<String?>? reason,
    Value<String?>? actorUserId,
    Value<int>? rowid,
  }) {
    return AuditEntriesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      tableId: tableId ?? this.tableId,
      at: at ?? this.at,
      approvedBy: approvedBy ?? this.approvedBy,
      reason: reason ?? this.reason,
      actorUserId: actorUserId ?? this.actorUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (tableId.present) {
      map['table_id'] = Variable<String>(tableId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (approvedBy.present) {
      map['approved_by'] = Variable<String>(approvedBy.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (actorUserId.present) {
      map['actor_user_id'] = Variable<String>(actorUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditEntriesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('tableId: $tableId, ')
          ..write('at: $at, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('reason: $reason, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $RolesTable roles = $RolesTable(this);
  late final $ZonesTable zones = $ZonesTable(this);
  late final $VenueTablesTable venueTables = $VenueTablesTable(this);
  late final $MenuCategoriesTable menuCategories = $MenuCategoriesTable(this);
  late final $MenuItemsTable menuItems = $MenuItemsTable(this);
  late final $ModifierGroupsTable modifierGroups = $ModifierGroupsTable(this);
  late final $TicketsTable tickets = $TicketsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $PairTokensTable pairTokens = $PairTokensTable(this);
  late final $IdempotencyTable idempotency = $IdempotencyTable(this);
  late final $AuditEntriesTable auditEntries = $AuditEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    roles,
    zones,
    venueTables,
    menuCategories,
    menuItems,
    modifierGroups,
    tickets,
    sessions,
    devices,
    pairTokens,
    idempotency,
    auditEntries,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      required String name,
      required String initials,
      required String roleId,
      Value<String?> zoneAssigned,
      required String pinHash,
      Value<bool> onDuty,
      Value<bool> disabled,
      Value<DateTime?> shiftStartedAt,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> initials,
      Value<String> roleId,
      Value<String?> zoneAssigned,
      Value<String> pinHash,
      Value<bool> onDuty,
      Value<bool> disabled,
      Value<DateTime?> shiftStartedAt,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initials => $composableBuilder(
    column: $table.initials,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zoneAssigned => $composableBuilder(
    column: $table.zoneAssigned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onDuty => $composableBuilder(
    column: $table.onDuty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get disabled => $composableBuilder(
    column: $table.disabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get shiftStartedAt => $composableBuilder(
    column: $table.shiftStartedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initials => $composableBuilder(
    column: $table.initials,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneAssigned => $composableBuilder(
    column: $table.zoneAssigned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onDuty => $composableBuilder(
    column: $table.onDuty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get disabled => $composableBuilder(
    column: $table.disabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get shiftStartedAt => $composableBuilder(
    column: $table.shiftStartedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get initials =>
      $composableBuilder(column: $table.initials, builder: (column) => column);

  GeneratedColumn<String> get roleId =>
      $composableBuilder(column: $table.roleId, builder: (column) => column);

  GeneratedColumn<String> get zoneAssigned => $composableBuilder(
    column: $table.zoneAssigned,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<bool> get onDuty =>
      $composableBuilder(column: $table.onDuty, builder: (column) => column);

  GeneratedColumn<bool> get disabled =>
      $composableBuilder(column: $table.disabled, builder: (column) => column);

  GeneratedColumn<DateTime> get shiftStartedAt => $composableBuilder(
    column: $table.shiftStartedAt,
    builder: (column) => column,
  );
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> initials = const Value.absent(),
                Value<String> roleId = const Value.absent(),
                Value<String?> zoneAssigned = const Value.absent(),
                Value<String> pinHash = const Value.absent(),
                Value<bool> onDuty = const Value.absent(),
                Value<bool> disabled = const Value.absent(),
                Value<DateTime?> shiftStartedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                initials: initials,
                roleId: roleId,
                zoneAssigned: zoneAssigned,
                pinHash: pinHash,
                onDuty: onDuty,
                disabled: disabled,
                shiftStartedAt: shiftStartedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String initials,
                required String roleId,
                Value<String?> zoneAssigned = const Value.absent(),
                required String pinHash,
                Value<bool> onDuty = const Value.absent(),
                Value<bool> disabled = const Value.absent(),
                Value<DateTime?> shiftStartedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                initials: initials,
                roleId: roleId,
                zoneAssigned: zoneAssigned,
                pinHash: pinHash,
                onDuty: onDuty,
                disabled: disabled,
                shiftStartedAt: shiftStartedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$RolesTableCreateCompanionBuilder =
    RolesCompanion Function({
      required String id,
      required String name,
      Value<String> colorHex,
      Value<String> capabilitiesJson,
      Value<int> rowid,
    });
typedef $$RolesTableUpdateCompanionBuilder =
    RolesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> colorHex,
      Value<String> capabilitiesJson,
      Value<int> rowid,
    });

class $$RolesTableFilterComposer extends Composer<_$AppDatabase, $RolesTable> {
  $$RolesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capabilitiesJson => $composableBuilder(
    column: $table.capabilitiesJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RolesTableOrderingComposer
    extends Composer<_$AppDatabase, $RolesTable> {
  $$RolesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capabilitiesJson => $composableBuilder(
    column: $table.capabilitiesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RolesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RolesTable> {
  $$RolesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get capabilitiesJson => $composableBuilder(
    column: $table.capabilitiesJson,
    builder: (column) => column,
  );
}

class $$RolesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RolesTable,
          Role,
          $$RolesTableFilterComposer,
          $$RolesTableOrderingComposer,
          $$RolesTableAnnotationComposer,
          $$RolesTableCreateCompanionBuilder,
          $$RolesTableUpdateCompanionBuilder,
          (Role, BaseReferences<_$AppDatabase, $RolesTable, Role>),
          Role,
          PrefetchHooks Function()
        > {
  $$RolesTableTableManager(_$AppDatabase db, $RolesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RolesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RolesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RolesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<String> capabilitiesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RolesCompanion(
                id: id,
                name: name,
                colorHex: colorHex,
                capabilitiesJson: capabilitiesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> colorHex = const Value.absent(),
                Value<String> capabilitiesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RolesCompanion.insert(
                id: id,
                name: name,
                colorHex: colorHex,
                capabilitiesJson: capabilitiesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RolesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RolesTable,
      Role,
      $$RolesTableFilterComposer,
      $$RolesTableOrderingComposer,
      $$RolesTableAnnotationComposer,
      $$RolesTableCreateCompanionBuilder,
      $$RolesTableUpdateCompanionBuilder,
      (Role, BaseReferences<_$AppDatabase, $RolesTable, Role>),
      Role,
      PrefetchHooks Function()
    >;
typedef $$ZonesTableCreateCompanionBuilder =
    ZonesCompanion Function({
      required String id,
      required String name,
      required String short,
      Value<String> colorHex,
      Value<String> iconKey,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$ZonesTableUpdateCompanionBuilder =
    ZonesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> short,
      Value<String> colorHex,
      Value<String> iconKey,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$ZonesTableFilterComposer extends Composer<_$AppDatabase, $ZonesTable> {
  $$ZonesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get short => $composableBuilder(
    column: $table.short,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ZonesTableOrderingComposer
    extends Composer<_$AppDatabase, $ZonesTable> {
  $$ZonesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get short => $composableBuilder(
    column: $table.short,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ZonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ZonesTable> {
  $$ZonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get short =>
      $composableBuilder(column: $table.short, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ZonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ZonesTable,
          Zone,
          $$ZonesTableFilterComposer,
          $$ZonesTableOrderingComposer,
          $$ZonesTableAnnotationComposer,
          $$ZonesTableCreateCompanionBuilder,
          $$ZonesTableUpdateCompanionBuilder,
          (Zone, BaseReferences<_$AppDatabase, $ZonesTable, Zone>),
          Zone,
          PrefetchHooks Function()
        > {
  $$ZonesTableTableManager(_$AppDatabase db, $ZonesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ZonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ZonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ZonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> short = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ZonesCompanion(
                id: id,
                name: name,
                short: short,
                colorHex: colorHex,
                iconKey: iconKey,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String short,
                Value<String> colorHex = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ZonesCompanion.insert(
                id: id,
                name: name,
                short: short,
                colorHex: colorHex,
                iconKey: iconKey,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ZonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ZonesTable,
      Zone,
      $$ZonesTableFilterComposer,
      $$ZonesTableOrderingComposer,
      $$ZonesTableAnnotationComposer,
      $$ZonesTableCreateCompanionBuilder,
      $$ZonesTableUpdateCompanionBuilder,
      (Zone, BaseReferences<_$AppDatabase, $ZonesTable, Zone>),
      Zone,
      PrefetchHooks Function()
    >;
typedef $$VenueTablesTableCreateCompanionBuilder =
    VenueTablesCompanion Function({
      required String id,
      required String zoneId,
      Value<String?> label,
      Value<int> pax,
      Value<bool> active,
      Value<String> status,
      Value<int> openAmount,
      Value<int> readyCount,
      Value<String?> lastActorId,
      Value<int> rowid,
    });
typedef $$VenueTablesTableUpdateCompanionBuilder =
    VenueTablesCompanion Function({
      Value<String> id,
      Value<String> zoneId,
      Value<String?> label,
      Value<int> pax,
      Value<bool> active,
      Value<String> status,
      Value<int> openAmount,
      Value<int> readyCount,
      Value<String?> lastActorId,
      Value<int> rowid,
    });

class $$VenueTablesTableFilterComposer
    extends Composer<_$AppDatabase, $VenueTablesTable> {
  $$VenueTablesTableFilterComposer({
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

  ColumnFilters<String> get zoneId => $composableBuilder(
    column: $table.zoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pax => $composableBuilder(
    column: $table.pax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openAmount => $composableBuilder(
    column: $table.openAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readyCount => $composableBuilder(
    column: $table.readyCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastActorId => $composableBuilder(
    column: $table.lastActorId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VenueTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $VenueTablesTable> {
  $$VenueTablesTableOrderingComposer({
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

  ColumnOrderings<String> get zoneId => $composableBuilder(
    column: $table.zoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pax => $composableBuilder(
    column: $table.pax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openAmount => $composableBuilder(
    column: $table.openAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readyCount => $composableBuilder(
    column: $table.readyCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastActorId => $composableBuilder(
    column: $table.lastActorId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VenueTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VenueTablesTable> {
  $$VenueTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get zoneId =>
      $composableBuilder(column: $table.zoneId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get pax =>
      $composableBuilder(column: $table.pax, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get openAmount => $composableBuilder(
    column: $table.openAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get readyCount => $composableBuilder(
    column: $table.readyCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastActorId => $composableBuilder(
    column: $table.lastActorId,
    builder: (column) => column,
  );
}

class $$VenueTablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VenueTablesTable,
          VenueTable,
          $$VenueTablesTableFilterComposer,
          $$VenueTablesTableOrderingComposer,
          $$VenueTablesTableAnnotationComposer,
          $$VenueTablesTableCreateCompanionBuilder,
          $$VenueTablesTableUpdateCompanionBuilder,
          (
            VenueTable,
            BaseReferences<_$AppDatabase, $VenueTablesTable, VenueTable>,
          ),
          VenueTable,
          PrefetchHooks Function()
        > {
  $$VenueTablesTableTableManager(_$AppDatabase db, $VenueTablesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VenueTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VenueTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VenueTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> zoneId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int> pax = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> openAmount = const Value.absent(),
                Value<int> readyCount = const Value.absent(),
                Value<String?> lastActorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VenueTablesCompanion(
                id: id,
                zoneId: zoneId,
                label: label,
                pax: pax,
                active: active,
                status: status,
                openAmount: openAmount,
                readyCount: readyCount,
                lastActorId: lastActorId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String zoneId,
                Value<String?> label = const Value.absent(),
                Value<int> pax = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> openAmount = const Value.absent(),
                Value<int> readyCount = const Value.absent(),
                Value<String?> lastActorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VenueTablesCompanion.insert(
                id: id,
                zoneId: zoneId,
                label: label,
                pax: pax,
                active: active,
                status: status,
                openAmount: openAmount,
                readyCount: readyCount,
                lastActorId: lastActorId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VenueTablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VenueTablesTable,
      VenueTable,
      $$VenueTablesTableFilterComposer,
      $$VenueTablesTableOrderingComposer,
      $$VenueTablesTableAnnotationComposer,
      $$VenueTablesTableCreateCompanionBuilder,
      $$VenueTablesTableUpdateCompanionBuilder,
      (
        VenueTable,
        BaseReferences<_$AppDatabase, $VenueTablesTable, VenueTable>,
      ),
      VenueTable,
      PrefetchHooks Function()
    >;
typedef $$MenuCategoriesTableCreateCompanionBuilder =
    MenuCategoriesCompanion Function({
      required String id,
      required String name,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$MenuCategoriesTableUpdateCompanionBuilder =
    MenuCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$MenuCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $MenuCategoriesTable> {
  $$MenuCategoriesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MenuCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuCategoriesTable> {
  $$MenuCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MenuCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuCategoriesTable> {
  $$MenuCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$MenuCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuCategoriesTable,
          MenuCategory,
          $$MenuCategoriesTableFilterComposer,
          $$MenuCategoriesTableOrderingComposer,
          $$MenuCategoriesTableAnnotationComposer,
          $$MenuCategoriesTableCreateCompanionBuilder,
          $$MenuCategoriesTableUpdateCompanionBuilder,
          (
            MenuCategory,
            BaseReferences<_$AppDatabase, $MenuCategoriesTable, MenuCategory>,
          ),
          MenuCategory,
          PrefetchHooks Function()
        > {
  $$MenuCategoriesTableTableManager(
    _$AppDatabase db,
    $MenuCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenuCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuCategoriesCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuCategoriesCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MenuCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuCategoriesTable,
      MenuCategory,
      $$MenuCategoriesTableFilterComposer,
      $$MenuCategoriesTableOrderingComposer,
      $$MenuCategoriesTableAnnotationComposer,
      $$MenuCategoriesTableCreateCompanionBuilder,
      $$MenuCategoriesTableUpdateCompanionBuilder,
      (
        MenuCategory,
        BaseReferences<_$AppDatabase, $MenuCategoriesTable, MenuCategory>,
      ),
      MenuCategory,
      PrefetchHooks Function()
    >;
typedef $$MenuItemsTableCreateCompanionBuilder =
    MenuItemsCompanion Function({
      required String id,
      required String name,
      required String categoryId,
      required String station,
      Value<String> description,
      required int basePrice,
      Value<int> prepTime,
      Value<String> variantsJson,
      Value<String> modifierGroupIdsJson,
      Value<String> allergensJson,
      Value<String> dietaryJson,
      Value<bool> unavailable,
      Value<int?> stockCount,
      Value<bool> autoEightySixAtZero,
      Value<int> rowid,
    });
typedef $$MenuItemsTableUpdateCompanionBuilder =
    MenuItemsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> categoryId,
      Value<String> station,
      Value<String> description,
      Value<int> basePrice,
      Value<int> prepTime,
      Value<String> variantsJson,
      Value<String> modifierGroupIdsJson,
      Value<String> allergensJson,
      Value<String> dietaryJson,
      Value<bool> unavailable,
      Value<int?> stockCount,
      Value<bool> autoEightySixAtZero,
      Value<int> rowid,
    });

class $$MenuItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MenuItemsTable> {
  $$MenuItemsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get station => $composableBuilder(
    column: $table.station,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get basePrice => $composableBuilder(
    column: $table.basePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prepTime => $composableBuilder(
    column: $table.prepTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantsJson => $composableBuilder(
    column: $table.variantsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifierGroupIdsJson => $composableBuilder(
    column: $table.modifierGroupIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allergensJson => $composableBuilder(
    column: $table.allergensJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dietaryJson => $composableBuilder(
    column: $table.dietaryJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get unavailable => $composableBuilder(
    column: $table.unavailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockCount => $composableBuilder(
    column: $table.stockCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoEightySixAtZero => $composableBuilder(
    column: $table.autoEightySixAtZero,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MenuItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuItemsTable> {
  $$MenuItemsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get station => $composableBuilder(
    column: $table.station,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get basePrice => $composableBuilder(
    column: $table.basePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prepTime => $composableBuilder(
    column: $table.prepTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantsJson => $composableBuilder(
    column: $table.variantsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifierGroupIdsJson => $composableBuilder(
    column: $table.modifierGroupIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allergensJson => $composableBuilder(
    column: $table.allergensJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dietaryJson => $composableBuilder(
    column: $table.dietaryJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get unavailable => $composableBuilder(
    column: $table.unavailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockCount => $composableBuilder(
    column: $table.stockCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoEightySixAtZero => $composableBuilder(
    column: $table.autoEightySixAtZero,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MenuItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuItemsTable> {
  $$MenuItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get station =>
      $composableBuilder(column: $table.station, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get basePrice =>
      $composableBuilder(column: $table.basePrice, builder: (column) => column);

  GeneratedColumn<int> get prepTime =>
      $composableBuilder(column: $table.prepTime, builder: (column) => column);

  GeneratedColumn<String> get variantsJson => $composableBuilder(
    column: $table.variantsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifierGroupIdsJson => $composableBuilder(
    column: $table.modifierGroupIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get allergensJson => $composableBuilder(
    column: $table.allergensJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dietaryJson => $composableBuilder(
    column: $table.dietaryJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get unavailable => $composableBuilder(
    column: $table.unavailable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockCount => $composableBuilder(
    column: $table.stockCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoEightySixAtZero => $composableBuilder(
    column: $table.autoEightySixAtZero,
    builder: (column) => column,
  );
}

class $$MenuItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuItemsTable,
          MenuItem,
          $$MenuItemsTableFilterComposer,
          $$MenuItemsTableOrderingComposer,
          $$MenuItemsTableAnnotationComposer,
          $$MenuItemsTableCreateCompanionBuilder,
          $$MenuItemsTableUpdateCompanionBuilder,
          (MenuItem, BaseReferences<_$AppDatabase, $MenuItemsTable, MenuItem>),
          MenuItem,
          PrefetchHooks Function()
        > {
  $$MenuItemsTableTableManager(_$AppDatabase db, $MenuItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenuItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> station = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> basePrice = const Value.absent(),
                Value<int> prepTime = const Value.absent(),
                Value<String> variantsJson = const Value.absent(),
                Value<String> modifierGroupIdsJson = const Value.absent(),
                Value<String> allergensJson = const Value.absent(),
                Value<String> dietaryJson = const Value.absent(),
                Value<bool> unavailable = const Value.absent(),
                Value<int?> stockCount = const Value.absent(),
                Value<bool> autoEightySixAtZero = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuItemsCompanion(
                id: id,
                name: name,
                categoryId: categoryId,
                station: station,
                description: description,
                basePrice: basePrice,
                prepTime: prepTime,
                variantsJson: variantsJson,
                modifierGroupIdsJson: modifierGroupIdsJson,
                allergensJson: allergensJson,
                dietaryJson: dietaryJson,
                unavailable: unavailable,
                stockCount: stockCount,
                autoEightySixAtZero: autoEightySixAtZero,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String categoryId,
                required String station,
                Value<String> description = const Value.absent(),
                required int basePrice,
                Value<int> prepTime = const Value.absent(),
                Value<String> variantsJson = const Value.absent(),
                Value<String> modifierGroupIdsJson = const Value.absent(),
                Value<String> allergensJson = const Value.absent(),
                Value<String> dietaryJson = const Value.absent(),
                Value<bool> unavailable = const Value.absent(),
                Value<int?> stockCount = const Value.absent(),
                Value<bool> autoEightySixAtZero = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuItemsCompanion.insert(
                id: id,
                name: name,
                categoryId: categoryId,
                station: station,
                description: description,
                basePrice: basePrice,
                prepTime: prepTime,
                variantsJson: variantsJson,
                modifierGroupIdsJson: modifierGroupIdsJson,
                allergensJson: allergensJson,
                dietaryJson: dietaryJson,
                unavailable: unavailable,
                stockCount: stockCount,
                autoEightySixAtZero: autoEightySixAtZero,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MenuItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuItemsTable,
      MenuItem,
      $$MenuItemsTableFilterComposer,
      $$MenuItemsTableOrderingComposer,
      $$MenuItemsTableAnnotationComposer,
      $$MenuItemsTableCreateCompanionBuilder,
      $$MenuItemsTableUpdateCompanionBuilder,
      (MenuItem, BaseReferences<_$AppDatabase, $MenuItemsTable, MenuItem>),
      MenuItem,
      PrefetchHooks Function()
    >;
typedef $$ModifierGroupsTableCreateCompanionBuilder =
    ModifierGroupsCompanion Function({
      required String id,
      required String name,
      Value<bool> required,
      Value<bool> multi,
      Value<String> optionsJson,
      Value<int> rowid,
    });
typedef $$ModifierGroupsTableUpdateCompanionBuilder =
    ModifierGroupsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> required,
      Value<bool> multi,
      Value<String> optionsJson,
      Value<int> rowid,
    });

class $$ModifierGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ModifierGroupsTable> {
  $$ModifierGroupsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get multi => $composableBuilder(
    column: $table.multi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ModifierGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ModifierGroupsTable> {
  $$ModifierGroupsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get multi => $composableBuilder(
    column: $table.multi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModifierGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModifierGroupsTable> {
  $$ModifierGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get required =>
      $composableBuilder(column: $table.required, builder: (column) => column);

  GeneratedColumn<bool> get multi =>
      $composableBuilder(column: $table.multi, builder: (column) => column);

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );
}

class $$ModifierGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModifierGroupsTable,
          ModifierGroup,
          $$ModifierGroupsTableFilterComposer,
          $$ModifierGroupsTableOrderingComposer,
          $$ModifierGroupsTableAnnotationComposer,
          $$ModifierGroupsTableCreateCompanionBuilder,
          $$ModifierGroupsTableUpdateCompanionBuilder,
          (
            ModifierGroup,
            BaseReferences<_$AppDatabase, $ModifierGroupsTable, ModifierGroup>,
          ),
          ModifierGroup,
          PrefetchHooks Function()
        > {
  $$ModifierGroupsTableTableManager(
    _$AppDatabase db,
    $ModifierGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModifierGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModifierGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModifierGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> required = const Value.absent(),
                Value<bool> multi = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModifierGroupsCompanion(
                id: id,
                name: name,
                required: required,
                multi: multi,
                optionsJson: optionsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> required = const Value.absent(),
                Value<bool> multi = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModifierGroupsCompanion.insert(
                id: id,
                name: name,
                required: required,
                multi: multi,
                optionsJson: optionsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ModifierGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModifierGroupsTable,
      ModifierGroup,
      $$ModifierGroupsTableFilterComposer,
      $$ModifierGroupsTableOrderingComposer,
      $$ModifierGroupsTableAnnotationComposer,
      $$ModifierGroupsTableCreateCompanionBuilder,
      $$ModifierGroupsTableUpdateCompanionBuilder,
      (
        ModifierGroup,
        BaseReferences<_$AppDatabase, $ModifierGroupsTable, ModifierGroup>,
      ),
      ModifierGroup,
      PrefetchHooks Function()
    >;
typedef $$TicketsTableCreateCompanionBuilder =
    TicketsCompanion Function({
      required String id,
      required String tableId,
      required String itemId,
      required String name,
      Value<String> variantName,
      required String course,
      required String station,
      Value<int> qty,
      Value<String> modifiersJson,
      Value<String?> specialInstructions,
      required int price,
      required String status,
      required DateTime sentAt,
      Value<String?> voidReason,
      Value<String?> voidApprovedBy,
      Value<String?> createdByUserId,
      Value<int> rowid,
    });
typedef $$TicketsTableUpdateCompanionBuilder =
    TicketsCompanion Function({
      Value<String> id,
      Value<String> tableId,
      Value<String> itemId,
      Value<String> name,
      Value<String> variantName,
      Value<String> course,
      Value<String> station,
      Value<int> qty,
      Value<String> modifiersJson,
      Value<String?> specialInstructions,
      Value<int> price,
      Value<String> status,
      Value<DateTime> sentAt,
      Value<String?> voidReason,
      Value<String?> voidApprovedBy,
      Value<String?> createdByUserId,
      Value<int> rowid,
    });

class $$TicketsTableFilterComposer
    extends Composer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableFilterComposer({
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

  ColumnFilters<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get course => $composableBuilder(
    column: $table.course,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get station => $composableBuilder(
    column: $table.station,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiersJson => $composableBuilder(
    column: $table.modifiersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specialInstructions => $composableBuilder(
    column: $table.specialInstructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidApprovedBy => $composableBuilder(
    column: $table.voidApprovedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdByUserId => $composableBuilder(
    column: $table.createdByUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TicketsTableOrderingComposer
    extends Composer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableOrderingComposer({
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

  ColumnOrderings<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get course => $composableBuilder(
    column: $table.course,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get station => $composableBuilder(
    column: $table.station,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiersJson => $composableBuilder(
    column: $table.modifiersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specialInstructions => $composableBuilder(
    column: $table.specialInstructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidApprovedBy => $composableBuilder(
    column: $table.voidApprovedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdByUserId => $composableBuilder(
    column: $table.createdByUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TicketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tableId =>
      $composableBuilder(column: $table.tableId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get course =>
      $composableBuilder(column: $table.course, builder: (column) => column);

  GeneratedColumn<String> get station =>
      $composableBuilder(column: $table.station, builder: (column) => column);

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get modifiersJson => $composableBuilder(
    column: $table.modifiersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specialInstructions => $composableBuilder(
    column: $table.specialInstructions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voidApprovedBy => $composableBuilder(
    column: $table.voidApprovedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdByUserId => $composableBuilder(
    column: $table.createdByUserId,
    builder: (column) => column,
  );
}

class $$TicketsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TicketsTable,
          Ticket,
          $$TicketsTableFilterComposer,
          $$TicketsTableOrderingComposer,
          $$TicketsTableAnnotationComposer,
          $$TicketsTableCreateCompanionBuilder,
          $$TicketsTableUpdateCompanionBuilder,
          (Ticket, BaseReferences<_$AppDatabase, $TicketsTable, Ticket>),
          Ticket,
          PrefetchHooks Function()
        > {
  $$TicketsTableTableManager(_$AppDatabase db, $TicketsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TicketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TicketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TicketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tableId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> variantName = const Value.absent(),
                Value<String> course = const Value.absent(),
                Value<String> station = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<String> modifiersJson = const Value.absent(),
                Value<String?> specialInstructions = const Value.absent(),
                Value<int> price = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<String?> voidApprovedBy = const Value.absent(),
                Value<String?> createdByUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TicketsCompanion(
                id: id,
                tableId: tableId,
                itemId: itemId,
                name: name,
                variantName: variantName,
                course: course,
                station: station,
                qty: qty,
                modifiersJson: modifiersJson,
                specialInstructions: specialInstructions,
                price: price,
                status: status,
                sentAt: sentAt,
                voidReason: voidReason,
                voidApprovedBy: voidApprovedBy,
                createdByUserId: createdByUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tableId,
                required String itemId,
                required String name,
                Value<String> variantName = const Value.absent(),
                required String course,
                required String station,
                Value<int> qty = const Value.absent(),
                Value<String> modifiersJson = const Value.absent(),
                Value<String?> specialInstructions = const Value.absent(),
                required int price,
                required String status,
                required DateTime sentAt,
                Value<String?> voidReason = const Value.absent(),
                Value<String?> voidApprovedBy = const Value.absent(),
                Value<String?> createdByUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TicketsCompanion.insert(
                id: id,
                tableId: tableId,
                itemId: itemId,
                name: name,
                variantName: variantName,
                course: course,
                station: station,
                qty: qty,
                modifiersJson: modifiersJson,
                specialInstructions: specialInstructions,
                price: price,
                status: status,
                sentAt: sentAt,
                voidReason: voidReason,
                voidApprovedBy: voidApprovedBy,
                createdByUserId: createdByUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TicketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TicketsTable,
      Ticket,
      $$TicketsTableFilterComposer,
      $$TicketsTableOrderingComposer,
      $$TicketsTableAnnotationComposer,
      $$TicketsTableCreateCompanionBuilder,
      $$TicketsTableUpdateCompanionBuilder,
      (Ticket, BaseReferences<_$AppDatabase, $TicketsTable, Ticket>),
      Ticket,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String token,
      required String userId,
      required String deviceId,
      required DateTime issuedAt,
      required DateTime expiresAt,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> token,
      Value<String> userId,
      Value<String> deviceId,
      Value<DateTime> issuedAt,
      Value<DateTime> expiresAt,
      Value<int> rowid,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get token =>
      $composableBuilder(column: $table.token, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get issuedAt =>
      $composableBuilder(column: $table.issuedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> token = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime> issuedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                token: token,
                userId: userId,
                deviceId: deviceId,
                issuedAt: issuedAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String token,
                required String userId,
                required String deviceId,
                required DateTime issuedAt,
                required DateTime expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                token: token,
                userId: userId,
                deviceId: deviceId,
                issuedAt: issuedAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$DevicesTableCreateCompanionBuilder =
    DevicesCompanion Function({
      required String id,
      required String label,
      required String publicKeyPem,
      required DateTime pairedAt,
      Value<bool> revoked,
      Value<int> rowid,
    });
typedef $$DevicesTableUpdateCompanionBuilder =
    DevicesCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<String> publicKeyPem,
      Value<DateTime> pairedAt,
      Value<bool> revoked,
      Value<int> rowid,
    });

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKeyPem => $composableBuilder(
    column: $table.publicKeyPem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get revoked => $composableBuilder(
    column: $table.revoked,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKeyPem => $composableBuilder(
    column: $table.publicKeyPem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get revoked => $composableBuilder(
    column: $table.revoked,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get publicKeyPem => $composableBuilder(
    column: $table.publicKeyPem,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get pairedAt =>
      $composableBuilder(column: $table.pairedAt, builder: (column) => column);

  GeneratedColumn<bool> get revoked =>
      $composableBuilder(column: $table.revoked, builder: (column) => column);
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevicesTable,
          Device,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (Device, BaseReferences<_$AppDatabase, $DevicesTable, Device>),
          Device,
          PrefetchHooks Function()
        > {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> publicKeyPem = const Value.absent(),
                Value<DateTime> pairedAt = const Value.absent(),
                Value<bool> revoked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion(
                id: id,
                label: label,
                publicKeyPem: publicKeyPem,
                pairedAt: pairedAt,
                revoked: revoked,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required String publicKeyPem,
                required DateTime pairedAt,
                Value<bool> revoked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion.insert(
                id: id,
                label: label,
                publicKeyPem: publicKeyPem,
                pairedAt: pairedAt,
                revoked: revoked,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevicesTable,
      Device,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (Device, BaseReferences<_$AppDatabase, $DevicesTable, Device>),
      Device,
      PrefetchHooks Function()
    >;
typedef $$PairTokensTableCreateCompanionBuilder =
    PairTokensCompanion Function({
      required String token,
      required DateTime createdAt,
      required DateTime expiresAt,
      Value<bool> used,
      Value<String?> claimedByDeviceId,
      Value<int> rowid,
    });
typedef $$PairTokensTableUpdateCompanionBuilder =
    PairTokensCompanion Function({
      Value<String> token,
      Value<DateTime> createdAt,
      Value<DateTime> expiresAt,
      Value<bool> used,
      Value<String?> claimedByDeviceId,
      Value<int> rowid,
    });

class $$PairTokensTableFilterComposer
    extends Composer<_$AppDatabase, $PairTokensTable> {
  $$PairTokensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claimedByDeviceId => $composableBuilder(
    column: $table.claimedByDeviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PairTokensTableOrderingComposer
    extends Composer<_$AppDatabase, $PairTokensTable> {
  $$PairTokensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claimedByDeviceId => $composableBuilder(
    column: $table.claimedByDeviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PairTokensTableAnnotationComposer
    extends Composer<_$AppDatabase, $PairTokensTable> {
  $$PairTokensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get token =>
      $composableBuilder(column: $table.token, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<bool> get used =>
      $composableBuilder(column: $table.used, builder: (column) => column);

  GeneratedColumn<String> get claimedByDeviceId => $composableBuilder(
    column: $table.claimedByDeviceId,
    builder: (column) => column,
  );
}

class $$PairTokensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PairTokensTable,
          PairToken,
          $$PairTokensTableFilterComposer,
          $$PairTokensTableOrderingComposer,
          $$PairTokensTableAnnotationComposer,
          $$PairTokensTableCreateCompanionBuilder,
          $$PairTokensTableUpdateCompanionBuilder,
          (
            PairToken,
            BaseReferences<_$AppDatabase, $PairTokensTable, PairToken>,
          ),
          PairToken,
          PrefetchHooks Function()
        > {
  $$PairTokensTableTableManager(_$AppDatabase db, $PairTokensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PairTokensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PairTokensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PairTokensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> token = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<bool> used = const Value.absent(),
                Value<String?> claimedByDeviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PairTokensCompanion(
                token: token,
                createdAt: createdAt,
                expiresAt: expiresAt,
                used: used,
                claimedByDeviceId: claimedByDeviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String token,
                required DateTime createdAt,
                required DateTime expiresAt,
                Value<bool> used = const Value.absent(),
                Value<String?> claimedByDeviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PairTokensCompanion.insert(
                token: token,
                createdAt: createdAt,
                expiresAt: expiresAt,
                used: used,
                claimedByDeviceId: claimedByDeviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PairTokensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PairTokensTable,
      PairToken,
      $$PairTokensTableFilterComposer,
      $$PairTokensTableOrderingComposer,
      $$PairTokensTableAnnotationComposer,
      $$PairTokensTableCreateCompanionBuilder,
      $$PairTokensTableUpdateCompanionBuilder,
      (PairToken, BaseReferences<_$AppDatabase, $PairTokensTable, PairToken>),
      PairToken,
      PrefetchHooks Function()
    >;
typedef $$IdempotencyTableCreateCompanionBuilder =
    IdempotencyCompanion Function({
      required String key,
      required String responseJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$IdempotencyTableUpdateCompanionBuilder =
    IdempotencyCompanion Function({
      Value<String> key,
      Value<String> responseJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$IdempotencyTableFilterComposer
    extends Composer<_$AppDatabase, $IdempotencyTable> {
  $$IdempotencyTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IdempotencyTableOrderingComposer
    extends Composer<_$AppDatabase, $IdempotencyTable> {
  $$IdempotencyTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IdempotencyTableAnnotationComposer
    extends Composer<_$AppDatabase, $IdempotencyTable> {
  $$IdempotencyTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$IdempotencyTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IdempotencyTable,
          IdempotencyData,
          $$IdempotencyTableFilterComposer,
          $$IdempotencyTableOrderingComposer,
          $$IdempotencyTableAnnotationComposer,
          $$IdempotencyTableCreateCompanionBuilder,
          $$IdempotencyTableUpdateCompanionBuilder,
          (
            IdempotencyData,
            BaseReferences<_$AppDatabase, $IdempotencyTable, IdempotencyData>,
          ),
          IdempotencyData,
          PrefetchHooks Function()
        > {
  $$IdempotencyTableTableManager(_$AppDatabase db, $IdempotencyTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdempotencyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdempotencyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdempotencyTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> responseJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IdempotencyCompanion(
                key: key,
                responseJson: responseJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String responseJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => IdempotencyCompanion.insert(
                key: key,
                responseJson: responseJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IdempotencyTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IdempotencyTable,
      IdempotencyData,
      $$IdempotencyTableFilterComposer,
      $$IdempotencyTableOrderingComposer,
      $$IdempotencyTableAnnotationComposer,
      $$IdempotencyTableCreateCompanionBuilder,
      $$IdempotencyTableUpdateCompanionBuilder,
      (
        IdempotencyData,
        BaseReferences<_$AppDatabase, $IdempotencyTable, IdempotencyData>,
      ),
      IdempotencyData,
      PrefetchHooks Function()
    >;
typedef $$AuditEntriesTableCreateCompanionBuilder =
    AuditEntriesCompanion Function({
      required String id,
      required String type,
      required String title,
      Value<String?> tableId,
      required DateTime at,
      Value<String?> approvedBy,
      Value<String?> reason,
      Value<String?> actorUserId,
      Value<int> rowid,
    });
typedef $$AuditEntriesTableUpdateCompanionBuilder =
    AuditEntriesCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> title,
      Value<String?> tableId,
      Value<DateTime> at,
      Value<String?> approvedBy,
      Value<String?> reason,
      Value<String?> actorUserId,
      Value<int> rowid,
    });

class $$AuditEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AuditEntriesTable> {
  $$AuditEntriesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditEntriesTable> {
  $$AuditEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditEntriesTable> {
  $$AuditEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get tableId =>
      $composableBuilder(column: $table.tableId, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => column,
  );
}

class $$AuditEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditEntriesTable,
          AuditEntry,
          $$AuditEntriesTableFilterComposer,
          $$AuditEntriesTableOrderingComposer,
          $$AuditEntriesTableAnnotationComposer,
          $$AuditEntriesTableCreateCompanionBuilder,
          $$AuditEntriesTableUpdateCompanionBuilder,
          (
            AuditEntry,
            BaseReferences<_$AppDatabase, $AuditEntriesTable, AuditEntry>,
          ),
          AuditEntry,
          PrefetchHooks Function()
        > {
  $$AuditEntriesTableTableManager(_$AppDatabase db, $AuditEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> tableId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> actorUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditEntriesCompanion(
                id: id,
                type: type,
                title: title,
                tableId: tableId,
                at: at,
                approvedBy: approvedBy,
                reason: reason,
                actorUserId: actorUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String title,
                Value<String?> tableId = const Value.absent(),
                required DateTime at,
                Value<String?> approvedBy = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> actorUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditEntriesCompanion.insert(
                id: id,
                type: type,
                title: title,
                tableId: tableId,
                at: at,
                approvedBy: approvedBy,
                reason: reason,
                actorUserId: actorUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditEntriesTable,
      AuditEntry,
      $$AuditEntriesTableFilterComposer,
      $$AuditEntriesTableOrderingComposer,
      $$AuditEntriesTableAnnotationComposer,
      $$AuditEntriesTableCreateCompanionBuilder,
      $$AuditEntriesTableUpdateCompanionBuilder,
      (
        AuditEntry,
        BaseReferences<_$AppDatabase, $AuditEntriesTable, AuditEntry>,
      ),
      AuditEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$RolesTableTableManager get roles =>
      $$RolesTableTableManager(_db, _db.roles);
  $$ZonesTableTableManager get zones =>
      $$ZonesTableTableManager(_db, _db.zones);
  $$VenueTablesTableTableManager get venueTables =>
      $$VenueTablesTableTableManager(_db, _db.venueTables);
  $$MenuCategoriesTableTableManager get menuCategories =>
      $$MenuCategoriesTableTableManager(_db, _db.menuCategories);
  $$MenuItemsTableTableManager get menuItems =>
      $$MenuItemsTableTableManager(_db, _db.menuItems);
  $$ModifierGroupsTableTableManager get modifierGroups =>
      $$ModifierGroupsTableTableManager(_db, _db.modifierGroups);
  $$TicketsTableTableManager get tickets =>
      $$TicketsTableTableManager(_db, _db.tickets);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$PairTokensTableTableManager get pairTokens =>
      $$PairTokensTableTableManager(_db, _db.pairTokens);
  $$IdempotencyTableTableManager get idempotency =>
      $$IdempotencyTableTableManager(_db, _db.idempotency);
  $$AuditEntriesTableTableManager get auditEntries =>
      $$AuditEntriesTableTableManager(_db, _db.auditEntries);
}
