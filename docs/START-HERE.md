# Barracks — Handover Package

This archive contains two distinct things. They are at different stages, and the
difference matters, so read this page before deploying anything.

```
website/    The finished storefront. Ready to go live today.
platform/   The commerce OS rebuild. Foundations only — not yet a live site.
docs/       Brand direction and the technical audit.
```

---

## 1. `website/` — deploy this today

A complete, self-contained static site: the luxury Barracks storefront with the
collection, product pages, bag with the automatic two-trouser offer, search, saved
items, both stores on live Google Maps, the real TikTok/Instagram feed, order
tracking and exchanges. No build step, no dependencies, no server.

**Fastest route:** unzip, go to [app.netlify.com/drop](https://app.netlify.com/drop),
drag the `website` folder onto the page. Live in seconds.

**cPanel / Sri Lankan shared hosting:** upload everything inside `website/` into
`public_html`. Enable "show hidden files" in File Manager so `.htaccess` transfers.
Then switch on the free SSL certificate and uncomment the HTTPS block at the top of
`.htaccess`.

**Vercel / GitHub Pages:** point either at the `website/` folder; the included
`vercel.json` handles the rest.

Verified from 320 px phones through tablets to desktop: no horizontal scrolling, no
console errors, touch-friendly targets throughout.

### Before it goes public — four things

1. **Replace the domain placeholders.** In `website/index.html`, search for
   `barracks.lk` and update `og:url`, `og:image` and `twitter:image` to the real
   domain. Link previews on WhatsApp and Facebook need absolute URLs or the preview
   image will not appear. Do the same in `robots.txt` and `sitemap.xml`.
2. **Swap in the real product photography.** Near the top of the `<script>` block in
   `index.html` there is a `BRAND_PHOTOS` object with instructions. Paste the brand's
   own image URLs there and they replace the placeholders everywhere — cards, product
   pages and the bag. Until then the site uses licensed stock photography chosen to
   match each product description.
3. **Approve the policy copy.** The returns terms (7-day window, free first exchange,
   3–5 day refunds) are drafted for approval, not confirmed operations.
4. **Check the contact details** — 077 065 7669, 105 Dutugemunu Street (Kohuwala),
   75 Nikape Road (Dehiwala).

### Taking card payments

The "Proceed to Checkout" button is deliberately not wired to a processor, because
only the business owner can open a merchant account. The route for Sri Lanka is
**PayHere** (cards, eZ Cash, mCash, FriMi, Genie, LankaQR — settles in LKR), with
**Koko** and **Mintpay** for instalments. Approval needs the business registration
certificate, the owner's NIC and a business bank account, and takes a few days to two
weeks — worth starting early.

Note that **WhatsApp ordering already works on every page**, with the full order
pre-filled into the message. The site is commercially usable the day it goes up.

---

## 2. `platform/` — the rebuild, in progress

This is the beginning of the commerce platform from the master brief: the system that
will let the owner add products, change prices, upload photography, schedule campaigns
and process orders without a developer.

**It is not a deployable storefront yet.** Its homepage is a placeholder that says so.
Deploying `platform/` today would put a near-empty page in front of customers. Deploy
`website/` instead until the storefront phases are finished.

### What is built and verified

- **Database schema** — 47 tables, 64 foreign keys, 294 check constraints, 94 indexes.
  Applied and tested against PostgreSQL 16, not merely written.
- **Row-level security** — enabled on all 47 tables with 90 policies, verified by
  connecting as an anonymous user: draft products, orders, inventory and audit logs are
  invisible, and writes are rejected.
- **Promotion engine** — 29 passing tests. Promotions are database rows, not code, so
  the Standard Offer can be repriced, scheduled or paused from Admin. Money is handled
  in integer minor units throughout, because floating-point drift in a cart total is a
  real accounting error.
- **Seeded catalogue** — all ten pieces with their copy, fabrics, colourways and sizes,
  both stores, and the homepage composition. No invented stock figures, and nothing
  auto-published.
- **Design tokens** — the Barracks palette, type scale and motion values in one place.

### What remains

Authentication wiring, the admin dashboard, the rebuilt storefront, checkout, customer
accounts, lookbook and Drop Room. The audit in `docs/AUDIT.md` maps each remaining item.

### Running it

```bash
cd platform
npm install
cp .env.example .env.local     # fill in Supabase values
npm run dev
npm test                       # promotion + money logic
```

Full setup, the database migration commands and how to create the first owner account
are in `platform/README.md`. No credentials are included anywhere in this archive.

---

## 3. `docs/`

- `AUDIT.md` — measured technical audit of the existing prototype and what the rebuild
  does about each finding.
- `REDESIGN.md` — brand analysis, verified social accounts, palette and type reasoning,
  and page-by-page direction.

---

*Always different. That's the standard.*
