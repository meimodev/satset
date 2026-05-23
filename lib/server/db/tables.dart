import 'package:drift/drift.dart';

/// Drift schema. Tables intentionally lean — only what the LAN core flow
/// touches today (auth, menu, tables, tickets, reference). Audit is limited
/// to auth/core-order events.
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get initials => text()();
  TextColumn get roleId => text()();
  TextColumn get zoneAssigned => text().nullable()();
  TextColumn get pinHash => text()();
  BoolColumn get onDuty => boolean().withDefault(const Constant(true))();
  BoolColumn get disabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get shiftStartedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Roles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text().withDefault(const Constant('#C08AFF'))();

  /// JSON array of capability keys.
  TextColumn get capabilitiesJson => text().withDefault(const Constant('[]'))();
  @override
  Set<Column> get primaryKey => {id};
}

class Zones extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get short => text()();
  TextColumn get colorHex => text().withDefault(const Constant('#FF9233'))();
  TextColumn get iconKey =>
      text().withDefault(const Constant('table_restaurant'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

class VenueTables extends Table {
  TextColumn get id => text()();
  TextColumn get zoneId => text()();
  TextColumn get label => text().nullable()();
  IntColumn get pax => integer().withDefault(const Constant(2))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get status => text().withDefault(const Constant('available'))();
  IntColumn get openAmount => integer().withDefault(const Constant(0))();
  IntColumn get readyCount => integer().withDefault(const Constant(0))();
  TextColumn get lastActorId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class MenuCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

class MenuItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get categoryId => text()();
  TextColumn get station => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get basePrice => integer()();
  IntColumn get prepTime => integer().withDefault(const Constant(5))();
  TextColumn get variantsJson => text().withDefault(const Constant('[]'))();
  TextColumn get modifierGroupIdsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get allergensJson => text().withDefault(const Constant('[]'))();
  TextColumn get dietaryJson => text().withDefault(const Constant('[]'))();
  BoolColumn get unavailable => boolean().withDefault(const Constant(false))();
  IntColumn get stockCount => integer().nullable()();
  BoolColumn get autoEightySixAtZero =>
      boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class ModifierGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get required => boolean().withDefault(const Constant(false))();
  BoolColumn get multi => boolean().withDefault(const Constant(false))();
  TextColumn get optionsJson => text().withDefault(const Constant('[]'))();
  @override
  Set<Column> get primaryKey => {id};
}

class Tickets extends Table {
  TextColumn get id => text()();
  TextColumn get tableId => text()();
  TextColumn get itemId => text()();
  TextColumn get name => text()();
  TextColumn get variantName => text().withDefault(const Constant(''))();
  TextColumn get course => text()();
  TextColumn get station => text()();
  IntColumn get qty => integer().withDefault(const Constant(1))();
  TextColumn get modifiersJson => text().withDefault(const Constant('[]'))();
  TextColumn get specialInstructions => text().nullable()();
  IntColumn get price => integer()();
  TextColumn get status => text()();
  DateTimeColumn get sentAt => dateTime()();
  TextColumn get voidReason => text().nullable()();
  TextColumn get voidApprovedBy => text().nullable()();
  TextColumn get createdByUserId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Sessions extends Table {
  TextColumn get token => text()();
  TextColumn get userId => text()();
  TextColumn get deviceId => text()();
  DateTimeColumn get issuedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  @override
  Set<Column> get primaryKey => {token};
}

class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get publicKeyPem => text()();
  DateTimeColumn get pairedAt => dateTime()();
  BoolColumn get revoked => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class PairTokens extends Table {
  TextColumn get token => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  BoolColumn get used => boolean().withDefault(const Constant(false))();
  TextColumn get claimedByDeviceId => text().nullable()();
  @override
  Set<Column> get primaryKey => {token};
}

class Idempotency extends Table {
  TextColumn get key => text()();

  /// JSON-serialised response body.
  TextColumn get responseJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {key};
}

class AuditEntries extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get tableId => text().nullable()();
  DateTimeColumn get at => dateTime()();
  TextColumn get approvedBy => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get actorUserId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
