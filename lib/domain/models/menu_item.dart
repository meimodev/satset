import 'modifier_group.dart';

enum Station { kitchen, bar }

enum Allergen { gluten, nut, dairy, shellfish, egg, soy, sesame, sulfites }

enum DietaryTag { vegetarian, vegan, glutenFree, dairyFree, spicy, halal, signature }

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
  final Station station;
  final String description;
  final List<Allergen> allergens;
  final List<DietaryTag> dietary;
  final int prepTime;
  final int basePrice;
  final int cost;
  final List<Variant> variants;
  final List<ModifierGroup> modifierGroups;
  final bool unavailable;
  final String? photoUrl;
  final int? stockCount;
  final bool autoEightySixAtZero;
  final HappyHourRule? happyHour;

  const MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.station,
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
    this.autoEightySixAtZero = false,
    this.happyHour,
  });

  /// True when stock is being tracked and depleted.
  bool get autoEightySixed =>
      autoEightySixAtZero && stockCount != null && stockCount! <= 0;

  /// Effective unavailability: manual toggle OR auto-86 from stock.
  bool get isEightySixed => unavailable || autoEightySixed;

  MenuItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    Station? station,
    String? description,
    List<Allergen>? allergens,
    List<DietaryTag>? dietary,
    int? prepTime,
    int? basePrice,
    int? cost,
    List<Variant>? variants,
    List<ModifierGroup>? modifierGroups,
    bool? unavailable,
    Object? photoUrl = _unset,
    Object? stockCount = _unset,
    bool? autoEightySixAtZero,
    Object? happyHour = _unset,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      station: station ?? this.station,
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
      autoEightySixAtZero: autoEightySixAtZero ?? this.autoEightySixAtZero,
      happyHour: identical(happyHour, _unset) ? this.happyHour : happyHour as HappyHourRule?,
    );
  }
}

const Object _unset = Object();

const allergenCodes = <Allergen, String>{
  Allergen.gluten: 'GL',
  Allergen.nut: 'NU',
  Allergen.dairy: 'DA',
  Allergen.shellfish: 'SH',
  Allergen.egg: 'EG',
  Allergen.soy: 'SO',
  Allergen.sesame: 'SE',
  Allergen.sulfites: 'SU',
};

const allergenNames = <Allergen, String>{
  Allergen.gluten: 'Gluten',
  Allergen.nut: 'Kacang',
  Allergen.dairy: 'Susu',
  Allergen.shellfish: 'Kerang',
  Allergen.egg: 'Telur',
  Allergen.soy: 'Kedelai',
  Allergen.sesame: 'Wijen',
  Allergen.sulfites: 'Sulfit',
};

const dietaryNames = <DietaryTag, String>{
  DietaryTag.vegetarian: 'Vegetarian',
  DietaryTag.vegan: 'Vegan',
  DietaryTag.glutenFree: 'Bebas gluten',
  DietaryTag.dairyFree: 'Bebas susu',
  DietaryTag.spicy: 'Pedas',
  DietaryTag.halal: 'Halal',
  DietaryTag.signature: 'Andalan',
};

const dietaryCodes = <DietaryTag, String>{
  DietaryTag.vegetarian: 'VG',
  DietaryTag.vegan: 'VN',
  DietaryTag.glutenFree: 'GF',
  DietaryTag.dairyFree: 'DF',
  DietaryTag.spicy: 'PD',
  DietaryTag.halal: 'HL',
  DietaryTag.signature: 'AD',
};
