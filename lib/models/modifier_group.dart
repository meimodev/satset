class ModifierOption {
  final String id;
  final String name;
  final int priceDelta;
  const ModifierOption({required this.id, required this.name, this.priceDelta = 0});
}

class ModifierGroup {
  final String id;
  final String name;
  final bool required;
  final bool multi;
  final List<ModifierOption> options;
  const ModifierGroup({
    required this.id,
    required this.name,
    this.required = false,
    this.multi = false,
    required this.options,
  });
}
