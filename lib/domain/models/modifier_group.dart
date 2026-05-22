class ModifierOption {
  final String id;
  final String name;
  final int priceDelta;
  const ModifierOption({required this.id, required this.name, this.priceDelta = 0});

  ModifierOption copyWith({String? id, String? name, int? priceDelta}) =>
      ModifierOption(
        id: id ?? this.id,
        name: name ?? this.name,
        priceDelta: priceDelta ?? this.priceDelta,
      );
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

  ModifierGroup copyWith({
    String? id,
    String? name,
    bool? required,
    bool? multi,
    List<ModifierOption>? options,
  }) =>
      ModifierGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        required: required ?? this.required,
        multi: multi ?? this.multi,
        options: options ?? this.options,
      );
}
