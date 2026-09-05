import 'dart:convert';
import 'package:satset/core/time/sat_clock.dart';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:satset/domain/models/user.dart' show avatarColorPalette;

import 'package:satset/server/guest/guest_code.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Roles,
    Zones,
    VenueTables,
    Visits,
    MenuCategories,
    MenuItems,
    MenuTags,
    Tickets,
    Sessions,
    Devices,
    Idempotency,
    AuditEntries,
    VenueSettings,
    Printers,
    TableSessions,
    TableSessionTickets,
    TableSessionCourses,
    Reservations,
    Receipts,
    ReceiptLines,
    Payments,
    TableSessionReceipts,
    TableSessionReceiptLines,
    TableSessionPayments,
    VisitExpenses,
    VisitExpenseCategories,
    DiscountPresets,
    Discounts,
    TableSessionDiscounts,
    DailyCounters,
    Ingredients,
    RecipeLines,
    StockMovements,
    StockCounts,
    StockCountLines,
    CashEntries,
    CashBoxes,
    CashCategories,
    Members,
    MemberTombstones,
    MemberPoints,
    MemberDebts,
    Shifts,
    DemoStates,
    GuestSessions,
    GuestOrders,
    GuestOrderLines,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  // 41 is the Indonesian menu-tag code fix; 42 is the cashier pass. The two
  // were developed in parallel and both reached for 41 — resolved in favour of
  // main, because a device that had already taken 41 would otherwise skip the
  // cashier migration silently and run against a schema with no `channel`, no
  // `prepaid` and a NOT NULL `receipt_id`.
  //
  // 43 is the venue audit log, which hit the same collision against 42 and is
  // resolved the same way and for the same reason: a device that had already
  // taken 42 as the cashier pass would never run the audit migration, and
  // every read of the log would fail on a missing `amount_cents`.
  // 46 adds foreign-key lookup indexes only — see _createLookupIndexes. No
  // schema shape change, so it is the one migration in this file that cannot
  // corrupt a device which took the number in parallel.
  int get schemaVersion => 75;

  /// The cap sums a visit's expenses on every capture, inside the transaction
  /// that writes the next one (ADR-0100), so the lookup is on the hot path of
  /// the one guard this ledger has.
  Future<void> _createVisitExpenseIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_visit_expenses_visit '
      'ON visit_expenses(visit_id)',
    );
  }

  /// At most one discount per target — one bill discount per visit (ADR-0070),
  /// one whole-order discount per receipt, one line discount per line: the
  /// ADR-0037 no-stacking rule, enforced in the schema rather than in route
  /// code. Drift cannot express partial indexes, so they are raw SQL and must be
  /// created on both fresh and upgraded databases.
  Future<void> _createDiscountIndexes() async {
    // One order discount per *source*, not per receipt (ADR-0118) — the same
    // move ADR-0094 made one level up, for the same reason. With the member's
    // tier discount and a redemption now applied against the
    // [[Pemilik struk]]'s own receipt, a receipt_id-only index would make a
    // cashier's manual promo and a member discount contend for one slot, and
    // the exclusive version is the one a guest experiences as being punished
    // for membership. The pre-v66 index (receipt_id alone) is dropped in the
    // v66 branch — leaving it would keep the three from coexisting.
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_discounts_order_uniq '
      'ON discounts (receipt_id, source) WHERE receipt_id IS NOT NULL '
      'AND ticket_id IS NULL',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_discounts_line_uniq '
      'ON discounts (receipt_id, ticket_id, source) '
      'WHERE ticket_id IS NOT NULL',
    );
    // One bill discount per *source*, not per visit (ADR-0094). A cashier's
    // promo, the member discount and a redemption each hold their own slot;
    // none can be applied twice. The pre-v51 index (visit_id alone) is dropped
    // in the v51 migration — leaving it would keep the three from coexisting.
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_discounts_bill_source_uniq '
      'ON discounts (visit_id, source) WHERE receipt_id IS NULL '
      'AND visit_id IS NOT NULL',
    );
  }

  /// The phone number **is** the member (ADR-0092), so uniqueness is a schema
  /// fact rather than a route-code convention. Raw SQL because it is partial:
  /// a blank phone should never collide with another blank one, though the
  /// enroll route refuses one anyway.
  Future<void> _createGuestIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_venue_tables_guest_code '
      "ON venue_tables(guest_code) WHERE guest_code <> ''",
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_guest_orders_status '
      'ON guest_orders(status, submitted_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_guest_orders_session '
      'ON guest_orders(session_id, submitted_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_guest_order_lines_order '
      'ON guest_order_lines(order_id)',
    );
  }

  /// Split out from [_createMemberIndexes] because that helper is called from
  /// migration branches that run **before** v71 adds `members.updated_at` —
  /// indexing a column that does not exist yet fails the whole upgrade.
  Future<void> _createMemberSyncIndexes() async {
    // The [[Salinan pelanggan]] cursor is one integer shared by both streams
    // (ADR-0129).
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_members_rev ON members (mirror_rev)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_member_tombstones_rev '
      'ON member_tombstones (rev)',
    );
  }

  Future<void> _createMemberIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_members_phone_uniq '
      "ON members (phone) WHERE phone <> ''",
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_member_points_member '
      'ON member_points (member_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_table_sessions_member '
      'ON table_sessions (member_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tickets_member '
      'ON tickets (member_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_table_session_tickets_member '
      'ON table_session_tickets (member_id)',
    );
    // Every [[Piutang]] read is "this member's ledger, oldest first" — the
    // balance sums it and the FIFO ageing walk needs it ordered. ADR-0098.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_member_debts_member '
      'ON member_debts (member_id, at)',
    );
    // Reversal looks a charge up by the payment that raised it, which is the
    // only join that survives bill close.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_member_debts_payment '
      'ON member_debts (payment_id)',
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // Every branch is gated on both ends: `from < N` because the venue has
    // not had it yet, and `to >= N` because it was asked for. In production
    // `to` is always [schemaVersion], so the upper bound never changes what
    // runs — it exists so `test/schema_migration_test.dart` can replay one
    // branch at a time. Without it a fixture for an early transform has to
    // survive every later branch, including the v27 one that deliberately
    // wipes transactional data, and there is no version of that test which
    // asserts anything.
    onUpgrade: (m, from, to) async {
      if (from < 2 && to >= 2) {
        // Idempotent: a previous failed migration may have already
        // added one or both columns before crashing. Tolerate the
        // "duplicate column" SQL error on re-run.
        await _safeAddColumn('email');
        await _safeAddColumn('password_hash');
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique '
          'ON users(email) WHERE email IS NOT NULL',
        );
      }
      if (from < 3 && to >= 3) {
        await _safeDropColumn('on_duty');
      }
      if (from < 4 && to >= 4) {
        await _safeAddColumn('avatar_color_hex', type: 'INTEGER');
        await _backfillAvatarColors();
      }
      if (from < 5 && to >= 5) {
        await _safeAddColumnOn('venue_tables', 'locked_by', type: 'TEXT');
        await _safeAddColumnOn('venue_tables', 'locked_by_name', type: 'TEXT');
        await _safeAddColumnOn('venue_tables', 'locked_at', type: 'INTEGER');
        await _safeAddColumnOn(
          'venue_tables',
          'lock_expires_at',
          type: 'INTEGER',
        );
      }
      if (from < 6 && to >= 6) {
        await _safeAddColumnOn('venue_tables', 'opened_at', type: 'INTEGER');
      }
      if (from < 7 && to >= 7) {
        // Wipe stale demo table + ticket seed; the app now requires
        // tables to be created via the admin floor editor.
        await customStatement('DELETE FROM tickets');
        await customStatement('DELETE FROM venue_tables');
      }
      if (from < 8 && to >= 8) {
        await _safeAddColumnOn(
          'venue_tables',
          'capacity',
          type: 'INTEGER NOT NULL DEFAULT 2',
        );
        // Pre-v8 `pax` doubled as seat count (admin floor labelled it
        // "Kapasitas kursi"). Promote it to the new capacity column and
        // reset pax to 1 so the stepper has headroom on existing rows.
        await customStatement(
          'UPDATE venue_tables SET capacity = pax WHERE pax > capacity',
        );
        await customStatement('UPDATE venue_tables SET pax = 1 WHERE pax > 1');
      }
      if (from < 9 && to >= 9) {
        await m.createTable(venueSettings);
        await customStatement(
          "INSERT OR IGNORE INTO venue_settings(id) VALUES('default')",
        );
      }
      if (from < 10 && to >= 10) {
        await _safeAddColumnOn(
          'venue_settings',
          'display_name',
          type: "TEXT NOT NULL DEFAULT 'Warung Sebelah'",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'legal_name',
          type: "TEXT NOT NULL DEFAULT ''",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'address',
          type: "TEXT NOT NULL DEFAULT ''",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'phone',
          type: "TEXT NOT NULL DEFAULT ''",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'receipt_header',
          type: "TEXT NOT NULL DEFAULT ''",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'receipt_footer',
          type: "TEXT NOT NULL DEFAULT ''",
        );
      }
      if (from < 11 && to >= 11) {
        await m.createTable(printers);
      }
      if (from < 12 && to >= 12) {
        await _safeAddColumnOn('tickets', 'created_by_user_id', type: 'TEXT');
      }
      if (from < 13 && to >= 13) {
        await m.createTable(tableSessions);
        await m.createTable(tableSessionTickets);
        await m.createTable(tableSessionCourses);
      }
      if (from < 14 && to >= 14) {
        await _safeAddColumnOn(
          'menu_items',
          'cost',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn('tickets', 'void_reason_code', type: 'TEXT');
        await _safeAddColumnOn(
          'table_session_tickets',
          'void_reason_code',
          type: 'TEXT',
        );
        // Backfill cost = basePrice * 0.35 for already-seeded items so the
        // matrix has plausible margins on existing installs. New seed paths
        // set this explicitly per item.
        await customStatement(
          'UPDATE menu_items SET cost = CAST(base_price * 0.35 AS INTEGER) WHERE cost = 0',
        );
        // Backfill void_reason_code from free-text reason via substring
        // heuristic. Unknown reasons fall through to "other".
        await customStatement(
          "UPDATE tickets SET void_reason_code = CASE "
          "WHEN void_reason IS NULL THEN NULL "
          "WHEN lower(void_reason) LIKE '%stok%' OR lower(void_reason) LIKE '%habis%' THEN 'outOfStock' "
          "WHEN lower(void_reason) LIKE '%salah%' OR lower(void_reason) LIKE '%input%' THEN 'wrongOrder' "
          "WHEN lower(void_reason) LIKE '%ganti%' OR lower(void_reason) LIKE '%batal%' THEN 'customerChange' "
          "WHEN lower(void_reason) LIKE '%dapur%' OR lower(void_reason) LIKE '%gosong%' OR lower(void_reason) LIKE '%kualitas%' THEN 'kitchenError' "
          "WHEN lower(void_reason) LIKE '%comp%' OR lower(void_reason) LIKE '%gratis%' THEN 'comp' "
          "ELSE 'other' END WHERE void_reason_code IS NULL",
        );
        await customStatement(
          "UPDATE table_session_tickets SET void_reason_code = CASE "
          "WHEN void_reason IS NULL THEN NULL "
          "WHEN lower(void_reason) LIKE '%stok%' OR lower(void_reason) LIKE '%habis%' THEN 'outOfStock' "
          "WHEN lower(void_reason) LIKE '%salah%' OR lower(void_reason) LIKE '%input%' THEN 'wrongOrder' "
          "WHEN lower(void_reason) LIKE '%ganti%' OR lower(void_reason) LIKE '%batal%' THEN 'customerChange' "
          "WHEN lower(void_reason) LIKE '%dapur%' OR lower(void_reason) LIKE '%gosong%' OR lower(void_reason) LIKE '%kualitas%' THEN 'kitchenError' "
          "WHEN lower(void_reason) LIKE '%comp%' OR lower(void_reason) LIKE '%gratis%' THEN 'comp' "
          "ELSE 'other' END WHERE void_reason_code IS NULL",
        );
      }
      if (from < 15 && to >= 15) {
        await _safeAddColumnOn(
          'venue_settings',
          'business_day_start_hour',
          type: 'INTEGER NOT NULL DEFAULT 4',
        );
        await m.createTable(reservations);
      }
      if (from < 16 && to >= 16) {
        await _safeAddColumnOn('venue_tables', 'guest_name', type: 'TEXT');
        await _safeAddColumnOn('venue_tables', 'guest_notes', type: 'TEXT');
        await _safeAddColumnOn('venue_tables', 'reservation_id', type: 'TEXT');
      }
      if (from < 17 && to >= 17) {
        // Wipe seeded reservations; reservations are now created entirely
        // via the UI flow.
        await customStatement('DELETE FROM reservations');
      }
      if (from < 18 && to >= 18) {
        await _safeAddColumnOn('tickets', 'voided_by_user_id', type: 'TEXT');
        await _safeAddColumnOn(
          'table_session_tickets',
          'voided_by_user_id',
          type: 'TEXT',
        );
      }
      if (from < 19 && to >= 19) {
        await _safeDropColumnOn('menu_items', 'station');
        await _safeDropColumnOn('tickets', 'station');
        await _safeDropColumnOn('table_session_tickets', 'station');
      }
      if (from < 20 && to >= 20) {
        // Modifier groups become per-item private, embedded as JSON on the
        // item. Backfill from the now-removed shared ModifierGroups table,
        // resolving each item's id list, then drop the table + id column.
        // See docs/adr/0009-per-item-embedded-modifiers.md.
        await _safeAddColumnOn(
          'menu_items',
          'modifier_groups_json',
          type: "TEXT NOT NULL DEFAULT '[]'",
        );
        await _backfillEmbeddedModifiers();
        await _safeDropColumnOn('menu_items', 'modifier_group_ids_json');
        await customStatement('DROP TABLE IF EXISTS modifier_groups');
      }
      if (from < 21 && to >= 21) {
        // Rename auto_eighty_six_at_zero → auto_sold_out_at_zero
        // (add + copy + drop; DROP no-ops on pre-3.35 SQLite, leaving a
        // harmless dead column). See docs/adr/0010 + the "Habis" rename.
        await _safeAddColumnOn(
          'menu_items',
          'auto_sold_out_at_zero',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        final oldCols = await customSelect(
          "PRAGMA table_info('menu_items')",
        ).get();
        if (oldCols.any(
          (r) => r.read<String>('name') == 'auto_eighty_six_at_zero',
        )) {
          await customStatement(
            'UPDATE menu_items '
            'SET auto_sold_out_at_zero = auto_eighty_six_at_zero',
          );
        }
        await _safeDropColumnOn('menu_items', 'auto_eighty_six_at_zero');
        // Capability rename: rewrite the stored string in every role.
        await customStatement(
          'UPDATE roles SET capabilities_json = '
          "replace(capabilities_json, '\"toggle86\"', '\"markSoldOut\"')",
        );
        // Allergen / diet enums become data rows.
        await m.createTable(menuTags);
        await _seedMenuTags();
      }
      if (from < 22 && to >= 22) {
        // Modifier snapshots become structured objects
        // ({groupId, optionId, label, priceDelta}) on both the live and
        // closed-session ticket tables. Rewrite any legacy bare-string
        // entries in place. See docs/adr/0011-ticket-modifier-snapshot.md.
        await _migrateModifierSnapshots('tickets');
        await _migrateModifierSnapshots('table_session_tickets');
      }
      if (from < 23 && to >= 23) {
        // Ticket lifecycle timestamps for speed-of-service + a unified,
        // configurable service target. No backfill: pre-v23 rows never
        // captured ready/served events, so they stay NULL and drop out of
        // speed metrics. See docs/adr/0013.
        await _safeAddColumnOn('tickets', 'ready_at', type: 'INTEGER');
        await _safeAddColumnOn('tickets', 'served_at', type: 'INTEGER');
        await _safeAddColumnOn(
          'table_session_tickets',
          'ready_at',
          type: 'INTEGER',
        );
        await _safeAddColumnOn(
          'table_session_tickets',
          'served_at',
          type: 'INTEGER',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'prep_target_mins',
          type: 'INTEGER NOT NULL DEFAULT 15',
        );
      }
      if (from < 24 && to >= 24) {
        // Item note column renamed special_instructions → note (single
        // canonical name across all layers). Add + copy + drop; DROP
        // no-ops on pre-3.35 SQLite, leaving a harmless dead column.
        // See CONTEXT.md "Guest note / Item note".
        await _safeAddColumnOn('tickets', 'note', type: 'TEXT');
        await _safeAddColumnOn('table_session_tickets', 'note', type: 'TEXT');
        await customStatement(
          'UPDATE tickets SET note = special_instructions '
          'WHERE special_instructions IS NOT NULL',
        );
        await customStatement(
          'UPDATE table_session_tickets SET note = special_instructions '
          'WHERE special_instructions IS NOT NULL',
        );
        await _safeDropColumnOn('tickets', 'special_instructions');
        await _safeDropColumnOn(
          'table_session_tickets',
          'special_instructions',
        );
      }
      if (from < 25 && to >= 25) {
        // Menu item photos: JPEG blob + monotonic rev for cache-busting.
        // See docs/adr/0014-menu-photo-blob-and-pinned-byte-fetch.md.
        await _safeAddColumnOn('menu_items', 'photo', type: 'BLOB');
        await _safeAddColumnOn(
          'menu_items',
          'photo_rev',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 26 && to >= 26) {
        // Firebase admin identity. Per-uid local user rows are
        // auto-provisioned on first Firebase sign-in (audit identity);
        // capabilities stay local. See ADR-0015.
        await _safeAddColumn('firebase_uid');
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS users_firebase_uid_unique '
          'ON users(firebase_uid) WHERE firebase_uid IS NOT NULL',
        );
      }
      if (from < 27 && to >= 27) {
        // Demo seed is gone (ADR-0017): the server no longer auto-loads
        // sample data, admin is Firebase-only (no PIN admin), and the
        // generic restaurant set is now prompted. Wipe the old auto-seeded
        // demo content + fake report history from existing (pre-production)
        // installs so they start from the same clean state as fresh ones.
        // Preserves the shared admin role, Firebase-provisioned admin
        // users, venue settings, and menu-tag definitions.
        await customStatement('DELETE FROM table_session_courses');
        await customStatement('DELETE FROM table_session_tickets');
        await customStatement('DELETE FROM table_sessions');
        await customStatement('DELETE FROM tickets');
        await customStatement('DELETE FROM reservations');
        await customStatement('DELETE FROM venue_tables');
        await customStatement('DELETE FROM menu_items');
        await customStatement('DELETE FROM menu_categories');
        await customStatement('DELETE FROM zones');
        // Drop every PIN user (incl. the old PIN admin "Pak Nyoman");
        // Firebase-provisioned admins carry a firebase_uid and survive.
        await customStatement('DELETE FROM users WHERE firebase_uid IS NULL');
        // Keep only the shared admin role; waiter/kitchen/manager demo
        // roles are removed (the generic seed re-creates waiter/kitchen).
        await customStatement("DELETE FROM roles WHERE id != 'role-admin'");
      }
      if (from < 28 && to >= 28) {
        // Two-phase settlement + split bills (ADR-0023). New live tables
        // for receipts/payments and their session snapshots; tax/service
        // amounts added to TableSessions (netTotal redefined — pre-v28
        // rows keep netTotal == subtotal, new columns default 0).
        await m.createTable(receipts);
        await m.createTable(receiptLines);
        await m.createTable(payments);
        await m.createTable(tableSessionReceipts);
        await m.createTable(tableSessionPayments);
        await _safeAddColumnOn(
          'table_sessions',
          'service_amount',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn(
          'table_sessions',
          'tax_amount',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 29 && to >= 29) {
        // Visit decoupled from table; bill-close (cashier) snapshots, not
        // table-close (waiter). New live Visits table; visitId on tickets/
        // receipts; current_visit_id on tables; loss/cashier on sessions.
        // Backfill one Visit per currently-occupied table and stamp its
        // live tickets/receipts. See ADR-0024.
        await m.createTable(visits);
        await _safeAddColumnOn('tickets', 'visit_id', type: 'TEXT');
        await _safeAddColumnOn('receipts', 'visit_id', type: 'TEXT');
        await _safeAddColumnOn(
          'venue_tables',
          'current_visit_id',
          type: 'TEXT',
        );
        await _safeAddColumnOn(
          'venue_tables',
          'bill_closed_at',
          type: 'INTEGER',
        );
        await _safeAddColumnOn('venue_tables', 'money_state', type: 'TEXT');
        await _safeAddColumnOn(
          'table_sessions',
          'loss_amount',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn(
          'table_sessions',
          'bill_closed_by',
          type: 'TEXT',
        );
        await _backfillVisits();
      }
      if (from < 30 && to >= 30) {
        // Mandatory proof photo on non-cash payments (ADR-0025). Nullable
        // JPEG blob on live payments and their session snapshot; no backfill
        // (pre-feature payments stay photo-less).
        await _safeAddColumnOn('payments', 'photo', type: 'BLOB');
        await _safeAddColumnOn('table_session_payments', 'photo', type: 'BLOB');
      }
      if (from < 31 && to >= 31) {
        // Table-less orders: takeaway visits (ADR-0026). A `kind` column on
        // live + snapshot visits (default dineIn leaves all existing rows
        // untouched) and a daily counter table for the takeaway pickup
        // number. No backfill.
        await _safeAddColumnOn(
          'visits',
          'kind',
          type: "TEXT NOT NULL DEFAULT 'dineIn'",
        );
        await _safeAddColumnOn(
          'table_sessions',
          'kind',
          type: "TEXT NOT NULL DEFAULT 'dineIn'",
        );
        await m.createTable(dailyCounters);
      }
      if (from < 32 && to >= 32) {
        // Guest QR self-ordering (ADR-0027/0028). Venue master toggle +
        // per-table opt-in, both default off (no venue auto-exposed).
        await _safeAddColumnOn(
          'venue_settings',
          'guest_ordering_enabled',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn(
          'venue_tables',
          'guest_ordering_enabled',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 33 && to >= 33) {
        // Receipt branding block (ADR-0033): a shared logo + extra text
        // lines + a footer QR on the venue settings row. Logo is a nullable
        // JPEG blob with a monotonic rev (mirrors the menu-photo pattern).
        await _safeAddColumnOn(
          'venue_settings',
          'receipt_tagline',
          type: "TEXT NOT NULL DEFAULT ''",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'receipt_social',
          type: "TEXT NOT NULL DEFAULT ''",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'receipt_thank_you',
          type: "TEXT NOT NULL DEFAULT ''",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'receipt_qr_url',
          type: "TEXT NOT NULL DEFAULT ''",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'receipt_qr_caption',
          type: "TEXT NOT NULL DEFAULT ''",
        );
        await _safeAddColumnOn('venue_settings', 'logo', type: 'BLOB');
        await _safeAddColumnOn(
          'venue_settings',
          'logo_rev',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 34 && to >= 34) {
        // Selectable per-event alert sounds (ADR-0035). Each column holds a
        // preset id; defaults reproduce ADR-0007's original fixed cues.
        await _safeAddColumnOn(
          'venue_settings',
          'sound_new_order',
          type: "TEXT NOT NULL DEFAULT 'alert'",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'sound_ready',
          type: "TEXT NOT NULL DEFAULT 'chime'",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'sound_void',
          type: "TEXT NOT NULL DEFAULT 'alert'",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'sound_overdue',
          type: "TEXT NOT NULL DEFAULT 'alert'",
        );
      }
      if (from < 35 && to >= 35) {
        // Cashier-stage catalog discounts (ADR-0037/0038/0039).
        await m.createTable(discountPresets);
        await m.createTable(discounts);
        await m.createTable(tableSessionDiscounts);
        await _createDiscountIndexes();
        await _safeAddColumnOn(
          'receipts',
          'discount_amount',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn(
          'table_session_receipts',
          'discount_amount',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn(
          'table_sessions',
          'discount_amount',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        // ADR-0039: netTotal is frozen at its ADR-0023 meaning; settled
        // revenue moves to settledTotal. Pre-v35 rows carried no discount,
        // so backfilling settledTotal = netTotal is exact, not an estimate.
        await _safeAddColumnOn(
          'table_sessions',
          'settled_total',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'UPDATE table_sessions SET settled_total = net_total '
          'WHERE settled_total = 0',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'tax_after_discount',
          type: 'INTEGER NOT NULL DEFAULT 1',
        );
      }
      if (from < 36 && to >= 36) {
        // Ingredient-level inventory (ADR-0040/0041). Stock moves off the
        // per-item counter and onto ingredients + recipes.
        await m.createTable(ingredients);
        await m.createTable(recipeLines);
        await m.createTable(stockMovements);
        await _createStockIndexes();
        await migrateItemStockCountsToIngredients();
        await _safeDropColumnOn('menu_items', 'stock_count');
        await _safeDropColumnOn('menu_items', 'auto_sold_out_at_zero');
        await backfillInventoryCapabilities();
      }
      if (from < 37 && to >= 37) {
        // Configurable service timings (ADR-0043/0044).
        //
        // `menu_items.prep_time` existed since v1 but nothing consumed it.
        // It becomes the per-item ready target, nullable so null can mean
        // "inherit the venue default" live. Rows still sitting at the old
        // column default (5) are treated as untouched and nulled so they
        // inherit; any other value is a deliberate override and survives.
        // The generic seed uses no 5s, so seeded venues migrate cleanly.
        // TableMigration is the only supported way to relax a NOT NULL
        // column in Drift/SQLite (SQLite has no ALTER COLUMN).
        await m.alterTable(
          // ignore: experimental_member_use
          TableMigration(
            menuItems,
            columnTransformer: {
              menuItems.prepTime: const CustomExpression<int>(
                'CASE WHEN prep_time = 5 THEN NULL ELSE prep_time END',
              ),
            },
          ),
        );
        // Kitchen-ownership clock, so a held course is not born overdue.
        await _safeAddColumnOn('tickets', 'fired_at', type: 'INTEGER');
        await _safeAddColumnOn(
          'table_session_tickets',
          'fired_at',
          type: 'INTEGER',
        );
        await _safeAddColumnOn('reservations', 'seated_at', type: 'INTEGER');
        // Thresholds. Defaults are live on upgrade (both audible cues
        // included) — see ADR-0044 for the trade-off accepted here.
        await _safeAddColumnOn(
          'venue_settings',
          'pickup_target_mins',
          type: 'INTEGER NOT NULL DEFAULT 4',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'ungreeted_mins',
          type: 'INTEGER NOT NULL DEFAULT 7',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'ungreeted_escalate_mins',
          type: 'INTEGER NOT NULL DEFAULT 5',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'long_stay_mins',
          type: 'INTEGER NOT NULL DEFAULT 90',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'idle_table_mins',
          type: 'INTEGER NOT NULL DEFAULT 20',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'reservation_grace_mins',
          type: 'INTEGER NOT NULL DEFAULT 15',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'ungreeted_alert_enabled',
          type: 'INTEGER NOT NULL DEFAULT 1',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'pickup_alert_enabled',
          type: 'INTEGER NOT NULL DEFAULT 1',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'sound_ungreeted',
          type: "TEXT NOT NULL DEFAULT 'chime'",
        );
        await _safeAddColumnOn(
          'venue_settings',
          'sound_pickup',
          type: "TEXT NOT NULL DEFAULT 'chime'",
        );
      }
      if (from < 38 && to >= 38) {
        // Floor staleness (ADR-0048). Every other threshold the stale
        // banner reads already existed; only the unreviewed guest order
        // had none.
        await _safeAddColumnOn(
          'venue_settings',
          'pending_review_mins',
          type: 'INTEGER NOT NULL DEFAULT 6',
        );
      }
      if (from < 39 && to >= 39) {
        // Demo clock + seed-job state (ADR-0053).
        await m.createTable(demoStates);
      }
      if (from < 40 && to >= 40) {
        // Guest orders get their own cue (ADR-0064). Existing venues inherit
        // the doorbell default, so the cue is live the moment they upgrade —
        // a guest order arriving silently was the bug this fixes.
        await _safeAddColumnOn(
          'venue_settings',
          'sound_guest_pending',
          type: "TEXT NOT NULL DEFAULT 'doorbell'",
        );
      }
      if (from < 41 && to >= 41) {
        // Badge codes were abbreviated from the English tag id while the name
        // beside them was Indonesian — a card read `SH` for `Kerang`. Force
        // every seeded code onto the Indonesian abbreviation; an admin's own
        // rename is overwritten, which is the tradeoff taken for a consistent
        // result on every device.
        await _fixMenuTagCodes();
      }
      if (from < 42 && to >= 42) {
        // The cashier reconciliation pass (ADR-0066..0070).
        //
        // Takeaway channel + prepaid, on the live visit and frozen into its
        // snapshot so history can still tell GoFood from a walk-in.
        for (final t in ['visits', 'table_sessions']) {
          await _safeAddColumnOn(
            t,
            'channel',
            type: "TEXT NOT NULL DEFAULT ''",
          );
          await _safeAddColumnOn(
            t,
            'prepaid',
            type: 'INTEGER NOT NULL DEFAULT 0',
          );
        }
        // Bill-level discounts (ADR-0070) need `receipt_id` nullable and a
        // `visit_id` beside it. SQLite cannot drop a NOT NULL in place, so this
        // is a rebuild — `alterTable` copies every surviving column across and
        // leaves the new nullable one NULL, which is exactly right: every
        // existing row is receipt-scoped.
        // `alterTable` is the only in-tree way to relax a NOT NULL; the
        // alternative is hand-rolling the same rebuild in raw SQL.
        //
        // `newColumns` is not optional here: the rebuild copies every column of
        // the NEW schema out of the OLD table, so a column the old table has
        // never heard of has to be named or the whole migration dies on
        // `no such column`. That means **every** column added to `discounts`
        // after v42 belongs in this list, not just the one this branch was
        // written for — the list is relative to the schema as it stands today,
        // not as it stood when the branch shipped.
        //
        // `visit_id` is nullable, so it needs no transformer: every
        // pre-existing row is receipt-scoped. `source` (ADR-0094) carries a
        // `manual` default, which is likewise the right answer for every row
        // that predates the concept — the three-way contest between a
        // cashier's promo, a member preset and a redemption did not exist yet,
        // so all of them are a cashier's promo.
        await m.alterTable(
          // ignore: experimental_member_use
          TableMigration(
            discounts,
            newColumns: [discounts.visitId, discounts.source],
          ),
        );
        // The snapshot mirrors the live row, so it relaxes the same way — and
        // gains the same column, for the same reason.
        await m.alterTable(
          // ignore: experimental_member_use
          TableMigration(
            tableSessionDiscounts,
            newColumns: [tableSessionDiscounts.source],
          ),
        );
        // The order-scope index gained a `receipt_id IS NOT NULL` clause, so it
        // has to be replaced rather than left alone — CREATE IF NOT EXISTS
        // would keep the old definition and let a second bill discount through.
        for (final ix in [
          'idx_discounts_order_uniq',
          'idx_discounts_line_uniq',
          'idx_discounts_bill_uniq',
        ]) {
          await customStatement('DROP INDEX IF EXISTS $ix');
        }
        await _createDiscountIndexes();
      }
      if (from < 43 && to >= 43) {
        // The venue audit log (ADR-0072) needs two things the personal feed
        // never did: a summable amount, and attribution that survives the
        // actor being renamed or deleted.
        //
        // `amount_cents` is a magnitude — direction is implied by the type, so
        // a void and a refund both store a positive number and no tile ever
        // has to reason about a sign. Null where money is meaningless (fire,
        // table moves, staff edits).
        //
        // Name and role are snapshotted at write rather than joined at read.
        // `staffDeleted` is a real audit type, so a live join would blank the
        // attribution on every row an ex-employee ever wrote — the one thing
        // an integrity log may not do. Rows written before this migration
        // have neither and fall back to the live join.
        await _safeAddColumnOn(
          'audit_entries',
          'amount_cents',
          type: 'INTEGER',
        );
        await _safeAddColumnOn('audit_entries', 'actor_name', type: 'TEXT');
        await _safeAddColumnOn(
          'audit_entries',
          'actor_role_name',
          type: 'TEXT',
        );
      }
      if (from < 44 && to >= 44) {
        // The sample seed absorbs the demo seed (ADR-0073). The demo clock is
        // gone, so `anchor_at` goes with it; `prompt_answered` replaces the
        // in-memory "Nanti" with a venue-wide, permanent answer.
        //
        // Any demo data an upgrading device holds is dropped outright rather
        // than migrated: its ids carry the old `demo-` tag that the new clear
        // path does not know, so leaving it in place would strand rows nothing
        // can delete. The guard means such a venue never traded for real.
        await _safeAddColumnOn(
          'demo_states',
          'prompt_answered',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeDropColumnOn('demo_states', 'anchor_at');
        for (final t in const [
          'tickets',
          'visits',
          'receipts',
          'payments',
          'stock_movements',
          'audit_entries',
          'table_sessions',
          'venue_tables',
          'zones',
        ]) {
          await customStatement("DELETE FROM $t WHERE id LIKE 'demo-%'");
        }
        await customStatement('DELETE FROM demo_states');
      }
      if (from < 45 && to >= 45) {
        // Guest QR self-ordering is gone (ADR-0080), and with it the venue
        // master switch, the per-table opt-in, the review threshold and the
        // arrival cue.
        //
        // `pendingReview` rows are deleted rather than remapped. They are
        // guest orders no waiter ever approved: never fired, never billed
        // (the bill filter excluded them by that exact status string). With
        // the enum value gone, `ticketStatusFromKey` would read them back as
        // `sent` — putting an unapproved order on a guest's bill. Deleting is
        // the only reading that stays true. Nothing references tickets by id
        // (`audit_entries` keys on `table_id`), so no row is orphaned.
        await customStatement(
          "DELETE FROM tickets WHERE status = 'pendingReview'",
        );
        await customStatement(
          "DELETE FROM table_session_tickets WHERE status = 'pendingReview'",
        );
        await _safeDropColumnOn('venue_tables', 'guest_ordering_enabled');
        await _safeDropColumnOn('venue_settings', 'guest_ordering_enabled');
        await _safeDropColumnOn('venue_settings', 'sound_guest_pending');
        await _safeDropColumnOn('venue_settings', 'pending_review_mins');
        // Token pairing is gone too (ADR-0080): /pair/auto-claim writes the
        // device row directly, so the single-use token table has no reader.
        await customStatement('DROP TABLE IF EXISTS pair_tokens');
      }
      if (from < 46 && to >= 46) {
        // Indexes only — no column or table changes, so this migration is safe
        // to re-run and safe to reach a device that skipped intermediate
        // versions. `IF NOT EXISTS` throughout.
        await _createLookupIndexes();
      }
      if (from < 47 && to >= 47) {
        // An audit event is structured, not a sentence (ADR-0085). `kind` says
        // which sentence the row is, `params` holds the values that fill it;
        // the words are composed at read time in the reader's language.
        //
        // **No backfill.** Existing rows keep their `title` and render from it,
        // in Indonesian, forever. Parsing a year of hand-written prose back
        // into fields would be guessing, and a wrong guess on an integrity log
        // is worse than a row that is honestly stuck in one language.
        await _safeAddColumnOn('audit_entries', 'kind', type: 'TEXT');
        await _safeAddColumnOn('audit_entries', 'params', type: 'TEXT');
        // Split-bill part labels were the same bug in miniature: `Bagian 1/3`
        // stored as prose. New parts store the bare `1/3` and are composed at
        // read time.
        //
        // These *are* rewritten, unlike the audit rows above, because stripping
        // a fixed prefix is mechanical rather than a guess — the numbers were
        // always the whole content. Anything that does not match keeps its text
        // and passes through the renderer verbatim.
        await customStatement(
          "UPDATE receipts SET label = REPLACE(label, 'Bagian ', '') "
          "WHERE label LIKE 'Bagian %'",
        );
        await customStatement(
          "UPDATE table_session_receipts SET label = REPLACE(label, 'Bagian ', '') "
          "WHERE label LIKE 'Bagian %'",
        );
      }
      if (from < 48 && to >= 48) {
        // A proof photo is reached from the audit trail, not the reports card
        // (ADR-0086). The column is the reference *and* the has-photo flag —
        // it is written only when an image exists.
        //
        // **No backfill.** A pre-v48 payment that closed had its id regenerated
        // on the way into history, so there is nothing left to point at; the
        // photo is still on the bill it belongs to. Existing rows stay null and
        // simply show no indicator.
        await _safeAddColumnOn('audit_entries', 'payment_id', type: 'TEXT');
      }
      if (from < 49 && to >= 49) {
        // The petty cash box (§Kas kecil). A new table, so nothing to backfill
        // and nothing to migrate: an upgrading venue starts at a balance of
        // zero, which is the honest answer — the app has never known what was
        // in the box.
        await m.createTable(cashEntries);
      }
      if (from < 50 && to >= 50) {
        // An offline order is an intent, not a row (ADR-0090). Both columns
        // stay null for every line the venue has ever taken, and for every
        // ordinary line it takes from here — they are written only when a
        // terputus handset delivers a backlog, which is exactly why no backfill
        // is possible or wanted: before this version, no such line existed.
        await _safeAddColumnOn('tickets', 'captured_at', type: 'INTEGER');
        await _safeAddColumnOn('tickets', 'replayed_by_user_id', type: 'TEXT');
      }
      if (from < 51 && to >= 51) {
        // Membership (ADR-0091..0095). Two new tables, so nothing to backfill:
        // an upgrading venue starts with an empty directory, which is the
        // honest answer — the app has never known who its regulars are.
        await m.createTable(members);
        await m.createTable(memberPoints);

        // The member rides the visit and freezes into history with it. Both
        // stay null for every visit ever taken, and for every non-member visit
        // taken from here.
        await _safeAddColumnOn('visits', 'member_id', type: 'TEXT');
        await _safeAddColumnOn('table_sessions', 'member_id', type: 'TEXT');
        await _safeAddColumnOn('reservations', 'member_id', type: 'TEXT');

        // A bill discount gains its source (ADR-0094). Every existing row is a
        // cashier's promo, which is exactly what `manual` means, so the column
        // default backfills correctly with no UPDATE.
        await _safeAddColumnOn(
          'discounts',
          'source',
          type: "TEXT NOT NULL DEFAULT 'manual'",
        );
        await _safeAddColumnOn(
          'table_session_discounts',
          'source',
          type: "TEXT NOT NULL DEFAULT 'manual'",
        );

        // The old one-per-visit index must go before the new one can mean
        // anything — with both present a member discount could never coexist
        // with a promo, which is the whole point of ADR-0094.
        await customStatement('DROP INDEX IF EXISTS idx_discounts_bill_uniq');
        await _createDiscountIndexes();
        await _createMemberIndexes();

        // Every membership setting is off or null by default, so an upgraded
        // venue looks and behaves exactly as it did until an owner opts in.
        await _safeAddColumnOn(
          'venue_settings',
          'members_enabled',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'member_points_enabled',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'member_punch_enabled',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn('venue_settings', 'member_preset_id');
        await _safeAddColumnOn(
          'venue_settings',
          'member_earn_per_thousand',
          type: 'INTEGER NOT NULL DEFAULT 1',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'member_point_value',
          type: 'INTEGER NOT NULL DEFAULT 1000',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'member_redeem_min',
          type: 'INTEGER NOT NULL DEFAULT 10',
        );
        await _safeAddColumnOn('venue_settings', 'member_punch_item_id');
        await _safeAddColumnOn(
          'venue_settings',
          'member_punch_target',
          type: 'INTEGER NOT NULL DEFAULT 10',
        );
      }
      // One arm at 54 for two shapes that were developed in parallel, and it
      // is deliberately not two arms at 52 and 53. Both numbers were handed
      // out twice — the opname document took 52 on one branch while the shifts
      // table took 52 and then 53 on another — so a device that ran either
      // lineage now sits at a version whose arms it has not all seen, with no
      // arm left to run and every read of the missing table 500ing forever.
      // 54 re-checks both. The checks inside are what make re-running them
      // harmless, which is also why a version number is never trusted as
      // evidence that a table exists.
      if (from < 54 && to >= 54) {
        await _ensureStockCountTables(m);
        await _ensureShiftsTable(m);
      }
      // [[Piutang]] — the member debt ledger (ADR-0098). Guarded the same way
      // 54 is: a version number is evidence of nothing, so the table check and
      // every column add are re-runnable.
      if (from < 55 && to >= 55) {
        if (!await _hasTable('member_debts')) {
          await m.createTable(memberDebts);
        }
        await _createMemberIndexes();
        await _safeAddColumnOn('members', 'debt_limit', type: 'INTEGER');
        await _safeAddColumnOn(
          'venue_settings',
          'member_debt_enabled',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        // Both limits land at 0 on an upgrade, which means "no tab" — an
        // existing venue must not wake up having extended credit to everyone
        // already enrolled.
        await _safeAddColumnOn(
          'venue_settings',
          'member_debt_limit',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'member_debt_overdue_days',
          type: 'INTEGER NOT NULL DEFAULT 30',
        );
      }

      // v56 — [[Pesan mandiri]] returns as an intent, not a ticket (ADR-0105).
      if (from < 56 && to >= 56) {
        if (!await _hasTable('guest_sessions')) {
          await m.createTable(guestSessions);
        }
        if (!await _hasTable('guest_orders')) {
          await m.createTable(guestOrders);
        }
        if (!await _hasTable('guest_order_lines')) {
          await m.createTable(guestOrderLines);
        }
        await _safeAddColumnOn(
          'venue_tables',
          'guest_ordering_enabled',
          type: 'INTEGER NOT NULL DEFAULT 1',
        );
        await _safeAddColumnOn(
          'venue_tables',
          'guest_code',
          type: "TEXT NOT NULL DEFAULT ''",
        );
        await _safeAddColumnOn(
          'menu_items',
          'guest_visible',
          type: 'INTEGER NOT NULL DEFAULT 1',
        );
        await _safeAddColumnOn(
          'menu_items',
          'guest_featured',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn(
          'menu_items',
          'guest_stock_override',
          type: "TEXT NOT NULL DEFAULT 'auto'",
        );
        await _safeAddColumnOn(
          'menu_items',
          'guest_override_at',
          type: 'INTEGER',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'guest_ordering_enabled',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'guest_note_enabled',
          type: 'INTEGER NOT NULL DEFAULT 1',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'guest_hours_start_min',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'guest_hours_end_min',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'guest_max_items',
          type: 'INTEGER NOT NULL DEFAULT 20',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'guest_session_hours',
          type: 'INTEGER NOT NULL DEFAULT 4',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'sound_guest_pending',
          type: 'TEXT',
        );
        // After the columns, never before: the unique index is *on*
        // `venue_tables.guest_code`, so creating it first fails the whole
        // upgrade with "no such column" on any venue that has traded.
        await _createGuestIndexes();
        // Every existing table needs a code or its QR cannot be printed. The
        // default is '' and a blank code resolves to nothing, so mint one here
        // rather than leaving the floor half-scannable.
        final rows = await customSelect(
          "SELECT id FROM venue_tables WHERE guest_code = ''",
        ).get();
        for (final r in rows) {
          await customStatement(
            'UPDATE venue_tables SET guest_code = ? WHERE id = ?',
            [mintGuestCode(), r.read<String>('id')],
          );
        }
      }

      // v57 — an item may need a human to check an ID before it reaches the
      // bar. Defaults false on every existing row and is deliberately **not**
      // backfilled by category: a venue's category names are its own, and
      // guessing which of them mean alcohol is how a soft drink acquires an
      // age check nobody asked for. The owner ticks the boxes once.
      if (from < 57 && to >= 57) {
        await _safeAddColumnOn(
          'menu_items',
          'alcohol',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 58 && to >= 58) {
        // NULL, not '': entitlement is cloud-owned and nothing has mirrored yet
        // at migration time. NULL reads as entitled, so an existing venue keeps
        // every feature it was using until its own venue doc says otherwise —
        // and a venue that genuinely holds no module records that as `''`,
        // which is a different answer. See ADR-0107.
        await _safeAddColumnOn('venue_settings', 'modules', type: 'TEXT');
      }
      if (from < 59 && to >= 59) {
        // Par level: the top-up target the shopping list subtracts from.
        // Nullable — an ingredient nobody stocks to a par has no shortfall.
        await _safeAddColumnOn('ingredients', 'par_level', type: 'INTEGER');
      }
      if (from < 62 && to >= 62) {
        // A category's guest window ([[Jam tayang]]). Both nullable, and no
        // backfill: category names are venue-authored, and guessing which of
        // them mean breakfast is how lunch acquires an opening time.
        await _safeAddColumnOn(
          'menu_categories',
          'guest_from_min',
          type: 'INTEGER',
        );
        await _safeAddColumnOn(
          'menu_categories',
          'guest_to_min',
          type: 'INTEGER',
        );
      }
      if (from < 61 && to >= 61) {
        // The counter's own guest code (ADR-0109). Nullable and *not* minted
        // here: a code is a printed thing, and handing every existing venue one
        // at upgrade time would mean a live QR nobody chose to publish.
        await _safeAddColumnOn(
          'venue_settings',
          'counter_guest_code',
          type: 'TEXT',
        );
      }
      if (from < 60 && to >= 60) {
        // Kedai mode switches. Nullable and fail-closed: an existing venue
        // reads every switch off, which is a restaurant (ADR-0109).
        await _safeAddColumnOn(
          'venue_settings',
          'counter_config',
          type: 'TEXT',
        );
      }
      if (from < 63 && to >= 63) {
        // Repair three columns that reached upgraded venues without the
        // constraints a fresh install gets. `_safeAddColumnOn` takes a raw
        // type string, and the two guest-ordering flags were added as bare
        // `INTEGER NOT NULL DEFAULT n` — no `CHECK (x IN (0, 1))` — while
        // `sound_guest_pending` arrived without its `DEFAULT NULL`. Nothing
        // wrote a bad value (drift only ever binds 0 or 1), but a migrated
        // venue and a fresh one had different schemas, which is the thing
        // `test/schema_migration_test.dart` exists to refuse.
        //
        // SQLite cannot add a CHECK to a live column, so both tables are
        // rebuilt from the declared schema. Small tables — venue_settings
        // holds one row and venue_tables holds a floor's worth — and the
        // column sets are unchanged, so every value copies across by name.
        //
        // **A column added to `venue_settings` after v71 belongs in
        // `newColumns` here too.** The rebuild copies the *declared* schema, so
        // a column this branch has never heard of is selected out of a table
        // that predates it — which fails the upgrade, not the test.
        // ignore: experimental_member_use
        await m.alterTable(
          TableMigration(
            venueSettings,
            newColumns: [
              // Added by v71 (ADR-0129) and therefore absent from any database
              // this branch is rebuilding. Both carry defaults, so they need
              // no transformer — just exclusion from the copy.
              venueSettings.memberMirrorEnabled,
              venueSettings.memberMirrorSalt,
              // Added by v72 (ADR-0130), same reasoning: absent from any
              // database this branch rebuilds, carries a default, needs no
              // transformer.
              venueSettings.tableExpenseEnabled,
            ],
          ),
        );
        // ignore: experimental_member_use
        await m.alterTable(TableMigration(venueTables));
        // The rebuild drops the indexes that hung off venue_tables.
        await _createGuestIndexes();
        await _createLookupIndexes();
      }
      if (from < 64 && to >= 64) {
        // `demo_states.failed` — the seed job's verdict, persisted so it
        // survives a restart (ADR-0073 addendum). Rebuilt rather than
        // `_safeAddColumnOn`'d for the v63 reason: that helper takes a raw
        // type string, and a boolean added as a bare `INTEGER NOT NULL
        // DEFAULT 0` lacks the `CHECK ("failed" IN (0, 1))` a fresh install
        // gets — the exact schema divergence the migration test refuses.
        // One row, no indexes, and every existing column copies across by
        // name, so the rebuild is the cheap way to be provably identical.
        // ignore: experimental_member_use
        await m.alterTable(
          TableMigration(demoStates, newColumns: [demoStates.failed]),
        );
      }
      if (from < 65 && to >= 65) {
        // `tickets_item_sent` for the [[Menu populer]] rank (ADR-0113). No
        // column, no data: [_createLookupIndexes] is `IF NOT EXISTS`
        // throughout, so re-running the whole set is the cheap way to reach an
        // upgraded venue with one new index.
        await _createLookupIndexes();
      }
      if (from < 66 && to >= 66) {
        // [[Pemilik struk]] (ADR-0118): a [[Split bill]] may name a member per
        // receipt. Two nullable columns and one snapshot table — nothing is
        // backfilled, because a receipt closed before this existed had no
        // member and inventing one would put rows in a points ledger nobody
        // earned.
        //
        // The type strings must match what `createAll` writes for a fresh
        // install, which is the v63 lesson: `_safeAddColumnOn` takes a raw
        // string and nothing compares the two populations but
        // schema_migration_test.
        // `TEXT NULL`, not `TEXT`: `createAll` spells a nullable column with
        // the keyword and `ALTER TABLE ADD COLUMN` does not, so the two
        // populations end up with different DDL for the same column — the v63
        // lesson, and the only thing that catches it is
        // schema_migration_test.
        await _safeAddColumnOn('receipts', 'member_id', type: 'TEXT NULL');
        await _safeAddColumnOn(
          'table_session_receipts',
          'member_id',
          type: 'TEXT NULL',
        );
        await m.createTable(tableSessionReceiptLines);
        // Widen the order-scope uniqueness to (receipt_id, source). Same name,
        // so `IF NOT EXISTS` alone would leave the old one-slot index standing
        // — it has to go first, exactly as v51 dropped idx_discounts_bill_uniq.
        await customStatement('DROP INDEX IF EXISTS idx_discounts_order_uniq');
        await _createDiscountIndexes();
      }
      if (from < 67 && to >= 67) {
        // [[Alamat pelanggan]]: four optional fields on the member. Nothing is
        // backfilled and nothing can be — an address is a fact only the guest
        // can supply.
        //
        // `TEXT NULL`, not `TEXT`, for the v63 reason spelled out above.
        await _safeAddColumnOn('members', 'kabupaten', type: 'TEXT NULL');
        await _safeAddColumnOn('members', 'kecamatan', type: 'TEXT NULL');
        await _safeAddColumnOn('members', 'kelurahan', type: 'TEXT NULL');
        await _safeAddColumnOn('members', 'address_text', type: 'TEXT NULL');
      }

      if (from < 68 && to >= 68) {
        // A refund names the leg it unwinds (ADR-0121). Not backfilled: every
        // existing refund was written while the bill-wide tender lock still
        // stood, so its struk held one method and "which leg" had no answer
        // worth inventing.
        //
        // `TEXT NULL`, not `TEXT`, for the v63 reason spelled out above.
        await _safeAddColumnOn(
          'payments',
          'refunds_payment_id',
          type: 'TEXT NULL',
        );
      }
      if (from < 69 && to >= 69) {
        // ADR-0125. No backfill: null version preserves receipt/visit
        // attribution for already-open visits; new visits are stamped v2.
        await _safeAddColumnOn(
          'visits',
          'member_attribution_version',
          type: 'INTEGER NULL',
        );
        await _safeAddColumnOn('tickets', 'member_id', type: 'TEXT NULL');
        await _safeAddColumnOn(
          'table_sessions',
          'member_attribution_version',
          type: 'INTEGER NULL',
        );
        await _safeAddColumnOn(
          'table_session_tickets',
          'member_id',
          type: 'TEXT NULL',
        );
        await _safeAddColumnOn('payments', 'member_id', type: 'TEXT NULL');
        await _safeAddColumnOn(
          'table_session_payments',
          'member_id',
          type: 'TEXT NULL',
        );
        await customStatement('DROP INDEX IF EXISTS idx_discounts_line_uniq');
        await _createDiscountIndexes();
        await _createMemberIndexes();
      }
      if (from < 70 && to >= 70) {
        // Attribution frozen onto the opname header. No backfill: a session
        // closed before v70 keeps a null name and is decorated by the live
        // join on read, exactly as a pre-v43 audit row is.
        await _safeAddColumnOn('stock_counts', 'user_name', type: 'TEXT NULL');
        await _safeAddColumnOn(
          'stock_counts',
          'closed_by_name',
          type: 'TEXT NULL',
        );
      }
      if (from < 71 && to >= 71) {
        // ADR-0129 — the [[Salinan pelanggan]] pages off `members.updated_at`
        // and learns a departure from the tombstone table. Backfilled from
        // `joined_at` rather than left null: a first sync pulls the whole
        // directory anyway, and a real timestamp keeps the cursor monotonic
        // from the very first page.
        await _safeAddColumnOn('members', 'mirror_rev', type: 'INTEGER NULL');
        // Backfilled with a sequence rather than left null: a first sync pulls
        // the whole directory anyway, and every row holding a real position
        // keeps the cursor monotonic from the very first page.
        await customStatement(
          'UPDATE members SET mirror_rev = ('
          'SELECT COUNT(*) FROM members m2 WHERE m2.rowid <= members.rowid'
          ') WHERE mirror_rev IS NULL',
        );
        await m.createTable(memberTombstones);
        await _createMemberSyncIndexes();
        await _safeAddColumnOn(
          'venue_settings',
          'member_mirror_enabled',
          type: 'INTEGER NOT NULL DEFAULT 1',
        );
        await _safeAddColumnOn(
          'venue_settings',
          'member_mirror_salt',
          type: "TEXT NOT NULL DEFAULT ''",
        );
      }
      if (from < 72 && to >= 72) {
        // ADR-0130 — the [[Pengeluaran kunjungan]] ledger and the venue's own
        // vocabulary for it.
        await m.createTable(visitExpenses);
        await m.createTable(visitExpenseCategories);
        await _createVisitExpenseIndexes();
        // Spelled out in full rather than as a bare `INTEGER NOT NULL DEFAULT
        // 0`: `_safeAddColumnOn` takes a raw type string, and a boolean without
        // its `CHECK` leaves a migrated venue with a different schema from a
        // fresh one — the divergence v63 and v64 exist to repair, and the one
        // `test/schema_migration_test.dart` refuses.
        await _safeAddColumnOn(
          'venue_settings',
          'table_expense_enabled',
          type:
              'INTEGER NOT NULL DEFAULT 0 '
              'CHECK ("table_expense_enabled" IN (0, 1))',
        );
        await _safeAddColumnOn(
          'table_sessions',
          'expense_amount',
          type: 'INTEGER NOT NULL DEFAULT 0',
        );
        // A venue upgrading into the feature needs somewhere to file the first
        // expense; the seed owns these four the way it owns its drink
        // categories, and never rewrites them afterwards.
        await _seedVisitExpenseCategories();
      }


      if (from < 73 && to >= 73) {
        // ADR-0131 — a venue counts more than one tin. The ledger gains the box
        // it moved and the other leg of a transfer; the boxes themselves are a
        // venue-authored catalogue.
        await m.createTable(cashBoxes);
        await _seedCashBoxes();
        // Both spelled out in full for the reason the v72 branch gives: a raw
        // type string here must match what a fresh install declares, or the two
        // populations diverge and the schema harness refuses.
        await _safeAddColumnOn(
          'cash_entries',
          'box_id',
          type: "TEXT NOT NULL DEFAULT 'box-main'",
        );
        // `NULL` spelled out: drift's `createAll` emits it for a nullable
        // column, so an ALTER that leaves it off gives an upgraded venue a
        // different constraint list from a fresh install — the divergence
        // `test/schema_migration_test.dart` compares and refuses.
        await _safeAddColumnOn(
          'cash_entries',
          'transfer_peer_id',
          type: 'TEXT NULL',
        );
        await _createCashIndexes();
        // Every existing row already carries `box-main` through the column
        // default; what needs saying out loud is the audit trail, whose params
        // are frozen JSON. Without this backfill a pre-v73 movement renders its
        // sentence with an empty box name — `auditText` reads a missing param
        // as '' — which is worse than the single-box screen it replaced.
        await customStatement(
          "UPDATE audit_entries "
          "SET params = json_set(COALESCE(params, '{}'), '\$.box', 'Kas Utama') "
          "WHERE type = 'cashMovement' "
          "AND json_extract(COALESCE(params, '{}'), '\$.box') IS NULL",
        );
      }

      if (from < 75 && to >= 75) {
        // ADR-0135 — a category is the venue's word, and the box owns it. The
        // five stock slugs go into *every* box under the names the deleted
        // `CashCategory` enum persisted, so an existing `cash_entries.category`
        // resolves against the `box_id` its row already carries. Nothing
        // backfills the ledger: it is append-only, and rewriting a money
        // column to satisfy an id scheme is the trade this ADR refused.
        await m.createTable(cashCategories);
        await seedCashCategories();
      }

      if (from < 74 && to >= 74) {
        // ADR-0132 — `adjustStock` and `manageRoles` become real gates. Both
        // were grantable toggles that nothing enforced, so every venue holds
        // them in whatever shape history left; grant each from the authority
        // that has been doing its job, or the upgrade *removes* access.
        await backfillRoleAndStockCapabilities();
      }
    },
    onCreate: (m) async {
      await m.createAll();
      await _createStockIndexes();
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique '
        'ON users(email) WHERE email IS NOT NULL',
      );
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS users_firebase_uid_unique '
        'ON users(firebase_uid) WHERE firebase_uid IS NOT NULL',
      );
      await _createDiscountIndexes();
      await _createVisitExpenseIndexes();
      await _createCashIndexes();
      await _createMemberIndexes();
      await _createMemberSyncIndexes();
      await _createGuestIndexes();
      await _createShiftIndexes();
      await _createLookupIndexes();
      await into(venueSettings).insertOnConflictUpdate(
        VenueSettingsCompanion.insert(
          id: 'default',
          displayName: const Value('Warung Sebelah'),
          legalName: const Value('PT Warung Sebelah Bali'),
          address: const Value('Jl. Pantai Berawa No. 17, Canggu, Bali 80361'),
          phone: const Value('+62 813 3700 2244'),
          receiptHeader: const Value('Warung Sebelah · Berawa'),
          receiptFooter: const Value('Terima kasih · Sampai jumpa lagi'),
        ),
      );
      await _seedMenuTags();
      await _seedVisitExpenseCategories();
      await _seedCashBoxes();
      await seedCashCategories();
    },
  );

  /// The venue's starting vocabulary for a [[Pengeluaran kunjungan]]
  /// (ADR-0130), so a venue that switches the feature on has somewhere to file
  /// the first one before anybody opens the settings screen.
  ///
  /// The list is venue-authored from here on: `insertOnConflictUpdate` would
  /// undo a rename on every boot, so this inserts and does nothing else. Ids
  /// are fixed, which is what makes a re-run after a half-finished migration
  /// idempotent rather than duplicating the four.
  /// Every balance is `SUM(delta)` over one box (ADR-0131), and the negative
  /// guard re-reads it inside the write transaction (ADR-0100) — so the box
  /// filter is on the hot path of the one invariant this ledger has.
  Future<void> _createCashIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cash_entries_box '
      'ON cash_entries(box_id)',
    );
  }

  /// The one box every venue starts with (ADR-0131), and the one every pre-v73
  /// row was backfilled to. Its name is venue content — renamable in a tap —
  /// which is why it is a literal here and not an ARB key.
  ///
  /// `insertOrIgnore` for the reason [_seedVisitExpenseCategories] gives: this
  /// runs on create, on the v73 upgrade and on every Server boot, and a rename
  /// must survive all three.
  Future<void> _seedCashBoxes() async {
    await into(cashBoxes).insert(
      CashBoxesCompanion.insert(id: 'box-main', name: 'Kas Utama'),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// The five stock [[Kategori kas (cash category)|categories]] (ADR-0135),
  /// seeded into **every** box that exists.
  ///
  /// The ids are the names the `CashCategory` enum persisted, which is the
  /// whole migration: a pre-v75 expense reading `category='ingredients'` finds
  /// this row under its own `box_id` and nothing had to be rewritten. The
  /// words are Indonesian literals rather than ARB keys because they are
  /// content now — the venue renames them.
  ///
  /// `insertOrIgnore` for [_seedCashBoxes]' reason: this runs on create, on the
  /// v75 upgrade, on every Server boot and on every box create, and a rename or
  /// a retirement must survive all four.
  Future<void> seedCashCategories({String? boxId}) async {
    const defaults = [
      ('ingredients', 'Belanja bahan', 0),
      ('operations', 'Operasional', 1),
      ('transport', 'Transport', 2),
      ('dailyWage', 'Upah harian', 3),
      ('other', 'Lainnya', 4),
    ];
    final boxIds = boxId != null
        ? [boxId]
        : (await select(cashBoxes).get()).map((b) => b.id).toList();
    for (final box in boxIds) {
      for (final (id, name, order) in defaults) {
        await into(cashCategories).insert(
          CashCategoriesCompanion.insert(
            boxId: box,
            id: id,
            name: name,
            sortOrder: Value(order),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }
  }

  Future<void> _seedVisitExpenseCategories() async {
    const defaults = [
      ('vexc-tissue', 'Tisu & perlengkapan', 0),
      ('vexc-courtesy', 'Pelengkap tamu', 1),
      ('vexc-errand', 'Titipan tamu', 2),
      ('vexc-other', 'Lainnya', 3),
    ];
    for (final (id, name, order) in defaults) {
      await into(visitExpenseCategories).insert(
        VisitExpenseCategoriesCompanion.insert(
          id: id,
          name: name,
          sortOrder: Value(order),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  /// Convert the legacy per-item `stock_count` into ingredients (v36, ADR-0040).
  ///
  /// Every item that was counted becomes a self-named `pcs` ingredient holding
  /// the old count, plus a 1-pcs recipe — same behaviour, new spine. Ids are
  /// derived from the item id (`ing_<id>` / `rl_<id>`) so a re-run after a
  /// half-finished migration is idempotent rather than duplicating rows.
  ///
  /// One-way, and it runs against shipped production data — hence the test.
  Future<void> migrateItemStockCountsToIngredients() async {
    final counted = await customSelect(
      'SELECT id, name, cost, stock_count FROM menu_items '
      'WHERE stock_count IS NOT NULL',
    ).get();
    for (final row in counted) {
      final itemId = row.read<String>('id');
      await customStatement(
        'INSERT OR IGNORE INTO ingredients '
        '(id, name, unit, stock_on_hand, cost_micro) VALUES (?, ?, ?, ?, ?)',
        [
          'ing_$itemId',
          row.read<String>('name'),
          'pcs',
          // milli-pcs, and micro-money per milli-pcs (see stock_unit.dart).
          row.read<int>('stock_count') * 1000,
          row.read<int>('cost') * 1000,
        ],
      );
      await customStatement(
        'INSERT OR IGNORE INTO recipe_lines '
        '(id, owner_kind, owner_id, variant_id, option_id, ingredient_id, qty) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        ['rl_$itemId', 'item', itemId, '', '', 'ing_$itemId', 1000],
      );
    }
  }

  /// Grant the v36 inventory capabilities from the nearest existing authority.
  ///
  /// A brand-new capability defaults to OFF for every existing role, which
  /// would close the `overrideStock` pressure valve at exactly the upgrade
  /// where a venue's counts are most likely to be wrong (ADR-0041). Follows the
  /// `voidItem` backfill precedent. Idempotent: skips roles already granted.
  Future<void> backfillInventoryCapabilities() async {
    Future<void> grant(String from, String to) => customStatement(
      'UPDATE roles SET capabilities_json = '
      'replace(capabilities_json, \'"$from"\', \'"$from","$to"\') '
      'WHERE capabilities_json LIKE \'%"$from"%\' '
      'AND capabilities_json NOT LIKE \'%"$to"%\'',
    );
    await grant('adjustStock', 'manageIngredients');
    await grant('markSoldOut', 'overrideStock');
  }

  /// Grant the v73 capabilities that stopped being decorative (ADR-0132).
  ///
  /// Both were toggles an owner could tick with no effect, so a venue's stored
  /// sets say nothing about who was *meant* to hold them. Enforcing them without
  /// a backfill would revoke, not restrict: every role that has been receiving
  /// stock under `manageIngredients` would lose the ledger, and every role that
  /// has been editing permissions under `manageStaff` would lose the role sheet.
  ///
  /// Grants from the nearest existing authority, the v36 shape, and idempotent
  /// for the same reason. Note the mirror: v36 granted `manageIngredients` *to*
  /// `adjustStock` holders, and this grants it back the other way, so the two
  /// populations end up equal and only a role authored **after** this migration
  /// can hold one without the other — which is the point of splitting them.
  ///
  /// A migration branch and deliberately **not** a boot-time reconcile like
  /// `_ensureAdminRole`: this repairs an upgrade once. Reconciling every boot
  /// would re-grant what an owner had just chosen to revoke.
  Future<void> backfillRoleAndStockCapabilities() async {
    Future<void> grant(String from, String to) => customStatement(
      'UPDATE roles SET capabilities_json = '
      'replace(capabilities_json, \'"$from"\', \'"$from","$to"\') '
      'WHERE capabilities_json LIKE \'%"$from"%\' '
      'AND capabilities_json NOT LIKE \'%"$to"%\'',
    );
    await grant('manageIngredients', 'adjustStock');
    await grant('manageStaff', 'manageRoles');
  }

  /// Recipe lookup is per-owner on every menu render (habis derivation), and
  /// the movement ledger is only ever read per-ingredient, newest-first.
  /// Indexes on the foreign-key columns the read paths filter and join by.
  /// SQLite creates an index for a PRIMARY KEY and a UNIQUE constraint and for
  /// nothing else — a plain `WHERE visit_id = ?` is a full table scan until one
  /// exists here, which is invisible on a fresh venue and quadratic over a
  /// season of trading.
  ///
  /// Deliberately *not* covered: `sessions.token` (already the primary key) and
  /// anything on `venue_tables` / `zones` / `users`, which are bounded at tens
  /// of rows and read entirely on most requests anyway.
  ///
  /// The three `discounts` indexes created by [_createDiscountIndexes] are
  /// **partial** (`WHERE receipt_id IS NOT NULL AND ticket_id IS NULL` and
  /// friends). SQLite will only use a partial index when the query's own WHERE
  /// implies the index predicate, which an ordinary "discounts for this
  /// receipt" read does not — hence the plain pair below alongside them.
  Future<void> _createLookupIndexes() async {
    const stmts = [
      // Live order path: lines by visit (the stable bill key, ADR-0024) and by
      // table for the legacy pre-v29 rows that still carry a null visit_id.
      'CREATE INDEX IF NOT EXISTS tickets_visit ON tickets(visit_id)',
      'CREATE INDEX IF NOT EXISTS tickets_table ON tickets(table_id)',
      // [[Menu populer]] (ADR-0113): the menu snapshot groups the last 30
      // business days by item on every refetch, and a `menuUpdated` event —
      // which a stock flip fires — is a refetch. Without this the rank costs a
      // full scan of every line the venue ever sent.
      'CREATE INDEX IF NOT EXISTS tickets_item_sent '
          'ON tickets(item_id, sent_at)',
      // Bill assembly: receipts for a visit, then everything hanging off each
      // receipt. This is the settlement screen's whole read.
      'CREATE INDEX IF NOT EXISTS receipts_visit ON receipts(visit_id)',
      'CREATE INDEX IF NOT EXISTS payments_receipt ON payments(receipt_id)',
      'CREATE INDEX IF NOT EXISTS receipt_lines_receipt '
          'ON receipt_lines(receipt_id)',
      'CREATE INDEX IF NOT EXISTS discounts_receipt ON discounts(receipt_id)',
      'CREATE INDEX IF NOT EXISTS discounts_visit ON discounts(visit_id)',
      // Immutable history: every snapshot table is read back by session.
      'CREATE INDEX IF NOT EXISTS table_session_tickets_session '
          'ON table_session_tickets(session_id)',
      'CREATE INDEX IF NOT EXISTS table_session_receipts_session '
          'ON table_session_receipts(session_id)',
      'CREATE INDEX IF NOT EXISTS table_session_payments_session '
          'ON table_session_payments(session_id)',
      'CREATE INDEX IF NOT EXISTS table_session_discounts_session '
          'ON table_session_discounts(session_id)',
      'CREATE INDEX IF NOT EXISTS table_session_courses_session '
          'ON table_session_courses(session_id)',
      // Reports scan sessions by close time; the open-session lookup filters on
      // the same column being null.
      'CREATE INDEX IF NOT EXISTS table_sessions_closed_at '
          'ON table_sessions(closed_at)',
      // Void reversal looks for a ticket's sale and its counter-entry.
      'CREATE INDEX IF NOT EXISTS stock_movements_ticket_reason '
          'ON stock_movements(ticket_id, reason)',
      // Venue audit pages on (at desc, id desc) — the composite lets SQLite
      // walk the index for the page instead of sorting the whole log to
      // return fifty rows. The own-shift feed filters actor first, then at.
      'CREATE INDEX IF NOT EXISTS audit_entries_at_id '
          'ON audit_entries(at, id)',
      'CREATE INDEX IF NOT EXISTS audit_entries_actor_at '
          'ON audit_entries(actor_user_id, at)',
    ];
    for (final s in stmts) {
      await customStatement(s);
    }
  }

  /// Create the opname document's two tables if they are missing (ADR-0096).
  ///
  /// Deliberately **no backfill**: every existing `adjust` row keeps a null
  /// `count_id`. Grouping historic rows into fabricated sessions would put a
  /// claim nobody made into an integrity-adjacent surface, so `/opname` starts
  /// empty on an upgraded venue and fills from the next count.
  ///
  /// Guarded rather than plain `createTable` for the same reason as
  /// [_ensureShiftsTable] — see the caller.
  Future<void> _ensureStockCountTables(Migrator m) async {
    if (!await _hasTable('stock_counts')) await m.createTable(stockCounts);
    if (!await _hasTable('stock_count_lines')) {
      await m.createTable(stockCountLines);
    }
    await _safeAddColumnOn('stock_movements', 'count_id', type: 'TEXT');
    await _createStockIndexes();
  }

  /// Create `shifts` if it is missing, and move any surviving `shiftStartedAt`
  /// stamp into it (ADR-0097).
  ///
  /// A shift becomes a row rather than a stamp, so the hours report has a
  /// history to read. Backfill first, drop second: whoever is mid-shift at the
  /// moment of the upgrade keeps their clock, as an open row.
  ///
  /// Written to be safe to run on a database that already has the table,
  /// because a version arm is a promise about what ran once and this one has
  /// already been broken — see the caller.
  Future<void> _ensureShiftsTable(Migrator m) async {
    if (!await _hasTable('shifts')) {
      await m.createTable(shifts);
    }
    await _createShiftIndexes();
    // Guarded: a database old enough to predate the stamp has no column to
    // read, and an unguarded SELECT would abort the whole upgrade on it.
    if (await _hasColumn('users', 'shift_started_at')) {
      await customStatement(
        "INSERT INTO shifts (id, user_id, started_at) "
        "SELECT 'mig-' || id, id, shift_started_at FROM users "
        'WHERE shift_started_at IS NOT NULL',
      );
      // Two places that can hold the same clock are two places that can
      // disagree. Tolerated if it fails: on a sqlite too old for DROP COLUMN
      // the column lingers, unreferenced by any Dart in the app.
      try {
        await customStatement('ALTER TABLE users DROP COLUMN shift_started_at');
      } catch (_) {}
    }
  }

  /// The open-shift lookup filters `user_id` then `ended_at IS NULL`; the hours
  /// report scans a date range and groups by user. One composite serves both.
  Future<void> _createShiftIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS shifts_user_started '
      'ON shifts(user_id, started_at)',
    );
  }

  Future<void> _createStockIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS recipe_lines_owner '
      'ON recipe_lines(owner_kind, owner_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS stock_movements_ingredient_at '
      'ON stock_movements(ingredient_id, at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS stock_count_lines_count '
      'ON stock_count_lines(count_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS stock_counts_started '
      'ON stock_counts(started_at)',
    );
    // A session may hold at most one line per bahan — a second count of the
    // same shelf overwrites the first rather than producing two expectations
    // that disagree.
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS stock_count_lines_uniq '
      'ON stock_count_lines(count_id, ingredient_id)',
    );
  }

  /// Default allergen / diet tags. Ids equal the legacy enum names so existing
  /// items' `allergens_json` / `dietary_json` refs stay valid with no item
  /// migration. INSERT OR IGNORE preserves any admin edits on re-run.
  Future<void> _seedMenuTags() async {
    // Codes derive from the Indonesian `name`, not the English `id` — the
    // badge on a menu card is read by Indonesian-speaking staff. `SS` (SuSu)
    // vs `SF` (SulFit) breaks the collision both words want.
    const allergens = [
      ['gluten', 'Gluten', 'GL'],
      ['nut', 'Kacang', 'KC'],
      ['dairy', 'Susu', 'SS'],
      ['shellfish', 'Kerang', 'KR'],
      ['egg', 'Telur', 'TL'],
      ['soy', 'Kedelai', 'KD'],
      ['sesame', 'Wijen', 'WJ'],
      ['sulfites', 'Sulfit', 'SF'],
      // Appended, not inserted in place: `sort_order` is the list index and
      // INSERT OR IGNORE leaves an existing install's rows alone, so slotting
      // a new tag mid-list would collide with whatever already holds that
      // index there.
      ['fish', 'Ikan', 'IK'],
    ];
    const diets = [
      ['vegetarian', 'Vegetarian', 'VG'],
      ['vegan', 'Vegan', 'VN'],
      ['glutenFree', 'Bebas gluten', 'BG'],
      ['dairyFree', 'Bebas susu', 'BS'],
      ['spicy', 'Pedas', 'PD'],
      ['halal', 'Halal', 'HL'],
      ['signature', 'Andalan', 'AD'],
    ];
    Future<void> ins(List<List<String>> rows, String kind) async {
      for (var i = 0; i < rows.length; i++) {
        await customStatement(
          'INSERT OR IGNORE INTO menu_tags(id, kind, name, code, sort_order) '
          'VALUES(?, ?, ?, ?, ?)',
          [rows[i][0], kind, rows[i][1], rows[i][2], i],
        );
      }
    }

    await ins(allergens, 'allergen');
    await ins(diets, 'diet');
  }

  /// Re-point every seeded tag's `code` at the Indonesian abbreviation (v41).
  ///
  /// `_seedMenuTags` is INSERT OR IGNORE, so it cannot correct a row that
  /// already exists — this is the paired UPDATE. Only ids the seed owns are
  /// touched; an admin-created tag keeps whatever code it was given.
  Future<void> _fixMenuTagCodes() async {
    const codes = {
      'nut': 'KC',
      'dairy': 'SS',
      'shellfish': 'KR',
      'egg': 'TL',
      'soy': 'KD',
      'sesame': 'WJ',
      'sulfites': 'SF',
      'glutenFree': 'BG',
      'dairyFree': 'BS',
    };
    for (final e in codes.entries) {
      await customStatement('UPDATE menu_tags SET code = ? WHERE id = ?', [
        e.value,
        e.key,
      ]);
    }
  }

  Future<void> _safeAddColumn(String column, {String type = 'TEXT'}) =>
      _safeAddColumnOn('users', column, type: type);

  Future<bool> _hasColumn(String table, String column) async {
    final cols = await customSelect("PRAGMA table_info('$table')").get();
    return cols.any((r) => r.read<String>('name') == column);
  }

  Future<bool> _hasTable(String table) async {
    final rows = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>(table)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<void> _safeAddColumnOn(
    String table,
    String column, {
    String type = 'TEXT',
  }) async {
    final cols = await customSelect("PRAGMA table_info('$table')").get();
    final exists = cols.any((r) => r.read<String>('name') == column);
    if (exists) return;
    await customStatement('ALTER TABLE $table ADD COLUMN $column $type');
  }

  /// Walk users with NULL avatar_color_hex and assign sequential palette
  /// colors. Recycles past the palette length so a venue with >12 staff
  /// still gets every row populated — duplicates are allowed per spec.
  Future<void> _backfillAvatarColors() async {
    final rows = await customSelect(
      'SELECT id FROM users WHERE avatar_color_hex IS NULL ORDER BY id',
    ).get();
    for (var i = 0; i < rows.length; i++) {
      final id = rows[i].read<String>('id');
      final c = avatarColorPalette[i % avatarColorPalette.length];
      await customStatement(
        'UPDATE users SET avatar_color_hex = ? WHERE id = ?',
        [c, id],
      );
    }
  }

  /// Backfill one [[Visit]] per currently-occupied table (ADR-0024). Mirrors
  /// the table's live session fields onto a new visit row, points the table at
  /// it via current_visit_id, and stamps that visit_id onto the table's live
  /// tickets + receipts so the bill keys off the visit going forward.
  Future<void> _backfillVisits() async {
    final rows = await customSelect(
      "SELECT id, label, zone_id, pax, opened_at, guest_name, guest_notes, "
      "reservation_id, last_actor_id FROM venue_tables "
      "WHERE status != 'available'",
    ).get();
    final now = SatClock.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    for (final r in rows) {
      final tableId = r.read<String>('id');
      final visitId = '$tableId-v0';
      await customStatement(
        'INSERT OR IGNORE INTO visits(id, table_id, table_label, zone_id, pax, '
        'opened_at, guest_name, guest_notes, reservation_id, last_actor_id, '
        'created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?)',
        [
          visitId,
          tableId,
          r.read<String?>('label'),
          r.read<String?>('zone_id') ?? '',
          r.read<int?>('pax') ?? 0,
          r.read<int?>('opened_at'),
          r.read<String?>('guest_name'),
          r.read<String?>('guest_notes'),
          r.read<String?>('reservation_id'),
          r.read<String?>('last_actor_id'),
          now,
        ],
      );
      await customStatement(
        'UPDATE venue_tables SET current_visit_id = ? WHERE id = ?',
        [visitId, tableId],
      );
      await customStatement(
        'UPDATE tickets SET visit_id = ? WHERE table_id = ? AND visit_id IS NULL',
        [visitId, tableId],
      );
      await customStatement(
        'UPDATE receipts SET visit_id = ? WHERE table_id = ? AND visit_id IS NULL',
        [visitId, tableId],
      );
    }
  }

  /// Resolve each item's `modifier_group_ids_json` against the shared
  /// `modifier_groups` table and write the full groups into the new
  /// `modifier_groups_json` column. Tolerant of a missing old column/table
  /// (leaves the default '[]').
  Future<void> _backfillEmbeddedModifiers() async {
    final itemCols = await customSelect(
      "PRAGMA table_info('menu_items')",
    ).get();
    final hasIds = itemCols.any(
      (r) => r.read<String>('name') == 'modifier_group_ids_json',
    );
    if (!hasIds) return;
    final groupRows = await customSelect(
      'SELECT id, name, required, multi, options_json FROM modifier_groups',
    ).get();
    final groupsById = {
      for (final g in groupRows)
        g.read<String>('id'): {
          'id': g.read<String>('id'),
          'name': g.read<String>('name'),
          'required': g.read<bool>('required'),
          'multi': g.read<bool>('multi'),
          'options': jsonDecode(g.read<String>('options_json')),
        },
    };
    final items = await customSelect(
      'SELECT id, modifier_group_ids_json FROM menu_items',
    ).get();
    for (final it in items) {
      final ids =
          (jsonDecode(it.read<String>('modifier_group_ids_json')) as List)
              .cast<String>();
      final embedded = [
        for (final id in ids)
          if (groupsById[id] != null) groupsById[id]!,
      ];
      await customStatement(
        'UPDATE menu_items SET modifier_groups_json = ? WHERE id = ?',
        [jsonEncode(embedded), it.read<String>('id')],
      );
    }
  }

  /// Rewrite legacy `modifiers_json` entries into the structured snapshot
  /// shape. A bare-string entry becomes `{groupId, optionId, label,
  /// priceDelta}`; a `"group:option"` string keeps its two parts. Entries
  /// already objects pass through untouched. Shallow — does not resolve
  /// bare ids against the (possibly edited) menu. See ADR-0011.
  Future<void> _migrateModifierSnapshots(String table) async {
    final rows = await customSelect(
      'SELECT id, modifiers_json FROM $table',
    ).get();
    for (final r in rows) {
      final id = r.read<String>('id');
      List<dynamic> decoded;
      try {
        decoded = jsonDecode(r.read<String>('modifiers_json')) as List;
      } catch (_) {
        continue;
      }
      var changed = false;
      final out = <Map<String, dynamic>>[];
      for (final e in decoded) {
        if (e is Map) {
          out.add(Map<String, dynamic>.from(e));
          continue;
        }
        changed = true;
        final s = e.toString();
        final parts = s.split(':');
        out.add(
          parts.length == 2
              ? {
                  'groupId': parts[0],
                  'optionId': parts[1],
                  'label': parts[1],
                  'priceDelta': 0,
                }
              : {'groupId': '', 'optionId': '', 'label': s, 'priceDelta': 0},
        );
      }
      if (changed) {
        await customStatement(
          'UPDATE $table SET modifiers_json = ? WHERE id = ?',
          [jsonEncode(out), id],
        );
      }
    }
  }

  Future<void> _safeDropColumn(String column) =>
      _safeDropColumnOn('users', column);

  Future<void> _safeDropColumnOn(String table, String column) async {
    final cols = await customSelect("PRAGMA table_info('$table')").get();
    final exists = cols.any((r) => r.read<String>('name') == column);
    if (!exists) return;
    // SQLite 3.35+ supports DROP COLUMN. Wrap in try so older runtimes
    // degrade to a no-op rather than blocking boot.
    try {
      await customStatement('ALTER TABLE $table DROP COLUMN $column');
    } catch (_) {}
  }

  static Future<AppDatabase> open() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'satset.sqlite'));
    final executor = NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA journal_mode=WAL;'),
    );
    return AppDatabase(executor);
  }
}
