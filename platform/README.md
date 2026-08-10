# Barracks Commerce OS

The platform rebuild: Next.js App Router · TypeScript (strict) · Tailwind · PostgreSQL
via Supabase. It replaces the single-file prototype with a system the owner can run
without touching code.

The existing static site remains at the repository root and stays deployable throughout
the rebuild, so Barracks is never without a website.

## Status

| Phase | Scope | State |
|---|---|---|
| 1 | Audit of the existing code | ✅ [`AUDIT.md`](../AUDIT.md) |
| 2 | Architecture, schema, RLS, seed | ✅ verified against PostgreSQL 16 |
| 13 (pulled forward) | Promotion engine + Standard Offer | ✅ 29 passing tests |
| 3–12, 14–20 | Auth, admin, storefront, checkout, polish | ◻ next |

The promotion engine was built early on purpose: it decides what customers are charged,
so it is the least safe thing to leave until last.

## Running it

```bash
npm install
cp .env.example .env.local     # fill in Supabase values
npm run dev
```

```bash
npm test          # promotion + money logic
npm run build     # production build with type checking
```

### Database

Migrations are plain SQL and run in order. With the Supabase CLI:

```bash
supabase db reset          # applies supabase/migrations/*.sql
```

Against any PostgreSQL 16 instance:

```bash
psql "$DATABASE_URL" -f supabase/migrations/0001_schema.sql
psql "$DATABASE_URL" -f supabase/migrations/0002_rls.sql
psql "$DATABASE_URL" -f supabase/migrations/0003_seed.sql
```

`0001` creates 47 tables with 64 foreign keys and 294 check constraints. `0002` enables
row-level security on every one of them and adds 90 policies. `0003` migrates the ten
prototype pieces — names, copy, fabrics, colourways, sizes — plus both stores, the
homepage composition and the Standard Offer.

Outside Supabase, create the `auth` schema the policies expect first:

```sql
create schema auth;
create table auth.users (id uuid primary key default gen_random_uuid());
create function auth.uid() returns uuid language sql stable as $$ select null::uuid $$;
```

### Creating the first owner

No password is hard-coded and no owner account is seeded (§75). To appoint the first one:

1. Create the user through Supabase Auth (dashboard → Authentication → Add user, or a
   normal sign-up).
2. Grant the role using the **service role** connection, once:

   ```sql
   insert into profiles (id, email) values ('<auth-user-uuid>', '<email>')
     on conflict (id) do nothing;
   insert into user_roles (user_id, role) values ('<auth-user-uuid>', 'OWNER');
   ```

Every later role grant happens in Admin, and only an `OWNER` may grant roles — enforced by
policy, not by hiding a button.

## How the money works

All prices are **integers in minor units** (`Rs 2,750` is `275000`). Floating-point money
drifts once discounts compound, and drift in a cart total is a real accounting error.
`src/lib/money.ts` is the only place that converts to a display string.

Promotions are **rows, not code**. The Standard Offer is one record using the
`BUNDLE_FIXED_PRICE` rule; the owner can retitle, reprice, schedule or pause it, and can
create entirely different promotions (percentage off, spend-and-save, buy-X-get-Y, free
delivery) without a developer.

`src/lib/promotions/engine.ts` is pure — no database, no clock of its own. The browser runs
it for an instant preview and the server runs it again at checkout with trusted prices and
a trusted time. Because it is the same code, the preview matches the charge; because the
server re-runs it, a tampered cart cannot change what is charged.

Two behaviours worth knowing, both covered by tests:

- The bundle pairs the **most expensive** eligible trousers first, which maximises the
  customer's saving.
- A bundle can never *raise* a price: two Rs 2,000 trousers stay Rs 4,000 rather than
  becoming Rs 5,000.

## Security posture

- Row-level security is enabled on all 47 tables with no exceptions, and is verified by
  connecting as an anonymous role: draft products, orders, inventory and audit logs are
  invisible, and writes are rejected outright.
- Authorization is answered in the database via `has_role()`, so a `STAFF` session cannot
  perform an owner action even by calling the API directly.
- The service-role key bypasses RLS by design and is used only in trusted server code. It
  is never `NEXT_PUBLIC_` and never reaches the browser.
- Stock quantities have no public read policy, so competitors cannot scrape inventory.

## Payments

No payment credentials are committed, and none are required to run the app. When
`PAYHERE_MERCHANT_ID` is absent the checkout reports itself as unconfigured rather than
simulating a successful payment. See `.env.example` for the exact credentials needed and
how to obtain them.
