# Cloud-owned venue identity, mirrored read-only into local VenueSettings

**Status:** accepted

**Amends [0016](0016-fleet-superadmin-cloud-control-plane.md):** ADR-0016 declared the cloud `venues/{vid}` doc and the local `VenueSettings` Drift row **deliberately distinct** (cloud = fleet identity, local = display). This narrows that: the venue's **name and address** are now cloud-owned and mirror down read-only.

## Context

ADR-0016 kept cloud `venues/{vid}.{name,address}` and local `VenueSettings.{displayName,address}` independent — the local admin could edit the in-app name freely, and the cloud name was only for the Fleet console. That allows the same restaurant to show one name to the super admin and a different name to its own staff/receipts, with no reconciliation. The super admin (who creates and manages venues) is the natural owner of a venue's identity.

## Decision

**The cloud venue doc is the source of truth for the venue's name and address; the local `VenueSettings` mirrors them live and read-only.**

- The app already holds a live snapshot listener on `venues/{vid}` (the kill switch, ADR-0016). That same listener now **upserts** `venue.name → VenueSettings.displayName` and `venue.address → VenueSettings.address` on every snapshot — always-on, **not** gated by the first-run seed prompt.
- Those two fields become **read-only** in the Admin → Settings UI. All other `VenueSettings` fields (receipt header/footer, tax, service charge, prep target, etc.) stay locally editable.
- Mirroring runs on the host (Main Device, ADR-0017), which holds the listener and owns the authoritative DB.

## Considered options

- **Live read-only mirror, SA owns it (chosen)** — one name everywhere; the SA edits it once in the Fleet console. Costs: contradicts the prior "distinct" stance, and requires disabling two settings fields.
- **One-time seed copy, then locally editable** (rejected) — copy cloud values as initial defaults at seed, then let the admin diverge. Minimal change and preserves local autonomy, but reintroduces the drift between fleet-console name and in-app name that motivated this.
- **Keep fully distinct (status quo, ADR-0016)** (rejected) — no reconciliation; two sources of truth for one human-meaningful fact.

## Consequences

- **Identity edits move to the Fleet console.** A venue admin can no longer rename their own venue locally; they ask the super admin (or it is set at venue creation). Acceptable given the SA owns venue lifecycle.
- **Offline:** the mirror reflects the last cached `venues/{vid}` snapshot; an SA rename made while the host is offline lands when the listener reconnects. The read-only fields show the cached value meanwhile.
- **Receipts and in-app chrome** now track the cloud name automatically — no manual local update needed after an SA rename.
- Narrows ADR-0016's "distinct" claim: cloud and local `VenueSettings` are still separate rows, but `name`/`address` now flow one-way cloud → local.
