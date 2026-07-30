import 'package:satset/domain/models/audit_entry.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/domain/models/menu_category.dart';
import 'package:satset/domain/models/menu_item.dart';
import 'package:satset/domain/models/modifier_group.dart';
import 'package:satset/domain/models/role.dart';
import 'package:satset/domain/models/user.dart';
import 'package:satset/domain/models/venue_table.dart';
import 'package:satset/domain/models/zone.dart';

class Venue {
  static const name = 'Warung Sebelah';
  static const address = 'Berawa, Bali';
}

class DummyData {
  DummyData._();

  static const roleWaiterId = 'role-waiter';
  static const roleKitchenId = 'role-kitchen';
  static const roleManagerId = 'role-manager';
  static const roleKasirId = 'role-kasir';
  static const roleAdminId = 'role-admin';

  static const maya = AppUser(
    id: 'maya',
    name: 'Maya',
    initials: 'MA',
    role: UserRole.waiter,
    shiftStartedAt: '17:30',
    zoneAssigned: 'Terrace',
    roleId: roleWaiterId,
    pin: '100001',
    avatarColorHex: 0xFFC08AFF,
  );

  static const budi = AppUser(
    id: 'budi',
    name: 'Budi',
    initials: 'BU',
    role: UserRole.waiter,
    shiftStartedAt: '17:30',
    zoneAssigned: 'Garden',
    roleId: roleWaiterId,
    pin: '100002',
    avatarColorHex: 0xFF6DB5FF,
  );

  static const rina = AppUser(
    id: 'rina',
    name: 'Rina',
    initials: 'RI',
    role: UserRole.waiter,
    shiftStartedAt: '17:30',
    zoneAssigned: 'Indoor',
    roleId: roleWaiterId,
    pin: '100003',
    avatarColorHex: 0xFF4DD487,
  );

  static const koki = AppUser(
    id: 'koki',
    name: 'Komang',
    initials: 'KT',
    role: UserRole.kitchen,
    shiftStartedAt: '16:30',
    zoneAssigned: '—',
    roleId: roleKitchenId,
    pin: '100004',
    avatarColorHex: 0xFFFF9233,
  );

  static const bos = AppUser(
    id: 'bos',
    name: 'Pak Nyoman',
    initials: 'PN',
    role: UserRole.admin,
    shiftStartedAt: '17:00',
    zoneAssigned: '—',
    roleId: roleAdminId,
    pin: '100000',
    avatarColorHex: 0xFFFFC04D,
  );

  static const users = <AppUser>[maya, budi, rina, koki, bos];

  static List<Role> initialRoles() => <Role>[
    Role(
      id: roleAdminId,
      name: 'Admin',
      colorHex: 0xFFC08AFF,
      capabilities: Capability.values.toSet(),
    ),
    Role(
      id: roleManagerId,
      name: 'Manager',
      colorHex: 0xFF6DB5FF,
      capabilities: const {
        Capability.takeOrder,
        Capability.modifyOrder,
        Capability.voidItem,
        Capability.compItem,
        Capability.viewKds,
        Capability.openDrawer,
        Capability.applyDiscount,
        Capability.settleBill,
        Capability.refund,
        Capability.closeShift,
        Capability.editMenu,
        Capability.markSoldOut,
        Capability.adjustStock,
        Capability.manageStaff,
        Capability.viewReports,
        Capability.editSettings,
      },
    ),
    // The cashier role CONTEXT.md described but the seed never created —
    // without it no seeded non-Admin user could reach the money screen.
    // Deliberately WITHOUT applyDiscount (ADR-0037): a cashier reaches a
    // discount through manager step-up unless the owner grants it. refund
    // likewise stays manager-approved and is not auto-granted.
    Role(
      id: roleKasirId,
      name: 'Kasir',
      colorHex: 0xFF4DD487,
      capabilities: const {Capability.settleBill, Capability.openDrawer},
    ),
    Role(
      id: roleWaiterId,
      name: 'Waiter',
      colorHex: 0xFFFF9233,
      capabilities: const {Capability.takeOrder, Capability.modifyOrder},
    ),
    Role(
      id: roleKitchenId,
      name: 'Kitchen',
      colorHex: 0xFFFF5C5C,
      capabilities: const {Capability.viewKds, Capability.markSoldOut},
    ),
  ];

