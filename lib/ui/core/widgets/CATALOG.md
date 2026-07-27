# Shared UI catalog

**Check this file before writing a new widget.** If something here is close, extend it
(add a parameter, widen a callback) rather than writing a private `_Thing` inside a
screen. Private widgets are how three `StatusChip`s and two `SectionLabel`s happened.

Not auto-generated. When you add, rename, or delete a shared widget, edit this file in
the same commit. Guard: `test/design_tokens_test.dart`.

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
| `Sp.s1`…`Sp.s12` | `spacing.dart` | Every gap and pad. 4/8/12/16/20/24/32/40/48. Off-scale values (6, 10, 14, 18) are drift — snap to the nearest step. |
| `SatR` | `skin.dart` | Every corner radius. Skin-aware (ADR-0047) — a raw `BorderRadius.circular(n)` ignores the active skin. |
| `SatType` | `typography.dart` | Every text style. |
| `satEaseOut`, `motionEnabled(context)` | `motion.dart` | Every animation. One curve app-wide. Re-exported by `anim.dart`, so a screen using both needs one import. Prefer the `anim.dart` primitives below over raw `AnimatedFoo`. |
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
| `SatAppBar` | `sat_app_bar.dart` | **The** app bar. Responsive phone/tablet. Don't build another. |
| `SatAppBarPill` | `sat_app_bar.dart` | Trailing pill slot in `SatAppBar` (e.g. `T+0:45`). |
| `LoginClock` | `satset_top_bar.dart` | Live clock. |
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
| `NoteLine` | `note_line.dart` | Guest note / item note. Quiet reference text — never `urgent`-colored. |
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

## Sheets

Entry points, not widgets. Call the function; don't `showModalBottomSheet` yourself.

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
| `GuestStepper` | `guest_stepper.dart` — pax +/- control. |
| `showGuestStepperSheet(...)` | `guest_stepper_sheet.dart` |
| `showAssignTableSheet(...)` → `AssignTableResult?` | `assign_table_sheet.dart` |
| `showMoveTableSheet(...)` → `String?` | `move_table_sheet.dart` |
| `openReservationsSurface(...)`, `ReservationsBook`, `SeatPicker`, `openCreateReservationSheet(...)` | `reservations_surface.dart` |
| `openTakeawaySurface(context)` | `takeaway_surface.dart` |

**`features/admin/`**

| Entry | File |
|---|---|
| `AdminPage`, `AdminRow`, `SetTile`, `SetHero`, `AdminEmbeddedStrip`, `adminPill(...)`, `adminToggle(...)` | `_common.dart` |
| `ReceiptPreview`, `ReceiptPreviewData` | `widgets/receipt_preview.dart` |

---

## Known duplicates — consolidate on contact

Rebuilt in more than one place. Guarded by `test/design_tokens_test.dart`
("widget class name declared in 2+ files", baseline 12) — the count can fall, never rise.

| Name | Copies | Target |
|---|---|---|
| `_CourseBlock` | 2 (`table_detail`, `review`) | Likely a real copy. Promote on contact. |
| `_ZoneRow` | 2 (`tables_screen`, `zone_admin`) | Likely a real copy. Promote on contact. |
| `_PulseDot` | 2 (`pin_screen`, `kitchen_screen`) | **Same name, different widget.** One glows via `spreadRadius` and always pulses; the other scales and gates on a `pulse` flag. Merging them yields a 4-param widget with two behaviours — rename instead. |
| `_FilterChip` | 2 (`cashier_bill`, `reservations_surface`) | **Same name, different widget.** One is a plain Material pill, the other carries a count badge and skin-aware fills. Rename to `_SatFilterChip` / `_RvFilterChip` (both also shadow Material's `FilterChip`). |
| `_SectionLabel` | 2 (`discount_presets`, `me_screen`) | **Same name, different widget.** Different padding, size, weight, tracking. |
| `_Header`, `_Empty`, `_Section`, `_Footer`, `_Head`, `_ItemRow`, `_PhoneDetailScreen` | 2–3 each | Generic names over unrelated widgets. Rename on contact; do not merge. |

### Consolidated (do not re-create)

| Was | Now |
|---|---|
| `_StatusChip` ×3 (`order_line_card`, `orders_screen`, `line_item_action_sheet`) | `StatusChip` — `core/widgets/status_chip.dart` |
| `_EntranceFade` ×2 (`order_line_card`, `table_detail_screen`) | `Reveal` — `anim.dart`. `delayMs: i * 50` became `index: i`. |
| `Reveal` ×2 + `PressableScale`/`PressScale` (two parallel motion systems, one in `design/motion.dart` and one in `widgets/anim.dart`) | One each in `anim.dart`. `design/motion.dart` is tokens only, per the layout rule above. |
| `kSatEase` `Cubic(0.16, 1, 0.3, 1)` vs `satEaseOut` `Cubic(0.22, 1, 0.36, 1)` | `satEaseOut`. Two ease curves is two hands, not one. |
| `computeLuminance() > 0.45 ? dark : light` ×3 | `onFill(Color)` — `design/colors.dart`. Took the last hardcoded `Color(0x…)` in `lib/ui/` with it; that rule is now a hard ban. |
