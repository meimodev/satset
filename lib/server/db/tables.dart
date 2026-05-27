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
  TextColumn get email => text().nullable()();
  TextColumn get passwordHash => text().nullable()();
  BoolColumn get disabled => boolean().withDefault(const Constant(false))();
  IntColumn get avatarColorHex => integer().nullable()();
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
  IntColumn get capacity => integer().withDefault(const Constant(2))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get status => text().withDefault(const Constant('available'))();
  IntColumn get openAmount => integer().withDefault(const Constant(0))();
  IntColumn get readyCount => integer().withDefault(const Constant(0))();
  TextColumn get lastActorId => text().nullable()();
  TextColumn get lockedBy => text().nullable()();
  TextColumn get lockedByName => text().nullable()();
  DateTimeColumn get lockedAt => dateTime().nullable()();
  DateTimeColumn get lockExpiresAt => dateTime().nullable()();
  DateTimeColumn get openedAt => dateTime().nullable()();
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
  /// Cost of goods (same int-cents unit as `basePrice`). Used for margin
  /// reports + menu-engineering matrix. 0 = unknown (treated as full margin).
  IntColumn get cost => integer().withDefault(const Constant(0))();
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
  /// Canonical enum slug for void/comp analytics. One of:
  /// outOfStock | wrongOrder | customerChange | kitchenError | comp | other.
  TextColumn get voidReasonCode => text().nullable()();
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

/// Single-row venue config: pajak (tax) + layanan (service charge) settings.
/// Always keyed by id='default'. UI exposes toggles + editable rates.
class VenueSettings extends Table {
  TextColumn get id => text()();
  TextColumn get displayName =>
      text().withDefault(const Constant('Warung Sebelah'))();
  TextColumn get legalName => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get receiptHeader => text().withDefault(const Constant(''))();
  TextColumn get receiptFooter => text().withDefault(const Constant(''))();
  BoolColumn get taxEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get taxRateBps => integer().withDefault(const Constant(1100))();
  BoolColumn get serviceEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get serviceMode =>
      text().withDefault(const Constant('percent'))();
  IntColumn get serviceRateBps => integer().withDefault(const Constant(500))();
  IntColumn get serviceFixedAmount =>
      integer().withDefault(const Constant(0))();
  /// Business-day rollover hour (0..23). Reports bucket "today" as
  /// [hour, hour+24h). Default 4 covers late-night service.
  IntColumn get businessDayStartHour =>
      integer().withDefault(const Constant(4))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Printers + KDS displays advertised on the LAN. ESC/POS receipt printers
/// or KDS station screens. `lastSeenAt` updated when the device check-ins
/// (test print, status ping). Online = now - lastSeenAt &lt; 5min.
class Printers extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get host => text()();
  IntColumn get port => integer().withDefault(const Constant(9100))();

  /// 'escpos' or 'kds'.
  TextColumn get kind => text().withDefault(const Constant('escpos'))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
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

/// Historical table-occupancy session. Inserted when a table is closed.
/// Source of truth for reports + insights (revenue, turn time, item mix,
/// void rate). Tickets are snapshotted into TableSessionTickets and the
/// originals are deleted from the live `tickets` table.
class TableSessions extends Table {
  TextColumn get id => text()();
  TextColumn get tableId => text()();
  TextColumn get tableLabel => text().nullable()();
  TextColumn get zoneId => text()();
  IntColumn get pax => integer().withDefault(const Constant(0))();
  DateTimeColumn get openedAt => dateTime().nullable()();
  DateTimeColumn get closedAt => dateTime()();
  IntColumn get durationSec => integer().withDefault(const Constant(0))();
  TextColumn get actorUserId => text().nullable()();
  IntColumn get subtotal => integer().withDefault(const Constant(0))();
  IntColumn get voidAmount => integer().withDefault(const Constant(0))();
  IntColumn get netTotal => integer().withDefault(const Constant(0))();
  IntColumn get ticketCount => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Per-ticket snapshot tied to a TableSession. Mirrors `tickets` columns
/// at close time so reports survive after live tickets are hard-deleted.
class TableSessionTickets extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get ticketId => text()();
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
  /// Canonical enum slug — mirrors Tickets.voidReasonCode at session close.
  TextColumn get voidReasonCode => text().nullable()();
  TextColumn get voidApprovedBy => text().nullable()();
  TextColumn get createdByUserId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Internal-only reservation entries. Hosts add via the tables screen.
/// Status flow: pending → seated | noShow | cancelled. Deletes are
/// disallowed for `seated` rows (transition to cancelled first).
class Reservations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  IntColumn get partySize => integer().withDefault(const Constant(1))();
  DateTimeColumn get expectedAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get zoneId => text().nullable()();
  TextColumn get tableId => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Per-course timing rollup for a session. `firedAt` is the earliest
/// ticket `sentAt` in that course; `servedAt` is the latest sentAt of
/// tickets in `served` status (best-effort — live tickets do not yet
/// carry an explicit servedAt column).
class TableSessionCourses extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get courseId => text()();
  DateTimeColumn get firedAt => dateTime().nullable()();
  DateTimeColumn get servedAt => dateTime().nullable()();
  IntColumn get ticketCount => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}
