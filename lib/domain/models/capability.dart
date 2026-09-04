enum CapabilityGroup { orders, money, inventory, admin, kitchen }

/// The name is persisted (roles store capability keys) and is the join to the
/// ARB entry — see `capabilityLabel` in `core/localization/labels.dart`, which
/// is where the words live. Never rename one.
enum Capability {
  takeOrder(CapabilityGroup.orders),
  modifyOrder(CapabilityGroup.orders),
  voidItem(CapabilityGroup.orders),
  compItem(CapabilityGroup.orders),
  /// Sell an [[Item bebas]] — a line typed at the till with its own name and
  /// price, no menu row behind it. Deliberately **not** on the waiter role: a
  /// line nobody priced is a hole in the menu report, so it belongs to whoever
  /// already answers for the money.
  sellOpenItem(CapabilityGroup.orders),
  viewKds(CapabilityGroup.kitchen),
  openDrawer(CapabilityGroup.money),
  applyDiscount(CapabilityGroup.money),
  settleBill(CapabilityGroup.money),
  refund(CapabilityGroup.money),
  closeShift(CapabilityGroup.money),

  /// Post an expense against the petty cash box. Funding it (top-up) and
  /// counting it (opname) sit behind `editSettings` instead — a supervisor
  /// spends from the box, the owner fills and verifies it.
  ///
  /// Deliberately **not** `openDrawer`, which names the sales drawer and stays
  /// reserved for it. See §Kas kecil in CONTEXT.md.
  manageCash(CapabilityGroup.money),

  /// **[[Pengeluaran kunjungan]]** (ADR-0130) — spend cash on the party you are
  /// serving, capped at what that visit rang up.
  ///
  /// Its own capability rather than a corner of `takeOrder`: this is an
  /// arbitrary-amount write against revenue, the surface `sellOpenItem` was
  /// withheld from the floor over, so an owner has to be able to revoke it
  /// without stopping order-taking. Deliberately not `manageCash` — that opens
  /// the petty cash box, which this feature never touches.
  recordTableExpense(CapabilityGroup.money),
  editMenu(CapabilityGroup.inventory),
  markSoldOut(CapabilityGroup.inventory),
  adjustStock(CapabilityGroup.inventory),
  manageIngredients(CapabilityGroup.inventory),
  overrideStock(CapabilityGroup.inventory),
  /// Edit, merge, delete a [[Pelanggan (member)]] and adjust points by hand.
  ///
  /// Deliberately **not** what a cashier needs: enrolling, attaching and
  /// redeeming ride `settleBill`, because they happen at the till in the middle
  /// of taking money. This capability is the directory-keeper's, and it is
  /// granted to the admin role only until an owner says otherwise.
  manageMembers(CapabilityGroup.admin),
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
