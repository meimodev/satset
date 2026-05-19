class MenuCategory {
  final String id;
  final String name;
  final int sortOrder;

  const MenuCategory({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });
}
