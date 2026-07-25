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

  /// Firebase Auth uid for admin rows auto-provisioned on first Firebase
  /// sign-in. Null for PIN/demo staff. Unique when present. See
  /// docs/adr/0015-firebase-admin-auth-and-server-kill-switch.md.
  TextColumn get firebaseUid => text().nullable()();
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
  TextColumn get guestName => text().nullable()();
  TextColumn get guestNotes => text().nullable()();
  TextColumn get reservationId => text().nullable()();

  /// The live [[Visit]] currently attached to this table (null ⇒ kosong).
  /// A visit is detached at table-close (table freed for reuse) but lives on
  /// until bill-close — so the table's *current* visit is this id, never an
  /// older detached one still open on the cashier. See ADR-0024.
  TextColumn get currentVisitId => text().nullable()();

  /// Mirror of the current visit's bill-close, for the floor's **Lunas** pill:
  /// set when the cashier locks the bill while the table is still occupied
  /// (guests lingering), cleared when the table is freed/reused. Denormalised
  /// so the floor needn't subscribe to bills. See ADR-0024.
  DateTimeColumn get billClosedAt => dateTime().nullable()();

  /// Live settlement state of the current visit, denormalised for the floor's
  /// money badge: `partial` (some paid, still owing) | `paid` (fully paid, not
  /// yet locked) | null (nothing paid). `openAmount` carries the **outstanding**
  /// rupiah. Kept in sync on order/serve/void + every payment. See ADR-0024.
  TextColumn get moneyState => text().nullable()();

  /// Per-table opt-in for guest QR self-ordering (ADR-0027/0028). A table only
  /// exposes a working QR when this AND the venue master toggle
  /// (`VenueSettings.guestOrderingEnabled`) are both true. Default off.
  BoolColumn get guestOrderingEnabled =>
      boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

/// A live seating occurrence — one party from seat to bill-close. Owns the
/// visit's tickets/receipts/payments (they key off `visitId`), independent of
/// the physical table: a visit is **detached** (`tableFreedAt` set, the table
/// freed for reuse) yet stays open on the cashier until **bill-close**, which
/// snapshots it into TableSessions and deletes this row. `tableId`/`tableLabel`
/// are frozen for display after detach. See ADR-0024.
class Visits extends Table {
  TextColumn get id => text()();
  TextColumn get tableId => text()();
  TextColumn get tableLabel => text().nullable()();
  TextColumn get zoneId => text().withDefault(const Constant(''))();
  IntColumn get pax => integer().withDefault(const Constant(0))();
  DateTimeColumn get openedAt => dateTime().nullable()();
  TextColumn get guestName => text().nullable()();
  TextColumn get guestNotes => text().nullable()();
  TextColumn get reservationId => text().nullable()();
  TextColumn get lastActorId => text().nullable()();
  /// Set when the waiter frees the table (table-close / detach). Non-null ⇒
  /// the visit is detached: floor shows the table kosong, the cashier still
  /// lists this bill, flagged.
  DateTimeColumn get tableFreedAt => dateTime().nullable()();

