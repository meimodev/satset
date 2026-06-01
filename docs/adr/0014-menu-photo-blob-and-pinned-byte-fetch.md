# 14. Menu photo: DB blob + pinned byte-fetch with rev cache-busting

Date: 2026-05-31

## Status

Accepted

## Context

Menu items gain an optional [[Menu photo]] (CONTEXT.md), picked from gallery or
camera, CRUD'd alongside the rest of menu management. The app is LAN-only: an
in-process shelf server (Server mode) is the source of truth; client devices
reach it only through `apiConfig` (IP + port) over **self-signed TLS that is
pinned by SHA-256 fingerprint** inside `ApiClient`'s custom `HttpClient`. There
is no `HttpOverrides.global`.

Several forks had to be resolved together:

- **Where the bytes live** — DB blob vs filesystem-on-server vs base64 embedded
  in the `/menu` snapshot.
- **Blob placement** — on the `menu_items` row vs a side table.
- **Upload transport** — dedicated binary endpoint vs multipart vs base64 in the
  item-upsert JSON.
- **Client render** — `Image.network` vs fetching bytes through the pinned client.

Constraints that drove the call: the `/menu` snapshot reads **all** items on
every menu refresh and re-broadcasts on every edit (`menuUpdated`); a 100-item
menu must stay lightweight. `Image.network` uses Flutter's default
`dart:io HttpClient`, which has none of `ApiClient`'s pinning callback and so
fails TLS against the self-signed cert on real (non-loopback) devices.

## Decision

- **Store the JPEG as a blob on the `menu_items` row** (`photo BLOB nullable`),
  plus a monotonic `photo_rev INT default 0` (0 = no photo). One table, one
  row, blob dies with the item — no orphan files, no cascade code. Migration
  adds both columns.
  - To keep the hot path lean, `_snapshot` / `_readItem` use `selectOnly` with
    explicit columns and **never select `photo`**; only `photo_rev` rides the
    snapshot. The blob is read solely by the photo route's single-row fetch.
- **Picked images are downscaled on capture** via `image_picker`
  (`maxWidth/maxHeight ≈ 1000`, `imageQuality: 80`) — no extra image/crop
  dependency. Both surfaces render the one stored JPEG with `BoxFit.cover`.
- **Dedicated binary endpoints**, photo kept out of the item-upsert JSON:
  - `PUT /menu/items/:id/photo` — raw JPEG body, writes blob, bumps `photo_rev`,
    broadcasts `menuUpdated`. Gated by `editMenu`.
  - `DELETE /menu/items/:id/photo` — clears blob, bumps `photo_rev`. Gated by
    `editMenu`.
  - `GET /menu/items/:id/photo` — streams bytes, ungated (matches open `GET
    /menu`).
- **Photo commit sequencing is split by item existence**:
  - **Existing item** — the photo applies **immediately on the action**, not on
    Save. Picking auto-fires the PUT; removing auto-fires the DELETE. The
    optimistic memory preview is reverted (and a snackbar shown) if the call
    fails; on success the pending state is cleared and the draft's `photoRev`
    refreshed from the merged server item, so the editor's explicit Save never
    re-sends the photo. The rest of the editor (name, price, tags…) stays
    staged-until-Save — so photo and form deliberately have different commit
    semantics on the same screen (accepted: the photo is a heavy binary
    side-channel with its own endpoint + `photoRev`).
  - **New item** — there is no row to attach to yet, so picked bytes (or a clear
    intent) are held in local draft state and previewed from memory; on `_save()`
    the item row is upserted **first**, then the photo PUT/DELETE fires.
    `upsertItem` is awaitable so the PUT lands against an existing row.
- **Clients fetch through the pinned client, not `Image.network`**:
  `apiClient.getBytes(path)` reuses the pinned `IOClient`; a `photoBytes`
  provider family keyed by `(itemId, photoRev)` fetches once and caches,
  autodisposing stale-rev entries. A shared `MenuPhoto` widget renders
  `Image.memory`, falling back to the initials avatar while loading or when
  `photoRev == 0`.

## Consequences

- **Good**: no static file server, no multipart parser, no `HttpOverrides`
  hack; all server IO stays on the pinned/auth path. `photo_rev` gives free,
  correct cache-busting across devices via the existing `menuUpdated` broadcast.
  Delete-cascade is automatic. Snapshot stays byte-free.
- **Cost / risk**: the blob lives on the busiest table, so any future query that
  forgets `selectOnly` will silently drag bytes into every menu read — this is a
  standing footgun the snapshot/read helpers must guard. SQLite file grows with
  the menu (bounded: ~100 items × ~100 KB ≈ 10 MB, acceptable).
- **Reversible-ish**: moving to a side table or filesystem later is a migration
  plus a swap of the photo route's read/write; the client contract
  (`photoRev` + `GET …/photo`) and the `MenuPhoto` widget are unaffected.
- The vestigial `MenuItem.photoUrl` (never serialized) is replaced by
  `int photoRev`.

## Alternatives considered

- **Filesystem on server + `photoRev`** — leaner DB, but adds a file-lifecycle
  to manage (orphans on delete, path handling) for no client-visible benefit;
  rejected for v1 simplicity.
- **Side table `menu_photos`** — keeps bytes off the hot row structurally
  instead of by query discipline; rejected to avoid a second table + join when
  `selectOnly` already solves the read cost.
- **Base64 in the `/menu` snapshot** — re-ships every photo on every menu
  refresh/broadcast; defeats the lightweight snapshot. Rejected.
- **`HttpOverrides.global` + `Image.network` + `cached_network_image`** — a
  global override that must track the per-`apiConfig` fingerprint, plus a new
  cache dep; rejected in favour of staying on the existing pinned client.
