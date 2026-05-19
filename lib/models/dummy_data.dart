import '../models/user.dart';
import '../models/zone.dart';
import '../models/venue_table.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../models/modifier_group.dart';
import '../models/order.dart';
import '../models/inventory_item.dart';

class DummyData {
  DummyData._();

  static final users = [
    const User(id: 'u1', username: 'admin', displayName: 'Admin', role: UserRole.admin),
    const User(id: 'u2', username: 'chef', displayName: 'Chef Rina', role: UserRole.chef),
    const User(id: 'u3', username: 'waiter', displayName: 'Budi Setiawan', role: UserRole.waiter),
    const User(id: 'u4', username: 'manager', displayName: 'Maya Putri', role: UserRole.manager),
  ];

  static final zones = [
    const Zone(id: 'z1', name: 'Lantai Utama', description: 'Area makan dalam ruangan', sortOrder: 0),
    const Zone(id: 'z2', name: 'Teras', description: 'Area makan luar ruangan', sortOrder: 1),
    const Zone(id: 'z3', name: 'Ruang VIP', description: 'Akses khusus', sortOrder: 2),
  ];

  static final tables = [
    // Main Floor
    const VenueTable(id: 't1', zoneId: 'z1', label: '12', capacity: 4, status: TableStatus.ordering, guestCount: 4),
    const VenueTable(id: 't2', zoneId: 'z1', label: '14', capacity: 2, status: TableStatus.waiting, guestCount: 2),
    const VenueTable(id: 't3', zoneId: 'z1', label: '15', capacity: 4, status: TableStatus.empty),
    const VenueTable(id: 't4', zoneId: 'z1', label: '16', capacity: 2, status: TableStatus.empty),
    const VenueTable(id: 't5', zoneId: 'z1', label: '18', capacity: 6, status: TableStatus.ready, guestCount: 6),
    const VenueTable(id: 't6', zoneId: 'z1', label: '20', capacity: 4, status: TableStatus.ordering, guestCount: 3),
    const VenueTable(id: 't7', zoneId: 'z1', label: '22', capacity: 4, status: TableStatus.ordering, guestCount: 4),
    const VenueTable(id: 't8', zoneId: 'z1', label: '24', capacity: 2, status: TableStatus.empty),
    const VenueTable(id: 't9', zoneId: 'z1', label: 'B1', capacity: 6, status: TableStatus.ordering, guestCount: 6, isBooth: true),
    const VenueTable(id: 't10', zoneId: 'z1', label: 'B2', capacity: 6, status: TableStatus.empty, isBooth: true),
    // Terrace
    const VenueTable(id: 't11', zoneId: 'z2', label: 'T1', capacity: 4, status: TableStatus.empty),
    const VenueTable(id: 't12', zoneId: 'z2', label: 'T2', capacity: 4, status: TableStatus.empty),
    const VenueTable(id: 't13', zoneId: 'z2', label: 'T3', capacity: 2, status: TableStatus.ordering, guestCount: 2),
    const VenueTable(id: 't14', zoneId: 'z2', label: 'T4', capacity: 4, status: TableStatus.empty),
    const VenueTable(id: 't15', zoneId: 'z2', label: 'T5', capacity: 4, status: TableStatus.empty),
    // VIP Gallery
    const VenueTable(id: 't16', zoneId: 'z3', label: 'V1', capacity: 6, status: TableStatus.ready, guestCount: 4),
    const VenueTable(id: 't17', zoneId: 'z3', label: 'V2', capacity: 4, status: TableStatus.waiting, guestCount: 3),
    const VenueTable(id: 't18', zoneId: 'z3', label: 'V3', capacity: 4, status: TableStatus.empty),
  ];

  static final categories = [
    const MenuCategory(id: 'c1', name: 'Makanan Utama', sortOrder: 0),
    const MenuCategory(id: 'c2', name: 'Lauk Pauk', sortOrder: 1),
    const MenuCategory(id: 'c3', name: 'Minuman', sortOrder: 2),
    const MenuCategory(id: 'c4', name: 'Menu Spesial', sortOrder: 3),
  ];