  /// Set when the cashier closes the bill (lock). Non-null ⇒ the bill is
  /// locked and off the active cashier list. The visit is **snapshotted +
  /// deleted only when BOTH `tableFreedAt` and `billClosedAt` are set** (the
  /// second act completes the pair); whichever act lands first just stamps its
  /// timestamp and keeps the visit live. See ADR-0024.
  DateTimeColumn get billClosedAt => dateTime().nullable()();
  TextColumn get billClosedBy => text().nullable()();
  /// Outstanding written off at a "tak tertagih" bill-close (walkout). 0 for a
  /// normal Lunas close.
  IntColumn get lossAmount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  /// Visit kind: `dineIn` (table-bound, default) | `takeaway` (Bawa pulang —
  /// no table, ADR-0026). For takeaway the lifecycle reuses the two-axis model
  /// with handover ("Serahkan") in place of table-close. Drives label
  /// resolution (KDS/cashier) and the reports dine-in/takeaway split.
  TextColumn get kind => text().withDefault(const Constant('dineIn'))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Per-business-day running counters. Today only the takeaway pickup number
/// minted at takeaway-visit creation (`Bawa pulang #N`). Keyed by a
/// business-day date string (yyyy-MM-dd). See ADR-0026.
class DailyCounters extends Table {
  TextColumn get dateStr => text()();
  IntColumn get takeawayNext => integer().withDefault(const Constant(1))();
  @override
  Set<Column> get primaryKey => {dateStr};
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
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get basePrice => integer()();
  /// Cost of goods (same int-cents unit as `basePrice`). Used for margin
  /// reports + menu-engineering matrix. 0 = unknown (treated as full margin).
  IntColumn get cost => integer().withDefault(const Constant(0))();
  IntColumn get prepTime => integer().withDefault(const Constant(5))();
  TextColumn get variantsJson => text().withDefault(const Constant('[]'))();
  /// Full modifier groups embedded per-item (private, not a shared library).
  /// JSON: [{id,name,required,multi,options:[{id,name,priceDelta}]}]. See
  /// docs/adr/0009-per-item-embedded-modifiers.md.
  TextColumn get modifierGroupsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get allergensJson => text().withDefault(const Constant('[]'))();
  TextColumn get dietaryJson => text().withDefault(const Constant('[]'))();
  BoolColumn get unavailable => boolean().withDefault(const Constant(false))();
  IntColumn get stockCount => integer().nullable()();
  BoolColumn get autoSoldOutAtZero =>
      boolean().withDefault(const Constant(false))();
  /// Optional photo as a JPEG blob. Null = no photo (UI falls back to the
  /// initials avatar). Read ONLY by the photo route — never select this in
  /// the `/menu` snapshot or item upsert path; use `selectOnly` excluding it.
  /// See docs/adr/0014-menu-photo-blob-and-pinned-byte-fetch.md.
  BlobColumn get photo => blob().nullable()();
  /// Monotonic revision bumped on every photo write/clear. Rides the snapshot
  /// (the bytes do not) so clients cache-bust by `(itemId, photoRev)`.
  IntColumn get photoRev => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Admin-managed allergen / diet labels. See
/// docs/adr/0010-customizable-menu-tags.md. `kind` ∈ {allergen, diet}.
class MenuTags extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get name => text()();
  TextColumn get code => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

class Tickets extends Table {
  TextColumn get id => text()();
  TextColumn get tableId => text()();
  /// The [[Visit]] this line belongs to — the stable key the bill hangs off,
  /// independent of `tableId` (which is the visit's *current* table and is
  /// reused across visits). Stamped at create from the table's
  /// `currentVisitId`. See ADR-0024. Nullable only for pre-v29 rows.
  TextColumn get visitId => text().nullable()();
  TextColumn get itemId => text()();
  TextColumn get name => text()();
  TextColumn get variantName => text().withDefault(const Constant(''))();
  TextColumn get course => text()();
  IntColumn get qty => integer().withDefault(const Constant(1))();
  TextColumn get modifiersJson => text().withDefault(const Constant('[]'))();
  TextColumn get note => text().nullable()();
  IntColumn get price => integer()();
  TextColumn get status => text()();
  DateTimeColumn get sentAt => dateTime()();
  /// Set once, on first entry into `ready` (prep time = readyAt − sentAt).
  /// See docs/adr/0013-ticket-lifecycle-timestamps-and-service-target.md.
  DateTimeColumn get readyAt => dateTime().nullable()();
  /// Last-write, most recent `served` (pickup lag = servedAt − readyAt).
  DateTimeColumn get servedAt => dateTime().nullable()();
  TextColumn get voidReason => text().nullable()();
  /// Canonical enum slug for void/comp analytics. One of:
  /// outOfStock | wrongOrder | customerChange | kitchenError | comp | other.
  TextColumn get voidReasonCode => text().nullable()();
  TextColumn get voidApprovedBy => text().nullable()();
  TextColumn get createdByUserId => text().nullable()();
  /// User who voided this ticket. Server-stamped from the JWT on the
  /// void transition — never client-supplied. See ADR-0006.
  TextColumn get voidedByUserId => text().nullable()();
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
  /// Receipt branding block (ADR-0033) — one shared block stamped on every
  /// document. Short slogan under the venue name, plus a website/social handle
  /// line in the header.
  TextColumn get receiptTagline => text().withDefault(const Constant(''))();
  TextColumn get receiptSocial => text().withDefault(const Constant(''))();
  /// Closing sign-off (was a hardcoded "Terima kasih"). Empty ⇒ renderers fall
  /// back to "Terima kasih".
  TextColumn get receiptThankYou => text().withDefault(const Constant(''))();
  /// Footer QR (money docs only): a free-form URL + a short caption.
  TextColumn get receiptQrUrl => text().withDefault(const Constant(''))();
  TextColumn get receiptQrCaption => text().withDefault(const Constant(''))();
  /// Optional logo as a JPEG blob. Null = no logo (header is text-only). Read
  /// ONLY by the logo route — never selected into the settings JSON snapshot.
  /// Mirrors the menu-photo pattern (ADR-0014 / ADR-0033).
  BlobColumn get logo => blob().nullable()();
  /// Monotonic revision bumped on every logo write/clear. Rides the settings
  /// JSON (the bytes do not) so clients cache-bust by `logoRev`.
  IntColumn get logoRev => integer().withDefault(const Constant(0))();
  BoolColumn get taxEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get taxRateBps => integer().withDefault(const Constant(1100))();
  BoolColumn get serviceEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get serviceMode =>
      text().withDefault(const Constant('percent'))();
  IntColumn get serviceRateBps => integer().withDefault(const Constant(500))();
  IntColumn get serviceFixedAmount =>
      integer().withDefault(const Constant(0))();

