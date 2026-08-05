import 'dart:convert';
import 'dart:typed_data';

import 'package:satset/data/repositories/accounting_report_repository.dart';
import 'package:satset/data/repositories/admin_grace.dart';
import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/order_history_repository.dart';
import 'package:satset/data/repositories/reports_repository.dart';
import 'package:satset/data/repositories/staff_report_repository.dart';
import 'package:satset/data/models/reports_dto.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/course.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/menu_tag.dart';
import 'package:satset/domain/models/ticket.dart';
import 'package:satset/domain/models/ticket_modifier.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/ui/core/state/ready_alert_view_model.dart';

/// Canned domain objects for the widget book (`_book/`), debug builds only.
///
/// Deliberately hand-written rather than pulled from `server/db/seed_data.dart`:
/// the book needs the *awkward* rows — a 68-character item name, six modifiers,
/// a void reason, an account with no avatar colour — which real seed data does
/// not carry and should not be bent to carry.
///
/// Nothing here touches IO. Every value is a plain constructor call, so a state
/// renders identically on an unpaired device and a live one.
abstract final class BookStubs {
  // ── Identity ──────────────────────────────────────────────────────────────

  static const waiter = AppUser(
    id: 'u-waiter',
    name: 'Rani',
    initials: 'RN',
    role: UserRole.waiter,
    shiftStartedAt: '17:00',
    zoneAssigned: 'Teras',
    avatarColorHex: 0xFF4F8DF7,
  );

  static const kitchen = AppUser(
    id: 'u-kitchen',
    name: 'Bagas',
    initials: 'BG',
    role: UserRole.kitchen,
    shiftStartedAt: '16:30',
    zoneAssigned: 'Dapur',
    avatarColorHex: 0xFF34C759,
  );

  static const admin = AppUser(
    id: 'u-admin',
    name: 'Pak Hendra',
    initials: 'HD',
    role: UserRole.admin,
    shiftStartedAt: '09:00',
    zoneAssigned: 'Kantor',
    avatarColorHex: 0xFFAF7BFF,
  );

  /// An account that has never been given a colour — exercises every
  /// `fallbackColor:` path in `StaffAvatar`.
  static const uncoloured = AppUser(
    id: 'u-new',
    name: 'Staf Baru',
    initials: 'SB',
    role: UserRole.waiter,
    shiftStartedAt: '18:00',
    zoneAssigned: '',
  );

  static const signedOut = AuthState();

  static AuthState authAs(AppUser user, {Set<Capability>? caps}) => AuthState(
    isAuthenticated: true,
    user: user,
    capabilities: caps ?? Capability.values.toSet(),
  );

  static final waiterAuth = authAs(
    waiter,
    caps: {Capability.takeOrder, Capability.modifyOrder},
  );
  static final adminAuth = authAs(admin);

  // ── Menu tags ─────────────────────────────────────────────────────────────

  static const tags = <String, MenuTag>{
    'gluten': MenuTag(
      id: 'gluten',
      kind: MenuTagKind.allergen,
      name: 'Gluten',
      code: 'GL',
    ),
    'kacang': MenuTag(
      id: 'kacang',
      kind: MenuTagKind.allergen,
      name: 'Kacang',
      code: 'KC',
    ),
    'seafood': MenuTag(
      id: 'seafood',
      kind: MenuTagKind.allergen,
      name: 'Seafood',
      code: 'SF',
    ),
    'susu': MenuTag(
      id: 'susu',
      kind: MenuTagKind.allergen,
      name: 'Susu',
      code: 'SU',
    ),
    'vegan': MenuTag(
      id: 'vegan',
      kind: MenuTagKind.diet,
      name: 'Vegan',
      code: 'VG',
    ),
    'halal': MenuTag(
      id: 'halal',
      kind: MenuTagKind.diet,
      name: 'Halal',
      code: 'HL',
    ),
    'pedas': MenuTag(
      id: 'pedas',
      kind: MenuTagKind.diet,
      name: 'Pedas',
      code: 'PD',
    ),
  };

  /// Item ids the tag map above resolves against, for `MenuTagBadges`.
  static const taggedItemId = 'itm-gado';
  static const untaggedItemId = 'itm-teh';

