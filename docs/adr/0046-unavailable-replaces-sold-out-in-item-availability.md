# ADR-0046 — "Tidak tersedia" replaces "habis" for item availability

## Status

Accepted.

## Context

A menu item can stop being sellable for two unrelated reasons:

1. **Stock ran out.** `MenuItem.isAutoSoldOut` — a recipe ingredient hit zero, so
   the server marks the item down automatically (ADR-0040, ADR-0041).
2. **An admin switched it off.** `MenuItem.unavailable` — the manual flag. Stock
   may be completely full; the kitchen simply isn't serving it today.

Both funnelled into one word, `habis`, and the copy showed the strain:

| state | copy | true? |
| --- | --- | --- |
| `isAutoSoldOut` | `Otomatis ditandai habis (stok 0)` | yes — ingredients ran out |
| `unavailable` | `Ditandai habis manual` | **no** — nothing is habis |
| neither | `Aktif untuk dijual` | yes |

`Ditandai habis manual` asserts something false. Worse, the same word labelled
both a state and a command: the action button read `Habis`, inside a section
titled `Ketersediaan`. Item-count strips (`N habis`) counted *both* causes, so
the label was already wrong there for the same reason.

## Decision

### One word for "cannot be sold", cause in the parenthetical

`tidak tersedia` is the state. The cause is a detail appended in parentheses,
not a separate vocabulary:

| state | copy |
| --- | --- |
| `isAutoSoldOut` | `Tidak tersedia (stok 0)` |
| `unavailable` | `Tidak tersedia (manual)` |
| neither | `Aktif untuk dijual` |
| action button | `Tandai tidak tersedia` / `Aktifkan` |
| header badge | `Tidak tersedia` / `Aktif` |
| count strips | `N tidak tersedia` |

The rejected alternative was splitting by cause — keep `habis` for stock-driven,
use `tidak tersedia` for admin-driven. It is the more precise model, and for a
seated admin it would be better.

It loses because of who reads the word. This label is read by a waiter
mid-rush, at arm's length, in about half a second, and **both states have the
identical consequence: do not sell this.** Making that reader distinguish two
words to arrive at one action is cost with no payoff at the moment of use. An
admin who needs the cause finds it in the parenthetical; a waiter ignores it.

### `habis` survives where it is literally true

The rename is scoped to *item availability*. These keep `habis`, because in each
the thing named genuinely ran out:

- `Bahan habis` — an ingredient, not an item.
- `N varian habis` — variants, same reasoning.
- `'$name · habis'` in the modifier sheet.
- `Stok habis` as a **void reason** (`tickets_routes.dart`,
  `reports_routes.dart`). Different concept, different flow, and it feeds
  reports — renaming it would break continuity of historical data.

Renaming those would be the actual inconsistency: `habis` means *ran out*, and
that is exactly what they mean.

## Consequences

- `habis` narrows to a claim about **stock**. Any future copy asserting it must
  be able to point at something that reached zero.
- `tidak tersedia` becomes the vocabulary for **sellability**, independent of
  cause. New reasons for an item being unsellable (scheduled hours, station
  offline) extend the parenthetical rather than inventing a third word.
- The availability control moved to the top of the item editor and gained a
  read-only status badge in the editor header. Availability reads as item
  *status*, not as a form field near the bottom of a long scroll.
