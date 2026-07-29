# Shared UI catalog

**Check this file before writing a new widget.** If something here is close, extend it
(add a parameter, widen a callback) rather than writing a private `_Thing` inside a
screen. Private widgets are how three `StatusChip`s and two `SectionLabel`s happened.

Not auto-generated. When you add, rename, or delete a shared widget, edit this file in
the same commit — **and add a matching entry to the widget book** (`lib/ui/features/_book/
book_entries.dart`, ADR-0054). Guard: `test/design_tokens_test.dart`.

**See the widgets, don't just read about them.** In a debug build, `/book` renders every
widget on this page in all of its states — reachable from the "Book" item at the foot of
the tablet rail, or the "Widget book" button on the sign-in screen when unpaired. Per-entry coverage rule: every enum value, every
meaningful boolean, plus one stress state (longest realistic name, ×99, six modifiers,
two-line note). The stage flips theme/skin, 1.0×/1.3× text scale, reduced motion, and
phone/tablet width.

---

## Where things live

| Path | Scope |
|---|---|
| `lib/ui/core/design/` | Tokens only — colors, type, spacing, motion, skin. No widgets. |
| `lib/ui/core/widgets/` | Cross-feature widgets. Anything used by 2+ features belongs here. |
| `lib/ui/core/state/` | Cross-feature view-models. |
| `lib/ui/features/<area>/widgets/` | Single-feature widgets. Promote to `core/widgets/` on second consumer. |
| `lib/ui/features/admin/_common.dart` | Admin-only chrome. Not for non-admin screens. |

---

## Tokens — `core/design/`

Never hardcode a `Color`, a spacing number, or a curve. Go through these.

| Token | File | Use for |
|---|---|---|
| `context.sat` → `SatColors` | `colors.dart` | Every color. Neutral ramp `bg0`–`bg4`, `border0`–`border2`, `textHi`→`textDim`; semantic `accent`, `success`, `warn`, `urgent`, `info`, `violet`. |
| `Sp.sHair`, `Sp.s1`…`Sp.s12` | `spacing.dart` | Every gap and pad. 2/4/6/8/10/12/14/16/18/20/24/32/40/48 — a 4px grid with half-steps below 20, because a chip with 10px type has no room for an 8px inset and 12 makes it read as a button. `sHair` (2) is for stacked text that belongs together, not for layout. Above 20 the grid is pure. |
| `SatR` | `skin.dart` | Every corner radius. Skin-aware (ADR-0047) — a raw `BorderRadius.circular(n)` ignores the active skin. |
| `SatType` | `typography.dart` | Every text style. |
| `satEaseOut`, `motionEnabled(context)`, `satMotion(context, ms)` | `motion.dart` | Every animation. One curve app-wide. **Take every `duration:` from `satMotion`** — it collapses to zero under reduced motion, and a raw `Duration` ignores that silently (hard-banned by the guard test). Re-exported by `anim.dart`, so a screen using both needs one import. Prefer the `anim.dart` primitives below over raw `AnimatedFoo`. |
| `onFill(Color)` | `colors.dart` | Ink for text on a *saturated* fill (status pill, owner chip, brutal badge). Luminance-derived, so it stays correct on every palette. Never a literal near-black. |
| `darken(Color, [amount])` | `colors.dart` | Far end of an avatar/badge gradient. Blends toward black so a saturated hue keeps its identity. |
| `satBarrier`, `satMediaScrim`, `satShadowInk` | `colors.dart` | Dimming and shadow that must stay dark on *both* themes — modal barrier, label-over-photo scrim, ambient shadow. Not `sc.scrim`: that token is an opaque blend base and paints the layer underneath out entirely. |
| `context.layout` | `layout.dart` | Phone/tablet breakpoints, `useTabletShell`. |
| `courseVisual`, `roleVisual`, `zoneVisual` | `course_visuals.dart`, `role_visuals.dart`, `zone_visuals.dart` | Course/role/zone color + icon. One hue vocabulary — don't re-map. |
| `format.dart` | `format.dart` | Currency, time, duration formatting. |

User-facing strings go through `lib/core/localization/app_strings.dart`. Never inline.

## Accessibility

Flutter derives semantics from `Text`, so anything **without** text needs naming by hand.
Enforced by `test/design_tokens_test.dart` (`IconButton` is a hard ban, not a baseline).

