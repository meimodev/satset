# A category is the venue's word, and the box owns it

**Status:** Accepted — 2026-09-05 — **amends** [0131](0131-a-venue-counts-more-than-one-tin.md) and reverses the closed-set half of [0130](0130-a-visit-expense-is-revenue-not-petty-cash.md); neither is superseded.

[[Kategori kas (cash category)]] was a closed enum of five words — belanja bahan,
operasional, transport, upah harian, lainnya — chosen by us, translated by us,
and the same in every venue. This ADR makes it a **venue-authored catalogue owned
by a [[Kas (cash box)|box]]**: each tin carries its own list of what money leaves
it for, the venue writes the words, and the five stock ones survive as seeded
rows rather than as code.

## Context

ADR-0130 drew the line deliberately and said so: a [[Pengeluaran kunjungan (visit
expense)]] category is venue-authored *"which is the opposite of the call
`CashCategory` makes for the petty cash box, and deliberately so"*. That call was
right for one venue-wide fund and stopped being right the moment ADR-0131 gave a
venue several tins.

**A tin spends on its own things.** Kas Dapur buys vegetables, ice and LPG. The
bar tin buys limes and straws. The owner's tin pays an ojek and a day labourer.
Offering all three the same five words means every picker is mostly wrong, and
the one that fits — *lainnya* — is the one that tells a report nothing.

**Five words we chose are not the venue's five words.** *Upah harian* is a
category in a warung and meaningless in a coffee bar; *belanja pasar* is what
half of them actually say. A closed set makes that unsayable, and the workaround
is the note field, where nothing aggregates.

**The enum names are persisted.** `cash_entries.category` holds `ingredients`,
`operations`, `transport`, `dailyWage`, `other` across every row a venue has ever
written, under the never-rename rule. Any move here had to leave those rows
resolvable without touching them — the ledger is append-only, and `reversedById`
is its one stamped exception.

**A category is not a code.** ADR-0085 keeps *codes* crossing the layer so words
can be composed at read time in either language. That is the right rule for a
[[Capability]] or a `TicketStatus`, which mean the same thing in every venue. A
category name is content, like a zone's or a menu item's — the same argument
ADR-0131 already made for a box's name, one line after excluding a category from
it.

## Decision

**`cash_categories`, keyed `(box_id, id)`.** Venue-authored, shaped like
`CashBoxes`, `VisitExpenseCategories` and `DiscountPresets`: name, `active`,
`sortOrder`, **soft-delete only**. The composite key is what makes the migration
free — the five stock slugs are seeded into **every** box under their existing
enum names, so a row reading `category='ingredients'` resolves against the
`box_id` it already carries. **Nothing backfills `cash_entries`.** A global uuid
with a `box_id` column was the alternative and it required rewriting a money
column in an append-only ledger to satisfy an id scheme.

The five are seeded on box create, on the v75 upgrade and on every Server boot,
the belt-and-braces `box-main` already gets — no path may leave a box with
nowhere to file an expense. A **new box starts with the five**, and no custom
ones: a tin that cannot take an expense until somebody authors a word is a dead
end.

**`CashCategory` is deleted**, and with it `cashCategoryFromName`,
`cashCategoryLabel` and the five `cashCat*` ARB keys. The stock words therefore
**stop being localised** — an English-locale venue reads *Belanja bahan*. That is
the real cost of this ADR and it is accepted: they become content, in a venue
that authors the other twenty in its own language anyway, and a venue that
dislikes the word can now rename it.

**A rename is retroactive.** The entry stores the id and the word is resolved at
read time, `VisitExpenses`' posture, not `Discounts`' — a discount snapshots
because its *value* is money that must not move, while a category is a label on
money already fixed. One asymmetry falls out and is deliberate: `auditParams`
writes the word at movement time, so the [[Audit]] trail keeps the original while
[[Report freshness (Live vs Snapshot)|Reports]] shows the new one.

**The report's venue-wide `byCategory` is keyed by the venue's word, not by a
code.** Per-box ids cannot merge — two tins' "Sayur" are two rows — and an owner
asking *what did we spend on vegetables* is asking about the word. Each `byBox`
entry gains its own `byCategory`, keyed the same way so the client needs no
lookup and the detail sums to the total. This is the shape
`PengeluaranSectionDto.byCategory` already documents, and its doc comment stops
contrasting with the Kas section.

**Authoring is `editSettings`, on `/kas`.** Spending stays `manageCash`.
Authoring what a tin spends on is the same authority and the same trip as
authoring the tin. **No audit rows** for the catalogue's own CRUD: a box audits
because it holds a balance, and a category is vocabulary — the movement rows
already carry both. Catalogue edits ride the existing **`cash.boxes`** WS frame,
which already replaces the box list wholesale.

**No guard against retiring the last one.** A box with an empty catalogue shows
an empty state pointing at the editor and the write path still refuses
`category_required`. Guarding it would block the natural order — retire the five
you don't use, *then* author yours — to prevent a state that is visible and one
tap from reversible.

## Consequences

- The five stock words leave the ARB. `arb_parity_test` loses five keys; an
  English-locale venue sees Indonesian defaults until it renames them.
- `spendCash` validates the category **against this box**, inside the write
  transaction beside the ADR-0088 balance check (ADR-0100). A category from
  another tin is `unknown_category`, not silently accepted.
- The v75 migration must seed before anything reads, or every historical expense
  renders an unresolvable id. Fresh install and upgraded venue must end
  byte-identical — the population trap ADR-0131's `{box}` backfill and the v63
  `venue_settings` rebuild both hit.
- Still **no module or mode key**, for ADR-0131's reason: one list is the
  degenerate case of N, and a fail-closed key would hide an existing venue's
  categories.
- Transfers stay categoryless and reversals still inherit; neither learns
  anything from this.