  /// Where a whole-order [[Diskon (discount)]] sits in the stack (ADR-0038).
  /// `true` (default, DPP-correct): the discount reduces the base both service
  /// and tax compute from. `false`: both are computed on the gross subtotal and
  /// the discount comes off the grand total last. Line discounts are always
  /// pre-tax and ignore this flag.
  BoolColumn get taxAfterDiscount =>
      boolean().withDefault(const Constant(true))();
  /// Business-day rollover hour (0..23). Reports bucket "today" as
  /// [hour, hour+24h). Default 4 covers late-night service.
  IntColumn get businessDayStartHour =>
      integer().withDefault(const Constant(4))();

  /// Single configurable "kitchen should be ready by now" threshold (minutes).
  /// Drives BOTH the floor/audio overdue alert and the report SLA hit-rate.
  /// See docs/adr/0013-ticket-lifecycle-timestamps-and-service-target.md.
  IntColumn get prepTargetMins =>
      integer().withDefault(const Constant(15))();

  /// Venue master switch for guest QR self-ordering (ADR-0027/0028). Default
  /// OFF so shipping the feature exposes no venue automatically. When true,
  /// per-table `VenueTables.guestOrderingEnabled` controls which tables show a
  /// working QR.
  BoolColumn get guestOrderingEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Per-event alert sound choice (ADR-0035). Each holds a preset id from
  /// `alertSoundPresets` ('none' = silent). Defaults reproduce ADR-0007's
  /// original fixed cues. Venue-wide: one choice every paired device obeys.
  TextColumn get soundNewOrder => text().withDefault(const Constant('alert'))();
  TextColumn get soundReady => text().withDefault(const Constant('chime'))();
  TextColumn get soundVoid => text().withDefault(const Constant('alert'))();
  TextColumn get soundOverdue => text().withDefault(const Constant('alert'))();
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
  /// Service charge + tax applied at settlement (ADR-0023). Pre-v28 sessions
  /// carry 0 (tax/service were never applied before settlement existed).
  IntColumn get serviceAmount => integer().withDefault(const Constant(0))();
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  /// REDEFINED in ADR-0023: the total net of voids plus service and tax
  /// (`subtotal − void + service + tax`), not the old `netTotal == subtotal`.
  /// Historical pre-v28 rows still equal their subtotal.
  ///
  /// FROZEN at that formula by ADR-0039 — it deliberately does **not** learn
  /// about discounts, so its meaning never changes again. Answers "what did we
  /// ring up net of voids". For money actually collected read [settledTotal].
  IntColumn get netTotal => integer().withDefault(const Constant(0))();

  /// Total [[Diskon (discount)]] on this visit (line + whole-order, across
  /// every receipt). 0 for pre-v35 sessions. ADR-0037.
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();

  /// Money actually collected: `netTotal − discountAmount` (ADR-0039). This is
  /// the revenue figure every report and export reads. Equals [netTotal] on
  /// pre-v35 rows, which carried no discounts.
  IntColumn get settledTotal => integer().withDefault(const Constant(0))();
  IntColumn get ticketCount => integer().withDefault(const Constant(0))();
  /// Outstanding written off at bill-close as a recorded loss — a walkout /
  /// "tak tertagih" close. 0 for a normal (Lunas) close. Distinct from a comp
  /// (which zeroes a line); this is the unpaid remainder. See ADR-0024.
  IntColumn get lossAmount => integer().withDefault(const Constant(0))();
  /// Cashier (userId) who performed the bill-close. ADR-0024.
  TextColumn get billClosedBy => text().nullable()();