| Situation | Do this |
|---|---|
| Icon-only `IconButton` | `tooltip: AppStrings.…` — doubles as the screen-reader name and the long-press hint. |
| `GestureDetector`/`InkWell` with no text child | Wrap in `Semantics(button: true, label: AppStrings.…)`. |
| Disabled tappable | Pass `enabled:` too, and label the *reason* (`a11yTableLocked`), not the glyph. |
| Composite card (name + chips + banner) | `MergeSemantics` — announces as one unit, and the label stays derived from what is painted, so it cannot drift. See `TableCard`. |

Labels live in the `a11y*` block of `app_strings.dart`. Text scale is clamped to 1.3× in
`lib/app.dart` — a ceiling over fixed-height rows, not a substitute for flexible layout.

---

## Controls — the shared vocabulary (ADR-0055)

**The guard test bans the raw Material equivalents outside `core/widgets/`.** These are
not suggestions; a screen cannot reach for `FilledButton`, `TextField`, `DropdownButton`
or `IconButton` and still pass CI.

It also bans the *lookalikes*: a private `_FilledBtn` that draws the same pill out of a
`Container` never names a Material class, and five of them survived the first sweep for
exactly that reason. A widget whose name claims to be a control (`…Btn`, `…Button`,
`…Chip`, `…Pill`, `…Badge`, `…Field`, `…Toggle`, `…Stepper`) has to be built on one.
Wrapping a shared control to add domain meaning is fine — that is composition. Redrawing
it is not.

