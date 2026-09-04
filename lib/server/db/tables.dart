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
  @override
  Set<Column> get primaryKey => {id};
}

/// One staff member's signed-in stretch of work — a [[Shift]].
///
/// The open shift is the row with a null [endedAt], which is why `Users` no
/// longer carries a `shiftStartedAt` stamp: two places that can hold the same
/// clock are two places that can disagree, and the history has to exist here
/// anyway for the hours report to have anything to read.
///
/// Rows are written only by `lib/server/shift.dart` — the same
/// one-writer rule `writeAudit`, `cash.dart` and `members.dart` hold, and for
/// the same reason.
class Shifts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get startedAt => dateTime()();

  /// Null while the shift is open.
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// `manual` (the staff member signed out) or `rollover` (the business-day
  /// boundary retired a shift nobody closed). **The name is persisted** — a
  /// rename orphans every row already written under the old spelling, exactly
  /// as with `AuditKind` and `CashEntryKind`.
  TextColumn get endedBy => text().nullable()();

  /// When this shift last did something auditable, read at close time rather
  /// than tracked live — stamping it per request would be a write on every
  /// authenticated call. Meaningful mainly on a `rollover` row, where it is the
  /// difference between "16 hours" and "stopped around 21:40, never confirmed".
  /// Null when the shift did nothing the audit log records, which is honest.
  DateTimeColumn get lastActivityAt => dateTime().nullable()();
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

  /// **[[Pesan mandiri]]** per-table opt-in. A venue can run self-order on the
  /// dining room and keep the bar counter staff-only (ADR-0105).
  BoolColumn get guestOrderingEnabled =>
      boolean().withDefault(const Constant(true))();

  /// The rotatable code in the guest URL (`/t/<code>`). This is the *whole*
  /// guest credential — there is no guest JWT and no guest auth scope
  /// (ADR-0105). Rotating it invalidates every printed QR for the table.
  TextColumn get guestCode => text().withDefault(const Constant(''))();
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

  /// The [[Pelanggan (member)]] this party belongs to, attached at the till any
  /// time before bill close (ADR-0093). Distinct from [guestName], which is the
  /// waiter's per-visit party label — attaching fills an empty one and never
  /// overwrites a typed one. Nullable forever: most visits are not members.
  ///
  /// A weak reference. A deleted member leaves it dangling on purpose
  /// (ADR-0092) — the visit *was* a member visit, and history does not rewrite.
  TextColumn get memberId => text().nullable()();

  /// Null marks a visit opened before ticket attribution existed. New visits
  /// use version 2 and read membership from their tickets (ADR-0125).
  IntColumn get memberAttributionVersion => integer().nullable()();

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

  /// How a takeaway order reached the venue — `bungkus` | `telepon` | `gofood`
  /// | `grab`. Empty for a dine-in visit. Provenance, not a payment method: a
  /// GoFood order can still be unpaid. Drives the cashier's channel pill, which
  /// is a takeaway's stand-in for a dine-in's zone. ADR-0066.
  TextColumn get channel => text().withDefault(const Constant(''))();

  /// The aggregator already settled this order, so there is nothing to collect.
  /// Normal for gofood/grab, impossible for a walk-in bungkus — but not derived
  /// from [channel], because an aggregator order can be cash-on-delivery.
  BoolColumn get prepaid => boolean().withDefault(const Constant(false))();
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

  /// The **[[Jam tayang]]** of a whole category on the guest menu: minutes from
  /// midnight, inclusive start, exclusive end. Both null — the default — means
  /// always. A window is deliberately per *category* and not per item: a cafe
  /// decides that breakfast stops at eleven, not that each of nine breakfast
  /// items stops at eleven, and a per-item window is nine chances to forget one.
  ///
  /// `from > to` **wraps midnight**, which is what a late-night menu is.
  /// `from == to` would be an empty window with no way to express "always", so
  /// it is rejected at the route rather than stored.
  ///
  /// Outside its window an item reads sold out, exactly as an empty ingredient
  /// does — it is not hidden. A guest who cannot find yesterday's breakfast at
  /// all assumes the cafe stopped selling it; one who sees it greyed knows to
  /// come back in the morning. A same-day `forceIn` still beats the window,
  /// because a human saying "we have it" outranks a clock, same as it outranks
  /// the stock ledger.
  IntColumn get guestFromMin => integer().nullable()();
  IntColumn get guestToMin => integer().nullable()();

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

  /// Per-item ready target in minutes ("Waktu siap"). **Null = inherit** the
  /// venue default (`VenueSettings.prepTargetMins`) live — so moving the venue
  /// default shifts every non-overridden item. A value is a deliberate
  /// per-item override. Resolved per line, then rolled up to the course (the
  /// unit of "late"). See docs/adr/0043-per-item-ready-target-and-course-lateness.md.
  IntColumn get prepTime => integer().nullable()();
  TextColumn get variantsJson => text().withDefault(const Constant('[]'))();

  /// Full modifier groups embedded per-item (private, not a shared library).
  /// JSON: [{id,name,required,multi,options:[{id,name,priceDelta}]}]. See
  /// docs/adr/0009-per-item-embedded-modifiers.md.
  TextColumn get modifierGroupsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get allergensJson => text().withDefault(const Constant('[]'))();
  TextColumn get dietaryJson => text().withDefault(const Constant('[]'))();

  /// Manual "ditandai habis" toggle. Auto sold-out is **derived** from
  /// ingredient stock at read time and is never stored — v36 dropped the old
  /// `stock_count` / `auto_sold_out_at_zero` columns (ADR-0040).
  BoolColumn get unavailable => boolean().withDefault(const Constant(false))();

  /// Optional photo as a JPEG blob. Null = no photo (UI falls back to the
  /// initials avatar). Read ONLY by the photo route — never select this in
  /// the `/menu` snapshot or item upsert path; use `selectOnly` excluding it.
  /// See docs/adr/0014-menu-photo-blob-and-pinned-byte-fetch.md.
  BlobColumn get photo => blob().nullable()();

  /// Monotonic revision bumped on every photo write/clear. Rides the snapshot
  /// (the bytes do not) so clients cache-bust by `(itemId, photoRev)`.
  IntColumn get photoRev => integer().withDefault(const Constant(0))();

  /// Contains alcohol, so a human must see the guest before it reaches the
  /// bar. The one thing on a guest order that cannot be delegated to the
  /// phone that placed it — self-order can take the order, but it cannot
  /// check an ID. Set from the [[Menu tamu]] tab, seeded by category.
  BoolColumn get alcohol => boolean().withDefault(const Constant(false))();

  /// **[[Menu tamu]]** (ADR-0105). Hidden items still sell at the till; this
  /// only governs what the guest phone page lists.
  BoolColumn get guestVisible => boolean().withDefault(const Constant(true))();
  BoolColumn get guestFeatured =>
      boolean().withDefault(const Constant(false))();

  /// `auto` | `forceIn` | `forceOut`. **Persisted names** — renaming orphans
  /// every row. `auto` reads the live recipe/stock derivation; the two forces
  /// are a shift-long manual call and are cleared at the business-day
  /// rollover, which is what `guestOverrideAt` is for.
  TextColumn get guestStockOverride =>
      text().withDefault(const Constant('auto'))();
  DateTimeColumn get guestOverrideAt => dateTime().nullable()();
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

  /// The member who owns this order line. Nullable means deliberately
  /// unassigned; payment ownership is recorded separately (ADR-0125).
  TextColumn get memberId => text().nullable()();
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

  /// When the waiter keyed this line at the table, if that is not when the
  /// kitchen received it. Null on every ordinary send — the two moments are the
  /// same one. Non-null only for a line captured while the handset was terputus
  /// and delivered later: `sentAt` stays the moment the host accepted it, so no
  /// KDS clock, ticker or alert threshold is fooled into calling the kitchen
  /// late for food it had not received. This column is the truth for the audit
  /// trail and for telling a guest why their food is behind. See ADR-0090.
  DateTimeColumn get capturedAt => dateTime().nullable()();

  /// Who drained the queue this line arrived on, when that is not its author.
  /// Handsets are shared, so a backlog outlives the session that captured it
  /// (ADR-0065); `createdByUserId` keeps naming the waiter who took the order
  /// (ADR-0056 never backfills authorship) and this names whoever carried it
  /// in. Null on every ordinary send. See ADR-0090.
  TextColumn get replayedByUserId => text().nullable()();

  /// When the kitchen actually started owning this line. Null on a normal
  /// send (the clock starts at `sentAt`); stamped on the `held → sent` fire
  /// so a course held 40 minutes is not born overdue. `sentAt` keeps meaning
  /// "guest ordered". Prep clock = `readyAt − (firedAt ?? sentAt)`.
  /// See docs/adr/0043-per-item-ready-target-and-course-lateness.md.
  DateTimeColumn get firedAt => dateTime().nullable()();

  /// Set once, on first entry into `ready`
  /// (prep time = readyAt − (firedAt ?? sentAt)).
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
  TextColumn get serviceMode => text().withDefault(const Constant('percent'))();
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

  /// Venue-wide **default** ready target (minutes) — "Target siap (default
  /// semua menu)". Every menu item with a null `prepTime` inherits this live,
  /// so changing it shifts the whole floor. Still drives the report SLA, now
  /// measured per course. See ADR-0013 (amended by ADR-0043).
  IntColumn get prepTargetMins => integer().withDefault(const Constant(15))();

  /// "Menunggu diantar" — how long food may sit at the pass (`readyAt →
  /// servedAt`) before the waiters are cued. See ADR-0044.
  IntColumn get pickupTargetMins => integer().withDefault(const Constant(4))();

  /// "Belum dilayani" — a seated table with no line sent yet. First cue goes
  /// to the seating waiter at `ungreetedMins`; escalates floor-wide a further
  /// `ungreetedEscalateMins` later. See ADR-0044.
  IntColumn get ungreetedMins => integer().withDefault(const Constant(7))();
  IntColumn get ungreetedEscalateMins =>
      integer().withDefault(const Constant(5))();

  /// "Meja lama" — long-occupancy visual state on the floor grid (replaces the
  /// hardcoded 1h colour ramp). Visual only, never audible.
  IntColumn get longStayMins => integer().withDefault(const Constant(90))();

  /// "Meja selesai makan" — everything served and idle this long. Visual only.
  IntColumn get idleTableMins => integer().withDefault(const Constant(20))();

  /// "Terlambat" — grace past a reservation's `expectedAt` before the chip
  /// renders late. Display state only: never auto-flips status to `noShow`.
  IntColumn get reservationGraceMins =>
      integer().withDefault(const Constant(15))();

  /// Venue-wide off switches for the two **audible** table cues. Distinct from
  /// the per-device mute (device-local) and from the threshold value — a
  /// disabled cue is not a mistyped one. See ADR-0044.
  BoolColumn get ungreetedAlertEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get pickupAlertEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Per-event alert sound choice (ADR-0035). Each holds a preset id from
  /// `alertSoundPresets` ('none' = silent). Defaults reproduce ADR-0007's
  /// original fixed cues. Venue-wide: one choice every paired device obeys.
  TextColumn get soundNewOrder => text().withDefault(const Constant('alert'))();
  TextColumn get soundReady => text().withDefault(const Constant('chime'))();
  TextColumn get soundVoid => text().withDefault(const Constant('alert'))();
  TextColumn get soundOverdue => text().withDefault(const Constant('alert'))();

  /// Presets for the two table cues added by ADR-0044.
  TextColumn get soundUngreeted =>
      text().withDefault(const Constant('chime'))();
  TextColumn get soundPickup => text().withDefault(const Constant('chime'))();

  /// **Keanggotaan** — the master switch, **on** for a new venue: a directory of
  /// regulars is the ordinary case, and a venue that does not want one turns it
  /// off in Pengaturan. Off hides `/members`, the bill overlay's member row, the
  /// receipt lines and the whole Reports section; it never deletes anything.
  /// The default only paints a *fresh* row — an existing venue keeps whatever it
  /// stored, so nobody's deliberate "off" is flipped by an upgrade.
  BoolColumn get membersEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Whether the directory mirrors to devices, so a dark handset can still
  /// find and attach a regular (ADR-0129). **On by default**, and a plain
  /// boolean rather than a [[Modul]] or a mode key on purpose: a mode key
  /// fails closed (ADR-0109), which would switch the mirror off on precisely
  /// the venue that has never phoned home. It is the only lever an owner has
  /// over "is my customer list on the phone my waiter lost", so it is a switch
  /// they can find, not an entitlement somebody sells them.
  /// Whether the floor may record a [[Pengeluaran kunjungan]] against the visit
  /// it is serving (ADR-0130). Off by default — a venue opts in, and the
  /// `tableExpense` [[Modul|mode key]] has to be held on top, which is where
  /// the AND lives.
  BoolColumn get tableExpenseEnabled =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get memberMirrorEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Per-venue salt for the **masked** half of a [[Salinan pelanggan]] — the
  /// hash a `takeOrder`-only device searches by, in place of the number itself.
  /// Minted on first sync and never rotated (rotating it blinds every mirror
  /// until each one refetches). Empty means not yet minted.
  ///
  /// It exists because an unsalted hash of a phone number is not a mask: the
  /// number space is small enough to walk end to end, so a pulled database
  /// file would hand back every number. The salt travels to the device but is
  /// kept **out of the sqlite file** — `flutter_secure_storage`, so the file
  /// alone is not enough.
  TextColumn get memberMirrorSalt =>
      text().withDefault(const Constant(''))();

  /// The two mechanisms that nest under it, both off by default. Turning
  /// [memberPointsEnabled] off **freezes** the [[Poin]] ledger — balances stay,
  /// redemption hides, flipping it back on restores history (ADR-0095).
  BoolColumn get memberPointsEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get memberPunchEnabled =>
      boolean().withDefault(const Constant(false))();

  /// The [[Preset diskon]] the owner nominates as the member discount, applied
  /// in the `member` slot (ADR-0094). Null is a valid state — a venue can run
  /// membership on points and stempel alone. A **pointer, not a flag on the
  /// preset**: presets are hard-deleted, and a dangling pointer reads as "not
  /// configured" where a stale flag on two presets has no obvious repair.
  TextColumn get memberPresetId => text().nullable()();

  /// Earn rate: poin per Rp 1.000 of the bill net of discount, excluding
  /// service and tax, floored (ADR-0095).
  IntColumn get memberEarnPerThousand =>
      integer().withDefault(const Constant(1))();

  /// Redemption: rupiah a single poin is worth, and the floor below which
  /// redeeming is refused (a 3-poin redemption is not worth a cashier's tap).
  IntColumn get memberPointValue =>
      integer().withDefault(const Constant(1000))();
  IntColumn get memberRedeemMin => integer().withDefault(const Constant(10))();

  /// The [[Kartu stempel (punch card)]] program: one menu item, N paid units
  /// earn one free. Null item ⇒ no program running even when the toggle is on.
  TextColumn get memberPunchItemId => text().nullable()();
  IntColumn get memberPunchTarget =>
      integer().withDefault(const Constant(10))();

  /// **[[Piutang]]** — the third mechanism nesting under [membersEnabled], off
  /// by default (ADR-0098). Off hides the `piutang` payment method, the till's
  /// collection sheet and the Reports section; balances stay put.
  BoolColumn get memberDebtEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Venue-wide fallback credit limit for a member whose own `debtLimit` is
  /// null. **`0` means no tab** — the deliberate default, so switching the
  /// feature on extends credit to nobody until an owner names a number.
  IntColumn get memberDebtLimit => integer().withDefault(const Constant(0))();

  /// How old an unsettled charge must be before the Piutang section counts it
  /// overdue. A credit policy, not a fact, which is why it is not hardcoded.
  IntColumn get memberDebtOverdueDays =>
      integer().withDefault(const Constant(30))();

  /// **[[Pesan mandiri]]** master switch (ADR-0105). Off ⇒ the cleartext guest
  /// listener never binds, so the plane does not exist rather than 403ing.
  BoolColumn get guestOrderingEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Guest-side rules. A note the guest may leave per line (capped in the
  /// route), the service window in minutes-from-midnight (equal values ⇒ no
  /// window), the cap on lines in one submit, and how long a guest session
  /// stays valid before the phone must re-scan.
  BoolColumn get guestNoteEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get guestHoursStartMin =>
      integer().withDefault(const Constant(0))();
  IntColumn get guestHoursEndMin => integer().withDefault(const Constant(0))();
  IntColumn get guestMaxItems => integer().withDefault(const Constant(20))();
  IntColumn get guestSessionHours => integer().withDefault(const Constant(4))();

  /// Sound id for [AlertEvent.guestPending]. Same shape as the sibling
  /// `sound*` columns.
  TextColumn get soundGuestPending => text().nullable()();

  /// The **[[Modul]]** set this venue holds, comma-joined (ADR-0107).
  ///
  /// **Cloud-owned and mirrored down**, in the ADR-0018 sense: written only by
  /// the host's venue-doc listener, editable on no screen, and read by the
  /// features' own gate writers rather than by routes. Empty means "no module",
  /// which is also what a device that has never seen its venue doc holds — the
  /// mirror is the only thing that fills it.
  ///
  /// Deliberately **not** cleared when the cloud goes quiet: the last known set
  /// keeps serving, because payment is enforced by the suspend sweep and never
  /// by a feature going dark mid-service.
  ///
  /// **Nullable, and the null is load-bearing.** `NULL` means *never mirrored* —
  /// an upgraded venue, a fresh seed, a device that has not reached its cloud
  /// doc yet — and reads as **entitled to everything**, because a venue must not
  /// lose a feature it was using to a schema migration. `''` is a real answer:
  /// mirrored, and holds no module. Collapsing the two is how an offline
  /// upgrade takes Keanggotaan off a venue that pays for it.
  TextColumn get modules => text().nullable()();

  /// **[[Kedai]] mode** switches (ADR-0109), the on ones comma-joined, mirrored
  /// from `venues/{vid}.counterConfig`.
  ///
  /// Unlike [modules] the null here is **not** load-bearing, because a mode
  /// fails closed: never mirrored, mirrored-empty and "every switch off" are
  /// the same answer and are meant to be. A venue that has never phoned home is
  /// a restaurant, which is the point.
  TextColumn get counterConfig => text().nullable()();

  /// The venue's own [[Pesan mandiri]] code — the QR taped to the counter
  /// rather than to a table (ADR-0109, switch `counterQr`). Minted blank-only,
  /// like a table's, and killed by the same venue-wide rotate. Null on a venue
  /// that has never turned the switch on; a counter shop with no tables at all
  /// has this and nothing else.
  TextColumn get counterGuestCode => text().nullable()();
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

  /// What the audited act was worth, as a **magnitude** — never signed.
  /// Direction is carried by [type]: a void, a comp, a discount and a refund
  /// all store a positive number, and every tile on the venue log sums within
  /// one type, so no reader ever has to decide what a negative means here.
  /// Null for types where money is not the point (fire, tableMoved, staff and
  /// role edits) and on rows written before v43.
  IntColumn get amountCents => integer().nullable()();

  /// Who acted, snapshotted at write time — not a join key. Staff get renamed
  /// and deleted (`staffDeleted` is itself an audit type); resolving these at
  /// read would let a later personnel change rewrite the trail. Null on
  /// pre-v43 rows, which fall back to a live join against `users`/`roles`.
  TextColumn get actorName => text().nullable()();
  TextColumn get actorRoleName => text().nullable()();

  /// Which sentence this row is (an `AuditKind` name) and the values that fill
  /// it, as a flat `{String: String}` JSON object — ADR-0085.
  ///
  /// [title] stays, and stays NOT NULL: it is written from these at write time
  /// so the raw table is still readable by a human with a SQL client, and it is
  /// the only thing pre-v47 rows have. The read path prefers [kind] and treats
  /// [title] as the fallback, never the other way round — a row's stored
  /// sentence is frozen in whatever language the writing device was set to.
  ///
  /// Never rename a kind. The name here is the join to the ARB template, and a
  /// rename silently drops every existing row back to its frozen title.
  TextColumn get kind => text().nullable()();
  TextColumn get params => text().nullable()();

  /// The payment whose **proof photo** this row can pull up — ADR-0086.
  ///
  /// Set only when a proof actually exists, which is why this doubles as the
  /// `hasPhoto` flag and no join is needed to render the log: cash tenders and
  /// refunds carry no photo and store null here, so a non-null value always
  /// means there is an image to show.
  ///
  /// Not a [params] key. `params` exists to compose a sentence in the reader's
  /// language (ADR-0085); this is a reference, and belongs somewhere queryable
  /// rather than inside an opaque blob.
  ///
  /// The id survives the bill closing: the close path carries the payment's id
  /// into `table_session_payments` rather than minting a new one, so the photo
  /// route resolves against whichever table still holds the row. Null on rows
  /// written before v48 — history shows no indicator, and nothing is backfilled.
  TextColumn get paymentId => text().nullable()();
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

  /// Money **billed and settled**: `netTotal − discountAmount` (ADR-0039). This
  /// is the revenue figure every report and export reads. Equals [netTotal] on
  /// pre-v35 rows, which carried no discounts.
  ///
  /// It used to say *money actually collected*, and ADR-0130 made that false:
  /// a [[Pengeluaran kunjungan]] takes cash out of the till against this visit,
  /// so money in hand is `settledTotal − expenseAmount`. The formula here does
  /// **not** move — it is frozen for the reason ADR-0039 froze [netTotal], and
  /// redefining it would silently rewrite every historical comparison and every
  /// accounting export already in a customer's hands. See [expenseAmount].
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

  /// Takeaway channel + prepaid flag, frozen at snapshot so history can still
  /// tell a GoFood order from a walk-in bungkus. Empty / false for dine-in and
  /// for pre-v42 rows. ADR-0066.
  TextColumn get channel => text().withDefault(const Constant(''))();
  BoolColumn get prepaid => boolean().withDefault(const Constant(false))();

  /// Total [[Pengeluaran kunjungan]] on this visit — money that left the till
  /// against this party (ADR-0130). 0 for every row predating v72.
  ///
  /// **Frozen, like its neighbours, and deliberately not folded into any of
  /// them.** [netTotal] and [settledTotal] keep the formulas ADR-0039 gave
  /// them; what changes is [settledTotal]'s *meaning*, which is now money
  /// billed and settled. Cash actually in hand is `settledTotal -
  /// expenseAmount`, and that subtraction happens in the report, once.
  ///
  /// Rewritten on a re-close after a reopen, exactly as [discountAmount] is —
  /// the snapshot mirrors the live visit, and an expense recorded during a
  /// reopen is as real as one recorded before the first close.
  IntColumn get expenseAmount => integer().withDefault(const Constant(0))();

  /// The [[Pelanggan (member)]] frozen at snapshot. Every member figure in
  /// Reports reads this, not the live directory — which is what lets a deleted
  /// member's past trade still count in the member/non-member split while the
  /// person themselves is gone (ADR-0092).
  TextColumn get memberId => text().nullable()();
  IntColumn get memberAttributionVersion => integer().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Per-ticket snapshot tied to a TableSession. Mirrors `tickets` columns
/// at close time so reports survive after live tickets are hard-deleted.
class TableSessionTickets extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get ticketId => text()();
  TextColumn get memberId => text().nullable()();
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

  /// Mirrors Tickets.firedAt — the kitchen-ownership clock, so a held course
  /// is not reported as slow for the time it sat unfired. ADR-0043.
  DateTimeColumn get firedAt => dateTime().nullable()();

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

  /// `itemized` ⇒ the receipt **owns units** and its total is recomputed from
  /// them. `even` ⇒ an [[Amount receipt]] (ADR-0068): it owns no lines and
  /// holds a frozen money claim on the untracked remainder — bill total less
  /// every itemized receipt's total and every other amount receipt's claim.
  /// The stored value stays `even` for compatibility; the concept is wider than
  /// the word, because a bill can hold both kinds at once now (ADR-0067).
  ///
  /// An amount receipt's [total] is **never recomputed** after minting. A guest
  /// quoted a third of the bill is owed that number even if a line is voided
  /// afterwards; the correction belongs in a refund, which has an audit trail.
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

  /// The [[Pemilik struk]] — the [[Pelanggan (member)]] this receipt is *for*,
  /// as distinct from whoever pays it (ADR-0118). Written only at a venue
  /// holding the `memberSplit` mode; null everywhere else, and null on any
  /// receipt nobody named, whose money earns to the [[Pemilik tagihan]]
  /// instead.
  ///
  /// Set while the receipt is unpaid and **frozen at its first payment**, with
  /// the rest of the receipt (ADR-0068) — the member's discount is money
  /// collected under that name, so the name may not move while the money does
  /// not. Correcting one goes through the audited reopen.
  ///
  /// A weak reference, like [Visits.memberId]: a deleted member leaves it
  /// dangling on purpose (ADR-0092), because the receipt *was* theirs.
  TextColumn get memberId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Owner-defined discount the [[Cashier]] may pick from — cashiers never type a
/// percentage (ADR-0037). `scope` ∈ {bill, order, line} keeps a fixed whole-bill
/// amount off a single cheap line — `bill` is the whole [[Bill (tab)]] (a
/// table-wide promo, ADR-0070), `order` one receipt, `line` one line;
/// `kind` ∈ {percent, fixed} mirrors
/// `VenueSettings.serviceMode`, with `value` in basis points or rupiah.
/// Hard-deleted rather than archived — safe because every applied discount
/// snapshots these values onto its `discounts` row. `active` hides a seasonal
/// preset without deleting it.
/// One **[[Pengeluaran kunjungan]]** — cash a [[Waiter|pelayan]] spent on a
/// party while serving it, out of the money that [[Visit|kunjungan]] is
/// producing (ADR-0130).
///
/// **Not a [[Kas kecil (petty cash)]] row.** The box is a standing venue float
/// that only ever leaves the venue and is deliberately not revenue (ADR-0089);
/// this is money out of one visit's own takings and *is* revenue-affecting. The
/// two ledgers never meet: nothing here moves a box balance and no top-up funds
/// it.
///
/// Rows are written only by `lib/server/visit_expenses.dart` — the one-writer
/// rule `writeAudit`, `cash.dart` and `members.dart` hold — and are **never
/// updated and never deleted**. That is not "not yet": there is no correction
/// story, by design, because the cash already left.
class VisitExpenses extends Table {
  /// Client-minted, and doubles as the idempotency key — the [[Antrean kirim]]
  /// replays under it, so a request that timed out after the server committed
  /// reads back the stored response instead of posting the photo twice.
  TextColumn get id => text()();
  TextColumn get visitId => text()();

  /// Names a [[VisitExpenseCategories]] row. Deliberately not a foreign key
  /// with a cascade: a category is soft-deleted, never removed, so a closed
  /// month keeps rendering the word it was filed under.
  TextColumn get categoryId => text()();

  /// Positive. The sign lives in the reader — this ledger only ever pays out,
  /// so storing a negative would be a second way to say the same thing.
  IntColumn get amount => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// **Mandatory** (ADR-0130). Not nullable, and the writer refuses an empty
  /// one: a photo the client could skip is an optional photo.
  BlobColumn get photo => blob()();

  /// The waiter who spent it. Survives a handset handover and stays the row's
  /// author — ADR-0056 never backfills authorship.
  TextColumn get actorUserId => text().nullable()();
  DateTimeColumn get at => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

/// The venue's own vocabulary for what a [[Pengeluaran kunjungan]] was for.
///
/// Shaped exactly like [DiscountPresets], and venue-authored rather than a
/// closed enum — which is the opposite of the call `CashCategory` makes for the
/// petty cash box, and deliberately so (ADR-0130). A name here is content, like
/// a menu item's, so it is ARB-exempt.
///
/// **Soft-delete only.** [active] hides a category from the picker; nothing
/// removes the row, because a removed one orphans every expense filed under it
/// and the report then renders an id where a word should be.
class VisitExpenseCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

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

/// An applied [[Diskon (discount)]], at settlement only (ADR-0037). Three
/// scopes, told apart by which key is set:
///
/// - `visitId` set, `receiptId` null ⇒ a **bill** discount (ADR-0070) — a
///   table-wide promo, applied before any receipt claims anything and then
///   distributed across receipts the way an order discount already is.
/// - `receiptId` set, `ticketId` null ⇒ a **whole-order** discount on one receipt.
/// - `receiptId` and `ticketId` both set ⇒ a **line** discount against the units
///   *this receipt* owns.
///
/// `name`/`kind`/`value` are **snapshotted** off the preset at apply time so
/// editing or deleting a preset never rewrites settled history; `presetId` is a
/// weak reference kept only for the per-preset reporting rollup (ADR-0039).
///
/// At most one of each per target — one bill discount per visit, one order
/// discount per receipt, one line discount per line. See the three partial
/// unique indexes in `AppDatabase.migration`. Receipt-scoped rows cascade with
/// their receipt; a bill discount outlives every receipt on the visit, which is
/// the point — receipts are minted per payment now (ADR-0067) and the promo
/// predates all of them.
class Discounts extends Table {
  TextColumn get id => text()();

  /// Null ⇒ a bill discount (see [visitId]). Set ⇒ receipt- or line-scoped.
  TextColumn get receiptId => text().nullable()();

  /// Set only on a bill discount. Receipt-scoped rows reach their visit through
  /// the receipt.
  TextColumn get visitId => text().nullable()();

  /// Null ⇒ whole-order discount. Set ⇒ line discount on this ticket's units.
  TextColumn get ticketId => text().nullable()();

  /// Which authority applied a **bill** discount: `manual` (a cashier's promo),
  /// `member` (the venue's nominated member preset), `redeem` (a
  /// [[Tukar poin (redeem)|points redemption]]). Always `manual` on order- and
  /// line-scope rows, which have no such contest.
  ///
  /// The one-per-visit rule of ADR-0070 is now **one per source** (ADR-0094):
  /// the partial unique index covers `(visit_id, source)`, so the three stack
  /// by design and none can be applied twice.
  TextColumn get source => text().withDefault(const Constant('manual'))();

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

  /// On a refund row, the payment it unwinds (ADR-0121). Null on a payment,
  /// and null on a refund written before the tender lock came off — those
  /// predate the leg concept and are deliberately not backfilled, for the
  /// reason `stock_movements.count_id` is not: there is no honest answer to
  /// "which leg" on a struk that could only ever hold one.
  TextColumn get refundsPaymentId => text().nullable()();

  /// Debtor explicitly selected for a piutang payment leg (ADR-0125).
  TextColumn get memberId => text().nullable()();
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

  /// The [[Pemilik struk]] frozen at snapshot (ADR-0118). Every per-member
  /// figure in Reports reads this rather than the live directory, for the
  /// reason [TableSessions.memberId] does: a deleted member's past trade still
  /// counts while the person is gone (ADR-0092).
  TextColumn get memberId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Per-assignment snapshot tied to a TableSession (mirrors ReceiptLines at
/// close), so which units sat on which [[Receipt]] survives the live-row
/// delete.
///
/// It exists for [[Kartu stempel (punch card)|stempel]] (ADR-0118). Punch
/// progress is derived from settled history, and under `memberSplit` it counts
/// the units on a member's **own** receipts — a question nothing could answer
/// after close, because `TableSessionTickets` records no receipt. Flattening
/// the link onto that table instead would have been one nullable column and
/// loses the qty split: a `qty: 3` punch item divided 2+1 between two members
/// would credit one of them for all three, silently. Punch is a counting path,
/// so it gets the faithful mirror.
class TableSessionReceiptLines extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get receiptId => text()();
  TextColumn get ticketId => text()();
  IntColumn get qtyUnits => integer().withDefault(const Constant(1))();
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

  /// Null ⇒ a **bill** discount, which belongs to the visit rather than to any
  /// one receipt (ADR-0070). The session is the visit here, so no `visitId` is
  /// needed alongside — `sessionId` already carries it.
  TextColumn get receiptId => text().nullable()();

  /// Null ⇒ whole-order (or bill) discount; set ⇒ line discount.
  TextColumn get ticketId => text().nullable()();
  TextColumn get presetId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  IntColumn get value => integer().withDefault(const Constant(0))();
  IntColumn get amount => integer().withDefault(const Constant(0))();

  /// Mirrors `Discounts.source` at close so history can still say *why* money
  /// came off — promo, membership or redemption (ADR-0094). Pre-v51 rows are
  /// `manual`, which is what they all were.
  TextColumn get source => text().withDefault(const Constant('manual'))();
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
  TextColumn get memberId => text().nullable()();
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

  /// Set when the phone typed at booking already belongs to a
  /// [[Pelanggan (member)]] — member lookup is the primary path in the booking
  /// flow, manual name+phone the fallback. [name] and [phone] stay a **snapshot
  /// of what was booked**: a later edit to the member never rewrites the
  /// booking, the same rule `discounts` keeps against its preset.
  TextColumn get memberId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Stamped when the reservation is actually seated. Distinct from
  /// [updatedAt], which any later edit moves — lateness (`seatedAt −
  /// expectedAt` past the venue grace) needs a stamp that only the seat sets.
  /// ADR-0044.
  DateTimeColumn get seatedAt => dateTime().nullable()();
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

/// A raw stock item — "Bahan" in CONTEXT.md. The ONLY stock entity: a bottled
/// drink is an ingredient whose recipe is one of itself. Replaces the former
/// per-item `MenuItems.stockCount`. See ADR-0040.
///
/// Row class is named explicitly: the default (`Ingredient`) would collide with
/// the domain model of the same name, which the server imports alongside.
@DataClassName('IngredientRow')
class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Unit **preset** key (`mg|g|kg|ml|l|pcs|butir|siung|lembar`) — entry and
  /// display only. Quantities are stored in the dimension's milli-base, never
  /// in this unit. See `domain/models/stock_unit.dart`.
  TextColumn get unit => text()();

  /// On-hand quantity in milli-base units (mg / µl / milli-pcs). Denormalised
  /// from [StockMovements]; both are written in the same transaction (ADR-0041).
  /// MAY go negative — an `overrideStock` send is a deliberate "your counts are
  /// wrong" signal and must not be clamped.
  IntColumn get stockOnHand => integer().withDefault(const Constant(0))();

  /// Reorder threshold in milli-base units. Null = no low-stock badge.
  IntColumn get lowStockAt => integer().nullable()();

  /// **Par level** — the quantity this ingredient should be topped back up to,
  /// in milli-base units. Null = not stocked to a par, so it never appears on
  /// the shopping list. Distinct from [lowStockAt], which only decides when to
  /// warn: the threshold says "shout", the par says "buy this much".
  IntColumn get parLevel => integer().nullable()();

  /// Moving-average cost, in **micro-money per milli-base unit** (money × 1e6
  /// per storage unit) so that sub-rupiah per-gram costs survive integer
  /// storage. Cost of a quantity = `qty * costMicro ~/ 1000000`.
  IntColumn get costMicro => integer().withDefault(const Constant(0))();

  /// Output quantity of one production batch, in this ingredient's milli-base
  /// units. Non-null ⇒ this is a **produced** ingredient (sambal, kaldu) with
  /// recipe lines of its own. One level only: a produced ingredient's recipe
  /// may reference non-produced ingredients exclusively (ADR-0040).
  IntColumn get batchYield => integer().nullable()();

  DateTimeColumn get archivedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// One line of a "Resep" — flat, scoped by `(ownerKind, ownerId, variantId,
/// optionId)`. There is no separate recipe header table: a recipe *is* the set
/// of lines sharing a scope, and the only header field a recipe needs (yield)
/// lives on [Ingredients.batchYield].
///
/// Scopes, per ADR-0040:
/// - `item` + empty variant/option — the item's **base** recipe.
/// - `item` + `variantId` — **replaces** the base entirely for that variant.
/// - `item` + `optionId` — **adds** on top of whichever won.
/// - `ingredient` — the batch recipe for a produced ingredient.
@DataClassName('RecipeLineRow')
class RecipeLines extends Table {
  TextColumn get id => text()();

  /// `item` | `ingredient`.
  TextColumn get ownerKind => text()();
  TextColumn get ownerId => text()();
  TextColumn get variantId => text().withDefault(const Constant(''))();
  TextColumn get optionId => text().withDefault(const Constant(''))();
  TextColumn get ingredientId => text()();

  /// Quantity consumed, in the referenced ingredient's milli-base units.
  IntColumn get qty => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Append-only ledger of every change to an ingredient's stock — the audit
/// trail behind every number inventory shows. Rows are **self-contained**
/// (frozen `sourceLabel`, nullable `ticketId`) because live ticket rows are
/// deleted at bill close. See ADR-0041.
@DataClassName('StockMovementRow')
class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get ingredientId => text()();

  /// Signed change in milli-base units.
  IntColumn get delta => integer()();

  /// `sale | voidReturn | waste | receive | adjust | produce`.
  TextColumn get reason => text()();

  /// The ticket that caused this, when there was one. Dangles by design once
  /// the visit is snapshotted — read [sourceLabel] instead.
  TextColumn get ticketId => text().nullable()();

  /// Frozen human label of the cause (item + variant as ordered, supplier
  /// note, "Opname", …). Never resolved by join.
  TextColumn get sourceLabel => text().withDefault(const Constant(''))();
  TextColumn get userId => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Unit cost at the moment of the movement, in micro-money per milli-base
  /// unit — so waste/usage can be valued historically without re-pricing.
  IntColumn get costMicro => integer().withDefault(const Constant(0))();

  /// Groups the input rows and the output row of one `produce` batch.
  TextColumn get batchId => text().nullable()();

  /// The [StockCounts] session this `adjust` was closed out of. Null on every
  /// other reason, and on `adjust` rows written before v52 — those predate the
  /// session concept and are deliberately not backfilled (ADR-0096).
  TextColumn get countId => text().nullable()();
  DateTimeColumn get at => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

/// One stok opname — a counting session, and the document an inventory manager
/// files. See §Opname (Stocktake) in CONTEXT.md and ADR-0096.
///
/// A session is opened, walked, and closed. It writes no [StockMovements] until
/// close, so a forty-minute walk of the pantry survives the tablet sleeping.
@DataClassName('StockCountRow')
class StockCounts extends Table {
  TextColumn get id => text()();

  /// Who opened it. `closedBy` may differ — a manager may finish a walk.
  TextColumn get userId => text().nullable()();
  TextColumn get closedBy => text().nullable()();

  /// Their names, **frozen at write** — same rule as `audit_entries.actorName`
  /// and `stock_count_lines.name`: a filing copy printed a year later must name
  /// the person who counted, not whoever holds that user row today. Null on a
  /// session opened before v70; the read path fills those with a live join.
  TextColumn get userName => text().nullable()();
  TextColumn get closedByName => text().nullable()();

  /// `full | partial` — whether this session claims to have seen *every* active
  /// [Ingredients] row. Without the claim, "did we count everything in March?"
  /// has no answer.
  TextColumn get scope => text().withDefault(const Constant('partial'))();

  /// Whether the expected quantity was hidden from the counter while counting.
  /// Recorded because it decides how much the variance is worth: a stocktake
  /// shown the answer is weaker evidence than one that was not.
  BoolColumn get blind => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();

  /// Null while the session is open. Stamped once, at close — a closed session
  /// is never reopened, because its movements are already in the ledger.
  DateTimeColumn get closedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// One counted [Ingredients] row inside a [StockCounts] session.
///
/// **Every counted bahan gets a line, including one found correct** — a zero
/// variance is a fact somebody established, not an absence. Only a non-zero
/// variance also writes a movement: the count is the evidence, the movement is
/// the consequence (ADR-0096).
///
/// [expectedQty] and [costMicro] are frozen **when the line is entered**, not at
/// close. Sales keep deducting while the pantry is walked, and folding those
/// into the variance would blame the counter for them.
@DataClassName('StockCountLineRow')
class StockCountLines extends Table {
  TextColumn get id => text()();
  TextColumn get countId => text()();
  TextColumn get ingredientId => text()();

  /// `stockOnHand` at the moment this line was entered, in milli-base units.
  IntColumn get expectedQty => integer()();

  /// What the counter found, absolute, in milli-base units.
  IntColumn get countedQty => integer()();

  /// Unit cost frozen at entry, micro-money per milli-base unit — so a session
  /// read a year later reports the rupiah it reported at close.
  IntColumn get costMicro => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get at => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

/// One **[[Kas (cash box)|kas]]** — a named tin of physical cash (ADR-0131).
///
/// Venue-authored, shaped like [VisitExpenseCategories] and [DiscountPresets]:
/// a name here is content, not copy, so it never reaches the ARB. **Soft-delete
/// only** — a closed month's rows must still be able to name the box they came
/// out of, and `active` is what hides a retired one from the picker.
///
/// There is no balance column here either, for the reason [CashEntries] gives:
/// a box's balance is `SUM(delta)` over its own rows and nothing else.
// Named explicitly: drift would singularise this to `CashBoxe`, and the name a
// reader would reach for — `CashBox` — is already the domain model in
// `domain/models/cash_entry.dart`. The row and what a reader sees are two
// different things, so the row takes the suffix.
@DataClassName('CashBoxRow')
class CashBoxes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

/// The [[Kas kecil]] ledger — the venue's petty cash boxes, append-only.
///
/// **There is no balance column and there never will be.** The balance is
/// `SUM(delta)`, derived on every read: a box sees tens of rows a week, so the
/// denormalised column `Ingredients.stockOnHand` earns for a 42-item menu screen
/// buys nothing here, and money must never have two answers.
///
/// Rows are never updated and never deleted, with the single exception of
/// [reversedById] being stamped onto a row that has been undone — a link, not a
/// rewrite of what happened. See §Kas kecil in CONTEXT.md, ADR-0088 and ADR-0089.
class CashEntries extends Table {
  TextColumn get id => text()();

  /// `topUp | expense | count | reversal`.
  TextColumn get kind => text()();

  /// Signed **plain rupiah** — positive into the box, negative out. Not micro-
  /// scaled like `costMicro`: the box is counted in notes.
  IntColumn get delta => integer()();

  /// `ingredients | operations | transport | dailyWage | other`. Set on an
  /// expense, null on every other kind.
  TextColumn get category => text().nullable()();

  /// Optional on top-up / expense / count; **required** on a reversal, enforced
  /// in the route — a reversal with no reason is a hole in the ledger.
  TextColumn get note => text().nullable()();

  /// The row this one undoes, on a reversal only.
  TextColumn get reversesId => text().nullable()();

  /// The reversal that undid this row. Non-null is the whole already-reversed
  /// test, which is what caps a row at one reversal.
  TextColumn get reversedById => text().nullable()();

  /// Absolute cash the counter reported, on a `count` only. Kept beside [delta]
  /// because the variance alone cannot be read back into what was in the box.
  IntColumn get countedAmount => integer().nullable()();

  /// Optional photo of whatever receipt existed (JPEG blob), expense only.
  /// Read **only** by the photo route — never select it in the ledger or report
  /// path; use `selectOnly` excluding it, the same discipline `Payments.photo`
  /// keeps.
  BlobColumn get photo => blob().nullable()();

  TextColumn get actorUserId => text().nullable()();

  /// Attribution frozen at write time so a later rename or deletion cannot
  /// rewrite the trail.
  TextColumn get actorName => text().nullable()();
  DateTimeColumn get at => dateTime()();

  // The two ADR-0131 columns sit last, in the order the v73 migration ALTERs
  // them in. SQLite can only append, so declaring them where they read best
  // would leave an upgraded venue's columns in a different order from a fresh
  // install's; matching the migration keeps the two populations identical.
  /// Which [[Kas (cash box)|kas]] this movement moved (ADR-0131). Never null:
  /// the default names the box every pre-v73 row was backfilled to, so the
  /// migrated population and a fresh install agree about the column.
  TextColumn get boxId => text().withDefault(const Constant('box-main'))();

  /// The other leg of a transfer between two boxes (ADR-0131) — the out-leg
  /// names the in-leg and vice versa. Non-null is the whole "this is internal
  /// movement" test.
  ///
  /// A transfer is deliberately **not** a fifth `CashEntryKind`: it is an
  /// ordinary `expense` out of one box and an ordinary `topUp` into another,
  /// written in one transaction, so every reader that already sums a box needs
  /// no new arm. The link is what stops half a transfer from being reversed —
  /// see `reverseCash`.
  TextColumn get transferPeerId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A [[Pelanggan (member)]] — a person the venue recognises across visits.
///
/// **The phone number is the identity** (ADR-0092): unique venue-wide, enforced
/// by a real unique index rather than by route code, because the whole scheme
/// rests on "enrolling an existing number attaches, never duplicates". There is
/// no anonymous member and no soft delete — deleting the row is how a person is
/// forgotten, and the [[Visit|visits]] they made keep a dangling `memberId`
/// that renders as "Pelanggan dihapus".
///
/// Venue-local, never synced to the cloud (ADR-0091).
class Members extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Normalised to digits at write time so `0812…`, `+62812…` and `62812…`
  /// cannot become three members. Unique — see `_createMemberIndexes`.
  TextColumn get phone => text()();

  /// Short human-readable code printed on the receipt and read back over the
  /// counter. **Display only** — never the lookup key, which is [phone].
  TextColumn get code => text().withDefault(const Constant(''))();
  TextColumn get note => text().nullable()();

  /// Date only (time ignored). Feeds the directory's "ulang tahun bulan ini"
  /// filter and nothing else: there is deliberately no birthday rules engine.
  DateTimeColumn get birthday => dateTime().nullable()();
  DateTimeColumn get joinedAt => dateTime()();

  /// How much [[Piutang]] this member may carry, in rupiah. **Null means fall
  /// back to `venueSettings.memberDebtLimit`** — not "unlimited". `0` (either
  /// here or on the venue default) means no tab at all, which is what both
  /// ship at: turning the feature on must not silently extend credit to
  /// everybody already enrolled. See ADR-0098.
  IntColumn get debtLimit => integer().nullable()();

  /// [[Alamat pelanggan]] — four optional fields, all nullable, none of them
  /// ever required. Record-keeping only: nothing searches, groups, reports or
  /// prints an address, which is why this is four columns on the person rather
  /// than a table of its own.
  ///
  /// The three administrative levels store the **name**, snapshotted at write
  /// time — never the Kemendagri wilayah code. Same rule a [[Preset diskon]]
  /// and a booked [[Reservation]] name keep: the displayed value is frozen, so
  /// swapping the bundled dataset or renaming a kelurahan upstream can never
  /// rewrite a record somebody already saved. Nothing joins on these, so the
  /// stable key a code would buy has no buyer.
  ///
  /// **Any prefix is legal.** [kabupaten] alone stores fine; picking a new
  /// parent clears its children, because a stale child is worse than a blank.
  TextColumn get kabupaten => text().nullable()();
  TextColumn get kecamatan => text().nullable()();
  TextColumn get kelurahan => text().nullable()();

  /// The street line **only** — `Jl. Sam Ratulangi No. 12`. Never the whole
  /// address: a freeform field repeating the three above is a field that
  /// disagrees with them the first time someone edits one and not the other.
  /// Also the escape hatch for a guest from outside Sulawesi Utara, whose
  /// three pickers stay empty.
  TextColumn get addressText => text().nullable()();

  /// The revision a [[Salinan pelanggan]] pages off (ADR-0129).
  ///
  /// A **counter, not a clock**. Drift stores a `DateTime` at second
  /// granularity, so a timestamp cursor drops any change that lands in the
  /// same second as the cursor and sorts below it — silently, and forever,
  /// because nothing revisits a row that did not move. A monotonic integer has
  /// no ties to break.
  ///
  /// Stamped by every writer that changes what a mirror *shows* — the identity
  /// here, and the derived figures on top of it ([[Poin]], [[Piutang]], visit
  /// count). One helper stamps it, `touchMember`; a writer that skips it drops
  /// that member out of every device's copy until some unrelated edit moves
  /// them again, which is the same failure class `writeAudit` and `cash.dart`
  /// exist to prevent.
  ///
  /// Shares one sequence with [MemberTombstones.rev], so one cursor resumes
  /// both streams. Nullable only for pre-v71 rows, which v71 backfills.
  IntColumn get mirrorRev => integer().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// A [[Pelanggan (member)]] that is **gone**, so a [[Salinan pelanggan]] can
/// learn it (ADR-0129).
///
/// [Members] has no soft delete on purpose — deleting the row is how a person
/// is forgotten — which leaves a device that was dark during the delete holding
/// them forever. This is the one place that remembers *that* an id went away,
/// and it stores no name, no number and nothing else about them: a tombstone
/// that carried the person's details would be the erasure undone.
class MemberTombstones extends Table {
  /// The member id that went away.
  TextColumn get id => text()();
  DateTimeColumn get deletedAt => dateTime()();

  /// Position in the same sequence as [Members.mirrorRev] — a departure and an
  /// edit are one ordered stream, so one cursor resumes both.
  IntColumn get rev => integer().withDefault(const Constant(0))();

  /// Set when the row went by a **merge**: the id that survived, so a local
  /// reference follows it instead of dangling. Null for a plain delete —
  /// there is nowhere to follow.
  TextColumn get mergedInto => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// The [[Poin]] ledger — append-only, one row per movement.
///
/// **There is no balance column and there never will be**, for the reason
/// [CashEntries] has none: the balance is `SUM(delta)`, money must never have
/// two answers, and a stored one drifts silently. It cannot go negative
/// (checked in `lib/server/members.dart`, the single writer).
///
/// Earn happens **once, at bill close** (ADR-0095) — never per payment, because
/// a bill mints a receipt per payment and a reopen would earn twice.
class MemberPoints extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text()();

  /// `earn | redeem | adjust | reversal`. A reversal is what a reopened bill
  /// writes against its own earn; a re-close then earns afresh.
  TextColumn get kind => text()();

  /// Signed points — positive earned, negative spent or reversed.
  IntColumn get delta => integer()();

  /// The [[Visit]] that produced it, on `earn`, `redeem` and `reversal`. Null on
  /// a hand adjustment, which is the only movement with no bill behind it.
  TextColumn get visitId => text().nullable()();

  /// The bill figure the earn was computed from (net of discount, excluding
  /// service and tax). Kept so a balance can be explained without re-deriving
  /// it from a snapshot whose rate may since have changed.
  IntColumn get baseAmount => integer().withDefault(const Constant(0))();

  /// Required on `adjust` (enforced in the writer) — an adjustment with no
  /// reason is a hole in the ledger, exactly as it is in the cash box.
  TextColumn get note => text().nullable()();
  TextColumn get actorUserId => text().nullable()();

  /// Attribution frozen at write time so a later rename cannot rewrite history.
  TextColumn get actorName => text().nullable()();
  DateTimeColumn get at => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

/// The [[Piutang]] ledger — append-only, one row per movement (ADR-0098).
///
/// **No balance column**, for the third time and the same reason [CashEntries]
/// and [MemberPoints] have none: the balance is `SUM(delta)`, money must never
/// have two answers. It cannot go negative and it cannot exceed the member's
/// credit limit — both checked in `lib/server/debts.dart`, the single writer.
///
/// A charge is written **with the payment that discharged the receipt**, not at
/// bill close: a bill can go part-cash part-tab, so the tab is one payment
/// among several rather than a property of the close.
class MemberDebts extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text()();

  /// `charge | payment | reversal | writeOff | adjust`. `reversal` is automatic
  /// (a reopened receipt undoing its own charge); `adjust` is the hand
  /// correction that exists because a snapshotted visit has no receipt left to
  /// reopen, and without it a typo could only be fixed by a `writeOff` — which
  /// would make the bad-debt figure meaningless.
  TextColumn get kind => text()();

  /// Signed rupiah — positive charged, negative collected, reversed, written
  /// off or corrected down.
  IntColumn get delta => integer()();

  /// The [[Payment (manual confirmation)]] that raised this charge. **The join
  /// that survives bill close**: `snapshotVisitAndDelete` copies a payment
  /// under its live id but mints a fresh `table_sessions.id`, so this is the
  /// only stable way back to the bill. Null on every kind but `charge`.
  TextColumn get paymentId => text().nullable()();

  /// The [[Visit]] behind a `charge`, for as long as one exists. Goes dangling
  /// at snapshot **by design** — read [paymentId] to reach history.
  TextColumn get visitId => text().nullable()();

  /// Table label frozen at write time, so a ledger row can name its bill after
  /// the visit is gone without joining anything.
  TextColumn get billLabel => text().withDefault(const Constant(''))();

  /// Collection method on `payment` (`tunai` | `kartu` | `qris` | `transfer` |
  /// `lainnya` — never `piutang`, which would be circular). Null otherwise.
  TextColumn get method => text().nullable()();

  /// Required on `writeOff` and `adjust` (enforced in the writer) — the same
  /// rule the cash box and the points ledger keep.
  TextColumn get note => text().nullable()();

  /// Proof photo for a non-cash collection (ADR-0025). A `charge` never has
  /// one: there is no slip for a promise.
  BlobColumn get photo => blob().nullable()();
  TextColumn get actorUserId => text().nullable()();

  /// Attribution frozen at write time so a later rename cannot rewrite history.
  TextColumn get actorName => text().nullable()();
  DateTimeColumn get at => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Single-row state for the [[Generic seed (sample data)]] job and its
/// first-run prompt (ADR-0073).
///
/// Venue-wide, not per device: "never ask again" is a property of the venue,
/// so skipping on the tablet also skips on the phone.
class DemoStates extends Table {
  TextColumn get id => text().withDefault(const Constant('default'))();

  /// False while a seed job is still running. A job that is interrupted —
  /// host backgrounded, process reclaimed, app force-quit — leaves this false
  /// forever, and the prompt then offers only "Hapus & muat ulang": partial
  /// history would otherwise trip the seed guard while reporting a loaded
  /// venue, so the reports look real and are quietly short (ADR-0053 §9).
  BoolColumn get complete => boolean().withDefault(const Constant(false))();

  /// Progress for the async seed job's WS broadcasts.
  IntColumn get daysDone => integer().withDefault(const Constant(0))();
  IntColumn get daysTotal => integer().withDefault(const Constant(0))();

  /// The admin answered the first-run prompt and declined. Written on **skip**
  /// or on a **completed** seed, never when the job merely starts — an
  /// interrupted job means the question went unanswered, so the prompt fires
  /// again and offers to clear the partial data (ADR-0073).
  BoolColumn get promptAnswered =>
      boolean().withDefault(const Constant(false))();

  /// The last job ended in an **error**, not an interruption. Persisted so the
  /// verdict survives a restart: without it the only carrier is the live
  /// `seed.progress` broadcast, and a relaunched app reads a crashed job as
  /// merely interrupted. Reset by [SeedJob.begin], [SeedJob.clear] and
  /// [SeedJob.markComplete] — a new attempt never inherits the old verdict.
  BoolColumn get failed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A guest's phone, bound to one table for a while. Opaque id in a cookie;
/// the row exists so "Pesanan saya" can list what *this* phone submitted
/// without any account. Expires by `expiresAt` and is closed at bill-close.
/// See ADR-0105.
class GuestSessions extends Table {
  TextColumn get id => text()();
  TextColumn get tableId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// A guest's submission — an **intent, not a ticket** (ADR-0105). Nothing
/// reaches the kitchen, the bill or a report until staff accept it, at which
/// point the ordinary `submitOrder` path runs and this row records what came
/// of it. `status`: `pending` | `accepted` | `rejected` | `cancelled`
/// (persisted names).
class GuestOrders extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get tableId => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get submittedAt => dateTime()();
  DateTimeColumn get decidedAt => dateTime().nullable()();
  TextColumn get decidedByUserId => text().nullable()();

  /// A code, never a sentence (ADR-0085).
  TextColumn get rejectReasonCode => text().nullable()();

  /// Filled on accept: the visit the lines joined and the tickets born of them.
  TextColumn get visitId => text().nullable()();
  TextColumn get ticketIdsJson => text().withDefault(const Constant('[]'))();

  /// Frozen at submit so the queue card renders without re-pricing a menu that
  /// may have moved. The bill is priced by `submitOrder`, not by this.
  IntColumn get subtotal => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

/// One line of a [GuestOrders] row, in the shape `submitOrder` already accepts.
class GuestOrderLines extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get itemId => text()();
  TextColumn get name => text()();
  TextColumn get variantName => text().withDefault(const Constant(''))();
  TextColumn get course => text().withDefault(const Constant('mains'))();
  IntColumn get qty => integer().withDefault(const Constant(1))();

  /// `[{"optionId": "..."}]` — same wire shape the staff order path sends.
  TextColumn get modifiersJson => text().withDefault(const Constant('[]'))();
  TextColumn get note => text().nullable()();
  IntColumn get unitPrice => integer()();
  @override
  Set<Column> get primaryKey => {id};
}
