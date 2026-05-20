import 'modifier_group.dart';

enum Station { kitchen, bar }

enum Allergen { gluten, nut, dairy, shellfish, egg, soy, sesame, sulfites }

class Variant {
  final String id;
  final String name;
  final int price;
  const Variant({required this.id, required this.name, required this.price});
}

class MenuItem {
  final String id;
  final String name;
  final String categoryId;
  final Station station;
  final String description;
  final List<Allergen> allergens;
  final int prepTime;
  final int basePrice;
  final List<Variant> variants;
  final List<ModifierGroup> modifierGroups;
  final bool unavailable;

  const MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.station,
    required this.description,
    this.allergens = const [],
    this.prepTime = 5,
    required this.basePrice,
    required this.variants,
    this.modifierGroups = const [],
    this.unavailable = false,
  });
}

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
