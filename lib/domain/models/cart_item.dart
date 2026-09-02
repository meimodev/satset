import 'course.dart';
import 'ticket_modifier.dart';

class CartItem {
  final String id;
  final String itemId;
  final String name;
  final String variantId;
  final String variantName;
  final String? memberId;
  final String? memberName;

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
    this.memberId,
    this.memberName,
    this.modifiers = const [],
    this.selectedModifiers = const [],
    this.note = '',
    required this.course,
    this.qty = 1,
    required this.unitPrice,
    this.allergens = const [],
  });

  CartItem copyWith({
    String? id,
    String? itemId,
    String? name,
    String? variantId,
    String? variantName,
    List<String>? modifiers,
    List<TicketModifier>? selectedModifiers,
    String? note,
    CourseId? course,
    int? qty,
    int? unitPrice,
    List<String>? allergens,
  }) => CartItem(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    name: name ?? this.name,
    variantId: variantId ?? this.variantId,
    variantName: variantName ?? this.variantName,
    memberId: memberId,
    memberName: memberName,
    modifiers: modifiers ?? this.modifiers,
    selectedModifiers: selectedModifiers ?? this.selectedModifiers,
    note: note ?? this.note,
    course: course ?? this.course,
    qty: qty ?? this.qty,
    unitPrice: unitPrice ?? this.unitPrice,
    allergens: allergens ?? this.allergens,
  );

  CartItem withMember(String? memberId, String? memberName) => CartItem(
    id: id,
    itemId: itemId,
    name: name,
    variantId: variantId,
    variantName: variantName,
    memberId: memberId,
    memberName: memberName,
    modifiers: modifiers,
    selectedModifiers: selectedModifiers,
    note: note,
    course: course,
    qty: qty,
    unitPrice: unitPrice,
    allergens: allergens,
  );

  /// Order-insensitive identity of the chosen options. Two lines that picked
  /// the same options in a different order are the same line to the kitchen,
  /// so the set — not the list — is what stacking compares. See ADR-0060.
  Set<String> get modifierKeys => {
    for (final m in selectedModifiers) '${m.groupId}|${m.optionId}',
  };

  /// Whether [other] is the same order line: same dish, same config, same
  /// note, same course. Deliberately ignores `id` (a fresh uuid per add),
  /// `qty` (the thing being summed) and `unitPrice`/`allergens` (both derived
  /// from the fields above).
  bool sameLineAs(CartItem other) =>
      itemId == other.itemId &&
      variantId == other.variantId &&
      memberId == other.memberId &&
      course == other.course &&
      note.trim() == other.note.trim() &&
      modifierKeys.length == other.modifierKeys.length &&
      modifierKeys.containsAll(other.modifierKeys);
}