| Widget | File | Use for |
|---|---|---|
| `SatButton` | `sat_button.dart` | **Every** button. `.primary` / `.neutral` / `.outline` / `.ghost` / `.success` / `.danger` carry the intent; `size` (sm/md/lg), `icon`, `busy` and `trailingValue` are the only open axes. Disabled reads from the neutral ramp on every variant — a greyed danger button must not still look dangerous. |
| `SatIconButton` | `sat_icon_button.dart` | Icon-only target. `tooltip` is **required**: with no text child Flutter derives no semantics. |
| `SatChip` | `sat_chip.dart` | `.tag` states a fact (seven hues, optional icon/dot/count); `.select` takes a tap. Selection is a **fill, never a tint** — under Glow it fills with `accent` and takes `accentInk`, matching the zone strip (ADR-0051 as amended; the obsidian slab stays on the active menu category tab, which is not a chip). Not `StatusChip`, which stays: a ticket's lifecycle is domain vocabulary with a fixed set. `.tag(filled: true)` fills the hue instead of tinting it and inks via `inkOn` — a fact that changes what someone does, e.g. the KDS paid add-on beside a merely-chosen option (ADR-0051). `neutral` ignores it; its tint is already flat `bg3`. |
| `SatToggle` | `sat_toggle.dart` | On/off. Owns its 44px tap target and its `Semantics(toggled:)`. A disabled toggle still announces its state. |
| `SatStepper` | `sat_stepper.dart` | Quantity. Boxed for forms, `.pill` for a crowded row (`icon`, `showMax` → `3/6`). Count slides in the direction of travel. |
| `SatTabs` + `SatTab` | `sat_tabs.dart` | Segmented strip. No `TabController` — the screen already holds the index. For a handful of options that all fit, prefer a `SatChip.select` row, which shows every choice at once. Two tabs is the **scope switch** shape — mutually exclusive views of one list (the Pesanan board's Milik saya / Semua, ADR-0056) — and needs no wrapper widget of its own. Under Glow the selected tab fills `accent` and inks `accentInk`, matching `SatChip.select` and the zone strip (ADR-0051 as amended). |
| `SatField` | `sat_field.dart` | **Every** text input. The constructor names what it accepts — `.text` / `.number` / `.money` / `.decimal` / `.search` / `.pin` / `.inline` / `.password` — and carries the keyboard, the formatters and the affix. `.inline` is the borderless settings-row editor. `.password` masks unless `visible` and builds its own reveal eye — never hand-roll that suffix onto `.text`, which cannot mask. |
| `satInputDecoration(context, …)` | `sat_field.dart` | For a neighbour Material dresses with an `InputDecoration` and that must match a field beside it. |
| `SatDropdown` + `SatOption` | `sat_dropdown.dart` | One choice from a closed list, in the same box as `SatField`. |
| `SatCard` | `sat_card.dart` | The card surface. `.plain`, `.section` (caps header), `.titled` (title + caps tag — the admin section card), `.tappable` (press feedback + `Semantics`). Owns the surface and the header, not the layout inside. |
| `SatEmpty` | `sat_empty.dart` | "Nothing here yet". `body` is where the next action goes, in words. |
| `SatSectionLabel` | `sat_empty.dart` | Caps label above a section that is not inside a card. |
| `SatSheetHeader` | `sat_sheet_header.dart` | Top of a bottom sheet: padding, leading slot, and the close button with its tooltip. |
| `PulseDot` | `pulse_dot.dart` | Status dot that breathes while something needs attention. Reduced motion holds it at the **midpoint**, not the trough — a dot frozen at its dimmest reads as "off". |

### Type roles — `SatType`

`SatType.sans/mono/display` are the substrate. A screen names a **role**, and a literal
`size:` outside `core/design/` is banned.

`display54` · `h1` · `h2` · `h3` · `bodyL/M/S` · `labelL/M/S` · `monoDisplay54` ·
`monoDisplay` · `monoL/M/S` · `caption`

Only `color` varies per call site. `labelL/M/S` and `monoS`/`monoDisplay54` are
extensions beyond the design source's eleven — the sheet has no w600 body and no small
regular mono, and ~100 call sites needed one.

---

## Motion — `core/widgets/anim.dart`

All collapse to a static final frame under reduced motion. Callers never branch on it.

| Widget | Use for |
|---|---|
| `Reveal` | Fade + slide-up entrance on mount. Increasing `index` staggers siblings (55ms/step). Pass a stable `animKey` for rows in a recycling `ListView.builder` so scroll-back doesn't re-trigger. |
| `ExpandFade` | Conditional block toggling on/off. Animates height + opacity instead of popping. Pass `SizedBox.shrink()` for the absent state. |
| `AnimatedReflow` | List whose children are added/removed — animates own height so rows grow/collapse. Pairs with keyed children. |
| `AnimatedBarFill` | Horizontal track + fill, grows from zero, eases on `factor` change. |
| `GrowBarV` | Vertical bar growing from baseline. Mini charts (cover trend, hourly revenue). |
| `PressScale` | Tactile press dip on any tappable. Child still owns the tap. |
| `AnimatedCount` | Integer rolling to a new value. `builder` renders the interpolated number. |

---

## Chrome — `core/widgets/`

| Widget | File | Use for |
|---|---|---|
| `SatAppBar` | `sat_app_bar.dart` | **The** app bar. Responsive phone/tablet. Don't build another. Pass `crumbs` (coarsest first) — there is no `title`. Tablet renders the trail; phone drops it. Phone owns the clock too, and only when `onBack` is null (ADR-0062). |
| `SatAppBarPill` | `sat_app_bar.dart` | Trailing pill slot in `SatAppBar` (e.g. `T+0:45`). Phone is width-bound — check ADR-0062's budget before adding one. |
| `SatBackButton` | `satset_top_bar.dart` | Back affordance. |
| `safePop(context)` | `satset_top_bar.dart` | Pop with a route fallback — use instead of raw `Navigator.pop`. |
| `TabletShell` | `tablet_chrome.dart` | Tablet shell scaffold. |
| `TabletSideRail` | `tablet_chrome.dart` | Tablet nav rail. |
| `TabletSectionHead` | `tablet_chrome.dart` | Section header (title + sub + trailing). |
| `TabletCard` | `tablet_chrome.dart` | Tablet content card. |
| `TabletStatTile` | `tablet_chrome.dart` | KPI value + label tile. |
| `ExitGuard` | `exit_guard.dart` | Back-to-exit confirmation. Mount inside go_router's `Navigator`. |
| `AlertHost` | `alert_host.dart` | App-wide alert sound keep-alive + `ReadyToast` host. Wrap the router child. |
| `AdminGraceBanner` | `admin_grace_banner.dart` | Offline-stale countdown on a Server-mode device. |

---

## Content

| Widget | File | Use for |
|---|---|---|
| `OrderLineCard` | `order_line_card.dart` | **Canonical** sent-line card: qty, name/variant, badges, modifiers, note, void reason, status chip, elapsed pill, orderer avatar, price, mark-served. Table detail + takeaway detail share it (ADR-0026). Table-agnostic — host supplies `onTap`/`onMarkServed`/`readOnly`. |
| `StatusChip` | `status_chip.dart` | **The** ticket-status pill — one colour vocabulary per `TicketStatus`, shared by the line card, the orders board and the void sheet. Morphs its fill and cross-fades the label when a WS push changes the status under your thumb. |
| `ElapsedPill` | `elapsed_pill.dart` | Time-since-sent. Ticks live, freezes when terminal, escalates to `urgent` at `prepTargetMins` (ADR-0013). |
| `NoteLine` | `note_line.dart` | Guest note / item note. Quiet reference text — never `urgent`-colored. One exception: `alert: true` renders a filled `urgentSoft` block with `textHi` ink, for the KDS ticket card only — at the pass the note is a constraint, not a jotting (ADR-0051). |
| `TagBadgeRow` | `tag_badge_row.dart` | One wrapping row of 2-char code badges, caller passes the kind color. |
| `MenuTagBadges` | `tag_badge_row.dart` | Allergen (red) + diet (blue) stack, live-resolved from the menu by `itemId` (ADR-0012). Prefer this over `TagBadgeRow` on line items. |
| `MenuPhoto` | `menu_photo.dart` | Menu item photo or initials fallback. Fills parent, `BoxFit.cover`. Never a broken image (ADR-0014). |
| `StaffAvatar` | `staff_avatar.dart` | Initials avatar in the account's own color. `mine: true` rings it accent. `fallbackColor:` for an account with no colour yet (staff admin passes the role's). `.raw()` when you hold a view-model row rather than an `AppUser`. **Same person = same swatch everywhere** — three screens used to inline their own, with different darkening and glyph weight, so the same waiter looked like two people between the rail and the list. |
| `ReadyBanner` | `ready_banner.dart` | Inline ready notice. |
| `ReadyToast` | `ready_toast.dart` | Transient ready alert with view/dismiss. Mounted by `AlertHost` — don't mount directly. |