  static final modifierGroups = [
    const ModifierGroup(
      id: 'mg1',
      name: 'Tingkat Kematangan',
      selectionType: SelectionType.single,
      isRequired: true,
      options: [
        ModifierOption(id: 'mo1', modifierGroupId: 'mg1', name: 'Matang'),
        ModifierOption(id: 'mo2', modifierGroupId: 'mg1', name: 'Setengah Matang'),
        ModifierOption(id: 'mo3', modifierGroupId: 'mg1', name: 'Matang Sempurna'),
      ],
    ),
    const ModifierGroup(
      id: 'mg2',
      name: 'Tambahan',
      selectionType: SelectionType.multiple,
      isRequired: false,
      options: [
        ModifierOption(id: 'mo6', modifierGroupId: 'mg2', name: 'Extra Sambal'),
        ModifierOption(id: 'mo7', modifierGroupId: 'mg2', name: 'Tanpa Es'),
        ModifierOption(id: 'mo8', modifierGroupId: 'mg2', name: 'Extra Kerupuk', priceAdjustment: 3000),
        ModifierOption(id: 'mo9', modifierGroupId: 'mg2', name: 'Nasi Putih', priceAdjustment: 5000),
      ],
    ),
    const ModifierGroup(
      id: 'mg3',
      name: 'Susu',
      selectionType: SelectionType.single,
      isRequired: false,
      options: [
        ModifierOption(id: 'mo10', modifierGroupId: 'mg3', name: 'Susu Sapi'),
        ModifierOption(id: 'mo11', modifierGroupId: 'mg3', name: 'Susu Oat', priceAdjustment: 3000),
        ModifierOption(id: 'mo12', modifierGroupId: 'mg3', name: 'Susu Almond', priceAdjustment: 3000),
      ],
    ),
  ];

  static final menuItems = [
    const MenuItem(id: 'mi1', categoryId: 'c1', name: 'Nasi Goreng Special', description: 'Nasi goreng dengan telur & kerupuk', price: 28000, modifierGroupIds: ['mg2']),
    const MenuItem(id: 'mi2', categoryId: 'c1', name: 'Sate Ayam Madura', description: 'Sate ayam 10 tusuk bumbu kacang', price: 32000, modifierGroupIds: ['mg1']),
    const MenuItem(id: 'mi3', categoryId: 'c1', name: 'Gado-Gado Betawi', description: 'Sayuran segar dengan bumbu kacang', price: 22000, modifierGroupIds: []),
    const MenuItem(id: 'mi4', categoryId: 'c2', name: 'Soto Ayam Lamongan', description: 'Soto ayam kuning dengan bihun', price: 24000, modifierGroupIds: ['mg2']),
    const MenuItem(id: 'mi5', categoryId: 'c2', name: 'Rendang Sapi Padang', description: 'Rendang daging sapi asli Padang', price: 45000, modifierGroupIds: ['mg1', 'mg2'], isAvailable: false),
    const MenuItem(id: 'mi6', categoryId: 'c2', name: 'Mie Goreng Jawa', description: 'Mie goreng dengan sayuran & telur', price: 18000, modifierGroupIds: []),
    const MenuItem(id: 'mi7', categoryId: 'c2', name: 'Bakso Urat Special', description: 'Bakso daging sapi dengan mie', price: 15000, modifierGroupIds: []),
    const MenuItem(id: 'mi8', categoryId: 'c2', name: 'Siomay Bandung', description: 'Siomay ikan dengan bumbu kacang', price: 12000, modifierGroupIds: []),
    const MenuItem(id: 'mi9', categoryId: 'c3', name: 'Kopi Tubruk', description: 'Kopi hitam khas Indonesia', price: 8000, modifierGroupIds: ['mg3']),
    const MenuItem(id: 'mi10', categoryId: 'c3', name: 'Es Teh Manis', description: 'Teh manis segar', price: 5000, modifierGroupIds: []),
    const MenuItem(id: 'mi11', categoryId: 'c3', name: 'Es Jeruk Peras', description: 'Jeruk peras segar', price: 7000, modifierGroupIds: []),
    const MenuItem(id: 'mi12', categoryId: 'c4', name: 'Nasi Uduk Komplit', description: 'Nasi uduk dengan lauk lengkap', price: 35000, modifierGroupIds: ['mg2']),
  ];