  static AppUser? userById(String? id) {
    if (id == null) return null;
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  static const zones = <Zone>[
    Zone(
      id: 'terrace',
      name: 'Teras',
      short: 'Ter',
      colorHex: 0xFFFF9233,
      iconKey: 'deck',
    ),
    Zone(
      id: 'garden',
      name: 'Taman',
      short: 'Tam',
      colorHex: 0xFF4DD487,
      iconKey: 'park',
    ),
    Zone(
      id: 'indoor',
      name: 'Dalam',
      short: 'Dlm',
      colorHex: 0xFF6DB5FF,
      iconKey: 'weekend',
    ),
    Zone(
      id: 'bar',
      name: 'Bar',
      short: 'Bar',
      colorHex: 0xFFC08AFF,
      iconKey: 'localBar',
    ),
  ];

  static const tables = <VenueTable>[
    VenueTable(
      id: 'T1',
      zoneId: 'terrace',
      pax: 2,
      status: TableStatus.occupied,
      elapsed: '0:18',
      openAmount: 245000,
      lastActorId: 'maya',
    ),
    VenueTable(
      id: 'T2',
      zoneId: 'terrace',
      pax: 4,
      status: TableStatus.ready,
      elapsed: '0:42',
      openAmount: 612000,
      readyCount: 2,
      lastActorId: 'maya',
    ),
    VenueTable(
      id: 'T3',
      zoneId: 'terrace',
      pax: 2,
      status: TableStatus.available,
    ),
    VenueTable(
      id: 'T4',
      zoneId: 'terrace',
      pax: 6,
      status: TableStatus.pending,
      elapsed: '0:08',
      lastActorId: 'maya',
    ),
    VenueTable(
      id: 'T5',
      zoneId: 'terrace',
      pax: 3,
      status: TableStatus.occupied,
      elapsed: '1:14',
      openAmount: 880000,
      lastActorId: 'rina',
    ),
    VenueTable(
      id: 'T6',
      zoneId: 'terrace',
      pax: 2,
      status: TableStatus.available,
    ),
    VenueTable(
      id: 'G1',
      zoneId: 'garden',
      pax: 4,
      status: TableStatus.occupied,
      elapsed: '0:32',
      openAmount: 425000,
      lastActorId: 'budi',
    ),
    VenueTable(
      id: 'G2',
      zoneId: 'garden',
      pax: 2,
      status: TableStatus.available,
    ),
    VenueTable(
      id: 'G3',
      zoneId: 'garden',
      pax: 5,
      status: TableStatus.occupied,
      elapsed: '0:54',
      openAmount: 690000,
      lastActorId: 'budi',
    ),
    VenueTable(
      id: 'G4',
      zoneId: 'garden',
      pax: 2,
      status: TableStatus.ready,
      elapsed: '0:21',
      openAmount: 180000,
      readyCount: 1,
      lastActorId: 'budi',
    ),
    VenueTable(
      id: 'I1',
      zoneId: 'indoor',
      pax: 2,
      status: TableStatus.available,
    ),
    VenueTable(
      id: 'I2',
      zoneId: 'indoor',
      pax: 4,
      status: TableStatus.occupied,
      elapsed: '0:46',
      openAmount: 535000,
      lastActorId: 'rina',
    ),
    VenueTable(
      id: 'I3',
      zoneId: 'indoor',
      pax: 2,
      status: TableStatus.pending,
      elapsed: '0:03',
      lastActorId: 'rina',
    ),
    VenueTable(
      id: 'I4',
      zoneId: 'indoor',
      pax: 4,
      status: TableStatus.occupied,
      elapsed: '1:32',
      openAmount: 1120000,
      lastActorId: 'rina',
    ),
    VenueTable(
      id: 'I5',
      zoneId: 'indoor',
      pax: 6,
      status: TableStatus.available,
    ),
    VenueTable(
      id: 'I6',
      zoneId: 'indoor',
      pax: 2,
      status: TableStatus.occupied,
      elapsed: '0:12',
      openAmount: 95000,
      lastActorId: 'budi',
    ),
    VenueTable(
      id: 'B1',
      zoneId: 'bar',
      pax: 2,
      status: TableStatus.occupied,
      elapsed: '0:24',
      openAmount: 145000,
      lastActorId: 'maya',
    ),
    VenueTable(id: 'B2', zoneId: 'bar', pax: 1, status: TableStatus.available),
    VenueTable(id: 'B3', zoneId: 'bar', pax: 3, status: TableStatus.available),
    VenueTable(
      id: 'B4',
      zoneId: 'bar',
      pax: 2,
      status: TableStatus.occupied,
      elapsed: '0:38',
      openAmount: 270000,
      lastActorId: 'rina',
    ),
  ];

  static const categories = <MenuCategory>[
    MenuCategory(id: 'all', name: 'Semua'),
    MenuCategory(id: 'starters', name: 'Pembuka'),
    MenuCategory(id: 'mains', name: 'Utama'),
    MenuCategory(id: 'sides', name: 'Pendamping'),
    MenuCategory(id: 'desserts', name: 'Penutup'),
    MenuCategory(id: 'cocktails', name: 'Cocktail'),
    MenuCategory(id: 'wine', name: 'Anggur'),
    MenuCategory(id: 'beer', name: 'Bir'),
    MenuCategory(id: 'soft', name: 'Non-alkohol'),
  ];

  static final items = <MenuItem>[
    MenuItem(
      id: 'gado-gado',
      name: 'Gado-Gado',
      categoryId: 'starters',
      description: 'Sayur kukus, tahu, tempe, telur rebus, saus kacang',
      allergens: const ['nut', 'soy', 'egg'],
      prepTime: 8,
      basePrice: 65000,
      variants: const [Variant(id: 'reg', name: '', price: 65000)],
      modifierGroups: const [
        ModifierGroup(
          id: 'sauce',
          name: 'Saus kacang',
          required: true,
          options: [
            ModifierOption(id: 'mild', name: 'Sedikit pedas'),
            ModifierOption(id: 'medium', name: 'Sedang'),
            ModifierOption(id: 'spicy', name: 'Pedas'),
            ModifierOption(id: 'side', name: 'Saus di pinggir'),
          ],
        ),
      ],
    ),
    MenuItem(
      id: 'lumpia',
      name: 'Lumpia Renyah (4 buah)',
      categoryId: 'starters',
      description: 'Lumpia goreng isi sayur dan ayam, saus cabai manis',
      allergens: const ['gluten', 'egg'],
      prepTime: 7,
      basePrice: 55000,
      variants: const [Variant(id: 'reg', name: '', price: 55000)],
    ),
    MenuItem(
      id: 'sate-ayam',
      name: 'Sate Ayam (4 tusuk)',
      categoryId: 'starters',
      description: 'Sate ayam bakar, saus kacang, lontong',
      allergens: const ['nut', 'soy'],
      prepTime: 10,
      basePrice: 75000,
      variants: const [Variant(id: 'reg', name: '', price: 75000)],
    ),
    MenuItem(
      id: 'nasi-goreng',
      name: 'Nasi Goreng',
      categoryId: 'mains',
      description: 'Nasi goreng dengan terasi, bawang goreng, telur, krupuk',
      allergens: const ['shellfish', 'egg', 'gluten'],
      prepTime: 12,
      basePrice: 85000,
      variants: const [
        Variant(id: 'reg', name: 'Reguler', price: 85000),
        Variant(id: 'lg', name: 'Besar', price: 110000),
      ],
      modifierGroups: const [
        ModifierGroup(
          id: 'protein',
          name: 'Pilih protein',
          required: true,
          options: [
            ModifierOption(id: 'chicken', name: 'Ayam'),
            ModifierOption(id: 'beef', name: 'Sapi', priceDelta: 15000),
            ModifierOption(id: 'prawn', name: 'Udang', priceDelta: 20000),
            ModifierOption(id: 'tofu', name: 'Tahu', priceDelta: -5000),
            ModifierOption(
              id: 'none',
              name: 'Tanpa protein',
              priceDelta: -10000,
            ),
          ],
        ),
        ModifierGroup(
          id: 'spice',
          name: 'Tingkat pedas',
          required: true,
          options: [
            ModifierOption(id: 'no', name: 'Tidak pedas'),
            ModifierOption(id: 'mi', name: 'Sedikit pedas'),
            ModifierOption(id: 'md', name: 'Sedang'),
            ModifierOption(id: 'hot', name: 'Pedas'),
            ModifierOption(id: 'xhot', name: 'Sangat pedas'),
          ],
        ),
        ModifierGroup(
          id: 'extras',
          name: 'Tambahan',
          multi: true,
          options: [
            ModifierOption(
              id: 'krupuk',
              name: 'Krupuk ekstra',
              priceDelta: 8000,
            ),
            ModifierOption(
              id: 'satay',
              name: 'Sate Ayam (2 tusuk)',
              priceDelta: 25000,
            ),
            ModifierOption(
              id: 'egg',
              name: 'Telur ceplok ekstra',
              priceDelta: 10000,
            ),
            ModifierOption(
              id: 'sambal',
              name: 'Sambal di pinggir',
              priceDelta: 5000,
            ),
          ],
        ),
      ],
    ),
    MenuItem(
      id: 'rendang',
      name: 'Rendang Sapi',
      categoryId: 'mains',
      description:
          'Sapi rendang Padang, santan, serai, cabai. Dengan nasi uduk.',
      allergens: const ['nut'],
      prepTime: 14,
      basePrice: 145000,
      variants: const [Variant(id: 'reg', name: '', price: 145000)],
      modifierGroups: const [
        ModifierGroup(
          id: 'rice',
          name: 'Nasi',
          required: true,
          options: [
            ModifierOption(id: 'coconut', name: 'Nasi uduk'),
            ModifierOption(id: 'steamed', name: 'Nasi putih'),
            ModifierOption(
              id: 'no-rice',
              name: 'Tanpa nasi',
              priceDelta: -10000,
            ),
          ],
        ),
      ],
    ),
    MenuItem(
      id: 'mie-goreng',
      name: 'Mie Goreng',
      categoryId: 'mains',
      description: 'Mie telur tumis, sayur, bawang goreng',
      allergens: const ['gluten', 'egg', 'soy'],
      prepTime: 10,
      basePrice: 80000,
      variants: const [Variant(id: 'reg', name: '', price: 80000)],
    ),
    MenuItem(
      id: 'burger',
      name: 'Burger Wagyu',
      categoryId: 'mains',
      description:
          'Daging wagyu, keju, roti brioche, acar rumahan, kentang goreng',
      allergens: const ['gluten', 'dairy', 'egg'],
      prepTime: 13,
      basePrice: 165000,
      unavailable: true,
      variants: const [Variant(id: 'reg', name: '', price: 165000)],
    ),
    MenuItem(
      id: 'crispy-tempeh',
      name: 'Tempe Sambal Bowl',
      categoryId: 'mains',
      description: 'Tempe sambal, nasi uduk, sayur acar, telur ceplok',
      allergens: const ['soy', 'egg', 'gluten'],
      prepTime: 11,
      basePrice: 95000,
      variants: const [Variant(id: 'reg', name: '', price: 95000)],
    ),
    MenuItem(
      id: 'krupuk-side',
      name: 'Krupuk',
      categoryId: 'sides',
      description: 'Krupuk udang',
      allergens: const ['shellfish'],
      prepTime: 2,
      basePrice: 15000,
      variants: const [Variant(id: 'reg', name: '', price: 15000)],
    ),
    MenuItem(
      id: 'pisang',
      name: 'Pisang Goreng',
      categoryId: 'desserts',
      description: 'Pisang goreng, saus gula merah, es krim vanila',
      allergens: const ['gluten', 'dairy', 'egg'],
      prepTime: 8,
      basePrice: 55000,
      variants: const [Variant(id: 'reg', name: '', price: 55000)],
      modifierGroups: const [
        ModifierGroup(
          id: 'ic',
          name: 'Es krim',
          required: true,
          options: [
            ModifierOption(id: 'vanilla', name: 'Vanila'),
            ModifierOption(id: 'coconut', name: 'Kelapa'),
            ModifierOption(
              id: 'none',
              name: 'Tanpa es krim',
              priceDelta: -10000,
            ),
          ],
        ),
      ],
    ),
    MenuItem(
      id: 'es-teh',
      name: 'Es Teh Manis',
      categoryId: 'soft',
      description: 'Iced sweet jasmine tea',
      prepTime: 2,
      basePrice: 25000,
      variants: const [Variant(id: 'reg', name: '', price: 25000)],
      modifierGroups: const [
        ModifierGroup(
          id: 'sweet',
          name: 'Tingkat manis',
          options: [
            ModifierOption(id: 'less', name: 'Kurang manis'),
            ModifierOption(id: 'norm', name: 'Normal'),
            ModifierOption(id: 'extra', name: 'Ekstra manis'),
          ],
        ),
      ],
    ),
    MenuItem(
      id: 'bintang',
      name: 'Bintang Pilsner',
      categoryId: 'beer',
      description: '330ml. Lager paling populer di Indonesia.',
      allergens: const ['gluten'],
      prepTime: 1,
      basePrice: 45000,
      variants: const [Variant(id: 'reg', name: '', price: 45000)],
    ),
    MenuItem(
      id: 'margarita',
      name: 'Spicy Margarita',
      categoryId: 'cocktails',
      description: 'Tequila, lime, agave, cabai segar, garam asap',
      prepTime: 4,
      basePrice: 110000,
      variants: const [Variant(id: 'reg', name: '', price: 110000)],
    ),
    MenuItem(
      id: 'negroni',
      name: 'Negroni',
      categoryId: 'cocktails',
      description: 'Gin, Campari, sweet vermouth, kulit jeruk',
      prepTime: 4,
      basePrice: 130000,
      variants: const [Variant(id: 'reg', name: '', price: 130000)],
    ),
    MenuItem(
      id: 'rose',
      name: 'House Rosé',
      categoryId: 'wine',
      description: 'Crisp, dry, Provence-style',
      allergens: const ['sulfites'],
      prepTime: 1,
      basePrice: 95000,
      variants: const [
        Variant(id: 'glass', name: 'Gelas', price: 95000),
        Variant(id: 'bottle', name: 'Botol', price: 485000),
      ],
    ),
    MenuItem(
      id: 'kombucha',
      name: 'House Kombucha',
      categoryId: 'soft',
      description: 'Jahe-jeruk nipis, fermentasi di tempat',
      prepTime: 1,
      basePrice: 38000,
      variants: const [Variant(id: 'reg', name: '', price: 38000)],
    ),
  ];

  static MenuItem itemById(String id) => items.firstWhere((i) => i.id == id);

  // ---------------------------------------------------------------------------
  // Generic restaurant seed (prompted on first run — see ADR-0017).
  // A minimal, clean starter set: 2 zones x 2 tables, 2 staff (1 waiter +
  // 1 kitchen), and the generic menu above. NO PIN admin (admin is
  // Firebase-only) and NO fake report history.
  // ---------------------------------------------------------------------------

  /// Roles offered by the generic seed. The shared **admin** role is infra
  /// (always seeded, not here) and the **manager** role is intentionally
  /// omitted — it carries `manageStaff`, which the staff screen forbids
  /// assigning now that admin is Firebase-only.
  static List<Role> genericRoles() => <Role>[
    Role(
      id: roleWaiterId,
      name: 'Waiter',
      colorHex: 0xFFFF9233,
      capabilities: const {
        Capability.takeOrder,
        Capability.modifyOrder,
        Capability.voidItem,
        Capability.settleBill,
      },
    ),
    Role(
      id: roleKitchenId,
      name: 'Kitchen',
      colorHex: 0xFFFF5C5C,
      capabilities: const {
        Capability.viewKds,
        Capability.markSoldOut,
        // The people who physically receive and count stock are the ones
        // who record it (ADR-0042). `overrideStock` stays a deliberate
        // grant — no seeded role sells past zero by default.
        Capability.adjustStock,
        Capability.manageIngredients,
      },
    ),
  ];

  static const genericWaiter = AppUser(
    id: 'seed-waiter',
    name: 'Pelayan',
    initials: 'PL',
    role: UserRole.waiter,
    shiftStartedAt: '',
    zoneAssigned: 'Dalam',
    roleId: roleWaiterId,
    pin: '100001',
    avatarColorHex: 0xFFC08AFF,
  );

  static const genericKitchen = AppUser(
    id: 'seed-kitchen',
    name: 'Dapur',
    initials: 'DP',
    role: UserRole.kitchen,
    shiftStartedAt: '',
    zoneAssigned: '—',
    roleId: roleKitchenId,
    pin: '100002',
    avatarColorHex: 0xFFFF9233,
  );

  static const genericUsers = <AppUser>[genericWaiter, genericKitchen];

  static const genericZones = <Zone>[
    Zone(
      id: 'indoor',
      name: 'Dalam',
      short: 'Dlm',
      colorHex: 0xFF6DB5FF,
      iconKey: 'weekend',
    ),
    Zone(
      id: 'outdoor',
      name: 'Luar',
      short: 'Luar',
      colorHex: 0xFF4DD487,
      iconKey: 'deck',
    ),
  ];

  static const genericTables = <VenueTable>[
    VenueTable(
      id: 'D1',
      zoneId: 'indoor',
      pax: 2,
      status: TableStatus.available,
    ),
    VenueTable(
      id: 'D2',
      zoneId: 'indoor',
      pax: 4,
      status: TableStatus.available,
    ),
    VenueTable(
      id: 'L1',
      zoneId: 'outdoor',
      pax: 2,
      status: TableStatus.available,
    ),
    VenueTable(
      id: 'L2',
      zoneId: 'outdoor',
      pax: 4,
      status: TableStatus.available,
    ),
  ];

  static List<AuditEntry> initialAudit() => const [
    AuditEntry(
      id: 'A0',
      type: AuditType.fire,
      title: 'Course Utama dibakar untuk Meja T1',
      tableId: 'T1',
      when: '17:46',
    ),
  ];
}
