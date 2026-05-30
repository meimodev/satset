enum CapabilityGroup { orders, money, inventory, admin, kitchen }

enum Capability {
  takeOrder(CapabilityGroup.orders, 'Take order'),
  modifyOrder(CapabilityGroup.orders, 'Modify order'),
  voidItem(CapabilityGroup.orders, 'Void item'),
  compItem(CapabilityGroup.orders, 'Comp item'),
  viewKds(CapabilityGroup.kitchen, 'View KDS'),
  openDrawer(CapabilityGroup.money, 'Open drawer'),
  applyDiscount(CapabilityGroup.money, 'Apply discount'),
  refund(CapabilityGroup.money, 'Refund'),
  closeShift(CapabilityGroup.money, 'Close shift'),
  editMenu(CapabilityGroup.inventory, 'Edit menu'),
  markSoldOut(CapabilityGroup.inventory, 'Mark sold out'),
  adjustStock(CapabilityGroup.inventory, 'Adjust stock'),
  manageStaff(CapabilityGroup.admin, 'Manage staff'),
  manageRoles(CapabilityGroup.admin, 'Manage roles'),
  viewReports(CapabilityGroup.admin, 'View reports'),
  editSettings(CapabilityGroup.admin, 'Edit settings');

  final CapabilityGroup group;
  final String label;
  const Capability(this.group, this.label);
}

String capabilityGroupLabel(CapabilityGroup g) => switch (g) {
      CapabilityGroup.orders => 'Orders',
      CapabilityGroup.money => 'Money',
      CapabilityGroup.inventory => 'Inventory',
      CapabilityGroup.admin => 'Admin',
      CapabilityGroup.kitchen => 'Kitchen',
    };

Capability? capabilityFromKey(String key) {
  for (final c in Capability.values) {
    if (c.name == key) return c;
  }
  return null;
}