  static final orders = [
    Order(
      id: 'o1',
      tableId: 't1',
      waiterId: 'u3',
      tableLabel: '12',
      status: OrderStatus.received,
      createdAt: DateTime.now().subtract(const Duration(minutes: 19)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 19)),
      customerName: null,
      items: const [
        OrderItem(id: 'oi1', orderId: 'o1', menuItemId: 'mi1', name: 'Nasi Goreng Special', quantity: 2, notes: 'Pedas, tanpa kerupuk', modifierNames: ['Extra Sambal', 'Extra Kerupuk']),
        OrderItem(id: 'oi2', orderId: 'o1', menuItemId: 'mi3', name: 'Gado-Gado Betawi', quantity: 1),
        OrderItem(id: 'oi3', orderId: 'o1', menuItemId: 'mi11', name: 'Es Jeruk Peras', quantity: 3),
      ],
    ),
    Order(
      id: 'o2',
      tableId: 't0',
      waiterId: 'u3',
      tableLabel: '-',
      customerName: 'Bob S.',
      status: OrderStatus.cooking,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      items: const [
        OrderItem(id: 'oi4', orderId: 'o2', menuItemId: 'mi2', name: 'Sate Ayam Madura', quantity: 1, notes: 'Setengah Matang', modifierNames: ['Setengah Matang']),
        OrderItem(id: 'oi5', orderId: 'o2', menuItemId: 'mi9', name: 'Kopi Tubruk', quantity: 1),
      ],
    ),
    Order(
      id: 'o3',
      tableId: 't16',
      waiterId: 'u3',
      tableLabel: 'V1',
      status: OrderStatus.cooking,
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 3)),
      items: const [
        OrderItem(id: 'oi6', orderId: 'o3', menuItemId: 'mi7', name: 'Bakso Urat Special', quantity: 4),
        OrderItem(id: 'oi7', orderId: 'o3', menuItemId: 'mi8', name: 'Siomay Bandung', quantity: 2),
      ],
    ),
    Order(
      id: 'o4',
      tableId: 't13',
      waiterId: 'u3',
      tableLabel: 'Bar',
      customerName: 'Walk-in',
      status: OrderStatus.received,
      createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      items: const [
        OrderItem(id: 'oi8', orderId: 'o4', menuItemId: 'mi12', name: 'Nasi Uduk Komplit', quantity: 2),
        OrderItem(id: 'oi9', orderId: 'o4', menuItemId: 'mi8', name: 'Siomay Bandung', quantity: 1),
      ],
    ),
  ];

  static final inventoryItems = [
    const InventoryItem(id: 'inv1', category: 'Minuman', name: 'Kopi Arabika', sku: 'MIN-001', unit: 'kg', currentStock: 145, lowStockThreshold: 20),
    const InventoryItem(id: 'inv2', category: 'Minuman', name: 'Teh Melati', sku: 'MIN-002', unit: 'kg', currentStock: 12, lowStockThreshold: 15),
    const InventoryItem(id: 'inv3', category: 'Minuman', name: 'Bubuk Matcha', sku: 'MIN-003', unit: 'kg', currentStock: 45, lowStockThreshold: 10),
    const InventoryItem(id: 'inv4', category: 'Bahan Pokok', name: 'Beras Premium', sku: 'BPK-101', unit: 'kg', currentStock: 240, lowStockThreshold: 50),
    const InventoryItem(id: 'inv5', category: 'Bahan Pokok', name: 'Minyak Goreng', sku: 'BPK-105', unit: 'ltr', currentStock: 48, lowStockThreshold: 12),
    const InventoryItem(id: 'inv6', category: 'Bahan Pokok', name: 'Bumbu Dapur', sku: 'BPK-202', unit: 'kg', currentStock: 18, lowStockThreshold: 6),
    const InventoryItem(id: 'inv7', category: 'Perlengkapan', name: 'Tisu Makan', sku: 'PRL-020', unit: 'pak', currentStock: 5, lowStockThreshold: 8),
    const InventoryItem(id: 'inv8', category: 'Perlengkapan', name: 'Sabun Cuci Tangan', sku: 'PRL-025', unit: 'btl', currentStock: 200, lowStockThreshold: 30),
    const InventoryItem(id: 'inv9', category: 'Perlengkapan', name: 'Serbet Meja', sku: 'PRL-030', unit: 'lbr', currentStock: 150, lowStockThreshold: 50),
  ];

  static List<VenueTable> tablesForZone(String zoneId) {
    return tables.where((t) => t.zoneId == zoneId).toList();
  }

  static List<MenuItem> itemsForCategory(String categoryId) {
    return menuItems.where((i) => i.categoryId == categoryId).toList();
  }

  static MenuItem? findMenuItem(String id) {
    try {
      return menuItems.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  static ModifierGroup? findModifierGroup(String id) {
    try {
      return modifierGroups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<ModifierGroup> modifierGroupsForItem(String itemId) {
    final item = findMenuItem(itemId);
    if (item == null) return [];
    return item.modifierGroupIds
        .map((id) => findModifierGroup(id))
        .where((g) => g != null)
        .cast<ModifierGroup>()
        .toList();
  }
}
