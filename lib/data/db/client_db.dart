import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'client_db.g.dart';

/// The **[[Antrean setelmen]]** — one row per settlement act a
/// [[Terputus (client disconnected)|terputus]] till captured (ADR-0123).
///
/// Ordered per [visitId] by [seq], because a settlement is a chain: each act
/// reads what the last one wrote. That is the whole reason this is not a second
/// [[Antrean kirim]].
@DataClassName('SettlementEventRow')
class SettlementEvents extends Table {
  /// Also the idempotency key the replay carries, and the id of whatever row
  /// the act mints (ADR-0123 §ids). Stable across every retry.
  TextColumn get id => text()();

  TextColumn get visitId => text()();

  /// Order within the visit. Monotonic per visit, never reused.
  IntColumn get seq => integer()();

  /// A [SettlementEventKind] name. **Persisted** — never rename one, same rule
  /// as `AuditKind`.
  TextColumn get kind => text()();

  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();

  /// When the cashier did it, not when it drained. The host honours this for
  /// the payment's `at`, the audit row and the business day it lands in.
  DateTimeColumn get capturedAt => dateTime()();

  TextColumn get actorId => text().withDefault(const Constant(''))();

  /// `pending` — waiting to drain. `parked` — this visit's chain hit a refusal
  /// and everything from here on is untried (never "failed": the act happened,
  /// the host just has not taken it).
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// The host's machine-readable refusal `code`, on the one event that was
  /// actually refused. A code crosses the layer, never a sentence (ADR-0085).
  TextColumn get failCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The last full [[Bill (tab)]] the host gave us for an open [[Visit]],
/// prefetched while online so a bill nobody happened to open is still
/// settleable when the host goes away (ADR-0123 §Q19).
@DataClassName('CachedBillRow')
class CachedBills extends Table {
  TextColumn get visitId => text()();

  /// The server's own bill JSON, stored whole. Kept as the wire shape rather
  /// than a parsed model so the projection can hand `Bill.fromJson` exactly
  /// what the host would have.
  TextColumn get billJson => text()();

  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {visitId};
}

/// The last **[[Antrean setelmen]]-bearing payable list** the host gave us.
///
/// One row. Without it a cold boot with no host renders an empty `/kasir` —
/// every bill cached and none of them reachable, because the list a cashier
/// taps through is fetched, not derived. The bills are useless if the way in
/// is missing.
@DataClassName('CachedPayableRow')
class CachedPayable extends Table {
  /// Always [payableRowId]; this table holds one snapshot, not a history.
  TextColumn get id => text()();

  /// The server's own `/settlement/payable` JSON array, stored whole, for the
  /// reason [CachedBills] stores the bill whole.
  TextColumn get listJson => text()();

  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The single row [CachedPayable] ever holds.
const payableRowId = 'payable';

/// The **[[Salinan pelanggan]]** — this device's copy of the venue's member
/// directory, so a dark handset can still find and attach a regular (ADR-0129).
///
/// A copy and never a source. Every derived figure below arrives already
/// computed by the host and is rendered **with [syncedAt]** beside it, because
/// a balance is `SUM(delta)` over a ledger this device holds no rows of — the
/// same rule that keeps the till from summing points online (ADR-0092,
/// ADR-0095).
///
/// It lives in this database rather than prefs for one reason: a directory of
/// low thousands, searched by prefix on two columns, is a query. That widens
/// ADR-0124's charter from "money it cannot send" to "money it cannot send, and
/// the directory that money names" — deliberately, and stated in ADR-0129.
@DataClassName('CachedMemberRow')
class CachedMembers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// The number, in the clear — **only on a device that may settle**. A
  /// handset that can only take orders stores `''` here and searches by
  /// [phoneHash] instead, which is the same split `/members/lookup` makes on
  /// the wire, applied to a copy that sits on disk.
  TextColumn get phone => text().withDefault(const Constant(''))();

  /// Salted digest of the number, for the masked half. The salt lives in
  /// `flutter_secure_storage` and never in this file — a pulled database is
  /// then not enough to walk the (small) space of phone numbers back.
  TextColumn get phoneHash => text().withDefault(const Constant(''))();

  /// Last four digits, so an identity can still be read back over a counter.
  TextColumn get phoneTail => text().withDefault(const Constant(''))();

  TextColumn get code => text().withDefault(const Constant(''))();

  /// The whole `memberJson` payload, stored as it arrived. Parsed back through
  /// the ordinary `MemberDto.fromJson`, so an offline member and an online one
  /// are the same object to every screen above.
  TextColumn get payloadJson => text()();

  /// When the host said this was true. **Every stale figure renders with it**
  /// — a stamped number a cashier can caveat is useful; a bare one the guest
  /// photographs is what ADR-0123 was avoiding.
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The client-side store, for money it cannot send yet (ADR-0124).
///
/// A cache and a journal, never a source of truth: nothing here survives its
/// chain draining, and the host's answer replaces it. Belongs to the **device**,
/// not the session — handsets are shared and a backlog must outlive a handover.
///
/// Since ADR-0129 it also holds the [[Salinan pelanggan]] — still a cache, and
/// still never a source: the host's directory is the directory.
/// The photo a queued [[Pengeluaran kunjungan]] is waiting to post (ADR-0130).
///
/// Here rather than in the [[Antrean kirim]] itself because that queue is a
/// **prefs blob**, loaded synchronously at boot: a base64 JPEG per queued
/// expense would put megabytes in a string parsed on every launch. This
/// database already exists for exactly this — money the client cannot send yet
/// (ADR-0124).
///
/// Keyed by the intent id, which is also the expense id and the idempotency
/// key. The row is deleted when the intent drains, so it cannot orphan.
class QueuedPhotos extends Table {
  TextColumn get intentId => text()();
  BlobColumn get bytes => blob()();
  @override
  Set<Column> get primaryKey => {intentId};
}

@DriftDatabase(
  tables: [
    SettlementEvents,
    CachedBills,
    CachedPayable,
    CachedMembers,
    QueuedPhotos,
  ],
)
class ClientDb extends _$ClientDb {
  ClientDb(super.e);

  /// In-memory, for tests.
  ClientDb.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 4;

  /// Drift's default `onUpgrade` throws, so a bump without this bricks every
  /// till that already carries a journal — which is exactly the device this
  /// store exists for.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2 && to >= 2) await m.createTable(cachedPayable);
      if (from < 3 && to >= 3) {
        await m.createTable(cachedMembers);
        // Prefix search runs against both, and the masked half only ever has
        // the hash — an exact match, but indexed the same way.
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_cached_members_name '
          'ON cached_members (name)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_cached_members_phone '
          'ON cached_members (phone)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_cached_members_hash '
          'ON cached_members (phone_hash)',
        );
      }
      // ADR-0130 — a queued expense's photo, which the prefs-backed queue
      // cannot carry.
      if (from < 4 && to >= 4) await m.createTable(queuedPhotos);
    },
  );

  /// Opened lazily so the provider that holds it can be synchronous — the
  /// journal must exist from the first frame, and a captured payment in the
  /// frames before the file resolves would otherwise die with a rebuilt
  /// notifier (the failure ADR-0090's queue documents on prefs).
  ClientDb.lazy()
    : super(
        LazyDatabase(() async {
          final dir = await getApplicationSupportDirectory();
          final file = File(p.join(dir.path, 'satset_client.sqlite'));
          return NativeDatabase.createInBackground(
            file,
            setup: (db) => db.execute('PRAGMA journal_mode=WAL;'),
          );
        }),
      );
}
