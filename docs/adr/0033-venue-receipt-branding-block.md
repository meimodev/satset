# Venue receipt branding block (logo, header, footer, QR)

Status: accepted

"Edit the receipt" is implemented as a **single, venue-wide branding block** stamped on every document — the no-money order [[Struk]], the [[Tagihan / Struk pembayaran]] money docs, and a trimmed letterhead form on the PDF exports. The block lives on the venue identity screen ("Branding struk" card) with a live preview. It extends the pre-existing `receiptHeader` / `receiptFooter` fields rather than replacing them.

The block: optional **logo** image; **venue name + address** (read-only, cloud-mirrored); editable **contact** (phone), **header**, **tagline**, **social line**, **footer**, and **thank-you**; and a **footer QR** (free-form URL + caption). See CONTEXT.md "Venue branding (receipt branding block)".

Four non-obvious choices govern it:

1. **One shared block, not per-document overrides.** Editing the receipt edits the block once; it renders on every doc. The renderers stay dumb — they read the same `VenueSettings` fields they already read; only the field set grows.

2. **Logo is a JPEG blob + monotonic `logoRev`, kept OUT of the settings JSON snapshot**, served by a side-endpoint (`GET /venue/logo`) and cache-busted by `logoRev` — identical to the menu-photo pattern (ADR-0014) and payment-proof pattern (ADR-0025). The settings broadcast that fans out over WS on every edit stays small. Thermal print converts the stored colour JPEG to a monochrome-dithered raster fit to the 384-dot (58mm) width at print time; PDF embeds it full-colour. Adds the `image` package (decode/downscale/dither).

3. **Address (and venue name) stay read-only here**, even though the feature is framed as "make the receipt editable." They remain cloud-owned and mirrored from the fleet console per ADR-0018; the branding editor shows them locked ("Dikelola pengelola"). Only the receipt-specific text and logo are locally editable.

4. **Footer QR prints on the money docs only** (Tagihan + Struk pembayaran), not the order-confirmation Struk and not the PDF exports. **PDF exports get only a letterhead subset** (logo + name + address + contact next to the report title) — never the customer-facing footer, tagline, thank-you, or QR.

## Considered options

- **One shared block vs. per-document-type header/footer** — per-type is more flexible but multiplies the data model, the editor UI, and the preview surface for a need no operator voiced. A single consistent brand is the common case. Chose shared; a per-type override can layer on later as optional fields without reshaping this.

- **Logo as blob+rev vs. base64 inline in the settings JSON** — inline is one round-trip with no side-endpoint, but it bloats every settings broadcast (logos dwarf the rest of the payload) and breaks the established "bytes never ride the snapshot" rule from ADR-0014. Chose blob+rev for consistency and a lean broadcast.

- **Address: keep read-only vs. re-open for local edit vs. add a `receiptAddress` override** — re-opening or overriding would contradict ADR-0018's cloud-as-source-of-truth invariant and need its own ADR. The receipt already prints the mirrored address; making it editable solves no real problem. Chose to keep it locked.

- **QR everywhere vs. money-docs-only** — a review/IG QR on an order-confirmation slip or an accounting PDF reads as clutter. Scoped to the documents a paying guest actually leaves with.

- **Square-cropped logo vs. free aspect** — a square crop needs an image-cropper dependency and mangles wide wordmark logos. Chose free aspect with auto-downscale; the renderer centres and fits.

## Consequences

- New `VenueSettings` Drift columns: logo blob, `logoRev`, plus text fields `receiptTagline`, `receiptSocial`, `receiptThankYou`, `receiptQrUrl`, `receiptQrCaption`. Same fields added to `VenueSettingsDto` (except the blob). Requires `tool/codegen.sh` (freezed/json + drift) and a Drift schema migration.
- The hardcoded "Terima kasih" in `bill_struk_renderer` becomes the `receiptThankYou` field (defaulting to "Terima kasih" so existing behaviour is unchanged when unset).
- Renderers touched: `bill_struk_renderer` (logo + QR + thank-you), `struk_renderer` (logo), `pdf_theme`/`pdfTitleBlock` (letterhead subset). All three read the same settings — no per-doc branching beyond which fields each consumes.
- The live preview is a **mock** Flutter widget, not real ESC/POS output; it can drift from true printer rendering (font metrics, dither). Treat it as a layout/content preview, not a pixel-exact proof.
- If true accrual-grade or per-branch addressing is ever needed on receipts, that is a new field, not a re-opening of the cloud-owned address.
