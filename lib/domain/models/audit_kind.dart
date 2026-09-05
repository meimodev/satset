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
  // Every movement kind below also carries `{box}` — the [[Kas (cash box)]]
  // it moved, by name (ADR-0131). The name is venue content, so it travels
  // pre-rendered rather than as a key: unlike a category, there is no closed
  // set to look it up in. Rows written before v73 were backfilled in the
  // migration, so none renders the placeholder empty.
  /// `{amount}` (pre-formatted rupiah, ADR-0084), `{box}`.
  cashToppedUp,

  /// `{amount}`, `{category}`, `{box}` — the category travels as the **word**
  /// the venue authored (ADR-0135), not a key: it is venue content, like the
  /// box name beside it, so there is nothing to resolve and a later rename
  /// cannot rewrite what this line says was bought.
  cashSpent,

  /// `{counted}` (what was physically found), `{variance}` (signed, against
  /// what the ledger said) and `{box}`. The first two are pre-formatted rupiah.
  cashCounted,

  /// `{amount}` — the magnitude of the movement being undone — and `{box}`.
  cashReversed,

  /// **A transfer between two boxes** (ADR-0131). `{amount}`, `{from}`, `{to}`.
  /// One row for the pair: the second leg is the same act seen from the other
  /// tin, and auditing both would read as two transfers.
  cashTransferred,

  /// `{box}` — a [[Kas (cash box)]] was created.
  cashBoxCreated,

  /// `{from}`, `{to}` — a box's name changed. The rows it already owns are
  /// untouched; only what the picker shows moves.
  cashBoxRenamed,

  /// `{box}` — a box was retired. Only ever possible at a zero balance, so no
  /// rupiah can hide behind it.
  cashBoxRetired,

  /// `{box}` — a retired box was brought back.
  cashBoxReopened,

  /// **[[Pengeluaran kunjungan]]** (ADR-0130) — a waiter spent cash on the
  /// party they were serving. Params: `{amount}` (pre-formatted rupiah),
  /// `{category}` (the venue's own category **name**, not a key — this
  /// vocabulary is venue-authored and ARB-exempt, unlike [cashSpent]'s closed
  /// set), `{table}` (the label frozen at write time).
  ///
  /// A separate kind from [cashSpent] on purpose: different ledger, different
  /// money, and the name is persisted forever.
  tableExpenseRecorded,

  // ---------- inventory ----------
  /// A stok opname was closed (ADR-0096). `{lines}` (how many bahan were
  /// counted), `{variance}` (signed, pre-formatted rupiah). The session's scope
  /// and whether it was blind live on the document, not in the sentence — the
  /// log's job is that something material happened and who did it.
  ///
  /// One row per session, never per line: the per-bahan detail is already the
  /// opname document, and a flooded log is a log nobody reads.
  stockCountClosed,

  /// Stock was thrown away. `{what}` (the bahan or the menu item, as named at
  /// write time), `{value}` (pre-formatted rupiah, the cost of what was lost).
  ///
  /// One row per act, never per bahan: binning one portion of nasi goreng
  /// explodes into five movements and is still one thing the cook did. The
  /// *why* rides `reason` as free text, because a waste note is the cook's own
  /// words and there is no closed set of them.
  stockWasted,

  /// **[[Item bebas]]** — one line sold off-menu. Params: `{name}` (what the
  /// seller typed), `{price}` (pre-formatted rupiah, unit price × qty). The
  /// *why* rides `reason`, which the route requires: an unexplained arbitrary
  /// price is the exact hole this row exists to close.
  openItemSold,

  // ---------- pesan mandiri (ADR-0105) ----------
  /// `{table}` (the label frozen at write time), `{lines}` — a guest's order
  /// became real tickets. One row per accepted submission, never per line.
  guestOrderAccepted,

  /// `{table}`, `{lines}`. The *why* rides `reason` as a code, where every
  /// other explained act keeps it.
  guestOrderRejected,

  /// `{tables}` — how many table codes were reminted. Every printed QR for the
  /// venue died at this moment, which is exactly why it is audited.
  guestCodesRotated,

  /// No params. Two kinds rather than one with a state param: a log line is
  /// composed at read time from a code, and "on" is not a code (ADR-0085).
  guestOrderingEnabled,
  guestOrderingDisabled,

  // ---------- membership ----------
  /// `{name}` — the member's own name, guest-authored and never translated.
  memberCreated,
  memberDeleted,

  /// `{from}`, `{to}` — the member absorbed and the one that survives.
  memberMerged,

  /// `{from}`, `{to}` — an offline enrolment whose number was already in the
  /// directory, folded into the standing record at drain (ADR-0129).
  ///
  /// Deliberately **not** [memberMerged]: that one means a person chose to
  /// merge two records, and an owner reading their own directory back has to
  /// be able to tell "the queue reconciled these" from "somebody did this".
  memberEnrolFoldedAtDrain,

  /// `{name}`, `{points}` (signed, e.g. `+40`). The reason rides `reason`,
  /// where every other explained act keeps it.
  memberPointsAdjusted,

  /// `{name}`, `{points}` (magnitude spent), `{amount}` (pre-formatted rupiah
  /// taken off the bill).
  memberPointsRedeemed,

  // ---------- piutang (ADR-0098) ----------
  /// `{member}`, `{amount}` (pre-formatted rupiah), `{bill}` — the table label
  /// frozen at write time, because the visit is gone by the time anyone reads
  /// this back.
  debtCharged,

  /// `{member}`, `{amount}`, `{method}` — the method travels as its **key** and
  /// is rendered through `paymentMethodLabel`, same as `paymentRecorded`.
  debtPaid,

  /// `{member}`, `{amount}`, `{bill}` — a charge undone because its receipt was
  /// reopened. Automatic; nobody chose it, which is why it has no reason.
  debtReversed,

  /// `{member}`, `{amount}`. The reason rides `reason` and is mandatory.
  debtWrittenOff,

  /// `{member}`, `{amount}` — **signed** (`+`/`-`), because which way a hand
  /// correction went is the whole finding. Reason mandatory.
  debtAdjusted,

  // ---------- menu ----------
  /// `{name}`.
  menuKilled,
  menuRestored,

  // ---------- staff & roles ----------
  /// `{name}`.
  /// A wrong PIN, and which try it was. ADR-0112.
  signInFailed,
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

  /// **Buka kedai** (ADR-0111). No params. The float that went in is a
  /// [[Kas kecil]] row of its own; this says only that the shop opened, and by
  /// whom — which is the fact no other row carries.
  venueOpened,

  /// **Tutup kedai** (ADR-0111). No params, for the same reason: the count and
  /// its variance are the `cashCounted` row, and duplicating the number here
  /// would give the log two places to disagree about it.
  venueClosed,

  /// The sample seed ran (ADR-0073). No params.
  sampleDataLoaded,

  /// A settlement act captured on a [[Terputus (client disconnected)|terputus]]
  /// till reached the host **after the business day it belongs to had already
  /// closed its books** (ADR-0123). Params: `{table}`, `{amount}`
  /// (pre-formatted rupiah), `{captured}` (when it was collected, already
  /// formatted).
  ///
  /// Never a refusal — the cash is physically in the drawer and discarding the
  /// record loses it. This row exists so the discrepancy the owner finds in a
  /// signed-off day has a name.
  settlementArrivedLate,
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
