# Barracks Clothing — Website Redesign Direction

Prepared 17 July 2026 · Grounded in a live audit of the brand's web + social presence.

**Scope note on method.** The brand's store (`barracks.lk`, Shopify) and the social platforms
block direct automated browsing from this environment, so site/social findings below come from
indexed pages, bios, captions, follower counts and post metadata rather than pixel-level
inspection — exactly the fallback the brief anticipates. Where exact visuals matter (campaign
color sampling, store photography), that's listed as an open ask in §4. The pitch prototype
deployed at `barrackclothing.netlify.app` was analyzed from its full source
(`prototype/index.html` in this repo).

---

## 1 · Brand analysis summary

### 1.1 The account map (Step 0 — with three flags)

| Channel | Handle | Size / activity | Status |
|---|---|---|---|
| TikTok | [@barracksclothing](https://www.tiktok.com/@barracksclothing) | **239.2K followers · 3M likes** · posting continuously | ✅ Primary channel, verified active |
| Instagram | [@barracksclothing](https://www.instagram.com/barracksclothing/) — "Barracks Clothing lk" | **29K followers · 442 posts** · reels mirror TikTok (Track Bottom, Varsity Jacket, 3-for-5,000, Oversize Tee — all 2025) | ✅ Primary IG |
| Instagram | [@barracks.lk](https://www.instagram.com/barracks.lk/) | 3,194 followers · 259 posts · bio: island-wide delivery, orders via DM/WhatsApp/**Viber** | ⚠️ Legacy/secondary account |
| Facebook | [Barracks.lk](https://www.facebook.com/barracks.lk/) | **32,287 likes** · bio: "Sri Lanka's apparel business providing high quality dry fit material t-shirts" · +94 77 065 7669 · barrackslk@gmail.com | ✅ Primary FB |
| Facebook | "Barracks Clothing" (p/100093598287491) and [Barracks Clothing LK](https://www.facebook.com/barracksclothinglk/) | smaller | ⚠️ Duplicate pages |
| Twitter/X | *(brief supplied a LinkedIn job URL, `linkedin.com/jobs/view/4433606175`)* | — | ❌ Not a brand account; no Barracks X/Twitter presence found at all |

**Flag 1 — the brief points at the wrong Instagram.** The supplied handle `@barracks.lk` is the
*smaller, older* account (3.1K). The brand's real Instagram audience is on `@barracksclothing`
(29K), which is also the handle TikTok uses. The redesigned site must link `@barracksclothing`;
the prototype already does this correctly, the brief does not.

**Flag 2 — split naming across platforms.** Facebook's main page is `barracks.lk` (32K likes)
while TikTok/IG are `barracksclothing`. There is no single canonical handle. The Netlify
subdomain even drops an "s" (`barrackclothing`). Recommend consolidating on
**@barracksclothing** everywhere and pointing the legacy accounts' bios at it.

**Flag 3 — the bios lag the brand.** Facebook still introduces Barracks as a
"dry fit material t-shirts" business — the founding product — while the content that actually
performs in 2025–26 is chinos, linen, party shirts, baggy fits and varsity jackets. The brand
outgrew its own bio; the site copy should not inherit it.

### 1.2 Site health (Step 1)

Two "current websites" exist, and they are different things:

**`barracks.lk` — the real store (Shopify).** Live and transactional. Indexed collections:
Men Pants (slug `pants-1` — a default-Shopify duplicate-slug artifact), Tees, Dri-fit Crew Tees,
Baggy Big Fold Pants, Caps, Accessories, Underwear, and **Women's T-Shirts & Tops** — a women's
line the brief and the prototype both miss. Catalog mixes own-label product (Baggy Big Fold
Pants, Rs 3,850) with **resale items (Nike Dri-FIT Training Shorts)** — a positioning question,
see §4. Prices observed: men's pants up to Rs 5,850; women's tees discounted Rs 1,950 → Rs 850;
the **"any 2 pants for 5,000/=" bundle is live**. No brand story / about content surfaced
anywhere in the index — the store is product listings only. Generic Shopify title pattern
("Products – Barracks Clothing") and no evident custom design language.

**`barrackclothing.netlify.app` — a pitch prototype, not a live site.** This is the previously
built redesign concept (full source: `prototype/index.html`). It is honest about being a
prototype (footer: "Design prototype — sample data · Unsplash placeholder photography") but if
anyone treats it as the production site they should know: all photography is Unsplash
placeholder, all products/reviews are sample data, checkout is stubbed ("wires to Shopify in
production"), and its TikTok counter is already stale (hard-coded 227.8K vs. 239.2K actual).

**Where the real store's UX breaks down** (from structure; direct click-through pending):
no brand story, no offer landing page for the bundle that drives their TikTok traffic, women's
line buried as one collection, duplicate-slug IA (`pants-1`), and none of the brand's dominant
social content surfaced on the site.

### 1.3 What the brand actually is, across socials (Step 2)

- **Format that performs:** short vertical video — in-store try-ons, drop announcements,
  price-offer promos. TikTok is ~8× Instagram and ~7,000× the legacy IG. This is a
  **TikTok-first, store-floor brand**, not a studio-editorial one.
- **Voice:** urgent, price-forward, caps-heavy retail energy — "2 for 6,000/= Premium Stretch
  Chino Pants", "3 for 5,000/=", "IMPORTANT MESSAGE ATTENTION…" — with a fixed hashtag block
  (#colombofashion #clothingsrilanka #srilankan_tik_tok🇱🇰 #mensfashion #fyp) pasted on every
  post. Voice is consistent on TikTok/IG because IG republishes TikTok; Facebook is where the
  older, stiffer voice lives.
- **Offers are the recurring motif** — and they *rotate* (2-for-5,000, 2-for-6,000,
  3-for-5,000 all appear within months). Design consequence: the offer is a **content slot**,
  not a hard-coded string.
- **Commerce channel reality:** WhatsApp (077 065 7669) is the transaction layer; the legacy
  IG bio adds Viber. Any redesign that buries WhatsApp behind a contact page fights how the
  brand actually sells.
- **Audience (brief asked us to define it):** Sri Lankan men roughly 18–35, Colombo/suburbs
  core with island-wide delivery reach, discovering on TikTok/IG reels, price-responsive
  (bundle mechanics dominate the top-performing posts), buying via WhatsApp DM or walk-in
  (Kohuwala · Dehiwala, 10:30–20:30 daily). Secondary, growing: women's-line buyers. Discovery
  is effectively 100% mobile.
- **Unclaimed territory in the name:** "Barracks" carries military-surplus visual equity —
  olive drab, stencil type, kit/issue language ("Standard Issue" drops, "field-tested"
  product notes). Nobody in the Colombo streetwear set owns that space; the current store
  doesn't use it at all, and the prototype only gestures at it (olive tint, "Standard Issue
  SS26" hero line).

---

## 2 · Style direction

**One sentence:** *army-surplus calm as the frame, TikTok heat as the content* — a quiet
olive-and-ink retail system whose loudest element is always the current offer, mirroring how
the brand's feed actually works.

### 2.1 Palette (evidence-sourced, prototype-refined)

The prototype's system is the right starting point and survives contact with the evidence:

| Role | Hex | Source / reasoning |
|---|---|---|
| Ink (text, dark surfaces) | `#1D1D1F` | prototype; neutral chassis that lets product video carry color |
| Surfaces | `#FFFFFF` / `#F5F5F7` | prototype; clean retail ground, reads premium at Rs 2–6K price points |
| **Barracks olive** (brand tint) | `#4A5240` (deep `#3A4132`) | the name's military equity + the olive/khaki garments recurring in drops; the single most defensible brand color available |
| **Signal orange** (offers only) | `#E8722E` | earns the "price-forward" voice a dedicated channel; reserved exclusively for the rotating bundle so it never dilutes |
| Supporting garment neutrals | khaki `#B3A886`, sand `#B8A582`, navy `#2E3A4A` | product-derived accents for category tiles |

Rule worth keeping from the prototype: **orange belongs to the offer and nothing else.** That
one constraint encodes the brand's actual behavior (everything calm except the deal).

⚠️ Caveat: these hexes could not be verified against actual campaign pixels (platform
blocking). Treat olive/orange as a strong hypothesis pending the screenshot ask in §4.

### 2.2 Type

- **Display / prices / labels:** Space Grotesk — techy-utilitarian, fits "barracks" without
  cosplaying camo.
- **Body / UI:** Manrope — neutral, excellent at small mobile sizes.
- **Accent (sparingly):** Georgia italic for the logo "B" and one hero line, as in the
  prototype's wordmark.
- Worth exploring given the unclaimed territory: a stencil or DIN-adjacent face for **offer
  chips and drop labels only** — military-issue flavor at the moments the brand shouts.

### 2.3 Imagery & mood

Traceable to the *strongest* platform (TikTok), not the weakest (legacy IG):

- Vertical 9:16 video as a first-class layout element, not an embed afterthought.
- Store-floor authenticity over studio polish — try-ons, racks, the actual Kohuwala shop.
  The prototype's Unsplash editorial look is *placeholder only* and skews more polished than
  the brand's real feed; production must shoot in-store or the site will feel like a
  different company than the TikTok.
- Motion language: quick crossfades, Ken Burns on stills, count-up numbers, pulsing
  "open now / low stock" dots — retail liveness, `prefers-reduced-motion` respected
  (already modeled in the prototype).

### 2.4 Mirror vs. diverge from social

- **Mirror:** offer-first messaging, WhatsApp as the primary CTA, drop cadence ("New this
  week"), follower-count social proof, vertical video.
- **Diverge:** the site should *not* inherit the hashtag spam, all-caps urgency, or Comic-
  levels of sticker energy. The feed is the hype; the site is the calm place that converts
  the hype. That contrast is the design.

---

## 3 · Page-by-page recommendations

The prototype (`prototype/index.html`) already implements most of the right skeleton.
Below: what to keep, what to change, what's missing.

**Home** — Keep: full-bleed slideshow hero with offer strip above nav; marquee ticker;
"New this week" rail; category grid; promo duo (offer + stores); reels grid; store cards;
trust row; newsletter. Change: hero copy "Always different. That's the standard." is
*invented* — needs client sign-off or replacement with their real line; TikTok counter must
be fetched, not hard-coded (already stale); reels grid should embed/link **real** posts
(TikTok oEmbed or manual curation with outbound links), replacing placeholder tiles.
Add: women's entry point — the store sells a women's line the prototype ignores entirely.

**Shop / collection** — Keep: chip filters + sort, hover image swap, quick-add, offer badges.
Change: category set must match the real catalog — add **Women**, **Caps**, **Accessories**
(underwear likely stays findable but unfeatured). Fix Shopify IA while migrating: kill
`pants-1`-style slugs, one canonical collection per category.

**Product (PDP)** — Keep: swatches, size chart accordion-table, fit notes, reviews, low-stock
signals, sticky mobile buy bar with WhatsApp button, 3-installment (Koko/MintPay) price line.
Change: reviews/ratings are sample data — launch hidden until real reviews exist (fake social
proof is a trust grenade in a WhatsApp-DM market where buyers *will* ask).

**Offer landing (`/2-for-5000` → permanent `/offer`)** — New page, highest priority addition.
Every TikTok bio/caption can link one URL that always shows the *current* bundle (they rotate:
2-for-5,000 / 2-for-6,000 / 3-for-5,000). Offer terms, eligible items, bundle-builder UI (the
prototype's cart already auto-applies the discount — keep that mechanic).

**Stores & contact** — Keep: two store cards with hours + map links, WhatsApp/call/DM stack,
"same standard, both sides of the flyover" locality tone. Change: add real storefront
photography — this page is the brand's authenticity proof.

**Track order / Returns** — Keep both (prototype versions are solid, incl. Trans Express
timeline and WhatsApp-first exchange flow). Change: returns copy is explicitly draft — every
number (7 days, free first swap, 3–5 day refunds) must be confirmed against actual ops
before launch (§4).

**Brand story** — New section (home block + short page). Nothing anywhere currently says who
Barracks is; the raw material is good: started on Dutugemunu Street with dry-fit tees, grew
into a 239K-follower menswear brand, still runs both shops seven days a week.

**Components:** pill buttons (dark/olive/orange hierarchy), rounded-16–22px cards, hairline
borders, frosted dark header, cart drawer with free-delivery progress bar, spotlight search —
all in the prototype, all worth keeping.

**Mobile-first:** ~all discovery is social → mobile. Sticky buy bar, horizontal snap rails,
bottom-sheet cart, tap-to-WhatsApp everywhere. Test at 360px first, desktop second.

---

## 4 · Open questions & assumptions to confirm

1. **Screenshots for color truth.** Platform blocking prevented sampling real campaign
   pixels. Ask the client for 5–10 recent reels/frames + any logo files to lock the olive
   (`#4A5240`) and confirm there's no existing brand color we'd be overriding.
2. **Tagline.** "Always different. That's the standard." is prototype-invented. Adopt,
   adapt, or replace with the brand's own line?
3. **Handle consolidation.** OK to standardize on `@barracksclothing` and repoint
   `@barracks.lk` (IG) + duplicate FB pages? Who controls the legacy accounts?
4. **Catalog scope.** Does the redesign cover the women's line, caps, accessories,
   underwear — and is the Nike resale item part of the assortment story or being phased out?
5. **Offer mechanics.** Confirm the current live bundle (2-for-5,000 per the store; TikTok
   history shows 2-for-6,000 and 3-for-5,000 variants) and who updates it — the design treats
   it as editable content.
6. **Returns/exchange policy numbers.** All prototype policy copy is draft; confirm window,
   free-swap terms, refund timing, COD refund process against actual operations.
7. **Platform assumption.** Store stays on Shopify; redesign ships as a Shopify theme (or
   headless front end on the Storefront API) — the prototype's checkout stub already assumes
   this. WhatsApp ordering remains a parallel first-class path.
8. **Twitter/X.** The brief's "Twitter/X" input was a LinkedIn job URL. Assumption: the brand
   has no X presence and none is planned; the site's social row is TikTok · Instagram ·
   Facebook only.
9. **TikTok counter.** Needs a lightweight update path (manual CMS field is fine) — it was
   already stale inside the prototype within months.

---

## 5 · Addendum — the luxury build (`index.html`)

Following client direction, a second full prototype was built at the repo root
(`index.html`): a **luxury-house treatment** in the register of Ralph Lauren / Lacoste /
Crocodile, holding the Barracks palette (olive `#4A5240` / `#343A2D`, ink `#1B1C18`,
ecru/ivory grounds, signal orange reserved for the Standard Offer). Key moves versus the
first "clean iOS" prototype (`prototype/index.html`):

- **Type:** Cormorant Garamond display serif + Jost letter-spaced small caps replace
  Space Grotesk/Manrope; the serif "B" crest and wordmark move to a centered masthead.
- **Form language:** sharp corners, hairline rules and framed imagery replace rounded
  cards and soft shadows; buttons become bordered small-caps rectangles.
- **Voice:** "the house / the concierge / the Standard Offer" — offers presented with
  restraint (a dark olive editorial band) rather than badges and countdown energy.
- **Structure kept:** SPA with shop, PDP (swatches, size guide, accordions), bag drawer
  with the auto-applied 2-for-5,000 logic, spotlight search, stores, order tracking and
  exchanges pages; WhatsApp remains a first-class path throughout. Sample reviews and
  low-stock urgency were deliberately dropped — off-register for the luxury direction.
- Verified headless (Chromium): all pages render, offer math correct (Rs 2,750 + 2,950 →
  Rs 5,000), no console errors, no horizontal scroll at 390px.

Photography remains Unsplash placeholder; the §4 open questions (palette verification,
tagline sign-off, policy numbers) apply to this build equally.

**Live-content update (17 Jul 2026).** Three classes of real content are now wired in:

- **Trending social section** — real @barracksclothing posts embedded live (two TikTok
  videos + two Instagram reels, verified URLs), hydrated client-side by the official
  TikTok/Instagram embed scripts with styled non-JS fallbacks; follow buttons carry the
  verified counts (TikTok 239.2K · IG 29K · FB 32K).
- **Store locations** — real Google Maps embeds (`output=embed`, no API key) for both
  stores, in a monochrome treatment that colors on hover; "Directions & Photos" links to
  each store's Maps listing, where the real shop photographs live.
- **Product photography** — still placeholder by necessity: the build environment cannot
  reach barracks.lk/Shopify CDN or Google's image hosts, and Google-hosted place photos
  cannot be hotlinked durably anyway. A `BRAND_PHOTOS` override map at the top of the
  script is the one-paste swap-in point for the store's real image URLs (documented
  inline); placeholders are mapped per product description in the meantime.

### Source index

- Store: [barracks.lk](https://barracks.lk/) · [collections](https://barracks.lk/collections) ·
  [Men Pants](https://barracks.lk/collections/pants-1) ·
  [Women's T-Shirts & Tops](https://barracks.lk/collections/womens-t-shirts) ·
  [Baggy Big Fold Pants](https://barracks.lk/collections/baggy-big-fold-pants) ·
  [Caps](https://barracks.lk/collections/caps) ·
  [Accessories](https://barracks.lk/collections/accessories) ·
  [Underwear](https://barracks.lk/collections/underwear) ·
  [Nike Dri-FIT Training Shorts](https://barracks.lk/products/nike-dri-fit-training-shorts-white)
- Social: [TikTok @barracksclothing](https://www.tiktok.com/@barracksclothing) ·
  [IG @barracksclothing](https://www.instagram.com/barracksclothing/) ·
  [IG @barracks.lk](https://www.instagram.com/barracks.lk/) ·
  [FB Barracks.lk](https://www.facebook.com/barracks.lk/) ·
  [FB Barracks Clothing LK](https://www.facebook.com/barracksclothinglk/)
- Prototype: [barrackclothing.netlify.app](https://barrackclothing.netlify.app/) —
  source mirrored at `prototype/index.html`
- Marketplace trace: [Daraz tag "barracks clothing"](https://www.daraz.lk/tag/barracks-clothing/)
