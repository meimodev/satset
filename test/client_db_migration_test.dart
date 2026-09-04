// The client database's own upgrade path (ADR-0124, widened by ADR-0129).
//
// There is no `drift_schemas/` harness on this side — that one covers the
// server — so the bump is guarded here instead, and the thing it guards is
// specific: **a device carrying uncollected money must survive the migration**.
// Drift's default `onUpgrade` throws, and this store exists precisely for the
// till that has a chain it has not drained yet.
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'package:satset/data/db/client_db.dart';

void main() {
  test('a journal written at v2 survives the bump to v3', () async {
    final dir = await Directory.systemTemp.createTemp('satset_client_db');
    final file = File(p.join(dir.path, 'client.sqlite'));

    // A v2 database, written by hand in the shape the shipped one had: the
    // three tables that existed then, `user_version = 2`, and nothing about
    // members. Constructing it through `ClientDb` would run `createAll` and
    // hand us a v3 file, which is exactly the upgrade we are trying to exercise.
    final legacy = sqlite3.open(file.path);
    legacy.execute("""
      CREATE TABLE settlement_events (
        id TEXT NOT NULL,
        visit_id TEXT NOT NULL,
        seq INTEGER NOT NULL,
        kind TEXT NOT NULL,
        payload_json TEXT NOT NULL DEFAULT '{}',
        captured_at INTEGER NOT NULL,
        actor_id TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'pending',
        fail_code TEXT,
        PRIMARY KEY (id)
      );
    """);
    legacy.execute("""
      CREATE TABLE cached_bills (
        visit_id TEXT NOT NULL,
        bill_json TEXT NOT NULL,
        fetched_at INTEGER NOT NULL,
        PRIMARY KEY (visit_id)
      );
    """);
    legacy.execute("""
      CREATE TABLE cached_payable (
        id TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        fetched_at INTEGER NOT NULL,
        PRIMARY KEY (id)
      );
    """);
    legacy.execute(
      "INSERT INTO settlement_events "
      "(id, visit_id, seq, kind, payload_json, captured_at) "
      "VALUES ('ev-1', 'v-1', 0, 'recordPayment', '{\"amount\":50000}', 1)",
    );
    legacy.execute('PRAGMA user_version = 2');
    legacy.close();

    final db = ClientDb(NativeDatabase(file));
    final events = await db.select(db.settlementEvents).get();
    expect(
      events.single.id,
      'ev-1',
      reason: 'money captured before the upgrade is still captured after it',
    );

    // And the new table arrived with the bump rather than on the next fresh
    // install.
    await db
        .into(db.cachedMembers)
        .insert(
          CachedMembersCompanion.insert(
            id: 'm-1',
            name: 'Budi',
            payloadJson: '{"id":"m-1","name":"Budi"}',
            syncedAt: DateTime.utc(2026, 9, 2, 9),
          ),
        );
    expect((await db.select(db.cachedMembers).get()).single.name, 'Budi');
    await db.close();
    await dir.delete(recursive: true);
  });

  test('a journal written at v3 survives the bump to v4', () async {
    final dir = await Directory.systemTemp.createTemp('satset_client_db_v3');
    final file = File(p.join(dir.path, 'client.sqlite'));

    // Built through `ClientDb` at the *current* version would defeat the point,
    // so the v3 shape is written by hand again — the four tables that existed
    // then, `user_version = 3`, and nothing about queued photos.
    final legacy = sqlite3.open(file.path);
    legacy.execute("""
      CREATE TABLE settlement_events (
        id TEXT NOT NULL,
        visit_id TEXT NOT NULL,
        seq INTEGER NOT NULL,
        kind TEXT NOT NULL,
        payload_json TEXT NOT NULL DEFAULT '{}',
        captured_at INTEGER NOT NULL,
        actor_id TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'pending',
        fail_code TEXT,
        PRIMARY KEY (id)
      );
    """);
    legacy.execute(
      'CREATE TABLE cached_bills (visit_id TEXT NOT NULL, '
      'bill_json TEXT NOT NULL, fetched_at INTEGER NOT NULL, '
      'PRIMARY KEY (visit_id));',
    );
    legacy.execute(
      'CREATE TABLE cached_payable (id TEXT NOT NULL, '
      'payload_json TEXT NOT NULL, fetched_at INTEGER NOT NULL, '
      'PRIMARY KEY (id));',
    );
    legacy.execute(
      'CREATE TABLE cached_members (id TEXT NOT NULL, name TEXT NOT NULL, '
      "phone TEXT NOT NULL DEFAULT '', phone_hash TEXT NOT NULL DEFAULT '', "
      "phone_tail TEXT NOT NULL DEFAULT '', code TEXT NOT NULL DEFAULT '', "
      'payload_json TEXT NOT NULL, synced_at INTEGER NOT NULL, '
      'PRIMARY KEY (id));',
    );
    legacy.execute(
      "INSERT INTO settlement_events "
      "(id, visit_id, seq, kind, payload_json, captured_at) "
      "VALUES ('ev-9', 'v-9', 0, 'recordPayment', '{\"amount\":90000}', 1)",
    );
    legacy.execute('PRAGMA user_version = 3');
    legacy.close();

    final db = ClientDb(NativeDatabase(file));
    expect(
      (await db.select(db.settlementEvents).get()).single.id,
      'ev-9',
      reason: 'money captured before the upgrade is still captured after it',
    );

    // ADR-0130's photo store arrived with the bump, not on the next fresh
    // install — a device carrying a queued expense across the upgrade would
    // otherwise drain it with no proof attached.
    await db
        .into(db.queuedPhotos)
        .insert(
          QueuedPhotosCompanion.insert(
            intentId: 'e-1',
            bytes: Uint8List.fromList([7, 7, 7]),
          ),
        );
    expect((await db.select(db.queuedPhotos).get()).single.bytes, [7, 7, 7]);
    await db.close();
    await dir.delete(recursive: true);
  });
}