  /// `MenuTagBadges` resolves tags live off the menu snapshot (ADR-0012), so
  /// the book has to stand up items as well as tags.
  static const menuItems = <MenuItem>[
    MenuItem(
      id: taggedItemId,
      name: 'Gado-Gado Siram',
      categoryId: 'cat-main',
      description: 'Sayur rebus, bumbu kacang, lontong.',
      allergens: ['kacang', 'gluten'],
      dietary: ['vegan', 'halal'],
      basePrice: 28000,
      variants: [],
    ),
    MenuItem(
      id: untaggedItemId,
      name: 'Teh Tawar Hangat',
      categoryId: 'cat-drink',
      description: '',
      basePrice: 5000,
      variants: [],
    ),
  ];

  // ── Text that breaks layouts ──────────────────────────────────────────────

  /// The stress string. Real Indonesian menu names get this long, and this is
  /// the only place in the app you can see one on demand.
  static const longName =
      'Nasi Goreng Kampung Spesial Telur Mata Sapi Sambal Matah Ekstra Pedas';

  static const longNote =
      'Tolong pisahkan sambalnya, tamu alergi kacang. Nasi setengah porsi saja, '
      'jangan pakai bawang goreng, dan antar bersama minumnya.';

  static const manyModifiers = <TicketModifier>[
    TicketModifier(groupId: 'spice', optionId: 'hot', label: 'Level 5'),
    TicketModifier(
      groupId: 'egg',
      optionId: 'extra',
      label: 'Telur tambah',
      priceDelta: 5000,
    ),
    TicketModifier(groupId: 'rice', optionId: 'half', label: 'Nasi setengah'),
    TicketModifier(
      groupId: 'crackers',
      optionId: 'none',
      label: 'Tanpa kerupuk',
      priceDelta: -2000,
    ),
    TicketModifier(
      groupId: 'protein',
      optionId: 'chicken',
      label: 'Ayam suwir',
      priceDelta: 8000,
    ),
    TicketModifier(groupId: 'serve', optionId: 'togo', label: 'Bungkus'),
  ];

  // ── Tickets ───────────────────────────────────────────────────────────────

  /// One line, dialled to whatever state an entry needs.
  ///
  /// [ageMinutes] drives `ElapsedPill` and the overdue escalation without any
  /// provider override — the venue's default `prepTargetMins` is 15, so 40
  /// reads as urgent and 3 does not.
  static Ticket ticket({
    TicketStatus status = TicketStatus.sent,
    String name = 'Ayam Bakar Madu',
    String variantName = '',
    int qty = 1,
    int price = 38000,
    int ageMinutes = 3,
    CourseId course = CourseId.mains,
    List<TicketModifier> modifiers = const [],
    String? note,
    String? voidReason,
    String? createdBy = 'u-waiter',
    bool held = false,
  }) {
    final now = DateTime.now();
    final sentAt = now.subtract(Duration(minutes: ageMinutes));
    final terminal =
        status == TicketStatus.served || status == TicketStatus.voided;
    return Ticket(
      id: 'tk-${status.name}-$name-$qty',
      visitId: 'vs-1',
      tableId: 't-5',
      itemId: taggedItemId,
      name: name,
      variantName: variantName,
      course: course,
      qty: qty,
      modifiers: modifiers,
      note: note,
      price: price,
      status: status,
      sentAt: _clock(sentAt),
      sentAtTime: sentAt,
      firedAtTime: held ? now.subtract(const Duration(minutes: 1)) : null,
      readyAtTime: status == TicketStatus.ready || terminal
          ? now.subtract(const Duration(minutes: 1))
          : null,
      servedAtTime: status == TicketStatus.served ? now : null,
      voidReason: voidReason,
      voidReasonCode: voidReason == null ? null : 'guest_changed_mind',
      voidApprovedBy: voidReason == null ? null : admin.name,
      createdBy: createdBy,
      voidedBy: voidReason == null ? null : waiter.id,
    );
  }

  /// Every awkward property at once — the state that finds overflow bugs.
  static Ticket get stressTicket => ticket(
    status: TicketStatus.prep,
    name: longName,
    variantName: 'Porsi Jumbo',
    qty: 99,
    price: 187500,
    ageMinutes: 42,
    modifiers: manyModifiers,
    note: longNote,
  );

