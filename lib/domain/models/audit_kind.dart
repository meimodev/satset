/// What an audit row *says*, as a discriminator plus named parameters — the
/// structured half of ADR-0085.
///
/// [AuditType] and [AuditKind] look alike and are not the same axis. The type
/// is the **act** and drives filtering, tiles and the admin/non-admin split; a
/// single type can be phrased several ways (`billClosed` reads differently when
/// the bill was written off, `discountApplied` when it was line-scoped). The
/// kind is the **sentence** — one per phrasing, each with its own ARB template.
///
/// Plain Dart, no Flutter: the server picks the kind at write time and the
/// client renders it, so this file sits below both. The rendering lives in
/// `lib/core/localization/audit_text.dart`, which is where the `AppL10n` import
/// is allowed.
///
/// **Adding one** means an ARB template in both locales and a branch in
/// `auditText`; the switch there is exhaustive, so the analyzer will say so.
/// **Never rename one** — the name is persisted in `audit_entries.kind`, and a
/// rename orphans every row already written under the old spelling. They fall
/// back to the stored `title`, which is the pre-ADR-0085 behaviour, so the
/// damage is silent.
library;

enum AuditKind {
  // ---------- service ----------
  /// A course was fired. `{course}`, `{table}`.
  fire,

  /// A line was edited without changing its quantity. `{name}`.
  modify,

  /// A line's quantity changed. `{oldQty}`, `{newQty}`, `{name}`.
  modifyQty,

  /// `{qty}`, `{name}`, `{amount}` (pre-formatted rupiah, ADR-0084).
  voidItem,
  comp,

  /// The sample seed's flatter phrasing — the act is placed at a table rather
  /// than against a named amount. `{name}`, `{table}`.
  voidItemAtTable,
  modifyAtTable,

  /// `{src}`, `{tgt}` — table labels.
  tableMoved,

  // ---------- money ----------
  /// `{amount}` (rupiah), `{method}` (raw method key — rendered through
  /// `paymentMethodLabel`, so the method follows the reader's language),
  /// `{label}` (receipt label prose).
  paymentRecorded,
  refund,

  /// The seed's phrasing, which names the table rather than a receipt.
  /// `{method}`, `{table}`.
  paymentAtTable,

  /// `{name}` — the preset's own name, snapshotted venue content and never
  /// translated (ADR-0084's sibling rule for venue-authored strings).
  discountApplied,
  discountAppliedLine,
  discountRemoved,
  discountBillApplied,
  discountBillRemoved,

  /// `{percent}`, `{table}` — the seed's fabricated flat discount.
  discountAtTable,

  /// `{label}` (receipt) / `{table}` (whole bill).
  billReopenedReceipt,
  billReopened,

  /// `{table}`; the written-off flavour also carries `{amount}`.
  billClosed,
  billWrittenOff,

  // ---------- petty cash ----------
  /// `{amount}` (pre-formatted rupiah, ADR-0084).
  cashToppedUp,

  /// `{amount}`, `{category}` — the category travels as its **key** and is
  /// rendered through `cashCategoryLabel`, so it follows the reader's language
  /// the way `paymentRecorded`'s method key already does.
  cashSpent,

  /// `{counted}` (what was physically found) and `{variance}` (signed, against
  /// what the ledger said). Both pre-formatted rupiah.
  cashCounted,

  /// `{amount}` — the magnitude of the movement being undone.
  cashReversed,

  // ---------- inventory ----------
  /// A stok opname was closed (ADR-0096). `{lines}` (how many bahan were
  /// counted), `{variance}` (signed, pre-formatted rupiah). The session's scope
  /// and whether it was blind live on the document, not in the sentence — the
  /// log's job is that something material happened and who did it.
  ///
  /// One row per session, never per line: the per-bahan detail is already the
  /// opname document, and a flooded log is a log nobody reads.
  stockCountClosed,

  // ---------- membership ----------
  /// `{name}` — the member's own name, guest-authored and never translated.
  memberCreated,
  memberDeleted,

  /// `{from}`, `{to}` — the member absorbed and the one that survives.
  memberMerged,

  /// `{name}`, `{points}` (signed, e.g. `+40`). The reason rides `reason`,
  /// where every other explained act keeps it.
  memberPointsAdjusted,

  /// `{name}`, `{points}` (magnitude spent), `{amount}` (pre-formatted rupiah
  /// taken off the bill).
  memberPointsRedeemed,

  // ---------- menu ----------
  /// `{name}`.
  menuKilled,
  menuRestored,

  // ---------- staff & roles ----------
  /// `{name}`.
  staffCreated,
  staffDeleted,
  staffDisabled,
  staffEnabled,
  staffPinSet,
  staffPinReset,
  roleCreated,
  roleDeleted,
  roleColorChanged,

  /// `{name}`, `{from}`, `{to}`.
  staffRoleChanged,

  /// `{from}`, `{to}`.
  roleRenamed,

  /// `{name}`, `{changes}` — the `+cap,-cap` diff, which is a list of
  /// capability identifiers and stays as-is in both languages.
  roleCapabilityChanged,

  /// The sample seed ran (ADR-0073). No params.
  sampleDataLoaded,
}

/// Read a persisted kind back, tolerating one written by a newer build.
///
/// Returns null rather than throwing: an unknown kind means this reader has no
/// template for it, and the row still carries the `title` the writer composed.
/// Falling back to that sentence beats an exception on the integrity screen.
AuditKind? auditKindFromName(String? name) {
  if (name == null) return null;
  for (final k in AuditKind.values) {
    if (k.name == name) return k;
  }
  return null;
}
