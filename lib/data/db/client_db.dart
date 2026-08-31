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

/// The client-side store, for money it cannot send yet (ADR-0124).
///
/// A cache and a journal, never a source of truth: nothing here survives its
/// chain draining, and the host's answer replaces it. Belongs to the **device**,
/// not the session — handsets are shared and a backlog must outlive a handover.
@DriftDatabase(tables: [SettlementEvents, CachedBills, CachedPayable])
class ClientDb extends _$ClientDb {
  ClientDb(super.e);

  /// In-memory, for tests.
  ClientDb.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  /// Drift's default `onUpgrade` throws, so a bump without this bricks every
  /// till that already carries a journal — which is exactly the device this
  /// store exists for.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2 && to >= 2) await m.createTable(cachedPayable);
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
