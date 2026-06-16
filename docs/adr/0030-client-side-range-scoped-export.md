# Export is client-side and range-scoped; the live order board is untouched

**Status:** accepted

## Context

Admin needs to get venue data off the tablet — the [[Reports]] aggregates and the order list — as **CSV or PDF** for accounting and owners. Two facts shape the design:

- The **Reports** screen already carries a timeline chip (`today` / `yesterday` / `7 hari` / `30 hari` / `bulan ini`), and its snapshot DTO is already in client memory.
- The **order list** (Pesanan board) is a **live operational board** — waiters watch open tickets in real time off `ticketsProvider`. It has no date filter and no historical/closed-ticket query.

Naive instinct is to render files on the shelf server (one place, server already owns the data) and to add a range chip to the order board that reloads it for the chosen window (reuse the reports pattern). Both are wrong for this app.

## Decision

**Generate exports on-device (client-side) for both surfaces, scope the order export to a range chosen *in the export sheet* without touching the live board, and hand the file off through the Android share sheet.**

- **Format:** CSV or PDF, user picks at export. PDF is styled in Flutter with `pdf`/`printing` using the existing Heritage design tokens; CSV is hand-rolled. Both shared via `share_plus`.
- **Report export** reads the timeline chip already active on the Reports screen — no second picker. PDF = full report; CSV = KPI block + key tables (staff, menu top/slow, category mix, hourly).
- **Order history export** lives on the order list but leaves the board **live**. The range is picked inside the export sheet; the board does not reload. Rows are line items for closed visits in the window, **grouped by visit**, voids included and flagged. Data comes from a dedicated read-only window query (`GET /orders/history?range=`) mirroring the reports `_windowFor` + session join.
- **Gate:** the export action is gated behind `viewReports` on **both** screens, even though the order board is otherwise open to `takeOrder` — export exposes historical financial data.

## Considered options

- **Client-side generation (chosen)** — keeps PDF styling in Flutter with the real design tokens, reuses the in-memory reports snapshot, keeps the shelf server thin (one JSON window query). Cost: three deps (`share_plus`, `pdf`, `printing`); PDF layout code lives in the client.
- **Server-renders the files** (rejected) — one code path and direct DB access, but duplicates the visual theme outside Flutter, bloats the embedded server with a rendering stack, and streams bytes the client must still hand to the share sheet anyway.
- **Range chip drives the order board** (rejected) — selecting a past range would turn the live ops board into a historical browser, forcing it to render closed/settled states and breaking the waiters' real-time mental model. Export-scoping the range keeps live ops intact.

## Consequences

- New deps: `share_plus`, `pdf`, `printing`. PDF layout is Flutter code, maintained alongside the screens it mirrors.
- One new server endpoint (`GET /orders/history?range=`, read-only, `viewReports`-gated) — the only server work; everything else is client-side.
- The order board keeps zero coupling to history: the export sheet owns the range, the board owns "now".
- A report/order DTO shape change that affects export must be reflected in the CSV/PDF builders.
