class Zone {
  final String id;
  final String name;
  final String? description;
  final int sortOrder;

  const Zone({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
  });
}
