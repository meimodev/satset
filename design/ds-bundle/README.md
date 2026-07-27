# Claude Design bundle

Static mirror of SatSet's design system, published to the Claude Design project
**"Design System"** (`903615af-8796-484d-aa4a-bd1cf0e1ceb2`).

`lib/ui/core/design/` is the source of truth. These files are a hand-maintained
transcription — when a Dart token changes, update the matching page here in the same
commit, then re-push. Nothing here is generated, and nothing here feeds back into the app.

## Layout

Flat on purpose: the pane serves each preview standalone, and a same-directory
`href="ds.css"` is the one relative link that always resolves.

| File | Mirrors |
|---|---|
| `ds.css` | All six palettes as `[data-pal="…"]` blocks + shared component classes |
| `index.html` | Brand context — personas, principles, anti-references (CLAUDE.md §Design Context) |
| `tokens-color.html` | `colors.dart` |
| `tokens-type.html` | `typography.dart` |
| `tokens-spacing-layout.html` | `spacing.dart`, `layout.dart` |
| `tokens-shape-skin.html` | `skin.dart` (ADR-0047) |
| `tokens-motion.html` | `motion.dart`, `anim.dart` |
| `tokens-course-role-zone.html` | `course_visuals.dart`, `role_visuals.dart`, `zone_visuals.dart` |
| `comp-status-chip.html` | `_StatusChip` in `order_line_card.dart` |
| `comp-pills.html` | `elapsed_pill.dart`, `_NetworkPill`/`SatAppBarPill`, `_StatePill` |
| `comp-badges-avatar-note.html` | `tag_badge_row.dart`, `staff_avatar.dart`, `note_line.dart`, `menu_photo.dart` |
| `comp-order-line-card.html` | `order_line_card.dart` |
| `comp-table-card.html` | `features/tables/widgets/table_card.dart` |
| `comp-app-bar.html` | `sat_app_bar.dart`, phone shell tab bar |
| `comp-side-rail.html` | `TabletSideRail` in `tablet_chrome.dart` |
| `comp-tablet-surfaces.html` | `TabletSectionHead`, `TabletCard`, `TabletStatTile` |
| `comp-ready-alerts.html` | `ready_banner.dart`, `ready_toast.dart`, `admin_grace_banner.dart` |
| `comp-skeletons.html` | `skeleton_card.dart` |
| `comp-motion-primitives.html` | `anim.dart` — every primitive, live, plus the full duration table |
| `comp-buttons.html` | The button shapes that recur (there is no shared Button widget) |
| `comp-inputs.html` | `_Field` in `pin_screen.dart`, `modifier_sheet.dart`, `reports_screen.dart` filter chip, `adminToggle` |
| `comp-sheets.html` | `pin_sheet.dart`, `export_sheet.dart`, `custom_range_sheet.dart`, `me/widgets/theme_sheet.dart` |
| `comp-modifier-sheet.html` | `features/menu/modifier_sheet.dart` |
| `comp-states.html` | Empty / loading / error across every feature |
| `pattern-floor-grid.html` | `/tables` |
| `pattern-table-detail.html` | `/table/:id` |
| `pattern-kds.html` | `/kitchen` |
| `pattern-menu-browse.html` | `/table/:id/menu` — phone grid + tablet cart pane |
| `pattern-review.html` | `/table/:id/review` + commit chooser (ADR-0026) |
| `pattern-sent.html` | `/table/:id/sent` |
| `pattern-signin.html` | `/pin` — admin form, staff server list, restore loader |
| `pattern-onboarding.html` | `/onboarding`, `/pair`, `/forbidden` — **as shipped (stock Material) and as targeted** |
| `pattern-admin.html` | `/venue`, `_common.dart` surfaces, `/reports` chrome |
| `pattern-guest-spa.html` | `lib/server/guest_app_html.dart` (ADR-0027 / 0029) |

### Known deviations recorded in the bundle

- **`pattern-onboarding.html`** — mode select, pair and forbidden render stock Material 3
  with the default purple seed. No `context.sat`, no `SatType`, no `SatBox`. The page shows
  both what ships today and what it should be; it is the first screen a new install sees.
- **`comp-buttons.html`** — there is no button widget in `ui/core/widgets/`. Every call site
  builds its own. The page documents the heights and radii that repeat often enough to count
  as the system, and says plainly that the remaining variance is drift.
- **Menu search** — rendered on both phone and tablet menu screens, inert. Flagged in
  `comp-inputs.html` so it is not read back as a working control.

### Still not covered

Cashier (`/cashier`, bill, discount sheet), stock, staff and menu admin editors, fleet
console, takeaway and reservations surfaces, printing / receipt preview, `/me`, `/orders`,
void flow. These reuse the primitives above; none introduces a new visual idiom.

Each page renders dark plus at least one contrasting palette, and carries a `.spec` block
holding the *why* — lifted from the Dart doc comments, not restated from the CSS.

## Re-sync

The `/design-sync` skill is not installed, so the `DesignSync` tool is driven by hand and
the `_ds_manifest.json` self-check never runs — the `@dsCard` first-line comments alone
will not build the pane index. `register_assets` is mandatory on any newly added page.

1. `list_files` on the project, diff against this directory. These are app-managed, have no
   local counterpart, and must never appear in a `deletes` list:
   `_adherence.oxlintrc.json`, `_ds_bundle.js`, `_ds_manifest.json`, `styles.css`,
   `thumbnail.html`, `.thumbnail`, `fonts/**`, `tokens/fonts.css`.
2. `finalize_plan` — `writes` and `deletes` are **both required** (`deletes: []` if none);
   `localDir` is this directory.
3. `write_files` with `localPath` per file. Same path redeploys in place.
4. `register_assets` for new pages only. Existing cards keep their group and viewport.

Do not push to project `22fdf998-a3c0-49f4-a3bf-ada54fa87e3b` ("SatSet v2") — it is
`PROJECT_TYPE_PROJECT`, and the type is immutable at creation.
