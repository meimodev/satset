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
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firebaseUidMeta = const VerificationMeta(
    'firebaseUid',
  );
  @override
  late final GeneratedColumn<String> firebaseUid = GeneratedColumn<String>(
    'firebase_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _avatarColorHexMeta = const VerificationMeta(
    'avatarColorHex',
  );
  @override
  late final GeneratedColumn<int> avatarColorHex = GeneratedColumn<int>(
    'avatar_color_hex',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    email,
    passwordHash,
    firebaseUid,
    disabled,
    avatarColorHex,
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
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    }
    if (data.containsKey('firebase_uid')) {
      context.handle(
        _firebaseUidMeta,
        firebaseUid.isAcceptableOrUnknown(
          data['firebase_uid']!,
          _firebaseUidMeta,
        ),
      );
    }
    if (data.containsKey('disabled')) {
      context.handle(
        _disabledMeta,
        disabled.isAcceptableOrUnknown(data['disabled']!, _disabledMeta),
      );
    }
    if (data.containsKey('avatar_color_hex')) {
      context.handle(
        _avatarColorHexMeta,
        avatarColorHex.isAcceptableOrUnknown(
          data['avatar_color_hex']!,
          _avatarColorHexMeta,
        ),
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
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      ),
      firebaseUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firebase_uid'],
      ),
      disabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}disabled'],
      )!,
      avatarColorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_color_hex'],
      ),
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
  final String? email;
  final String? passwordHash;

  /// Firebase Auth uid for admin rows auto-provisioned on first Firebase
  /// sign-in. Null for PIN/demo staff. Unique when present. See
  /// docs/adr/0015-firebase-admin-auth-and-server-kill-switch.md.
  final String? firebaseUid;
  final bool disabled;
  final int? avatarColorHex;
  final DateTime? shiftStartedAt;
  const User({
    required this.id,
    required this.name,
    required this.initials,
    required this.roleId,
    this.zoneAssigned,
    required this.pinHash,
    this.email,
    this.passwordHash,
    this.firebaseUid,
    required this.disabled,
    this.avatarColorHex,
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
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || passwordHash != null) {
      map['password_hash'] = Variable<String>(passwordHash);
    }
    if (!nullToAbsent || firebaseUid != null) {
      map['firebase_uid'] = Variable<String>(firebaseUid);
    }
    map['disabled'] = Variable<bool>(disabled);
    if (!nullToAbsent || avatarColorHex != null) {
      map['avatar_color_hex'] = Variable<int>(avatarColorHex);
    }
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
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      passwordHash: passwordHash == null && nullToAbsent
          ? const Value.absent()
          : Value(passwordHash),
      firebaseUid: firebaseUid == null && nullToAbsent
          ? const Value.absent()
          : Value(firebaseUid),
      disabled: Value(disabled),
      avatarColorHex: avatarColorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarColorHex),
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
      email: serializer.fromJson<String?>(json['email']),
      passwordHash: serializer.fromJson<String?>(json['passwordHash']),
      firebaseUid: serializer.fromJson<String?>(json['firebaseUid']),
      disabled: serializer.fromJson<bool>(json['disabled']),
      avatarColorHex: serializer.fromJson<int?>(json['avatarColorHex']),
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
      'email': serializer.toJson<String?>(email),
      'passwordHash': serializer.toJson<String?>(passwordHash),
      'firebaseUid': serializer.toJson<String?>(firebaseUid),
      'disabled': serializer.toJson<bool>(disabled),
      'avatarColorHex': serializer.toJson<int?>(avatarColorHex),
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
    Value<String?> email = const Value.absent(),
    Value<String?> passwordHash = const Value.absent(),
    Value<String?> firebaseUid = const Value.absent(),
    bool? disabled,
    Value<int?> avatarColorHex = const Value.absent(),
    Value<DateTime?> shiftStartedAt = const Value.absent(),
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    initials: initials ?? this.initials,
    roleId: roleId ?? this.roleId,
    zoneAssigned: zoneAssigned.present ? zoneAssigned.value : this.zoneAssigned,
    pinHash: pinHash ?? this.pinHash,
    email: email.present ? email.value : this.email,
    passwordHash: passwordHash.present ? passwordHash.value : this.passwordHash,
    firebaseUid: firebaseUid.present ? firebaseUid.value : this.firebaseUid,
    disabled: disabled ?? this.disabled,
    avatarColorHex: avatarColorHex.present
        ? avatarColorHex.value
        : this.avatarColorHex,
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
      email: data.email.present ? data.email.value : this.email,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      firebaseUid: data.firebaseUid.present
          ? data.firebaseUid.value
          : this.firebaseUid,
      disabled: data.disabled.present ? data.disabled.value : this.disabled,
      avatarColorHex: data.avatarColorHex.present
          ? data.avatarColorHex.value
          : this.avatarColorHex,
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
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('firebaseUid: $firebaseUid, ')
          ..write('disabled: $disabled, ')
          ..write('avatarColorHex: $avatarColorHex, ')
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
    email,
    passwordHash,
    firebaseUid,
    disabled,
    avatarColorHex,
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
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.firebaseUid == this.firebaseUid &&
          other.disabled == this.disabled &&
          other.avatarColorHex == this.avatarColorHex &&
          other.shiftStartedAt == this.shiftStartedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> initials;
  final Value<String> roleId;
  final Value<String?> zoneAssigned;
  final Value<String> pinHash;
  final Value<String?> email;
  final Value<String?> passwordHash;
  final Value<String?> firebaseUid;
  final Value<bool> disabled;
  final Value<int?> avatarColorHex;
  final Value<DateTime?> shiftStartedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.initials = const Value.absent(),
    this.roleId = const Value.absent(),
    this.zoneAssigned = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.firebaseUid = const Value.absent(),
    this.disabled = const Value.absent(),
    this.avatarColorHex = const Value.absent(),
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
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.firebaseUid = const Value.absent(),
    this.disabled = const Value.absent(),
    this.avatarColorHex = const Value.absent(),
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
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<String>? firebaseUid,
    Expression<bool>? disabled,
    Expression<int>? avatarColorHex,
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
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (firebaseUid != null) 'firebase_uid': firebaseUid,
      if (disabled != null) 'disabled': disabled,
      if (avatarColorHex != null) 'avatar_color_hex': avatarColorHex,
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
    Value<String?>? email,
    Value<String?>? passwordHash,
    Value<String?>? firebaseUid,
    Value<bool>? disabled,
    Value<int?>? avatarColorHex,
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
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      disabled: disabled ?? this.disabled,
      avatarColorHex: avatarColorHex ?? this.avatarColorHex,
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
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (firebaseUid.present) {
      map['firebase_uid'] = Variable<String>(firebaseUid.value);
    }
    if (disabled.present) {
      map['disabled'] = Variable<bool>(disabled.value);
    }
    if (avatarColorHex.present) {
      map['avatar_color_hex'] = Variable<int>(avatarColorHex.value);
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
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('firebaseUid: $firebaseUid, ')
          ..write('disabled: $disabled, ')
          ..write('avatarColorHex: $avatarColorHex, ')
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
  static const VerificationMeta _capacityMeta = const VerificationMeta(
    'capacity',
  );
  @override
  late final GeneratedColumn<int> capacity = GeneratedColumn<int>(
    'capacity',
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
  static const VerificationMeta _lockedByMeta = const VerificationMeta(
    'lockedBy',
  );
  @override
  late final GeneratedColumn<String> lockedBy = GeneratedColumn<String>(
    'locked_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockedByNameMeta = const VerificationMeta(
    'lockedByName',
  );
  @override
  late final GeneratedColumn<String> lockedByName = GeneratedColumn<String>(
    'locked_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockedAtMeta = const VerificationMeta(
    'lockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lockedAt = GeneratedColumn<DateTime>(
    'locked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockExpiresAtMeta = const VerificationMeta(
    'lockExpiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> lockExpiresAt =
      GeneratedColumn<DateTime>(
        'lock_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guestNameMeta = const VerificationMeta(
    'guestName',
  );
  @override
  late final GeneratedColumn<String> guestName = GeneratedColumn<String>(
    'guest_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guestNotesMeta = const VerificationMeta(
    'guestNotes',
  );
  @override
  late final GeneratedColumn<String> guestNotes = GeneratedColumn<String>(
    'guest_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reservationIdMeta = const VerificationMeta(
    'reservationId',
  );
  @override
  late final GeneratedColumn<String> reservationId = GeneratedColumn<String>(
    'reservation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentVisitIdMeta = const VerificationMeta(
    'currentVisitId',
  );
  @override
  late final GeneratedColumn<String> currentVisitId = GeneratedColumn<String>(
    'current_visit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _billClosedAtMeta = const VerificationMeta(
    'billClosedAt',
  );
  @override
  late final GeneratedColumn<DateTime> billClosedAt = GeneratedColumn<DateTime>(
    'bill_closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moneyStateMeta = const VerificationMeta(
    'moneyState',
  );
  @override
  late final GeneratedColumn<String> moneyState = GeneratedColumn<String>(
    'money_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guestOrderingEnabledMeta =
      const VerificationMeta('guestOrderingEnabled');
  @override
  late final GeneratedColumn<bool> guestOrderingEnabled = GeneratedColumn<bool>(
    'guest_ordering_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("guest_ordering_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    zoneId,
    label,
    pax,
    capacity,
    active,
    status,
    openAmount,
    readyCount,
    lastActorId,
    lockedBy,
    lockedByName,
    lockedAt,
    lockExpiresAt,
    openedAt,
    guestName,
    guestNotes,
    reservationId,
    currentVisitId,
    billClosedAt,
    moneyState,
    guestOrderingEnabled,
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
    if (data.containsKey('capacity')) {
      context.handle(
        _capacityMeta,
        capacity.isAcceptableOrUnknown(data['capacity']!, _capacityMeta),
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
    if (data.containsKey('locked_by')) {
      context.handle(
        _lockedByMeta,
        lockedBy.isAcceptableOrUnknown(data['locked_by']!, _lockedByMeta),
      );
    }
    if (data.containsKey('locked_by_name')) {
      context.handle(
        _lockedByNameMeta,
        lockedByName.isAcceptableOrUnknown(
          data['locked_by_name']!,
          _lockedByNameMeta,
        ),
      );
    }
    if (data.containsKey('locked_at')) {
      context.handle(
        _lockedAtMeta,
        lockedAt.isAcceptableOrUnknown(data['locked_at']!, _lockedAtMeta),
      );
    }
    if (data.containsKey('lock_expires_at')) {
      context.handle(
        _lockExpiresAtMeta,
        lockExpiresAt.isAcceptableOrUnknown(
          data['lock_expires_at']!,
          _lockExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('guest_name')) {
      context.handle(
        _guestNameMeta,
        guestName.isAcceptableOrUnknown(data['guest_name']!, _guestNameMeta),
      );
    }
    if (data.containsKey('guest_notes')) {
      context.handle(
        _guestNotesMeta,
        guestNotes.isAcceptableOrUnknown(data['guest_notes']!, _guestNotesMeta),
      );
    }
    if (data.containsKey('reservation_id')) {
      context.handle(
        _reservationIdMeta,
        reservationId.isAcceptableOrUnknown(
          data['reservation_id']!,
          _reservationIdMeta,
        ),
      );
    }
    if (data.containsKey('current_visit_id')) {
      context.handle(
        _currentVisitIdMeta,
        currentVisitId.isAcceptableOrUnknown(
          data['current_visit_id']!,
          _currentVisitIdMeta,
        ),
      );
    }
    if (data.containsKey('bill_closed_at')) {
      context.handle(
        _billClosedAtMeta,
        billClosedAt.isAcceptableOrUnknown(
          data['bill_closed_at']!,
          _billClosedAtMeta,
        ),
      );
    }
    if (data.containsKey('money_state')) {
      context.handle(
        _moneyStateMeta,
        moneyState.isAcceptableOrUnknown(data['money_state']!, _moneyStateMeta),
      );
    }
    if (data.containsKey('guest_ordering_enabled')) {
      context.handle(
        _guestOrderingEnabledMeta,
        guestOrderingEnabled.isAcceptableOrUnknown(
          data['guest_ordering_enabled']!,
          _guestOrderingEnabledMeta,
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
      capacity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}capacity'],
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
      lockedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locked_by'],
      ),
      lockedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locked_by_name'],
      ),
      lockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_at'],
      ),
      lockExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lock_expires_at'],
      ),
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      ),
      guestName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guest_name'],
      ),
      guestNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guest_notes'],
      ),
      reservationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reservation_id'],
      ),
      currentVisitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_visit_id'],
      ),
      billClosedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}bill_closed_at'],
      ),
      moneyState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}money_state'],
      ),
      guestOrderingEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}guest_ordering_enabled'],
      )!,
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
  final int capacity;
  final bool active;
  final String status;
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

  /// The live [[Visit]] currently attached to this table (null ⇒ kosong).
  /// A visit is detached at table-close (table freed for reuse) but lives on
  /// until bill-close — so the table's *current* visit is this id, never an
  /// older detached one still open on the cashier. See ADR-0024.
  final String? currentVisitId;

  /// Mirror of the current visit's bill-close, for the floor's **Lunas** pill:
  /// set when the cashier locks the bill while the table is still occupied
  /// (guests lingering), cleared when the table is freed/reused. Denormalised
  /// so the floor needn't subscribe to bills. See ADR-0024.
  final DateTime? billClosedAt;

  /// Live settlement state of the current visit, denormalised for the floor's
  /// money badge: `partial` (some paid, still owing) | `paid` (fully paid, not
  /// yet locked) | null (nothing paid). `openAmount` carries the **outstanding**
  /// rupiah. Kept in sync on order/serve/void + every payment. See ADR-0024.
  final String? moneyState;

  /// Per-table opt-in for guest QR self-ordering (ADR-0027/0028). A table only
  /// exposes a working QR when this AND the venue master toggle
  /// (`VenueSettings.guestOrderingEnabled`) are both true. Default off.
  final bool guestOrderingEnabled;
  const VenueTable({
    required this.id,
    required this.zoneId,
    this.label,
    required this.pax,
    required this.capacity,
    required this.active,
    required this.status,
    required this.openAmount,
    required this.readyCount,
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
    this.billClosedAt,
    this.moneyState,
    required this.guestOrderingEnabled,
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
    map['capacity'] = Variable<int>(capacity);
    map['active'] = Variable<bool>(active);
    map['status'] = Variable<String>(status);
    map['open_amount'] = Variable<int>(openAmount);
    map['ready_count'] = Variable<int>(readyCount);
    if (!nullToAbsent || lastActorId != null) {
      map['last_actor_id'] = Variable<String>(lastActorId);
    }
    if (!nullToAbsent || lockedBy != null) {
      map['locked_by'] = Variable<String>(lockedBy);
    }
    if (!nullToAbsent || lockedByName != null) {
      map['locked_by_name'] = Variable<String>(lockedByName);
    }
    if (!nullToAbsent || lockedAt != null) {
      map['locked_at'] = Variable<DateTime>(lockedAt);
    }
    if (!nullToAbsent || lockExpiresAt != null) {
      map['lock_expires_at'] = Variable<DateTime>(lockExpiresAt);
    }
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    if (!nullToAbsent || guestName != null) {
      map['guest_name'] = Variable<String>(guestName);
    }
    if (!nullToAbsent || guestNotes != null) {
      map['guest_notes'] = Variable<String>(guestNotes);
    }
    if (!nullToAbsent || reservationId != null) {
      map['reservation_id'] = Variable<String>(reservationId);
    }
    if (!nullToAbsent || currentVisitId != null) {
      map['current_visit_id'] = Variable<String>(currentVisitId);
    }
    if (!nullToAbsent || billClosedAt != null) {
      map['bill_closed_at'] = Variable<DateTime>(billClosedAt);
    }
    if (!nullToAbsent || moneyState != null) {
      map['money_state'] = Variable<String>(moneyState);
    }
    map['guest_ordering_enabled'] = Variable<bool>(guestOrderingEnabled);
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
      capacity: Value(capacity),
      active: Value(active),
      status: Value(status),
      openAmount: Value(openAmount),
      readyCount: Value(readyCount),
      lastActorId: lastActorId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActorId),
      lockedBy: lockedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedBy),
      lockedByName: lockedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedByName),
      lockedAt: lockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedAt),
      lockExpiresAt: lockExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lockExpiresAt),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      guestName: guestName == null && nullToAbsent
          ? const Value.absent()
          : Value(guestName),
      guestNotes: guestNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(guestNotes),
      reservationId: reservationId == null && nullToAbsent
          ? const Value.absent()
          : Value(reservationId),
      currentVisitId: currentVisitId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentVisitId),
      billClosedAt: billClosedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(billClosedAt),
      moneyState: moneyState == null && nullToAbsent
          ? const Value.absent()
          : Value(moneyState),
      guestOrderingEnabled: Value(guestOrderingEnabled),
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
      capacity: serializer.fromJson<int>(json['capacity']),
      active: serializer.fromJson<bool>(json['active']),
      status: serializer.fromJson<String>(json['status']),
      openAmount: serializer.fromJson<int>(json['openAmount']),
      readyCount: serializer.fromJson<int>(json['readyCount']),
      lastActorId: serializer.fromJson<String?>(json['lastActorId']),
      lockedBy: serializer.fromJson<String?>(json['lockedBy']),
      lockedByName: serializer.fromJson<String?>(json['lockedByName']),
      lockedAt: serializer.fromJson<DateTime?>(json['lockedAt']),
      lockExpiresAt: serializer.fromJson<DateTime?>(json['lockExpiresAt']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
      guestName: serializer.fromJson<String?>(json['guestName']),
      guestNotes: serializer.fromJson<String?>(json['guestNotes']),
      reservationId: serializer.fromJson<String?>(json['reservationId']),
      currentVisitId: serializer.fromJson<String?>(json['currentVisitId']),
      billClosedAt: serializer.fromJson<DateTime?>(json['billClosedAt']),
      moneyState: serializer.fromJson<String?>(json['moneyState']),
      guestOrderingEnabled: serializer.fromJson<bool>(
        json['guestOrderingEnabled'],
      ),
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
      'capacity': serializer.toJson<int>(capacity),
      'active': serializer.toJson<bool>(active),
      'status': serializer.toJson<String>(status),
      'openAmount': serializer.toJson<int>(openAmount),
      'readyCount': serializer.toJson<int>(readyCount),
      'lastActorId': serializer.toJson<String?>(lastActorId),
      'lockedBy': serializer.toJson<String?>(lockedBy),
      'lockedByName': serializer.toJson<String?>(lockedByName),
      'lockedAt': serializer.toJson<DateTime?>(lockedAt),
      'lockExpiresAt': serializer.toJson<DateTime?>(lockExpiresAt),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'guestName': serializer.toJson<String?>(guestName),
      'guestNotes': serializer.toJson<String?>(guestNotes),
      'reservationId': serializer.toJson<String?>(reservationId),
      'currentVisitId': serializer.toJson<String?>(currentVisitId),
      'billClosedAt': serializer.toJson<DateTime?>(billClosedAt),
      'moneyState': serializer.toJson<String?>(moneyState),
      'guestOrderingEnabled': serializer.toJson<bool>(guestOrderingEnabled),
    };
  }

  VenueTable copyWith({
    String? id,
    String? zoneId,
    Value<String?> label = const Value.absent(),
    int? pax,
    int? capacity,
    bool? active,
    String? status,
    int? openAmount,
    int? readyCount,
    Value<String?> lastActorId = const Value.absent(),
    Value<String?> lockedBy = const Value.absent(),
    Value<String?> lockedByName = const Value.absent(),
    Value<DateTime?> lockedAt = const Value.absent(),
    Value<DateTime?> lockExpiresAt = const Value.absent(),
    Value<DateTime?> openedAt = const Value.absent(),
    Value<String?> guestName = const Value.absent(),
    Value<String?> guestNotes = const Value.absent(),
    Value<String?> reservationId = const Value.absent(),
    Value<String?> currentVisitId = const Value.absent(),
    Value<DateTime?> billClosedAt = const Value.absent(),
    Value<String?> moneyState = const Value.absent(),
    bool? guestOrderingEnabled,
  }) => VenueTable(
    id: id ?? this.id,
    zoneId: zoneId ?? this.zoneId,
    label: label.present ? label.value : this.label,
    pax: pax ?? this.pax,
    capacity: capacity ?? this.capacity,
    active: active ?? this.active,
    status: status ?? this.status,
    openAmount: openAmount ?? this.openAmount,
    readyCount: readyCount ?? this.readyCount,
    lastActorId: lastActorId.present ? lastActorId.value : this.lastActorId,
    lockedBy: lockedBy.present ? lockedBy.value : this.lockedBy,
    lockedByName: lockedByName.present ? lockedByName.value : this.lockedByName,
    lockedAt: lockedAt.present ? lockedAt.value : this.lockedAt,
    lockExpiresAt: lockExpiresAt.present
        ? lockExpiresAt.value
        : this.lockExpiresAt,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    guestName: guestName.present ? guestName.value : this.guestName,
    guestNotes: guestNotes.present ? guestNotes.value : this.guestNotes,
    reservationId: reservationId.present
        ? reservationId.value
        : this.reservationId,
    currentVisitId: currentVisitId.present
        ? currentVisitId.value
        : this.currentVisitId,
    billClosedAt: billClosedAt.present ? billClosedAt.value : this.billClosedAt,
    moneyState: moneyState.present ? moneyState.value : this.moneyState,
    guestOrderingEnabled: guestOrderingEnabled ?? this.guestOrderingEnabled,
  );
  VenueTable copyWithCompanion(VenueTablesCompanion data) {
    return VenueTable(
      id: data.id.present ? data.id.value : this.id,
      zoneId: data.zoneId.present ? data.zoneId.value : this.zoneId,
      label: data.label.present ? data.label.value : this.label,
      pax: data.pax.present ? data.pax.value : this.pax,
      capacity: data.capacity.present ? data.capacity.value : this.capacity,
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
      lockedBy: data.lockedBy.present ? data.lockedBy.value : this.lockedBy,
      lockedByName: data.lockedByName.present
          ? data.lockedByName.value
          : this.lockedByName,
      lockedAt: data.lockedAt.present ? data.lockedAt.value : this.lockedAt,
      lockExpiresAt: data.lockExpiresAt.present
          ? data.lockExpiresAt.value
          : this.lockExpiresAt,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      guestName: data.guestName.present ? data.guestName.value : this.guestName,
      guestNotes: data.guestNotes.present
          ? data.guestNotes.value
          : this.guestNotes,
      reservationId: data.reservationId.present
          ? data.reservationId.value
          : this.reservationId,
      currentVisitId: data.currentVisitId.present
          ? data.currentVisitId.value
          : this.currentVisitId,
      billClosedAt: data.billClosedAt.present
          ? data.billClosedAt.value
          : this.billClosedAt,
      moneyState: data.moneyState.present
          ? data.moneyState.value
          : this.moneyState,
      guestOrderingEnabled: data.guestOrderingEnabled.present
          ? data.guestOrderingEnabled.value
          : this.guestOrderingEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VenueTable(')
          ..write('id: $id, ')
          ..write('zoneId: $zoneId, ')
          ..write('label: $label, ')
          ..write('pax: $pax, ')
          ..write('capacity: $capacity, ')
          ..write('active: $active, ')
          ..write('status: $status, ')
          ..write('openAmount: $openAmount, ')
          ..write('readyCount: $readyCount, ')
          ..write('lastActorId: $lastActorId, ')
          ..write('lockedBy: $lockedBy, ')
          ..write('lockedByName: $lockedByName, ')
          ..write('lockedAt: $lockedAt, ')
          ..write('lockExpiresAt: $lockExpiresAt, ')
          ..write('openedAt: $openedAt, ')
          ..write('guestName: $guestName, ')
          ..write('guestNotes: $guestNotes, ')
          ..write('reservationId: $reservationId, ')
          ..write('currentVisitId: $currentVisitId, ')
          ..write('billClosedAt: $billClosedAt, ')
          ..write('moneyState: $moneyState, ')
          ..write('guestOrderingEnabled: $guestOrderingEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    zoneId,
    label,
    pax,
    capacity,
    active,
    status,
    openAmount,
    readyCount,
    lastActorId,
    lockedBy,
    lockedByName,
    lockedAt,
    lockExpiresAt,
    openedAt,
    guestName,
    guestNotes,
    reservationId,
    currentVisitId,
    billClosedAt,
    moneyState,
    guestOrderingEnabled,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VenueTable &&
          other.id == this.id &&
          other.zoneId == this.zoneId &&
          other.label == this.label &&
          other.pax == this.pax &&
          other.capacity == this.capacity &&
          other.active == this.active &&
          other.status == this.status &&
          other.openAmount == this.openAmount &&
          other.readyCount == this.readyCount &&
          other.lastActorId == this.lastActorId &&
          other.lockedBy == this.lockedBy &&
          other.lockedByName == this.lockedByName &&
          other.lockedAt == this.lockedAt &&
          other.lockExpiresAt == this.lockExpiresAt &&
          other.openedAt == this.openedAt &&
          other.guestName == this.guestName &&
          other.guestNotes == this.guestNotes &&
          other.reservationId == this.reservationId &&
          other.currentVisitId == this.currentVisitId &&
          other.billClosedAt == this.billClosedAt &&
          other.moneyState == this.moneyState &&
          other.guestOrderingEnabled == this.guestOrderingEnabled);
}

class VenueTablesCompanion extends UpdateCompanion<VenueTable> {
  final Value<String> id;
  final Value<String> zoneId;
  final Value<String?> label;
  final Value<int> pax;
  final Value<int> capacity;
  final Value<bool> active;
  final Value<String> status;
  final Value<int> openAmount;
  final Value<int> readyCount;
  final Value<String?> lastActorId;
  final Value<String?> lockedBy;
  final Value<String?> lockedByName;
  final Value<DateTime?> lockedAt;
  final Value<DateTime?> lockExpiresAt;
  final Value<DateTime?> openedAt;
  final Value<String?> guestName;
  final Value<String?> guestNotes;
  final Value<String?> reservationId;
  final Value<String?> currentVisitId;
  final Value<DateTime?> billClosedAt;
  final Value<String?> moneyState;
  final Value<bool> guestOrderingEnabled;
  final Value<int> rowid;
  const VenueTablesCompanion({
    this.id = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.label = const Value.absent(),
    this.pax = const Value.absent(),
    this.capacity = const Value.absent(),
    this.active = const Value.absent(),
    this.status = const Value.absent(),
    this.openAmount = const Value.absent(),
    this.readyCount = const Value.absent(),
    this.lastActorId = const Value.absent(),
    this.lockedBy = const Value.absent(),
    this.lockedByName = const Value.absent(),
    this.lockedAt = const Value.absent(),
    this.lockExpiresAt = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.guestName = const Value.absent(),
    this.guestNotes = const Value.absent(),
    this.reservationId = const Value.absent(),
    this.currentVisitId = const Value.absent(),
    this.billClosedAt = const Value.absent(),
    this.moneyState = const Value.absent(),
    this.guestOrderingEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VenueTablesCompanion.insert({
    required String id,
    required String zoneId,
    this.label = const Value.absent(),
    this.pax = const Value.absent(),
    this.capacity = const Value.absent(),
    this.active = const Value.absent(),
    this.status = const Value.absent(),
    this.openAmount = const Value.absent(),
    this.readyCount = const Value.absent(),
    this.lastActorId = const Value.absent(),
    this.lockedBy = const Value.absent(),
    this.lockedByName = const Value.absent(),
    this.lockedAt = const Value.absent(),
    this.lockExpiresAt = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.guestName = const Value.absent(),
    this.guestNotes = const Value.absent(),
    this.reservationId = const Value.absent(),
    this.currentVisitId = const Value.absent(),
    this.billClosedAt = const Value.absent(),
    this.moneyState = const Value.absent(),
    this.guestOrderingEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       zoneId = Value(zoneId);
  static Insertable<VenueTable> custom({
    Expression<String>? id,
    Expression<String>? zoneId,
    Expression<String>? label,
    Expression<int>? pax,
    Expression<int>? capacity,
    Expression<bool>? active,
    Expression<String>? status,
    Expression<int>? openAmount,
    Expression<int>? readyCount,
    Expression<String>? lastActorId,
    Expression<String>? lockedBy,
    Expression<String>? lockedByName,
    Expression<DateTime>? lockedAt,
    Expression<DateTime>? lockExpiresAt,
    Expression<DateTime>? openedAt,
    Expression<String>? guestName,
    Expression<String>? guestNotes,
    Expression<String>? reservationId,
    Expression<String>? currentVisitId,
    Expression<DateTime>? billClosedAt,
    Expression<String>? moneyState,
    Expression<bool>? guestOrderingEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (zoneId != null) 'zone_id': zoneId,
      if (label != null) 'label': label,
      if (pax != null) 'pax': pax,
      if (capacity != null) 'capacity': capacity,
      if (active != null) 'active': active,
      if (status != null) 'status': status,
      if (openAmount != null) 'open_amount': openAmount,
      if (readyCount != null) 'ready_count': readyCount,
      if (lastActorId != null) 'last_actor_id': lastActorId,
      if (lockedBy != null) 'locked_by': lockedBy,
      if (lockedByName != null) 'locked_by_name': lockedByName,
      if (lockedAt != null) 'locked_at': lockedAt,
      if (lockExpiresAt != null) 'lock_expires_at': lockExpiresAt,
      if (openedAt != null) 'opened_at': openedAt,
      if (guestName != null) 'guest_name': guestName,
      if (guestNotes != null) 'guest_notes': guestNotes,
      if (reservationId != null) 'reservation_id': reservationId,
      if (currentVisitId != null) 'current_visit_id': currentVisitId,
      if (billClosedAt != null) 'bill_closed_at': billClosedAt,
      if (moneyState != null) 'money_state': moneyState,
      if (guestOrderingEnabled != null)
        'guest_ordering_enabled': guestOrderingEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VenueTablesCompanion copyWith({
    Value<String>? id,
    Value<String>? zoneId,
    Value<String?>? label,
    Value<int>? pax,
    Value<int>? capacity,
    Value<bool>? active,
    Value<String>? status,
    Value<int>? openAmount,
    Value<int>? readyCount,
    Value<String?>? lastActorId,
    Value<String?>? lockedBy,
    Value<String?>? lockedByName,
    Value<DateTime?>? lockedAt,
    Value<DateTime?>? lockExpiresAt,
    Value<DateTime?>? openedAt,
    Value<String?>? guestName,
    Value<String?>? guestNotes,
    Value<String?>? reservationId,
    Value<String?>? currentVisitId,
    Value<DateTime?>? billClosedAt,
    Value<String?>? moneyState,
    Value<bool>? guestOrderingEnabled,
    Value<int>? rowid,
  }) {
    return VenueTablesCompanion(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      label: label ?? this.label,
      pax: pax ?? this.pax,
      capacity: capacity ?? this.capacity,
      active: active ?? this.active,
      status: status ?? this.status,
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
      billClosedAt: billClosedAt ?? this.billClosedAt,
      moneyState: moneyState ?? this.moneyState,
      guestOrderingEnabled: guestOrderingEnabled ?? this.guestOrderingEnabled,
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
    if (capacity.present) {
      map['capacity'] = Variable<int>(capacity.value);
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
    if (lockedBy.present) {
      map['locked_by'] = Variable<String>(lockedBy.value);
    }
    if (lockedByName.present) {
      map['locked_by_name'] = Variable<String>(lockedByName.value);
    }
    if (lockedAt.present) {
      map['locked_at'] = Variable<DateTime>(lockedAt.value);
    }
    if (lockExpiresAt.present) {
      map['lock_expires_at'] = Variable<DateTime>(lockExpiresAt.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (guestName.present) {
      map['guest_name'] = Variable<String>(guestName.value);
    }
    if (guestNotes.present) {
      map['guest_notes'] = Variable<String>(guestNotes.value);
    }
    if (reservationId.present) {
      map['reservation_id'] = Variable<String>(reservationId.value);
    }
    if (currentVisitId.present) {
      map['current_visit_id'] = Variable<String>(currentVisitId.value);
    }
    if (billClosedAt.present) {
      map['bill_closed_at'] = Variable<DateTime>(billClosedAt.value);
    }
    if (moneyState.present) {
      map['money_state'] = Variable<String>(moneyState.value);
    }
    if (guestOrderingEnabled.present) {
      map['guest_ordering_enabled'] = Variable<bool>(
        guestOrderingEnabled.value,
      );
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
          ..write('capacity: $capacity, ')
          ..write('active: $active, ')
          ..write('status: $status, ')
          ..write('openAmount: $openAmount, ')
          ..write('readyCount: $readyCount, ')
          ..write('lastActorId: $lastActorId, ')
          ..write('lockedBy: $lockedBy, ')
          ..write('lockedByName: $lockedByName, ')
          ..write('lockedAt: $lockedAt, ')
          ..write('lockExpiresAt: $lockExpiresAt, ')
          ..write('openedAt: $openedAt, ')
          ..write('guestName: $guestName, ')
          ..write('guestNotes: $guestNotes, ')
          ..write('reservationId: $reservationId, ')
          ..write('currentVisitId: $currentVisitId, ')
          ..write('billClosedAt: $billClosedAt, ')
          ..write('moneyState: $moneyState, ')
          ..write('guestOrderingEnabled: $guestOrderingEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitsTable extends Visits with TableInfo<$VisitsTable, Visit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tableLabelMeta = const VerificationMeta(
    'tableLabel',
  );
  @override
  late final GeneratedColumn<String> tableLabel = GeneratedColumn<String>(
    'table_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zoneIdMeta = const VerificationMeta('zoneId');
  @override
  late final GeneratedColumn<String> zoneId = GeneratedColumn<String>(
    'zone_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _paxMeta = const VerificationMeta('pax');
  @override
  late final GeneratedColumn<int> pax = GeneratedColumn<int>(
    'pax',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guestNameMeta = const VerificationMeta(
    'guestName',
  );
  @override
  late final GeneratedColumn<String> guestName = GeneratedColumn<String>(
    'guest_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guestNotesMeta = const VerificationMeta(
    'guestNotes',
  );
  @override
  late final GeneratedColumn<String> guestNotes = GeneratedColumn<String>(
    'guest_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reservationIdMeta = const VerificationMeta(
    'reservationId',
  );
  @override
  late final GeneratedColumn<String> reservationId = GeneratedColumn<String>(
    'reservation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _tableFreedAtMeta = const VerificationMeta(
    'tableFreedAt',
  );
  @override
  late final GeneratedColumn<DateTime> tableFreedAt = GeneratedColumn<DateTime>(
    'table_freed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _billClosedAtMeta = const VerificationMeta(
    'billClosedAt',
  );
  @override
  late final GeneratedColumn<DateTime> billClosedAt = GeneratedColumn<DateTime>(
    'bill_closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _billClosedByMeta = const VerificationMeta(
    'billClosedBy',
  );
  @override
  late final GeneratedColumn<String> billClosedBy = GeneratedColumn<String>(
    'bill_closed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lossAmountMeta = const VerificationMeta(
    'lossAmount',
  );
  @override
  late final GeneratedColumn<int> lossAmount = GeneratedColumn<int>(
    'loss_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dineIn'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tableId,
    tableLabel,
    zoneId,
    pax,
    openedAt,
    guestName,
    guestNotes,
    reservationId,
    lastActorId,
    tableFreedAt,
    billClosedAt,
    billClosedBy,
    lossAmount,
    createdAt,
    kind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Visit> instance, {
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
    if (data.containsKey('table_label')) {
      context.handle(
        _tableLabelMeta,
        tableLabel.isAcceptableOrUnknown(data['table_label']!, _tableLabelMeta),
      );
    }
    if (data.containsKey('zone_id')) {
      context.handle(
        _zoneIdMeta,
        zoneId.isAcceptableOrUnknown(data['zone_id']!, _zoneIdMeta),
      );
    }
    if (data.containsKey('pax')) {
      context.handle(
        _paxMeta,
        pax.isAcceptableOrUnknown(data['pax']!, _paxMeta),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('guest_name')) {
      context.handle(
        _guestNameMeta,
        guestName.isAcceptableOrUnknown(data['guest_name']!, _guestNameMeta),
      );
    }
    if (data.containsKey('guest_notes')) {
      context.handle(
        _guestNotesMeta,
        guestNotes.isAcceptableOrUnknown(data['guest_notes']!, _guestNotesMeta),
      );
    }
    if (data.containsKey('reservation_id')) {
      context.handle(
        _reservationIdMeta,
        reservationId.isAcceptableOrUnknown(
          data['reservation_id']!,
          _reservationIdMeta,
        ),
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
    if (data.containsKey('table_freed_at')) {
      context.handle(
        _tableFreedAtMeta,
        tableFreedAt.isAcceptableOrUnknown(
          data['table_freed_at']!,
          _tableFreedAtMeta,
        ),
      );
    }
    if (data.containsKey('bill_closed_at')) {
      context.handle(
        _billClosedAtMeta,
        billClosedAt.isAcceptableOrUnknown(
          data['bill_closed_at']!,
          _billClosedAtMeta,
        ),
      );
    }
    if (data.containsKey('bill_closed_by')) {
      context.handle(
        _billClosedByMeta,
        billClosedBy.isAcceptableOrUnknown(
          data['bill_closed_by']!,
          _billClosedByMeta,
        ),
      );
    }
    if (data.containsKey('loss_amount')) {
      context.handle(
        _lossAmountMeta,
        lossAmount.isAcceptableOrUnknown(data['loss_amount']!, _lossAmountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Visit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Visit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_id'],
      )!,
      tableLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_label'],
      ),
      zoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_id'],
      )!,
      pax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pax'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      ),
      guestName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guest_name'],
      ),
      guestNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guest_notes'],
      ),
      reservationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reservation_id'],
      ),
      lastActorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_actor_id'],
      ),
      tableFreedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}table_freed_at'],
      ),
      billClosedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}bill_closed_at'],
      ),
      billClosedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_closed_by'],
      ),
      lossAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loss_amount'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  $VisitsTable createAlias(String alias) {
    return $VisitsTable(attachedDatabase, alias);
  }
}

class Visit extends DataClass implements Insertable<Visit> {
  final String id;
  final String tableId;
  final String? tableLabel;
  final String zoneId;
  final int pax;
  final DateTime? openedAt;
  final String? guestName;
  final String? guestNotes;
  final String? reservationId;
  final String? lastActorId;

  /// Set when the waiter frees the table (table-close / detach). Non-null ⇒
  /// the visit is detached: floor shows the table kosong, the cashier still
  /// lists this bill, flagged.
  final DateTime? tableFreedAt;

  /// Set when the cashier closes the bill (lock). Non-null ⇒ the bill is
  /// locked and off the active cashier list. The visit is **snapshotted +
  /// deleted only when BOTH `tableFreedAt` and `billClosedAt` are set** (the
  /// second act completes the pair); whichever act lands first just stamps its
  /// timestamp and keeps the visit live. See ADR-0024.
  final DateTime? billClosedAt;
  final String? billClosedBy;

  /// Outstanding written off at a "tak tertagih" bill-close (walkout). 0 for a
  /// normal Lunas close.
  final int lossAmount;
  final DateTime createdAt;

  /// Visit kind: `dineIn` (table-bound, default) | `takeaway` (Bawa pulang —
  /// no table, ADR-0026). For takeaway the lifecycle reuses the two-axis model
  /// with handover ("Serahkan") in place of table-close. Drives label
  /// resolution (KDS/cashier) and the reports dine-in/takeaway split.
  final String kind;
  const Visit({
    required this.id,
    required this.tableId,
    this.tableLabel,
    required this.zoneId,
    required this.pax,
    this.openedAt,
    this.guestName,
    this.guestNotes,
    this.reservationId,
    this.lastActorId,
    this.tableFreedAt,
    this.billClosedAt,
    this.billClosedBy,
    required this.lossAmount,
    required this.createdAt,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['table_id'] = Variable<String>(tableId);
    if (!nullToAbsent || tableLabel != null) {
      map['table_label'] = Variable<String>(tableLabel);
    }
    map['zone_id'] = Variable<String>(zoneId);
    map['pax'] = Variable<int>(pax);
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    if (!nullToAbsent || guestName != null) {
      map['guest_name'] = Variable<String>(guestName);
    }
    if (!nullToAbsent || guestNotes != null) {
      map['guest_notes'] = Variable<String>(guestNotes);
    }
    if (!nullToAbsent || reservationId != null) {
      map['reservation_id'] = Variable<String>(reservationId);
    }
    if (!nullToAbsent || lastActorId != null) {
      map['last_actor_id'] = Variable<String>(lastActorId);
    }
    if (!nullToAbsent || tableFreedAt != null) {
      map['table_freed_at'] = Variable<DateTime>(tableFreedAt);
    }
    if (!nullToAbsent || billClosedAt != null) {
      map['bill_closed_at'] = Variable<DateTime>(billClosedAt);
    }
    if (!nullToAbsent || billClosedBy != null) {
      map['bill_closed_by'] = Variable<String>(billClosedBy);
    }
    map['loss_amount'] = Variable<int>(lossAmount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['kind'] = Variable<String>(kind);
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      tableId: Value(tableId),
      tableLabel: tableLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(tableLabel),
      zoneId: Value(zoneId),
      pax: Value(pax),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      guestName: guestName == null && nullToAbsent
          ? const Value.absent()
          : Value(guestName),
      guestNotes: guestNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(guestNotes),
      reservationId: reservationId == null && nullToAbsent
          ? const Value.absent()
          : Value(reservationId),
      lastActorId: lastActorId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActorId),
      tableFreedAt: tableFreedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(tableFreedAt),
      billClosedAt: billClosedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(billClosedAt),
      billClosedBy: billClosedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(billClosedBy),
      lossAmount: Value(lossAmount),
      createdAt: Value(createdAt),
      kind: Value(kind),
    );
  }

  factory Visit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Visit(
      id: serializer.fromJson<String>(json['id']),
      tableId: serializer.fromJson<String>(json['tableId']),
      tableLabel: serializer.fromJson<String?>(json['tableLabel']),
      zoneId: serializer.fromJson<String>(json['zoneId']),
      pax: serializer.fromJson<int>(json['pax']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
      guestName: serializer.fromJson<String?>(json['guestName']),
      guestNotes: serializer.fromJson<String?>(json['guestNotes']),
      reservationId: serializer.fromJson<String?>(json['reservationId']),
      lastActorId: serializer.fromJson<String?>(json['lastActorId']),
      tableFreedAt: serializer.fromJson<DateTime?>(json['tableFreedAt']),
      billClosedAt: serializer.fromJson<DateTime?>(json['billClosedAt']),
      billClosedBy: serializer.fromJson<String?>(json['billClosedBy']),
      lossAmount: serializer.fromJson<int>(json['lossAmount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tableId': serializer.toJson<String>(tableId),
      'tableLabel': serializer.toJson<String?>(tableLabel),
      'zoneId': serializer.toJson<String>(zoneId),
      'pax': serializer.toJson<int>(pax),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'guestName': serializer.toJson<String?>(guestName),
      'guestNotes': serializer.toJson<String?>(guestNotes),
      'reservationId': serializer.toJson<String?>(reservationId),
      'lastActorId': serializer.toJson<String?>(lastActorId),
      'tableFreedAt': serializer.toJson<DateTime?>(tableFreedAt),
      'billClosedAt': serializer.toJson<DateTime?>(billClosedAt),
      'billClosedBy': serializer.toJson<String?>(billClosedBy),
      'lossAmount': serializer.toJson<int>(lossAmount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'kind': serializer.toJson<String>(kind),
    };
  }

  Visit copyWith({
    String? id,
    String? tableId,
    Value<String?> tableLabel = const Value.absent(),
    String? zoneId,
    int? pax,
    Value<DateTime?> openedAt = const Value.absent(),
    Value<String?> guestName = const Value.absent(),
    Value<String?> guestNotes = const Value.absent(),
    Value<String?> reservationId = const Value.absent(),
    Value<String?> lastActorId = const Value.absent(),
    Value<DateTime?> tableFreedAt = const Value.absent(),
    Value<DateTime?> billClosedAt = const Value.absent(),
    Value<String?> billClosedBy = const Value.absent(),
    int? lossAmount,
    DateTime? createdAt,
    String? kind,
  }) => Visit(
    id: id ?? this.id,
    tableId: tableId ?? this.tableId,
    tableLabel: tableLabel.present ? tableLabel.value : this.tableLabel,
    zoneId: zoneId ?? this.zoneId,
    pax: pax ?? this.pax,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    guestName: guestName.present ? guestName.value : this.guestName,
    guestNotes: guestNotes.present ? guestNotes.value : this.guestNotes,
    reservationId: reservationId.present
        ? reservationId.value
        : this.reservationId,
    lastActorId: lastActorId.present ? lastActorId.value : this.lastActorId,
    tableFreedAt: tableFreedAt.present ? tableFreedAt.value : this.tableFreedAt,
    billClosedAt: billClosedAt.present ? billClosedAt.value : this.billClosedAt,
    billClosedBy: billClosedBy.present ? billClosedBy.value : this.billClosedBy,
    lossAmount: lossAmount ?? this.lossAmount,
    createdAt: createdAt ?? this.createdAt,
    kind: kind ?? this.kind,
  );
  Visit copyWithCompanion(VisitsCompanion data) {
    return Visit(
      id: data.id.present ? data.id.value : this.id,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      tableLabel: data.tableLabel.present
          ? data.tableLabel.value
          : this.tableLabel,
      zoneId: data.zoneId.present ? data.zoneId.value : this.zoneId,
      pax: data.pax.present ? data.pax.value : this.pax,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      guestName: data.guestName.present ? data.guestName.value : this.guestName,
      guestNotes: data.guestNotes.present
          ? data.guestNotes.value
          : this.guestNotes,
      reservationId: data.reservationId.present
          ? data.reservationId.value
          : this.reservationId,
      lastActorId: data.lastActorId.present
          ? data.lastActorId.value
          : this.lastActorId,
      tableFreedAt: data.tableFreedAt.present
          ? data.tableFreedAt.value
          : this.tableFreedAt,
      billClosedAt: data.billClosedAt.present
          ? data.billClosedAt.value
          : this.billClosedAt,
      billClosedBy: data.billClosedBy.present
          ? data.billClosedBy.value
          : this.billClosedBy,
      lossAmount: data.lossAmount.present
          ? data.lossAmount.value
          : this.lossAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Visit(')
          ..write('id: $id, ')
          ..write('tableId: $tableId, ')
          ..write('tableLabel: $tableLabel, ')
          ..write('zoneId: $zoneId, ')
          ..write('pax: $pax, ')
          ..write('openedAt: $openedAt, ')
          ..write('guestName: $guestName, ')
          ..write('guestNotes: $guestNotes, ')
          ..write('reservationId: $reservationId, ')
          ..write('lastActorId: $lastActorId, ')
          ..write('tableFreedAt: $tableFreedAt, ')
          ..write('billClosedAt: $billClosedAt, ')
          ..write('billClosedBy: $billClosedBy, ')
          ..write('lossAmount: $lossAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tableId,
    tableLabel,
    zoneId,
    pax,
    openedAt,
    guestName,
    guestNotes,
    reservationId,
    lastActorId,
    tableFreedAt,
    billClosedAt,
    billClosedBy,
    lossAmount,
    createdAt,
    kind,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Visit &&
          other.id == this.id &&
          other.tableId == this.tableId &&
          other.tableLabel == this.tableLabel &&
          other.zoneId == this.zoneId &&
          other.pax == this.pax &&
          other.openedAt == this.openedAt &&
          other.guestName == this.guestName &&
          other.guestNotes == this.guestNotes &&
          other.reservationId == this.reservationId &&
          other.lastActorId == this.lastActorId &&
          other.tableFreedAt == this.tableFreedAt &&
          other.billClosedAt == this.billClosedAt &&
          other.billClosedBy == this.billClosedBy &&
          other.lossAmount == this.lossAmount &&
          other.createdAt == this.createdAt &&
          other.kind == this.kind);
}

class VisitsCompanion extends UpdateCompanion<Visit> {
  final Value<String> id;
  final Value<String> tableId;
  final Value<String?> tableLabel;
  final Value<String> zoneId;
  final Value<int> pax;
  final Value<DateTime?> openedAt;
  final Value<String?> guestName;
  final Value<String?> guestNotes;
  final Value<String?> reservationId;
  final Value<String?> lastActorId;
  final Value<DateTime?> tableFreedAt;
  final Value<DateTime?> billClosedAt;
  final Value<String?> billClosedBy;
  final Value<int> lossAmount;
  final Value<DateTime> createdAt;
  final Value<String> kind;
  final Value<int> rowid;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.tableId = const Value.absent(),
    this.tableLabel = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.pax = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.guestName = const Value.absent(),
    this.guestNotes = const Value.absent(),
    this.reservationId = const Value.absent(),
    this.lastActorId = const Value.absent(),
    this.tableFreedAt = const Value.absent(),
    this.billClosedAt = const Value.absent(),
    this.billClosedBy = const Value.absent(),
    this.lossAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitsCompanion.insert({
    required String id,
    required String tableId,
    this.tableLabel = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.pax = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.guestName = const Value.absent(),
    this.guestNotes = const Value.absent(),
    this.reservationId = const Value.absent(),
    this.lastActorId = const Value.absent(),
    this.tableFreedAt = const Value.absent(),
    this.billClosedAt = const Value.absent(),
    this.billClosedBy = const Value.absent(),
    this.lossAmount = const Value.absent(),
    required DateTime createdAt,
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tableId = Value(tableId),
       createdAt = Value(createdAt);
  static Insertable<Visit> custom({
    Expression<String>? id,
    Expression<String>? tableId,
    Expression<String>? tableLabel,
    Expression<String>? zoneId,
    Expression<int>? pax,
    Expression<DateTime>? openedAt,
    Expression<String>? guestName,
    Expression<String>? guestNotes,
    Expression<String>? reservationId,
    Expression<String>? lastActorId,
    Expression<DateTime>? tableFreedAt,
    Expression<DateTime>? billClosedAt,
    Expression<String>? billClosedBy,
    Expression<int>? lossAmount,
    Expression<DateTime>? createdAt,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tableId != null) 'table_id': tableId,
      if (tableLabel != null) 'table_label': tableLabel,
      if (zoneId != null) 'zone_id': zoneId,
      if (pax != null) 'pax': pax,
      if (openedAt != null) 'opened_at': openedAt,
      if (guestName != null) 'guest_name': guestName,
      if (guestNotes != null) 'guest_notes': guestNotes,
      if (reservationId != null) 'reservation_id': reservationId,
      if (lastActorId != null) 'last_actor_id': lastActorId,
      if (tableFreedAt != null) 'table_freed_at': tableFreedAt,
      if (billClosedAt != null) 'bill_closed_at': billClosedAt,
      if (billClosedBy != null) 'bill_closed_by': billClosedBy,
      if (lossAmount != null) 'loss_amount': lossAmount,
      if (createdAt != null) 'created_at': createdAt,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitsCompanion copyWith({
    Value<String>? id,
    Value<String>? tableId,
    Value<String?>? tableLabel,
    Value<String>? zoneId,
    Value<int>? pax,
    Value<DateTime?>? openedAt,
    Value<String?>? guestName,
    Value<String?>? guestNotes,
    Value<String?>? reservationId,
    Value<String?>? lastActorId,
    Value<DateTime?>? tableFreedAt,
    Value<DateTime?>? billClosedAt,
    Value<String?>? billClosedBy,
    Value<int>? lossAmount,
    Value<DateTime>? createdAt,
    Value<String>? kind,
    Value<int>? rowid,
  }) {
    return VisitsCompanion(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableLabel: tableLabel ?? this.tableLabel,
      zoneId: zoneId ?? this.zoneId,
      pax: pax ?? this.pax,
      openedAt: openedAt ?? this.openedAt,
      guestName: guestName ?? this.guestName,
      guestNotes: guestNotes ?? this.guestNotes,
      reservationId: reservationId ?? this.reservationId,
      lastActorId: lastActorId ?? this.lastActorId,
      tableFreedAt: tableFreedAt ?? this.tableFreedAt,
      billClosedAt: billClosedAt ?? this.billClosedAt,
      billClosedBy: billClosedBy ?? this.billClosedBy,
      lossAmount: lossAmount ?? this.lossAmount,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
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
    if (tableLabel.present) {
      map['table_label'] = Variable<String>(tableLabel.value);
    }
    if (zoneId.present) {
      map['zone_id'] = Variable<String>(zoneId.value);
    }
    if (pax.present) {
      map['pax'] = Variable<int>(pax.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (guestName.present) {
      map['guest_name'] = Variable<String>(guestName.value);
    }
    if (guestNotes.present) {
      map['guest_notes'] = Variable<String>(guestNotes.value);
    }
    if (reservationId.present) {
      map['reservation_id'] = Variable<String>(reservationId.value);
    }
    if (lastActorId.present) {
      map['last_actor_id'] = Variable<String>(lastActorId.value);
    }
    if (tableFreedAt.present) {
      map['table_freed_at'] = Variable<DateTime>(tableFreedAt.value);
    }
    if (billClosedAt.present) {
      map['bill_closed_at'] = Variable<DateTime>(billClosedAt.value);
    }
    if (billClosedBy.present) {
      map['bill_closed_by'] = Variable<String>(billClosedBy.value);
    }
    if (lossAmount.present) {
      map['loss_amount'] = Variable<int>(lossAmount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsCompanion(')
          ..write('id: $id, ')
          ..write('tableId: $tableId, ')
          ..write('tableLabel: $tableLabel, ')
          ..write('zoneId: $zoneId, ')
          ..write('pax: $pax, ')
          ..write('openedAt: $openedAt, ')
          ..write('guestName: $guestName, ')
          ..write('guestNotes: $guestNotes, ')
          ..write('reservationId: $reservationId, ')
          ..write('lastActorId: $lastActorId, ')
          ..write('tableFreedAt: $tableFreedAt, ')
          ..write('billClosedAt: $billClosedAt, ')
          ..write('billClosedBy: $billClosedBy, ')
          ..write('lossAmount: $lossAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('kind: $kind, ')
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
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<int> cost = GeneratedColumn<int>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _modifierGroupsJsonMeta =
      const VerificationMeta('modifierGroupsJson');
  @override
  late final GeneratedColumn<String> modifierGroupsJson =
      GeneratedColumn<String>(
        'modifier_groups_json',
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
  static const VerificationMeta _autoSoldOutAtZeroMeta = const VerificationMeta(
    'autoSoldOutAtZero',
  );
  @override
  late final GeneratedColumn<bool> autoSoldOutAtZero = GeneratedColumn<bool>(
    'auto_sold_out_at_zero',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_sold_out_at_zero" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<Uint8List> photo = GeneratedColumn<Uint8List>(
    'photo',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoRevMeta = const VerificationMeta(
    'photoRev',
  );
  @override
  late final GeneratedColumn<int> photoRev = GeneratedColumn<int>(
    'photo_rev',
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
    categoryId,
    description,
    basePrice,
    cost,
    prepTime,
    variantsJson,
    modifierGroupsJson,
    allergensJson,
    dietaryJson,
    unavailable,
    stockCount,
    autoSoldOutAtZero,
    photo,
    photoRev,
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
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
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
    if (data.containsKey('modifier_groups_json')) {
      context.handle(
        _modifierGroupsJsonMeta,
        modifierGroupsJson.isAcceptableOrUnknown(
          data['modifier_groups_json']!,
          _modifierGroupsJsonMeta,
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
    if (data.containsKey('auto_sold_out_at_zero')) {
      context.handle(
        _autoSoldOutAtZeroMeta,
        autoSoldOutAtZero.isAcceptableOrUnknown(
          data['auto_sold_out_at_zero']!,
          _autoSoldOutAtZeroMeta,
        ),
      );
    }
    if (data.containsKey('photo')) {
      context.handle(
        _photoMeta,
        photo.isAcceptableOrUnknown(data['photo']!, _photoMeta),
      );
    }
    if (data.containsKey('photo_rev')) {
      context.handle(
        _photoRevMeta,
        photoRev.isAcceptableOrUnknown(data['photo_rev']!, _photoRevMeta),
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
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      basePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_price'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost'],
      )!,
      prepTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prep_time'],
      )!,
      variantsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variants_json'],
      )!,
      modifierGroupsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modifier_groups_json'],
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
      autoSoldOutAtZero: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_sold_out_at_zero'],
      )!,
      photo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}photo'],
      ),
      photoRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}photo_rev'],
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
  final String description;
  final int basePrice;

  /// Cost of goods (same int-cents unit as `basePrice`). Used for margin
  /// reports + menu-engineering matrix. 0 = unknown (treated as full margin).
  final int cost;
  final int prepTime;
  final String variantsJson;

  /// Full modifier groups embedded per-item (private, not a shared library).
  /// JSON: [{id,name,required,multi,options:[{id,name,priceDelta}]}]. See
  /// docs/adr/0009-per-item-embedded-modifiers.md.
  final String modifierGroupsJson;
  final String allergensJson;
  final String dietaryJson;
  final bool unavailable;
  final int? stockCount;
  final bool autoSoldOutAtZero;

  /// Optional photo as a JPEG blob. Null = no photo (UI falls back to the
  /// initials avatar). Read ONLY by the photo route — never select this in
  /// the `/menu` snapshot or item upsert path; use `selectOnly` excluding it.
  /// See docs/adr/0014-menu-photo-blob-and-pinned-byte-fetch.md.
  final Uint8List? photo;

  /// Monotonic revision bumped on every photo write/clear. Rides the snapshot
  /// (the bytes do not) so clients cache-bust by `(itemId, photoRev)`.
  final int photoRev;
  const MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.basePrice,
    required this.cost,
    required this.prepTime,
    required this.variantsJson,
    required this.modifierGroupsJson,
    required this.allergensJson,
    required this.dietaryJson,
    required this.unavailable,
    this.stockCount,
    required this.autoSoldOutAtZero,
    this.photo,
    required this.photoRev,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category_id'] = Variable<String>(categoryId);
    map['description'] = Variable<String>(description);
    map['base_price'] = Variable<int>(basePrice);
    map['cost'] = Variable<int>(cost);
    map['prep_time'] = Variable<int>(prepTime);
    map['variants_json'] = Variable<String>(variantsJson);
    map['modifier_groups_json'] = Variable<String>(modifierGroupsJson);
    map['allergens_json'] = Variable<String>(allergensJson);
    map['dietary_json'] = Variable<String>(dietaryJson);
    map['unavailable'] = Variable<bool>(unavailable);
    if (!nullToAbsent || stockCount != null) {
      map['stock_count'] = Variable<int>(stockCount);
    }
    map['auto_sold_out_at_zero'] = Variable<bool>(autoSoldOutAtZero);
    if (!nullToAbsent || photo != null) {
      map['photo'] = Variable<Uint8List>(photo);
    }
    map['photo_rev'] = Variable<int>(photoRev);
    return map;
  }

  MenuItemsCompanion toCompanion(bool nullToAbsent) {
    return MenuItemsCompanion(
      id: Value(id),
      name: Value(name),
      categoryId: Value(categoryId),
      description: Value(description),
      basePrice: Value(basePrice),
      cost: Value(cost),
      prepTime: Value(prepTime),
      variantsJson: Value(variantsJson),
      modifierGroupsJson: Value(modifierGroupsJson),
      allergensJson: Value(allergensJson),
      dietaryJson: Value(dietaryJson),
      unavailable: Value(unavailable),
      stockCount: stockCount == null && nullToAbsent
          ? const Value.absent()
          : Value(stockCount),
      autoSoldOutAtZero: Value(autoSoldOutAtZero),
      photo: photo == null && nullToAbsent
          ? const Value.absent()
          : Value(photo),
      photoRev: Value(photoRev),
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
      description: serializer.fromJson<String>(json['description']),
      basePrice: serializer.fromJson<int>(json['basePrice']),
      cost: serializer.fromJson<int>(json['cost']),
      prepTime: serializer.fromJson<int>(json['prepTime']),
      variantsJson: serializer.fromJson<String>(json['variantsJson']),
      modifierGroupsJson: serializer.fromJson<String>(
        json['modifierGroupsJson'],
      ),
      allergensJson: serializer.fromJson<String>(json['allergensJson']),
      dietaryJson: serializer.fromJson<String>(json['dietaryJson']),
      unavailable: serializer.fromJson<bool>(json['unavailable']),
      stockCount: serializer.fromJson<int?>(json['stockCount']),
      autoSoldOutAtZero: serializer.fromJson<bool>(json['autoSoldOutAtZero']),
      photo: serializer.fromJson<Uint8List?>(json['photo']),
      photoRev: serializer.fromJson<int>(json['photoRev']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<String>(categoryId),
      'description': serializer.toJson<String>(description),
      'basePrice': serializer.toJson<int>(basePrice),
      'cost': serializer.toJson<int>(cost),
      'prepTime': serializer.toJson<int>(prepTime),
      'variantsJson': serializer.toJson<String>(variantsJson),
      'modifierGroupsJson': serializer.toJson<String>(modifierGroupsJson),
      'allergensJson': serializer.toJson<String>(allergensJson),
      'dietaryJson': serializer.toJson<String>(dietaryJson),
      'unavailable': serializer.toJson<bool>(unavailable),
      'stockCount': serializer.toJson<int?>(stockCount),
      'autoSoldOutAtZero': serializer.toJson<bool>(autoSoldOutAtZero),
      'photo': serializer.toJson<Uint8List?>(photo),
      'photoRev': serializer.toJson<int>(photoRev),
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? description,
    int? basePrice,
    int? cost,
    int? prepTime,
    String? variantsJson,
    String? modifierGroupsJson,
    String? allergensJson,
    String? dietaryJson,
    bool? unavailable,
    Value<int?> stockCount = const Value.absent(),
    bool? autoSoldOutAtZero,
    Value<Uint8List?> photo = const Value.absent(),
    int? photoRev,
  }) => MenuItem(
    id: id ?? this.id,
    name: name ?? this.name,
    categoryId: categoryId ?? this.categoryId,
    description: description ?? this.description,
    basePrice: basePrice ?? this.basePrice,
    cost: cost ?? this.cost,
    prepTime: prepTime ?? this.prepTime,
    variantsJson: variantsJson ?? this.variantsJson,
    modifierGroupsJson: modifierGroupsJson ?? this.modifierGroupsJson,
    allergensJson: allergensJson ?? this.allergensJson,
    dietaryJson: dietaryJson ?? this.dietaryJson,
    unavailable: unavailable ?? this.unavailable,
    stockCount: stockCount.present ? stockCount.value : this.stockCount,
    autoSoldOutAtZero: autoSoldOutAtZero ?? this.autoSoldOutAtZero,
    photo: photo.present ? photo.value : this.photo,
    photoRev: photoRev ?? this.photoRev,
  );
  MenuItem copyWithCompanion(MenuItemsCompanion data) {
    return MenuItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      description: data.description.present
          ? data.description.value
          : this.description,
      basePrice: data.basePrice.present ? data.basePrice.value : this.basePrice,
      cost: data.cost.present ? data.cost.value : this.cost,
      prepTime: data.prepTime.present ? data.prepTime.value : this.prepTime,
      variantsJson: data.variantsJson.present
          ? data.variantsJson.value
          : this.variantsJson,
      modifierGroupsJson: data.modifierGroupsJson.present
          ? data.modifierGroupsJson.value
          : this.modifierGroupsJson,
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
      autoSoldOutAtZero: data.autoSoldOutAtZero.present
          ? data.autoSoldOutAtZero.value
          : this.autoSoldOutAtZero,
      photo: data.photo.present ? data.photo.value : this.photo,
      photoRev: data.photoRev.present ? data.photoRev.value : this.photoRev,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('description: $description, ')
          ..write('basePrice: $basePrice, ')
          ..write('cost: $cost, ')
          ..write('prepTime: $prepTime, ')
          ..write('variantsJson: $variantsJson, ')
          ..write('modifierGroupsJson: $modifierGroupsJson, ')
          ..write('allergensJson: $allergensJson, ')
          ..write('dietaryJson: $dietaryJson, ')
          ..write('unavailable: $unavailable, ')
          ..write('stockCount: $stockCount, ')
          ..write('autoSoldOutAtZero: $autoSoldOutAtZero, ')
          ..write('photo: $photo, ')
          ..write('photoRev: $photoRev')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    categoryId,
    description,
    basePrice,
    cost,
    prepTime,
    variantsJson,
    modifierGroupsJson,
    allergensJson,
    dietaryJson,
    unavailable,
    stockCount,
    autoSoldOutAtZero,
    $driftBlobEquality.hash(photo),
    photoRev,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.description == this.description &&
          other.basePrice == this.basePrice &&
          other.cost == this.cost &&
          other.prepTime == this.prepTime &&
          other.variantsJson == this.variantsJson &&
          other.modifierGroupsJson == this.modifierGroupsJson &&
          other.allergensJson == this.allergensJson &&
          other.dietaryJson == this.dietaryJson &&
          other.unavailable == this.unavailable &&
          other.stockCount == this.stockCount &&
          other.autoSoldOutAtZero == this.autoSoldOutAtZero &&
          $driftBlobEquality.equals(other.photo, this.photo) &&
          other.photoRev == this.photoRev);
}

class MenuItemsCompanion extends UpdateCompanion<MenuItem> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> categoryId;
  final Value<String> description;
  final Value<int> basePrice;
  final Value<int> cost;
  final Value<int> prepTime;
  final Value<String> variantsJson;
  final Value<String> modifierGroupsJson;
  final Value<String> allergensJson;
  final Value<String> dietaryJson;
  final Value<bool> unavailable;
  final Value<int?> stockCount;
  final Value<bool> autoSoldOutAtZero;
  final Value<Uint8List?> photo;
  final Value<int> photoRev;
  final Value<int> rowid;
  const MenuItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.description = const Value.absent(),
    this.basePrice = const Value.absent(),
    this.cost = const Value.absent(),
    this.prepTime = const Value.absent(),
    this.variantsJson = const Value.absent(),
    this.modifierGroupsJson = const Value.absent(),
    this.allergensJson = const Value.absent(),
    this.dietaryJson = const Value.absent(),
    this.unavailable = const Value.absent(),
    this.stockCount = const Value.absent(),
    this.autoSoldOutAtZero = const Value.absent(),
    this.photo = const Value.absent(),
    this.photoRev = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuItemsCompanion.insert({
    required String id,
    required String name,
    required String categoryId,
    this.description = const Value.absent(),
    required int basePrice,
    this.cost = const Value.absent(),
    this.prepTime = const Value.absent(),
    this.variantsJson = const Value.absent(),
    this.modifierGroupsJson = const Value.absent(),
    this.allergensJson = const Value.absent(),
    this.dietaryJson = const Value.absent(),
    this.unavailable = const Value.absent(),
    this.stockCount = const Value.absent(),
    this.autoSoldOutAtZero = const Value.absent(),
    this.photo = const Value.absent(),
    this.photoRev = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       categoryId = Value(categoryId),
       basePrice = Value(basePrice);
  static Insertable<MenuItem> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? categoryId,
    Expression<String>? description,
    Expression<int>? basePrice,
    Expression<int>? cost,
    Expression<int>? prepTime,
    Expression<String>? variantsJson,
    Expression<String>? modifierGroupsJson,
    Expression<String>? allergensJson,
    Expression<String>? dietaryJson,
    Expression<bool>? unavailable,
    Expression<int>? stockCount,
    Expression<bool>? autoSoldOutAtZero,
    Expression<Uint8List>? photo,
    Expression<int>? photoRev,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      if (basePrice != null) 'base_price': basePrice,
      if (cost != null) 'cost': cost,
      if (prepTime != null) 'prep_time': prepTime,
      if (variantsJson != null) 'variants_json': variantsJson,
      if (modifierGroupsJson != null)
        'modifier_groups_json': modifierGroupsJson,
      if (allergensJson != null) 'allergens_json': allergensJson,
      if (dietaryJson != null) 'dietary_json': dietaryJson,
      if (unavailable != null) 'unavailable': unavailable,
      if (stockCount != null) 'stock_count': stockCount,
      if (autoSoldOutAtZero != null) 'auto_sold_out_at_zero': autoSoldOutAtZero,
      if (photo != null) 'photo': photo,
      if (photoRev != null) 'photo_rev': photoRev,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? categoryId,
    Value<String>? description,
    Value<int>? basePrice,
    Value<int>? cost,
    Value<int>? prepTime,
    Value<String>? variantsJson,
    Value<String>? modifierGroupsJson,
    Value<String>? allergensJson,
    Value<String>? dietaryJson,
    Value<bool>? unavailable,
    Value<int?>? stockCount,
    Value<bool>? autoSoldOutAtZero,
    Value<Uint8List?>? photo,
    Value<int>? photoRev,
    Value<int>? rowid,
  }) {
    return MenuItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      cost: cost ?? this.cost,
      prepTime: prepTime ?? this.prepTime,
      variantsJson: variantsJson ?? this.variantsJson,
      modifierGroupsJson: modifierGroupsJson ?? this.modifierGroupsJson,
      allergensJson: allergensJson ?? this.allergensJson,
      dietaryJson: dietaryJson ?? this.dietaryJson,
      unavailable: unavailable ?? this.unavailable,
      stockCount: stockCount ?? this.stockCount,
      autoSoldOutAtZero: autoSoldOutAtZero ?? this.autoSoldOutAtZero,
      photo: photo ?? this.photo,
      photoRev: photoRev ?? this.photoRev,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (basePrice.present) {
      map['base_price'] = Variable<int>(basePrice.value);
    }
    if (cost.present) {
      map['cost'] = Variable<int>(cost.value);
    }
    if (prepTime.present) {
      map['prep_time'] = Variable<int>(prepTime.value);
    }
    if (variantsJson.present) {
      map['variants_json'] = Variable<String>(variantsJson.value);
    }
    if (modifierGroupsJson.present) {
      map['modifier_groups_json'] = Variable<String>(modifierGroupsJson.value);
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
    if (autoSoldOutAtZero.present) {
      map['auto_sold_out_at_zero'] = Variable<bool>(autoSoldOutAtZero.value);
    }
    if (photo.present) {
      map['photo'] = Variable<Uint8List>(photo.value);
    }
    if (photoRev.present) {
      map['photo_rev'] = Variable<int>(photoRev.value);
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
          ..write('description: $description, ')
          ..write('basePrice: $basePrice, ')
          ..write('cost: $cost, ')
          ..write('prepTime: $prepTime, ')
          ..write('variantsJson: $variantsJson, ')
          ..write('modifierGroupsJson: $modifierGroupsJson, ')
          ..write('allergensJson: $allergensJson, ')
          ..write('dietaryJson: $dietaryJson, ')
          ..write('unavailable: $unavailable, ')
          ..write('stockCount: $stockCount, ')
          ..write('autoSoldOutAtZero: $autoSoldOutAtZero, ')
          ..write('photo: $photo, ')
          ..write('photoRev: $photoRev, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuTagsTable extends MenuTags with TableInfo<$MenuTagsTable, MenuTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  List<GeneratedColumn> get $columns => [id, kind, name, code, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
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
  MenuTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuTag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $MenuTagsTable createAlias(String alias) {
    return $MenuTagsTable(attachedDatabase, alias);
  }
}

class MenuTag extends DataClass implements Insertable<MenuTag> {
  final String id;
  final String kind;
  final String name;
  final String code;
  final int sortOrder;
  const MenuTag({
    required this.id,
    required this.kind,
    required this.name,
    required this.code,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  MenuTagsCompanion toCompanion(bool nullToAbsent) {
    return MenuTagsCompanion(
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      code: Value(code),
      sortOrder: Value(sortOrder),
    );
  }

  factory MenuTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuTag(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  MenuTag copyWith({
    String? id,
    String? kind,
    String? name,
    String? code,
    int? sortOrder,
  }) => MenuTag(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    code: code ?? this.code,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  MenuTag copyWithCompanion(MenuTagsCompanion data) {
    return MenuTag(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuTag(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, name, code, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuTag &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.code == this.code &&
          other.sortOrder == this.sortOrder);
}

class MenuTagsCompanion extends UpdateCompanion<MenuTag> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> name;
  final Value<String> code;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const MenuTagsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuTagsCompanion.insert({
    required String id,
    required String kind,
    required String name,
    this.code = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       name = Value(name);
  static Insertable<MenuTag> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? code,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuTagsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? name,
    Value<String>? code,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return MenuTagsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      code: code ?? this.code,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
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
    return (StringBuffer('MenuTagsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('sortOrder: $sortOrder, ')
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
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
  static const VerificationMeta _readyAtMeta = const VerificationMeta(
    'readyAt',
  );
  @override
  late final GeneratedColumn<DateTime> readyAt = GeneratedColumn<DateTime>(
    'ready_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servedAtMeta = const VerificationMeta(
    'servedAt',
  );
  @override
  late final GeneratedColumn<DateTime> servedAt = GeneratedColumn<DateTime>(
    'served_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  static const VerificationMeta _voidReasonCodeMeta = const VerificationMeta(
    'voidReasonCode',
  );
  @override
  late final GeneratedColumn<String> voidReasonCode = GeneratedColumn<String>(
    'void_reason_code',
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
  static const VerificationMeta _voidedByUserIdMeta = const VerificationMeta(
    'voidedByUserId',
  );
  @override
  late final GeneratedColumn<String> voidedByUserId = GeneratedColumn<String>(
    'voided_by_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tableId,
    visitId,
    itemId,
    name,
    variantName,
    course,
    qty,
    modifiersJson,
    note,
    price,
    status,
    sentAt,
    readyAt,
    servedAt,
    voidReason,
    voidReasonCode,
    voidApprovedBy,
    createdByUserId,
    voidedByUserId,
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
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
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
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
    if (data.containsKey('ready_at')) {
      context.handle(
        _readyAtMeta,
        readyAt.isAcceptableOrUnknown(data['ready_at']!, _readyAtMeta),
      );
    }
    if (data.containsKey('served_at')) {
      context.handle(
        _servedAtMeta,
        servedAt.isAcceptableOrUnknown(data['served_at']!, _servedAtMeta),
      );
    }
    if (data.containsKey('void_reason')) {
      context.handle(
        _voidReasonMeta,
        voidReason.isAcceptableOrUnknown(data['void_reason']!, _voidReasonMeta),
      );
    }
    if (data.containsKey('void_reason_code')) {
      context.handle(
        _voidReasonCodeMeta,
        voidReasonCode.isAcceptableOrUnknown(
          data['void_reason_code']!,
          _voidReasonCodeMeta,
        ),
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
    if (data.containsKey('voided_by_user_id')) {
      context.handle(
        _voidedByUserIdMeta,
        voidedByUserId.isAcceptableOrUnknown(
          data['voided_by_user_id']!,
          _voidedByUserIdMeta,
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
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      ),
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
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      modifiersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modifiers_json'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
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
      readyAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ready_at'],
      ),
      servedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}served_at'],
      ),
      voidReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_reason'],
      ),
      voidReasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_reason_code'],
      ),
      voidApprovedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_approved_by'],
      ),
      createdByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_user_id'],
      ),
      voidedByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voided_by_user_id'],
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

  /// The [[Visit]] this line belongs to — the stable key the bill hangs off,
  /// independent of `tableId` (which is the visit's *current* table and is
  /// reused across visits). Stamped at create from the table's
  /// `currentVisitId`. See ADR-0024. Nullable only for pre-v29 rows.
  final String? visitId;
  final String itemId;
  final String name;
  final String variantName;
  final String course;
  final int qty;
  final String modifiersJson;
  final String? note;
  final int price;
  final String status;
  final DateTime sentAt;

  /// Set once, on first entry into `ready` (prep time = readyAt − sentAt).
  /// See docs/adr/0013-ticket-lifecycle-timestamps-and-service-target.md.
  final DateTime? readyAt;

  /// Last-write, most recent `served` (pickup lag = servedAt − readyAt).
  final DateTime? servedAt;
  final String? voidReason;

  /// Canonical enum slug for void/comp analytics. One of:
  /// outOfStock | wrongOrder | customerChange | kitchenError | comp | other.
  final String? voidReasonCode;
  final String? voidApprovedBy;
  final String? createdByUserId;

  /// User who voided this ticket. Server-stamped from the JWT on the
  /// void transition — never client-supplied. See ADR-0006.
  final String? voidedByUserId;
  const Ticket({
    required this.id,
    required this.tableId,
    this.visitId,
    required this.itemId,
    required this.name,
    required this.variantName,
    required this.course,
    required this.qty,
    required this.modifiersJson,
    this.note,
    required this.price,
    required this.status,
    required this.sentAt,
    this.readyAt,
    this.servedAt,
    this.voidReason,
    this.voidReasonCode,
    this.voidApprovedBy,
    this.createdByUserId,
    this.voidedByUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['table_id'] = Variable<String>(tableId);
    if (!nullToAbsent || visitId != null) {
      map['visit_id'] = Variable<String>(visitId);
    }
    map['item_id'] = Variable<String>(itemId);
    map['name'] = Variable<String>(name);
    map['variant_name'] = Variable<String>(variantName);
    map['course'] = Variable<String>(course);
    map['qty'] = Variable<int>(qty);
    map['modifiers_json'] = Variable<String>(modifiersJson);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['price'] = Variable<int>(price);
    map['status'] = Variable<String>(status);
    map['sent_at'] = Variable<DateTime>(sentAt);
    if (!nullToAbsent || readyAt != null) {
      map['ready_at'] = Variable<DateTime>(readyAt);
    }
    if (!nullToAbsent || servedAt != null) {
      map['served_at'] = Variable<DateTime>(servedAt);
    }
    if (!nullToAbsent || voidReason != null) {
      map['void_reason'] = Variable<String>(voidReason);
    }
    if (!nullToAbsent || voidReasonCode != null) {
      map['void_reason_code'] = Variable<String>(voidReasonCode);
    }
    if (!nullToAbsent || voidApprovedBy != null) {
      map['void_approved_by'] = Variable<String>(voidApprovedBy);
    }
    if (!nullToAbsent || createdByUserId != null) {
      map['created_by_user_id'] = Variable<String>(createdByUserId);
    }
    if (!nullToAbsent || voidedByUserId != null) {
      map['voided_by_user_id'] = Variable<String>(voidedByUserId);
    }
    return map;
  }

  TicketsCompanion toCompanion(bool nullToAbsent) {
    return TicketsCompanion(
      id: Value(id),
      tableId: Value(tableId),
      visitId: visitId == null && nullToAbsent
          ? const Value.absent()
          : Value(visitId),
      itemId: Value(itemId),
      name: Value(name),
      variantName: Value(variantName),
      course: Value(course),
      qty: Value(qty),
      modifiersJson: Value(modifiersJson),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      price: Value(price),
      status: Value(status),
      sentAt: Value(sentAt),
      readyAt: readyAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readyAt),
      servedAt: servedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(servedAt),
      voidReason: voidReason == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReason),
      voidReasonCode: voidReasonCode == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReasonCode),
      voidApprovedBy: voidApprovedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(voidApprovedBy),
      createdByUserId: createdByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserId),
      voidedByUserId: voidedByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedByUserId),
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
      visitId: serializer.fromJson<String?>(json['visitId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      name: serializer.fromJson<String>(json['name']),
      variantName: serializer.fromJson<String>(json['variantName']),
      course: serializer.fromJson<String>(json['course']),
      qty: serializer.fromJson<int>(json['qty']),
      modifiersJson: serializer.fromJson<String>(json['modifiersJson']),
      note: serializer.fromJson<String?>(json['note']),
      price: serializer.fromJson<int>(json['price']),
      status: serializer.fromJson<String>(json['status']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      readyAt: serializer.fromJson<DateTime?>(json['readyAt']),
      servedAt: serializer.fromJson<DateTime?>(json['servedAt']),
      voidReason: serializer.fromJson<String?>(json['voidReason']),
      voidReasonCode: serializer.fromJson<String?>(json['voidReasonCode']),
      voidApprovedBy: serializer.fromJson<String?>(json['voidApprovedBy']),
      createdByUserId: serializer.fromJson<String?>(json['createdByUserId']),
      voidedByUserId: serializer.fromJson<String?>(json['voidedByUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tableId': serializer.toJson<String>(tableId),
      'visitId': serializer.toJson<String?>(visitId),
      'itemId': serializer.toJson<String>(itemId),
      'name': serializer.toJson<String>(name),
      'variantName': serializer.toJson<String>(variantName),
      'course': serializer.toJson<String>(course),
      'qty': serializer.toJson<int>(qty),
      'modifiersJson': serializer.toJson<String>(modifiersJson),
      'note': serializer.toJson<String?>(note),
      'price': serializer.toJson<int>(price),
      'status': serializer.toJson<String>(status),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'readyAt': serializer.toJson<DateTime?>(readyAt),
      'servedAt': serializer.toJson<DateTime?>(servedAt),
      'voidReason': serializer.toJson<String?>(voidReason),
      'voidReasonCode': serializer.toJson<String?>(voidReasonCode),
      'voidApprovedBy': serializer.toJson<String?>(voidApprovedBy),
      'createdByUserId': serializer.toJson<String?>(createdByUserId),
      'voidedByUserId': serializer.toJson<String?>(voidedByUserId),
    };
  }

  Ticket copyWith({
    String? id,
    String? tableId,
    Value<String?> visitId = const Value.absent(),
    String? itemId,
    String? name,
    String? variantName,
    String? course,
    int? qty,
    String? modifiersJson,
    Value<String?> note = const Value.absent(),
    int? price,
    String? status,
    DateTime? sentAt,
    Value<DateTime?> readyAt = const Value.absent(),
    Value<DateTime?> servedAt = const Value.absent(),
    Value<String?> voidReason = const Value.absent(),
    Value<String?> voidReasonCode = const Value.absent(),
    Value<String?> voidApprovedBy = const Value.absent(),
    Value<String?> createdByUserId = const Value.absent(),
    Value<String?> voidedByUserId = const Value.absent(),
  }) => Ticket(
    id: id ?? this.id,
    tableId: tableId ?? this.tableId,
    visitId: visitId.present ? visitId.value : this.visitId,
    itemId: itemId ?? this.itemId,
    name: name ?? this.name,
    variantName: variantName ?? this.variantName,
    course: course ?? this.course,
    qty: qty ?? this.qty,
    modifiersJson: modifiersJson ?? this.modifiersJson,
    note: note.present ? note.value : this.note,
    price: price ?? this.price,
    status: status ?? this.status,
    sentAt: sentAt ?? this.sentAt,
    readyAt: readyAt.present ? readyAt.value : this.readyAt,
    servedAt: servedAt.present ? servedAt.value : this.servedAt,
    voidReason: voidReason.present ? voidReason.value : this.voidReason,
    voidReasonCode: voidReasonCode.present
        ? voidReasonCode.value
        : this.voidReasonCode,
    voidApprovedBy: voidApprovedBy.present
        ? voidApprovedBy.value
        : this.voidApprovedBy,
    createdByUserId: createdByUserId.present
        ? createdByUserId.value
        : this.createdByUserId,
    voidedByUserId: voidedByUserId.present
        ? voidedByUserId.value
        : this.voidedByUserId,
  );
  Ticket copyWithCompanion(TicketsCompanion data) {
    return Ticket(
      id: data.id.present ? data.id.value : this.id,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      name: data.name.present ? data.name.value : this.name,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      course: data.course.present ? data.course.value : this.course,
      qty: data.qty.present ? data.qty.value : this.qty,
      modifiersJson: data.modifiersJson.present
          ? data.modifiersJson.value
          : this.modifiersJson,
      note: data.note.present ? data.note.value : this.note,
      price: data.price.present ? data.price.value : this.price,
      status: data.status.present ? data.status.value : this.status,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      readyAt: data.readyAt.present ? data.readyAt.value : this.readyAt,
      servedAt: data.servedAt.present ? data.servedAt.value : this.servedAt,
      voidReason: data.voidReason.present
          ? data.voidReason.value
          : this.voidReason,
      voidReasonCode: data.voidReasonCode.present
          ? data.voidReasonCode.value
          : this.voidReasonCode,
      voidApprovedBy: data.voidApprovedBy.present
          ? data.voidApprovedBy.value
          : this.voidApprovedBy,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      voidedByUserId: data.voidedByUserId.present
          ? data.voidedByUserId.value
          : this.voidedByUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ticket(')
          ..write('id: $id, ')
          ..write('tableId: $tableId, ')
          ..write('visitId: $visitId, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('variantName: $variantName, ')
          ..write('course: $course, ')
          ..write('qty: $qty, ')
          ..write('modifiersJson: $modifiersJson, ')
          ..write('note: $note, ')
          ..write('price: $price, ')
          ..write('status: $status, ')
          ..write('sentAt: $sentAt, ')
          ..write('readyAt: $readyAt, ')
          ..write('servedAt: $servedAt, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidReasonCode: $voidReasonCode, ')
          ..write('voidApprovedBy: $voidApprovedBy, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('voidedByUserId: $voidedByUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tableId,
    visitId,
    itemId,
    name,
    variantName,
    course,
    qty,
    modifiersJson,
    note,
    price,
    status,
    sentAt,
    readyAt,
    servedAt,
    voidReason,
    voidReasonCode,
    voidApprovedBy,
    createdByUserId,
    voidedByUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ticket &&
          other.id == this.id &&
          other.tableId == this.tableId &&
          other.visitId == this.visitId &&
          other.itemId == this.itemId &&
          other.name == this.name &&
          other.variantName == this.variantName &&
          other.course == this.course &&
          other.qty == this.qty &&
          other.modifiersJson == this.modifiersJson &&
          other.note == this.note &&
          other.price == this.price &&
          other.status == this.status &&
          other.sentAt == this.sentAt &&
          other.readyAt == this.readyAt &&
          other.servedAt == this.servedAt &&
          other.voidReason == this.voidReason &&
          other.voidReasonCode == this.voidReasonCode &&
          other.voidApprovedBy == this.voidApprovedBy &&
          other.createdByUserId == this.createdByUserId &&
          other.voidedByUserId == this.voidedByUserId);
}

class TicketsCompanion extends UpdateCompanion<Ticket> {
  final Value<String> id;
  final Value<String> tableId;
  final Value<String?> visitId;
  final Value<String> itemId;
  final Value<String> name;
  final Value<String> variantName;
  final Value<String> course;
  final Value<int> qty;
  final Value<String> modifiersJson;
  final Value<String?> note;
  final Value<int> price;
  final Value<String> status;
  final Value<DateTime> sentAt;
  final Value<DateTime?> readyAt;
  final Value<DateTime?> servedAt;
  final Value<String?> voidReason;
  final Value<String?> voidReasonCode;
  final Value<String?> voidApprovedBy;
  final Value<String?> createdByUserId;
  final Value<String?> voidedByUserId;
  final Value<int> rowid;
  const TicketsCompanion({
    this.id = const Value.absent(),
    this.tableId = const Value.absent(),
    this.visitId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.name = const Value.absent(),
    this.variantName = const Value.absent(),
    this.course = const Value.absent(),
    this.qty = const Value.absent(),
    this.modifiersJson = const Value.absent(),
    this.note = const Value.absent(),
    this.price = const Value.absent(),
    this.status = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.readyAt = const Value.absent(),
    this.servedAt = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidReasonCode = const Value.absent(),
    this.voidApprovedBy = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.voidedByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TicketsCompanion.insert({
    required String id,
    required String tableId,
    this.visitId = const Value.absent(),
    required String itemId,
    required String name,
    this.variantName = const Value.absent(),
    required String course,
    this.qty = const Value.absent(),
    this.modifiersJson = const Value.absent(),
    this.note = const Value.absent(),
    required int price,
    required String status,
    required DateTime sentAt,
    this.readyAt = const Value.absent(),
    this.servedAt = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidReasonCode = const Value.absent(),
    this.voidApprovedBy = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.voidedByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tableId = Value(tableId),
       itemId = Value(itemId),
       name = Value(name),
       course = Value(course),
       price = Value(price),
       status = Value(status),
       sentAt = Value(sentAt);
  static Insertable<Ticket> custom({
    Expression<String>? id,
    Expression<String>? tableId,
    Expression<String>? visitId,
    Expression<String>? itemId,
    Expression<String>? name,
    Expression<String>? variantName,
    Expression<String>? course,
    Expression<int>? qty,
    Expression<String>? modifiersJson,
    Expression<String>? note,
    Expression<int>? price,
    Expression<String>? status,
    Expression<DateTime>? sentAt,
    Expression<DateTime>? readyAt,
    Expression<DateTime>? servedAt,
    Expression<String>? voidReason,
    Expression<String>? voidReasonCode,
    Expression<String>? voidApprovedBy,
    Expression<String>? createdByUserId,
    Expression<String>? voidedByUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tableId != null) 'table_id': tableId,
      if (visitId != null) 'visit_id': visitId,
      if (itemId != null) 'item_id': itemId,
      if (name != null) 'name': name,
      if (variantName != null) 'variant_name': variantName,
      if (course != null) 'course': course,
      if (qty != null) 'qty': qty,
      if (modifiersJson != null) 'modifiers_json': modifiersJson,
      if (note != null) 'note': note,
      if (price != null) 'price': price,
      if (status != null) 'status': status,
      if (sentAt != null) 'sent_at': sentAt,
      if (readyAt != null) 'ready_at': readyAt,
      if (servedAt != null) 'served_at': servedAt,
      if (voidReason != null) 'void_reason': voidReason,
      if (voidReasonCode != null) 'void_reason_code': voidReasonCode,
      if (voidApprovedBy != null) 'void_approved_by': voidApprovedBy,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (voidedByUserId != null) 'voided_by_user_id': voidedByUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TicketsCompanion copyWith({
    Value<String>? id,
    Value<String>? tableId,
    Value<String?>? visitId,
    Value<String>? itemId,
    Value<String>? name,
    Value<String>? variantName,
    Value<String>? course,
    Value<int>? qty,
    Value<String>? modifiersJson,
    Value<String?>? note,
    Value<int>? price,
    Value<String>? status,
    Value<DateTime>? sentAt,
    Value<DateTime?>? readyAt,
    Value<DateTime?>? servedAt,
    Value<String?>? voidReason,
    Value<String?>? voidReasonCode,
    Value<String?>? voidApprovedBy,
    Value<String?>? createdByUserId,
    Value<String?>? voidedByUserId,
    Value<int>? rowid,
  }) {
    return TicketsCompanion(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      visitId: visitId ?? this.visitId,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      variantName: variantName ?? this.variantName,
      course: course ?? this.course,
      qty: qty ?? this.qty,
      modifiersJson: modifiersJson ?? this.modifiersJson,
      note: note ?? this.note,
      price: price ?? this.price,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      readyAt: readyAt ?? this.readyAt,
      servedAt: servedAt ?? this.servedAt,
      voidReason: voidReason ?? this.voidReason,
      voidReasonCode: voidReasonCode ?? this.voidReasonCode,
      voidApprovedBy: voidApprovedBy ?? this.voidApprovedBy,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      voidedByUserId: voidedByUserId ?? this.voidedByUserId,
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
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
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
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (modifiersJson.present) {
      map['modifiers_json'] = Variable<String>(modifiersJson.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    if (readyAt.present) {
      map['ready_at'] = Variable<DateTime>(readyAt.value);
    }
    if (servedAt.present) {
      map['served_at'] = Variable<DateTime>(servedAt.value);
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    if (voidReasonCode.present) {
      map['void_reason_code'] = Variable<String>(voidReasonCode.value);
    }
    if (voidApprovedBy.present) {
      map['void_approved_by'] = Variable<String>(voidApprovedBy.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (voidedByUserId.present) {
      map['voided_by_user_id'] = Variable<String>(voidedByUserId.value);
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
          ..write('visitId: $visitId, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('variantName: $variantName, ')
          ..write('course: $course, ')
          ..write('qty: $qty, ')
          ..write('modifiersJson: $modifiersJson, ')
          ..write('note: $note, ')
          ..write('price: $price, ')
          ..write('status: $status, ')
          ..write('sentAt: $sentAt, ')
          ..write('readyAt: $readyAt, ')
          ..write('servedAt: $servedAt, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidReasonCode: $voidReasonCode, ')
          ..write('voidApprovedBy: $voidApprovedBy, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('voidedByUserId: $voidedByUserId, ')
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

class $VenueSettingsTable extends VenueSettings
    with TableInfo<$VenueSettingsTable, VenueSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VenueSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Warung Sebelah'),
  );
  static const VerificationMeta _legalNameMeta = const VerificationMeta(
    'legalName',
  );
  @override
  late final GeneratedColumn<String> legalName = GeneratedColumn<String>(
    'legal_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptHeaderMeta = const VerificationMeta(
    'receiptHeader',
  );
  @override
  late final GeneratedColumn<String> receiptHeader = GeneratedColumn<String>(
    'receipt_header',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptFooterMeta = const VerificationMeta(
    'receiptFooter',
  );
  @override
  late final GeneratedColumn<String> receiptFooter = GeneratedColumn<String>(
    'receipt_footer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptTaglineMeta = const VerificationMeta(
    'receiptTagline',
  );
  @override
  late final GeneratedColumn<String> receiptTagline = GeneratedColumn<String>(
    'receipt_tagline',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptSocialMeta = const VerificationMeta(
    'receiptSocial',
  );
  @override
  late final GeneratedColumn<String> receiptSocial = GeneratedColumn<String>(
    'receipt_social',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptThankYouMeta = const VerificationMeta(
    'receiptThankYou',
  );
  @override
  late final GeneratedColumn<String> receiptThankYou = GeneratedColumn<String>(
    'receipt_thank_you',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptQrUrlMeta = const VerificationMeta(
    'receiptQrUrl',
  );
  @override
  late final GeneratedColumn<String> receiptQrUrl = GeneratedColumn<String>(
    'receipt_qr_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _receiptQrCaptionMeta = const VerificationMeta(
    'receiptQrCaption',
  );
  @override
  late final GeneratedColumn<String> receiptQrCaption = GeneratedColumn<String>(
    'receipt_qr_caption',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _logoMeta = const VerificationMeta('logo');
  @override
  late final GeneratedColumn<Uint8List> logo = GeneratedColumn<Uint8List>(
    'logo',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoRevMeta = const VerificationMeta(
    'logoRev',
  );
  @override
  late final GeneratedColumn<int> logoRev = GeneratedColumn<int>(
    'logo_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxEnabledMeta = const VerificationMeta(
    'taxEnabled',
  );
  @override
  late final GeneratedColumn<bool> taxEnabled = GeneratedColumn<bool>(
    'tax_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tax_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _taxRateBpsMeta = const VerificationMeta(
    'taxRateBps',
  );
  @override
  late final GeneratedColumn<int> taxRateBps = GeneratedColumn<int>(
    'tax_rate_bps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1100),
  );
  static const VerificationMeta _serviceEnabledMeta = const VerificationMeta(
    'serviceEnabled',
  );
  @override
  late final GeneratedColumn<bool> serviceEnabled = GeneratedColumn<bool>(
    'service_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("service_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _serviceModeMeta = const VerificationMeta(
    'serviceMode',
  );
  @override
  late final GeneratedColumn<String> serviceMode = GeneratedColumn<String>(
    'service_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('percent'),
  );
  static const VerificationMeta _serviceRateBpsMeta = const VerificationMeta(
    'serviceRateBps',
  );
  @override
  late final GeneratedColumn<int> serviceRateBps = GeneratedColumn<int>(
    'service_rate_bps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(500),
  );
  static const VerificationMeta _serviceFixedAmountMeta =
      const VerificationMeta('serviceFixedAmount');
  @override
  late final GeneratedColumn<int> serviceFixedAmount = GeneratedColumn<int>(
    'service_fixed_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _businessDayStartHourMeta =
      const VerificationMeta('businessDayStartHour');
  @override
  late final GeneratedColumn<int> businessDayStartHour = GeneratedColumn<int>(
    'business_day_start_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _prepTargetMinsMeta = const VerificationMeta(
    'prepTargetMins',
  );
  @override
  late final GeneratedColumn<int> prepTargetMins = GeneratedColumn<int>(
    'prep_target_mins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(15),
  );
  static const VerificationMeta _guestOrderingEnabledMeta =
      const VerificationMeta('guestOrderingEnabled');
  @override
  late final GeneratedColumn<bool> guestOrderingEnabled = GeneratedColumn<bool>(
    'guest_ordering_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("guest_ordering_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _soundNewOrderMeta = const VerificationMeta(
    'soundNewOrder',
  );
  @override
  late final GeneratedColumn<String> soundNewOrder = GeneratedColumn<String>(
    'sound_new_order',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('alert'),
  );
  static const VerificationMeta _soundReadyMeta = const VerificationMeta(
    'soundReady',
  );
  @override
  late final GeneratedColumn<String> soundReady = GeneratedColumn<String>(
    'sound_ready',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('chime'),
  );
  static const VerificationMeta _soundVoidMeta = const VerificationMeta(
    'soundVoid',
  );
  @override
  late final GeneratedColumn<String> soundVoid = GeneratedColumn<String>(
    'sound_void',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('alert'),
  );
  static const VerificationMeta _soundOverdueMeta = const VerificationMeta(
    'soundOverdue',
  );
  @override
  late final GeneratedColumn<String> soundOverdue = GeneratedColumn<String>(
    'sound_overdue',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('alert'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    legalName,
    address,
    phone,
    receiptHeader,
    receiptFooter,
    receiptTagline,
    receiptSocial,
    receiptThankYou,
    receiptQrUrl,
    receiptQrCaption,
    logo,
    logoRev,
    taxEnabled,
    taxRateBps,
    serviceEnabled,
    serviceMode,
    serviceRateBps,
    serviceFixedAmount,
    businessDayStartHour,
    prepTargetMins,
    guestOrderingEnabled,
    soundNewOrder,
    soundReady,
    soundVoid,
    soundOverdue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'venue_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<VenueSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('legal_name')) {
      context.handle(
        _legalNameMeta,
        legalName.isAcceptableOrUnknown(data['legal_name']!, _legalNameMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('receipt_header')) {
      context.handle(
        _receiptHeaderMeta,
        receiptHeader.isAcceptableOrUnknown(
          data['receipt_header']!,
          _receiptHeaderMeta,
        ),
      );
    }
    if (data.containsKey('receipt_footer')) {
      context.handle(
        _receiptFooterMeta,
        receiptFooter.isAcceptableOrUnknown(
          data['receipt_footer']!,
          _receiptFooterMeta,
        ),
      );
    }
    if (data.containsKey('receipt_tagline')) {
      context.handle(
        _receiptTaglineMeta,
        receiptTagline.isAcceptableOrUnknown(
          data['receipt_tagline']!,
          _receiptTaglineMeta,
        ),
      );
    }
    if (data.containsKey('receipt_social')) {
      context.handle(
        _receiptSocialMeta,
        receiptSocial.isAcceptableOrUnknown(
          data['receipt_social']!,
          _receiptSocialMeta,
        ),
      );
    }
    if (data.containsKey('receipt_thank_you')) {
      context.handle(
        _receiptThankYouMeta,
        receiptThankYou.isAcceptableOrUnknown(
          data['receipt_thank_you']!,
          _receiptThankYouMeta,
        ),
      );
    }
    if (data.containsKey('receipt_qr_url')) {
      context.handle(
        _receiptQrUrlMeta,
        receiptQrUrl.isAcceptableOrUnknown(
          data['receipt_qr_url']!,
          _receiptQrUrlMeta,
        ),
      );
    }
    if (data.containsKey('receipt_qr_caption')) {
      context.handle(
        _receiptQrCaptionMeta,
        receiptQrCaption.isAcceptableOrUnknown(
          data['receipt_qr_caption']!,
          _receiptQrCaptionMeta,
        ),
      );
    }
    if (data.containsKey('logo')) {
      context.handle(
        _logoMeta,
        logo.isAcceptableOrUnknown(data['logo']!, _logoMeta),
      );
    }
    if (data.containsKey('logo_rev')) {
      context.handle(
        _logoRevMeta,
        logoRev.isAcceptableOrUnknown(data['logo_rev']!, _logoRevMeta),
      );
    }
    if (data.containsKey('tax_enabled')) {
      context.handle(
        _taxEnabledMeta,
        taxEnabled.isAcceptableOrUnknown(data['tax_enabled']!, _taxEnabledMeta),
      );
    }
    if (data.containsKey('tax_rate_bps')) {
      context.handle(
        _taxRateBpsMeta,
        taxRateBps.isAcceptableOrUnknown(
          data['tax_rate_bps']!,
          _taxRateBpsMeta,
        ),
      );
    }
    if (data.containsKey('service_enabled')) {
      context.handle(
        _serviceEnabledMeta,
        serviceEnabled.isAcceptableOrUnknown(
          data['service_enabled']!,
          _serviceEnabledMeta,
        ),
      );
    }
    if (data.containsKey('service_mode')) {
      context.handle(
        _serviceModeMeta,
        serviceMode.isAcceptableOrUnknown(
          data['service_mode']!,
          _serviceModeMeta,
        ),
      );
    }
    if (data.containsKey('service_rate_bps')) {
      context.handle(
        _serviceRateBpsMeta,
        serviceRateBps.isAcceptableOrUnknown(
          data['service_rate_bps']!,
          _serviceRateBpsMeta,
        ),
      );
    }
    if (data.containsKey('service_fixed_amount')) {
      context.handle(
        _serviceFixedAmountMeta,
        serviceFixedAmount.isAcceptableOrUnknown(
          data['service_fixed_amount']!,
          _serviceFixedAmountMeta,
        ),
      );
    }
    if (data.containsKey('business_day_start_hour')) {
      context.handle(
        _businessDayStartHourMeta,
        businessDayStartHour.isAcceptableOrUnknown(
          data['business_day_start_hour']!,
          _businessDayStartHourMeta,
        ),
      );
    }
    if (data.containsKey('prep_target_mins')) {
      context.handle(
        _prepTargetMinsMeta,
        prepTargetMins.isAcceptableOrUnknown(
          data['prep_target_mins']!,
          _prepTargetMinsMeta,
        ),
      );
    }
    if (data.containsKey('guest_ordering_enabled')) {
      context.handle(
        _guestOrderingEnabledMeta,
        guestOrderingEnabled.isAcceptableOrUnknown(
          data['guest_ordering_enabled']!,
          _guestOrderingEnabledMeta,
        ),
      );
    }
    if (data.containsKey('sound_new_order')) {
      context.handle(
        _soundNewOrderMeta,
        soundNewOrder.isAcceptableOrUnknown(
          data['sound_new_order']!,
          _soundNewOrderMeta,
        ),
      );
    }
    if (data.containsKey('sound_ready')) {
      context.handle(
        _soundReadyMeta,
        soundReady.isAcceptableOrUnknown(data['sound_ready']!, _soundReadyMeta),
      );
    }
    if (data.containsKey('sound_void')) {
      context.handle(
        _soundVoidMeta,
        soundVoid.isAcceptableOrUnknown(data['sound_void']!, _soundVoidMeta),
      );
    }
    if (data.containsKey('sound_overdue')) {
      context.handle(
        _soundOverdueMeta,
        soundOverdue.isAcceptableOrUnknown(
          data['sound_overdue']!,
          _soundOverdueMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VenueSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VenueSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      legalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legal_name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      receiptHeader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_header'],
      )!,
      receiptFooter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_footer'],
      )!,
      receiptTagline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_tagline'],
      )!,
      receiptSocial: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_social'],
      )!,
      receiptThankYou: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_thank_you'],
      )!,
      receiptQrUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_qr_url'],
      )!,
      receiptQrCaption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_qr_caption'],
      )!,
      logo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}logo'],
      ),
      logoRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}logo_rev'],
      )!,
      taxEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tax_enabled'],
      )!,
      taxRateBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_rate_bps'],
      )!,
      serviceEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}service_enabled'],
      )!,
      serviceMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_mode'],
      )!,
      serviceRateBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_rate_bps'],
      )!,
      serviceFixedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_fixed_amount'],
      )!,
      businessDayStartHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}business_day_start_hour'],
      )!,
      prepTargetMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prep_target_mins'],
      )!,
      guestOrderingEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}guest_ordering_enabled'],
      )!,
      soundNewOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_new_order'],
      )!,
      soundReady: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_ready'],
      )!,
      soundVoid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_void'],
      )!,
      soundOverdue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_overdue'],
      )!,
    );
  }

  @override
  $VenueSettingsTable createAlias(String alias) {
    return $VenueSettingsTable(attachedDatabase, alias);
  }
}

class VenueSetting extends DataClass implements Insertable<VenueSetting> {
  final String id;
  final String displayName;
  final String legalName;
  final String address;
  final String phone;
  final String receiptHeader;
  final String receiptFooter;

  /// Receipt branding block (ADR-0033) — one shared block stamped on every
  /// document. Short slogan under the venue name, plus a website/social handle
  /// line in the header.
  final String receiptTagline;
  final String receiptSocial;

  /// Closing sign-off (was a hardcoded "Terima kasih"). Empty ⇒ renderers fall
  /// back to "Terima kasih".
  final String receiptThankYou;

  /// Footer QR (money docs only): a free-form URL + a short caption.
  final String receiptQrUrl;
  final String receiptQrCaption;

  /// Optional logo as a JPEG blob. Null = no logo (header is text-only). Read
  /// ONLY by the logo route — never selected into the settings JSON snapshot.
  /// Mirrors the menu-photo pattern (ADR-0014 / ADR-0033).
  final Uint8List? logo;

  /// Monotonic revision bumped on every logo write/clear. Rides the settings
  /// JSON (the bytes do not) so clients cache-bust by `logoRev`.
  final int logoRev;
  final bool taxEnabled;
  final int taxRateBps;
  final bool serviceEnabled;
  final String serviceMode;
  final int serviceRateBps;
  final int serviceFixedAmount;

  /// Business-day rollover hour (0..23). Reports bucket "today" as
  /// [hour, hour+24h). Default 4 covers late-night service.
  final int businessDayStartHour;

  /// Single configurable "kitchen should be ready by now" threshold (minutes).
  /// Drives BOTH the floor/audio overdue alert and the report SLA hit-rate.
  /// See docs/adr/0013-ticket-lifecycle-timestamps-and-service-target.md.
  final int prepTargetMins;

  /// Venue master switch for guest QR self-ordering (ADR-0027/0028). Default
  /// OFF so shipping the feature exposes no venue automatically. When true,
  /// per-table `VenueTables.guestOrderingEnabled` controls which tables show a
  /// working QR.
  final bool guestOrderingEnabled;

  /// Per-event alert sound choice (ADR-0035). Each holds a preset id from
  /// `alertSoundPresets` ('none' = silent). Defaults reproduce ADR-0007's
  /// original fixed cues. Venue-wide: one choice every paired device obeys.
  final String soundNewOrder;
  final String soundReady;
  final String soundVoid;
  final String soundOverdue;
  const VenueSetting({
    required this.id,
    required this.displayName,
    required this.legalName,
    required this.address,
    required this.phone,
    required this.receiptHeader,
    required this.receiptFooter,
    required this.receiptTagline,
    required this.receiptSocial,
    required this.receiptThankYou,
    required this.receiptQrUrl,
    required this.receiptQrCaption,
    this.logo,
    required this.logoRev,
    required this.taxEnabled,
    required this.taxRateBps,
    required this.serviceEnabled,
    required this.serviceMode,
    required this.serviceRateBps,
    required this.serviceFixedAmount,
    required this.businessDayStartHour,
    required this.prepTargetMins,
    required this.guestOrderingEnabled,
    required this.soundNewOrder,
    required this.soundReady,
    required this.soundVoid,
    required this.soundOverdue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['legal_name'] = Variable<String>(legalName);
    map['address'] = Variable<String>(address);
    map['phone'] = Variable<String>(phone);
    map['receipt_header'] = Variable<String>(receiptHeader);
    map['receipt_footer'] = Variable<String>(receiptFooter);
    map['receipt_tagline'] = Variable<String>(receiptTagline);
    map['receipt_social'] = Variable<String>(receiptSocial);
    map['receipt_thank_you'] = Variable<String>(receiptThankYou);
    map['receipt_qr_url'] = Variable<String>(receiptQrUrl);
    map['receipt_qr_caption'] = Variable<String>(receiptQrCaption);
    if (!nullToAbsent || logo != null) {
      map['logo'] = Variable<Uint8List>(logo);
    }
    map['logo_rev'] = Variable<int>(logoRev);
    map['tax_enabled'] = Variable<bool>(taxEnabled);
    map['tax_rate_bps'] = Variable<int>(taxRateBps);
    map['service_enabled'] = Variable<bool>(serviceEnabled);
    map['service_mode'] = Variable<String>(serviceMode);
    map['service_rate_bps'] = Variable<int>(serviceRateBps);
    map['service_fixed_amount'] = Variable<int>(serviceFixedAmount);
    map['business_day_start_hour'] = Variable<int>(businessDayStartHour);
    map['prep_target_mins'] = Variable<int>(prepTargetMins);
    map['guest_ordering_enabled'] = Variable<bool>(guestOrderingEnabled);
    map['sound_new_order'] = Variable<String>(soundNewOrder);
    map['sound_ready'] = Variable<String>(soundReady);
    map['sound_void'] = Variable<String>(soundVoid);
    map['sound_overdue'] = Variable<String>(soundOverdue);
    return map;
  }

  VenueSettingsCompanion toCompanion(bool nullToAbsent) {
    return VenueSettingsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      legalName: Value(legalName),
      address: Value(address),
      phone: Value(phone),
      receiptHeader: Value(receiptHeader),
      receiptFooter: Value(receiptFooter),
      receiptTagline: Value(receiptTagline),
      receiptSocial: Value(receiptSocial),
      receiptThankYou: Value(receiptThankYou),
      receiptQrUrl: Value(receiptQrUrl),
      receiptQrCaption: Value(receiptQrCaption),
      logo: logo == null && nullToAbsent ? const Value.absent() : Value(logo),
      logoRev: Value(logoRev),
      taxEnabled: Value(taxEnabled),
      taxRateBps: Value(taxRateBps),
      serviceEnabled: Value(serviceEnabled),
      serviceMode: Value(serviceMode),
      serviceRateBps: Value(serviceRateBps),
      serviceFixedAmount: Value(serviceFixedAmount),
      businessDayStartHour: Value(businessDayStartHour),
      prepTargetMins: Value(prepTargetMins),
      guestOrderingEnabled: Value(guestOrderingEnabled),
      soundNewOrder: Value(soundNewOrder),
      soundReady: Value(soundReady),
      soundVoid: Value(soundVoid),
      soundOverdue: Value(soundOverdue),
    );
  }

  factory VenueSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VenueSetting(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      legalName: serializer.fromJson<String>(json['legalName']),
      address: serializer.fromJson<String>(json['address']),
      phone: serializer.fromJson<String>(json['phone']),
      receiptHeader: serializer.fromJson<String>(json['receiptHeader']),
      receiptFooter: serializer.fromJson<String>(json['receiptFooter']),
      receiptTagline: serializer.fromJson<String>(json['receiptTagline']),
      receiptSocial: serializer.fromJson<String>(json['receiptSocial']),
      receiptThankYou: serializer.fromJson<String>(json['receiptThankYou']),
      receiptQrUrl: serializer.fromJson<String>(json['receiptQrUrl']),
      receiptQrCaption: serializer.fromJson<String>(json['receiptQrCaption']),
      logo: serializer.fromJson<Uint8List?>(json['logo']),
      logoRev: serializer.fromJson<int>(json['logoRev']),
      taxEnabled: serializer.fromJson<bool>(json['taxEnabled']),
      taxRateBps: serializer.fromJson<int>(json['taxRateBps']),
      serviceEnabled: serializer.fromJson<bool>(json['serviceEnabled']),
      serviceMode: serializer.fromJson<String>(json['serviceMode']),
      serviceRateBps: serializer.fromJson<int>(json['serviceRateBps']),
      serviceFixedAmount: serializer.fromJson<int>(json['serviceFixedAmount']),
      businessDayStartHour: serializer.fromJson<int>(
        json['businessDayStartHour'],
      ),
      prepTargetMins: serializer.fromJson<int>(json['prepTargetMins']),
      guestOrderingEnabled: serializer.fromJson<bool>(
        json['guestOrderingEnabled'],
      ),
      soundNewOrder: serializer.fromJson<String>(json['soundNewOrder']),
      soundReady: serializer.fromJson<String>(json['soundReady']),
      soundVoid: serializer.fromJson<String>(json['soundVoid']),
      soundOverdue: serializer.fromJson<String>(json['soundOverdue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'legalName': serializer.toJson<String>(legalName),
      'address': serializer.toJson<String>(address),
      'phone': serializer.toJson<String>(phone),
      'receiptHeader': serializer.toJson<String>(receiptHeader),
      'receiptFooter': serializer.toJson<String>(receiptFooter),
      'receiptTagline': serializer.toJson<String>(receiptTagline),
      'receiptSocial': serializer.toJson<String>(receiptSocial),
      'receiptThankYou': serializer.toJson<String>(receiptThankYou),
      'receiptQrUrl': serializer.toJson<String>(receiptQrUrl),
      'receiptQrCaption': serializer.toJson<String>(receiptQrCaption),
      'logo': serializer.toJson<Uint8List?>(logo),
      'logoRev': serializer.toJson<int>(logoRev),
      'taxEnabled': serializer.toJson<bool>(taxEnabled),
      'taxRateBps': serializer.toJson<int>(taxRateBps),
      'serviceEnabled': serializer.toJson<bool>(serviceEnabled),
      'serviceMode': serializer.toJson<String>(serviceMode),
      'serviceRateBps': serializer.toJson<int>(serviceRateBps),
      'serviceFixedAmount': serializer.toJson<int>(serviceFixedAmount),
      'businessDayStartHour': serializer.toJson<int>(businessDayStartHour),
      'prepTargetMins': serializer.toJson<int>(prepTargetMins),
      'guestOrderingEnabled': serializer.toJson<bool>(guestOrderingEnabled),
      'soundNewOrder': serializer.toJson<String>(soundNewOrder),
      'soundReady': serializer.toJson<String>(soundReady),
      'soundVoid': serializer.toJson<String>(soundVoid),
      'soundOverdue': serializer.toJson<String>(soundOverdue),
    };
  }

  VenueSetting copyWith({
    String? id,
    String? displayName,
    String? legalName,
    String? address,
    String? phone,
    String? receiptHeader,
    String? receiptFooter,
    String? receiptTagline,
    String? receiptSocial,
    String? receiptThankYou,
    String? receiptQrUrl,
    String? receiptQrCaption,
    Value<Uint8List?> logo = const Value.absent(),
    int? logoRev,
    bool? taxEnabled,
    int? taxRateBps,
    bool? serviceEnabled,
    String? serviceMode,
    int? serviceRateBps,
    int? serviceFixedAmount,
    int? businessDayStartHour,
    int? prepTargetMins,
    bool? guestOrderingEnabled,
    String? soundNewOrder,
    String? soundReady,
    String? soundVoid,
    String? soundOverdue,
  }) => VenueSetting(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    legalName: legalName ?? this.legalName,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    receiptHeader: receiptHeader ?? this.receiptHeader,
    receiptFooter: receiptFooter ?? this.receiptFooter,
    receiptTagline: receiptTagline ?? this.receiptTagline,
    receiptSocial: receiptSocial ?? this.receiptSocial,
    receiptThankYou: receiptThankYou ?? this.receiptThankYou,
    receiptQrUrl: receiptQrUrl ?? this.receiptQrUrl,
    receiptQrCaption: receiptQrCaption ?? this.receiptQrCaption,
    logo: logo.present ? logo.value : this.logo,
    logoRev: logoRev ?? this.logoRev,
    taxEnabled: taxEnabled ?? this.taxEnabled,
    taxRateBps: taxRateBps ?? this.taxRateBps,
    serviceEnabled: serviceEnabled ?? this.serviceEnabled,
    serviceMode: serviceMode ?? this.serviceMode,
    serviceRateBps: serviceRateBps ?? this.serviceRateBps,
    serviceFixedAmount: serviceFixedAmount ?? this.serviceFixedAmount,
    businessDayStartHour: businessDayStartHour ?? this.businessDayStartHour,
    prepTargetMins: prepTargetMins ?? this.prepTargetMins,
    guestOrderingEnabled: guestOrderingEnabled ?? this.guestOrderingEnabled,
    soundNewOrder: soundNewOrder ?? this.soundNewOrder,
    soundReady: soundReady ?? this.soundReady,
    soundVoid: soundVoid ?? this.soundVoid,
    soundOverdue: soundOverdue ?? this.soundOverdue,
  );
  VenueSetting copyWithCompanion(VenueSettingsCompanion data) {
    return VenueSetting(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      legalName: data.legalName.present ? data.legalName.value : this.legalName,
      address: data.address.present ? data.address.value : this.address,
      phone: data.phone.present ? data.phone.value : this.phone,
      receiptHeader: data.receiptHeader.present
          ? data.receiptHeader.value
          : this.receiptHeader,
      receiptFooter: data.receiptFooter.present
          ? data.receiptFooter.value
          : this.receiptFooter,
      receiptTagline: data.receiptTagline.present
          ? data.receiptTagline.value
          : this.receiptTagline,
      receiptSocial: data.receiptSocial.present
          ? data.receiptSocial.value
          : this.receiptSocial,
      receiptThankYou: data.receiptThankYou.present
          ? data.receiptThankYou.value
          : this.receiptThankYou,
      receiptQrUrl: data.receiptQrUrl.present
          ? data.receiptQrUrl.value
          : this.receiptQrUrl,
      receiptQrCaption: data.receiptQrCaption.present
          ? data.receiptQrCaption.value
          : this.receiptQrCaption,
      logo: data.logo.present ? data.logo.value : this.logo,
      logoRev: data.logoRev.present ? data.logoRev.value : this.logoRev,
      taxEnabled: data.taxEnabled.present
          ? data.taxEnabled.value
          : this.taxEnabled,
      taxRateBps: data.taxRateBps.present
          ? data.taxRateBps.value
          : this.taxRateBps,
      serviceEnabled: data.serviceEnabled.present
          ? data.serviceEnabled.value
          : this.serviceEnabled,
      serviceMode: data.serviceMode.present
          ? data.serviceMode.value
          : this.serviceMode,
      serviceRateBps: data.serviceRateBps.present
          ? data.serviceRateBps.value
          : this.serviceRateBps,
      serviceFixedAmount: data.serviceFixedAmount.present
          ? data.serviceFixedAmount.value
          : this.serviceFixedAmount,
      businessDayStartHour: data.businessDayStartHour.present
          ? data.businessDayStartHour.value
          : this.businessDayStartHour,
      prepTargetMins: data.prepTargetMins.present
          ? data.prepTargetMins.value
          : this.prepTargetMins,
      guestOrderingEnabled: data.guestOrderingEnabled.present
          ? data.guestOrderingEnabled.value
          : this.guestOrderingEnabled,
      soundNewOrder: data.soundNewOrder.present
          ? data.soundNewOrder.value
          : this.soundNewOrder,
      soundReady: data.soundReady.present
          ? data.soundReady.value
          : this.soundReady,
      soundVoid: data.soundVoid.present ? data.soundVoid.value : this.soundVoid,
      soundOverdue: data.soundOverdue.present
          ? data.soundOverdue.value
          : this.soundOverdue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VenueSetting(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('legalName: $legalName, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('receiptHeader: $receiptHeader, ')
          ..write('receiptFooter: $receiptFooter, ')
          ..write('receiptTagline: $receiptTagline, ')
          ..write('receiptSocial: $receiptSocial, ')
          ..write('receiptThankYou: $receiptThankYou, ')
          ..write('receiptQrUrl: $receiptQrUrl, ')
          ..write('receiptQrCaption: $receiptQrCaption, ')
          ..write('logo: $logo, ')
          ..write('logoRev: $logoRev, ')
          ..write('taxEnabled: $taxEnabled, ')
          ..write('taxRateBps: $taxRateBps, ')
          ..write('serviceEnabled: $serviceEnabled, ')
          ..write('serviceMode: $serviceMode, ')
          ..write('serviceRateBps: $serviceRateBps, ')
          ..write('serviceFixedAmount: $serviceFixedAmount, ')
          ..write('businessDayStartHour: $businessDayStartHour, ')
          ..write('prepTargetMins: $prepTargetMins, ')
          ..write('guestOrderingEnabled: $guestOrderingEnabled, ')
          ..write('soundNewOrder: $soundNewOrder, ')
          ..write('soundReady: $soundReady, ')
          ..write('soundVoid: $soundVoid, ')
          ..write('soundOverdue: $soundOverdue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    displayName,
    legalName,
    address,
    phone,
    receiptHeader,
    receiptFooter,
    receiptTagline,
    receiptSocial,
    receiptThankYou,
    receiptQrUrl,
    receiptQrCaption,
    $driftBlobEquality.hash(logo),
    logoRev,
    taxEnabled,
    taxRateBps,
    serviceEnabled,
    serviceMode,
    serviceRateBps,
    serviceFixedAmount,
    businessDayStartHour,
    prepTargetMins,
    guestOrderingEnabled,
    soundNewOrder,
    soundReady,
    soundVoid,
    soundOverdue,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VenueSetting &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.legalName == this.legalName &&
          other.address == this.address &&
          other.phone == this.phone &&
          other.receiptHeader == this.receiptHeader &&
          other.receiptFooter == this.receiptFooter &&
          other.receiptTagline == this.receiptTagline &&
          other.receiptSocial == this.receiptSocial &&
          other.receiptThankYou == this.receiptThankYou &&
          other.receiptQrUrl == this.receiptQrUrl &&
          other.receiptQrCaption == this.receiptQrCaption &&
          $driftBlobEquality.equals(other.logo, this.logo) &&
          other.logoRev == this.logoRev &&
          other.taxEnabled == this.taxEnabled &&
          other.taxRateBps == this.taxRateBps &&
          other.serviceEnabled == this.serviceEnabled &&
          other.serviceMode == this.serviceMode &&
          other.serviceRateBps == this.serviceRateBps &&
          other.serviceFixedAmount == this.serviceFixedAmount &&
          other.businessDayStartHour == this.businessDayStartHour &&
          other.prepTargetMins == this.prepTargetMins &&
          other.guestOrderingEnabled == this.guestOrderingEnabled &&
          other.soundNewOrder == this.soundNewOrder &&
          other.soundReady == this.soundReady &&
          other.soundVoid == this.soundVoid &&
          other.soundOverdue == this.soundOverdue);
}

class VenueSettingsCompanion extends UpdateCompanion<VenueSetting> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> legalName;
  final Value<String> address;
  final Value<String> phone;
  final Value<String> receiptHeader;
  final Value<String> receiptFooter;
  final Value<String> receiptTagline;
  final Value<String> receiptSocial;
  final Value<String> receiptThankYou;
  final Value<String> receiptQrUrl;
  final Value<String> receiptQrCaption;
  final Value<Uint8List?> logo;
  final Value<int> logoRev;
  final Value<bool> taxEnabled;
  final Value<int> taxRateBps;
  final Value<bool> serviceEnabled;
  final Value<String> serviceMode;
  final Value<int> serviceRateBps;
  final Value<int> serviceFixedAmount;
  final Value<int> businessDayStartHour;
  final Value<int> prepTargetMins;
  final Value<bool> guestOrderingEnabled;
  final Value<String> soundNewOrder;
  final Value<String> soundReady;
  final Value<String> soundVoid;
  final Value<String> soundOverdue;
  final Value<int> rowid;
  const VenueSettingsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.legalName = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.receiptHeader = const Value.absent(),
    this.receiptFooter = const Value.absent(),
    this.receiptTagline = const Value.absent(),
    this.receiptSocial = const Value.absent(),
    this.receiptThankYou = const Value.absent(),
    this.receiptQrUrl = const Value.absent(),
    this.receiptQrCaption = const Value.absent(),
    this.logo = const Value.absent(),
    this.logoRev = const Value.absent(),
    this.taxEnabled = const Value.absent(),
    this.taxRateBps = const Value.absent(),
    this.serviceEnabled = const Value.absent(),
    this.serviceMode = const Value.absent(),
    this.serviceRateBps = const Value.absent(),
    this.serviceFixedAmount = const Value.absent(),
    this.businessDayStartHour = const Value.absent(),
    this.prepTargetMins = const Value.absent(),
    this.guestOrderingEnabled = const Value.absent(),
    this.soundNewOrder = const Value.absent(),
    this.soundReady = const Value.absent(),
    this.soundVoid = const Value.absent(),
    this.soundOverdue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VenueSettingsCompanion.insert({
    required String id,
    this.displayName = const Value.absent(),
    this.legalName = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.receiptHeader = const Value.absent(),
    this.receiptFooter = const Value.absent(),
    this.receiptTagline = const Value.absent(),
    this.receiptSocial = const Value.absent(),
    this.receiptThankYou = const Value.absent(),
    this.receiptQrUrl = const Value.absent(),
    this.receiptQrCaption = const Value.absent(),
    this.logo = const Value.absent(),
    this.logoRev = const Value.absent(),
    this.taxEnabled = const Value.absent(),
    this.taxRateBps = const Value.absent(),
    this.serviceEnabled = const Value.absent(),
    this.serviceMode = const Value.absent(),
    this.serviceRateBps = const Value.absent(),
    this.serviceFixedAmount = const Value.absent(),
    this.businessDayStartHour = const Value.absent(),
    this.prepTargetMins = const Value.absent(),
    this.guestOrderingEnabled = const Value.absent(),
    this.soundNewOrder = const Value.absent(),
    this.soundReady = const Value.absent(),
    this.soundVoid = const Value.absent(),
    this.soundOverdue = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<VenueSetting> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? legalName,
    Expression<String>? address,
    Expression<String>? phone,
    Expression<String>? receiptHeader,
    Expression<String>? receiptFooter,
    Expression<String>? receiptTagline,
    Expression<String>? receiptSocial,
    Expression<String>? receiptThankYou,
    Expression<String>? receiptQrUrl,
    Expression<String>? receiptQrCaption,
    Expression<Uint8List>? logo,
    Expression<int>? logoRev,
    Expression<bool>? taxEnabled,
    Expression<int>? taxRateBps,
    Expression<bool>? serviceEnabled,
    Expression<String>? serviceMode,
    Expression<int>? serviceRateBps,
    Expression<int>? serviceFixedAmount,
    Expression<int>? businessDayStartHour,
    Expression<int>? prepTargetMins,
    Expression<bool>? guestOrderingEnabled,
    Expression<String>? soundNewOrder,
    Expression<String>? soundReady,
    Expression<String>? soundVoid,
    Expression<String>? soundOverdue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (legalName != null) 'legal_name': legalName,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (receiptHeader != null) 'receipt_header': receiptHeader,
      if (receiptFooter != null) 'receipt_footer': receiptFooter,
      if (receiptTagline != null) 'receipt_tagline': receiptTagline,
      if (receiptSocial != null) 'receipt_social': receiptSocial,
      if (receiptThankYou != null) 'receipt_thank_you': receiptThankYou,
      if (receiptQrUrl != null) 'receipt_qr_url': receiptQrUrl,
      if (receiptQrCaption != null) 'receipt_qr_caption': receiptQrCaption,
      if (logo != null) 'logo': logo,
      if (logoRev != null) 'logo_rev': logoRev,
      if (taxEnabled != null) 'tax_enabled': taxEnabled,
      if (taxRateBps != null) 'tax_rate_bps': taxRateBps,
      if (serviceEnabled != null) 'service_enabled': serviceEnabled,
      if (serviceMode != null) 'service_mode': serviceMode,
      if (serviceRateBps != null) 'service_rate_bps': serviceRateBps,
      if (serviceFixedAmount != null)
        'service_fixed_amount': serviceFixedAmount,
      if (businessDayStartHour != null)
        'business_day_start_hour': businessDayStartHour,
      if (prepTargetMins != null) 'prep_target_mins': prepTargetMins,
      if (guestOrderingEnabled != null)
        'guest_ordering_enabled': guestOrderingEnabled,
      if (soundNewOrder != null) 'sound_new_order': soundNewOrder,
      if (soundReady != null) 'sound_ready': soundReady,
      if (soundVoid != null) 'sound_void': soundVoid,
      if (soundOverdue != null) 'sound_overdue': soundOverdue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VenueSettingsCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? legalName,
    Value<String>? address,
    Value<String>? phone,
    Value<String>? receiptHeader,
    Value<String>? receiptFooter,
    Value<String>? receiptTagline,
    Value<String>? receiptSocial,
    Value<String>? receiptThankYou,
    Value<String>? receiptQrUrl,
    Value<String>? receiptQrCaption,
    Value<Uint8List?>? logo,
    Value<int>? logoRev,
    Value<bool>? taxEnabled,
    Value<int>? taxRateBps,
    Value<bool>? serviceEnabled,
    Value<String>? serviceMode,
    Value<int>? serviceRateBps,
    Value<int>? serviceFixedAmount,
    Value<int>? businessDayStartHour,
    Value<int>? prepTargetMins,
    Value<bool>? guestOrderingEnabled,
    Value<String>? soundNewOrder,
    Value<String>? soundReady,
    Value<String>? soundVoid,
    Value<String>? soundOverdue,
    Value<int>? rowid,
  }) {
    return VenueSettingsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      legalName: legalName ?? this.legalName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      receiptTagline: receiptTagline ?? this.receiptTagline,
      receiptSocial: receiptSocial ?? this.receiptSocial,
      receiptThankYou: receiptThankYou ?? this.receiptThankYou,
      receiptQrUrl: receiptQrUrl ?? this.receiptQrUrl,
      receiptQrCaption: receiptQrCaption ?? this.receiptQrCaption,
      logo: logo ?? this.logo,
      logoRev: logoRev ?? this.logoRev,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      taxRateBps: taxRateBps ?? this.taxRateBps,
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
      serviceMode: serviceMode ?? this.serviceMode,
      serviceRateBps: serviceRateBps ?? this.serviceRateBps,
      serviceFixedAmount: serviceFixedAmount ?? this.serviceFixedAmount,
      businessDayStartHour: businessDayStartHour ?? this.businessDayStartHour,
      prepTargetMins: prepTargetMins ?? this.prepTargetMins,
      guestOrderingEnabled: guestOrderingEnabled ?? this.guestOrderingEnabled,
      soundNewOrder: soundNewOrder ?? this.soundNewOrder,
      soundReady: soundReady ?? this.soundReady,
      soundVoid: soundVoid ?? this.soundVoid,
      soundOverdue: soundOverdue ?? this.soundOverdue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (legalName.present) {
      map['legal_name'] = Variable<String>(legalName.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (receiptHeader.present) {
      map['receipt_header'] = Variable<String>(receiptHeader.value);
    }
    if (receiptFooter.present) {
      map['receipt_footer'] = Variable<String>(receiptFooter.value);
    }
    if (receiptTagline.present) {
      map['receipt_tagline'] = Variable<String>(receiptTagline.value);
    }
    if (receiptSocial.present) {
      map['receipt_social'] = Variable<String>(receiptSocial.value);
    }
    if (receiptThankYou.present) {
      map['receipt_thank_you'] = Variable<String>(receiptThankYou.value);
    }
    if (receiptQrUrl.present) {
      map['receipt_qr_url'] = Variable<String>(receiptQrUrl.value);
    }
    if (receiptQrCaption.present) {
      map['receipt_qr_caption'] = Variable<String>(receiptQrCaption.value);
    }
    if (logo.present) {
      map['logo'] = Variable<Uint8List>(logo.value);
    }
    if (logoRev.present) {
      map['logo_rev'] = Variable<int>(logoRev.value);
    }
    if (taxEnabled.present) {
      map['tax_enabled'] = Variable<bool>(taxEnabled.value);
    }
    if (taxRateBps.present) {
      map['tax_rate_bps'] = Variable<int>(taxRateBps.value);
    }
    if (serviceEnabled.present) {
      map['service_enabled'] = Variable<bool>(serviceEnabled.value);
    }
    if (serviceMode.present) {
      map['service_mode'] = Variable<String>(serviceMode.value);
    }
    if (serviceRateBps.present) {
      map['service_rate_bps'] = Variable<int>(serviceRateBps.value);
    }
    if (serviceFixedAmount.present) {
      map['service_fixed_amount'] = Variable<int>(serviceFixedAmount.value);
    }
    if (businessDayStartHour.present) {
      map['business_day_start_hour'] = Variable<int>(
        businessDayStartHour.value,
      );
    }
    if (prepTargetMins.present) {
      map['prep_target_mins'] = Variable<int>(prepTargetMins.value);
    }
    if (guestOrderingEnabled.present) {
      map['guest_ordering_enabled'] = Variable<bool>(
        guestOrderingEnabled.value,
      );
    }
    if (soundNewOrder.present) {
      map['sound_new_order'] = Variable<String>(soundNewOrder.value);
    }
    if (soundReady.present) {
      map['sound_ready'] = Variable<String>(soundReady.value);
    }
    if (soundVoid.present) {
      map['sound_void'] = Variable<String>(soundVoid.value);
    }
    if (soundOverdue.present) {
      map['sound_overdue'] = Variable<String>(soundOverdue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VenueSettingsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('legalName: $legalName, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('receiptHeader: $receiptHeader, ')
          ..write('receiptFooter: $receiptFooter, ')
          ..write('receiptTagline: $receiptTagline, ')
          ..write('receiptSocial: $receiptSocial, ')
          ..write('receiptThankYou: $receiptThankYou, ')
          ..write('receiptQrUrl: $receiptQrUrl, ')
          ..write('receiptQrCaption: $receiptQrCaption, ')
          ..write('logo: $logo, ')
          ..write('logoRev: $logoRev, ')
          ..write('taxEnabled: $taxEnabled, ')
          ..write('taxRateBps: $taxRateBps, ')
          ..write('serviceEnabled: $serviceEnabled, ')
          ..write('serviceMode: $serviceMode, ')
          ..write('serviceRateBps: $serviceRateBps, ')
          ..write('serviceFixedAmount: $serviceFixedAmount, ')
          ..write('businessDayStartHour: $businessDayStartHour, ')
          ..write('prepTargetMins: $prepTargetMins, ')
          ..write('guestOrderingEnabled: $guestOrderingEnabled, ')
          ..write('soundNewOrder: $soundNewOrder, ')
          ..write('soundReady: $soundReady, ')
          ..write('soundVoid: $soundVoid, ')
          ..write('soundOverdue: $soundOverdue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrintersTable extends Printers with TableInfo<$PrintersTable, Printer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrintersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(9100),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('escpos'),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  List<GeneratedColumn> get $columns => [
    id,
    label,
    host,
    port,
    kind,
    enabled,
    lastSeenAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'printers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Printer> instance, {
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
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Printer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Printer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      )!,
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PrintersTable createAlias(String alias) {
    return $PrintersTable(attachedDatabase, alias);
  }
}

class Printer extends DataClass implements Insertable<Printer> {
  final String id;
  final String label;
  final String host;
  final int port;

  /// 'escpos' or 'kds'.
  final String kind;
  final bool enabled;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  const Printer({
    required this.id,
    required this.label,
    required this.host,
    required this.port,
    required this.kind,
    required this.enabled,
    this.lastSeenAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['host'] = Variable<String>(host);
    map['port'] = Variable<int>(port);
    map['kind'] = Variable<String>(kind);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PrintersCompanion toCompanion(bool nullToAbsent) {
    return PrintersCompanion(
      id: Value(id),
      label: Value(label),
      host: Value(host),
      port: Value(port),
      kind: Value(kind),
      enabled: Value(enabled),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      createdAt: Value(createdAt),
    );
  }

  factory Printer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Printer(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      host: serializer.fromJson<String>(json['host']),
      port: serializer.fromJson<int>(json['port']),
      kind: serializer.fromJson<String>(json['kind']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'host': serializer.toJson<String>(host),
      'port': serializer.toJson<int>(port),
      'kind': serializer.toJson<String>(kind),
      'enabled': serializer.toJson<bool>(enabled),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Printer copyWith({
    String? id,
    String? label,
    String? host,
    int? port,
    String? kind,
    bool? enabled,
    Value<DateTime?> lastSeenAt = const Value.absent(),
    DateTime? createdAt,
  }) => Printer(
    id: id ?? this.id,
    label: label ?? this.label,
    host: host ?? this.host,
    port: port ?? this.port,
    kind: kind ?? this.kind,
    enabled: enabled ?? this.enabled,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Printer copyWithCompanion(PrintersCompanion data) {
    return Printer(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      kind: data.kind.present ? data.kind.value : this.kind,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Printer(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('kind: $kind, ')
          ..write('enabled: $enabled, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, label, host, port, kind, enabled, lastSeenAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Printer &&
          other.id == this.id &&
          other.label == this.label &&
          other.host == this.host &&
          other.port == this.port &&
          other.kind == this.kind &&
          other.enabled == this.enabled &&
          other.lastSeenAt == this.lastSeenAt &&
          other.createdAt == this.createdAt);
}

class PrintersCompanion extends UpdateCompanion<Printer> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> host;
  final Value<int> port;
  final Value<String> kind;
  final Value<bool> enabled;
  final Value<DateTime?> lastSeenAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PrintersCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.kind = const Value.absent(),
    this.enabled = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrintersCompanion.insert({
    required String id,
    required String label,
    required String host,
    this.port = const Value.absent(),
    this.kind = const Value.absent(),
    this.enabled = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       host = Value(host),
       createdAt = Value(createdAt);
  static Insertable<Printer> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? host,
    Expression<int>? port,
    Expression<String>? kind,
    Expression<bool>? enabled,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (kind != null) 'kind': kind,
      if (enabled != null) 'enabled': enabled,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrintersCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String>? host,
    Value<int>? port,
    Value<String>? kind,
    Value<bool>? enabled,
    Value<DateTime?>? lastSeenAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PrintersCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      host: host ?? this.host,
      port: port ?? this.port,
      kind: kind ?? this.kind,
      enabled: enabled ?? this.enabled,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
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
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
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
    return (StringBuffer('PrintersCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('kind: $kind, ')
          ..write('enabled: $enabled, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TableSessionsTable extends TableSessions
    with TableInfo<$TableSessionsTable, TableSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TableSessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tableLabelMeta = const VerificationMeta(
    'tableLabel',
  );
  @override
  late final GeneratedColumn<String> tableLabel = GeneratedColumn<String>(
    'table_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _paxMeta = const VerificationMeta('pax');
  @override
  late final GeneratedColumn<int> pax = GeneratedColumn<int>(
    'pax',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<int> subtotal = GeneratedColumn<int>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _voidAmountMeta = const VerificationMeta(
    'voidAmount',
  );
  @override
  late final GeneratedColumn<int> voidAmount = GeneratedColumn<int>(
    'void_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _serviceAmountMeta = const VerificationMeta(
    'serviceAmount',
  );
  @override
  late final GeneratedColumn<int> serviceAmount = GeneratedColumn<int>(
    'service_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<int> taxAmount = GeneratedColumn<int>(
    'tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _netTotalMeta = const VerificationMeta(
    'netTotal',
  );
  @override
  late final GeneratedColumn<int> netTotal = GeneratedColumn<int>(
    'net_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ticketCountMeta = const VerificationMeta(
    'ticketCount',
  );
  @override
  late final GeneratedColumn<int> ticketCount = GeneratedColumn<int>(
    'ticket_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lossAmountMeta = const VerificationMeta(
    'lossAmount',
  );
  @override
  late final GeneratedColumn<int> lossAmount = GeneratedColumn<int>(
    'loss_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _billClosedByMeta = const VerificationMeta(
    'billClosedBy',
  );
  @override
  late final GeneratedColumn<String> billClosedBy = GeneratedColumn<String>(
    'bill_closed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dineIn'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tableId,
    tableLabel,
    zoneId,
    pax,
    openedAt,
    closedAt,
    durationSec,
    actorUserId,
    subtotal,
    voidAmount,
    serviceAmount,
    taxAmount,
    netTotal,
    ticketCount,
    lossAmount,
    billClosedBy,
    kind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'table_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TableSession> instance, {
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
    if (data.containsKey('table_label')) {
      context.handle(
        _tableLabelMeta,
        tableLabel.isAcceptableOrUnknown(data['table_label']!, _tableLabelMeta),
      );
    }
    if (data.containsKey('zone_id')) {
      context.handle(
        _zoneIdMeta,
        zoneId.isAcceptableOrUnknown(data['zone_id']!, _zoneIdMeta),
      );
    } else if (isInserting) {
      context.missing(_zoneIdMeta);
    }
    if (data.containsKey('pax')) {
      context.handle(
        _paxMeta,
        pax.isAcceptableOrUnknown(data['pax']!, _paxMeta),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_closedAtMeta);
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
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
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    }
    if (data.containsKey('void_amount')) {
      context.handle(
        _voidAmountMeta,
        voidAmount.isAcceptableOrUnknown(data['void_amount']!, _voidAmountMeta),
      );
    }
    if (data.containsKey('service_amount')) {
      context.handle(
        _serviceAmountMeta,
        serviceAmount.isAcceptableOrUnknown(
          data['service_amount']!,
          _serviceAmountMeta,
        ),
      );
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    }
    if (data.containsKey('net_total')) {
      context.handle(
        _netTotalMeta,
        netTotal.isAcceptableOrUnknown(data['net_total']!, _netTotalMeta),
      );
    }
    if (data.containsKey('ticket_count')) {
      context.handle(
        _ticketCountMeta,
        ticketCount.isAcceptableOrUnknown(
          data['ticket_count']!,
          _ticketCountMeta,
        ),
      );
    }
    if (data.containsKey('loss_amount')) {
      context.handle(
        _lossAmountMeta,
        lossAmount.isAcceptableOrUnknown(data['loss_amount']!, _lossAmountMeta),
      );
    }
    if (data.containsKey('bill_closed_by')) {
      context.handle(
        _billClosedByMeta,
        billClosedBy.isAcceptableOrUnknown(
          data['bill_closed_by']!,
          _billClosedByMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TableSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TableSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_id'],
      )!,
      tableLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_label'],
      ),
      zoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_id'],
      )!,
      pax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pax'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      ),
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      )!,
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      )!,
      actorUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_user_id'],
      ),
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal'],
      )!,
      voidAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}void_amount'],
      )!,
      serviceAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_amount'],
      )!,
      taxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_amount'],
      )!,
      netTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}net_total'],
      )!,
      ticketCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ticket_count'],
      )!,
      lossAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loss_amount'],
      )!,
      billClosedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_closed_by'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  $TableSessionsTable createAlias(String alias) {
    return $TableSessionsTable(attachedDatabase, alias);
  }
}

class TableSession extends DataClass implements Insertable<TableSession> {
  final String id;
  final String tableId;
  final String? tableLabel;
  final String zoneId;
  final int pax;
  final DateTime? openedAt;
  final DateTime closedAt;
  final int durationSec;
  final String? actorUserId;
  final int subtotal;
  final int voidAmount;

  /// Service charge + tax applied at settlement (ADR-0023). Pre-v28 sessions
  /// carry 0 (tax/service were never applied before settlement existed).
  final int serviceAmount;
  final int taxAmount;

  /// REDEFINED in ADR-0023: now the actually-settled total
  /// (`subtotal − void + service + tax`), not the old `netTotal == subtotal`.
  /// Historical pre-v28 rows still equal their subtotal.
  final int netTotal;
  final int ticketCount;

  /// Outstanding written off at bill-close as a recorded loss — a walkout /
  /// "tak tertagih" close. 0 for a normal (Lunas) close. Distinct from a comp
  /// (which zeroes a line); this is the unpaid remainder. See ADR-0024.
  final int lossAmount;

  /// Cashier (userId) who performed the bill-close. ADR-0024.
  final String? billClosedBy;

  /// Visit kind frozen at snapshot: `dineIn` (default) | `takeaway`. Lets
  /// reports split takeaway out of per-cover / turn-time / occupancy. ADR-0026.
  final String kind;
  const TableSession({
    required this.id,
    required this.tableId,
    this.tableLabel,
    required this.zoneId,
    required this.pax,
    this.openedAt,
    required this.closedAt,
    required this.durationSec,
    this.actorUserId,
    required this.subtotal,
    required this.voidAmount,
    required this.serviceAmount,
    required this.taxAmount,
    required this.netTotal,
    required this.ticketCount,
    required this.lossAmount,
    this.billClosedBy,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['table_id'] = Variable<String>(tableId);
    if (!nullToAbsent || tableLabel != null) {
      map['table_label'] = Variable<String>(tableLabel);
    }
    map['zone_id'] = Variable<String>(zoneId);
    map['pax'] = Variable<int>(pax);
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    map['closed_at'] = Variable<DateTime>(closedAt);
    map['duration_sec'] = Variable<int>(durationSec);
    if (!nullToAbsent || actorUserId != null) {
      map['actor_user_id'] = Variable<String>(actorUserId);
    }
    map['subtotal'] = Variable<int>(subtotal);
    map['void_amount'] = Variable<int>(voidAmount);
    map['service_amount'] = Variable<int>(serviceAmount);
    map['tax_amount'] = Variable<int>(taxAmount);
    map['net_total'] = Variable<int>(netTotal);
    map['ticket_count'] = Variable<int>(ticketCount);
    map['loss_amount'] = Variable<int>(lossAmount);
    if (!nullToAbsent || billClosedBy != null) {
      map['bill_closed_by'] = Variable<String>(billClosedBy);
    }
    map['kind'] = Variable<String>(kind);
    return map;
  }

  TableSessionsCompanion toCompanion(bool nullToAbsent) {
    return TableSessionsCompanion(
      id: Value(id),
      tableId: Value(tableId),
      tableLabel: tableLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(tableLabel),
      zoneId: Value(zoneId),
      pax: Value(pax),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      closedAt: Value(closedAt),
      durationSec: Value(durationSec),
      actorUserId: actorUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorUserId),
      subtotal: Value(subtotal),
      voidAmount: Value(voidAmount),
      serviceAmount: Value(serviceAmount),
      taxAmount: Value(taxAmount),
      netTotal: Value(netTotal),
      ticketCount: Value(ticketCount),
      lossAmount: Value(lossAmount),
      billClosedBy: billClosedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(billClosedBy),
      kind: Value(kind),
    );
  }

  factory TableSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TableSession(
      id: serializer.fromJson<String>(json['id']),
      tableId: serializer.fromJson<String>(json['tableId']),
      tableLabel: serializer.fromJson<String?>(json['tableLabel']),
      zoneId: serializer.fromJson<String>(json['zoneId']),
      pax: serializer.fromJson<int>(json['pax']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
      closedAt: serializer.fromJson<DateTime>(json['closedAt']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      actorUserId: serializer.fromJson<String?>(json['actorUserId']),
      subtotal: serializer.fromJson<int>(json['subtotal']),
      voidAmount: serializer.fromJson<int>(json['voidAmount']),
      serviceAmount: serializer.fromJson<int>(json['serviceAmount']),
      taxAmount: serializer.fromJson<int>(json['taxAmount']),
      netTotal: serializer.fromJson<int>(json['netTotal']),
      ticketCount: serializer.fromJson<int>(json['ticketCount']),
      lossAmount: serializer.fromJson<int>(json['lossAmount']),
      billClosedBy: serializer.fromJson<String?>(json['billClosedBy']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tableId': serializer.toJson<String>(tableId),
      'tableLabel': serializer.toJson<String?>(tableLabel),
      'zoneId': serializer.toJson<String>(zoneId),
      'pax': serializer.toJson<int>(pax),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'closedAt': serializer.toJson<DateTime>(closedAt),
      'durationSec': serializer.toJson<int>(durationSec),
      'actorUserId': serializer.toJson<String?>(actorUserId),
      'subtotal': serializer.toJson<int>(subtotal),
      'voidAmount': serializer.toJson<int>(voidAmount),
      'serviceAmount': serializer.toJson<int>(serviceAmount),
      'taxAmount': serializer.toJson<int>(taxAmount),
      'netTotal': serializer.toJson<int>(netTotal),
      'ticketCount': serializer.toJson<int>(ticketCount),
      'lossAmount': serializer.toJson<int>(lossAmount),
      'billClosedBy': serializer.toJson<String?>(billClosedBy),
      'kind': serializer.toJson<String>(kind),
    };
  }

  TableSession copyWith({
    String? id,
    String? tableId,
    Value<String?> tableLabel = const Value.absent(),
    String? zoneId,
    int? pax,
    Value<DateTime?> openedAt = const Value.absent(),
    DateTime? closedAt,
    int? durationSec,
    Value<String?> actorUserId = const Value.absent(),
    int? subtotal,
    int? voidAmount,
    int? serviceAmount,
    int? taxAmount,
    int? netTotal,
    int? ticketCount,
    int? lossAmount,
    Value<String?> billClosedBy = const Value.absent(),
    String? kind,
  }) => TableSession(
    id: id ?? this.id,
    tableId: tableId ?? this.tableId,
    tableLabel: tableLabel.present ? tableLabel.value : this.tableLabel,
    zoneId: zoneId ?? this.zoneId,
    pax: pax ?? this.pax,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    closedAt: closedAt ?? this.closedAt,
    durationSec: durationSec ?? this.durationSec,
    actorUserId: actorUserId.present ? actorUserId.value : this.actorUserId,
    subtotal: subtotal ?? this.subtotal,
    voidAmount: voidAmount ?? this.voidAmount,
    serviceAmount: serviceAmount ?? this.serviceAmount,
    taxAmount: taxAmount ?? this.taxAmount,
    netTotal: netTotal ?? this.netTotal,
    ticketCount: ticketCount ?? this.ticketCount,
    lossAmount: lossAmount ?? this.lossAmount,
    billClosedBy: billClosedBy.present ? billClosedBy.value : this.billClosedBy,
    kind: kind ?? this.kind,
  );
  TableSession copyWithCompanion(TableSessionsCompanion data) {
    return TableSession(
      id: data.id.present ? data.id.value : this.id,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      tableLabel: data.tableLabel.present
          ? data.tableLabel.value
          : this.tableLabel,
      zoneId: data.zoneId.present ? data.zoneId.value : this.zoneId,
      pax: data.pax.present ? data.pax.value : this.pax,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      actorUserId: data.actorUserId.present
          ? data.actorUserId.value
          : this.actorUserId,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      voidAmount: data.voidAmount.present
          ? data.voidAmount.value
          : this.voidAmount,
      serviceAmount: data.serviceAmount.present
          ? data.serviceAmount.value
          : this.serviceAmount,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      netTotal: data.netTotal.present ? data.netTotal.value : this.netTotal,
      ticketCount: data.ticketCount.present
          ? data.ticketCount.value
          : this.ticketCount,
      lossAmount: data.lossAmount.present
          ? data.lossAmount.value
          : this.lossAmount,
      billClosedBy: data.billClosedBy.present
          ? data.billClosedBy.value
          : this.billClosedBy,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TableSession(')
          ..write('id: $id, ')
          ..write('tableId: $tableId, ')
          ..write('tableLabel: $tableLabel, ')
          ..write('zoneId: $zoneId, ')
          ..write('pax: $pax, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('durationSec: $durationSec, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('subtotal: $subtotal, ')
          ..write('voidAmount: $voidAmount, ')
          ..write('serviceAmount: $serviceAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('netTotal: $netTotal, ')
          ..write('ticketCount: $ticketCount, ')
          ..write('lossAmount: $lossAmount, ')
          ..write('billClosedBy: $billClosedBy, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tableId,
    tableLabel,
    zoneId,
    pax,
    openedAt,
    closedAt,
    durationSec,
    actorUserId,
    subtotal,
    voidAmount,
    serviceAmount,
    taxAmount,
    netTotal,
    ticketCount,
    lossAmount,
    billClosedBy,
    kind,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TableSession &&
          other.id == this.id &&
          other.tableId == this.tableId &&
          other.tableLabel == this.tableLabel &&
          other.zoneId == this.zoneId &&
          other.pax == this.pax &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.durationSec == this.durationSec &&
          other.actorUserId == this.actorUserId &&
          other.subtotal == this.subtotal &&
          other.voidAmount == this.voidAmount &&
          other.serviceAmount == this.serviceAmount &&
          other.taxAmount == this.taxAmount &&
          other.netTotal == this.netTotal &&
          other.ticketCount == this.ticketCount &&
          other.lossAmount == this.lossAmount &&
          other.billClosedBy == this.billClosedBy &&
          other.kind == this.kind);
}

class TableSessionsCompanion extends UpdateCompanion<TableSession> {
  final Value<String> id;
  final Value<String> tableId;
  final Value<String?> tableLabel;
  final Value<String> zoneId;
  final Value<int> pax;
  final Value<DateTime?> openedAt;
  final Value<DateTime> closedAt;
  final Value<int> durationSec;
  final Value<String?> actorUserId;
  final Value<int> subtotal;
  final Value<int> voidAmount;
  final Value<int> serviceAmount;
  final Value<int> taxAmount;
  final Value<int> netTotal;
  final Value<int> ticketCount;
  final Value<int> lossAmount;
  final Value<String?> billClosedBy;
  final Value<String> kind;
  final Value<int> rowid;
  const TableSessionsCompanion({
    this.id = const Value.absent(),
    this.tableId = const Value.absent(),
    this.tableLabel = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.pax = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.actorUserId = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.voidAmount = const Value.absent(),
    this.serviceAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.netTotal = const Value.absent(),
    this.ticketCount = const Value.absent(),
    this.lossAmount = const Value.absent(),
    this.billClosedBy = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TableSessionsCompanion.insert({
    required String id,
    required String tableId,
    this.tableLabel = const Value.absent(),
    required String zoneId,
    this.pax = const Value.absent(),
    this.openedAt = const Value.absent(),
    required DateTime closedAt,
    this.durationSec = const Value.absent(),
    this.actorUserId = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.voidAmount = const Value.absent(),
    this.serviceAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.netTotal = const Value.absent(),
    this.ticketCount = const Value.absent(),
    this.lossAmount = const Value.absent(),
    this.billClosedBy = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tableId = Value(tableId),
       zoneId = Value(zoneId),
       closedAt = Value(closedAt);
  static Insertable<TableSession> custom({
    Expression<String>? id,
    Expression<String>? tableId,
    Expression<String>? tableLabel,
    Expression<String>? zoneId,
    Expression<int>? pax,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? closedAt,
    Expression<int>? durationSec,
    Expression<String>? actorUserId,
    Expression<int>? subtotal,
    Expression<int>? voidAmount,
    Expression<int>? serviceAmount,
    Expression<int>? taxAmount,
    Expression<int>? netTotal,
    Expression<int>? ticketCount,
    Expression<int>? lossAmount,
    Expression<String>? billClosedBy,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tableId != null) 'table_id': tableId,
      if (tableLabel != null) 'table_label': tableLabel,
      if (zoneId != null) 'zone_id': zoneId,
      if (pax != null) 'pax': pax,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (durationSec != null) 'duration_sec': durationSec,
      if (actorUserId != null) 'actor_user_id': actorUserId,
      if (subtotal != null) 'subtotal': subtotal,
      if (voidAmount != null) 'void_amount': voidAmount,
      if (serviceAmount != null) 'service_amount': serviceAmount,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (netTotal != null) 'net_total': netTotal,
      if (ticketCount != null) 'ticket_count': ticketCount,
      if (lossAmount != null) 'loss_amount': lossAmount,
      if (billClosedBy != null) 'bill_closed_by': billClosedBy,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TableSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? tableId,
    Value<String?>? tableLabel,
    Value<String>? zoneId,
    Value<int>? pax,
    Value<DateTime?>? openedAt,
    Value<DateTime>? closedAt,
    Value<int>? durationSec,
    Value<String?>? actorUserId,
    Value<int>? subtotal,
    Value<int>? voidAmount,
    Value<int>? serviceAmount,
    Value<int>? taxAmount,
    Value<int>? netTotal,
    Value<int>? ticketCount,
    Value<int>? lossAmount,
    Value<String?>? billClosedBy,
    Value<String>? kind,
    Value<int>? rowid,
  }) {
    return TableSessionsCompanion(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableLabel: tableLabel ?? this.tableLabel,
      zoneId: zoneId ?? this.zoneId,
      pax: pax ?? this.pax,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      durationSec: durationSec ?? this.durationSec,
      actorUserId: actorUserId ?? this.actorUserId,
      subtotal: subtotal ?? this.subtotal,
      voidAmount: voidAmount ?? this.voidAmount,
      serviceAmount: serviceAmount ?? this.serviceAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      netTotal: netTotal ?? this.netTotal,
      ticketCount: ticketCount ?? this.ticketCount,
      lossAmount: lossAmount ?? this.lossAmount,
      billClosedBy: billClosedBy ?? this.billClosedBy,
      kind: kind ?? this.kind,
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
    if (tableLabel.present) {
      map['table_label'] = Variable<String>(tableLabel.value);
    }
    if (zoneId.present) {
      map['zone_id'] = Variable<String>(zoneId.value);
    }
    if (pax.present) {
      map['pax'] = Variable<int>(pax.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (actorUserId.present) {
      map['actor_user_id'] = Variable<String>(actorUserId.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<int>(subtotal.value);
    }
    if (voidAmount.present) {
      map['void_amount'] = Variable<int>(voidAmount.value);
    }
    if (serviceAmount.present) {
      map['service_amount'] = Variable<int>(serviceAmount.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<int>(taxAmount.value);
    }
    if (netTotal.present) {
      map['net_total'] = Variable<int>(netTotal.value);
    }
    if (ticketCount.present) {
      map['ticket_count'] = Variable<int>(ticketCount.value);
    }
    if (lossAmount.present) {
      map['loss_amount'] = Variable<int>(lossAmount.value);
    }
    if (billClosedBy.present) {
      map['bill_closed_by'] = Variable<String>(billClosedBy.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TableSessionsCompanion(')
          ..write('id: $id, ')
          ..write('tableId: $tableId, ')
          ..write('tableLabel: $tableLabel, ')
          ..write('zoneId: $zoneId, ')
          ..write('pax: $pax, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('durationSec: $durationSec, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('subtotal: $subtotal, ')
          ..write('voidAmount: $voidAmount, ')
          ..write('serviceAmount: $serviceAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('netTotal: $netTotal, ')
          ..write('ticketCount: $ticketCount, ')
          ..write('lossAmount: $lossAmount, ')
          ..write('billClosedBy: $billClosedBy, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TableSessionTicketsTable extends TableSessionTickets
    with TableInfo<$TableSessionTicketsTable, TableSessionTicket> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TableSessionTicketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ticketIdMeta = const VerificationMeta(
    'ticketId',
  );
  @override
  late final GeneratedColumn<String> ticketId = GeneratedColumn<String>(
    'ticket_id',
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
  static const VerificationMeta _readyAtMeta = const VerificationMeta(
    'readyAt',
  );
  @override
  late final GeneratedColumn<DateTime> readyAt = GeneratedColumn<DateTime>(
    'ready_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servedAtMeta = const VerificationMeta(
    'servedAt',
  );
  @override
  late final GeneratedColumn<DateTime> servedAt = GeneratedColumn<DateTime>(
    'served_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  static const VerificationMeta _voidReasonCodeMeta = const VerificationMeta(
    'voidReasonCode',
  );
  @override
  late final GeneratedColumn<String> voidReasonCode = GeneratedColumn<String>(
    'void_reason_code',
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
  static const VerificationMeta _voidedByUserIdMeta = const VerificationMeta(
    'voidedByUserId',
  );
  @override
  late final GeneratedColumn<String> voidedByUserId = GeneratedColumn<String>(
    'voided_by_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    ticketId,
    itemId,
    name,
    variantName,
    course,
    qty,
    modifiersJson,
    note,
    price,
    status,
    sentAt,
    readyAt,
    servedAt,
    voidReason,
    voidReasonCode,
    voidApprovedBy,
    createdByUserId,
    voidedByUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'table_session_tickets';
  @override
  VerificationContext validateIntegrity(
    Insertable<TableSessionTicket> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('ticket_id')) {
      context.handle(
        _ticketIdMeta,
        ticketId.isAcceptableOrUnknown(data['ticket_id']!, _ticketIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ticketIdMeta);
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
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
    if (data.containsKey('ready_at')) {
      context.handle(
        _readyAtMeta,
        readyAt.isAcceptableOrUnknown(data['ready_at']!, _readyAtMeta),
      );
    }
    if (data.containsKey('served_at')) {
      context.handle(
        _servedAtMeta,
        servedAt.isAcceptableOrUnknown(data['served_at']!, _servedAtMeta),
      );
    }
    if (data.containsKey('void_reason')) {
      context.handle(
        _voidReasonMeta,
        voidReason.isAcceptableOrUnknown(data['void_reason']!, _voidReasonMeta),
      );
    }
    if (data.containsKey('void_reason_code')) {
      context.handle(
        _voidReasonCodeMeta,
        voidReasonCode.isAcceptableOrUnknown(
          data['void_reason_code']!,
          _voidReasonCodeMeta,
        ),
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
    if (data.containsKey('voided_by_user_id')) {
      context.handle(
        _voidedByUserIdMeta,
        voidedByUserId.isAcceptableOrUnknown(
          data['voided_by_user_id']!,
          _voidedByUserIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TableSessionTicket map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TableSessionTicket(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      ticketId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_id'],
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
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      modifiersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modifiers_json'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
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
      readyAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ready_at'],
      ),
      servedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}served_at'],
      ),
      voidReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_reason'],
      ),
      voidReasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_reason_code'],
      ),
      voidApprovedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_approved_by'],
      ),
      createdByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_user_id'],
      ),
      voidedByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voided_by_user_id'],
      ),
    );
  }

  @override
  $TableSessionTicketsTable createAlias(String alias) {
    return $TableSessionTicketsTable(attachedDatabase, alias);
  }
}

class TableSessionTicket extends DataClass
    implements Insertable<TableSessionTicket> {
  final String id;
  final String sessionId;
  final String ticketId;
  final String itemId;
  final String name;
  final String variantName;
  final String course;
  final int qty;
  final String modifiersJson;
  final String? note;
  final int price;
  final String status;
  final DateTime sentAt;

  /// Mirrors Tickets.readyAt / Tickets.servedAt at session close, so speed-of-
  /// service survives the live-ticket delete. See ADR-0013.
  final DateTime? readyAt;
  final DateTime? servedAt;
  final String? voidReason;

  /// Canonical enum slug — mirrors Tickets.voidReasonCode at session close.
  final String? voidReasonCode;
  final String? voidApprovedBy;
  final String? createdByUserId;

  /// Mirrors Tickets.voidedByUserId at session close.
  final String? voidedByUserId;
  const TableSessionTicket({
    required this.id,
    required this.sessionId,
    required this.ticketId,
    required this.itemId,
    required this.name,
    required this.variantName,
    required this.course,
    required this.qty,
    required this.modifiersJson,
    this.note,
    required this.price,
    required this.status,
    required this.sentAt,
    this.readyAt,
    this.servedAt,
    this.voidReason,
    this.voidReasonCode,
    this.voidApprovedBy,
    this.createdByUserId,
    this.voidedByUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['ticket_id'] = Variable<String>(ticketId);
    map['item_id'] = Variable<String>(itemId);
    map['name'] = Variable<String>(name);
    map['variant_name'] = Variable<String>(variantName);
    map['course'] = Variable<String>(course);
    map['qty'] = Variable<int>(qty);
    map['modifiers_json'] = Variable<String>(modifiersJson);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['price'] = Variable<int>(price);
    map['status'] = Variable<String>(status);
    map['sent_at'] = Variable<DateTime>(sentAt);
    if (!nullToAbsent || readyAt != null) {
      map['ready_at'] = Variable<DateTime>(readyAt);
    }
    if (!nullToAbsent || servedAt != null) {
      map['served_at'] = Variable<DateTime>(servedAt);
    }
    if (!nullToAbsent || voidReason != null) {
      map['void_reason'] = Variable<String>(voidReason);
    }
    if (!nullToAbsent || voidReasonCode != null) {
      map['void_reason_code'] = Variable<String>(voidReasonCode);
    }
    if (!nullToAbsent || voidApprovedBy != null) {
      map['void_approved_by'] = Variable<String>(voidApprovedBy);
    }
    if (!nullToAbsent || createdByUserId != null) {
      map['created_by_user_id'] = Variable<String>(createdByUserId);
    }
    if (!nullToAbsent || voidedByUserId != null) {
      map['voided_by_user_id'] = Variable<String>(voidedByUserId);
    }
    return map;
  }

  TableSessionTicketsCompanion toCompanion(bool nullToAbsent) {
    return TableSessionTicketsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      ticketId: Value(ticketId),
      itemId: Value(itemId),
      name: Value(name),
      variantName: Value(variantName),
      course: Value(course),
      qty: Value(qty),
      modifiersJson: Value(modifiersJson),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      price: Value(price),
      status: Value(status),
      sentAt: Value(sentAt),
      readyAt: readyAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readyAt),
      servedAt: servedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(servedAt),
      voidReason: voidReason == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReason),
      voidReasonCode: voidReasonCode == null && nullToAbsent
          ? const Value.absent()
          : Value(voidReasonCode),
      voidApprovedBy: voidApprovedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(voidApprovedBy),
      createdByUserId: createdByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserId),
      voidedByUserId: voidedByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedByUserId),
    );
  }

  factory TableSessionTicket.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TableSessionTicket(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      ticketId: serializer.fromJson<String>(json['ticketId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      name: serializer.fromJson<String>(json['name']),
      variantName: serializer.fromJson<String>(json['variantName']),
      course: serializer.fromJson<String>(json['course']),
      qty: serializer.fromJson<int>(json['qty']),
      modifiersJson: serializer.fromJson<String>(json['modifiersJson']),
      note: serializer.fromJson<String?>(json['note']),
      price: serializer.fromJson<int>(json['price']),
      status: serializer.fromJson<String>(json['status']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      readyAt: serializer.fromJson<DateTime?>(json['readyAt']),
      servedAt: serializer.fromJson<DateTime?>(json['servedAt']),
      voidReason: serializer.fromJson<String?>(json['voidReason']),
      voidReasonCode: serializer.fromJson<String?>(json['voidReasonCode']),
      voidApprovedBy: serializer.fromJson<String?>(json['voidApprovedBy']),
      createdByUserId: serializer.fromJson<String?>(json['createdByUserId']),
      voidedByUserId: serializer.fromJson<String?>(json['voidedByUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'ticketId': serializer.toJson<String>(ticketId),
      'itemId': serializer.toJson<String>(itemId),
      'name': serializer.toJson<String>(name),
      'variantName': serializer.toJson<String>(variantName),
      'course': serializer.toJson<String>(course),
      'qty': serializer.toJson<int>(qty),
      'modifiersJson': serializer.toJson<String>(modifiersJson),
      'note': serializer.toJson<String?>(note),
      'price': serializer.toJson<int>(price),
      'status': serializer.toJson<String>(status),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'readyAt': serializer.toJson<DateTime?>(readyAt),
      'servedAt': serializer.toJson<DateTime?>(servedAt),
      'voidReason': serializer.toJson<String?>(voidReason),
      'voidReasonCode': serializer.toJson<String?>(voidReasonCode),
      'voidApprovedBy': serializer.toJson<String?>(voidApprovedBy),
      'createdByUserId': serializer.toJson<String?>(createdByUserId),
      'voidedByUserId': serializer.toJson<String?>(voidedByUserId),
    };
  }

  TableSessionTicket copyWith({
    String? id,
    String? sessionId,
    String? ticketId,
    String? itemId,
    String? name,
    String? variantName,
    String? course,
    int? qty,
    String? modifiersJson,
    Value<String?> note = const Value.absent(),
    int? price,
    String? status,
    DateTime? sentAt,
    Value<DateTime?> readyAt = const Value.absent(),
    Value<DateTime?> servedAt = const Value.absent(),
    Value<String?> voidReason = const Value.absent(),
    Value<String?> voidReasonCode = const Value.absent(),
    Value<String?> voidApprovedBy = const Value.absent(),
    Value<String?> createdByUserId = const Value.absent(),
    Value<String?> voidedByUserId = const Value.absent(),
  }) => TableSessionTicket(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    ticketId: ticketId ?? this.ticketId,
    itemId: itemId ?? this.itemId,
    name: name ?? this.name,
    variantName: variantName ?? this.variantName,
    course: course ?? this.course,
    qty: qty ?? this.qty,
    modifiersJson: modifiersJson ?? this.modifiersJson,
    note: note.present ? note.value : this.note,
    price: price ?? this.price,
    status: status ?? this.status,
    sentAt: sentAt ?? this.sentAt,
    readyAt: readyAt.present ? readyAt.value : this.readyAt,
    servedAt: servedAt.present ? servedAt.value : this.servedAt,
    voidReason: voidReason.present ? voidReason.value : this.voidReason,
    voidReasonCode: voidReasonCode.present
        ? voidReasonCode.value
        : this.voidReasonCode,
    voidApprovedBy: voidApprovedBy.present
        ? voidApprovedBy.value
        : this.voidApprovedBy,
    createdByUserId: createdByUserId.present
        ? createdByUserId.value
        : this.createdByUserId,
    voidedByUserId: voidedByUserId.present
        ? voidedByUserId.value
        : this.voidedByUserId,
  );
  TableSessionTicket copyWithCompanion(TableSessionTicketsCompanion data) {
    return TableSessionTicket(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      ticketId: data.ticketId.present ? data.ticketId.value : this.ticketId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      name: data.name.present ? data.name.value : this.name,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      course: data.course.present ? data.course.value : this.course,
      qty: data.qty.present ? data.qty.value : this.qty,
      modifiersJson: data.modifiersJson.present
          ? data.modifiersJson.value
          : this.modifiersJson,
      note: data.note.present ? data.note.value : this.note,
      price: data.price.present ? data.price.value : this.price,
      status: data.status.present ? data.status.value : this.status,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      readyAt: data.readyAt.present ? data.readyAt.value : this.readyAt,
      servedAt: data.servedAt.present ? data.servedAt.value : this.servedAt,
      voidReason: data.voidReason.present
          ? data.voidReason.value
          : this.voidReason,
      voidReasonCode: data.voidReasonCode.present
          ? data.voidReasonCode.value
          : this.voidReasonCode,
      voidApprovedBy: data.voidApprovedBy.present
          ? data.voidApprovedBy.value
          : this.voidApprovedBy,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      voidedByUserId: data.voidedByUserId.present
          ? data.voidedByUserId.value
          : this.voidedByUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TableSessionTicket(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('ticketId: $ticketId, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('variantName: $variantName, ')
          ..write('course: $course, ')
          ..write('qty: $qty, ')
          ..write('modifiersJson: $modifiersJson, ')
          ..write('note: $note, ')
          ..write('price: $price, ')
          ..write('status: $status, ')
          ..write('sentAt: $sentAt, ')
          ..write('readyAt: $readyAt, ')
          ..write('servedAt: $servedAt, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidReasonCode: $voidReasonCode, ')
          ..write('voidApprovedBy: $voidApprovedBy, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('voidedByUserId: $voidedByUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    ticketId,
    itemId,
    name,
    variantName,
    course,
    qty,
    modifiersJson,
    note,
    price,
    status,
    sentAt,
    readyAt,
    servedAt,
    voidReason,
    voidReasonCode,
    voidApprovedBy,
    createdByUserId,
    voidedByUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TableSessionTicket &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.ticketId == this.ticketId &&
          other.itemId == this.itemId &&
          other.name == this.name &&
          other.variantName == this.variantName &&
          other.course == this.course &&
          other.qty == this.qty &&
          other.modifiersJson == this.modifiersJson &&
          other.note == this.note &&
          other.price == this.price &&
          other.status == this.status &&
          other.sentAt == this.sentAt &&
          other.readyAt == this.readyAt &&
          other.servedAt == this.servedAt &&
          other.voidReason == this.voidReason &&
          other.voidReasonCode == this.voidReasonCode &&
          other.voidApprovedBy == this.voidApprovedBy &&
          other.createdByUserId == this.createdByUserId &&
          other.voidedByUserId == this.voidedByUserId);
}

class TableSessionTicketsCompanion extends UpdateCompanion<TableSessionTicket> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> ticketId;
  final Value<String> itemId;
  final Value<String> name;
  final Value<String> variantName;
  final Value<String> course;
  final Value<int> qty;
  final Value<String> modifiersJson;
  final Value<String?> note;
  final Value<int> price;
  final Value<String> status;
  final Value<DateTime> sentAt;
  final Value<DateTime?> readyAt;
  final Value<DateTime?> servedAt;
  final Value<String?> voidReason;
  final Value<String?> voidReasonCode;
  final Value<String?> voidApprovedBy;
  final Value<String?> createdByUserId;
  final Value<String?> voidedByUserId;
  final Value<int> rowid;
  const TableSessionTicketsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.ticketId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.name = const Value.absent(),
    this.variantName = const Value.absent(),
    this.course = const Value.absent(),
    this.qty = const Value.absent(),
    this.modifiersJson = const Value.absent(),
    this.note = const Value.absent(),
    this.price = const Value.absent(),
    this.status = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.readyAt = const Value.absent(),
    this.servedAt = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidReasonCode = const Value.absent(),
    this.voidApprovedBy = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.voidedByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TableSessionTicketsCompanion.insert({
    required String id,
    required String sessionId,
    required String ticketId,
    required String itemId,
    required String name,
    this.variantName = const Value.absent(),
    required String course,
    this.qty = const Value.absent(),
    this.modifiersJson = const Value.absent(),
    this.note = const Value.absent(),
    required int price,
    required String status,
    required DateTime sentAt,
    this.readyAt = const Value.absent(),
    this.servedAt = const Value.absent(),
    this.voidReason = const Value.absent(),
    this.voidReasonCode = const Value.absent(),
    this.voidApprovedBy = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.voidedByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       ticketId = Value(ticketId),
       itemId = Value(itemId),
       name = Value(name),
       course = Value(course),
       price = Value(price),
       status = Value(status),
       sentAt = Value(sentAt);
  static Insertable<TableSessionTicket> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? ticketId,
    Expression<String>? itemId,
    Expression<String>? name,
    Expression<String>? variantName,
    Expression<String>? course,
    Expression<int>? qty,
    Expression<String>? modifiersJson,
    Expression<String>? note,
    Expression<int>? price,
    Expression<String>? status,
    Expression<DateTime>? sentAt,
    Expression<DateTime>? readyAt,
    Expression<DateTime>? servedAt,
    Expression<String>? voidReason,
    Expression<String>? voidReasonCode,
    Expression<String>? voidApprovedBy,
    Expression<String>? createdByUserId,
    Expression<String>? voidedByUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (ticketId != null) 'ticket_id': ticketId,
      if (itemId != null) 'item_id': itemId,
      if (name != null) 'name': name,
      if (variantName != null) 'variant_name': variantName,
      if (course != null) 'course': course,
      if (qty != null) 'qty': qty,
      if (modifiersJson != null) 'modifiers_json': modifiersJson,
      if (note != null) 'note': note,
      if (price != null) 'price': price,
      if (status != null) 'status': status,
      if (sentAt != null) 'sent_at': sentAt,
      if (readyAt != null) 'ready_at': readyAt,
      if (servedAt != null) 'served_at': servedAt,
      if (voidReason != null) 'void_reason': voidReason,
      if (voidReasonCode != null) 'void_reason_code': voidReasonCode,
      if (voidApprovedBy != null) 'void_approved_by': voidApprovedBy,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (voidedByUserId != null) 'voided_by_user_id': voidedByUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TableSessionTicketsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? ticketId,
    Value<String>? itemId,
    Value<String>? name,
    Value<String>? variantName,
    Value<String>? course,
    Value<int>? qty,
    Value<String>? modifiersJson,
    Value<String?>? note,
    Value<int>? price,
    Value<String>? status,
    Value<DateTime>? sentAt,
    Value<DateTime?>? readyAt,
    Value<DateTime?>? servedAt,
    Value<String?>? voidReason,
    Value<String?>? voidReasonCode,
    Value<String?>? voidApprovedBy,
    Value<String?>? createdByUserId,
    Value<String?>? voidedByUserId,
    Value<int>? rowid,
  }) {
    return TableSessionTicketsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      ticketId: ticketId ?? this.ticketId,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      variantName: variantName ?? this.variantName,
      course: course ?? this.course,
      qty: qty ?? this.qty,
      modifiersJson: modifiersJson ?? this.modifiersJson,
      note: note ?? this.note,
      price: price ?? this.price,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      readyAt: readyAt ?? this.readyAt,
      servedAt: servedAt ?? this.servedAt,
      voidReason: voidReason ?? this.voidReason,
      voidReasonCode: voidReasonCode ?? this.voidReasonCode,
      voidApprovedBy: voidApprovedBy ?? this.voidApprovedBy,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      voidedByUserId: voidedByUserId ?? this.voidedByUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (ticketId.present) {
      map['ticket_id'] = Variable<String>(ticketId.value);
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
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (modifiersJson.present) {
      map['modifiers_json'] = Variable<String>(modifiersJson.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    if (readyAt.present) {
      map['ready_at'] = Variable<DateTime>(readyAt.value);
    }
    if (servedAt.present) {
      map['served_at'] = Variable<DateTime>(servedAt.value);
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    if (voidReasonCode.present) {
      map['void_reason_code'] = Variable<String>(voidReasonCode.value);
    }
    if (voidApprovedBy.present) {
      map['void_approved_by'] = Variable<String>(voidApprovedBy.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (voidedByUserId.present) {
      map['voided_by_user_id'] = Variable<String>(voidedByUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TableSessionTicketsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('ticketId: $ticketId, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('variantName: $variantName, ')
          ..write('course: $course, ')
          ..write('qty: $qty, ')
          ..write('modifiersJson: $modifiersJson, ')
          ..write('note: $note, ')
          ..write('price: $price, ')
          ..write('status: $status, ')
          ..write('sentAt: $sentAt, ')
          ..write('readyAt: $readyAt, ')
          ..write('servedAt: $servedAt, ')
          ..write('voidReason: $voidReason, ')
          ..write('voidReasonCode: $voidReasonCode, ')
          ..write('voidApprovedBy: $voidApprovedBy, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('voidedByUserId: $voidedByUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TableSessionCoursesTable extends TableSessionCourses
    with TableInfo<$TableSessionCoursesTable, TableSessionCourse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TableSessionCoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firedAtMeta = const VerificationMeta(
    'firedAt',
  );
  @override
  late final GeneratedColumn<DateTime> firedAt = GeneratedColumn<DateTime>(
    'fired_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servedAtMeta = const VerificationMeta(
    'servedAt',
  );
  @override
  late final GeneratedColumn<DateTime> servedAt = GeneratedColumn<DateTime>(
    'served_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ticketCountMeta = const VerificationMeta(
    'ticketCount',
  );
  @override
  late final GeneratedColumn<int> ticketCount = GeneratedColumn<int>(
    'ticket_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    courseId,
    firedAt,
    servedAt,
    ticketCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'table_session_courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<TableSessionCourse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('fired_at')) {
      context.handle(
        _firedAtMeta,
        firedAt.isAcceptableOrUnknown(data['fired_at']!, _firedAtMeta),
      );
    }
    if (data.containsKey('served_at')) {
      context.handle(
        _servedAtMeta,
        servedAt.isAcceptableOrUnknown(data['served_at']!, _servedAtMeta),
      );
    }
    if (data.containsKey('ticket_count')) {
      context.handle(
        _ticketCountMeta,
        ticketCount.isAcceptableOrUnknown(
          data['ticket_count']!,
          _ticketCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TableSessionCourse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TableSessionCourse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      firedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fired_at'],
      ),
      servedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}served_at'],
      ),
      ticketCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ticket_count'],
      )!,
    );
  }

  @override
  $TableSessionCoursesTable createAlias(String alias) {
    return $TableSessionCoursesTable(attachedDatabase, alias);
  }
}

class TableSessionCourse extends DataClass
    implements Insertable<TableSessionCourse> {
  final String id;
  final String sessionId;
  final String courseId;
  final DateTime? firedAt;
  final DateTime? servedAt;
  final int ticketCount;
  const TableSessionCourse({
    required this.id,
    required this.sessionId,
    required this.courseId,
    this.firedAt,
    this.servedAt,
    required this.ticketCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['course_id'] = Variable<String>(courseId);
    if (!nullToAbsent || firedAt != null) {
      map['fired_at'] = Variable<DateTime>(firedAt);
    }
    if (!nullToAbsent || servedAt != null) {
      map['served_at'] = Variable<DateTime>(servedAt);
    }
    map['ticket_count'] = Variable<int>(ticketCount);
    return map;
  }

  TableSessionCoursesCompanion toCompanion(bool nullToAbsent) {
    return TableSessionCoursesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      courseId: Value(courseId),
      firedAt: firedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firedAt),
      servedAt: servedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(servedAt),
      ticketCount: Value(ticketCount),
    );
  }

  factory TableSessionCourse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TableSessionCourse(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      courseId: serializer.fromJson<String>(json['courseId']),
      firedAt: serializer.fromJson<DateTime?>(json['firedAt']),
      servedAt: serializer.fromJson<DateTime?>(json['servedAt']),
      ticketCount: serializer.fromJson<int>(json['ticketCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'courseId': serializer.toJson<String>(courseId),
      'firedAt': serializer.toJson<DateTime?>(firedAt),
      'servedAt': serializer.toJson<DateTime?>(servedAt),
      'ticketCount': serializer.toJson<int>(ticketCount),
    };
  }

  TableSessionCourse copyWith({
    String? id,
    String? sessionId,
    String? courseId,
    Value<DateTime?> firedAt = const Value.absent(),
    Value<DateTime?> servedAt = const Value.absent(),
    int? ticketCount,
  }) => TableSessionCourse(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    courseId: courseId ?? this.courseId,
    firedAt: firedAt.present ? firedAt.value : this.firedAt,
    servedAt: servedAt.present ? servedAt.value : this.servedAt,
    ticketCount: ticketCount ?? this.ticketCount,
  );
  TableSessionCourse copyWithCompanion(TableSessionCoursesCompanion data) {
    return TableSessionCourse(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      firedAt: data.firedAt.present ? data.firedAt.value : this.firedAt,
      servedAt: data.servedAt.present ? data.servedAt.value : this.servedAt,
      ticketCount: data.ticketCount.present
          ? data.ticketCount.value
          : this.ticketCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TableSessionCourse(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('courseId: $courseId, ')
          ..write('firedAt: $firedAt, ')
          ..write('servedAt: $servedAt, ')
          ..write('ticketCount: $ticketCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, courseId, firedAt, servedAt, ticketCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TableSessionCourse &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.courseId == this.courseId &&
          other.firedAt == this.firedAt &&
          other.servedAt == this.servedAt &&
          other.ticketCount == this.ticketCount);
}

class TableSessionCoursesCompanion extends UpdateCompanion<TableSessionCourse> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> courseId;
  final Value<DateTime?> firedAt;
  final Value<DateTime?> servedAt;
  final Value<int> ticketCount;
  final Value<int> rowid;
  const TableSessionCoursesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.courseId = const Value.absent(),
    this.firedAt = const Value.absent(),
    this.servedAt = const Value.absent(),
    this.ticketCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TableSessionCoursesCompanion.insert({
    required String id,
    required String sessionId,
    required String courseId,
    this.firedAt = const Value.absent(),
    this.servedAt = const Value.absent(),
    this.ticketCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       courseId = Value(courseId);
  static Insertable<TableSessionCourse> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? courseId,
    Expression<DateTime>? firedAt,
    Expression<DateTime>? servedAt,
    Expression<int>? ticketCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (courseId != null) 'course_id': courseId,
      if (firedAt != null) 'fired_at': firedAt,
      if (servedAt != null) 'served_at': servedAt,
      if (ticketCount != null) 'ticket_count': ticketCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TableSessionCoursesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? courseId,
    Value<DateTime?>? firedAt,
    Value<DateTime?>? servedAt,
    Value<int>? ticketCount,
    Value<int>? rowid,
  }) {
    return TableSessionCoursesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      courseId: courseId ?? this.courseId,
      firedAt: firedAt ?? this.firedAt,
      servedAt: servedAt ?? this.servedAt,
      ticketCount: ticketCount ?? this.ticketCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (firedAt.present) {
      map['fired_at'] = Variable<DateTime>(firedAt.value);
    }
    if (servedAt.present) {
      map['served_at'] = Variable<DateTime>(servedAt.value);
    }
    if (ticketCount.present) {
      map['ticket_count'] = Variable<int>(ticketCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TableSessionCoursesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('courseId: $courseId, ')
          ..write('firedAt: $firedAt, ')
          ..write('servedAt: $servedAt, ')
          ..write('ticketCount: $ticketCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReservationsTable extends Reservations
    with TableInfo<$ReservationsTable, Reservation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReservationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partySizeMeta = const VerificationMeta(
    'partySize',
  );
  @override
  late final GeneratedColumn<int> partySize = GeneratedColumn<int>(
    'party_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _expectedAtMeta = const VerificationMeta(
    'expectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> expectedAt = GeneratedColumn<DateTime>(
    'expected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
  static const VerificationMeta _zoneIdMeta = const VerificationMeta('zoneId');
  @override
  late final GeneratedColumn<String> zoneId = GeneratedColumn<String>(
    'zone_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    phone,
    partySize,
    expectedAt,
    status,
    zoneId,
    tableId,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reservations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reservation> instance, {
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
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('party_size')) {
      context.handle(
        _partySizeMeta,
        partySize.isAcceptableOrUnknown(data['party_size']!, _partySizeMeta),
      );
    }
    if (data.containsKey('expected_at')) {
      context.handle(
        _expectedAtMeta,
        expectedAt.isAcceptableOrUnknown(data['expected_at']!, _expectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expectedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('zone_id')) {
      context.handle(
        _zoneIdMeta,
        zoneId.isAcceptableOrUnknown(data['zone_id']!, _zoneIdMeta),
      );
    }
    if (data.containsKey('table_id')) {
      context.handle(
        _tableIdMeta,
        tableId.isAcceptableOrUnknown(data['table_id']!, _tableIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reservation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reservation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      partySize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}party_size'],
      )!,
      expectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expected_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      zoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_id'],
      ),
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ReservationsTable createAlias(String alias) {
    return $ReservationsTable(attachedDatabase, alias);
  }
}

class Reservation extends DataClass implements Insertable<Reservation> {
  final String id;
  final String name;
  final String? phone;
  final int partySize;
  final DateTime expectedAt;
  final String status;
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['party_size'] = Variable<int>(partySize);
    map['expected_at'] = Variable<DateTime>(expectedAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || zoneId != null) {
      map['zone_id'] = Variable<String>(zoneId);
    }
    if (!nullToAbsent || tableId != null) {
      map['table_id'] = Variable<String>(tableId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ReservationsCompanion toCompanion(bool nullToAbsent) {
    return ReservationsCompanion(
      id: Value(id),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      partySize: Value(partySize),
      expectedAt: Value(expectedAt),
      status: Value(status),
      zoneId: zoneId == null && nullToAbsent
          ? const Value.absent()
          : Value(zoneId),
      tableId: tableId == null && nullToAbsent
          ? const Value.absent()
          : Value(tableId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Reservation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reservation(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      partySize: serializer.fromJson<int>(json['partySize']),
      expectedAt: serializer.fromJson<DateTime>(json['expectedAt']),
      status: serializer.fromJson<String>(json['status']),
      zoneId: serializer.fromJson<String?>(json['zoneId']),
      tableId: serializer.fromJson<String?>(json['tableId']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'partySize': serializer.toJson<int>(partySize),
      'expectedAt': serializer.toJson<DateTime>(expectedAt),
      'status': serializer.toJson<String>(status),
      'zoneId': serializer.toJson<String?>(zoneId),
      'tableId': serializer.toJson<String?>(tableId),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Reservation copyWith({
    String? id,
    String? name,
    Value<String?> phone = const Value.absent(),
    int? partySize,
    DateTime? expectedAt,
    String? status,
    Value<String?> zoneId = const Value.absent(),
    Value<String?> tableId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => Reservation(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    partySize: partySize ?? this.partySize,
    expectedAt: expectedAt ?? this.expectedAt,
    status: status ?? this.status,
    zoneId: zoneId.present ? zoneId.value : this.zoneId,
    tableId: tableId.present ? tableId.value : this.tableId,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  Reservation copyWithCompanion(ReservationsCompanion data) {
    return Reservation(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      partySize: data.partySize.present ? data.partySize.value : this.partySize,
      expectedAt: data.expectedAt.present
          ? data.expectedAt.value
          : this.expectedAt,
      status: data.status.present ? data.status.value : this.status,
      zoneId: data.zoneId.present ? data.zoneId.value : this.zoneId,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reservation(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('partySize: $partySize, ')
          ..write('expectedAt: $expectedAt, ')
          ..write('status: $status, ')
          ..write('zoneId: $zoneId, ')
          ..write('tableId: $tableId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    phone,
    partySize,
    expectedAt,
    status,
    zoneId,
    tableId,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reservation &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.partySize == this.partySize &&
          other.expectedAt == this.expectedAt &&
          other.status == this.status &&
          other.zoneId == this.zoneId &&
          other.tableId == this.tableId &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReservationsCompanion extends UpdateCompanion<Reservation> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<int> partySize;
  final Value<DateTime> expectedAt;
  final Value<String> status;
  final Value<String?> zoneId;
  final Value<String?> tableId;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const ReservationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.partySize = const Value.absent(),
    this.expectedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.tableId = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReservationsCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.partySize = const Value.absent(),
    required DateTime expectedAt,
    this.status = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.tableId = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       expectedAt = Value(expectedAt),
       createdAt = Value(createdAt);
  static Insertable<Reservation> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<int>? partySize,
    Expression<DateTime>? expectedAt,
    Expression<String>? status,
    Expression<String>? zoneId,
    Expression<String>? tableId,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (partySize != null) 'party_size': partySize,
      if (expectedAt != null) 'expected_at': expectedAt,
      if (status != null) 'status': status,
      if (zoneId != null) 'zone_id': zoneId,
      if (tableId != null) 'table_id': tableId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReservationsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? phone,
    Value<int>? partySize,
    Value<DateTime>? expectedAt,
    Value<String>? status,
    Value<String?>? zoneId,
    Value<String?>? tableId,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReservationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      partySize: partySize ?? this.partySize,
      expectedAt: expectedAt ?? this.expectedAt,
      status: status ?? this.status,
      zoneId: zoneId ?? this.zoneId,
      tableId: tableId ?? this.tableId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (partySize.present) {
      map['party_size'] = Variable<int>(partySize.value);
    }
    if (expectedAt.present) {
      map['expected_at'] = Variable<DateTime>(expectedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (zoneId.present) {
      map['zone_id'] = Variable<String>(zoneId.value);
    }
    if (tableId.present) {
      map['table_id'] = Variable<String>(tableId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReservationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('partySize: $partySize, ')
          ..write('expectedAt: $expectedAt, ')
          ..write('status: $status, ')
          ..write('zoneId: $zoneId, ')
          ..write('tableId: $tableId, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptsTable extends Receipts with TableInfo<$ReceiptsTable, Receipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('itemized'),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<int> subtotal = GeneratedColumn<int>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _serviceAmountMeta = const VerificationMeta(
    'serviceAmount',
  );
  @override
  late final GeneratedColumn<int> serviceAmount = GeneratedColumn<int>(
    'service_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<int> taxAmount = GeneratedColumn<int>(
    'tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unpaid'),
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
  List<GeneratedColumn> get $columns => [
    id,
    tableId,
    visitId,
    mode,
    label,
    subtotal,
    serviceAmount,
    taxAmount,
    total,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Receipt> instance, {
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
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    }
    if (data.containsKey('service_amount')) {
      context.handle(
        _serviceAmountMeta,
        serviceAmount.isAcceptableOrUnknown(
          data['service_amount']!,
          _serviceAmountMeta,
        ),
      );
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Receipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Receipt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal'],
      )!,
      serviceAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_amount'],
      )!,
      taxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_amount'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final String id;
  final String tableId;

  /// The [[Visit]] this receipt settles — see Tickets.visitId. Nullable only
  /// for pre-v29 rows. ADR-0024.
  final String? visitId;
  final String mode;
  final String label;
  final int subtotal;
  final int serviceAmount;
  final int taxAmount;
  final int total;
  final String status;
  final DateTime createdAt;
  const Receipt({
    required this.id,
    required this.tableId,
    this.visitId,
    required this.mode,
    required this.label,
    required this.subtotal,
    required this.serviceAmount,
    required this.taxAmount,
    required this.total,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['table_id'] = Variable<String>(tableId);
    if (!nullToAbsent || visitId != null) {
      map['visit_id'] = Variable<String>(visitId);
    }
    map['mode'] = Variable<String>(mode);
    map['label'] = Variable<String>(label);
    map['subtotal'] = Variable<int>(subtotal);
    map['service_amount'] = Variable<int>(serviceAmount);
    map['tax_amount'] = Variable<int>(taxAmount);
    map['total'] = Variable<int>(total);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      id: Value(id),
      tableId: Value(tableId),
      visitId: visitId == null && nullToAbsent
          ? const Value.absent()
          : Value(visitId),
      mode: Value(mode),
      label: Value(label),
      subtotal: Value(subtotal),
      serviceAmount: Value(serviceAmount),
      taxAmount: Value(taxAmount),
      total: Value(total),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Receipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Receipt(
      id: serializer.fromJson<String>(json['id']),
      tableId: serializer.fromJson<String>(json['tableId']),
      visitId: serializer.fromJson<String?>(json['visitId']),
      mode: serializer.fromJson<String>(json['mode']),
      label: serializer.fromJson<String>(json['label']),
      subtotal: serializer.fromJson<int>(json['subtotal']),
      serviceAmount: serializer.fromJson<int>(json['serviceAmount']),
      taxAmount: serializer.fromJson<int>(json['taxAmount']),
      total: serializer.fromJson<int>(json['total']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tableId': serializer.toJson<String>(tableId),
      'visitId': serializer.toJson<String?>(visitId),
      'mode': serializer.toJson<String>(mode),
      'label': serializer.toJson<String>(label),
      'subtotal': serializer.toJson<int>(subtotal),
      'serviceAmount': serializer.toJson<int>(serviceAmount),
      'taxAmount': serializer.toJson<int>(taxAmount),
      'total': serializer.toJson<int>(total),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Receipt copyWith({
    String? id,
    String? tableId,
    Value<String?> visitId = const Value.absent(),
    String? mode,
    String? label,
    int? subtotal,
    int? serviceAmount,
    int? taxAmount,
    int? total,
    String? status,
    DateTime? createdAt,
  }) => Receipt(
    id: id ?? this.id,
    tableId: tableId ?? this.tableId,
    visitId: visitId.present ? visitId.value : this.visitId,
    mode: mode ?? this.mode,
    label: label ?? this.label,
    subtotal: subtotal ?? this.subtotal,
    serviceAmount: serviceAmount ?? this.serviceAmount,
    taxAmount: taxAmount ?? this.taxAmount,
    total: total ?? this.total,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      id: data.id.present ? data.id.value : this.id,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      mode: data.mode.present ? data.mode.value : this.mode,
      label: data.label.present ? data.label.value : this.label,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      serviceAmount: data.serviceAmount.present
          ? data.serviceAmount.value
          : this.serviceAmount,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      total: data.total.present ? data.total.value : this.total,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('id: $id, ')
          ..write('tableId: $tableId, ')
          ..write('visitId: $visitId, ')
          ..write('mode: $mode, ')
          ..write('label: $label, ')
          ..write('subtotal: $subtotal, ')
          ..write('serviceAmount: $serviceAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('total: $total, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tableId,
    visitId,
    mode,
    label,
    subtotal,
    serviceAmount,
    taxAmount,
    total,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.id == this.id &&
          other.tableId == this.tableId &&
          other.visitId == this.visitId &&
          other.mode == this.mode &&
          other.label == this.label &&
          other.subtotal == this.subtotal &&
          other.serviceAmount == this.serviceAmount &&
          other.taxAmount == this.taxAmount &&
          other.total == this.total &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<String> id;
  final Value<String> tableId;
  final Value<String?> visitId;
  final Value<String> mode;
  final Value<String> label;
  final Value<int> subtotal;
  final Value<int> serviceAmount;
  final Value<int> taxAmount;
  final Value<int> total;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.tableId = const Value.absent(),
    this.visitId = const Value.absent(),
    this.mode = const Value.absent(),
    this.label = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.serviceAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.total = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    required String id,
    required String tableId,
    this.visitId = const Value.absent(),
    this.mode = const Value.absent(),
    this.label = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.serviceAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.total = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tableId = Value(tableId),
       createdAt = Value(createdAt);
  static Insertable<Receipt> custom({
    Expression<String>? id,
    Expression<String>? tableId,
    Expression<String>? visitId,
    Expression<String>? mode,
    Expression<String>? label,
    Expression<int>? subtotal,
    Expression<int>? serviceAmount,
    Expression<int>? taxAmount,
    Expression<int>? total,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tableId != null) 'table_id': tableId,
      if (visitId != null) 'visit_id': visitId,
      if (mode != null) 'mode': mode,
      if (label != null) 'label': label,
      if (subtotal != null) 'subtotal': subtotal,
      if (serviceAmount != null) 'service_amount': serviceAmount,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (total != null) 'total': total,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptsCompanion copyWith({
    Value<String>? id,
    Value<String>? tableId,
    Value<String?>? visitId,
    Value<String>? mode,
    Value<String>? label,
    Value<int>? subtotal,
    Value<int>? serviceAmount,
    Value<int>? taxAmount,
    Value<int>? total,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ReceiptsCompanion(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      visitId: visitId ?? this.visitId,
      mode: mode ?? this.mode,
      label: label ?? this.label,
      subtotal: subtotal ?? this.subtotal,
      serviceAmount: serviceAmount ?? this.serviceAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
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
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<int>(subtotal.value);
    }
    if (serviceAmount.present) {
      map['service_amount'] = Variable<int>(serviceAmount.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<int>(taxAmount.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
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
    return (StringBuffer('ReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('tableId: $tableId, ')
          ..write('visitId: $visitId, ')
          ..write('mode: $mode, ')
          ..write('label: $label, ')
          ..write('subtotal: $subtotal, ')
          ..write('serviceAmount: $serviceAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('total: $total, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptLinesTable extends ReceiptLines
    with TableInfo<$ReceiptLinesTable, ReceiptLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ticketIdMeta = const VerificationMeta(
    'ticketId',
  );
  @override
  late final GeneratedColumn<String> ticketId = GeneratedColumn<String>(
    'ticket_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyUnitsMeta = const VerificationMeta(
    'qtyUnits',
  );
  @override
  late final GeneratedColumn<int> qtyUnits = GeneratedColumn<int>(
    'qty_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [id, receiptId, ticketId, qtyUnits];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('ticket_id')) {
      context.handle(
        _ticketIdMeta,
        ticketId.isAcceptableOrUnknown(data['ticket_id']!, _ticketIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ticketIdMeta);
    }
    if (data.containsKey('qty_units')) {
      context.handle(
        _qtyUnitsMeta,
        qtyUnits.isAcceptableOrUnknown(data['qty_units']!, _qtyUnitsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceiptLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptLine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      ticketId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_id'],
      )!,
      qtyUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_units'],
      )!,
    );
  }

  @override
  $ReceiptLinesTable createAlias(String alias) {
    return $ReceiptLinesTable(attachedDatabase, alias);
  }
}

class ReceiptLine extends DataClass implements Insertable<ReceiptLine> {
  final String id;
  final String receiptId;
  final String ticketId;
  final int qtyUnits;
  const ReceiptLine({
    required this.id,
    required this.receiptId,
    required this.ticketId,
    required this.qtyUnits,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['receipt_id'] = Variable<String>(receiptId);
    map['ticket_id'] = Variable<String>(ticketId);
    map['qty_units'] = Variable<int>(qtyUnits);
    return map;
  }

  ReceiptLinesCompanion toCompanion(bool nullToAbsent) {
    return ReceiptLinesCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      ticketId: Value(ticketId),
      qtyUnits: Value(qtyUnits),
    );
  }

  factory ReceiptLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptLine(
      id: serializer.fromJson<String>(json['id']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      ticketId: serializer.fromJson<String>(json['ticketId']),
      qtyUnits: serializer.fromJson<int>(json['qtyUnits']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'receiptId': serializer.toJson<String>(receiptId),
      'ticketId': serializer.toJson<String>(ticketId),
      'qtyUnits': serializer.toJson<int>(qtyUnits),
    };
  }

  ReceiptLine copyWith({
    String? id,
    String? receiptId,
    String? ticketId,
    int? qtyUnits,
  }) => ReceiptLine(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    ticketId: ticketId ?? this.ticketId,
    qtyUnits: qtyUnits ?? this.qtyUnits,
  );
  ReceiptLine copyWithCompanion(ReceiptLinesCompanion data) {
    return ReceiptLine(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      ticketId: data.ticketId.present ? data.ticketId.value : this.ticketId,
      qtyUnits: data.qtyUnits.present ? data.qtyUnits.value : this.qtyUnits,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptLine(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('ticketId: $ticketId, ')
          ..write('qtyUnits: $qtyUnits')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, receiptId, ticketId, qtyUnits);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptLine &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.ticketId == this.ticketId &&
          other.qtyUnits == this.qtyUnits);
}

class ReceiptLinesCompanion extends UpdateCompanion<ReceiptLine> {
  final Value<String> id;
  final Value<String> receiptId;
  final Value<String> ticketId;
  final Value<int> qtyUnits;
  final Value<int> rowid;
  const ReceiptLinesCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.ticketId = const Value.absent(),
    this.qtyUnits = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptLinesCompanion.insert({
    required String id,
    required String receiptId,
    required String ticketId,
    this.qtyUnits = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       receiptId = Value(receiptId),
       ticketId = Value(ticketId);
  static Insertable<ReceiptLine> custom({
    Expression<String>? id,
    Expression<String>? receiptId,
    Expression<String>? ticketId,
    Expression<int>? qtyUnits,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (ticketId != null) 'ticket_id': ticketId,
      if (qtyUnits != null) 'qty_units': qtyUnits,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? receiptId,
    Value<String>? ticketId,
    Value<int>? qtyUnits,
    Value<int>? rowid,
  }) {
    return ReceiptLinesCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      ticketId: ticketId ?? this.ticketId,
      qtyUnits: qtyUnits ?? this.qtyUnits,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (ticketId.present) {
      map['ticket_id'] = Variable<String>(ticketId.value);
    }
    if (qtyUnits.present) {
      map['qty_units'] = Variable<int>(qtyUnits.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptLinesCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('ticketId: $ticketId, ')
          ..write('qtyUnits: $qtyUnits, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRefundMeta = const VerificationMeta(
    'isRefund',
  );
  @override
  late final GeneratedColumn<bool> isRefund = GeneratedColumn<bool>(
    'is_refund',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_refund" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tenderedAmountMeta = const VerificationMeta(
    'tenderedAmount',
  );
  @override
  late final GeneratedColumn<int> tenderedAmount = GeneratedColumn<int>(
    'tendered_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashierUserIdMeta = const VerificationMeta(
    'cashierUserId',
  );
  @override
  late final GeneratedColumn<String> cashierUserId = GeneratedColumn<String>(
    'cashier_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<Uint8List> photo = GeneratedColumn<Uint8List>(
    'photo',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptId,
    method,
    amount,
    isRefund,
    tenderedAmount,
    cashierUserId,
    note,
    at,
    photo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Payment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('is_refund')) {
      context.handle(
        _isRefundMeta,
        isRefund.isAcceptableOrUnknown(data['is_refund']!, _isRefundMeta),
      );
    }
    if (data.containsKey('tendered_amount')) {
      context.handle(
        _tenderedAmountMeta,
        tenderedAmount.isAcceptableOrUnknown(
          data['tendered_amount']!,
          _tenderedAmountMeta,
        ),
      );
    }
    if (data.containsKey('cashier_user_id')) {
      context.handle(
        _cashierUserIdMeta,
        cashierUserId.isAcceptableOrUnknown(
          data['cashier_user_id']!,
          _cashierUserIdMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('photo')) {
      context.handle(
        _photoMeta,
        photo.isAcceptableOrUnknown(data['photo']!, _photoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      isRefund: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_refund'],
      )!,
      tenderedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tendered_amount'],
      ),
      cashierUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_user_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      photo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}photo'],
      ),
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class Payment extends DataClass implements Insertable<Payment> {
  final String id;
  final String receiptId;
  final String method;
  final int amount;
  final bool isRefund;
  final int? tenderedAmount;
  final String? cashierUserId;
  final String? note;
  final DateTime at;

  /// Mandatory proof photo (JPEG blob) for a non-cash payment — null for cash
  /// and pre-feature rows. Camera-shot at the till. Read ONLY by the photo
  /// route — never select in the bill/list path; use `selectOnly` excluding it.
  /// See docs/adr/0025-mandatory-non-cash-payment-proof-photo.md.
  final Uint8List? photo;
  const Payment({
    required this.id,
    required this.receiptId,
    required this.method,
    required this.amount,
    required this.isRefund,
    this.tenderedAmount,
    this.cashierUserId,
    this.note,
    required this.at,
    this.photo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['receipt_id'] = Variable<String>(receiptId);
    map['method'] = Variable<String>(method);
    map['amount'] = Variable<int>(amount);
    map['is_refund'] = Variable<bool>(isRefund);
    if (!nullToAbsent || tenderedAmount != null) {
      map['tendered_amount'] = Variable<int>(tenderedAmount);
    }
    if (!nullToAbsent || cashierUserId != null) {
      map['cashier_user_id'] = Variable<String>(cashierUserId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || photo != null) {
      map['photo'] = Variable<Uint8List>(photo);
    }
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      method: Value(method),
      amount: Value(amount),
      isRefund: Value(isRefund),
      tenderedAmount: tenderedAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(tenderedAmount),
      cashierUserId: cashierUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashierUserId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      at: Value(at),
      photo: photo == null && nullToAbsent
          ? const Value.absent()
          : Value(photo),
    );
  }

  factory Payment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<String>(json['id']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      method: serializer.fromJson<String>(json['method']),
      amount: serializer.fromJson<int>(json['amount']),
      isRefund: serializer.fromJson<bool>(json['isRefund']),
      tenderedAmount: serializer.fromJson<int?>(json['tenderedAmount']),
      cashierUserId: serializer.fromJson<String?>(json['cashierUserId']),
      note: serializer.fromJson<String?>(json['note']),
      at: serializer.fromJson<DateTime>(json['at']),
      photo: serializer.fromJson<Uint8List?>(json['photo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'receiptId': serializer.toJson<String>(receiptId),
      'method': serializer.toJson<String>(method),
      'amount': serializer.toJson<int>(amount),
      'isRefund': serializer.toJson<bool>(isRefund),
      'tenderedAmount': serializer.toJson<int?>(tenderedAmount),
      'cashierUserId': serializer.toJson<String?>(cashierUserId),
      'note': serializer.toJson<String?>(note),
      'at': serializer.toJson<DateTime>(at),
      'photo': serializer.toJson<Uint8List?>(photo),
    };
  }

  Payment copyWith({
    String? id,
    String? receiptId,
    String? method,
    int? amount,
    bool? isRefund,
    Value<int?> tenderedAmount = const Value.absent(),
    Value<String?> cashierUserId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? at,
    Value<Uint8List?> photo = const Value.absent(),
  }) => Payment(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    method: method ?? this.method,
    amount: amount ?? this.amount,
    isRefund: isRefund ?? this.isRefund,
    tenderedAmount: tenderedAmount.present
        ? tenderedAmount.value
        : this.tenderedAmount,
    cashierUserId: cashierUserId.present
        ? cashierUserId.value
        : this.cashierUserId,
    note: note.present ? note.value : this.note,
    at: at ?? this.at,
    photo: photo.present ? photo.value : this.photo,
  );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      method: data.method.present ? data.method.value : this.method,
      amount: data.amount.present ? data.amount.value : this.amount,
      isRefund: data.isRefund.present ? data.isRefund.value : this.isRefund,
      tenderedAmount: data.tenderedAmount.present
          ? data.tenderedAmount.value
          : this.tenderedAmount,
      cashierUserId: data.cashierUserId.present
          ? data.cashierUserId.value
          : this.cashierUserId,
      note: data.note.present ? data.note.value : this.note,
      at: data.at.present ? data.at.value : this.at,
      photo: data.photo.present ? data.photo.value : this.photo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('method: $method, ')
          ..write('amount: $amount, ')
          ..write('isRefund: $isRefund, ')
          ..write('tenderedAmount: $tenderedAmount, ')
          ..write('cashierUserId: $cashierUserId, ')
          ..write('note: $note, ')
          ..write('at: $at, ')
          ..write('photo: $photo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    receiptId,
    method,
    amount,
    isRefund,
    tenderedAmount,
    cashierUserId,
    note,
    at,
    $driftBlobEquality.hash(photo),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.method == this.method &&
          other.amount == this.amount &&
          other.isRefund == this.isRefund &&
          other.tenderedAmount == this.tenderedAmount &&
          other.cashierUserId == this.cashierUserId &&
          other.note == this.note &&
          other.at == this.at &&
          $driftBlobEquality.equals(other.photo, this.photo));
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<String> id;
  final Value<String> receiptId;
  final Value<String> method;
  final Value<int> amount;
  final Value<bool> isRefund;
  final Value<int?> tenderedAmount;
  final Value<String?> cashierUserId;
  final Value<String?> note;
  final Value<DateTime> at;
  final Value<Uint8List?> photo;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.method = const Value.absent(),
    this.amount = const Value.absent(),
    this.isRefund = const Value.absent(),
    this.tenderedAmount = const Value.absent(),
    this.cashierUserId = const Value.absent(),
    this.note = const Value.absent(),
    this.at = const Value.absent(),
    this.photo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    required String id,
    required String receiptId,
    required String method,
    required int amount,
    this.isRefund = const Value.absent(),
    this.tenderedAmount = const Value.absent(),
    this.cashierUserId = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime at,
    this.photo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       receiptId = Value(receiptId),
       method = Value(method),
       amount = Value(amount),
       at = Value(at);
  static Insertable<Payment> custom({
    Expression<String>? id,
    Expression<String>? receiptId,
    Expression<String>? method,
    Expression<int>? amount,
    Expression<bool>? isRefund,
    Expression<int>? tenderedAmount,
    Expression<String>? cashierUserId,
    Expression<String>? note,
    Expression<DateTime>? at,
    Expression<Uint8List>? photo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (method != null) 'method': method,
      if (amount != null) 'amount': amount,
      if (isRefund != null) 'is_refund': isRefund,
      if (tenderedAmount != null) 'tendered_amount': tenderedAmount,
      if (cashierUserId != null) 'cashier_user_id': cashierUserId,
      if (note != null) 'note': note,
      if (at != null) 'at': at,
      if (photo != null) 'photo': photo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? receiptId,
    Value<String>? method,
    Value<int>? amount,
    Value<bool>? isRefund,
    Value<int?>? tenderedAmount,
    Value<String?>? cashierUserId,
    Value<String?>? note,
    Value<DateTime>? at,
    Value<Uint8List?>? photo,
    Value<int>? rowid,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      isRefund: isRefund ?? this.isRefund,
      tenderedAmount: tenderedAmount ?? this.tenderedAmount,
      cashierUserId: cashierUserId ?? this.cashierUserId,
      note: note ?? this.note,
      at: at ?? this.at,
      photo: photo ?? this.photo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (isRefund.present) {
      map['is_refund'] = Variable<bool>(isRefund.value);
    }
    if (tenderedAmount.present) {
      map['tendered_amount'] = Variable<int>(tenderedAmount.value);
    }
    if (cashierUserId.present) {
      map['cashier_user_id'] = Variable<String>(cashierUserId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (photo.present) {
      map['photo'] = Variable<Uint8List>(photo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('method: $method, ')
          ..write('amount: $amount, ')
          ..write('isRefund: $isRefund, ')
          ..write('tenderedAmount: $tenderedAmount, ')
          ..write('cashierUserId: $cashierUserId, ')
          ..write('note: $note, ')
          ..write('at: $at, ')
          ..write('photo: $photo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TableSessionReceiptsTable extends TableSessionReceipts
    with TableInfo<$TableSessionReceiptsTable, TableSessionReceipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TableSessionReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('itemized'),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<int> subtotal = GeneratedColumn<int>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _serviceAmountMeta = const VerificationMeta(
    'serviceAmount',
  );
  @override
  late final GeneratedColumn<int> serviceAmount = GeneratedColumn<int>(
    'service_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<int> taxAmount = GeneratedColumn<int>(
    'tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unpaid'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    receiptId,
    mode,
    label,
    subtotal,
    serviceAmount,
    taxAmount,
    total,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'table_session_receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<TableSessionReceipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    }
    if (data.containsKey('service_amount')) {
      context.handle(
        _serviceAmountMeta,
        serviceAmount.isAcceptableOrUnknown(
          data['service_amount']!,
          _serviceAmountMeta,
        ),
      );
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TableSessionReceipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TableSessionReceipt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal'],
      )!,
      serviceAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_amount'],
      )!,
      taxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_amount'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $TableSessionReceiptsTable createAlias(String alias) {
    return $TableSessionReceiptsTable(attachedDatabase, alias);
  }
}

class TableSessionReceipt extends DataClass
    implements Insertable<TableSessionReceipt> {
  final String id;
  final String sessionId;
  final String receiptId;
  final String mode;
  final String label;
  final int subtotal;
  final int serviceAmount;
  final int taxAmount;
  final int total;
  final String status;
  const TableSessionReceipt({
    required this.id,
    required this.sessionId,
    required this.receiptId,
    required this.mode,
    required this.label,
    required this.subtotal,
    required this.serviceAmount,
    required this.taxAmount,
    required this.total,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['receipt_id'] = Variable<String>(receiptId);
    map['mode'] = Variable<String>(mode);
    map['label'] = Variable<String>(label);
    map['subtotal'] = Variable<int>(subtotal);
    map['service_amount'] = Variable<int>(serviceAmount);
    map['tax_amount'] = Variable<int>(taxAmount);
    map['total'] = Variable<int>(total);
    map['status'] = Variable<String>(status);
    return map;
  }

  TableSessionReceiptsCompanion toCompanion(bool nullToAbsent) {
    return TableSessionReceiptsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      receiptId: Value(receiptId),
      mode: Value(mode),
      label: Value(label),
      subtotal: Value(subtotal),
      serviceAmount: Value(serviceAmount),
      taxAmount: Value(taxAmount),
      total: Value(total),
      status: Value(status),
    );
  }

  factory TableSessionReceipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TableSessionReceipt(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      mode: serializer.fromJson<String>(json['mode']),
      label: serializer.fromJson<String>(json['label']),
      subtotal: serializer.fromJson<int>(json['subtotal']),
      serviceAmount: serializer.fromJson<int>(json['serviceAmount']),
      taxAmount: serializer.fromJson<int>(json['taxAmount']),
      total: serializer.fromJson<int>(json['total']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'receiptId': serializer.toJson<String>(receiptId),
      'mode': serializer.toJson<String>(mode),
      'label': serializer.toJson<String>(label),
      'subtotal': serializer.toJson<int>(subtotal),
      'serviceAmount': serializer.toJson<int>(serviceAmount),
      'taxAmount': serializer.toJson<int>(taxAmount),
      'total': serializer.toJson<int>(total),
      'status': serializer.toJson<String>(status),
    };
  }

  TableSessionReceipt copyWith({
    String? id,
    String? sessionId,
    String? receiptId,
    String? mode,
    String? label,
    int? subtotal,
    int? serviceAmount,
    int? taxAmount,
    int? total,
    String? status,
  }) => TableSessionReceipt(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    receiptId: receiptId ?? this.receiptId,
    mode: mode ?? this.mode,
    label: label ?? this.label,
    subtotal: subtotal ?? this.subtotal,
    serviceAmount: serviceAmount ?? this.serviceAmount,
    taxAmount: taxAmount ?? this.taxAmount,
    total: total ?? this.total,
    status: status ?? this.status,
  );
  TableSessionReceipt copyWithCompanion(TableSessionReceiptsCompanion data) {
    return TableSessionReceipt(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      mode: data.mode.present ? data.mode.value : this.mode,
      label: data.label.present ? data.label.value : this.label,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      serviceAmount: data.serviceAmount.present
          ? data.serviceAmount.value
          : this.serviceAmount,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      total: data.total.present ? data.total.value : this.total,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TableSessionReceipt(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('receiptId: $receiptId, ')
          ..write('mode: $mode, ')
          ..write('label: $label, ')
          ..write('subtotal: $subtotal, ')
          ..write('serviceAmount: $serviceAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('total: $total, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    receiptId,
    mode,
    label,
    subtotal,
    serviceAmount,
    taxAmount,
    total,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TableSessionReceipt &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.receiptId == this.receiptId &&
          other.mode == this.mode &&
          other.label == this.label &&
          other.subtotal == this.subtotal &&
          other.serviceAmount == this.serviceAmount &&
          other.taxAmount == this.taxAmount &&
          other.total == this.total &&
          other.status == this.status);
}

class TableSessionReceiptsCompanion
    extends UpdateCompanion<TableSessionReceipt> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> receiptId;
  final Value<String> mode;
  final Value<String> label;
  final Value<int> subtotal;
  final Value<int> serviceAmount;
  final Value<int> taxAmount;
  final Value<int> total;
  final Value<String> status;
  final Value<int> rowid;
  const TableSessionReceiptsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.mode = const Value.absent(),
    this.label = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.serviceAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.total = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TableSessionReceiptsCompanion.insert({
    required String id,
    required String sessionId,
    required String receiptId,
    this.mode = const Value.absent(),
    this.label = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.serviceAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.total = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       receiptId = Value(receiptId);
  static Insertable<TableSessionReceipt> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? receiptId,
    Expression<String>? mode,
    Expression<String>? label,
    Expression<int>? subtotal,
    Expression<int>? serviceAmount,
    Expression<int>? taxAmount,
    Expression<int>? total,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (receiptId != null) 'receipt_id': receiptId,
      if (mode != null) 'mode': mode,
      if (label != null) 'label': label,
      if (subtotal != null) 'subtotal': subtotal,
      if (serviceAmount != null) 'service_amount': serviceAmount,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (total != null) 'total': total,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TableSessionReceiptsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? receiptId,
    Value<String>? mode,
    Value<String>? label,
    Value<int>? subtotal,
    Value<int>? serviceAmount,
    Value<int>? taxAmount,
    Value<int>? total,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return TableSessionReceiptsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      receiptId: receiptId ?? this.receiptId,
      mode: mode ?? this.mode,
      label: label ?? this.label,
      subtotal: subtotal ?? this.subtotal,
      serviceAmount: serviceAmount ?? this.serviceAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<int>(subtotal.value);
    }
    if (serviceAmount.present) {
      map['service_amount'] = Variable<int>(serviceAmount.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<int>(taxAmount.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TableSessionReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('receiptId: $receiptId, ')
          ..write('mode: $mode, ')
          ..write('label: $label, ')
          ..write('subtotal: $subtotal, ')
          ..write('serviceAmount: $serviceAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('total: $total, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TableSessionPaymentsTable extends TableSessionPayments
    with TableInfo<$TableSessionPaymentsTable, TableSessionPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TableSessionPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRefundMeta = const VerificationMeta(
    'isRefund',
  );
  @override
  late final GeneratedColumn<bool> isRefund = GeneratedColumn<bool>(
    'is_refund',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_refund" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cashierUserIdMeta = const VerificationMeta(
    'cashierUserId',
  );
  @override
  late final GeneratedColumn<String> cashierUserId = GeneratedColumn<String>(
    'cashier_user_id',
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
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<Uint8List> photo = GeneratedColumn<Uint8List>(
    'photo',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    receiptId,
    method,
    amount,
    isRefund,
    cashierUserId,
    at,
    photo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'table_session_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<TableSessionPayment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('is_refund')) {
      context.handle(
        _isRefundMeta,
        isRefund.isAcceptableOrUnknown(data['is_refund']!, _isRefundMeta),
      );
    }
    if (data.containsKey('cashier_user_id')) {
      context.handle(
        _cashierUserIdMeta,
        cashierUserId.isAcceptableOrUnknown(
          data['cashier_user_id']!,
          _cashierUserIdMeta,
        ),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('photo')) {
      context.handle(
        _photoMeta,
        photo.isAcceptableOrUnknown(data['photo']!, _photoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TableSessionPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TableSessionPayment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      isRefund: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_refund'],
      )!,
      cashierUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_user_id'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      photo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}photo'],
      ),
    );
  }

  @override
  $TableSessionPaymentsTable createAlias(String alias) {
    return $TableSessionPaymentsTable(attachedDatabase, alias);
  }
}

class TableSessionPayment extends DataClass
    implements Insertable<TableSessionPayment> {
  final String id;
  final String sessionId;
  final String receiptId;
  final String method;
  final int amount;
  final bool isRefund;
  final String? cashierUserId;
  final DateTime at;

  /// Frozen copy of the live payment's proof photo (JPEG blob), carried across
  /// at bill close so immutable history is self-contained. Read ONLY by the
  /// photo route. See docs/adr/0025-mandatory-non-cash-payment-proof-photo.md.
  final Uint8List? photo;
  const TableSessionPayment({
    required this.id,
    required this.sessionId,
    required this.receiptId,
    required this.method,
    required this.amount,
    required this.isRefund,
    this.cashierUserId,
    required this.at,
    this.photo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['receipt_id'] = Variable<String>(receiptId);
    map['method'] = Variable<String>(method);
    map['amount'] = Variable<int>(amount);
    map['is_refund'] = Variable<bool>(isRefund);
    if (!nullToAbsent || cashierUserId != null) {
      map['cashier_user_id'] = Variable<String>(cashierUserId);
    }
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || photo != null) {
      map['photo'] = Variable<Uint8List>(photo);
    }
    return map;
  }

  TableSessionPaymentsCompanion toCompanion(bool nullToAbsent) {
    return TableSessionPaymentsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      receiptId: Value(receiptId),
      method: Value(method),
      amount: Value(amount),
      isRefund: Value(isRefund),
      cashierUserId: cashierUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashierUserId),
      at: Value(at),
      photo: photo == null && nullToAbsent
          ? const Value.absent()
          : Value(photo),
    );
  }

  factory TableSessionPayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TableSessionPayment(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      method: serializer.fromJson<String>(json['method']),
      amount: serializer.fromJson<int>(json['amount']),
      isRefund: serializer.fromJson<bool>(json['isRefund']),
      cashierUserId: serializer.fromJson<String?>(json['cashierUserId']),
      at: serializer.fromJson<DateTime>(json['at']),
      photo: serializer.fromJson<Uint8List?>(json['photo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'receiptId': serializer.toJson<String>(receiptId),
      'method': serializer.toJson<String>(method),
      'amount': serializer.toJson<int>(amount),
      'isRefund': serializer.toJson<bool>(isRefund),
      'cashierUserId': serializer.toJson<String?>(cashierUserId),
      'at': serializer.toJson<DateTime>(at),
      'photo': serializer.toJson<Uint8List?>(photo),
    };
  }

  TableSessionPayment copyWith({
    String? id,
    String? sessionId,
    String? receiptId,
    String? method,
    int? amount,
    bool? isRefund,
    Value<String?> cashierUserId = const Value.absent(),
    DateTime? at,
    Value<Uint8List?> photo = const Value.absent(),
  }) => TableSessionPayment(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    receiptId: receiptId ?? this.receiptId,
    method: method ?? this.method,
    amount: amount ?? this.amount,
    isRefund: isRefund ?? this.isRefund,
    cashierUserId: cashierUserId.present
        ? cashierUserId.value
        : this.cashierUserId,
    at: at ?? this.at,
    photo: photo.present ? photo.value : this.photo,
  );
  TableSessionPayment copyWithCompanion(TableSessionPaymentsCompanion data) {
    return TableSessionPayment(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      method: data.method.present ? data.method.value : this.method,
      amount: data.amount.present ? data.amount.value : this.amount,
      isRefund: data.isRefund.present ? data.isRefund.value : this.isRefund,
      cashierUserId: data.cashierUserId.present
          ? data.cashierUserId.value
          : this.cashierUserId,
      at: data.at.present ? data.at.value : this.at,
      photo: data.photo.present ? data.photo.value : this.photo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TableSessionPayment(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('receiptId: $receiptId, ')
          ..write('method: $method, ')
          ..write('amount: $amount, ')
          ..write('isRefund: $isRefund, ')
          ..write('cashierUserId: $cashierUserId, ')
          ..write('at: $at, ')
          ..write('photo: $photo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    receiptId,
    method,
    amount,
    isRefund,
    cashierUserId,
    at,
    $driftBlobEquality.hash(photo),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TableSessionPayment &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.receiptId == this.receiptId &&
          other.method == this.method &&
          other.amount == this.amount &&
          other.isRefund == this.isRefund &&
          other.cashierUserId == this.cashierUserId &&
          other.at == this.at &&
          $driftBlobEquality.equals(other.photo, this.photo));
}

class TableSessionPaymentsCompanion
    extends UpdateCompanion<TableSessionPayment> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> receiptId;
  final Value<String> method;
  final Value<int> amount;
  final Value<bool> isRefund;
  final Value<String?> cashierUserId;
  final Value<DateTime> at;
  final Value<Uint8List?> photo;
  final Value<int> rowid;
  const TableSessionPaymentsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.method = const Value.absent(),
    this.amount = const Value.absent(),
    this.isRefund = const Value.absent(),
    this.cashierUserId = const Value.absent(),
    this.at = const Value.absent(),
    this.photo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TableSessionPaymentsCompanion.insert({
    required String id,
    required String sessionId,
    required String receiptId,
    required String method,
    required int amount,
    this.isRefund = const Value.absent(),
    this.cashierUserId = const Value.absent(),
    required DateTime at,
    this.photo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       receiptId = Value(receiptId),
       method = Value(method),
       amount = Value(amount),
       at = Value(at);
  static Insertable<TableSessionPayment> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? receiptId,
    Expression<String>? method,
    Expression<int>? amount,
    Expression<bool>? isRefund,
    Expression<String>? cashierUserId,
    Expression<DateTime>? at,
    Expression<Uint8List>? photo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (receiptId != null) 'receipt_id': receiptId,
      if (method != null) 'method': method,
      if (amount != null) 'amount': amount,
      if (isRefund != null) 'is_refund': isRefund,
      if (cashierUserId != null) 'cashier_user_id': cashierUserId,
      if (at != null) 'at': at,
      if (photo != null) 'photo': photo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TableSessionPaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? receiptId,
    Value<String>? method,
    Value<int>? amount,
    Value<bool>? isRefund,
    Value<String?>? cashierUserId,
    Value<DateTime>? at,
    Value<Uint8List?>? photo,
    Value<int>? rowid,
  }) {
    return TableSessionPaymentsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      receiptId: receiptId ?? this.receiptId,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      isRefund: isRefund ?? this.isRefund,
      cashierUserId: cashierUserId ?? this.cashierUserId,
      at: at ?? this.at,
      photo: photo ?? this.photo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (isRefund.present) {
      map['is_refund'] = Variable<bool>(isRefund.value);
    }
    if (cashierUserId.present) {
      map['cashier_user_id'] = Variable<String>(cashierUserId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (photo.present) {
      map['photo'] = Variable<Uint8List>(photo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TableSessionPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('receiptId: $receiptId, ')
          ..write('method: $method, ')
          ..write('amount: $amount, ')
          ..write('isRefund: $isRefund, ')
          ..write('cashierUserId: $cashierUserId, ')
          ..write('at: $at, ')
          ..write('photo: $photo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyCountersTable extends DailyCounters
    with TableInfo<$DailyCountersTable, DailyCounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyCountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateStrMeta = const VerificationMeta(
    'dateStr',
  );
  @override
  late final GeneratedColumn<String> dateStr = GeneratedColumn<String>(
    'date_str',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _takeawayNextMeta = const VerificationMeta(
    'takeawayNext',
  );
  @override
  late final GeneratedColumn<int> takeawayNext = GeneratedColumn<int>(
    'takeaway_next',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [dateStr, takeawayNext];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_counters';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyCounter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_str')) {
      context.handle(
        _dateStrMeta,
        dateStr.isAcceptableOrUnknown(data['date_str']!, _dateStrMeta),
      );
    } else if (isInserting) {
      context.missing(_dateStrMeta);
    }
    if (data.containsKey('takeaway_next')) {
      context.handle(
        _takeawayNextMeta,
        takeawayNext.isAcceptableOrUnknown(
          data['takeaway_next']!,
          _takeawayNextMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateStr};
  @override
  DailyCounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyCounter(
      dateStr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_str'],
      )!,
      takeawayNext: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}takeaway_next'],
      )!,
    );
  }

  @override
  $DailyCountersTable createAlias(String alias) {
    return $DailyCountersTable(attachedDatabase, alias);
  }
}

class DailyCounter extends DataClass implements Insertable<DailyCounter> {
  final String dateStr;
  final int takeawayNext;
  const DailyCounter({required this.dateStr, required this.takeawayNext});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_str'] = Variable<String>(dateStr);
    map['takeaway_next'] = Variable<int>(takeawayNext);
    return map;
  }

  DailyCountersCompanion toCompanion(bool nullToAbsent) {
    return DailyCountersCompanion(
      dateStr: Value(dateStr),
      takeawayNext: Value(takeawayNext),
    );
  }

  factory DailyCounter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyCounter(
      dateStr: serializer.fromJson<String>(json['dateStr']),
      takeawayNext: serializer.fromJson<int>(json['takeawayNext']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateStr': serializer.toJson<String>(dateStr),
      'takeawayNext': serializer.toJson<int>(takeawayNext),
    };
  }

  DailyCounter copyWith({String? dateStr, int? takeawayNext}) => DailyCounter(
    dateStr: dateStr ?? this.dateStr,
    takeawayNext: takeawayNext ?? this.takeawayNext,
  );
  DailyCounter copyWithCompanion(DailyCountersCompanion data) {
    return DailyCounter(
      dateStr: data.dateStr.present ? data.dateStr.value : this.dateStr,
      takeawayNext: data.takeawayNext.present
          ? data.takeawayNext.value
          : this.takeawayNext,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyCounter(')
          ..write('dateStr: $dateStr, ')
          ..write('takeawayNext: $takeawayNext')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dateStr, takeawayNext);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyCounter &&
          other.dateStr == this.dateStr &&
          other.takeawayNext == this.takeawayNext);
}

class DailyCountersCompanion extends UpdateCompanion<DailyCounter> {
  final Value<String> dateStr;
  final Value<int> takeawayNext;
  final Value<int> rowid;
  const DailyCountersCompanion({
    this.dateStr = const Value.absent(),
    this.takeawayNext = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyCountersCompanion.insert({
    required String dateStr,
    this.takeawayNext = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : dateStr = Value(dateStr);
  static Insertable<DailyCounter> custom({
    Expression<String>? dateStr,
    Expression<int>? takeawayNext,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dateStr != null) 'date_str': dateStr,
      if (takeawayNext != null) 'takeaway_next': takeawayNext,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyCountersCompanion copyWith({
    Value<String>? dateStr,
    Value<int>? takeawayNext,
    Value<int>? rowid,
  }) {
    return DailyCountersCompanion(
      dateStr: dateStr ?? this.dateStr,
      takeawayNext: takeawayNext ?? this.takeawayNext,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateStr.present) {
      map['date_str'] = Variable<String>(dateStr.value);
    }
    if (takeawayNext.present) {
      map['takeaway_next'] = Variable<int>(takeawayNext.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyCountersCompanion(')
          ..write('dateStr: $dateStr, ')
          ..write('takeawayNext: $takeawayNext, ')
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
  late final $VisitsTable visits = $VisitsTable(this);
  late final $MenuCategoriesTable menuCategories = $MenuCategoriesTable(this);
  late final $MenuItemsTable menuItems = $MenuItemsTable(this);
  late final $MenuTagsTable menuTags = $MenuTagsTable(this);
  late final $TicketsTable tickets = $TicketsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $PairTokensTable pairTokens = $PairTokensTable(this);
  late final $IdempotencyTable idempotency = $IdempotencyTable(this);
  late final $AuditEntriesTable auditEntries = $AuditEntriesTable(this);
  late final $VenueSettingsTable venueSettings = $VenueSettingsTable(this);
  late final $PrintersTable printers = $PrintersTable(this);
  late final $TableSessionsTable tableSessions = $TableSessionsTable(this);
  late final $TableSessionTicketsTable tableSessionTickets =
      $TableSessionTicketsTable(this);
  late final $TableSessionCoursesTable tableSessionCourses =
      $TableSessionCoursesTable(this);
  late final $ReservationsTable reservations = $ReservationsTable(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $ReceiptLinesTable receiptLines = $ReceiptLinesTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $TableSessionReceiptsTable tableSessionReceipts =
      $TableSessionReceiptsTable(this);
  late final $TableSessionPaymentsTable tableSessionPayments =
      $TableSessionPaymentsTable(this);
  late final $DailyCountersTable dailyCounters = $DailyCountersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    roles,
    zones,
    venueTables,
    visits,
    menuCategories,
    menuItems,
    menuTags,
    tickets,
    sessions,
    devices,
    pairTokens,
    idempotency,
    auditEntries,
    venueSettings,
    printers,
    tableSessions,
    tableSessionTickets,
    tableSessionCourses,
    reservations,
    receipts,
    receiptLines,
    payments,
    tableSessionReceipts,
    tableSessionPayments,
    dailyCounters,
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
      Value<String?> email,
      Value<String?> passwordHash,
      Value<String?> firebaseUid,
      Value<bool> disabled,
      Value<int?> avatarColorHex,
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
      Value<String?> email,
      Value<String?> passwordHash,
      Value<String?> firebaseUid,
      Value<bool> disabled,
      Value<int?> avatarColorHex,
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

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firebaseUid => $composableBuilder(
    column: $table.firebaseUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get disabled => $composableBuilder(
    column: $table.disabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avatarColorHex => $composableBuilder(
    column: $table.avatarColorHex,
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

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firebaseUid => $composableBuilder(
    column: $table.firebaseUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get disabled => $composableBuilder(
    column: $table.disabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avatarColorHex => $composableBuilder(
    column: $table.avatarColorHex,
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

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firebaseUid => $composableBuilder(
    column: $table.firebaseUid,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get disabled =>
      $composableBuilder(column: $table.disabled, builder: (column) => column);

  GeneratedColumn<int> get avatarColorHex => $composableBuilder(
    column: $table.avatarColorHex,
    builder: (column) => column,
  );

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
                Value<String?> email = const Value.absent(),
                Value<String?> passwordHash = const Value.absent(),
                Value<String?> firebaseUid = const Value.absent(),
                Value<bool> disabled = const Value.absent(),
                Value<int?> avatarColorHex = const Value.absent(),
                Value<DateTime?> shiftStartedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                initials: initials,
                roleId: roleId,
                zoneAssigned: zoneAssigned,
                pinHash: pinHash,
                email: email,
                passwordHash: passwordHash,
                firebaseUid: firebaseUid,
                disabled: disabled,
                avatarColorHex: avatarColorHex,
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
                Value<String?> email = const Value.absent(),
                Value<String?> passwordHash = const Value.absent(),
                Value<String?> firebaseUid = const Value.absent(),
                Value<bool> disabled = const Value.absent(),
                Value<int?> avatarColorHex = const Value.absent(),
                Value<DateTime?> shiftStartedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                initials: initials,
                roleId: roleId,
                zoneAssigned: zoneAssigned,
                pinHash: pinHash,
                email: email,
                passwordHash: passwordHash,
                firebaseUid: firebaseUid,
                disabled: disabled,
                avatarColorHex: avatarColorHex,
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
      Value<int> capacity,
      Value<bool> active,
      Value<String> status,
      Value<int> openAmount,
      Value<int> readyCount,
      Value<String?> lastActorId,
      Value<String?> lockedBy,
      Value<String?> lockedByName,
      Value<DateTime?> lockedAt,
      Value<DateTime?> lockExpiresAt,
      Value<DateTime?> openedAt,
      Value<String?> guestName,
      Value<String?> guestNotes,
      Value<String?> reservationId,
      Value<String?> currentVisitId,
      Value<DateTime?> billClosedAt,
      Value<String?> moneyState,
      Value<bool> guestOrderingEnabled,
      Value<int> rowid,
    });
typedef $$VenueTablesTableUpdateCompanionBuilder =
    VenueTablesCompanion Function({
      Value<String> id,
      Value<String> zoneId,
      Value<String?> label,
      Value<int> pax,
      Value<int> capacity,
      Value<bool> active,
      Value<String> status,
      Value<int> openAmount,
      Value<int> readyCount,
      Value<String?> lastActorId,
      Value<String?> lockedBy,
      Value<String?> lockedByName,
      Value<DateTime?> lockedAt,
      Value<DateTime?> lockExpiresAt,
      Value<DateTime?> openedAt,
      Value<String?> guestName,
      Value<String?> guestNotes,
      Value<String?> reservationId,
      Value<String?> currentVisitId,
      Value<DateTime?> billClosedAt,
      Value<String?> moneyState,
      Value<bool> guestOrderingEnabled,
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

  ColumnFilters<int> get capacity => $composableBuilder(
    column: $table.capacity,
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

  ColumnFilters<String> get lockedBy => $composableBuilder(
    column: $table.lockedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lockedByName => $composableBuilder(
    column: $table.lockedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockExpiresAt => $composableBuilder(
    column: $table.lockExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guestName => $composableBuilder(
    column: $table.guestName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guestNotes => $composableBuilder(
    column: $table.guestNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reservationId => $composableBuilder(
    column: $table.reservationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentVisitId => $composableBuilder(
    column: $table.currentVisitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get billClosedAt => $composableBuilder(
    column: $table.billClosedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moneyState => $composableBuilder(
    column: $table.moneyState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get guestOrderingEnabled => $composableBuilder(
    column: $table.guestOrderingEnabled,
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

  ColumnOrderings<int> get capacity => $composableBuilder(
    column: $table.capacity,
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

  ColumnOrderings<String> get lockedBy => $composableBuilder(
    column: $table.lockedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lockedByName => $composableBuilder(
    column: $table.lockedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockExpiresAt => $composableBuilder(
    column: $table.lockExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guestName => $composableBuilder(
    column: $table.guestName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guestNotes => $composableBuilder(
    column: $table.guestNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reservationId => $composableBuilder(
    column: $table.reservationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentVisitId => $composableBuilder(
    column: $table.currentVisitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get billClosedAt => $composableBuilder(
    column: $table.billClosedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moneyState => $composableBuilder(
    column: $table.moneyState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get guestOrderingEnabled => $composableBuilder(
    column: $table.guestOrderingEnabled,
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

  GeneratedColumn<int> get capacity =>
      $composableBuilder(column: $table.capacity, builder: (column) => column);

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

  GeneratedColumn<String> get lockedBy =>
      $composableBuilder(column: $table.lockedBy, builder: (column) => column);

  GeneratedColumn<String> get lockedByName => $composableBuilder(
    column: $table.lockedByName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lockedAt =>
      $composableBuilder(column: $table.lockedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lockExpiresAt => $composableBuilder(
    column: $table.lockExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<String> get guestName =>
      $composableBuilder(column: $table.guestName, builder: (column) => column);

  GeneratedColumn<String> get guestNotes => $composableBuilder(
    column: $table.guestNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reservationId => $composableBuilder(
    column: $table.reservationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentVisitId => $composableBuilder(
    column: $table.currentVisitId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get billClosedAt => $composableBuilder(
    column: $table.billClosedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get moneyState => $composableBuilder(
    column: $table.moneyState,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get guestOrderingEnabled => $composableBuilder(
    column: $table.guestOrderingEnabled,
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
                Value<int> capacity = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> openAmount = const Value.absent(),
                Value<int> readyCount = const Value.absent(),
                Value<String?> lastActorId = const Value.absent(),
                Value<String?> lockedBy = const Value.absent(),
                Value<String?> lockedByName = const Value.absent(),
                Value<DateTime?> lockedAt = const Value.absent(),
                Value<DateTime?> lockExpiresAt = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
                Value<String?> guestName = const Value.absent(),
                Value<String?> guestNotes = const Value.absent(),
                Value<String?> reservationId = const Value.absent(),
                Value<String?> currentVisitId = const Value.absent(),
                Value<DateTime?> billClosedAt = const Value.absent(),
                Value<String?> moneyState = const Value.absent(),
                Value<bool> guestOrderingEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VenueTablesCompanion(
                id: id,
                zoneId: zoneId,
                label: label,
                pax: pax,
                capacity: capacity,
                active: active,
                status: status,
                openAmount: openAmount,
                readyCount: readyCount,
                lastActorId: lastActorId,
                lockedBy: lockedBy,
                lockedByName: lockedByName,
                lockedAt: lockedAt,
                lockExpiresAt: lockExpiresAt,
                openedAt: openedAt,
                guestName: guestName,
                guestNotes: guestNotes,
                reservationId: reservationId,
                currentVisitId: currentVisitId,
                billClosedAt: billClosedAt,
                moneyState: moneyState,
                guestOrderingEnabled: guestOrderingEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String zoneId,
                Value<String?> label = const Value.absent(),
                Value<int> pax = const Value.absent(),
                Value<int> capacity = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> openAmount = const Value.absent(),
                Value<int> readyCount = const Value.absent(),
                Value<String?> lastActorId = const Value.absent(),
                Value<String?> lockedBy = const Value.absent(),
                Value<String?> lockedByName = const Value.absent(),
                Value<DateTime?> lockedAt = const Value.absent(),
                Value<DateTime?> lockExpiresAt = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
                Value<String?> guestName = const Value.absent(),
                Value<String?> guestNotes = const Value.absent(),
                Value<String?> reservationId = const Value.absent(),
                Value<String?> currentVisitId = const Value.absent(),
                Value<DateTime?> billClosedAt = const Value.absent(),
                Value<String?> moneyState = const Value.absent(),
                Value<bool> guestOrderingEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VenueTablesCompanion.insert(
                id: id,
                zoneId: zoneId,
                label: label,
                pax: pax,
                capacity: capacity,
                active: active,
                status: status,
                openAmount: openAmount,
                readyCount: readyCount,
                lastActorId: lastActorId,
                lockedBy: lockedBy,
                lockedByName: lockedByName,
                lockedAt: lockedAt,
                lockExpiresAt: lockExpiresAt,
                openedAt: openedAt,
                guestName: guestName,
                guestNotes: guestNotes,
                reservationId: reservationId,
                currentVisitId: currentVisitId,
                billClosedAt: billClosedAt,
                moneyState: moneyState,
                guestOrderingEnabled: guestOrderingEnabled,
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
typedef $$VisitsTableCreateCompanionBuilder =
    VisitsCompanion Function({
      required String id,
      required String tableId,
      Value<String?> tableLabel,
      Value<String> zoneId,
      Value<int> pax,
      Value<DateTime?> openedAt,
      Value<String?> guestName,
      Value<String?> guestNotes,
      Value<String?> reservationId,
      Value<String?> lastActorId,
      Value<DateTime?> tableFreedAt,
      Value<DateTime?> billClosedAt,
      Value<String?> billClosedBy,
      Value<int> lossAmount,
      required DateTime createdAt,
      Value<String> kind,
      Value<int> rowid,
    });
typedef $$VisitsTableUpdateCompanionBuilder =
    VisitsCompanion Function({
      Value<String> id,
      Value<String> tableId,
      Value<String?> tableLabel,
      Value<String> zoneId,
      Value<int> pax,
      Value<DateTime?> openedAt,
      Value<String?> guestName,
      Value<String?> guestNotes,
      Value<String?> reservationId,
      Value<String?> lastActorId,
      Value<DateTime?> tableFreedAt,
      Value<DateTime?> billClosedAt,
      Value<String?> billClosedBy,
      Value<int> lossAmount,
      Value<DateTime> createdAt,
      Value<String> kind,
      Value<int> rowid,
    });

class $$VisitsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableFilterComposer({
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

  ColumnFilters<String> get tableLabel => $composableBuilder(
    column: $table.tableLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zoneId => $composableBuilder(
    column: $table.zoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pax => $composableBuilder(
    column: $table.pax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guestName => $composableBuilder(
    column: $table.guestName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guestNotes => $composableBuilder(
    column: $table.guestNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reservationId => $composableBuilder(
    column: $table.reservationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastActorId => $composableBuilder(
    column: $table.lastActorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get tableFreedAt => $composableBuilder(
    column: $table.tableFreedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get billClosedAt => $composableBuilder(
    column: $table.billClosedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billClosedBy => $composableBuilder(
    column: $table.billClosedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lossAmount => $composableBuilder(
    column: $table.lossAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableOrderingComposer({
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

  ColumnOrderings<String> get tableLabel => $composableBuilder(
    column: $table.tableLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneId => $composableBuilder(
    column: $table.zoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pax => $composableBuilder(
    column: $table.pax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guestName => $composableBuilder(
    column: $table.guestName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guestNotes => $composableBuilder(
    column: $table.guestNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reservationId => $composableBuilder(
    column: $table.reservationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastActorId => $composableBuilder(
    column: $table.lastActorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get tableFreedAt => $composableBuilder(
    column: $table.tableFreedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get billClosedAt => $composableBuilder(
    column: $table.billClosedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billClosedBy => $composableBuilder(
    column: $table.billClosedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lossAmount => $composableBuilder(
    column: $table.lossAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableAnnotationComposer({
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

  GeneratedColumn<String> get tableLabel => $composableBuilder(
    column: $table.tableLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zoneId =>
      $composableBuilder(column: $table.zoneId, builder: (column) => column);

  GeneratedColumn<int> get pax =>
      $composableBuilder(column: $table.pax, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<String> get guestName =>
      $composableBuilder(column: $table.guestName, builder: (column) => column);

  GeneratedColumn<String> get guestNotes => $composableBuilder(
    column: $table.guestNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reservationId => $composableBuilder(
    column: $table.reservationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastActorId => $composableBuilder(
    column: $table.lastActorId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get tableFreedAt => $composableBuilder(
    column: $table.tableFreedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get billClosedAt => $composableBuilder(
    column: $table.billClosedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get billClosedBy => $composableBuilder(
    column: $table.billClosedBy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lossAmount => $composableBuilder(
    column: $table.lossAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);
}

class $$VisitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitsTable,
          Visit,
          $$VisitsTableFilterComposer,
          $$VisitsTableOrderingComposer,
          $$VisitsTableAnnotationComposer,
          $$VisitsTableCreateCompanionBuilder,
          $$VisitsTableUpdateCompanionBuilder,
          (Visit, BaseReferences<_$AppDatabase, $VisitsTable, Visit>),
          Visit,
          PrefetchHooks Function()
        > {
  $$VisitsTableTableManager(_$AppDatabase db, $VisitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tableId = const Value.absent(),
                Value<String?> tableLabel = const Value.absent(),
                Value<String> zoneId = const Value.absent(),
                Value<int> pax = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
                Value<String?> guestName = const Value.absent(),
                Value<String?> guestNotes = const Value.absent(),
                Value<String?> reservationId = const Value.absent(),
                Value<String?> lastActorId = const Value.absent(),
                Value<DateTime?> tableFreedAt = const Value.absent(),
                Value<DateTime?> billClosedAt = const Value.absent(),
                Value<String?> billClosedBy = const Value.absent(),
                Value<int> lossAmount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitsCompanion(
                id: id,
                tableId: tableId,
                tableLabel: tableLabel,
                zoneId: zoneId,
                pax: pax,
                openedAt: openedAt,
                guestName: guestName,
                guestNotes: guestNotes,
                reservationId: reservationId,
                lastActorId: lastActorId,
                tableFreedAt: tableFreedAt,
                billClosedAt: billClosedAt,
                billClosedBy: billClosedBy,
                lossAmount: lossAmount,
                createdAt: createdAt,
                kind: kind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tableId,
                Value<String?> tableLabel = const Value.absent(),
                Value<String> zoneId = const Value.absent(),
                Value<int> pax = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
                Value<String?> guestName = const Value.absent(),
                Value<String?> guestNotes = const Value.absent(),
                Value<String?> reservationId = const Value.absent(),
                Value<String?> lastActorId = const Value.absent(),
                Value<DateTime?> tableFreedAt = const Value.absent(),
                Value<DateTime?> billClosedAt = const Value.absent(),
                Value<String?> billClosedBy = const Value.absent(),
                Value<int> lossAmount = const Value.absent(),
                required DateTime createdAt,
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitsCompanion.insert(
                id: id,
                tableId: tableId,
                tableLabel: tableLabel,
                zoneId: zoneId,
                pax: pax,
                openedAt: openedAt,
                guestName: guestName,
                guestNotes: guestNotes,
                reservationId: reservationId,
                lastActorId: lastActorId,
                tableFreedAt: tableFreedAt,
                billClosedAt: billClosedAt,
                billClosedBy: billClosedBy,
                lossAmount: lossAmount,
                createdAt: createdAt,
                kind: kind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VisitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitsTable,
      Visit,
      $$VisitsTableFilterComposer,
      $$VisitsTableOrderingComposer,
      $$VisitsTableAnnotationComposer,
      $$VisitsTableCreateCompanionBuilder,
      $$VisitsTableUpdateCompanionBuilder,
      (Visit, BaseReferences<_$AppDatabase, $VisitsTable, Visit>),
      Visit,
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
      Value<String> description,
      required int basePrice,
      Value<int> cost,
      Value<int> prepTime,
      Value<String> variantsJson,
      Value<String> modifierGroupsJson,
      Value<String> allergensJson,
      Value<String> dietaryJson,
      Value<bool> unavailable,
      Value<int?> stockCount,
      Value<bool> autoSoldOutAtZero,
      Value<Uint8List?> photo,
      Value<int> photoRev,
      Value<int> rowid,
    });
typedef $$MenuItemsTableUpdateCompanionBuilder =
    MenuItemsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> categoryId,
      Value<String> description,
      Value<int> basePrice,
      Value<int> cost,
      Value<int> prepTime,
      Value<String> variantsJson,
      Value<String> modifierGroupsJson,
      Value<String> allergensJson,
      Value<String> dietaryJson,
      Value<bool> unavailable,
      Value<int?> stockCount,
      Value<bool> autoSoldOutAtZero,
      Value<Uint8List?> photo,
      Value<int> photoRev,
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get basePrice => $composableBuilder(
    column: $table.basePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cost => $composableBuilder(
    column: $table.cost,
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

  ColumnFilters<String> get modifierGroupsJson => $composableBuilder(
    column: $table.modifierGroupsJson,
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

  ColumnFilters<bool> get autoSoldOutAtZero => $composableBuilder(
    column: $table.autoSoldOutAtZero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get photoRev => $composableBuilder(
    column: $table.photoRev,
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get basePrice => $composableBuilder(
    column: $table.basePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cost => $composableBuilder(
    column: $table.cost,
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

  ColumnOrderings<String> get modifierGroupsJson => $composableBuilder(
    column: $table.modifierGroupsJson,
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

  ColumnOrderings<bool> get autoSoldOutAtZero => $composableBuilder(
    column: $table.autoSoldOutAtZero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get photoRev => $composableBuilder(
    column: $table.photoRev,
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get basePrice =>
      $composableBuilder(column: $table.basePrice, builder: (column) => column);

  GeneratedColumn<int> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<int> get prepTime =>
      $composableBuilder(column: $table.prepTime, builder: (column) => column);

  GeneratedColumn<String> get variantsJson => $composableBuilder(
    column: $table.variantsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifierGroupsJson => $composableBuilder(
    column: $table.modifierGroupsJson,
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

  GeneratedColumn<bool> get autoSoldOutAtZero => $composableBuilder(
    column: $table.autoSoldOutAtZero,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get photo =>
      $composableBuilder(column: $table.photo, builder: (column) => column);

  GeneratedColumn<int> get photoRev =>
      $composableBuilder(column: $table.photoRev, builder: (column) => column);
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
                Value<String> description = const Value.absent(),
                Value<int> basePrice = const Value.absent(),
                Value<int> cost = const Value.absent(),
                Value<int> prepTime = const Value.absent(),
                Value<String> variantsJson = const Value.absent(),
                Value<String> modifierGroupsJson = const Value.absent(),
                Value<String> allergensJson = const Value.absent(),
                Value<String> dietaryJson = const Value.absent(),
                Value<bool> unavailable = const Value.absent(),
                Value<int?> stockCount = const Value.absent(),
                Value<bool> autoSoldOutAtZero = const Value.absent(),
                Value<Uint8List?> photo = const Value.absent(),
                Value<int> photoRev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuItemsCompanion(
                id: id,
                name: name,
                categoryId: categoryId,
                description: description,
                basePrice: basePrice,
                cost: cost,
                prepTime: prepTime,
                variantsJson: variantsJson,
                modifierGroupsJson: modifierGroupsJson,
                allergensJson: allergensJson,
                dietaryJson: dietaryJson,
                unavailable: unavailable,
                stockCount: stockCount,
                autoSoldOutAtZero: autoSoldOutAtZero,
                photo: photo,
                photoRev: photoRev,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String categoryId,
                Value<String> description = const Value.absent(),
                required int basePrice,
                Value<int> cost = const Value.absent(),
                Value<int> prepTime = const Value.absent(),
                Value<String> variantsJson = const Value.absent(),
                Value<String> modifierGroupsJson = const Value.absent(),
                Value<String> allergensJson = const Value.absent(),
                Value<String> dietaryJson = const Value.absent(),
                Value<bool> unavailable = const Value.absent(),
                Value<int?> stockCount = const Value.absent(),
                Value<bool> autoSoldOutAtZero = const Value.absent(),
                Value<Uint8List?> photo = const Value.absent(),
                Value<int> photoRev = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuItemsCompanion.insert(
                id: id,
                name: name,
                categoryId: categoryId,
                description: description,
                basePrice: basePrice,
                cost: cost,
                prepTime: prepTime,
                variantsJson: variantsJson,
                modifierGroupsJson: modifierGroupsJson,
                allergensJson: allergensJson,
                dietaryJson: dietaryJson,
                unavailable: unavailable,
                stockCount: stockCount,
                autoSoldOutAtZero: autoSoldOutAtZero,
                photo: photo,
                photoRev: photoRev,
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
typedef $$MenuTagsTableCreateCompanionBuilder =
    MenuTagsCompanion Function({
      required String id,
      required String kind,
      required String name,
      Value<String> code,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$MenuTagsTableUpdateCompanionBuilder =
    MenuTagsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> name,
      Value<String> code,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$MenuTagsTableFilterComposer
    extends Composer<_$AppDatabase, $MenuTagsTable> {
  $$MenuTagsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MenuTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuTagsTable> {
  $$MenuTagsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MenuTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuTagsTable> {
  $$MenuTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$MenuTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuTagsTable,
          MenuTag,
          $$MenuTagsTableFilterComposer,
          $$MenuTagsTableOrderingComposer,
          $$MenuTagsTableAnnotationComposer,
          $$MenuTagsTableCreateCompanionBuilder,
          $$MenuTagsTableUpdateCompanionBuilder,
          (MenuTag, BaseReferences<_$AppDatabase, $MenuTagsTable, MenuTag>),
          MenuTag,
          PrefetchHooks Function()
        > {
  $$MenuTagsTableTableManager(_$AppDatabase db, $MenuTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenuTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuTagsCompanion(
                id: id,
                kind: kind,
                name: name,
                code: code,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String name,
                Value<String> code = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuTagsCompanion.insert(
                id: id,
                kind: kind,
                name: name,
                code: code,
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

typedef $$MenuTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuTagsTable,
      MenuTag,
      $$MenuTagsTableFilterComposer,
      $$MenuTagsTableOrderingComposer,
      $$MenuTagsTableAnnotationComposer,
      $$MenuTagsTableCreateCompanionBuilder,
      $$MenuTagsTableUpdateCompanionBuilder,
      (MenuTag, BaseReferences<_$AppDatabase, $MenuTagsTable, MenuTag>),
      MenuTag,
      PrefetchHooks Function()
    >;
typedef $$TicketsTableCreateCompanionBuilder =
    TicketsCompanion Function({
      required String id,
      required String tableId,
      Value<String?> visitId,
      required String itemId,
      required String name,
      Value<String> variantName,
      required String course,
      Value<int> qty,
      Value<String> modifiersJson,
      Value<String?> note,
      required int price,
      required String status,
      required DateTime sentAt,
      Value<DateTime?> readyAt,
      Value<DateTime?> servedAt,
      Value<String?> voidReason,
      Value<String?> voidReasonCode,
      Value<String?> voidApprovedBy,
      Value<String?> createdByUserId,
      Value<String?> voidedByUserId,
      Value<int> rowid,
    });
typedef $$TicketsTableUpdateCompanionBuilder =
    TicketsCompanion Function({
      Value<String> id,
      Value<String> tableId,
      Value<String?> visitId,
      Value<String> itemId,
      Value<String> name,
      Value<String> variantName,
      Value<String> course,
      Value<int> qty,
      Value<String> modifiersJson,
      Value<String?> note,
      Value<int> price,
      Value<String> status,
      Value<DateTime> sentAt,
      Value<DateTime?> readyAt,
      Value<DateTime?> servedAt,
      Value<String?> voidReason,
      Value<String?> voidReasonCode,
      Value<String?> voidApprovedBy,
      Value<String?> createdByUserId,
      Value<String?> voidedByUserId,
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

  ColumnFilters<String> get visitId => $composableBuilder(
    column: $table.visitId,
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

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiersJson => $composableBuilder(
    column: $table.modifiersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
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

  ColumnFilters<DateTime> get readyAt => $composableBuilder(
    column: $table.readyAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get servedAt => $composableBuilder(
    column: $table.servedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidReasonCode => $composableBuilder(
    column: $table.voidReasonCode,
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

  ColumnFilters<String> get voidedByUserId => $composableBuilder(
    column: $table.voidedByUserId,
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

  ColumnOrderings<String> get visitId => $composableBuilder(
    column: $table.visitId,
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

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiersJson => $composableBuilder(
    column: $table.modifiersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
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

  ColumnOrderings<DateTime> get readyAt => $composableBuilder(
    column: $table.readyAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get servedAt => $composableBuilder(
    column: $table.servedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidReasonCode => $composableBuilder(
    column: $table.voidReasonCode,
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

  ColumnOrderings<String> get voidedByUserId => $composableBuilder(
    column: $table.voidedByUserId,
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

  GeneratedColumn<String> get visitId =>
      $composableBuilder(column: $table.visitId, builder: (column) => column);

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

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get modifiersJson => $composableBuilder(
    column: $table.modifiersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get readyAt =>
      $composableBuilder(column: $table.readyAt, builder: (column) => column);

  GeneratedColumn<DateTime> get servedAt =>
      $composableBuilder(column: $table.servedAt, builder: (column) => column);

  GeneratedColumn<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voidReasonCode => $composableBuilder(
    column: $table.voidReasonCode,
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

  GeneratedColumn<String> get voidedByUserId => $composableBuilder(
    column: $table.voidedByUserId,
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
                Value<String?> visitId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> variantName = const Value.absent(),
                Value<String> course = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<String> modifiersJson = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> price = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
                Value<DateTime?> readyAt = const Value.absent(),
                Value<DateTime?> servedAt = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<String?> voidReasonCode = const Value.absent(),
                Value<String?> voidApprovedBy = const Value.absent(),
                Value<String?> createdByUserId = const Value.absent(),
                Value<String?> voidedByUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TicketsCompanion(
                id: id,
                tableId: tableId,
                visitId: visitId,
                itemId: itemId,
                name: name,
                variantName: variantName,
                course: course,
                qty: qty,
                modifiersJson: modifiersJson,
                note: note,
                price: price,
                status: status,
                sentAt: sentAt,
                readyAt: readyAt,
                servedAt: servedAt,
                voidReason: voidReason,
                voidReasonCode: voidReasonCode,
                voidApprovedBy: voidApprovedBy,
                createdByUserId: createdByUserId,
                voidedByUserId: voidedByUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tableId,
                Value<String?> visitId = const Value.absent(),
                required String itemId,
                required String name,
                Value<String> variantName = const Value.absent(),
                required String course,
                Value<int> qty = const Value.absent(),
                Value<String> modifiersJson = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int price,
                required String status,
                required DateTime sentAt,
                Value<DateTime?> readyAt = const Value.absent(),
                Value<DateTime?> servedAt = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<String?> voidReasonCode = const Value.absent(),
                Value<String?> voidApprovedBy = const Value.absent(),
                Value<String?> createdByUserId = const Value.absent(),
                Value<String?> voidedByUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TicketsCompanion.insert(
                id: id,
                tableId: tableId,
                visitId: visitId,
                itemId: itemId,
                name: name,
                variantName: variantName,
                course: course,
                qty: qty,
                modifiersJson: modifiersJson,
                note: note,
                price: price,
                status: status,
                sentAt: sentAt,
                readyAt: readyAt,
                servedAt: servedAt,
                voidReason: voidReason,
                voidReasonCode: voidReasonCode,
                voidApprovedBy: voidApprovedBy,
                createdByUserId: createdByUserId,
                voidedByUserId: voidedByUserId,
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
typedef $$VenueSettingsTableCreateCompanionBuilder =
    VenueSettingsCompanion Function({
      required String id,
      Value<String> displayName,
      Value<String> legalName,
      Value<String> address,
      Value<String> phone,
      Value<String> receiptHeader,
      Value<String> receiptFooter,
      Value<String> receiptTagline,
      Value<String> receiptSocial,
      Value<String> receiptThankYou,
      Value<String> receiptQrUrl,
      Value<String> receiptQrCaption,
      Value<Uint8List?> logo,
      Value<int> logoRev,
      Value<bool> taxEnabled,
      Value<int> taxRateBps,
      Value<bool> serviceEnabled,
      Value<String> serviceMode,
      Value<int> serviceRateBps,
      Value<int> serviceFixedAmount,
      Value<int> businessDayStartHour,
      Value<int> prepTargetMins,
      Value<bool> guestOrderingEnabled,
      Value<String> soundNewOrder,
      Value<String> soundReady,
      Value<String> soundVoid,
      Value<String> soundOverdue,
      Value<int> rowid,
    });
typedef $$VenueSettingsTableUpdateCompanionBuilder =
    VenueSettingsCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> legalName,
      Value<String> address,
      Value<String> phone,
      Value<String> receiptHeader,
      Value<String> receiptFooter,
      Value<String> receiptTagline,
      Value<String> receiptSocial,
      Value<String> receiptThankYou,
      Value<String> receiptQrUrl,
      Value<String> receiptQrCaption,
      Value<Uint8List?> logo,
      Value<int> logoRev,
      Value<bool> taxEnabled,
      Value<int> taxRateBps,
      Value<bool> serviceEnabled,
      Value<String> serviceMode,
      Value<int> serviceRateBps,
      Value<int> serviceFixedAmount,
      Value<int> businessDayStartHour,
      Value<int> prepTargetMins,
      Value<bool> guestOrderingEnabled,
      Value<String> soundNewOrder,
      Value<String> soundReady,
      Value<String> soundVoid,
      Value<String> soundOverdue,
      Value<int> rowid,
    });

class $$VenueSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $VenueSettingsTable> {
  $$VenueSettingsTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legalName => $composableBuilder(
    column: $table.legalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptHeader => $composableBuilder(
    column: $table.receiptHeader,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptFooter => $composableBuilder(
    column: $table.receiptFooter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptTagline => $composableBuilder(
    column: $table.receiptTagline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptSocial => $composableBuilder(
    column: $table.receiptSocial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptThankYou => $composableBuilder(
    column: $table.receiptThankYou,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptQrUrl => $composableBuilder(
    column: $table.receiptQrUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptQrCaption => $composableBuilder(
    column: $table.receiptQrCaption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get logoRev => $composableBuilder(
    column: $table.logoRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get taxEnabled => $composableBuilder(
    column: $table.taxEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxRateBps => $composableBuilder(
    column: $table.taxRateBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get serviceEnabled => $composableBuilder(
    column: $table.serviceEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceMode => $composableBuilder(
    column: $table.serviceMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceRateBps => $composableBuilder(
    column: $table.serviceRateBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceFixedAmount => $composableBuilder(
    column: $table.serviceFixedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get businessDayStartHour => $composableBuilder(
    column: $table.businessDayStartHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prepTargetMins => $composableBuilder(
    column: $table.prepTargetMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get guestOrderingEnabled => $composableBuilder(
    column: $table.guestOrderingEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundNewOrder => $composableBuilder(
    column: $table.soundNewOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundReady => $composableBuilder(
    column: $table.soundReady,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundVoid => $composableBuilder(
    column: $table.soundVoid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundOverdue => $composableBuilder(
    column: $table.soundOverdue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VenueSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $VenueSettingsTable> {
  $$VenueSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legalName => $composableBuilder(
    column: $table.legalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptHeader => $composableBuilder(
    column: $table.receiptHeader,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptFooter => $composableBuilder(
    column: $table.receiptFooter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptTagline => $composableBuilder(
    column: $table.receiptTagline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptSocial => $composableBuilder(
    column: $table.receiptSocial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptThankYou => $composableBuilder(
    column: $table.receiptThankYou,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptQrUrl => $composableBuilder(
    column: $table.receiptQrUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptQrCaption => $composableBuilder(
    column: $table.receiptQrCaption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get logoRev => $composableBuilder(
    column: $table.logoRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get taxEnabled => $composableBuilder(
    column: $table.taxEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxRateBps => $composableBuilder(
    column: $table.taxRateBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get serviceEnabled => $composableBuilder(
    column: $table.serviceEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceMode => $composableBuilder(
    column: $table.serviceMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceRateBps => $composableBuilder(
    column: $table.serviceRateBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceFixedAmount => $composableBuilder(
    column: $table.serviceFixedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get businessDayStartHour => $composableBuilder(
    column: $table.businessDayStartHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prepTargetMins => $composableBuilder(
    column: $table.prepTargetMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get guestOrderingEnabled => $composableBuilder(
    column: $table.guestOrderingEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundNewOrder => $composableBuilder(
    column: $table.soundNewOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundReady => $composableBuilder(
    column: $table.soundReady,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundVoid => $composableBuilder(
    column: $table.soundVoid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundOverdue => $composableBuilder(
    column: $table.soundOverdue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VenueSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VenueSettingsTable> {
  $$VenueSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get legalName =>
      $composableBuilder(column: $table.legalName, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get receiptHeader => $composableBuilder(
    column: $table.receiptHeader,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptFooter => $composableBuilder(
    column: $table.receiptFooter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptTagline => $composableBuilder(
    column: $table.receiptTagline,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptSocial => $composableBuilder(
    column: $table.receiptSocial,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptThankYou => $composableBuilder(
    column: $table.receiptThankYou,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptQrUrl => $composableBuilder(
    column: $table.receiptQrUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptQrCaption => $composableBuilder(
    column: $table.receiptQrCaption,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get logo =>
      $composableBuilder(column: $table.logo, builder: (column) => column);

  GeneratedColumn<int> get logoRev =>
      $composableBuilder(column: $table.logoRev, builder: (column) => column);

  GeneratedColumn<bool> get taxEnabled => $composableBuilder(
    column: $table.taxEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxRateBps => $composableBuilder(
    column: $table.taxRateBps,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get serviceEnabled => $composableBuilder(
    column: $table.serviceEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serviceMode => $composableBuilder(
    column: $table.serviceMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serviceRateBps => $composableBuilder(
    column: $table.serviceRateBps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serviceFixedAmount => $composableBuilder(
    column: $table.serviceFixedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get businessDayStartHour => $composableBuilder(
    column: $table.businessDayStartHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prepTargetMins => $composableBuilder(
    column: $table.prepTargetMins,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get guestOrderingEnabled => $composableBuilder(
    column: $table.guestOrderingEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundNewOrder => $composableBuilder(
    column: $table.soundNewOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundReady => $composableBuilder(
    column: $table.soundReady,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundVoid =>
      $composableBuilder(column: $table.soundVoid, builder: (column) => column);

  GeneratedColumn<String> get soundOverdue => $composableBuilder(
    column: $table.soundOverdue,
    builder: (column) => column,
  );
}

class $$VenueSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VenueSettingsTable,
          VenueSetting,
          $$VenueSettingsTableFilterComposer,
          $$VenueSettingsTableOrderingComposer,
          $$VenueSettingsTableAnnotationComposer,
          $$VenueSettingsTableCreateCompanionBuilder,
          $$VenueSettingsTableUpdateCompanionBuilder,
          (
            VenueSetting,
            BaseReferences<_$AppDatabase, $VenueSettingsTable, VenueSetting>,
          ),
          VenueSetting,
          PrefetchHooks Function()
        > {
  $$VenueSettingsTableTableManager(_$AppDatabase db, $VenueSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VenueSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VenueSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VenueSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> legalName = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> receiptHeader = const Value.absent(),
                Value<String> receiptFooter = const Value.absent(),
                Value<String> receiptTagline = const Value.absent(),
                Value<String> receiptSocial = const Value.absent(),
                Value<String> receiptThankYou = const Value.absent(),
                Value<String> receiptQrUrl = const Value.absent(),
                Value<String> receiptQrCaption = const Value.absent(),
                Value<Uint8List?> logo = const Value.absent(),
                Value<int> logoRev = const Value.absent(),
                Value<bool> taxEnabled = const Value.absent(),
                Value<int> taxRateBps = const Value.absent(),
                Value<bool> serviceEnabled = const Value.absent(),
                Value<String> serviceMode = const Value.absent(),
                Value<int> serviceRateBps = const Value.absent(),
                Value<int> serviceFixedAmount = const Value.absent(),
                Value<int> businessDayStartHour = const Value.absent(),
                Value<int> prepTargetMins = const Value.absent(),
                Value<bool> guestOrderingEnabled = const Value.absent(),
                Value<String> soundNewOrder = const Value.absent(),
                Value<String> soundReady = const Value.absent(),
                Value<String> soundVoid = const Value.absent(),
                Value<String> soundOverdue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VenueSettingsCompanion(
                id: id,
                displayName: displayName,
                legalName: legalName,
                address: address,
                phone: phone,
                receiptHeader: receiptHeader,
                receiptFooter: receiptFooter,
                receiptTagline: receiptTagline,
                receiptSocial: receiptSocial,
                receiptThankYou: receiptThankYou,
                receiptQrUrl: receiptQrUrl,
                receiptQrCaption: receiptQrCaption,
                logo: logo,
                logoRev: logoRev,
                taxEnabled: taxEnabled,
                taxRateBps: taxRateBps,
                serviceEnabled: serviceEnabled,
                serviceMode: serviceMode,
                serviceRateBps: serviceRateBps,
                serviceFixedAmount: serviceFixedAmount,
                businessDayStartHour: businessDayStartHour,
                prepTargetMins: prepTargetMins,
                guestOrderingEnabled: guestOrderingEnabled,
                soundNewOrder: soundNewOrder,
                soundReady: soundReady,
                soundVoid: soundVoid,
                soundOverdue: soundOverdue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> displayName = const Value.absent(),
                Value<String> legalName = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> receiptHeader = const Value.absent(),
                Value<String> receiptFooter = const Value.absent(),
                Value<String> receiptTagline = const Value.absent(),
                Value<String> receiptSocial = const Value.absent(),
                Value<String> receiptThankYou = const Value.absent(),
                Value<String> receiptQrUrl = const Value.absent(),
                Value<String> receiptQrCaption = const Value.absent(),
                Value<Uint8List?> logo = const Value.absent(),
                Value<int> logoRev = const Value.absent(),
                Value<bool> taxEnabled = const Value.absent(),
                Value<int> taxRateBps = const Value.absent(),
                Value<bool> serviceEnabled = const Value.absent(),
                Value<String> serviceMode = const Value.absent(),
                Value<int> serviceRateBps = const Value.absent(),
                Value<int> serviceFixedAmount = const Value.absent(),
                Value<int> businessDayStartHour = const Value.absent(),
                Value<int> prepTargetMins = const Value.absent(),
                Value<bool> guestOrderingEnabled = const Value.absent(),
                Value<String> soundNewOrder = const Value.absent(),
                Value<String> soundReady = const Value.absent(),
                Value<String> soundVoid = const Value.absent(),
                Value<String> soundOverdue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VenueSettingsCompanion.insert(
                id: id,
                displayName: displayName,
                legalName: legalName,
                address: address,
                phone: phone,
                receiptHeader: receiptHeader,
                receiptFooter: receiptFooter,
                receiptTagline: receiptTagline,
                receiptSocial: receiptSocial,
                receiptThankYou: receiptThankYou,
                receiptQrUrl: receiptQrUrl,
                receiptQrCaption: receiptQrCaption,
                logo: logo,
                logoRev: logoRev,
                taxEnabled: taxEnabled,
                taxRateBps: taxRateBps,
                serviceEnabled: serviceEnabled,
                serviceMode: serviceMode,
                serviceRateBps: serviceRateBps,
                serviceFixedAmount: serviceFixedAmount,
                businessDayStartHour: businessDayStartHour,
                prepTargetMins: prepTargetMins,
                guestOrderingEnabled: guestOrderingEnabled,
                soundNewOrder: soundNewOrder,
                soundReady: soundReady,
                soundVoid: soundVoid,
                soundOverdue: soundOverdue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VenueSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VenueSettingsTable,
      VenueSetting,
      $$VenueSettingsTableFilterComposer,
      $$VenueSettingsTableOrderingComposer,
      $$VenueSettingsTableAnnotationComposer,
      $$VenueSettingsTableCreateCompanionBuilder,
      $$VenueSettingsTableUpdateCompanionBuilder,
      (
        VenueSetting,
        BaseReferences<_$AppDatabase, $VenueSettingsTable, VenueSetting>,
      ),
      VenueSetting,
      PrefetchHooks Function()
    >;
typedef $$PrintersTableCreateCompanionBuilder =
    PrintersCompanion Function({
      required String id,
      required String label,
      required String host,
      Value<int> port,
      Value<String> kind,
      Value<bool> enabled,
      Value<DateTime?> lastSeenAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PrintersTableUpdateCompanionBuilder =
    PrintersCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<String> host,
      Value<int> port,
      Value<String> kind,
      Value<bool> enabled,
      Value<DateTime?> lastSeenAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PrintersTableFilterComposer
    extends Composer<_$AppDatabase, $PrintersTable> {
  $$PrintersTableFilterComposer({
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

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrintersTableOrderingComposer
    extends Composer<_$AppDatabase, $PrintersTable> {
  $$PrintersTableOrderingComposer({
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

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrintersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrintersTable> {
  $$PrintersTableAnnotationComposer({
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

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PrintersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrintersTable,
          Printer,
          $$PrintersTableFilterComposer,
          $$PrintersTableOrderingComposer,
          $$PrintersTableAnnotationComposer,
          $$PrintersTableCreateCompanionBuilder,
          $$PrintersTableUpdateCompanionBuilder,
          (Printer, BaseReferences<_$AppDatabase, $PrintersTable, Printer>),
          Printer,
          PrefetchHooks Function()
        > {
  $$PrintersTableTableManager(_$AppDatabase db, $PrintersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrintersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrintersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrintersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrintersCompanion(
                id: id,
                label: label,
                host: host,
                port: port,
                kind: kind,
                enabled: enabled,
                lastSeenAt: lastSeenAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required String host,
                Value<int> port = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PrintersCompanion.insert(
                id: id,
                label: label,
                host: host,
                port: port,
                kind: kind,
                enabled: enabled,
                lastSeenAt: lastSeenAt,
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

typedef $$PrintersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrintersTable,
      Printer,
      $$PrintersTableFilterComposer,
      $$PrintersTableOrderingComposer,
      $$PrintersTableAnnotationComposer,
      $$PrintersTableCreateCompanionBuilder,
      $$PrintersTableUpdateCompanionBuilder,
      (Printer, BaseReferences<_$AppDatabase, $PrintersTable, Printer>),
      Printer,
      PrefetchHooks Function()
    >;
typedef $$TableSessionsTableCreateCompanionBuilder =
    TableSessionsCompanion Function({
      required String id,
      required String tableId,
      Value<String?> tableLabel,
      required String zoneId,
      Value<int> pax,
      Value<DateTime?> openedAt,
      required DateTime closedAt,
      Value<int> durationSec,
      Value<String?> actorUserId,
      Value<int> subtotal,
      Value<int> voidAmount,
      Value<int> serviceAmount,
      Value<int> taxAmount,
      Value<int> netTotal,
      Value<int> ticketCount,
      Value<int> lossAmount,
      Value<String?> billClosedBy,
      Value<String> kind,
      Value<int> rowid,
    });
typedef $$TableSessionsTableUpdateCompanionBuilder =
    TableSessionsCompanion Function({
      Value<String> id,
      Value<String> tableId,
      Value<String?> tableLabel,
      Value<String> zoneId,
      Value<int> pax,
      Value<DateTime?> openedAt,
      Value<DateTime> closedAt,
      Value<int> durationSec,
      Value<String?> actorUserId,
      Value<int> subtotal,
      Value<int> voidAmount,
      Value<int> serviceAmount,
      Value<int> taxAmount,
      Value<int> netTotal,
      Value<int> ticketCount,
      Value<int> lossAmount,
      Value<String?> billClosedBy,
      Value<String> kind,
      Value<int> rowid,
    });

class $$TableSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $TableSessionsTable> {
  $$TableSessionsTableFilterComposer({
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

  ColumnFilters<String> get tableLabel => $composableBuilder(
    column: $table.tableLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zoneId => $composableBuilder(
    column: $table.zoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pax => $composableBuilder(
    column: $table.pax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get voidAmount => $composableBuilder(
    column: $table.voidAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceAmount => $composableBuilder(
    column: $table.serviceAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get netTotal => $composableBuilder(
    column: $table.netTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ticketCount => $composableBuilder(
    column: $table.ticketCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lossAmount => $composableBuilder(
    column: $table.lossAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billClosedBy => $composableBuilder(
    column: $table.billClosedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TableSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TableSessionsTable> {
  $$TableSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get tableLabel => $composableBuilder(
    column: $table.tableLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneId => $composableBuilder(
    column: $table.zoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pax => $composableBuilder(
    column: $table.pax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get voidAmount => $composableBuilder(
    column: $table.voidAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceAmount => $composableBuilder(
    column: $table.serviceAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get netTotal => $composableBuilder(
    column: $table.netTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ticketCount => $composableBuilder(
    column: $table.ticketCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lossAmount => $composableBuilder(
    column: $table.lossAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billClosedBy => $composableBuilder(
    column: $table.billClosedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TableSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TableSessionsTable> {
  $$TableSessionsTableAnnotationComposer({
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

  GeneratedColumn<String> get tableLabel => $composableBuilder(
    column: $table.tableLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zoneId =>
      $composableBuilder(column: $table.zoneId, builder: (column) => column);

  GeneratedColumn<int> get pax =>
      $composableBuilder(column: $table.pax, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<int> get voidAmount => $composableBuilder(
    column: $table.voidAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serviceAmount => $composableBuilder(
    column: $table.serviceAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<int> get netTotal =>
      $composableBuilder(column: $table.netTotal, builder: (column) => column);

  GeneratedColumn<int> get ticketCount => $composableBuilder(
    column: $table.ticketCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lossAmount => $composableBuilder(
    column: $table.lossAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get billClosedBy => $composableBuilder(
    column: $table.billClosedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);
}

class $$TableSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TableSessionsTable,
          TableSession,
          $$TableSessionsTableFilterComposer,
          $$TableSessionsTableOrderingComposer,
          $$TableSessionsTableAnnotationComposer,
          $$TableSessionsTableCreateCompanionBuilder,
          $$TableSessionsTableUpdateCompanionBuilder,
          (
            TableSession,
            BaseReferences<_$AppDatabase, $TableSessionsTable, TableSession>,
          ),
          TableSession,
          PrefetchHooks Function()
        > {
  $$TableSessionsTableTableManager(_$AppDatabase db, $TableSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TableSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TableSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TableSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tableId = const Value.absent(),
                Value<String?> tableLabel = const Value.absent(),
                Value<String> zoneId = const Value.absent(),
                Value<int> pax = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
                Value<DateTime> closedAt = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<String?> actorUserId = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<int> voidAmount = const Value.absent(),
                Value<int> serviceAmount = const Value.absent(),
                Value<int> taxAmount = const Value.absent(),
                Value<int> netTotal = const Value.absent(),
                Value<int> ticketCount = const Value.absent(),
                Value<int> lossAmount = const Value.absent(),
                Value<String?> billClosedBy = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TableSessionsCompanion(
                id: id,
                tableId: tableId,
                tableLabel: tableLabel,
                zoneId: zoneId,
                pax: pax,
                openedAt: openedAt,
                closedAt: closedAt,
                durationSec: durationSec,
                actorUserId: actorUserId,
                subtotal: subtotal,
                voidAmount: voidAmount,
                serviceAmount: serviceAmount,
                taxAmount: taxAmount,
                netTotal: netTotal,
                ticketCount: ticketCount,
                lossAmount: lossAmount,
                billClosedBy: billClosedBy,
                kind: kind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tableId,
                Value<String?> tableLabel = const Value.absent(),
                required String zoneId,
                Value<int> pax = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
                required DateTime closedAt,
                Value<int> durationSec = const Value.absent(),
                Value<String?> actorUserId = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<int> voidAmount = const Value.absent(),
                Value<int> serviceAmount = const Value.absent(),
                Value<int> taxAmount = const Value.absent(),
                Value<int> netTotal = const Value.absent(),
                Value<int> ticketCount = const Value.absent(),
                Value<int> lossAmount = const Value.absent(),
                Value<String?> billClosedBy = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TableSessionsCompanion.insert(
                id: id,
                tableId: tableId,
                tableLabel: tableLabel,
                zoneId: zoneId,
                pax: pax,
                openedAt: openedAt,
                closedAt: closedAt,
                durationSec: durationSec,
                actorUserId: actorUserId,
                subtotal: subtotal,
                voidAmount: voidAmount,
                serviceAmount: serviceAmount,
                taxAmount: taxAmount,
                netTotal: netTotal,
                ticketCount: ticketCount,
                lossAmount: lossAmount,
                billClosedBy: billClosedBy,
                kind: kind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TableSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TableSessionsTable,
      TableSession,
      $$TableSessionsTableFilterComposer,
      $$TableSessionsTableOrderingComposer,
      $$TableSessionsTableAnnotationComposer,
      $$TableSessionsTableCreateCompanionBuilder,
      $$TableSessionsTableUpdateCompanionBuilder,
      (
        TableSession,
        BaseReferences<_$AppDatabase, $TableSessionsTable, TableSession>,
      ),
      TableSession,
      PrefetchHooks Function()
    >;
typedef $$TableSessionTicketsTableCreateCompanionBuilder =
    TableSessionTicketsCompanion Function({
      required String id,
      required String sessionId,
      required String ticketId,
      required String itemId,
      required String name,
      Value<String> variantName,
      required String course,
      Value<int> qty,
      Value<String> modifiersJson,
      Value<String?> note,
      required int price,
      required String status,
      required DateTime sentAt,
      Value<DateTime?> readyAt,
      Value<DateTime?> servedAt,
      Value<String?> voidReason,
      Value<String?> voidReasonCode,
      Value<String?> voidApprovedBy,
      Value<String?> createdByUserId,
      Value<String?> voidedByUserId,
      Value<int> rowid,
    });
typedef $$TableSessionTicketsTableUpdateCompanionBuilder =
    TableSessionTicketsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> ticketId,
      Value<String> itemId,
      Value<String> name,
      Value<String> variantName,
      Value<String> course,
      Value<int> qty,
      Value<String> modifiersJson,
      Value<String?> note,
      Value<int> price,
      Value<String> status,
      Value<DateTime> sentAt,
      Value<DateTime?> readyAt,
      Value<DateTime?> servedAt,
      Value<String?> voidReason,
      Value<String?> voidReasonCode,
      Value<String?> voidApprovedBy,
      Value<String?> createdByUserId,
      Value<String?> voidedByUserId,
      Value<int> rowid,
    });

class $$TableSessionTicketsTableFilterComposer
    extends Composer<_$AppDatabase, $TableSessionTicketsTable> {
  $$TableSessionTicketsTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ticketId => $composableBuilder(
    column: $table.ticketId,
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

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiersJson => $composableBuilder(
    column: $table.modifiersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
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

  ColumnFilters<DateTime> get readyAt => $composableBuilder(
    column: $table.readyAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get servedAt => $composableBuilder(
    column: $table.servedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidReasonCode => $composableBuilder(
    column: $table.voidReasonCode,
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

  ColumnFilters<String> get voidedByUserId => $composableBuilder(
    column: $table.voidedByUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TableSessionTicketsTableOrderingComposer
    extends Composer<_$AppDatabase, $TableSessionTicketsTable> {
  $$TableSessionTicketsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ticketId => $composableBuilder(
    column: $table.ticketId,
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

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiersJson => $composableBuilder(
    column: $table.modifiersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
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

  ColumnOrderings<DateTime> get readyAt => $composableBuilder(
    column: $table.readyAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get servedAt => $composableBuilder(
    column: $table.servedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidReasonCode => $composableBuilder(
    column: $table.voidReasonCode,
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

  ColumnOrderings<String> get voidedByUserId => $composableBuilder(
    column: $table.voidedByUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TableSessionTicketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TableSessionTicketsTable> {
  $$TableSessionTicketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get ticketId =>
      $composableBuilder(column: $table.ticketId, builder: (column) => column);

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

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get modifiersJson => $composableBuilder(
    column: $table.modifiersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get readyAt =>
      $composableBuilder(column: $table.readyAt, builder: (column) => column);

  GeneratedColumn<DateTime> get servedAt =>
      $composableBuilder(column: $table.servedAt, builder: (column) => column);

  GeneratedColumn<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voidReasonCode => $composableBuilder(
    column: $table.voidReasonCode,
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

  GeneratedColumn<String> get voidedByUserId => $composableBuilder(
    column: $table.voidedByUserId,
    builder: (column) => column,
  );
}

class $$TableSessionTicketsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TableSessionTicketsTable,
          TableSessionTicket,
          $$TableSessionTicketsTableFilterComposer,
          $$TableSessionTicketsTableOrderingComposer,
          $$TableSessionTicketsTableAnnotationComposer,
          $$TableSessionTicketsTableCreateCompanionBuilder,
          $$TableSessionTicketsTableUpdateCompanionBuilder,
          (
            TableSessionTicket,
            BaseReferences<
              _$AppDatabase,
              $TableSessionTicketsTable,
              TableSessionTicket
            >,
          ),
          TableSessionTicket,
          PrefetchHooks Function()
        > {
  $$TableSessionTicketsTableTableManager(
    _$AppDatabase db,
    $TableSessionTicketsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TableSessionTicketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TableSessionTicketsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TableSessionTicketsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> ticketId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> variantName = const Value.absent(),
                Value<String> course = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<String> modifiersJson = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> price = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
                Value<DateTime?> readyAt = const Value.absent(),
                Value<DateTime?> servedAt = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<String?> voidReasonCode = const Value.absent(),
                Value<String?> voidApprovedBy = const Value.absent(),
                Value<String?> createdByUserId = const Value.absent(),
                Value<String?> voidedByUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TableSessionTicketsCompanion(
                id: id,
                sessionId: sessionId,
                ticketId: ticketId,
                itemId: itemId,
                name: name,
                variantName: variantName,
                course: course,
                qty: qty,
                modifiersJson: modifiersJson,
                note: note,
                price: price,
                status: status,
                sentAt: sentAt,
                readyAt: readyAt,
                servedAt: servedAt,
                voidReason: voidReason,
                voidReasonCode: voidReasonCode,
                voidApprovedBy: voidApprovedBy,
                createdByUserId: createdByUserId,
                voidedByUserId: voidedByUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String ticketId,
                required String itemId,
                required String name,
                Value<String> variantName = const Value.absent(),
                required String course,
                Value<int> qty = const Value.absent(),
                Value<String> modifiersJson = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int price,
                required String status,
                required DateTime sentAt,
                Value<DateTime?> readyAt = const Value.absent(),
                Value<DateTime?> servedAt = const Value.absent(),
                Value<String?> voidReason = const Value.absent(),
                Value<String?> voidReasonCode = const Value.absent(),
                Value<String?> voidApprovedBy = const Value.absent(),
                Value<String?> createdByUserId = const Value.absent(),
                Value<String?> voidedByUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TableSessionTicketsCompanion.insert(
                id: id,
                sessionId: sessionId,
                ticketId: ticketId,
                itemId: itemId,
                name: name,
                variantName: variantName,
                course: course,
                qty: qty,
                modifiersJson: modifiersJson,
                note: note,
                price: price,
                status: status,
                sentAt: sentAt,
                readyAt: readyAt,
                servedAt: servedAt,
                voidReason: voidReason,
                voidReasonCode: voidReasonCode,
                voidApprovedBy: voidApprovedBy,
                createdByUserId: createdByUserId,
                voidedByUserId: voidedByUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TableSessionTicketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TableSessionTicketsTable,
      TableSessionTicket,
      $$TableSessionTicketsTableFilterComposer,
      $$TableSessionTicketsTableOrderingComposer,
      $$TableSessionTicketsTableAnnotationComposer,
      $$TableSessionTicketsTableCreateCompanionBuilder,
      $$TableSessionTicketsTableUpdateCompanionBuilder,
      (
        TableSessionTicket,
        BaseReferences<
          _$AppDatabase,
          $TableSessionTicketsTable,
          TableSessionTicket
        >,
      ),
      TableSessionTicket,
      PrefetchHooks Function()
    >;
typedef $$TableSessionCoursesTableCreateCompanionBuilder =
    TableSessionCoursesCompanion Function({
      required String id,
      required String sessionId,
      required String courseId,
      Value<DateTime?> firedAt,
      Value<DateTime?> servedAt,
      Value<int> ticketCount,
      Value<int> rowid,
    });
typedef $$TableSessionCoursesTableUpdateCompanionBuilder =
    TableSessionCoursesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> courseId,
      Value<DateTime?> firedAt,
      Value<DateTime?> servedAt,
      Value<int> ticketCount,
      Value<int> rowid,
    });

class $$TableSessionCoursesTableFilterComposer
    extends Composer<_$AppDatabase, $TableSessionCoursesTable> {
  $$TableSessionCoursesTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firedAt => $composableBuilder(
    column: $table.firedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get servedAt => $composableBuilder(
    column: $table.servedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ticketCount => $composableBuilder(
    column: $table.ticketCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TableSessionCoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $TableSessionCoursesTable> {
  $$TableSessionCoursesTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firedAt => $composableBuilder(
    column: $table.firedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get servedAt => $composableBuilder(
    column: $table.servedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ticketCount => $composableBuilder(
    column: $table.ticketCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TableSessionCoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TableSessionCoursesTable> {
  $$TableSessionCoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<DateTime> get firedAt =>
      $composableBuilder(column: $table.firedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get servedAt =>
      $composableBuilder(column: $table.servedAt, builder: (column) => column);

  GeneratedColumn<int> get ticketCount => $composableBuilder(
    column: $table.ticketCount,
    builder: (column) => column,
  );
}

class $$TableSessionCoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TableSessionCoursesTable,
          TableSessionCourse,
          $$TableSessionCoursesTableFilterComposer,
          $$TableSessionCoursesTableOrderingComposer,
          $$TableSessionCoursesTableAnnotationComposer,
          $$TableSessionCoursesTableCreateCompanionBuilder,
          $$TableSessionCoursesTableUpdateCompanionBuilder,
          (
            TableSessionCourse,
            BaseReferences<
              _$AppDatabase,
              $TableSessionCoursesTable,
              TableSessionCourse
            >,
          ),
          TableSessionCourse,
          PrefetchHooks Function()
        > {
  $$TableSessionCoursesTableTableManager(
    _$AppDatabase db,
    $TableSessionCoursesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TableSessionCoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TableSessionCoursesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TableSessionCoursesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<DateTime?> firedAt = const Value.absent(),
                Value<DateTime?> servedAt = const Value.absent(),
                Value<int> ticketCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TableSessionCoursesCompanion(
                id: id,
                sessionId: sessionId,
                courseId: courseId,
                firedAt: firedAt,
                servedAt: servedAt,
                ticketCount: ticketCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String courseId,
                Value<DateTime?> firedAt = const Value.absent(),
                Value<DateTime?> servedAt = const Value.absent(),
                Value<int> ticketCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TableSessionCoursesCompanion.insert(
                id: id,
                sessionId: sessionId,
                courseId: courseId,
                firedAt: firedAt,
                servedAt: servedAt,
                ticketCount: ticketCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TableSessionCoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TableSessionCoursesTable,
      TableSessionCourse,
      $$TableSessionCoursesTableFilterComposer,
      $$TableSessionCoursesTableOrderingComposer,
      $$TableSessionCoursesTableAnnotationComposer,
      $$TableSessionCoursesTableCreateCompanionBuilder,
      $$TableSessionCoursesTableUpdateCompanionBuilder,
      (
        TableSessionCourse,
        BaseReferences<
          _$AppDatabase,
          $TableSessionCoursesTable,
          TableSessionCourse
        >,
      ),
      TableSessionCourse,
      PrefetchHooks Function()
    >;
typedef $$ReservationsTableCreateCompanionBuilder =
    ReservationsCompanion Function({
      required String id,
      required String name,
      Value<String?> phone,
      Value<int> partySize,
      required DateTime expectedAt,
      Value<String> status,
      Value<String?> zoneId,
      Value<String?> tableId,
      Value<String?> notes,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$ReservationsTableUpdateCompanionBuilder =
    ReservationsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> phone,
      Value<int> partySize,
      Value<DateTime> expectedAt,
      Value<String> status,
      Value<String?> zoneId,
      Value<String?> tableId,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$ReservationsTableFilterComposer
    extends Composer<_$AppDatabase, $ReservationsTable> {
  $$ReservationsTableFilterComposer({
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

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partySize => $composableBuilder(
    column: $table.partySize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expectedAt => $composableBuilder(
    column: $table.expectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zoneId => $composableBuilder(
    column: $table.zoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReservationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReservationsTable> {
  $$ReservationsTableOrderingComposer({
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

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partySize => $composableBuilder(
    column: $table.partySize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expectedAt => $composableBuilder(
    column: $table.expectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneId => $composableBuilder(
    column: $table.zoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReservationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReservationsTable> {
  $$ReservationsTableAnnotationComposer({
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

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<int> get partySize =>
      $composableBuilder(column: $table.partySize, builder: (column) => column);

  GeneratedColumn<DateTime> get expectedAt => $composableBuilder(
    column: $table.expectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get zoneId =>
      $composableBuilder(column: $table.zoneId, builder: (column) => column);

  GeneratedColumn<String> get tableId =>
      $composableBuilder(column: $table.tableId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReservationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReservationsTable,
          Reservation,
          $$ReservationsTableFilterComposer,
          $$ReservationsTableOrderingComposer,
          $$ReservationsTableAnnotationComposer,
          $$ReservationsTableCreateCompanionBuilder,
          $$ReservationsTableUpdateCompanionBuilder,
          (
            Reservation,
            BaseReferences<_$AppDatabase, $ReservationsTable, Reservation>,
          ),
          Reservation,
          PrefetchHooks Function()
        > {
  $$ReservationsTableTableManager(_$AppDatabase db, $ReservationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReservationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReservationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReservationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<int> partySize = const Value.absent(),
                Value<DateTime> expectedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> zoneId = const Value.absent(),
                Value<String?> tableId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReservationsCompanion(
                id: id,
                name: name,
                phone: phone,
                partySize: partySize,
                expectedAt: expectedAt,
                status: status,
                zoneId: zoneId,
                tableId: tableId,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<int> partySize = const Value.absent(),
                required DateTime expectedAt,
                Value<String> status = const Value.absent(),
                Value<String?> zoneId = const Value.absent(),
                Value<String?> tableId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReservationsCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                partySize: partySize,
                expectedAt: expectedAt,
                status: status,
                zoneId: zoneId,
                tableId: tableId,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReservationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReservationsTable,
      Reservation,
      $$ReservationsTableFilterComposer,
      $$ReservationsTableOrderingComposer,
      $$ReservationsTableAnnotationComposer,
      $$ReservationsTableCreateCompanionBuilder,
      $$ReservationsTableUpdateCompanionBuilder,
      (
        Reservation,
        BaseReferences<_$AppDatabase, $ReservationsTable, Reservation>,
      ),
      Reservation,
      PrefetchHooks Function()
    >;
typedef $$ReceiptsTableCreateCompanionBuilder =
    ReceiptsCompanion Function({
      required String id,
      required String tableId,
      Value<String?> visitId,
      Value<String> mode,
      Value<String> label,
      Value<int> subtotal,
      Value<int> serviceAmount,
      Value<int> taxAmount,
      Value<int> total,
      Value<String> status,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ReceiptsTableUpdateCompanionBuilder =
    ReceiptsCompanion Function({
      Value<String> id,
      Value<String> tableId,
      Value<String?> visitId,
      Value<String> mode,
      Value<String> label,
      Value<int> subtotal,
      Value<int> serviceAmount,
      Value<int> taxAmount,
      Value<int> total,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
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

  ColumnFilters<String> get visitId => $composableBuilder(
    column: $table.visitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceAmount => $composableBuilder(
    column: $table.serviceAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
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

  ColumnOrderings<String> get visitId => $composableBuilder(
    column: $table.visitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceAmount => $composableBuilder(
    column: $table.serviceAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
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

  GeneratedColumn<String> get visitId =>
      $composableBuilder(column: $table.visitId, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<int> get serviceAmount => $composableBuilder(
    column: $table.serviceAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptsTable,
          Receipt,
          $$ReceiptsTableFilterComposer,
          $$ReceiptsTableOrderingComposer,
          $$ReceiptsTableAnnotationComposer,
          $$ReceiptsTableCreateCompanionBuilder,
          $$ReceiptsTableUpdateCompanionBuilder,
          (Receipt, BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt>),
          Receipt,
          PrefetchHooks Function()
        > {
  $$ReceiptsTableTableManager(_$AppDatabase db, $ReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tableId = const Value.absent(),
                Value<String?> visitId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<int> serviceAmount = const Value.absent(),
                Value<int> taxAmount = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion(
                id: id,
                tableId: tableId,
                visitId: visitId,
                mode: mode,
                label: label,
                subtotal: subtotal,
                serviceAmount: serviceAmount,
                taxAmount: taxAmount,
                total: total,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tableId,
                Value<String?> visitId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<int> serviceAmount = const Value.absent(),
                Value<int> taxAmount = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion.insert(
                id: id,
                tableId: tableId,
                visitId: visitId,
                mode: mode,
                label: label,
                subtotal: subtotal,
                serviceAmount: serviceAmount,
                taxAmount: taxAmount,
                total: total,
                status: status,
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

typedef $$ReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptsTable,
      Receipt,
      $$ReceiptsTableFilterComposer,
      $$ReceiptsTableOrderingComposer,
      $$ReceiptsTableAnnotationComposer,
      $$ReceiptsTableCreateCompanionBuilder,
      $$ReceiptsTableUpdateCompanionBuilder,
      (Receipt, BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt>),
      Receipt,
      PrefetchHooks Function()
    >;
typedef $$ReceiptLinesTableCreateCompanionBuilder =
    ReceiptLinesCompanion Function({
      required String id,
      required String receiptId,
      required String ticketId,
      Value<int> qtyUnits,
      Value<int> rowid,
    });
typedef $$ReceiptLinesTableUpdateCompanionBuilder =
    ReceiptLinesCompanion Function({
      Value<String> id,
      Value<String> receiptId,
      Value<String> ticketId,
      Value<int> qtyUnits,
      Value<int> rowid,
    });

class $$ReceiptLinesTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptLinesTable> {
  $$ReceiptLinesTableFilterComposer({
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

  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ticketId => $composableBuilder(
    column: $table.ticketId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qtyUnits => $composableBuilder(
    column: $table.qtyUnits,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReceiptLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptLinesTable> {
  $$ReceiptLinesTableOrderingComposer({
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

  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ticketId => $composableBuilder(
    column: $table.ticketId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qtyUnits => $composableBuilder(
    column: $table.qtyUnits,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceiptLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptLinesTable> {
  $$ReceiptLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get ticketId =>
      $composableBuilder(column: $table.ticketId, builder: (column) => column);

  GeneratedColumn<int> get qtyUnits =>
      $composableBuilder(column: $table.qtyUnits, builder: (column) => column);
}

class $$ReceiptLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptLinesTable,
          ReceiptLine,
          $$ReceiptLinesTableFilterComposer,
          $$ReceiptLinesTableOrderingComposer,
          $$ReceiptLinesTableAnnotationComposer,
          $$ReceiptLinesTableCreateCompanionBuilder,
          $$ReceiptLinesTableUpdateCompanionBuilder,
          (
            ReceiptLine,
            BaseReferences<_$AppDatabase, $ReceiptLinesTable, ReceiptLine>,
          ),
          ReceiptLine,
          PrefetchHooks Function()
        > {
  $$ReceiptLinesTableTableManager(_$AppDatabase db, $ReceiptLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> receiptId = const Value.absent(),
                Value<String> ticketId = const Value.absent(),
                Value<int> qtyUnits = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptLinesCompanion(
                id: id,
                receiptId: receiptId,
                ticketId: ticketId,
                qtyUnits: qtyUnits,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String receiptId,
                required String ticketId,
                Value<int> qtyUnits = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptLinesCompanion.insert(
                id: id,
                receiptId: receiptId,
                ticketId: ticketId,
                qtyUnits: qtyUnits,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReceiptLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptLinesTable,
      ReceiptLine,
      $$ReceiptLinesTableFilterComposer,
      $$ReceiptLinesTableOrderingComposer,
      $$ReceiptLinesTableAnnotationComposer,
      $$ReceiptLinesTableCreateCompanionBuilder,
      $$ReceiptLinesTableUpdateCompanionBuilder,
      (
        ReceiptLine,
        BaseReferences<_$AppDatabase, $ReceiptLinesTable, ReceiptLine>,
      ),
      ReceiptLine,
      PrefetchHooks Function()
    >;
typedef $$PaymentsTableCreateCompanionBuilder =
    PaymentsCompanion Function({
      required String id,
      required String receiptId,
      required String method,
      required int amount,
      Value<bool> isRefund,
      Value<int?> tenderedAmount,
      Value<String?> cashierUserId,
      Value<String?> note,
      required DateTime at,
      Value<Uint8List?> photo,
      Value<int> rowid,
    });
typedef $$PaymentsTableUpdateCompanionBuilder =
    PaymentsCompanion Function({
      Value<String> id,
      Value<String> receiptId,
      Value<String> method,
      Value<int> amount,
      Value<bool> isRefund,
      Value<int?> tenderedAmount,
      Value<String?> cashierUserId,
      Value<String?> note,
      Value<DateTime> at,
      Value<Uint8List?> photo,
      Value<int> rowid,
    });

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
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

  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRefund => $composableBuilder(
    column: $table.isRefund,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tenderedAmount => $composableBuilder(
    column: $table.tenderedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierUserId => $composableBuilder(
    column: $table.cashierUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
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

  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRefund => $composableBuilder(
    column: $table.isRefund,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tenderedAmount => $composableBuilder(
    column: $table.tenderedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierUserId => $composableBuilder(
    column: $table.cashierUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<bool> get isRefund =>
      $composableBuilder(column: $table.isRefund, builder: (column) => column);

  GeneratedColumn<int> get tenderedAmount => $composableBuilder(
    column: $table.tenderedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashierUserId => $composableBuilder(
    column: $table.cashierUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<Uint8List> get photo =>
      $composableBuilder(column: $table.photo, builder: (column) => column);
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          Payment,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (Payment, BaseReferences<_$AppDatabase, $PaymentsTable, Payment>),
          Payment,
          PrefetchHooks Function()
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> receiptId = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<bool> isRefund = const Value.absent(),
                Value<int?> tenderedAmount = const Value.absent(),
                Value<String?> cashierUserId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<Uint8List?> photo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                receiptId: receiptId,
                method: method,
                amount: amount,
                isRefund: isRefund,
                tenderedAmount: tenderedAmount,
                cashierUserId: cashierUserId,
                note: note,
                at: at,
                photo: photo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String receiptId,
                required String method,
                required int amount,
                Value<bool> isRefund = const Value.absent(),
                Value<int?> tenderedAmount = const Value.absent(),
                Value<String?> cashierUserId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime at,
                Value<Uint8List?> photo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion.insert(
                id: id,
                receiptId: receiptId,
                method: method,
                amount: amount,
                isRefund: isRefund,
                tenderedAmount: tenderedAmount,
                cashierUserId: cashierUserId,
                note: note,
                at: at,
                photo: photo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      Payment,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (Payment, BaseReferences<_$AppDatabase, $PaymentsTable, Payment>),
      Payment,
      PrefetchHooks Function()
    >;
typedef $$TableSessionReceiptsTableCreateCompanionBuilder =
    TableSessionReceiptsCompanion Function({
      required String id,
      required String sessionId,
      required String receiptId,
      Value<String> mode,
      Value<String> label,
      Value<int> subtotal,
      Value<int> serviceAmount,
      Value<int> taxAmount,
      Value<int> total,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$TableSessionReceiptsTableUpdateCompanionBuilder =
    TableSessionReceiptsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> receiptId,
      Value<String> mode,
      Value<String> label,
      Value<int> subtotal,
      Value<int> serviceAmount,
      Value<int> taxAmount,
      Value<int> total,
      Value<String> status,
      Value<int> rowid,
    });

class $$TableSessionReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $TableSessionReceiptsTable> {
  $$TableSessionReceiptsTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceAmount => $composableBuilder(
    column: $table.serviceAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TableSessionReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $TableSessionReceiptsTable> {
  $$TableSessionReceiptsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceAmount => $composableBuilder(
    column: $table.serviceAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TableSessionReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TableSessionReceiptsTable> {
  $$TableSessionReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<int> get serviceAmount => $composableBuilder(
    column: $table.serviceAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$TableSessionReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TableSessionReceiptsTable,
          TableSessionReceipt,
          $$TableSessionReceiptsTableFilterComposer,
          $$TableSessionReceiptsTableOrderingComposer,
          $$TableSessionReceiptsTableAnnotationComposer,
          $$TableSessionReceiptsTableCreateCompanionBuilder,
          $$TableSessionReceiptsTableUpdateCompanionBuilder,
          (
            TableSessionReceipt,
            BaseReferences<
              _$AppDatabase,
              $TableSessionReceiptsTable,
              TableSessionReceipt
            >,
          ),
          TableSessionReceipt,
          PrefetchHooks Function()
        > {
  $$TableSessionReceiptsTableTableManager(
    _$AppDatabase db,
    $TableSessionReceiptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TableSessionReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TableSessionReceiptsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TableSessionReceiptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> receiptId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<int> serviceAmount = const Value.absent(),
                Value<int> taxAmount = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TableSessionReceiptsCompanion(
                id: id,
                sessionId: sessionId,
                receiptId: receiptId,
                mode: mode,
                label: label,
                subtotal: subtotal,
                serviceAmount: serviceAmount,
                taxAmount: taxAmount,
                total: total,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String receiptId,
                Value<String> mode = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<int> serviceAmount = const Value.absent(),
                Value<int> taxAmount = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TableSessionReceiptsCompanion.insert(
                id: id,
                sessionId: sessionId,
                receiptId: receiptId,
                mode: mode,
                label: label,
                subtotal: subtotal,
                serviceAmount: serviceAmount,
                taxAmount: taxAmount,
                total: total,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TableSessionReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TableSessionReceiptsTable,
      TableSessionReceipt,
      $$TableSessionReceiptsTableFilterComposer,
      $$TableSessionReceiptsTableOrderingComposer,
      $$TableSessionReceiptsTableAnnotationComposer,
      $$TableSessionReceiptsTableCreateCompanionBuilder,
      $$TableSessionReceiptsTableUpdateCompanionBuilder,
      (
        TableSessionReceipt,
        BaseReferences<
          _$AppDatabase,
          $TableSessionReceiptsTable,
          TableSessionReceipt
        >,
      ),
      TableSessionReceipt,
      PrefetchHooks Function()
    >;
typedef $$TableSessionPaymentsTableCreateCompanionBuilder =
    TableSessionPaymentsCompanion Function({
      required String id,
      required String sessionId,
      required String receiptId,
      required String method,
      required int amount,
      Value<bool> isRefund,
      Value<String?> cashierUserId,
      required DateTime at,
      Value<Uint8List?> photo,
      Value<int> rowid,
    });
typedef $$TableSessionPaymentsTableUpdateCompanionBuilder =
    TableSessionPaymentsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> receiptId,
      Value<String> method,
      Value<int> amount,
      Value<bool> isRefund,
      Value<String?> cashierUserId,
      Value<DateTime> at,
      Value<Uint8List?> photo,
      Value<int> rowid,
    });

class $$TableSessionPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $TableSessionPaymentsTable> {
  $$TableSessionPaymentsTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRefund => $composableBuilder(
    column: $table.isRefund,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierUserId => $composableBuilder(
    column: $table.cashierUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TableSessionPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $TableSessionPaymentsTable> {
  $$TableSessionPaymentsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRefund => $composableBuilder(
    column: $table.isRefund,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierUserId => $composableBuilder(
    column: $table.cashierUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TableSessionPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TableSessionPaymentsTable> {
  $$TableSessionPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<bool> get isRefund =>
      $composableBuilder(column: $table.isRefund, builder: (column) => column);

  GeneratedColumn<String> get cashierUserId => $composableBuilder(
    column: $table.cashierUserId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<Uint8List> get photo =>
      $composableBuilder(column: $table.photo, builder: (column) => column);
}

class $$TableSessionPaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TableSessionPaymentsTable,
          TableSessionPayment,
          $$TableSessionPaymentsTableFilterComposer,
          $$TableSessionPaymentsTableOrderingComposer,
          $$TableSessionPaymentsTableAnnotationComposer,
          $$TableSessionPaymentsTableCreateCompanionBuilder,
          $$TableSessionPaymentsTableUpdateCompanionBuilder,
          (
            TableSessionPayment,
            BaseReferences<
              _$AppDatabase,
              $TableSessionPaymentsTable,
              TableSessionPayment
            >,
          ),
          TableSessionPayment,
          PrefetchHooks Function()
        > {
  $$TableSessionPaymentsTableTableManager(
    _$AppDatabase db,
    $TableSessionPaymentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TableSessionPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TableSessionPaymentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TableSessionPaymentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> receiptId = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<bool> isRefund = const Value.absent(),
                Value<String?> cashierUserId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<Uint8List?> photo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TableSessionPaymentsCompanion(
                id: id,
                sessionId: sessionId,
                receiptId: receiptId,
                method: method,
                amount: amount,
                isRefund: isRefund,
                cashierUserId: cashierUserId,
                at: at,
                photo: photo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String receiptId,
                required String method,
                required int amount,
                Value<bool> isRefund = const Value.absent(),
                Value<String?> cashierUserId = const Value.absent(),
                required DateTime at,
                Value<Uint8List?> photo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TableSessionPaymentsCompanion.insert(
                id: id,
                sessionId: sessionId,
                receiptId: receiptId,
                method: method,
                amount: amount,
                isRefund: isRefund,
                cashierUserId: cashierUserId,
                at: at,
                photo: photo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TableSessionPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TableSessionPaymentsTable,
      TableSessionPayment,
      $$TableSessionPaymentsTableFilterComposer,
      $$TableSessionPaymentsTableOrderingComposer,
      $$TableSessionPaymentsTableAnnotationComposer,
      $$TableSessionPaymentsTableCreateCompanionBuilder,
      $$TableSessionPaymentsTableUpdateCompanionBuilder,
      (
        TableSessionPayment,
        BaseReferences<
          _$AppDatabase,
          $TableSessionPaymentsTable,
          TableSessionPayment
        >,
      ),
      TableSessionPayment,
      PrefetchHooks Function()
    >;
typedef $$DailyCountersTableCreateCompanionBuilder =
    DailyCountersCompanion Function({
      required String dateStr,
      Value<int> takeawayNext,
      Value<int> rowid,
    });
typedef $$DailyCountersTableUpdateCompanionBuilder =
    DailyCountersCompanion Function({
      Value<String> dateStr,
      Value<int> takeawayNext,
      Value<int> rowid,
    });

class $$DailyCountersTableFilterComposer
    extends Composer<_$AppDatabase, $DailyCountersTable> {
  $$DailyCountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dateStr => $composableBuilder(
    column: $table.dateStr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get takeawayNext => $composableBuilder(
    column: $table.takeawayNext,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyCountersTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyCountersTable> {
  $$DailyCountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dateStr => $composableBuilder(
    column: $table.dateStr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get takeawayNext => $composableBuilder(
    column: $table.takeawayNext,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyCountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyCountersTable> {
  $$DailyCountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dateStr =>
      $composableBuilder(column: $table.dateStr, builder: (column) => column);

  GeneratedColumn<int> get takeawayNext => $composableBuilder(
    column: $table.takeawayNext,
    builder: (column) => column,
  );
}

class $$DailyCountersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyCountersTable,
          DailyCounter,
          $$DailyCountersTableFilterComposer,
          $$DailyCountersTableOrderingComposer,
          $$DailyCountersTableAnnotationComposer,
          $$DailyCountersTableCreateCompanionBuilder,
          $$DailyCountersTableUpdateCompanionBuilder,
          (
            DailyCounter,
            BaseReferences<_$AppDatabase, $DailyCountersTable, DailyCounter>,
          ),
          DailyCounter,
          PrefetchHooks Function()
        > {
  $$DailyCountersTableTableManager(_$AppDatabase db, $DailyCountersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyCountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyCountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyCountersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> dateStr = const Value.absent(),
                Value<int> takeawayNext = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyCountersCompanion(
                dateStr: dateStr,
                takeawayNext: takeawayNext,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dateStr,
                Value<int> takeawayNext = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyCountersCompanion.insert(
                dateStr: dateStr,
                takeawayNext: takeawayNext,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyCountersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyCountersTable,
      DailyCounter,
      $$DailyCountersTableFilterComposer,
      $$DailyCountersTableOrderingComposer,
      $$DailyCountersTableAnnotationComposer,
      $$DailyCountersTableCreateCompanionBuilder,
      $$DailyCountersTableUpdateCompanionBuilder,
      (
        DailyCounter,
        BaseReferences<_$AppDatabase, $DailyCountersTable, DailyCounter>,
      ),
      DailyCounter,
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
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
  $$MenuCategoriesTableTableManager get menuCategories =>
      $$MenuCategoriesTableTableManager(_db, _db.menuCategories);
  $$MenuItemsTableTableManager get menuItems =>
      $$MenuItemsTableTableManager(_db, _db.menuItems);
  $$MenuTagsTableTableManager get menuTags =>
      $$MenuTagsTableTableManager(_db, _db.menuTags);
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
  $$VenueSettingsTableTableManager get venueSettings =>
      $$VenueSettingsTableTableManager(_db, _db.venueSettings);
  $$PrintersTableTableManager get printers =>
      $$PrintersTableTableManager(_db, _db.printers);
  $$TableSessionsTableTableManager get tableSessions =>
      $$TableSessionsTableTableManager(_db, _db.tableSessions);
  $$TableSessionTicketsTableTableManager get tableSessionTickets =>
      $$TableSessionTicketsTableTableManager(_db, _db.tableSessionTickets);
  $$TableSessionCoursesTableTableManager get tableSessionCourses =>
      $$TableSessionCoursesTableTableManager(_db, _db.tableSessionCourses);
  $$ReservationsTableTableManager get reservations =>
      $$ReservationsTableTableManager(_db, _db.reservations);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$ReceiptLinesTableTableManager get receiptLines =>
      $$ReceiptLinesTableTableManager(_db, _db.receiptLines);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$TableSessionReceiptsTableTableManager get tableSessionReceipts =>
      $$TableSessionReceiptsTableTableManager(_db, _db.tableSessionReceipts);
  $$TableSessionPaymentsTableTableManager get tableSessionPayments =>
      $$TableSessionPaymentsTableTableManager(_db, _db.tableSessionPayments);
  $$DailyCountersTableTableManager get dailyCounters =>
      $$DailyCountersTableTableManager(_db, _db.dailyCounters);
}
