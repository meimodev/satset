import 'modifier_group.dart';

class Variant {
  final String id;
  final String name;
  final int price;
  const Variant({required this.id, required this.name, required this.price});

  Variant copyWith({String? id, String? name, int? price}) =>
      Variant(id: id ?? this.id, name: name ?? this.name, price: price ?? this.price);
}

/// Daypart price override expressed in minutes from midnight (0..1439).
class HappyHourRule {
  final int startMinute;
  final int endMinute;
  final int price;
  const HappyHourRule({
    required this.startMinute,
    required this.endMinute,
    required this.price,
  });

  HappyHourRule copyWith({int? startMinute, int? endMinute, int? price}) => HappyHourRule(
        startMinute: startMinute ?? this.startMinute,
        endMinute: endMinute ?? this.endMinute,
        price: price ?? this.price,
      );

  String formatWindow() {
    String hhmm(int m) {
      final h = (m ~/ 60).toString().padLeft(2, '0');
      final mm = (m % 60).toString().padLeft(2, '0');
      return '$h:$mm';
    }
    return '${hhmm(startMinute)}–${hhmm(endMinute)}';
  }
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
  final String? photoUrl;
  final int? stockCount;
  final bool autoSoldOutAtZero;
  final HappyHourRule? happyHour;

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
    this.photoUrl,
    this.stockCount,
    this.autoSoldOutAtZero = false,
    this.happyHour,
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
    Object? photoUrl = _unset,
    Object? stockCount = _unset,
    bool? autoSoldOutAtZero,
    Object? happyHour = _unset,
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
      photoUrl: identical(photoUrl, _unset) ? this.photoUrl : photoUrl as String?,
      stockCount: identical(stockCount, _unset) ? this.stockCount : stockCount as int?,
      autoSoldOutAtZero: autoSoldOutAtZero ?? this.autoSoldOutAtZero,
      happyHour: identical(happyHour, _unset) ? this.happyHour : happyHour as HappyHourRule?,
    );
  }
}

const Object _unset = Object();
