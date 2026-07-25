import 'modifier_group.dart';

class Variant {
  final String id;
  final String name;
  final int price;
  const Variant({required this.id, required this.name, required this.price});

  Variant copyWith({String? id, String? name, int? price}) =>
      Variant(id: id ?? this.id, name: name ?? this.name, price: price ?? this.price);
}

class MenuItem {
  final String id;
  final String name;
  final String categoryId;
  final String description;

  /// Allergen tag ids (resolve against the menu snapshot's [MenuTag] list).
  final List<String> allergens;

  /// Diet tag ids (resolve against the menu snapshot's [MenuTag] list).
  final List<String> dietary;
  final int prepTime;
  final int basePrice;
  final int cost;
  final List<Variant> variants;
  final List<ModifierGroup> modifierGroups;
  final bool unavailable;
  /// Photo revision. 0 = no photo (UI shows the initials avatar). >0 means a
  /// photo exists, fetched as bytes from `GET /menu/items/:id/photo` and
  /// cache-keyed by this rev. The bytes never ride the model — see
  /// docs/adr/0014-menu-photo-blob-and-pinned-byte-fetch.md.
  final int photoRev;

  /// Derived from ingredient stock server-side: true when *no* configuration of
  /// this item can be made. Never stored — receiving stock clears it by itself
  /// (ADR-0037).
  final bool autoSoldOut;

  /// Variants that cannot currently be made. An item with one sellable variant
  /// is still orderable, so this is finer-grained than [autoSoldOut].
  final List<String> soldOutVariantIds;

  /// Modifier options whose own recipe cannot currently be covered.
  final List<String> soldOutOptionIds;

  bool get hasPhoto => photoRev > 0;

  const MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.description,
    this.allergens = const [],
    this.dietary = const [],
    this.prepTime = 5,
    required this.basePrice,
    this.cost = 0,
    required this.variants,
    this.modifierGroups = const [],
    this.unavailable = false,
    this.photoRev = 0,
    this.autoSoldOut = false,
    this.soldOutVariantIds = const [],
    this.soldOutOptionIds = const [],
  });

  /// True when ingredient stock cannot cover any configuration of this item.
  bool get isAutoSoldOut => autoSoldOut;

  /// Effective unavailability: manual toggle OR derived from ingredient stock.
  bool get isSoldOut => unavailable || autoSoldOut;

  bool isVariantSoldOut(String variantId) =>
      soldOutVariantIds.contains(variantId);

  bool isOptionSoldOut(String optionId) => soldOutOptionIds.contains(optionId);

  MenuItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? description,
    List<String>? allergens,
    List<String>? dietary,
    int? prepTime,
    int? basePrice,
    int? cost,
    List<Variant>? variants,
    List<ModifierGroup>? modifierGroups,
    bool? unavailable,
    int? photoRev,
    bool? autoSoldOut,
    List<String>? soldOutVariantIds,
    List<String>? soldOutOptionIds,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      allergens: allergens ?? this.allergens,
      dietary: dietary ?? this.dietary,
      prepTime: prepTime ?? this.prepTime,
      basePrice: basePrice ?? this.basePrice,
      cost: cost ?? this.cost,
      variants: variants ?? this.variants,
      modifierGroups: modifierGroups ?? this.modifierGroups,
      unavailable: unavailable ?? this.unavailable,
      photoRev: photoRev ?? this.photoRev,
      autoSoldOut: autoSoldOut ?? this.autoSoldOut,
      soldOutVariantIds: soldOutVariantIds ?? this.soldOutVariantIds,
      soldOutOptionIds: soldOutOptionIds ?? this.soldOutOptionIds,
    );
  }
}
