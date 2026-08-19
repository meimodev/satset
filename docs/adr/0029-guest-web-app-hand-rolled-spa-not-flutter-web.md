# Guest web app is a hand-rolled static SPA, not Flutter web

**Status:** Superseded by [0080](0080-self-order-and-token-pairing-removed.md) — guest QR self-ordering removed. Kept for the reasoning. Re-decided by [0105](0105-guest-self-order-returns-as-an-intent-not-a-ticket.md) — the hand-rolled SPA returns.

Originally: accepted — depends on [0027](0027-cleartext-guest-plane-for-self-order.md) (guest plane)

## Context

SatSet is a Flutter/Dart codebase with rich domain models, DTOs (`menu_dto`, `order_dto`, freezed + json_serializable), and a settled three-layer architecture. The instinct for the guest web app (CONTEXT.md: *Self-order*) is to build it in **Flutter web** to reuse that Dart code.

But the guest app runs in a fundamentally different environment than the rest of the app:

- It loads in a **stranger's mobile browser**, cold, over the **LAN**, with **no CDN** and possibly **no internet at all** (the venue Wi-Fi may be intranet-only).
- The app already depends on **`google_fonts`, which fetches fonts from the network on first launch** (a documented CLAUDE.md gotcha). A Flutter-web guest app on an offline LAN would render with broken/fallback fonts and icons.
- Flutter web's initial payload is **multi-MB** (engine + framework + tree-shaken app), giving a slow first paint over LAN — exactly the friction a "skip the wait" feature must avoid.
- The reuse is shallower than it looks: the menu is already served as **plain JSON** (`/menu` snapshot), so a JS client consumes it directly. The Dart models being reused would be only the wire shapes, which are trivially mirrored in a few JS types.

## Decision

**Build the guest app as a small hand-rolled static SPA (vanilla JS or a tiny framework such as Preact/Alpine), bundled into the APK and served by `shelf_static` from the guest plane.**

- Source lives in `guest_web/`, built to a small single bundle under `assets/guest_web/`, shipped inside the APK and served as static assets — **no network fetch for fonts, icons, or framework**.
- The SPA talks **JSON** to the guest API (`/guest/menu`, `/guest/orders`, photo blobs). It mirrors only the few DTO shapes it needs.
- Target: tens-to-low-hundreds of KB, **instant** first paint over LAN, **fully offline-capable** (no internet, no CDN, no Google Fonts).
- Indonesian-default copy to match the app (Rupiah, labels).

## Considered options

- **Hand-rolled static SPA (chosen)** — smallest payload, instant LAN load, zero network dependency, self-contained in the APK. Cost: a second small frontend stack to maintain, and DTO shapes mirrored (not shared) in JS.
- **Flutter web reusing Dart models** (rejected) — the apparent code reuse is undercut by multi-MB payload, slow LAN first paint, and the `google_fonts` network dependency breaking on an offline LAN. The shared code is mostly JSON shapes the JSON endpoint already exposes.
- **Server-rendered HTML + form POST** (rejected) — works everywhere and is cheapest, but full-page reloads make cart/modifier UX clunky for a feature whose whole value is a smooth self-serve flow.

## Consequences

- The repo gains a **non-Dart frontend** (`guest_web/`) with its own small build step feeding `assets/`. Codegen (`build_runner`) does not touch it.
- Wire shapes are **mirrored**, not shared, between Dart DTOs and the JS client — a guest-facing DTO change must be reflected in both. Bounded by keeping the guest API surface tiny.
- The guest app is **decoupled** from the Flutter render/runtime — it can't reuse SatSet widgets/theme, but it also can't be slowed by the engine or broken by the font dependency.
- Photos stream from `GET /guest/menu/photo/<id>` (blobs, ADR-0014) rather than being bundled — lazy-loaded so first paint stays fast.
