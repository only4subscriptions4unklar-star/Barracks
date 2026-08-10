-- ============================================================================
-- BARRACKS COMMERCE OS — core schema
-- ----------------------------------------------------------------------------
-- Conventions used throughout:
--   * Money is `integer` in minor units (cents). Never float, never numeric-as-
--     text. See src/lib/money.ts for the matching application contract.
--   * Every table carries created_at/updated_at; `touch_updated_at()` maintains
--     updated_at so application code cannot forget to.
--   * Destructive operations are avoided in favour of archived_at soft deletes,
--     so a mis-click in Admin never destroys history (brief §78).
--   * Order lines snapshot the product as it was sold, so editing a product or
--     a promotion later can never rewrite what a customer actually paid.
-- ============================================================================

create extension if not exists "pgcrypto";
create extension if not exists "pg_trgm";     -- trigram search for the storefront
create extension if not exists "unaccent";

-- ---------------------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------------------
create or replace function touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Enumerations
-- ---------------------------------------------------------------------------
create type app_role          as enum ('OWNER', 'ADMIN', 'MANAGER', 'STAFF');
create type publish_status    as enum ('DRAFT', 'SCHEDULED', 'ACTIVE', 'SOLD_OUT', 'ARCHIVED');
create type promotion_status  as enum ('DRAFT', 'SCHEDULED', 'ACTIVE', 'PAUSED', 'EXPIRED', 'ARCHIVED');
create type promotion_rule_kind as enum (
  'BUNDLE_FIXED_PRICE', 'PERCENT_OFF', 'FIXED_AMOUNT_OFF',
  'SPEND_GET_AMOUNT_OFF', 'BUY_X_GET_Y_FREE', 'FREE_SHIPPING'
);
create type order_status      as enum (
  'PENDING', 'CONFIRMED', 'PREPARING', 'PACKED', 'HANDED_TO_COURIER',
  'IN_TRANSIT', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED', 'REFUNDED'
);
create type payment_status    as enum ('UNPAID', 'AUTHORIZED', 'PAID', 'PARTIALLY_REFUNDED', 'REFUNDED', 'FAILED');
create type payment_method    as enum ('CARD', 'COD', 'BANK_TRANSFER', 'KOKO', 'MINTPAY', 'IN_STORE');
create type order_source      as enum ('WEB', 'WHATSAPP', 'ADMIN', 'STORE');
create type image_role        as enum ('PRIMARY', 'HOVER', 'MODEL', 'LIFESTYLE', 'DETAIL', 'FABRIC', 'VARIANT', 'MOBILE');
create type return_status     as enum ('REQUESTED', 'APPROVED', 'COLLECTED', 'REPLACEMENT_SENT', 'REFUNDED', 'REJECTED', 'CLOSED');
create type return_resolution as enum ('EXCHANGE', 'REFUND');

-- ---------------------------------------------------------------------------
-- Identity & access
-- Staff identities live in Supabase auth.users; profiles extends them.
-- ---------------------------------------------------------------------------
create table profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  full_name    text,
  email        text,
  phone        text,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table user_roles (
  user_id    uuid not null references profiles(id) on delete cascade,
  role       app_role not null,
  granted_at timestamptz not null default now(),
  granted_by uuid references profiles(id),
  primary key (user_id, role)
);
create index user_roles_role_idx on user_roles (role);

-- Authorization is answered in the database, so a hidden button is never the
-- only thing standing between a STAFF account and an owner-only action (§30).
create or replace function has_role(required app_role)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from user_roles ur
    where ur.user_id = auth.uid()
      and (
        ur.role = required
        or ur.role = 'OWNER'
        or (required = 'STAFF'   and ur.role in ('ADMIN', 'MANAGER'))
        or (required = 'MANAGER' and ur.role = 'ADMIN')
      )
  );
$$;

create or replace function is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from user_roles ur where ur.user_id = auth.uid());
$$;