  /// Visit kind frozen at snapshot: `dineIn` (default) | `takeaway`. Lets
  /// reports split takeaway out of per-cover / turn-time / occupancy. ADR-0026.
  TextColumn get kind => text().withDefault(const Constant('dineIn'))();
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
  IntColumn get qty => integer().withDefault(const Constant(1))();
  TextColumn get modifiersJson => text().withDefault(const Constant('[]'))();
  TextColumn get note => text().nullable()();
  IntColumn get price => integer()();
  TextColumn get status => text()();
  DateTimeColumn get sentAt => dateTime()();
  /// Mirrors Tickets.readyAt / Tickets.servedAt at session close, so speed-of-
  /// service survives the live-ticket delete. See ADR-0013.
  DateTimeColumn get readyAt => dateTime().nullable()();
  DateTimeColumn get servedAt => dateTime().nullable()();
  TextColumn get voidReason => text().nullable()();
  /// Canonical enum slug — mirrors Tickets.voidReasonCode at session close.
  TextColumn get voidReasonCode => text().nullable()();
  TextColumn get voidApprovedBy => text().nullable()();
  TextColumn get createdByUserId => text().nullable()();
  /// Mirrors Tickets.voidedByUserId at session close.
  TextColumn get voidedByUserId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// A settleable receipt under a table's [[Bill]]. The Bill itself is implicit
/// (the table IS the bill); receipts carry `tableId`. `mode` ∈ {itemized, even}.
/// In itemized mode the receipt owns line units via ReceiptLines; in even mode
/// it carries only `total` (its equal share). `serviceAmount`/`taxAmount` are
/// computed per-receipt (service-then-tax) at settle. `status` ∈ {unpaid, paid}.
/// Live rows; deleted + snapshotted into TableSessionReceipts at close.
/// See docs/adr/0023-two-phase-settlement-and-split-bills.md.
class Receipts extends Table {
  TextColumn get id => text()();
  TextColumn get tableId => text()();
  /// The [[Visit]] this receipt settles — see Tickets.visitId. Nullable only
  /// for pre-v29 rows. ADR-0024.
  TextColumn get visitId => text().nullable()();
  TextColumn get mode => text().withDefault(const Constant('itemized'))();
  TextColumn get label => text().withDefault(const Constant(''))();
  /// Line subtotal **net of line discounts** (ADR-0038) — what the Subtotal row
  /// prints.
  IntColumn get subtotal => integer().withDefault(const Constant(0))();
  /// Total [[Diskon (discount)]] on this receipt: line discounts (already
  /// inside [subtotal]) plus the whole-order one. Reporting figure; the math
  /// reads the `discounts` rows. ADR-0037.
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();
  IntColumn get serviceAmount => integer().withDefault(const Constant(0))();
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get total => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('unpaid'))();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Owner-defined discount the [[Cashier]] may pick from — cashiers never type a
/// percentage (ADR-0037). `scope` ∈ {order, line} keeps a fixed whole-bill
/// amount off a single cheap line; `kind` ∈ {percent, fixed} mirrors
/// `VenueSettings.serviceMode`, with `value` in basis points or rupiah.
/// Hard-deleted rather than archived — safe because every applied discount
/// snapshots these values onto its `discounts` row. `active` hides a seasonal
/// preset without deleting it.
class DiscountPresets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get scope => text().withDefault(const Constant('order'))();
  TextColumn get kind => text().withDefault(const Constant('percent'))();
  IntColumn get value => integer().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

/// An applied [[Diskon (discount)]] — always receipt-scoped, at settlement only
/// (ADR-0037). `ticketId == null` ⇒ whole-order discount; set ⇒ a line discount
/// against the units *this receipt* owns.
///
/// `name`/`kind`/`value` are **snapshotted** off the preset at apply time so
/// editing or deleting a preset never rewrites settled history; `presetId` is a
/// weak reference kept only for the per-preset reporting rollup (ADR-0039).
///
/// At most one order discount per receipt and one line discount per line — see
/// the two partial unique indexes in `AppDatabase.migration`. Rows cascade with
/// their receipt, which is how `split-even` disposes of line discounts.
class Discounts extends Table {
  TextColumn get id => text()();
  TextColumn get receiptId => text()();
  /// Null ⇒ whole-order discount. Set ⇒ line discount on this ticket's units.
  TextColumn get ticketId => text().nullable()();
  /// Weak reference — the preset may be edited or deleted afterwards. Never
  /// read it to render or report a settled bill; use the snapshot below.
  TextColumn get presetId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  IntColumn get value => integer().withDefault(const Constant(0))();
  /// Resolved rupiah amount at apply time (clamped so it can never exceed its
  /// base). Persisted so history never re-derives from a rate.
  IntColumn get amount => integer().withDefault(const Constant(0))();
  /// Who applied it, and — when the applier lacked `applyDiscount` and used
  /// manager step-up — who authorised it. ADR-0037.
  TextColumn get byUserId => text().nullable()();
  TextColumn get approvedByUserId => text().nullable()();
  DateTimeColumn get at => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Qty-level assignment of a live ticket line to a [[Receipt]] (itemized mode).
/// A `qty:3` line may split across receipts as 2+1, so `qtyUnits` ≤ the ticket's
/// qty and the sum of a ticket's assigned units across receipts ≤ its qty.
class ReceiptLines extends Table {
  TextColumn get id => text()();
  TextColumn get receiptId => text()();
  TextColumn get ticketId => text()();
  IntColumn get qtyUnits => integer().withDefault(const Constant(1))();
  @override
  Set<Column> get primaryKey => {id};
}

/// A cashier-recorded manual payment attestation against a [[Receipt]] (no
/// gateway). `method` ∈ {tunai, kartu, qris, transfer, lainnya}. A refund is a
/// negative `amount` (`isRefund` true). `tenderedAmount` (cash) is informational
/// — the recorded revenue is `amount`. `cashierUserId` is server-stamped.
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get receiptId => text()();
  TextColumn get method => text()();
  IntColumn get amount => integer()();
  BoolColumn get isRefund => boolean().withDefault(const Constant(false))();
  IntColumn get tenderedAmount => integer().nullable()();
  TextColumn get cashierUserId => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get at => dateTime()();
  /// Mandatory proof photo (JPEG blob) for a non-cash payment — null for cash
  /// and pre-feature rows. Camera-shot at the till. Read ONLY by the photo
  /// route — never select in the bill/list path; use `selectOnly` excluding it.
  /// See docs/adr/0025-mandatory-non-cash-payment-proof-photo.md.
  BlobColumn get photo => blob().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Per-receipt snapshot tied to a TableSession (mirrors Receipts at close).
class TableSessionReceipts extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get receiptId => text()();
  TextColumn get mode => text().withDefault(const Constant('itemized'))();
  TextColumn get label => text().withDefault(const Constant(''))();
  IntColumn get subtotal => integer().withDefault(const Constant(0))();
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();
  IntColumn get serviceAmount => integer().withDefault(const Constant(0))();
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get total => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('unpaid'))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Per-discount snapshot tied to a TableSession (mirrors Discounts at close).
/// Keeps the individual applied rows — not just the per-receipt total — so the
/// accounting export's per-preset rollup and the reprinted money doc's named
/// `Diskon <preset>` rows still work after live rows are deleted. ADR-0039.
class TableSessionDiscounts extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get receiptId => text()();
  /// Null ⇒ whole-order discount; set ⇒ line discount.
  TextColumn get ticketId => text().nullable()();
  TextColumn get presetId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  IntColumn get value => integer().withDefault(const Constant(0))();
  IntColumn get amount => integer().withDefault(const Constant(0))();
  TextColumn get byUserId => text().nullable()();
  TextColumn get approvedByUserId => text().nullable()();
  DateTimeColumn get at => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Per-payment snapshot tied to a TableSession (mirrors Payments at close).
/// Source for the report payment-method breakdown after live rows are deleted.
class TableSessionPayments extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get receiptId => text()();
  TextColumn get method => text()();
  IntColumn get amount => integer()();
  BoolColumn get isRefund => boolean().withDefault(const Constant(false))();
  TextColumn get cashierUserId => text().nullable()();
  DateTimeColumn get at => dateTime()();
  /// Frozen copy of the live payment's proof photo (JPEG blob), carried across
  /// at bill close so immutable history is self-contained. Read ONLY by the
  /// photo route. See docs/adr/0025-mandatory-non-cash-payment-proof-photo.md.
  BlobColumn get photo => blob().nullable()();
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
