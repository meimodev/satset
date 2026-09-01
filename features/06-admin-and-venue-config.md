# 06 · Admin & venue configuration

This area covers everything reached from the Venue hub (`/venue`, `VenueHubScreen`, `lib/ui/features/admin/venue_hub_screen.dart:270`): menu administration (categories, items, item editor, modifier groups, tags/allergens, photos), staff and role/capability editing, venue identity and receipt branding, tax/service configuration, discount presets, the [[Modul]] / [[Kedai]] mode / bypass-KDS entitlement system, the venue day open/close ritual, shifts, alerts configuration, the System (Sistem) screen (server status, printers/KDS stations, paired devices, restart), and seeding/clearing sample data. Every screen here is admin-facing: reached through the shell's Venue tab or the hub's tiles, gated by a `Capability`, and mostly tablet-first with a phone fallback that pushes detail views.

## Feature index

| Feature | Route | Capability | Server |
|---|---|---|---|
| Venue hub | `/venue` | `manageStaff` | reads several snapshots; writes none itself |
| Menu administration (items/categories/tags) | `/menuadm`, `/menuadm/:id` | `editMenu` (route); server also gates `markSoldOut` for the availability toggle | `GET/POST/PATCH/DELETE /menu/*` |
| Staff & roles | `/staff` | `manageStaff` | `GET/POST/PATCH/DELETE /staff`, `/roles` (in `reference_routes.dart`) |
| Venue settings (identity, receipt, tax/service, membership) | `/venue-settings` | `editSettings` | `GET/PATCH /venue/settings`, `GET/PUT/DELETE /venue/logo` |
| Discount presets | `/venue/diskon` | `editSettings` | `GET/POST/PATCH/DELETE /venue/discount-presets` |
| Zone & table admin | `/zone-admin` | `editSettings` | `GET/POST/PATCH/DELETE /zones` (in `reference_routes.dart`); tables via `tables_routes.dart` |
| Alerts configuration | `/alerts` | `editSettings` (thresholds/sounds are venue-wide via `PATCH /venue/settings`); device mute is local-only, no server call | `PATCH /venue/settings` |
| Venue day open/close | `/venue-day` | `openDrawer` (open half) / `closeShift` (close half) — either opens the screen | `POST /venue/day/open`, `POST /venue/day/close` |
| System (Sistem) | `/system` | `manageStaff` | `GET /server/status`, `POST /server/restart`, `GET /devices`, `POST /devices/<id>/revoke`, `GET/POST/PATCH/DELETE /printers`, `GET /kds/stations`(ish)/queue |
| Seed / clear sample data | dialog from `/venue` or `/system` | `manageStaff` | `GET /seed/state`, `POST /seed/generic`, `POST /seed/clear`, `POST /seed/skip` |

## Venue hub (ID · EN: [[Venue]])

**What** The landing screen for everything in this document — a grid of tiles, each opening one admin surface, plus a hero strip with venue identity and a live-status pill.

**Who** Anyone who can reach `/venue` — gated by `Capability.manageStaff` at the router (`_capabilityFor` in `lib/router/app_router.dart:135-139`, the bare `/venue` prefix arm). In practice this is the venue owner/admin.

**Where** `lib/ui/features/admin/venue_hub_screen.dart`. Tablet renders `AdminPage` with a hero strip (`_VenueHeroStrip`) plus a two-column `_HubGrid`; phone renders `_PhoneHub`, a single-column list with the same cards.