-- ---------------------------------------------------------------------------
-- Media library (§41) — every asset the owner uploads, in one place
-- ---------------------------------------------------------------------------
create table media (
  id            uuid primary key default gen_random_uuid(),
  storage_path  text not null unique,
  file_name     text not null,
  mime_type     text not null,
  byte_size     integer not null check (byte_size > 0),
  width         integer check (width > 0),
  height        integer check (height > 0),
  blur_data_url text,                       -- tiny base64 LQIP, prevents layout pop
  alt_text      text,
  focal_x       numeric(4,3) not null default 0.5 check (focal_x between 0 and 1),
  focal_y       numeric(4,3) not null default 0.5 check (focal_y between 0 and 1),
  uploaded_by   uuid references profiles(id),
  archived_at   timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index media_archived_idx on media (archived_at) where archived_at is null;

-- ---------------------------------------------------------------------------
-- Catalogue structure
-- ---------------------------------------------------------------------------
create table categories (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique,
  name        text not null,
  description text,
  position    integer not null default 0,
  archived_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table collections (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique,
  name           text not null,
  /* Editorial intro shown at the top of the collection page (§13). */
  intro          text,
  banner_media_id uuid references media(id) on delete set null,
  position       integer not null default 0,
  is_featured    boolean not null default false,
  archived_at    timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table products (
  id                 uuid primary key default gen_random_uuid(),
  slug               text not null unique,
  name               text not null,
  subtitle           text,
  sku                text unique,
  short_description  text,
  long_description   text,
  category_id        uuid references categories(id) on delete restrict,
  fabric             text,
  composition        text,
  fit                text,
  care               text,
  /* Selling price and the "was" price shown struck through, both minor units. */
  price_minor        integer not null check (price_minor >= 0),
  compare_at_minor   integer check (compare_at_minor >= 0),
  /* Never exposed publicly; powers margin reporting in Admin. */
  cost_minor         integer check (cost_minor >= 0),
  currency           char(3) not null default 'LKR',
  status             publish_status not null default 'DRAFT',
  published_at       timestamptz,
  is_featured        boolean not null default false,
  is_new_arrival     boolean not null default false,
  is_bestseller      boolean not null default false,
  is_limited         boolean not null default false,
  /* Owner switch that removes a product from every promotion (§36). */
  promotion_eligible boolean not null default true,
  /* Only shown when the owner deliberately opts in (§85 — no fake scarcity). */
  show_stock_count   boolean not null default false,
  seo_title          text,
  seo_description    text,
  position           integer not null default 0,
  archived_at        timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  constraint compare_at_above_price check (compare_at_minor is null or compare_at_minor >= price_minor)
);
create index products_status_idx    on products (status) where archived_at is null;
create index products_category_idx  on products (category_id);
create index products_name_trgm_idx on products using gin (name gin_trgm_ops);

create table product_collections (
  product_id    uuid not null references products(id) on delete cascade,
  collection_id uuid not null references collections(id) on delete cascade,
  position      integer not null default 0,
  primary key (product_id, collection_id)
);

create table product_tags (
  product_id uuid not null references products(id) on delete cascade,
  tag        text not null,
  primary key (product_id, tag)
);
create index product_tags_tag_idx on product_tags (tag);

-- A variant is a colourway; sizes hang off it and carry the sellable stock.
create table product_variants (
  id            uuid primary key default gen_random_uuid(),
  product_id    uuid not null references products(id) on delete cascade,
  colour_name   text not null,
  colour_hex    char(7) not null check (colour_hex ~ '^#[0-9A-Fa-f]{6}$'),
  position      integer not null default 0,
  archived_at   timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (product_id, colour_name)
);

create table product_sizes (
  id           uuid primary key default gen_random_uuid(),
  variant_id   uuid not null references product_variants(id) on delete cascade,
  label        text not null,                       -- '32', 'M', 'XXL'
  sku          text unique,
  /* Per-size override; null means "inherit the product price". */
  price_minor  integer check (price_minor >= 0),
  position     integer not null default 0,
  is_available boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (variant_id, label)
);

create table product_images (
  id          uuid primary key default gen_random_uuid(),
  product_id  uuid not null references products(id) on delete cascade,
  /* Null = applies to the whole product; set = specific colourway (§35). */
  variant_id  uuid references product_variants(id) on delete cascade,
  media_id    uuid not null references media(id) on delete restrict,
  role        image_role not null default 'MODEL',
  position    integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index product_images_product_idx on product_images (product_id, position);
-- Exactly one primary image per product keeps cards deterministic.
create unique index product_images_one_primary_idx
  on product_images (product_id) where role = 'PRIMARY';

-- Manual merchandising: the owner picks what completes a look (§86).
create table product_recommendations (
  product_id            uuid not null references products(id) on delete cascade,
  recommended_product_id uuid not null references products(id) on delete cascade,
  position              integer not null default 0,
  primary key (product_id, recommended_product_id),
  constraint no_self_recommendation check (product_id <> recommended_product_id)
);

-- ---------------------------------------------------------------------------
-- Inventory, per location (§21)
-- ---------------------------------------------------------------------------
create table inventory_locations (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,          -- 'KOHUWALA', 'DEHIWALA', 'ONLINE'
  name        text not null,
  is_online   boolean not null default false,
  archived_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table inventory (
  id           uuid primary key default gen_random_uuid(),
  size_id      uuid not null references product_sizes(id) on delete cascade,
  location_id  uuid not null references inventory_locations(id) on delete restrict,
  /* on_hand minus reserved is what may be sold. Both are guarded against
     going negative, which is what stops overselling (§80). */
  on_hand      integer not null default 0 check (on_hand >= 0),
  reserved     integer not null default 0 check (reserved >= 0),
  low_stock_at integer not null default 2 check (low_stock_at >= 0),
  updated_at   timestamptz not null default now(),
  unique (size_id, location_id),
  constraint reserved_within_on_hand check (reserved <= on_hand)
);
create index inventory_size_idx on inventory (size_id);

-- ---------------------------------------------------------------------------
-- Promotions (§39) — rules are rows, never code
-- ---------------------------------------------------------------------------
create table promotions (
  id                   uuid primary key default gen_random_uuid(),
  name                 text not null,
  internal_note        text,
  customer_message     text not null,
  rule_kind            promotion_rule_kind not null,
  /* Rule parameters, validated in the application by a Zod schema per kind.
     Kept as jsonb because each kind has a genuinely different shape — this is
     the one place where that is the correct modelling choice, not a shortcut. */
  rule_config          jsonb not null default '{}'::jsonb,
  status               promotion_status not null default 'DRAFT',
  starts_at            timestamptz,
  ends_at              timestamptz,
  coupon_code          text unique,
  min_quantity         integer check (min_quantity > 0),
  min_cart_value_minor integer check (min_cart_value_minor >= 0),
  usage_limit          integer check (usage_limit > 0),
  per_customer_limit   integer check (per_customer_limit > 0),
  times_used           integer not null default 0 check (times_used >= 0),
  stackable            boolean not null default false,
  priority             integer not null default 100,
  created_by           uuid references profiles(id),
  archived_at          timestamptz,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  constraint promotion_window_ordered check (ends_at is null or starts_at is null or ends_at > starts_at)
);
create index promotions_active_idx on promotions (status, starts_at, ends_at);

create table promotion_products (
  promotion_id uuid not null references promotions(id) on delete cascade,
  product_id   uuid not null references products(id) on delete cascade,
  primary key (promotion_id, product_id)
);

create table promotion_collections (
  promotion_id  uuid not null references promotions(id) on delete cascade,
  collection_id uuid not null references collections(id) on delete cascade,
  primary key (promotion_id, collection_id)
);

create table promotion_categories (
  promotion_id uuid not null references promotions(id) on delete cascade,
  category_id  uuid not null references categories(id) on delete cascade,
  primary key (promotion_id, category_id)
);

-- ---------------------------------------------------------------------------
-- Storefront content: banners, homepage builder, pages, stores, settings
-- ---------------------------------------------------------------------------
create table banners (
  id                uuid primary key default gen_random_uuid(),
  title             text not null,
  eyebrow           text,
  headline          text,
  editorial_line    text,
  body              text,
  desktop_media_id  uuid references media(id) on delete set null,
  mobile_media_id   uuid references media(id) on delete set null,
  video_url         text,
  cta_primary_label text,
  cta_primary_href  text,
  cta_secondary_label text,
  cta_secondary_href  text,
  text_position     text not null default 'center'
                    check (text_position in ('left','center','right')),
  overlay_intensity numeric(3,2) not null default 0.45
                    check (overlay_intensity between 0 and 1),
  status            publish_status not null default 'DRAFT',
  starts_at         timestamptz,
  ends_at           timestamptz,
  position          integer not null default 0,
  archived_at       timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- The homepage is an ordered list of blocks the owner arranges (§38).
create table homepage_sections (
  id         uuid primary key default gen_random_uuid(),
  kind       text not null check (kind in (
               'HERO','COLLECTION_GRID','PRODUCT_RAIL','EDITORIAL_IMAGE','EDITORIAL_SPLIT',
               'TEXT_STATEMENT','STANDARD_OFFER','FEATURED_PRODUCT','LOOKBOOK','SHOP_THE_LOOK',
               'VIDEO','STORE_FEATURE','SOCIAL','SERVICES','NEWSLETTER','DROP_COUNTDOWN','CUSTOM')),
  /* Block-specific settings; the shape is validated per kind in the app. */
  config     jsonb not null default '{}'::jsonb,
  position   integer not null default 0,
  is_visible boolean not null default true,
  starts_at  timestamptz,
  ends_at    timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index homepage_sections_order_idx on homepage_sections (position);

create table stores (
  id            uuid primary key default gen_random_uuid(),
  slug          text not null unique,
  name          text not null,
  address_line  text not null,
  city          text,
  phone         text,
  whatsapp      text,
  opening_hours text,
  map_embed_url text,
  map_link_url  text,
  notice        text,
  location_id   uuid references inventory_locations(id) on delete set null,
  position      integer not null default 0,
  is_published  boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table store_images (
  store_id uuid not null references stores(id) on delete cascade,
  media_id uuid not null references media(id) on delete cascade,
  position integer not null default 0,
  primary key (store_id, media_id)
);

create table pages (
  id               uuid primary key default gen_random_uuid(),
  slug             text not null unique,
  title            text not null,
  body             text,
  seo_title        text,
  seo_description  text,
  status           publish_status not null default 'DRAFT',
  published_at     timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- Single-row-per-key store for everything in §90.
create table site_settings (
  key         text primary key,
  value       jsonb not null,
  updated_by  uuid references profiles(id),
  updated_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Customers, carts, wishlists
-- ---------------------------------------------------------------------------
create table customers (
  id          uuid primary key default gen_random_uuid(),
  /* Null for guests — checkout never requires an account (§17). */
  auth_id     uuid unique references auth.users(id) on delete set null,
  email       text,
  phone       text,
  full_name   text,
  marketing_opt_in boolean not null default false,
  /* Fit Assistant profile (§11), stored only with consent. */
  fit_profile jsonb,
  archived_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create unique index customers_email_idx on customers (lower(email)) where email is not null;
create index customers_phone_idx on customers (phone);

create table addresses (
  id           uuid primary key default gen_random_uuid(),
  customer_id  uuid not null references customers(id) on delete cascade,
  label        text,
  recipient    text not null,
  phone        text not null,
  line1        text not null,
  line2        text,
  city         text not null,
  district     text,
  postal_code  text,
  country      char(2) not null default 'LK',
  is_default   boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index addresses_customer_idx on addresses (customer_id);

create table carts (
  id           uuid primary key default gen_random_uuid(),
  customer_id  uuid references customers(id) on delete set null,
  /* Anonymous carts are addressed by an opaque token in an httpOnly cookie. */
  session_token text unique,
  coupon_code  text,
  converted_order_id uuid,
  abandoned_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table cart_items (
  id         uuid primary key default gen_random_uuid(),
  cart_id    uuid not null references carts(id) on delete cascade,
  size_id    uuid not null references product_sizes(id) on delete cascade,
  quantity   integer not null check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (cart_id, size_id)
);

create table wishlists (
  id            uuid primary key default gen_random_uuid(),
  customer_id   uuid references customers(id) on delete cascade,
  session_token text unique,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table wishlist_items (
  wishlist_id uuid not null references wishlists(id) on delete cascade,
  product_id  uuid not null references products(id) on delete cascade,
  size_id     uuid references product_sizes(id) on delete set null,
  created_at  timestamptz not null default now(),
  primary key (wishlist_id, product_id)
);

create table back_in_stock_requests (
  id           uuid primary key default gen_random_uuid(),
  size_id      uuid not null references product_sizes(id) on delete cascade,
  email        text,
  phone        text,
  notified_at  timestamptz,
  created_at   timestamptz not null default now(),
  constraint contact_required check (email is not null or phone is not null)
);
create index back_in_stock_open_idx on back_in_stock_requests (size_id) where notified_at is null;

create table recently_viewed (
  customer_id uuid not null references customers(id) on delete cascade,
  product_id  uuid not null references products(id) on delete cascade,
  viewed_at   timestamptz not null default now(),
  primary key (customer_id, product_id)
);

-- ---------------------------------------------------------------------------
-- Orders — immutable record of what was actually sold
-- ---------------------------------------------------------------------------
create table orders (
  id                 uuid primary key default gen_random_uuid(),
  /* Human reference, e.g. BRK-10482. Generated by the application. */
  order_number       text not null unique,
  customer_id        uuid references customers(id) on delete set null,
  /* Contact is copied here so an order survives customer record changes. */
  contact_email      text,
  contact_phone      text not null,
  contact_name       text not null,
  shipping_address   jsonb,
  status             order_status not null default 'PENDING',
  payment_status     payment_status not null default 'UNPAID',
  payment_method     payment_method,
  source             order_source not null default 'WEB',
  subtotal_minor     integer not null check (subtotal_minor >= 0),
  discount_minor     integer not null default 0 check (discount_minor >= 0),
  shipping_minor     integer not null default 0 check (shipping_minor >= 0),
  total_minor        integer not null check (total_minor >= 0),
  currency           char(3) not null default 'LKR',
  /* Snapshot of which promotions applied and what each saved. */
  applied_promotions jsonb not null default '[]'::jsonb,
  coupon_code        text,
  courier_name       text,
  tracking_reference text,
  internal_note      text,
  placed_at          timestamptz not null default now(),
  delivered_at       timestamptz,
  cancelled_at       timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index orders_status_idx   on orders (status, placed_at desc);
create index orders_customer_idx on orders (customer_id);
create index orders_phone_idx    on orders (contact_phone);

create table order_items (
  id             uuid primary key default gen_random_uuid(),
  order_id       uuid not null references orders(id) on delete cascade,
  /* References are set null on delete: the snapshot below is the real record,
     so archiving a product never corrupts order history (§78). */
  product_id     uuid references products(id) on delete set null,
  size_id        uuid references product_sizes(id) on delete set null,
  product_name   text not null,
  colour_name    text,
  size_label     text,
  sku            text,
  image_url      text,
  unit_price_minor integer not null check (unit_price_minor >= 0),
  quantity       integer not null check (quantity > 0),
  discount_minor integer not null default 0 check (discount_minor >= 0),
  line_total_minor integer not null check (line_total_minor >= 0),
  created_at     timestamptz not null default now()
);
create index order_items_order_idx on order_items (order_id);

create table order_events (
  id         uuid primary key default gen_random_uuid(),
  order_id   uuid not null references orders(id) on delete cascade,
  status     order_status not null,
  note       text,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);
create index order_events_order_idx on order_events (order_id, created_at);

create table returns (
  id             uuid primary key default gen_random_uuid(),
  order_id       uuid not null references orders(id) on delete cascade,
  order_item_id  uuid references order_items(id) on delete set null,
  reason         text not null,
  resolution     return_resolution not null,
  preferred_size text,
  preferred_colour text,
  status         return_status not null default 'REQUESTED',
  admin_note     text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index returns_status_idx on returns (status, created_at desc);

-- ---------------------------------------------------------------------------
-- Editorial: lookbooks, drops, shop-the-look hotspots
-- ---------------------------------------------------------------------------
create table lookbooks (
  id           uuid primary key default gen_random_uuid(),
  slug         text not null unique,
  title        text not null,
  season       text,
  intro        text,
  cover_media_id uuid references media(id) on delete set null,
  status       publish_status not null default 'DRAFT',
  published_at timestamptz,
  position     integer not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table lookbook_images (
  id          uuid primary key default gen_random_uuid(),
  lookbook_id uuid not null references lookbooks(id) on delete cascade,
  media_id    uuid not null references media(id) on delete restrict,
  caption     text,
  position    integer not null default 0
);

create table lookbook_hotspots (
  id                uuid primary key default gen_random_uuid(),
  lookbook_image_id uuid not null references lookbook_images(id) on delete cascade,
  product_id        uuid not null references products(id) on delete cascade,
  /* Normalised 0–1 coordinates so hotspots survive any crop or breakpoint. */
  x                 numeric(4,3) not null check (x between 0 and 1),
  y                 numeric(4,3) not null check (y between 0 and 1),
  label             text
);

create table drops (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique,
  title          text not null,
  teaser         text,
  cover_media_id uuid references media(id) on delete set null,
  video_url      text,
  launch_at      timestamptz not null,
  status         publish_status not null default 'DRAFT',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table drop_products (
  drop_id    uuid not null references drops(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  position   integer not null default 0,
  primary key (drop_id, product_id)
);

create table drop_reminders (
  id         uuid primary key default gen_random_uuid(),
  drop_id    uuid not null references drops(id) on delete cascade,
  email      text,
  phone      text,
  created_at timestamptz not null default now(),
  constraint reminder_contact_required check (email is not null or phone is not null)
);

create table newsletter_subscribers (
  id            uuid primary key default gen_random_uuid(),
  email         text not null unique,
  consent_at    timestamptz not null default now(),
  unsubscribed_at timestamptz,
  source        text
);

-- ---------------------------------------------------------------------------
-- Operations: analytics events, notifications, audit trail
-- ---------------------------------------------------------------------------
create table analytics_events (
  id          bigserial primary key,
  name        text not null,
  session_id  text,
  customer_id uuid references customers(id) on delete set null,
  product_id  uuid references products(id) on delete set null,
  payload     jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now()
);
create index analytics_events_name_idx on analytics_events (name, occurred_at desc);
create index analytics_events_product_idx on analytics_events (product_id, occurred_at desc);

create table notifications (
  id         uuid primary key default gen_random_uuid(),
  kind       text not null,
  title      text not null,
  body       text,
  href       text,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_unread_idx on notifications (created_at desc) where read_at is null;

-- Who changed what, when, and what it was before (§46).
create table audit_logs (
  id          bigserial primary key,
  actor_id    uuid references profiles(id) on delete set null,
  action      text not null,                    -- 'product.price_changed'
  entity_type text not null,
  entity_id   uuid,
  before      jsonb,
  after       jsonb,
  created_at  timestamptz not null default now()
);
create index audit_logs_entity_idx on audit_logs (entity_type, entity_id, created_at desc);

-- Restorable revisions for content the owner can break with one click (§45/§46).
create table content_revisions (
  id          bigserial primary key,
  entity_type text not null,
  entity_id   uuid not null,
  snapshot    jsonb not null,
  created_by  uuid references profiles(id) on delete set null,
  created_at  timestamptz not null default now()
);
create index content_revisions_entity_idx on content_revisions (entity_type, entity_id, created_at desc);

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'profiles','media','categories','collections','products','product_variants',
    'product_sizes','product_images','inventory_locations','inventory','promotions',
    'banners','homepage_sections','stores','pages','customers','addresses','carts',
    'cart_items','wishlists','orders','returns','lookbooks','drops'
  ]
  loop
    execute format(
      'create trigger %I_touch before update on %I
         for each row execute function touch_updated_at()', t || '_updated', t);
  end loop;
end;
$$;