---

## Loading

| Widget | File | Use for |
|---|---|---|
| `Shimmer` | `skeleton_card.dart` | Sweeps highlight across any child while loading. |
| `SkeletonBox` | `skeleton_card.dart` | Rounded placeholder block. |
| `SkeletonCard` | `skeleton_card.dart` | Placeholder card. |
| `ReportsSkeleton` | `skeleton_card.dart` | Reports-shaped loading state (KPI row + two charts). |

Loading state should echo the layout that's about to appear — compose `SkeletonBox` into
a screen-shaped skeleton rather than dropping a `CircularProgressIndicator`.

---

## Overlays

Anything that floats above the current route goes through `sat_overlay.dart` (ADR-0061).
Raw `showModalBottomSheet` / `showDialog` / `showGeneralDialog` fail CI — they default to
the *shell* navigator, which on a phone paints under the floating tab bar.

| Entry | Use for |
|---|---|
| `showSatSheet<T>(context, builder:)` | Bottom sheet. `bare: true` for a body with its own chrome; `scrollControlled: false` for Material's 9/16 cap; `dismissible: false` to block tap-away. |
| `showSatDialog<T>(context, builder:)` | Centred dialog. |
| `showSatDrawer<T>(context, builder:)` | Edge-anchored panel; `alignment` picks the edge. |

Never pass `backgroundColor` or `shape` — colour, radius and elevation come from
`bottomSheetTheme` / `dialogTheme`. Safe area and `viewInsets` keyboard padding are the
body's job.

### Sheet entry points

Entry points, not widgets. Call the function; don't open the sheet yourself.

| Entry | File | Returns |
|---|---|---|
| `showPinSheet(...)` | `pin_sheet.dart` | `bool?` — `true` on verify, `null` on dismiss. `onSubmit` returns `null` for OK or an error string to shake. |
| `showExportSheet(...)` | `export_sheet.dart` | `void`. One sheet for every export kind (ADR-0030/31/32). |
| `showCustomRangeSheet(...)` | `custom_range_sheet.dart` | `(DateTime, DateTime)?` — inclusive date-only range, `null` on dismiss. |
| `showThemeSheet(context, ref)` | `../../features/me/widgets/theme_sheet.dart` | `void`. Theme + skin picker. |

---

## Feature-local

