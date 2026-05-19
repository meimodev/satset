class InventoryItem {
  final String id;
  final String category;
  final String name;
  final String sku;
  final String unit;
  final double currentStock;
  final double lowStockThreshold;
  final bool isActive;

  const InventoryItem({
    required this.id,
    required this.category,
    required this.name,
    required this.sku,
    required this.unit,
    required this.currentStock,
    this.lowStockThreshold = 10,
    this.isActive = true,
  });

  bool get isLowStock => currentStock <= lowStockThreshold;
}
