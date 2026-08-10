# Phase 1 — Audit of the existing Barracks prototype

Measured against `index.html` at commit `42d590a` (2,248 lines, 116 KB, single file).
This is the input to the rebuild, not a criticism of it: the prototype's brand thinking is
sound and is being preserved. What follows is what must change structurally.

## 1. What is worth keeping

The existing build already solved real problems, and the rebuild carries these forward
rather than restarting:

- **Art direction** — olive `#4A5240` / ink `#1B1C18` on warm ivory, Cormorant Garamond +
  Jost, hairlines instead of shadows, sharp corners. Approved and now expressed as design
  tokens rather than repeated literals.
- **Voice** — "Always different. That's the standard.", "The House of Barracks",
  "Compose your pair", "The collection, entire." Migrated verbatim into the database.
- **Commerce logic** — the two-trouser bundle, free-delivery threshold, WhatsApp ordering
  with pre-filled carts, size guides, saved items.
- **Mobile navigation** — the full-screen menu and sticky buy bar are the right patterns
  and are being rebuilt as components, not discarded.

## 2. Architectural findings

| # | Finding | Evidence | Consequence |
|---|---|---|---|
| 1 | All content is hard-coded in source | 10 product objects, hero slides, store details and copy inside `<script>` | The owner cannot add a product or change a price without a developer editing HTML — the central problem the brief names (§2) |
| 2 | Promotion is a constant | `const OFFER_PRICE = 5000` (line 1727), `const FREE_SHIP = 7500` (line 1726) | Every promotion change is a code change and a redeploy; no scheduling, no second promotion |
| 3 | No routing | 0 occurrences of `pushState`; navigation swaps `.page` visibility | One URL for the entire site. Products cannot be linked, shared, or indexed — directly contradicts §58 and §59 |
| 4 | Prices in floating-point rupees | `p.price` as plain numbers, `Math.round(p/3)` for instalments | Rounding drift once discounts and tax compound; unacceptable for the money customers are charged |
| 5 | Trust in the client | Bundle discount computed in the browser and shown as the total | A browser-computed total can be tampered with; §79 requires the server to price independently |
| 6 | 80 inline `onclick` handlers | `grep -c 'onclick='` → 80 | Blocks a meaningful Content-Security-Policy and prevents event delegation |
| 7 | 20 `innerHTML` assignments | `grep -c innerHTML` → 20 | Safe today with hard-coded strings; becomes a stored-XSS sink the moment product copy comes from an admin form |
| 8 | No inventory concept | No stock model anywhere | Cannot prevent overselling, show "only 2 left", or drive back-in-stock demand |
| 9 | No order persistence | Tracking page renders a fixed timeline for any input | Nothing to fulfil against; no order history |

## 3. Accessibility findings

- **No focus styling whatsoever** — `grep -c 'focus-visible'` → 0. A keyboard user cannot
  see where they are. This is the most serious accessibility defect present and is fixed in
  the new base layer.
- ARIA is sparse (26 attributes across the whole document) and the cart drawer, mobile menu
  and search overlay do not trap or restore focus.
- Interactive `div`s with `role="link"` (product cards) instead of real anchors, so they are
  invisible to assistive technology's link navigation and cannot be opened in a new tab.

## 4. Performance findings

Genuinely good already: images lazy-load with `decoding="async"`, social embed scripts
defer until the section nears the viewport, and reduced-motion is respected.

Remaining issues are structural rather than tuning:
- A single 116 KB HTML document parses and executes before anything renders; there is no
  code splitting because there is no module system.
- Images have no `width`/`height` and no responsive `srcset`, so every photograph is a
  layout-shift and bandwidth risk on mobile (§52).
- Product photography is stock, referenced by absolute external URLs embedded throughout
  the source — exactly what §73 says to centralise.

## 5. Duplication and technical debt

- Store card markup is generated twice (home and visit pages) from one template string —
  harmless now, but the pattern repeats for product cards, tiles and badges.
- `tileHTML`, `cardHTML` and `imgTag` are string builders; every render re-parses HTML
  rather than updating the DOM.
- The `renderShop()` empty state replaces `#prodGrid` via `outerHTML`, discarding and
  recreating the node — a subtle bug source if listeners were ever attached to it.
- No tests of any kind, despite the bundle calculation being the highest-risk logic.

## 6. What the rebuild does about it

| Finding | Resolution | Status |
|---|---|---|
| 1, 2 | Full relational schema; promotions are rows with schedules | ✅ Built and verified |
| 4 | Integer minor units throughout, with a branded `Minor` type | ✅ Built and tested |
| 5 | Pure promotion engine shared by client preview and server pricing | ✅ Built, 29 tests |
| 8 | `inventory` per location with `on_hand`/`reserved` constraints | ✅ Schema built |
| 3, 6, 7 | Next.js App Router with real URLs and React rendering | ◻ Phases 8–11 |
| Accessibility | Visible focus ring and 44px touch targets in the base layer | ✅ Started |
| 9 | `orders`, `order_items`, `order_events` with price snapshots | ✅ Schema built |
