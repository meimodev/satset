/// Admin-managed label attached to menu items. One of two [MenuTagKind]s.
/// Replaces the former fixed `Allergen` / `DietaryTag` enums — see
/// docs/adr/0010-customizable-menu-tags.md.
enum MenuTagKind { allergen, diet }

MenuTagKind menuTagKindFromKey(String key) =>
    key == 'diet' ? MenuTagKind.diet : MenuTagKind.allergen;

class MenuTag {
  final String id;
  final MenuTagKind kind;

  /// Display label, e.g. "Gluten", "Vegan".
  final String name;

  /// Short badge code shown on item cards, e.g. "GL", "VG".
  final String code;

  /// Controls chip ordering within a kind.
  final int sortOrder;

  const MenuTag({
    required this.id,
    required this.kind,
    required this.name,
    required this.code,
    this.sortOrder = 0,
  });

  MenuTag copyWith({
    String? id,
    MenuTagKind? kind,
    String? name,
    String? code,
    int? sortOrder,
  }) => MenuTag(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    code: code ?? this.code,
    sortOrder: sortOrder ?? this.sortOrder,
  );
}
