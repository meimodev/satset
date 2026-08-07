enum CapabilityGroup { orders, money, inventory, admin, kitchen }

/// The name is persisted (roles store capability keys) and is the join to the
/// ARB entry — see `capabilityLabel` in `core/localization/labels.dart`, which
/// is where the words live. Never rename one.
enum Capability {
  takeOrder(CapabilityGroup.orders),
  modifyOrder(CapabilityGroup.orders),
  voidItem(CapabilityGroup.orders),
  compItem(CapabilityGroup.orders),
  viewKds(CapabilityGroup.kitchen),
  openDrawer(CapabilityGroup.money),
  applyDiscount(CapabilityGroup.money),
  settleBill(CapabilityGroup.money),
  refund(CapabilityGroup.money),
  closeShift(CapabilityGroup.money),
  editMenu(CapabilityGroup.inventory),
  markSoldOut(CapabilityGroup.inventory),
  adjustStock(CapabilityGroup.inventory),
  manageIngredients(CapabilityGroup.inventory),
  overrideStock(CapabilityGroup.inventory),
  manageStaff(CapabilityGroup.admin),
  manageRoles(CapabilityGroup.admin),
  viewReports(CapabilityGroup.admin),
  editSettings(CapabilityGroup.admin);

  final CapabilityGroup group;
  const Capability(this.group);
}

Capability? capabilityFromKey(String key) {
  for (final c in Capability.values) {
    if (c.name == key) return c;
  }
  return null;
}