**How to use**
1. Open the Venue tab (rail item or bottom tab, capability-gated).
2. If the venue has never answered the sample-data prompt, a **non-dismissible** dialog appears first (see [Seeding sample data](#seeding--clearing-sample-data-generic-seed) below) — every other tile is unreachable until it is answered.
3. Tap a tile to open its screen: **Zona** (`/zone-admin`), **Menu** (`/menuadm`), **Stok** (`/stock`), **Pengaturan Venue** (`/venue-settings`), **Peringatan** (`/alerts`), **Sistem** (`/system`), **Staf** (`/staff`), **Laporan** (`/reports`), **Pesan mandiri** admin (`/selforder-admin`, only if `moduleSelfOrder` held), **Buka & tutup kedai** (`/venue-day`), **Kas** (`/kas`), **Pelanggan** (`/members`, if `moduleMembers` held), **Laporan anggota** (`/member-report`, if `moduleMembers` held), **Opname** (`/opname`), **Audit** (`/audit`).
4. A tile behind an unheld [[Modul]] renders **locked** (padlock icon, "Terkunci" badge) rather than hidden — tapping it opens an explanation dialog (`_showLocked`, `venue_hub_screen.dart:607-629`) instead of navigating, because "the routes behind it are gated server-side regardless" (ADR-0107 §3) — the lock is a sales surface, not a security boundary.
5. Tap the identity chip in the hero strip (`Ubah` / settings icon) to jump straight to `/venue-settings`.

**Under the hood**
- `_HubSection` (`venue_hub_screen.dart:32-63`) is the tile model: label, sub, icon, route, tint, an optional `badgeBuilder(ref)` for a live count, an optional `phoneBadge` string shown instead on phone for tablet-shaped destinations, an optional `hasAlert(ref)` predicate, and an optional `module` string.
- `_sectionsFor(l10n)` (line 68) is rebuilt per call, never cached in a `final`, so the list never outlives a locale change (ADR-0083).
- Badges read live Riverpod state: `zonesProvider`/`tablesProvider` (Zona), `menuItemsProvider`/`menuCategoriesProvider` (Menu), `ingredientsProvider` low-stock count (Stok), `venueSettingsProvider` tax/service state (Pengaturan Venue), `alertsSummary()` (Peringatan), `apiConfigProvider` host address (Sistem), `staffRepositoryProvider` count (Staf), `cashProvider` balance (Kas), `venueAuditProvider` event count (Audit).
- Module lock check: `_HubCard.build` (line 637) reads `venueSettingsProvider`, computes `locked = section.module != null && !settings.hasModule(section.module!)` — `hasModule` is the client mirror of `venueHasModule` on `VenueSettingsDto` (see [Module system](#module--mode--switch-system) below).
- First-run seed prompt: `_VenueHubScreenState.build` watches `genericSeedProvider.select((s) => s.mustPrompt)` and, if true and not yet shown this frame, schedules `showSeedDataDialog(context)` via `addPostFrameCallback` (lines 294-302).

**Offline behaviour** The hub itself makes no writes; every badge is a read off an already-hydrated repository, so it renders from cache while offline. The seed dialog's actions (`/seed/generic`, `/seed/clear`, `/seed/skip`) are plain HTTP calls with no offline queue — they require a live host.

**ADRs** ADR-0107 (module lock semantics, entitlement fails open), ADR-0083 (locale-rebuilt section list), ADR-0089 (Kas tinted `info` not `success` — not revenue), ADR-0111 (Buka/tutup kedai tile deliberately carries no "is it open" badge).

**Gotchas** The hub's own route capability (`manageStaff`) is stricter than several of the tiles it links to (e.g. `/kas` also opens for `manageCash`, `/opname` also for `manageIngredients`) — those capability-holders reach their screens through other navigation (e.g. deep link, or a rail entry outside the hub), never through this hub, because the hub itself is `manageStaff`-only.

## Menu administration — items, categories, tags (ID · EN: [[Menu]])

**What** CRUD for the menu catalogue: items (name, description, price, variants, modifier groups, recipe/HPP, photo, allergens/diet tags, availability), categories (ordered), and the allergen/diet tag vocabulary. Two-tier permission: staff get a read-only availability toggle, admin get full CRUD.

**Who** Route capability is `Capability.editMenu` (`_capabilityFor`, `app_router.dart:131`). Inside the screen, the finer split is client-side legacy-role based, not capability-based: `menuPermissionProvider` (`menu_admin_view_model.dart:28-33`) returns `MenuPermission.admin` only when `auth.user?.role == UserRole.admin`, else `MenuPermission.staff`. Staff can long-press an item to toggle availability (server-gated by `Capability.markSoldOut`); everything else is admin-only.

**Where** `lib/ui/features/admin/menu_admin_screen.dart` (list/tabs shell), `lib/ui/features/admin/menu_admin_item_editor.dart` (the full item editor, ~1950 lines), `lib/ui/features/admin/menu_admin_item_screen.dart` (phone-only full-screen wrapper at `/menuadm/:id`), `lib/ui/features/admin/menu_admin_view_model.dart` (providers).

**How to use**
1. Open **Menu** from the hub or the shell. Tablet shows a master-detail layout (`_TabletLayout`): item list on the left, editor on the right. Phone shows a list only; tapping an item pushes `/menuadm/:id`.
2. Three tabs (admin only, `_TabSwitcher`, `menu_admin_screen.dart:757-780`): **Item**, **Kategori**, **Tag** (`MenuAdminTab.items/categories/tags`).
3. **Item tab**: search box (`SatField.search`) + a horizontal category rail (`_CategoryRail`) filter the list. Tap **+ Item** (`mnaAddItemShort`/`mnaAddItem`) to start a blank draft. Tap a row to select it (tablet) or push the editor (phone). Long-press a row (admin) or tap its status pill to toggle sold-out — going *off* the menu opens `showKillReasonSheet` asking why (four presets — "Kehabisan stok / Kualitas / Alat rusak / Terlalu lambat" — plus free text; the reason lands on the audit row); coming *back on* needs no reason.
4. **Kategori tab**: reorderable list (`ReorderableListView`) with per-row rename/delete. Deleting is blocked while any item still references the category (button shows a snackbar naming the count, or the server rejects with `409 category_not_empty`).
5. **Tag tab**: two groups, **Alergen** and **Diet** (`MenuTagKind.allergen`/`.diet`). Each tag has a name and a short code (e.g. `GL`). Add/edit opens a small dialog; delete strips the tag id from every item's `allergens`/`dietary` arrays server-side.
6. Inside the item editor (`MenuAdminItemEditor`), sections cascade in: **Ketersediaan** (availability toggle + status pill — locked while auto-habis is true), **Identitas** (photo, name, description, category chips), **Harga** (base price, prep-time override with `mieFollowVenue` hint showing the inherited venue target, cost/HPP, live margin preview, variants list), **Grup modifier** (required/multi toggles, options with price deltas), **Resep** (per-scope recipe lines — base / per-variant / per-modifier-option — plus **Jual satuan** to mint a bought-in `pcs` ingredient and **Buang** to waste a portion, gated on `Capability.manageIngredients`), **Tag** (allergen/diet chips).
7. **Save** validates every name field is non-blank (`_hasBlankNames`); a photo pick/clear on an *existing* item applies immediately (PUT/DELETE side-call, ADR-0014), not staged for Save — only a brand-new item's photo rides the first Save. **Hapus** (delete) asks to confirm via a bottom sheet.

**Under the hood**
- Server routes: `lib/server/routes/menu_routes.dart`. `GET /menu` is open (unauthenticated snapshot read); every write (`POST/PATCH/DELETE /menu/items`, `/menu/categories`, `/menu/tags`, category/tag reorder) requires `Capability.editMenu`; the sold-out toggle is `POST /menu/items/<id>/availability`, gated by `Capability.markSoldOut` and audited (`AuditKind.menuKilled`/`menuRestored`) only on an actual flip, with the free-text reason attached.
- Photo bytes never ride the item JSON — `GET/PUT/DELETE /menu/items/<id>/photo` are side-endpoints; the snapshot carries only `photoRev` (bumped on write, used for cache-busting).
- `menuAdminFilteredItemsProvider` combines the category filter and search query client-side; `menuRealCategoriesProvider` strips the seed's synthetic "Semua"/`all` pseudo-category.
- Item list order is **not** user-controlled: the order-taking grid (not this admin screen) sorts by a derived, never-stored 30-day popularity rank (`popQty` on the wire, computed by `menuPopularity()` in `menu_routes.dart:567-587`) — ADR-0113. The admin list itself stays in whatever order the snapshot returns (insertion/category order), deliberately not resorted by sales, "since an owner hunting an item to edit wants a list that does not move between shifts."
- `deriveStockFlags` (from `stock.dart`) computes `autoSoldOut`/`soldOutVariantIds`/`soldOutOptionIds` from ingredient stock on every snapshot — nothing about auto-habis is stored (ADR-0040).

**Offline behaviour** Not in `SendIntentKind`'s offline-capable set — menu edits are plain HTTP calls with optimistic local state and rollback on failure (see the repository's `catchError` pattern used throughout `staff_repository.dart`/`roles_repository.dart`, and `menuRepositoryProvider` similarly). A client-mode device with no host simply cannot edit the menu; this is not part of the [[Antrean kirim]] or [[Antrean setelmen]] offline paths.

**ADRs** ADR-0009 (per-item embedded modifiers, private JSON blob), ADR-0014 (photo blob + pinned byte fetch, side-endpoint pattern), ADR-0040 (auto-habis derived from ingredient stock, never stored; HPP is a manual field with a derived-cost helper beside it, never overwriting it), ADR-0043 (per-item prep-time inherits the venue target when blank), ADR-0046 ("unavailable" replaces "sold out" terminology in the availability model), ADR-0113 (menu order is a derived rank, frozen at mount, computed only for order-taking, not this screen).

**Gotchas** `menuPermissionProvider` checks the *legacy* `UserRole.admin` enum, not a `Capability` directly — a custom role holding `editMenu` but not mapped to the legacy admin bucket still renders the read-only staff UI client-side (though the route itself already required `editMenu` to get here at all, so this mostly affects the availability-only long-press gate). Deleting a menu tag cascades a rewrite of every item's `allergensJson`/`dietaryJson` — there is no undo.

## Staff & roles (ID · EN: [[Staf & akun]])

**What** Two tabs: **Orang** (people — CRUD staff accounts, PIN, avatar colour, role assignment) and **Peran** (roles — CRUD custom roles, capability grants, colour). Permissions are edited one role at a time in a sheet (ADR-0087), replacing an earlier role × capability grid.

**Who** Route capability `Capability.manageStaff` (`_capabilityFor`, `app_router.dart:135-138`, the same arm as `/system` and `/venue`).

**Where** `lib/ui/features/admin/staff_screen.dart` (~1600 lines: list, filters, add-staff sheet, staff detail drawer, roles list, role-permissions drawer).

**How to use — Orang tab**
1. Search by name (`SatField.search`) and filter by role chip (`Semua` + one chip per role, showing member count).
2. Cards render in a responsive `Wrap` grid (tablet) or a simple list (phone); each shows avatar, name, role badge, PIN.
3. **+ Staf** (`staffAddPill`) opens `_NewStaffDialog`: name, role dropdown (excludes any role holding `manageStaff` — "Butuh peran non-admin" if none exist), and an avatar-colour swatch grid warning on collision with another staffer's colour. A 6-digit PIN is auto-generated (unique across the venue) on create.
4. Tapping a card opens `_StaffDetailDrawer`: rename, reassign role (blocked with a toast if the target role holds `manageStaff` — "admin is Firebase-only, never assignable from this screen", ADR-0017), avatar colour, PIN field + **Reset PIN** button, active/inactive toggle (confirms before disabling), and **Hapus**/**Simpan perubahan** at the footer.

**How to use — Peran tab**
1. Header shows role count and **+ Peran baru**. Each row is scan-only: colour dot, name, `n/22 izin` count, `n anggota` count, chevron — the admin role additionally carries a violet "Admin" badge.
2. Tapping a row opens `_RolePermissionsDrawer`: for a normal role, **Warna**/**Rename**/**Hapus** (delete disabled while any member holds the role) at the top, then every `Capability` grouped by `CapabilityGroup` (`Pesanan`/`Uang`/`Inventaris`/`Admin`/`Dapur`) as a toggle row with a one-line description beside the label (this is the fix for the old grid's illegible 3-way stock-capability confusion).
3. The **admin role** (any role holding `Capability.manageStaff`) renders **read-only end to end**: a banner explains it's locked, no rename/colour/delete controls, and every capability row shows plain text ("Aktif"/inactive) instead of a toggle — because admin is Firebase-provisioned only (ADR-0077) and its capability set is reconciled to `Capability.values` on every server boot (`_ensureAdminRole`, see [Seeding](#seeding--clearing-sample-data-generic-seed)).
4. `Capability.manageStaff` itself is never offered as a toggle on *any* role's sheet — granting it through the UI would mint a local admin as a backdoor (ADR-0017); the row shows a "hanya oleh super admin" description instead.
5. Under [[Tanpa antrian persiapan]] (`bypassKds` mode on), the `viewKds` row is dropped from the grouped list entirely (ADR-0115) — the toggle still writes the role's *stored* set if it was already granted, it is only hidden from the sheet.

**Under the hood**
- Server: `GET/POST/PATCH/DELETE /staff` and `GET/POST/PATCH/DELETE /roles`, both in `lib/server/routes/reference_routes.dart`. Writes require `Capability.manageStaff`. PIN must match `^\d{6}$`; a collision (including a *disabled* staffer's own PIN — "their PIN is still theirs") returns `409 pin_in_use`.
- Every mutation that could strip the venue's last active `manageStaff` holder is refused with `409 last_admin` by `_guardLastAdmin` (`reference_routes.dart:103-141`) — checked on role-capability PATCH, role delete, user role-reassign, user disable, and user delete. The client repeats the same guard locally (`_guardLastAdminAfter` in `staff_repository.dart:358-369`, `roles_repository.dart` has no local copy — server is authoritative there) for instant feedback before the round trip.
- An admin-level role (`Capability.manageStaff` in its set) is immutable from this screen in **both directions**: `_roleHasManageStaff` blocks the whole PATCH (name, colour, capabilities) and the DELETE, and blocks *creating* a new role or *granting* `manageStaff` to an existing one (`_adminRoleForbidden`, 403 `admin_role_forbidden`).
- Role edits are audited: `AuditKind.roleCreated/roleRenamed/roleColorChanged/roleCapabilityChanged/roleDeleted`; staff edits: `AuditKind.staffCreated/staffRoleChanged/staffDisabled/staffEnabled/staffPinSet/staffPinReset/staffDeleted`. Disabling a user also revokes every live session/bearer for them (`auth.revokeAllFor`) so a disabled account can't keep ordering on a stale token.
- `id == 'admin'` is refused at `DELETE /staff/<id>` regardless of any other guard — it would strand the email+password sign-in path.

**Offline behaviour** Same as menu admin — plain HTTP with optimistic local state and revert-on-failure; not part of the offline send queue or settlement journal. Unreachable from a client device with no host.

**ADRs** ADR-0017 (admin is Firebase-only; local roles can never carry `manageStaff`), ADR-0077 (one admin, one device; the admin role is locked read-only), ADR-0087 (permissions edited one role at a time, in a sheet, replacing the old grid — this is the file's current shape), ADR-0097 (a shift is a session, ends on sign-out — relevant background for why `shiftStartedAt` on `AppUser` is `'—'` client-side placeholder text and the real clock lives server-side).

**Gotchas** `Capability.manageRoles` is defined in the enum and has an ARB label/description, but **no server route currently checks it** — role CRUD is gated by `manageStaff` everywhere in `reference_routes.dart`. Its only live consumer is a client-side legacy-role heuristic (`_roleFromCapabilities` in `auth_repository.dart:32-35`, which treats holding `manageRoles` as one of three ways to bucket a user into the legacy `UserRole.admin`). Granting a custom role `manageRoles` today grants it nothing extra server-side.

## Venue settings (ID · EN: [[Pengaturan Venue]])

**What** Venue identity, receipt branding, tax/service configuration, business-day rollover hour, and the membership ([[Keanggotaan]]) program switches. The one place discount presets are *linked* from (editing itself lives on `/venue/diskon`).

**Who** `Capability.editSettings` (`_capabilityFor`, `app_router.dart:69`).

**Where** `lib/ui/features/admin/venue_settings_screen.dart` (~1700 lines).

**How to use**
1. Tablet: `AdminPage` with a hero card (name/legal name/address), then two columns — **Profil & alamat** + **Branding struk** with a live receipt preview beside them — then full-width **Pajak & layanan**, **Keanggotaan**, **Laporan & shift** cards. Phone: a list of rows, each pushing a detail page for that section.
2. **Profil & alamat**: display name and address are read-only ("Dikelola pengelola" — cloud-mirrored, ADR-0018); legal name and phone are locally editable text fields, committed on blur (`_bindFocusCommit` — commits when the focus node loses focus, not on every keystroke).
3. **Branding struk** (ADR-0033): logo (pick from gallery, auto-downscaled to ≤1024px and re-encoded JPEG q=85 client-side before upload; delete clears it), tagline, header, social line, footer (multiline), thank-you line, footer QR URL + caption. A live `ReceiptPreview` widget renders these as a mock struk beside the form.
4. **Pajak & layanan**: **Aktifkan pajak** toggle + a bps stepper (0–5000 bps, step 25 = 0.25%) when on; **Aktifkan layanan** toggle + a percent/fixed mode switcher and matching stepper (percent: 0–5000 bps step 50; fixed: Rp0–1,000,000 step 1,000); **Pajak dihitung setelah diskon** toggle (ADR-0038 — changes future totals only, settled bills stay snapshotted); a link row to **Preset diskon** (`/venue/diskon`).
5. **Keanggotaan** (ADR-0091, only meaningfully expands once its own top switch is on): master **Aktifkan keanggotaan** toggle; then, if on — **Poin** toggle + earn-rate (per Rp1,000, 1–100), point value (Rp100–100,000 step 100), minimum redeem (1–100,000 step 5); **Stempel** toggle + a punch-item dropdown (menu items) + a punch target stepper (2–100); **[[Piutang]] (tab)** toggle + a debt limit stepper that **starts at 0** (deliberately, "switching tabs on grants nobody one until an owner names a number") and an overdue-days stepper (1–365); a discount-preset dropdown naming the member discount (bill-scope presets only).
6. **Laporan & shift**: a business-day-start-hour stepper (0–23, `businessDayStartHour`) — the anchor every report, shift, and rollover in the app uses.

**Under the hood**
- `GET/PATCH /venue/settings` in `lib/server/routes/venue_settings_routes.dart`. `GET` is open; `PATCH` requires `Capability.editSettings`. The route is a giant field-by-field PATCH-merge (`body.containsKey(k) ? Value(...) : Value.absent()`), so a partial body only touches the fields it names.
- Server-side clamping is defensive, not merely cosmetic: every threshold/rate field is clamped to a range in the route itself (e.g. `taxRateBps` isn't clamped but `prepTargetMins` is `clamp(1,120)`, `memberDebtLimit` is `clamp(0, 1_000_000_000)`, etc.) — "off" is always the explicit boolean flag, never a degenerate zero threshold.
- `[[Modul]]`/`[[Kedai]]` mode fields (`modules`, `counterConfig`) are also patchable through this same route, but by design **only the host's own cloud-doc mirror writes them** — "no screen offers it, and a venue cannot buy itself a module by PATCHing one in." See [Module system](#module--mode--switch-system).
- Logo: `GET/PUT/DELETE /venue/logo`, bytes never in the settings JSON — only `logoRev` (bumped on write) rides the snapshot, matching the menu-photo pattern (ADR-0014/0033).
- Flipping `guestOrderingEnabled` is specifically audited (`AuditKind.guestOrderingEnabled`/`guestOrderingDisabled`) because it changes what the venue exposes to the street, unlike every other settings field.

**Offline behaviour** Plain HTTP, no offline queue. All fields commit on blur/change with optimistic local echo (`ref.listen<VenueSettingsDto>` resyncs controllers from server state, `_syncFromState`, unless the field currently has focus).

**ADRs** ADR-0018 (cloud mirror owns name/address, read-only here), ADR-0033 (receipt branding block), ADR-0037 (discount presets are authored only here/`/venue/diskon`, cashiers never type a rate), ADR-0038 (tax-after-discount toggle, future-only), ADR-0091 (membership on by default for new venues since Aug 2026; the two sub-programs — points, stempel — toggle independently), ADR-0095 (points balance is `SUM(delta)`, never stored, never negative, never expires — switching points off freezes rather than clears the ledger), ADR-0098 (`[[Piutang]]`/debt limit defaults to 0 on purpose), ADR-0107/0109 (module/mode fields on this same DTO, cloud-write-only).

**Gotchas** `businessDayStartHour` here is the *one* anchor for reports, shift rollover (`lib/server/shift.dart`), and the sample-seed's fabricated history — changing it retroactively shifts which bucket every future read falls into, never past ones (each business day is computed at read time from `at`, not stored per-row). The membership card's "Aktifkan keanggotaan" toggle and `moduleMembers` are two different gates ANDed together server-side — turning this switch on does nothing on a venue that doesn't hold the `members` module (its hub tile stays locked).

## Discount presets (ID · EN: [[Preset diskon]])

**What** The owner-authored catalogue of discounts a cashier may apply — cashiers pick from this list and can never type an arbitrary rate (ADR-0037). This is the **only** place discount values are authored.

**Who** `Capability.editSettings` (`_capabilityFor`, `app_router.dart:108`).

**Where** `lib/ui/features/admin/discount_presets_screen.dart`. Reached via a link row on Venue Settings' Pajak & layanan card (`context.push('/venue/diskon')`).

**How to use**
1. Presets are grouped by **scope**: "Per pesanan" (order-scope) and "Per item" (line-scope) sections.
2. Each tile shows name, value (`X%` or `Rp X`), and an "Nonaktif" tag if `active` is false. Tap to edit, or tap the trash icon to delete (confirm dialog).
3. **+ Preset baru** (FAB) or tapping a tile opens a bottom sheet: name, scope segmented button (order/line), kind segmented button (percent/fixed), value field, and an **Aktif** toggle (parks a seasonal promo without deleting it).
4. Validation: name required, value > 0, percent capped at 100% (10000 bps) — surfaced inline as `error`, never a silent clamp, "so the owner sees their typo."

**Under the hood**
- `lib/server/routes/discount_preset_routes.dart`. `GET /venue/discount-presets` is open (every paired device caches the list); `POST/PATCH/DELETE` need `editSettings`.
- **Hard delete**, not archive — safe because every *applied* discount snapshots its own name/kind/value at apply time (ADR-0037/0039), so deleting a preset can never corrupt settled history; the dangling `presetId` on old rows is expected and labels from the snapshot on read.
- Every mutation broadcasts `discountPresetsUpdated` over WS so every paired till re-syncs its picker without polling.

**Offline behaviour** Plain HTTP, no offline queue — a cashier on a disconnected till keeps whatever preset list it last cached, but cannot receive new presets until reconnected. (Applying an already-cached preset offline is a settlement-journal concern, out of this document's scope — see ADR-0123.)

**ADRs** ADR-0037 (the whole feature), ADR-0038 (stacking order with tax), ADR-0094 (a bill discount has a `source` — `manual`/`member`/`redeem` — one slot each; this screen only authors the catalogue, not which source a given application uses), ADR-0118 (member discount pointer lives on Venue Settings' Keanggotaan card, naming a preset from this same catalogue).

**Gotchas** `idx_discounts_bill_source_uniq` (mentioned in CONTEXT/ADR-0094) means a bill can carry a manual discount, the member tier discount, and a redemption simultaneously, each from a different preset — this screen has no visibility into which bills used which preset; that's a Reports concern.

## Zone & table administration (ID · EN: [[Zona]])

**What** CRUD for zones (named floor sections with a colour/icon) and the tables within them (name, capacity, active flag), plus manual table reordering within a zone.

**Who** `Capability.editSettings` (`_capabilityFor`, `app_router.dart:132`). The screen also separately reads `UserRole.admin` (`canManage`) to decide whether zone-management controls render at all versus a locked pill — the route capability already fully gates entry, so this is a belt-and-braces display check.

**Where** `lib/ui/features/admin/zone_admin_screen.dart` (~1200 lines).

**How to use**
1. A horizontal zone chip bar (`_ZoneBar`) selects the active zone; each chip shows the zone's table count. **+ Meja** adds a table to the selected zone.
2. The table list for the selected zone is a `ReorderableListView` — drag the handle to reorder within the zone; inactive tables show a red "Nonaktif" pill.
3. Tapping **Kelola zona** (or the zone-pill when locked) opens `_ZonesEditor`: a reorderable list of every zone with edit/delete per row (delete blocked with a snackbar while any table still references it).
4. Zone editor (`_ZoneEditor`): name, a live preview chip, a colour swatch grid (`zoneColorPresets`), an icon grid (`zoneIconPresets`); delete is refused (with a "pindahkan meja dulu" message) while table count > 0.
5. Table editor (`_TableEditor`): name (auto-generated `T{n}` if left blank), capacity stepper (1–20), zone picker (chips), and — for an existing table only — an active/inactive toggle.

**Under the hood**
- Zones: `GET/POST/PATCH/DELETE /zones` in `lib/server/routes/reference_routes.dart:291-383` — writes need `editSettings`; delete blocked (`409 zone_in_use`) while any table references the zone. Every write broadcasts `zoneCreated/zoneUpdated/zoneDeleted`.
- Tables: writes go through `tables_routes.dart` (not read in this pass) via `tablesRepositoryProvider` (`addTable`/`configureTable`/`removeTable`/`reorderTable`).

**Offline behaviour** Plain HTTP; no offline queue for zone/table administration.

**ADRs** No zone/table-specific ADR was found beyond general settings-route conventions; see CONTEXT.md `[[Zona]]`/`[[Meja]]` entries for canonical vocabulary.

**Gotchas** `zi`/sort order for zones is server-assigned append-only on create (`maxOrder + 1`); the client-side reorder (`ReorderableListView`) is what actually rewrites `sortOrder` for every zone, so a drag with many zones is one PATCH-per-position, not a single reorder call (unlike menu categories/tags which have dedicated `/reorder` endpoints).

## Alerts configuration (ID · EN: [[Peringatan]])

**What** Every timing threshold and sound choice that decides whether the floor beeps, grouped by **scope** — venue-wide thresholds, venue-wide sound choices, and this-device-only mutes — because scope is what gets misread ("I muted it, why does the waiter still hear it").

**Who** `Capability.editSettings` (`_capabilityFor`, `app_router.dart:79`); the device-mute card writes only to local `SharedPreferences`, no capability needed.

**Where** `lib/ui/features/admin/alerts_screen.dart`.

**How to use**
1. Tablet: two cards side by side (**Ambang waktu** + **Suara**), then a full-width **Senyapkan di alat ini** card below. Phone: stacked.
2. **Ambang waktu** (`_ThresholdCard`): a stepper row per threshold — prep target (5–60min, hidden entirely if `bypassKds` mode is on), pickup target (1–30min, with its own on/off switch), ungreeted / ungreeted-escalate (1–30min, ungreeted has its own switch), long-stay (15–240min), idle-table (5–120min), reservation grace (0–240min). Each row's stepper stays live even when its switch is off — "off" silences the *sound* only, the number keeps driving the floor card's state and the report SLA.
3. **Suara** (`_SoundCard`): one row per audible event (Pesanan baru, Siap, Batal, Terlambat, Belum disapa, Pickup, Guest pending — the last omitted, along with the three [[KDS]]-only cues, when `bypassKds` is on), each opening a picker sheet of `alertSoundPresets` with an inline preview-play button.
4. **Senyapkan di alat ini** (`_DeviceMuteCard`): per-event mute toggles, filtered to only the events *this device's role* can actually receive — kitchen (Server mode) sees `newOrder/overdue/voided`; waiter (Client mode) sees `orderReady/voided/ungreeted/pickup/guestPending`.

**Under the hood**
- Thresholds and sounds patch through `PATCH /venue/settings` (same route as Venue Settings) via `venueSettingsProvider.notifier.patch(...)`.
- Device mutes never touch the server — `prefsServiceProvider`'s `setAlertMuted(event, muted)` writes local `SharedPreferences` only, read by `mutedAlertsProvider`.
- `alertEventLabel()` (line 70) is the **single** place an `AlertEvent` gets a human name — it used to be duplicated between the sound card and the mute card, which is exactly the kind of duplication ADR-0083 flags as a localisation hazard.
- `_kdsCues` (`newOrder`/`overdue`/`orderReady`) and the prep-target row are hidden together under `bypassKds` (ADR-0115) because "none of them can fire" without a prep queue — hidden, not disabled, and the stored value survives if the mode is turned back off.

**Offline behaviour** Threshold/sound edits require a live host (plain HTTP PATCH); the mute list is purely local and works fully offline.

**ADRs** ADR-0043/0044 (per-item ready target, table-state alert channel + per-event mute — the architecture this screen exposes), ADR-0115 (bypassKds hides the prep-queue cues and threshold row).

**Gotchas** The alert-sound picker used to be a device-wide "Alert audio on/off" switch on the System screen; that was deliberately removed — "it silently overrode the per-event mute list two screens away." All audio config now lives on this one screen only.

## Venue day open/close (ID · EN: [[Buka kedai]] / [[Tutup kedai]])

**What** A guided ritual, not a data entity (ADR-0111): opening the shop posts a petty-cash top-up and an audit row; closing posts a cash count and an audit row. There is no `venue_days` table and no persisted "is the shop open" flag anywhere — "buka"/"tutup" are just two audit rows.

**Who** Two authorities: `Capability.openDrawer` renders/opens the **Buka kedai** card, `Capability.closeShift` renders/opens the **Tutup kedai** card — either capability opens the route itself (`_capabilityFor` returns both; `app_router.dart:76-78`, matched *before* the bare `/venue` prefix arm since `/venue-day` would otherwise be swallowed by the `manageStaff`-only `/venue` arm).

**Where** `lib/ui/features/admin/venue_day_screen.dart`.

**How to use**
1. **Buka kedai** card (shown only if the signer holds `openDrawer`): enter a float amount (`SatField.money`, helper text shows the current ledger balance) and tap **Buka kedai** — this posts a `Kas kecil` top-up (if amount > 0) *then* the open audit mark, in that order deliberately, "so a failing top-up leaves no audit row claiming the shop opened."
2. **Tutup kedai** card (shown only if the signer holds `closeShift`): enter the counted cash; a live variance line appears the moment the field is non-empty (`counted − ledger balance`, green "Sesuai" if zero, amber otherwise) — shown *before* the button, "so a counter about to record a 40k shortfall sees the number while the notes are still in their hand." Optional note field. **Baca laporan** jumps to `/reports`; **Tutup kedai** posts the count *then* the close audit mark.
3. Neither action blocks on open bills, unfired courses, or live tickets — "a cafe with one unpaid tab still has to go home," and the screen may show what's outstanding but never refuses.

**Under the hood**
- `POST /venue/day/open` → `Capability.openDrawer` → `AuditKind.venueOpened`; `POST /venue/day/close` → `Capability.closeShift` → `AuditKind.venueClosed`. Both in `lib/server/routes/venue_day_routes.dart`, sharing one `mark()` handler parameterised by capability + kind (`venue_day_routes.dart:54-81`) so the two ends can never silently diverge.
- The route itself calls **no** cash/audit writer beyond `writeAudit` — the screen sequences the existing `/cash/topup` and `/cash/count` calls (via `cashProvider`) itself, keeping every ledger guard inside the one transaction that can hold it (ADR-0100).
- `note` is free text, optional, attached as the audit row's `reason`.

**Offline behaviour** Both cash and audit calls are plain HTTP with no offline queue for this screen specifically — the venue-day ritual is not part of `SendIntentKind` or the settlement journal. (The `Kas kecil` top-up/count it sequences is likewise a direct write, not journaled.)

**ADRs** ADR-0111 (the whole feature — no entity, two audit rows, closing records but never enforces), ADR-0100 (ledger guards only hold inside a transaction — this screen deliberately owns none itself), ADR-0089 (the box is not revenue — same rule the Kas hub tile follows).

**Gotchas** The two reserved capabilities `openDrawer`/`closeShift` existed in `seed_data.dart` and were checked by *nothing* before ADR-0111 wired this screen — they now name and gate exactly this act and nothing else (`openDrawer` is not "open the cash drawer mid-shift", it is specifically this morning ritual, despite the name reading like a till-drawer action).

## System / Sistem (ID · EN: [[Sistem]])

**What** Live server/network diagnostics: connectivity ping, WS state, uptime, TLS cert expiry/fingerprint, printers + KDS stations, paired devices (with revoke), and operational actions (restart server, jump to the sample-data dialog).

**Who** `Capability.manageStaff` (`_capabilityFor`, `app_router.dart:133-138`, same arm as `/staff` and `/venue`).

**Where** `lib/ui/features/admin/system_screen.dart` (~1050 lines).

**How to use**
1. Tablet: a hero card (`_SystemHero`, ping + WS + session/paired counts, six-segment health meter) plus three stat tiles (KDS online, Tablet paired, Antrean/queue depth), then four cards: **Server (LAN)**, **Printer & KDS**, **Perangkat**, **Operasional**.
2. **Server (LAN)**: address (`host:port`), uptime, TLS cert expiry (relative + ISO date), LAN ping (p50/latest), p95 latency + recent request count, TLS fingerprint (12-char prefix, **Salin** button copies the full value).
3. **Printer & KDS**: lists every configured printer (host:port, kind, online/offline pill from `lastSeenAt < 5min`, per-row **Tes** button) and every live KDS station (name, staff-online/pending-tickets count, busy/quiet pill). **Cari** triggers `printerDiscoveryServiceProvider.discover()` (a spinner dialog, then a picker of discovered devices to add); **+ Printer** opens a manual add sheet (label, host, port, kind ESC/POS or KDS).
4. **Perangkat**: every paired device, last-session relative time, an active/idle/revoked pill, and a **Cabut** (revoke) button per non-revoked row (confirm dialog).
5. **Operasional**: **Restart server** button (asks for a PIN re-entry via `_RestartPinDialog` before calling, then waits for WS to reconnect and refreshes status/KDS/queue providers) — the button itself is additionally gated by a client-side `auth.has(Capability.manageStaff)` check with a snackbar fallback, even though the route already requires it; and a **Muat/Hapus contoh data** button that opens the same seed dialog as the hub's first-run prompt — "the permanent way back in after the first-run prompt was skipped."
6. Phone: four tappable rows (Server, Printer & KDS, Perangkat, Operasional), each pushing a full-screen detail (`_SystemPhoneDetail`) reusing the same card builders.

**Under the hood**
- `GET /server/status` (open to any authenticated user), `POST /server/restart` (`Capability.manageStaff`, `lib/server/routes/server_routes.dart:83-110` — broadcasts `serverRestarting` before the response returns, since the process tears down right after).
- `GET /devices` (open read, joined with each device's most recent session), `POST /devices/<id>/revoke` (`manageStaff`, `lib/server/routes/devices_routes.dart` — flips `revoked=true` and deletes every session row for that device, invalidating its bearer immediately).
- Printers: `GET /printers` open; `POST /printers` and `POST /printers/<id>/test` need only a valid bearer (`_requireAuth` — "any authenticated staff may do", ADR-0020); `PATCH/DELETE /printers/<id>` need `editSettings` (`lib/server/routes/printers_routes.dart`).
- KDS stations / queue depth are read via `kdsStationsProvider`/`queueDepthProvider` (not read in this pass — likely `kds_routes.dart`).
- The seed dialog reused here is the exact same `showSeedDataDialog` widget as the hub's first-run prompt (see below).

**Offline behaviour** Every action here requires a live host connection by nature (server diagnostics, restart, device/printer CRUD) — none of it is offline-capable or queued.

**ADRs** ADR-0020 (printer add/test needs only auth, not a specific capability — "any authenticated staff may do"), ADR-0073 (the seed dialog and the permanent Operasional way back into it).

**Gotchas** The restart flow has **two** independent gates stacked: the client checks `auth.has(Capability.manageStaff)` before even showing the PIN dialog (early snackbar bail-out), and the server independently re-checks the capability on `POST /server/restart` — so a stale client-side auth cache cannot bypass the real gate, it can only produce a redundant-looking 403 the client already tried to prevent.

## Seeding & clearing sample data (generic seed)

**What** A one-time (per venue) offer to load a full demonstration restaurant: 4 zones / 20 tables / the generic menu (~42 items across categories) / inventory (bahan + resep with opening stock) / 4 staff (2 waiters, 2 kitchen) — the **reference half** — plus, in the same job, a **fabricated month** (30 business days, `historyDays = 30` in `lib/server/db/seed_history.dart:49`) of settled bills and their audit trail, written through the *production* order path (`submitOrder`, backdated via its `at`/`idPrefix` overrides).

**Who** Gated by `Capability.manageStaff` on every route (`GET /seed/state`, `POST /seed/generic`, `POST /seed/clear`, `POST /seed/skip`) in `lib/server/routes/reference_routes.dart:987-1095`.

**Where** UI: `lib/ui/features/admin/widgets/seed_data_dialog.dart` (`showSeedDataDialog`, reused by both the hub's mandatory first-run prompt and the System screen's permanent re-entry point). Server: `lib/server/db/seed.dart` (`seedInfra`, `seedGenericRestaurant`, `needsGenericSeed`), `lib/server/db/seed_data.dart` (`DummyData` — the static reference content), `lib/server/db/seed_history.dart` (`seedSampleVenue`, `canSeedSample`, `hasSampleData`, `clearSampleData`, `historyDays`), `lib/server/seed_job.dart` (`SeedJob` — progress/state persistence).

**How to use**
1. On a never-prompted venue, the dialog appears **non-dismissible** the moment `/venue` mounts (no X, no tap-outside, no back button — `PopScope(canPop: false)`) — the admin must answer once.
2. **Muat contoh data**: starts the job (`POST /seed/generic`, returns `202` immediately; the actual month of history runs in the background over minutes, reporting progress via the `seed.progress` WS event and a linear progress bar with a `daysDone/daysTotal` caption).
3. **Lewati**: declines — recorded server-side (`promptAnswered = true`) so the prompt never fires again; **Admin → Sistem → Operasional** is the deliberate permanent way back in.
4. If a prior job crashed or was interrupted (app backgrounded mid-run — there is no resume), the dialog instead offers **Hapus & coba lagi**, unless the venue has since genuinely traded (`!canSeed`), in which case it explains why rather than offering a button that would 409.
5. Once loaded, re-opening the dialog (from System) offers **Hapus contoh data** — deletes every fabricated (`contoh-`-tagged) transactional row while leaving the menu/zones/staff standing, "so the venue can keep customizing on top of a familiar shape."

**Under the hood**
- `seedInfra(db)` runs on **every** server boot regardless: it ensures the admin role exists with `Capability.values` reconciled fresh each boot (`_ensureAdminRole`, `seed.dart:363-386` — "the admin role *is* all capabilities by definition... a stored snapshot is the one set nobody can repair"), plus a one-off `_ensureWaiterCanVoid` backfill. It never seeds zones/tables/menu/staff.
- `needsGenericSeed(db)` (`seed.dart:36-46`) — a venue is "set up" once it has any zone, any menu item, or any non-admin user; infra rows (the admin role, any Firebase-provisioned admin user) don't count.
- `seedGenericRestaurant(db)` (`seed.dart:59` onward) writes the reference half only, idempotently (`insertOnConflictUpdate`), and mints **no PIN admin** — admin stays Firebase-only.
- `seedSampleVenue` (in `seed_history.dart`) calls `seedGenericRestaurant` first, then fabricates the month on top, reporting via `onDay(done, total)`. It self-guards on `canSeedSample(db)` — refuses outright (`409 seedRefused`) on a venue that has already traded, "since the clear deletes by `contoh-` tag only and can never reach real rows."
- `SeedJob` (`lib/server/seed_job.dart`) is the persistence layer for progress/failure/prompt-answered state — it survives a crashed process because the client re-reads `/seed/state` on next launch rather than trusting only the live WS broadcast. `clear()` is a state **update**, not a row delete: dropping the row would silently un-answer `promptAnswered`, re-arming the mandatory prompt on a venue whose admin already decided.
- `clearSampleData` deletes only `contoh-`-tagged transactional rows (bills, tickets, audit rows written by the seed) — the menu, zones, and staff created by `seedGenericRestaurant` are left standing, because they may have been customised since.

**Offline behaviour** Every seed route requires a live host; there is no offline path, and the job itself only runs server-side (in-process, backgrounded via `unawaited(Future(...))`).

**ADRs** ADR-0042 (the generic seed also covers inventory and recipes — bahan + resep with opening stock), ADR-0052/0053 (predecessors — demo seed / demo clock — both superseded; the *live* demo clock is gone, a seeded venue now runs on real time with backdated writes via `at`/`idPrefix`), ADR-0073 (**the** ADR for this feature — one seed not two, the mandatory blocking prompt, the interrupted/failed recovery states, the permanent Operasional escape hatch).

**Gotchas** "One seed, not two" is a hard invariant (ADR-0073) — there is exactly one path (`seedGenericRestaurant` → `seedSampleVenue`), not a separate "just the reference data" vs "reference + history" choice in the UI; loading sample data always means the full month. A new seeded menu item needs a matching resep + bahan + a weight in `seed_history_mix.dart` or the seed's own order-submission path will reject its lines for want of stock.

## Full capability table

Every `Capability` value (`lib/domain/models/capability.dart`), its `CapabilityGroup`, the Indonesian label (`app_id.arb`), and what it actually gates — client route and/or server route. **Never rename a value** — the name is persisted in `roles.capabilities_json` and is the ARB join key.

| Capability | Group | Label (ID) | What it gates |
|---|---|---|---|
| `takeOrder` | orders | Ambil pesanan | Router: `/table/*`, `/orders`, `/order/*`, `/counter`, `/takeaway/*`, and (as one of two authorities) `/selforder`. Server: `submitOrder`/`seat`. |
| `modifyOrder` | orders | Ubah pesanan | Change qty/note on an unmoved order line. Server-side per-route in tickets/order flow (not re-read in this pass). |
| `voidItem` | orders | Batalkan item | `POST /tickets/<id>/transition → voided`. Offline-capable via `SendIntentKind.voidTicket` (the one ticket transition with an offline path, ADR-0114). |
| `compItem` | orders | Gratiskan item | Zero the price of an already-served item (`served → voided` in the transition graph). |
| `sellOpenItem` | orders | Jual item bebas | Sell an [[Item bebas]] — a typed line with no menu row. Deliberately not on the waiter role — "a line nobody priced is a hole in the menu report." |
| `viewKds` | kitchen | Lihat KDS | `/kitchen` route. Hidden (not revoked) from the Staff screen's capability grid under `bypassKds` mode (ADR-0115); the KDS rail slot itself also hides then, with two survivals (live prep queue, `viewKds`-only sign-in). |
| `openDrawer` | money | Buka laci | One of two authorities for `/venue-day` (route + the "Buka kedai" half). Server: `POST /venue/day/open`. |
| `applyDiscount` | money | Beri diskon | Apply a discount at the till (cashier flow, not read in this pass). |
| `settleBill` | money | Tutup tagihan | `/kasir` route. Also the capability member-enrol/attach/redeem ride, per CONTEXT.md — a cashier acts on members at the till without `manageMembers`. |
| `refund` | money | Refund | Refund an already-paid bill (cashier flow). |
| `closeShift` | money | Tutup shift | One of two authorities for `/venue-day` (the "Tutup kedai" half). Server: `POST /venue/day/close`. |
| `manageCash` | money | Kelola kas kecil | One of two authorities for `/kas` (posting an expense). Funding/counting the box needs `editSettings` instead — "a supervisor spends from the box, the owner fills and verifies it." Deliberately not `openDrawer`. |
| `editMenu` | inventory | Ubah menu | `/menuadm` route. Server: every `POST/PATCH/DELETE /menu/items`, `/menu/categories`, `/menu/tags`, plus item photo PUT/DELETE. |
| `markSoldOut` | inventory | Tandai habis | `POST /menu/items/<id>/availability` — the availability-only long-press a staff-permission user gets on the menu admin screen. |
| `adjustStock` | inventory | Sesuaikan stok | Opname, receive, waste (stock flow, `/stock` — not read in this pass). |
| `manageIngredients` | inventory | Kelola bahan | One of two authorities for `/opname`. Gates the "Buang" (waste) action inside the menu item editor's recipe section. |
| `overrideStock` | inventory | Jual saat stok habis | Submit an order despite ingredient stock reading empty. |
| `manageMembers` | admin | Kelola pelanggan | `/members` route; one of two authorities for `/member-report`. Deliberately *not* what a cashier needs for enrol/attach/redeem (those ride `settleBill`). |
| `manageStaff` | admin | Kelola staf | `/staff`, `/system`, `/venue` (hub) routes. Server: every staff/role CRUD write, `POST /server/restart`, `POST /devices/<id>/revoke`, every `/seed/*` route. The reconciled-on-boot admin role always holds it — see [Seeding](#seeding--clearing-sample-data-generic-seed). |
| `manageRoles` | admin | Kelola peran | **Reserved / unused server-side** — no route in `reference_routes.dart` checks it (role CRUD is gated by `manageStaff`). Only live use: a client-side legacy-role bucketing heuristic in `auth_repository.dart`. |
| `viewReports` | admin | Lihat laporan | `/reports` route; one of two authorities for `/audit`, `/member-report`, `/opname`. |
| `editSettings` | admin | Ubah pengaturan | `/venue-settings`, `/alerts`, `/zone-admin`, `/venue/diskon`, `/selforder-admin` routes; one of two authorities for `/kas`, `/selforder`. Server: `PATCH /venue/settings`, `PUT/DELETE /venue/logo`, `/venue/discount-presets` writes, `/zones` writes, `PATCH/DELETE /printers/<id>`. |

## Module / mode / switch system

Vocabulary lives in `lib/domain/models/venue_module.dart`; the server-side reader is `lib/server/modules.dart` (already quoted in full below); the client mirror is `VenueSettingsModules` on `VenueSettingsDto` (`lib/data/models/venue_settings_dto.dart`), read via `settings.hasModule(key)` / `settings.counterOn(key)` / equivalents.

**The three functions, verbatim (`lib/server/modules.dart`):**

```dart
bool venueHasModule(VenueSetting? s, String key) =>
    s?.modules == null || splitModules(s!.modules).contains(key);

bool venueHasMode(VenueSetting? s, String key) =>
    splitModules(s?.modules).contains(key);

bool counterSwitchOn(VenueSetting? s, String key) =>
    venueHasMode(s, modeCounterService) &&
    splitModules(s?.counterConfig).contains(key);
```

- **`venueHasModule` fails OPEN**: `s?.modules == null` (never mirrored, or no settings row yet) reads as **entitled**. This protects a paying venue from losing a feature to a cold boot or a schema migration; the real cutoff is the subscription lapsing, never a feature going dark on its own.
- **`venueHasMode` fails CLOSED**: an unknown/null/unmirrored mode key reads as **off**. Applied to a mode, fail-open would boot every not-yet-mirrored *restaurant* as a counter shop with its floor hidden — the opposite of the intended safety.
- **`counterSwitchOn` ANDs** the mode key with the per-switch CSV — a switch means nothing without the mode being held first, "or a half-mirrored venue gets half a shape."
- Both `modules` and `counterConfig` are comma-joined strings at rest (`splitModules`/`joinModules`), sorted before joining so a mirror's diff-guard never sees a reorder as a real change.

**Sellable modules** (`venueModuleKeys`) — fail-open, entitlement, cloud-owned:

| Key | Constant | Gates |
|---|---|---|
| `members` | `moduleMembers` | Venue hub `/members`, `/member-report` tiles (locked padlock if absent); server-side ANDed with `membersEnabled` per feature. |
| `selfOrder` | `moduleSelfOrder` | Venue hub `/selforder-admin` tile; the guest-ordering plane's existence. |

**Mode keys** (`venueModeKeys`) — fail-closed, config/shape, cloud-owned:

| Key | Constant | Gates |
|---|---|---|
| `counterService` | `modeCounterService` | [[Kedai]] (counter) mode — the preset the six `counterConfig` switches below live under. Read via `venueHasMode`, never `venueHasModule`. |
| `bypassKds` | `modeBypassKds` | [[Tanpa antrian persiapan]] — the **one** mode key that branches a writer (`submitOrder` stamps lines `ready` at send instead of `sent`). Hides the KDS rail slot, prep metrics, `prepTargetMins`, the three prep-queue alert cues, and the `viewKds` capability row in the Staff sheet — nothing is revoked, only hidden, with two survivals (a live prep queue drains rather than strands mid-flip; a `viewKds`-only signed-in user keeps their tab). |
| `memberSplit` | `modeMemberSplit` | [[Pemilik struk]] — whether a split-bill receipt may name a member for its own share. Branches **no writer**, only what's offered/read/reported; ANDed once with `moduleMembers` + `membersEnabled` in `MemberConfig.splitEnabled` server-side, `memberSplitOn` client-side. |

**Counter-mode switches** (`counterSwitchKeys`, in `venues/{vid}.counterConfig`, mirrored to `venue_settings.counter_config`) — config only, never a branch in a writer except the one documented exception at `counterGuestCode`:

| Switch | Constant | Effect |
|---|---|---|
| `menuHome` | `counterMenuHome` | Menu is the home tab; the floor is hidden (`showCounterHome` in `app_router.dart`). |
| `anonTakeaway` | `counterAnonTakeaway` | `guestName` becomes optional; the visit rides a `Bawa pulang #N` label instead. |
| `settleAfterSend` | `counterSettleAfterSend` | Committing an order opens the settle pane instead of returning to the floor. |
| `simpleKds` | `counterSimpleKds` | One KDS queue: no station split, no course-fire UI. |
| `counterQr` | `counterQr` | The venue-level [[Kode kedai]] QR. Being a socket route (`counterGuestCode` in `self_order.dart`), toggling it needs a server **restart** to take effect, like `guestOrderingEnabled`. |
| `ringkasReport` | `counterRingkasReport` | The [[Ringkas]] one-page report variant. |

**Rules that must hold** (from CLAUDE.md / ADR-0109 / ADR-0115, verified against the code read in this pass):
- A `counterConfig` switch is a *default or a layout*, **never a branch in a writer** — the sole exception is `counterQr` gating whether the [[Kode kedai]] socket route *exists* at all, mirroring how `guestOrderingEnabled` gates the whole cleartext guest plane.
- `counterService` (the mode) is a **write, never a read** in the sense that ticking it on the fleet console turns all six switches on at once and the operator unticks from there — nothing in this codebase computes "is this venue in the preset."
- Counter mode **hides, never refuses**: tables/zones/reservations/locks stay legal server-side and keep being written even with `menuHome` on, so unticking it later "finds everything where it was."
- A fleet-mirrored *switch* reaches a signed-in device on its next admin sign-in (`PrefsService.venueShape()` re-reads at `VenueSettingsRepository` construction, to survive a cold-boot-offline device that would otherwise render the wrong shape); `counterQr` and `guestOrderingEnabled`, both socket-route gates, need a server **restart** on top of that.

## Gotchas (area-wide)

- **A ticket transition carries its own capability**, not a lookup switch: `ticketTransitions` in `lib/domain/models/ticket_transitions.dart` maps `from → to → Capability`, and both client and server read that one table (ADR-0101). A move nothing writes gets no row at all.
- **Never rename a `Capability`, an `AuditKind`, a persisted enum value, a module/mode/switch key.** Every one of these is a string stored in a JSON column or a CSV cell; a rename silently orphans every existing row/venue that used the old name.
- **The admin role's capability set is reconciled every boot**, not stored once — this is the *only* mechanism that backfills a new `Capability` onto every already-seeded venue's admin. A capability a *non-admin* role needs has no backfill; it must be added to `seed_data.dart` **and** granted by hand through the Staff sheet on already-seeded venues.
- **`Capability.manageRoles` is dead weight server-side today** — defined, labelled, described, but unchecked by any route; role CRUD is `manageStaff`-gated everywhere.
- **The Venue hub's own capability (`manageStaff`) is stricter than several of its tiles' own routes** (`/kas`, `/opname`, `/member-report`, `/selforder` all accept a second, lower authority) — those authorities reach their screens by a path other than tapping through this hub.
- **Locked hub tiles are a sales surface, not a security boundary** (ADR-0107 §3) — every route behind a locked tile is independently capability-gated server-side; the lock only decides whether the *tile* is worth showing.
