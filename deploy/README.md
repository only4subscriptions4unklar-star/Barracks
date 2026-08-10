# Barracks Clothing — Deployment Package

A complete, self-contained static website. No build step, no dependencies, no server-side
code — upload the contents of this folder to any web host and the site is live.

## What's in here

| File | Purpose |
|---|---|
| `index.html` | The entire website (all pages, styles and behaviour in one file) |
| `favicon.svg` | Browser tab icon — the Barracks crest |
| `apple-touch-icon.png` | Icon used when saved to an iPhone/iPad home screen |
| `og-image.png` | Preview card shown when the link is shared on WhatsApp, Facebook, Instagram |
| `robots.txt`, `sitemap.xml` | Search-engine basics |
| `netlify.toml` | Config applied automatically if you deploy to Netlify |
| `vercel.json` | Config applied automatically if you deploy to Vercel |
| `.htaccess` | Config for Apache/cPanel hosting (most Sri Lankan shared hosts) |

## Deploy it — pick one

**Netlify (fastest, free, no account setup needed to test)**
Go to [app.netlify.com/drop](https://app.netlify.com/drop) and drag this whole folder onto
the page. It's live in seconds on a temporary URL; add the real domain under
*Site settings → Domain management*.

**Vercel** — [vercel.com/new](https://vercel.com/new), import the folder or the GitHub repo.
`vercel.json` handles the rest.

**cPanel / shared hosting (Hostinger, local Sri Lankan hosts)**
Upload every file in this folder into `public_html` via File Manager or FTP, keeping
`.htaccess` (it may be hidden — enable "show hidden files"). Then enable the free SSL
certificate in cPanel and uncomment the HTTPS block at the top of `.htaccess`.

**GitHub Pages** — push these files to a repo, then *Settings → Pages → Deploy from branch*.

## Before you go live — checklist

1. **Replace the domain placeholders.** Search `index.html` for `barracks.lk` and update the
   `og:url`, `og:image` and `twitter:image` tags to the real domain (these must be absolute
   URLs or WhatsApp/Facebook link previews won't show the image). Do the same in `robots.txt`
   and `sitemap.xml`.
2. **Swap in the real product photography.** Near the top of the `<script>` block in
   `index.html` there is a `BRAND_PHOTOS` object with instructions. Paste the brand's own
   image URLs there and they replace the placeholders everywhere — product cards, product
   pages and the bag. Until then the site uses licensed stock photography that matches each
   product description.
3. **Confirm the policy copy.** The returns/exchange terms (7-day window, free first
   exchange, 3–5 day refunds) are drafted for approval — verify them against how the stores
   actually operate before publishing.
4. **Check the phone number and addresses** — currently 077 065 7669, 105 Dutugemunu Street
   (Kohuwala) and 75 Nikape Road (Dehiwala).

## About the checkout

This package is the **storefront**. The "Proceed to Checkout" button is intentionally not
wired to a payment processor — taking card payments requires a merchant account that only
the business owner can open.

The recommended route for Sri Lanka: keep the existing Shopify store behind the scenes and
install **PayHere** (cards, eZ Cash, mCash, FriMi, Genie, LankaQR — settles in LKR),
alongside **Koko** and **Mintpay** for instalments. Gateway approval needs the business
registration certificate, the owner's NIC and a business bank account, and typically takes
a few days to two weeks — start that paperwork early.

Note that **WhatsApp ordering already works today** on every page and in the bag, with the
order details pre-filled in the message. Given that most Barracks orders currently happen
over WhatsApp, the site is commercially usable the moment it's uploaded, with card checkout
added later.

## Good to know

- Works offline-tolerant: if any photo fails to load, a designed garment tile takes its
  place, so the layout never breaks.
- The TikTok and Instagram posts and both Google Maps are live embeds — they need an
  internet connection and will not appear when opening the file straight from disk in some
  browsers. Once hosted, they work normally.
- Tested from 320px phones through tablets to desktop: no horizontal scrolling, no console
  errors, touch-friendly tap targets throughout.
