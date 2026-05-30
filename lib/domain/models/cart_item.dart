import 'course.dart';
import 'ticket_modifier.dart';

class CartItem {
  final String id;
  final String itemId;
  final String name;
  final String variantId;
  final String variantName;
  /// Display labels (with derived sign) for the cart/review screens.
  final List<String> modifiers;
  /// Structured snapshot of each chosen option — what rides the wire and
  /// freezes onto the sent line. See ADR-0011.
  final List<TicketModifier> selectedModifiers;
  final String note;
  final CourseId course;
  final int qty;
  final int unitPrice;
  /// Allergen tag ids (resolve against the menu snapshot's tags).
  final List<String> allergens;

  const CartItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.variantId,
    required this.variantName,
    this.modifiers = const [],
    this.selectedModifiers = const [],
    this.note = '',
    required this.course,
    this.qty = 1,
    required this.unitPrice,
    this.allergens = const [],
  });
}
