import 'course.dart';
import 'menu_item.dart';

class CartItem {
  final String id;
  final String itemId;
  final String name;
  final String variantId;
  final String variantName;
  final List<String> modifiers;
  final Map<String, dynamic> modifierIds;
  final String special;
  final CourseId course;
  final int qty;
  final int unitPrice;
  final List<Allergen> allergens;

  const CartItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.variantId,
    required this.variantName,
    this.modifiers = const [],
    this.modifierIds = const {},
    this.special = '',
    required this.course,
    this.qty = 1,
    required this.unitPrice,
    this.allergens = const [],
  });
}
