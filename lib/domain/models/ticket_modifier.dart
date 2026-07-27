/// One add-on a guest chose, snapshotted onto a sent line at order time.
///
/// Self-contained: carries the [label] as it read when ordered and the
/// [priceDelta] as a number, so the KDS (which has no menu to resolve
/// against) and reports never depend on the live menu. See
/// docs/adr/0011-ticket-modifier-snapshot.md.
class TicketModifier {
  /// Owning modifier group's id (e.g. `spice`). Empty on legacy rows.
  final String groupId;

  /// Chosen option's id (e.g. `hot`). Empty on legacy rows.
  final String optionId;

  /// Display label, frozen at order time (clean — no `+`/`−` prefix).
  final String label;

  /// Price adjustment in rupiah; sign is derived for display.
  final int priceDelta;

  const TicketModifier({
    this.groupId = '',
    this.optionId = '',
    required this.label,
    this.priceDelta = 0,
  });

  /// Label with a derived sign prefix for price-affecting options.
  String get display =>
      priceDelta > 0 ? '+ $label' : (priceDelta < 0 ? '− $label' : label);

  @override
  bool operator ==(Object other) =>
      other is TicketModifier &&
      other.groupId == groupId &&
      other.optionId == optionId &&
      other.label == label &&
      other.priceDelta == priceDelta;

  @override
  int get hashCode => Object.hash(groupId, optionId, label, priceDelta);
}
