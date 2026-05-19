enum SelectionType { single, multiple }

class ModifierGroup {
  final String id;
  final String name;
  final SelectionType selectionType;
  final bool isRequired;
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.name,
    required this.selectionType,
    this.isRequired = true,
    this.options = const [],
  });
}

class ModifierOption {
  final String id;
  final String modifierGroupId;
  final String name;
  final double priceAdjustment;

  const ModifierOption({
    required this.id,
    required this.modifierGroupId,
    required this.name,
    this.priceAdjustment = 0,
  });
}
