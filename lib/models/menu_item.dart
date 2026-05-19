class MenuItem {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final bool isAvailable;
  final String? sku;
  final List<String> modifierGroupIds;

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.isAvailable = true,
    this.sku,
    this.modifierGroupIds = const [],
  });
}
