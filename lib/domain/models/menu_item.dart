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
  final int? stockCount;
  final bool autoSoldOutAtZero;

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
    this.stockCount,
    this.autoSoldOutAtZero = false,
  });

  /// True when stock is being tracked and depleted.
  bool get isAutoSoldOut =>
      autoSoldOutAtZero && stockCount != null && stockCount! <= 0;

  /// Effective unavailability: manual toggle OR auto sold-out from stock.
  bool get isSoldOut => unavailable || isAutoSoldOut;

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
    Object? stockCount = _unset,
    bool? autoSoldOutAtZero,
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
      stockCount: identical(stockCount, _unset) ? this.stockCount : stockCount as int?,
      autoSoldOutAtZero: autoSoldOutAtZero ?? this.autoSoldOutAtZero,
    );
  }
}

const Object _unset = Object();
