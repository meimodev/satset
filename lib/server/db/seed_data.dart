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
        // A manager is exactly who spends from the box (§Kas kecil). Admin gets
        // it via `Capability.values`; every other role must ask for it.
        Capability.manageCash,
        Capability.sellOpenItem,
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
      capabilities: const {
        Capability.settleBill,
        Capability.openDrawer,
        // The counter till types the odd unlisted line; a waiter does not.
        Capability.sellOpenItem,
      },
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

    // ---- Pembuka ----
    MenuItem(
      id: 'tahu-isi',
      name: 'Tahu Isi (4 buah)',
      categoryId: 'starters',
      description: 'Tahu goreng isi sayur, saus cabai rawit',
      allergens: const ['soy', 'gluten'],
      prepTime: 8,
      basePrice: 48000,
      variants: const [Variant(id: 'reg', name: '', price: 48000)],
    ),
    MenuItem(
      id: 'perkedel',
      name: 'Perkedel Kentang (5 buah)',
      categoryId: 'starters',
      description: 'Kentang tumbuk, bawang goreng, telur',
      allergens: const ['egg'],
      prepTime: 9,
      basePrice: 45000,
      variants: const [Variant(id: 'reg', name: '', price: 45000)],
    ),
    MenuItem(
      id: 'sate-lilit',
      name: 'Sate Lilit Ikan (5 tusuk)',
      categoryId: 'starters',
      description: 'Ikan cincang, kelapa parut, bumbu Bali, batang serai',
      allergens: const ['fish'],
      prepTime: 11,
      basePrice: 78000,
      variants: const [Variant(id: 'reg', name: '', price: 78000)],
    ),

    // ---- Utama ----
    MenuItem(
      id: 'ayam-bakar',
      name: 'Ayam Bakar Bumbu Bali',
      categoryId: 'mains',
      description: 'Setengah ayam bakar arang, sambal matah, nasi putih',
      prepTime: 18,
      basePrice: 95000,
      variants: const [
        Variant(id: 'half', name: 'Setengah', price: 95000),
        Variant(id: 'whole', name: 'Utuh', price: 165000),
      ],
      modifierGroups: const [
        ModifierGroup(
          id: 'spice',
          name: 'Tingkat pedas',
          required: true,
          options: [
            ModifierOption(id: 'no', name: 'Tidak pedas'),
            ModifierOption(id: 'md', name: 'Sedang'),
            ModifierOption(id: 'hot', name: 'Pedas'),
          ],
        ),
      ],
    ),
    MenuItem(
      id: 'ikan-bakar',
      name: 'Ikan Bakar Jimbaran',
      categoryId: 'mains',
      description: 'Ikan segar bakar sambal matah, jeruk nipis, nasi putih',
      allergens: const ['fish'],
      prepTime: 20,
      basePrice: 125000,
      variants: const [Variant(id: 'reg', name: '', price: 125000)],
    ),
    MenuItem(
      id: 'bebek-goreng',
      name: 'Bebek Goreng Crispy',
      categoryId: 'mains',
      description: 'Bebek ungkep, digoreng renyah, sambal ijo, lalapan',
      prepTime: 22,
      basePrice: 135000,
      variants: const [Variant(id: 'reg', name: '', price: 135000)],
    ),
    MenuItem(
      id: 'nasi-campur',
      name: 'Nasi Campur Bali',
      categoryId: 'mains',
      description: 'Nasi, ayam sisit, telur, urap, krupuk, sambal',
      allergens: const ['egg', 'shellfish'],
      prepTime: 14,
      basePrice: 92000,
      variants: const [Variant(id: 'reg', name: '', price: 92000)],
      modifierGroups: const [
        ModifierGroup(
          id: 'spice',
          name: 'Tingkat pedas',
          required: true,
          options: [
            ModifierOption(id: 'no', name: 'Tidak pedas'),
            ModifierOption(id: 'md', name: 'Sedang'),
            ModifierOption(id: 'hot', name: 'Pedas'),
          ],
        ),
      ],
    ),
    MenuItem(
      id: 'cap-cay',
      name: 'Cap Cay Goreng',
      categoryId: 'mains',
      description: 'Sayur campur, udang, bakso ikan, saus tiram',
      allergens: const ['shellfish', 'soy'],
      prepTime: 12,
      basePrice: 78000,
      variants: const [Variant(id: 'reg', name: '', price: 78000)],
      modifierGroups: const [
        ModifierGroup(
          id: 'protein',
          name: 'Pilih protein',
          required: true,
          options: [
            ModifierOption(id: 'prawn', name: 'Udang'),
            ModifierOption(id: 'chicken', name: 'Ayam', priceDelta: -8000),
            ModifierOption(id: 'veg', name: 'Sayur saja', priceDelta: -15000),
          ],
        ),
      ],
    ),
    MenuItem(
      id: 'soto-ayam',
      name: 'Soto Ayam',
      categoryId: 'mains',
      description: 'Kuah kunyit, suwiran ayam, soun, telur, bawang goreng',
      allergens: const ['egg'],
      prepTime: 13,
      basePrice: 72000,
      variants: const [Variant(id: 'reg', name: '', price: 72000)],
    ),
    MenuItem(
      id: 'pepes-tahu',
      name: 'Pepes Tahu Kemangi',
      categoryId: 'mains',
      description: 'Tahu bumbu kuning, kemangi, dibungkus daun pisang',
      allergens: const ['soy'],
      prepTime: 16,
      basePrice: 62000,
      dietary: const ['vegan'],
      variants: const [Variant(id: 'reg', name: '', price: 62000)],
    ),

    // ---- Pendamping ----
    MenuItem(
      id: 'nasi-putih',
      name: 'Nasi Putih',
      categoryId: 'sides',
      description: 'Semangkuk nasi kukus',
      prepTime: 2,
      basePrice: 18000,
      dietary: const ['vegan'],
      variants: const [Variant(id: 'reg', name: '', price: 18000)],
    ),
    MenuItem(
      id: 'kentang-goreng',
      name: 'Kentang Goreng',
      categoryId: 'sides',
      description: 'Potongan tebal, garam laut, mayo sambal',
      allergens: const ['egg'],
      prepTime: 8,
      basePrice: 42000,
      variants: const [Variant(id: 'reg', name: '', price: 42000)],
    ),
    MenuItem(
      id: 'sayur-urap',
      name: 'Urap Sayur',
      categoryId: 'sides',
      description: 'Sayur kukus, kelapa parut berbumbu',
      prepTime: 6,
      basePrice: 35000,
      dietary: const ['vegan'],
      variants: const [Variant(id: 'reg', name: '', price: 35000)],
    ),
    MenuItem(
      id: 'telur-balado',
      name: 'Telur Balado (2 butir)',
      categoryId: 'sides',
      description: 'Telur rebus goreng, sambal balado',
      allergens: const ['egg'],
      prepTime: 7,
      basePrice: 32000,
      variants: const [Variant(id: 'reg', name: '', price: 32000)],
    ),

    // ---- Penutup ----
    MenuItem(
      id: 'es-campur',
      name: 'Es Campur',
      categoryId: 'desserts',
      description: 'Es serut, santan, sirup, buah, es krim kelapa',
      allergens: const ['dairy'],
      prepTime: 6,
      basePrice: 48000,
      variants: const [Variant(id: 'reg', name: '', price: 48000)],
    ),
    MenuItem(
      id: 'dadar-gulung',
      name: 'Dadar Gulung (3 buah)',
      categoryId: 'desserts',
      description: 'Dadar pandan isi kelapa gula merah',
      allergens: const ['gluten', 'egg'],
      prepTime: 8,
      basePrice: 42000,
      variants: const [Variant(id: 'reg', name: '', price: 42000)],
    ),
    MenuItem(
      id: 'panna-cotta',
      name: 'Panna Cotta Kelapa',
      categoryId: 'desserts',
      description: 'Santan, gula aren, kelapa panggang',
      prepTime: 4,
      basePrice: 55000,
      variants: const [Variant(id: 'reg', name: '', price: 55000)],
    ),

    // ---- Cocktail / Anggur ----
    // Seeded without a resep on purpose, like the cocktails above: an item
    // with no recipe consumes nothing and never goes auto-habis (ADR-0040 §4).
    MenuItem(
      id: 'mojito',
      name: 'Mojito',
      categoryId: 'cocktails',
      description: 'Rum putih, mint, lime, soda',
      prepTime: 4,
      basePrice: 105000,
      variants: const [Variant(id: 'reg', name: '', price: 105000)],
    ),
    MenuItem(
      id: 'espresso-martini',
      name: 'Espresso Martini',
      categoryId: 'cocktails',
      description: 'Vodka, kopi espresso, kahlua',
      prepTime: 5,
      basePrice: 135000,
      variants: const [Variant(id: 'reg', name: '', price: 135000)],
    ),
    MenuItem(
      id: 'sauvignon',
      name: 'Sauvignon Blanc',
      categoryId: 'wine',
      description: 'Marlborough, kering, aroma jeruk',
      allergens: const ['sulfites'],
      prepTime: 1,
      basePrice: 105000,
      variants: const [
        Variant(id: 'glass', name: 'Gelas', price: 105000),
        Variant(id: 'bottle', name: 'Botol', price: 545000),
      ],
    ),
    MenuItem(
      id: 'shiraz',
      name: 'Shiraz',
      categoryId: 'wine',
      description: 'Barossa, penuh, aroma buah gelap',
      allergens: const ['sulfites'],
      prepTime: 1,
      basePrice: 115000,
      variants: const [
        Variant(id: 'glass', name: 'Gelas', price: 115000),
        Variant(id: 'bottle', name: 'Botol', price: 595000),
      ],
    ),

    // ---- Bir ----
    MenuItem(
      id: 'bali-hai',
      name: 'Bali Hai',
      categoryId: 'beer',
      description: '330ml. Lager lokal, ringan.',
      allergens: const ['gluten'],
      prepTime: 1,
      basePrice: 40000,
      variants: const [Variant(id: 'reg', name: '', price: 40000)],
    ),
    MenuItem(
      id: 'guinness',
      name: 'Guinness Draught',
      categoryId: 'beer',
      description: '330ml. Stout, impor.',
      allergens: const ['gluten'],
      prepTime: 1,
      basePrice: 78000,
      variants: const [Variant(id: 'reg', name: '', price: 78000)],
    ),

    // ---- Non-alkohol ----
    MenuItem(
      id: 'es-jeruk',
      name: 'Es Jeruk Peras',
      categoryId: 'soft',
      description: 'Jeruk peras segar, es batu',
      prepTime: 2,
      basePrice: 30000,
      dietary: const ['vegan'],
      variants: const [Variant(id: 'reg', name: '', price: 30000)],
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
      id: 'kopi-susu',
      name: 'Es Kopi Susu',
      categoryId: 'soft',
      description: 'Espresso, susu segar, gula aren',
      allergens: const ['dairy'],
      prepTime: 3,
      basePrice: 35000,
      variants: const [Variant(id: 'reg', name: '', price: 35000)],
    ),
    MenuItem(
      id: 'air-mineral',
      name: 'Air Mineral',
      categoryId: 'soft',
      description: '600ml, dingin atau suhu ruang',
      prepTime: 1,
      basePrice: 15000,
      dietary: const ['vegan'],
      variants: const [Variant(id: 'reg', name: '', price: 15000)],
    ),
  ];

  static MenuItem itemById(String id) => items.firstWhere((i) => i.id == id);

  // ---------------------------------------------------------------------------
  // Generic restaurant seed (prompted on first run — see ADR-0017).
  // A minimal, clean starter set: 4 zones / 20 tables, 4 staff (2 waiters +
  // 2 kitchen), and the generic menu above. NO PIN admin (admin is
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

  /// Two of each front-of-house role, so a seeded venue can show work split
  /// between people: the reports' Pelayan column, the per-waiter void
  /// accountability (ADR-0006) and the audit log all read as one name
  /// repeated when there is only ever one waiter to attribute to.
  ///
  /// `zoneAssigned` is matched against zone **names**, not ids — these must
  /// stay spelled as [genericZones] spells them.
  static const genericWaiter = AppUser(
    id: 'seed-waiter',
    name: 'Pelayan 1',
    initials: 'P1',
    role: UserRole.waiter,
    shiftStartedAt: '',
    zoneAssigned: 'Dalam',
    roleId: roleWaiterId,
    pin: '100001',
    avatarColorHex: 0xFFC08AFF,
  );

  static const genericWaiter2 = AppUser(
    id: 'seed-waiter-2',
    name: 'Pelayan 2',
    initials: 'P2',
    role: UserRole.waiter,
    shiftStartedAt: '',
    zoneAssigned: 'Luar',
    roleId: roleWaiterId,
    pin: '100003',
    avatarColorHex: 0xFF6DB5FF,
  );

  static const genericKitchen = AppUser(
    id: 'seed-kitchen',
    name: 'Dapur 1',
    initials: 'D1',
    role: UserRole.kitchen,
    shiftStartedAt: '',
    zoneAssigned: '—',
    roleId: roleKitchenId,
    pin: '100002',
    avatarColorHex: 0xFFFF9233,
  );

  static const genericKitchen2 = AppUser(
    id: 'seed-kitchen-2',
    name: 'Dapur 2',
    initials: 'D2',
    role: UserRole.kitchen,
    shiftStartedAt: '',
    zoneAssigned: '—',
    roleId: roleKitchenId,
    pin: '100004',
    avatarColorHex: 0xFF4DD487,
  );

  static const genericUsers = <AppUser>[
    genericWaiter,
    genericWaiter2,
    genericKitchen,
    genericKitchen2,
  ];

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
    Zone(
      id: 'teras',
      name: 'Teras',
      short: 'Trs',
      colorHex: 0xFFFF9233,
      iconKey: 'balcony',
    ),
    Zone(
      id: 'vip',
      name: 'VIP',
      short: 'VIP',
      colorHex: 0xFFC08AFF,
      iconKey: 'celebration',
    ),
  ];

  /// Twenty tables across the four zones, pax 2–10. Sized so the floor screen
  /// has genuine density and a zone filter changes what you see; the seeded
  /// month spreads its ~1500 bills across all of them (ADR-0073).
  ///
  /// `D1`/`D2`/`L1`/`L2` keep their original ids: the seed is idempotent and
  /// re-postable, and renaming them would orphan an existing install's tables.
  static const genericTables = <VenueTable>[
    // Dalam — the covered room.
    VenueTable(id: 'D1', zoneId: 'indoor', pax: 2),
    VenueTable(id: 'D2', zoneId: 'indoor', pax: 4),
    VenueTable(id: 'D3', zoneId: 'indoor', pax: 4),
    VenueTable(id: 'D4', zoneId: 'indoor', pax: 6),
    VenueTable(id: 'D5', zoneId: 'indoor', pax: 2),
    VenueTable(id: 'D6', zoneId: 'indoor', pax: 8),
    // Luar — the garden.
    VenueTable(id: 'L1', zoneId: 'outdoor', pax: 2),
    VenueTable(id: 'L2', zoneId: 'outdoor', pax: 4),
    VenueTable(id: 'L3', zoneId: 'outdoor', pax: 4),
    VenueTable(id: 'L4', zoneId: 'outdoor', pax: 6),
    VenueTable(id: 'L5', zoneId: 'outdoor', pax: 2),
    // Teras — street-facing, the two-tops that turn fastest.
    VenueTable(id: 'T1', zoneId: 'teras', pax: 2),
    VenueTable(id: 'T2', zoneId: 'teras', pax: 2),
    VenueTable(id: 'T3', zoneId: 'teras', pax: 4),
    VenueTable(id: 'T4', zoneId: 'teras', pax: 4),
    VenueTable(id: 'T5', zoneId: 'teras', pax: 6),
    // VIP — the big-party room; few covers, the largest bills.
    VenueTable(id: 'V1', zoneId: 'vip', pax: 4),
    VenueTable(id: 'V2', zoneId: 'vip', pax: 6),
    VenueTable(id: 'V3', zoneId: 'vip', pax: 8),
    VenueTable(id: 'V4', zoneId: 'vip', pax: 10),
  ];
}