Listed so you find them before rebuilding them. Promote to `core/widgets/` on a second consumer.

**`features/tables/widgets/`**

| Entry | File |
|---|---|
| `TableCard` | `table_card.dart` — floor grid card: state, owner, staleness. |
| `showGuestStepperSheet(...)` | `guest_stepper_sheet.dart` |
| `showAssignTableSheet(...)` → `AssignTableResult?` | `assign_table_sheet.dart` |
| `showMoveTableSheet(...)` → `String?` | `move_table_sheet.dart` |
| `openReservationsSurface(...)`, `ReservationsBook`, `SeatPicker`, `openCreateReservationSheet(...)` | `reservations_surface.dart` |
| `openTakeawaySurface(context)` | `takeaway_surface.dart` |

**`features/admin/`**

| Entry | File |
|---|---|
| `AdminPage`, `AdminRow`, `SetTile`, `SetHero`, `AdminEmbeddedStrip` | `_common.dart` — `adminPill`/`adminToggle` are gone; use `SatButton`/`SatChip`/`SatToggle`. |
| `ReceiptPreview`, `ReceiptPreviewData` | `widgets/receipt_preview.dart` |

---

## Duplicates

There are none, and the guard test keeps it that way: a widget class name declared in
two files fails CI. If two things really are different, name them for what they are.

### Consolidated (do not re-create)

| Was | Now |
|---|---|
| `_StatusChip` ×3 (`order_line_card`, `orders_screen`, `line_item_action_sheet`) | `StatusChip` — `core/widgets/status_chip.dart` |
| `_EntranceFade` ×2 (`order_line_card`, `table_detail_screen`) | `Reveal` — `anim.dart`. `delayMs: i * 50` became `index: i`. |
| `Reveal` ×2 + `PressableScale`/`PressScale` (two parallel motion systems, one in `design/motion.dart` and one in `widgets/anim.dart`) | One each in `anim.dart`. `design/motion.dart` is tokens only, per the layout rule above. |
| `kSatEase` `Cubic(0.16, 1, 0.3, 1)` vs `satEaseOut` `Cubic(0.22, 1, 0.36, 1)` | `satEaseOut`. Two ease curves is two hands, not one. |
| `computeLuminance() > 0.45 ? dark : light` ×3 | `onFill(Color)` — `design/colors.dart`. Took the last hardcoded `Color(0x…)` in `lib/ui/` with it; that rule is now a hard ban. |
| Inline avatar ×3 (`staff_screen`, `me_screen`, plus the rail) with 0.32/0.36 darkening | `StaffAvatar` / `StaffAvatar.raw`. The rail keeps its own chrome but shares the tokens. |
| `_d(context, …)` ×2, `_motion(context, …)`, `_kEase` ×4, `_kStatusXfade` ×3 | `satMotion`, `satEaseOut`, `satStatusXfadeMs` — `design/motion.dart`. |
| ~139 raw `FilledButton`/`OutlinedButton`/`TextButton`/`ElevatedButton` | `SatButton` / `SatIconButton`. |
| 64 raw `TextField` + the menu editor's private `_fieldDeco`/`_input` pair | `SatField` + `satInputDecoration`. |
| 7 `DropdownButton*` | `SatDropdown`. |
| `adminPill` (a button call sites wrapped in a bare `GestureDetector`) | `SatButton` where a tap was attached, `SatChip.tag` where none was. |
| `adminToggle`, `_Switch`, 4× Material `Switch` | `SatToggle`. |
| `_Stepper`, `_StepperBtn`, `GuestStepper` | `SatStepper` / `SatStepper.pill`. |
| `_TabSwitcher`/`_TabFade`, `_Segments`/`_SegBtn` | `SatTabs`, or a `SatChip.select` row where the counts matter. |
| 12 private `_XChip`/`_XPill`/`_XBadge` | `SatChip.tag` / `SatChip.select`. |
| 6 hand-drawn section cards | `SatCard.section` / `SatCard.titled`. |
| `_PulseDot` ×2, `_Empty` ×2, `_SectionLabel` ×2, `_Head` ×2, a second private `Reveal` | `PulseDot`, `SatEmpty`, `SatSectionLabel`, `SatSheetHeader`, `Reveal`. |
| 730 `SatType.sans/mono/display(size: …)` call sites | The named roles above. |