  static String _clock(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // ── Ready alerts ──────────────────────────────────────────────────────────

  static const dineInAlert = ReadyAlert(
    tableId: 't-5',
    tableLabel: 'Meja 5',
    zone: 'Teras',
    what: 'Ayam Bakar Madu ×2',
  );

  static const takeawayAlert = ReadyAlert(
    tableId: 'v-7',
    tableLabel: 'Bawa pulang #7',
    zone: 'Ibu Sri',
    what: longName,
    isTakeaway: true,
  );

  // ── Offline grace ─────────────────────────────────────────────────────────

  static const graceWarn = AdminGrace(Duration(days: 4));
  static const graceCritical = AdminGrace(Duration(hours: 6));

  // ── Export payloads ───────────────────────────────────────────────────────
  //
  // Structurally valid but empty. The export sheet's job in the book is to show
  // its own chrome — kind pills, disabled states, the busy spinner — and an
  // empty report exercises all of that. Fabricating a plausible night of
  // trading here would be a second seed dataset to keep in sync for no extra
  // UI coverage.

  static final _from = DateTime.now().subtract(const Duration(days: 1));
  static final _to = DateTime.now();

  static OrderHistory orderHistory(ReportsQuery q) => OrderHistory(
    generatedAt: DateTime.now(),
    rangeFrom: _from,
    rangeTo: _to,
    range: q.range,
    visits: const [],
    visitCount: 0,
    lineCount: 0,
    net: 0,
  );

  static StaffReport staffReport(ReportsQuery q) => StaffReport(
    generatedAt: DateTime.now(),
    rangeFrom: _from,
    rangeTo: _to,
    range: q.range,
    rows: const [],
    net: 0,
    voidCount: 0,
    lostRupiah: 0,
  );

  static AccountingReport accountingReport(ReportsQuery q) => AccountingReport(
    generatedAt: DateTime.now(),
    rangeFrom: _from,
    rangeTo: _to,
    range: q.range,
    revenue: const AccountingRevenue(
      gross: 0,
      voidAmount: 0,
      service: 0,
      tax: 0,
      discount: 0,
      net: 0,
      collected: 0,
      refunded: 0,
      sessionCount: 0,
    ),
    methods: const [],
    voids: const [],
    discounts: const [],
    daily: const [],
  );

  static Map<String, Uint8List> historyPhotos(OrderHistory _) => const {};

  /// A stand-in payment proof, 96×128 — an amber header band over ink bars
  /// where a transfer slip carries its bank line, nominal and sender. Drawn
  /// rather than photographed so the book stays byte-tiny and offline, and
  /// portrait so the `cover` crop's edge-eating is visible in the thumb and
  /// gone in the lightbox. `PaymentProofThumb` takes it via `previewBytes`,
  /// which is the only way the book can show the loaded state at all — the
  /// real bytes come off a paired venue server.
  static final Uint8List proofSlip = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAGAAAACACAIAAAB7vvvtAAAA5ElEQVR42u3coQ'
    '2AMBBA0Y5DEBg2RRAU86G6AizQVFRQerzkT/DM5U5curdVlRICQIAAAQIECBAg'
    'FYFyvlQJECBAgAABAgQIkFqApnkZLkCAAAECBAgQIECA+gMJECBAgAABAuSiGD'
    'dAgAABAgQIECBAgAABAgQIECBAAgQIECBAgAAB2o+zS4AAAQIECJAxDwgQIECA'
    '7GJfDhAgQIAAARIgQIAAAbKLjXtaBQQIECBA8YAECBAgQIAAAQIESIAAvQ/0h2'
    'ekgAABAgQIECBAgAABAgQIUCwgAQIECBAgQIAAAVKxB2ko5Vq/7Pn2AAAAAElF'
    'TkSuQmCC',
  );

  static ReportsSnapshotDto get reportsSnapshot => ReportsSnapshotDto(
    generatedAt: DateTime.now().toIso8601String(),
    rangeFrom: _from.toIso8601String(),
    rangeTo: _to.toIso8601String(),
    range: reportRangeKey(ReportRange.today),
    filterOptions: const FilterOptionsDto(),
    sales: const SalesSectionDto(),
    staff: const StaffSectionDto(),
    menu: const MenuSectionDto(),
    ops: const OpsSectionDto(reservations: ReservationStatsDto()),
  );

  /// Six PINs so the pin sheet's debug-credential strip has something to fill.
  static const debugPins = <({String pin, String name, String role})>[
    (pin: '111111', name: 'Rani', role: 'Waiter'),
    (pin: '222222', name: 'Bagas', role: 'Kitchen'),
    (pin: '333333', name: 'Pak Hendra', role: 'Admin'),
  ];
}
