-- ============================================================================
-- BARRACKS — Row Level Security
-- ----------------------------------------------------------------------------
-- Every table is deny-by-default. Access is granted by explicit policy only.
--
-- Three audiences:
--   anon / authenticated  → may read *published* storefront content, and may
--                           read and write only their own cart, wishlist and
--                           orders.
--   staff (user_roles)    → may manage the catalogue and operations, gated by
--                           role via has_role().
--   service_role          → bypasses RLS by design; used exclusively by trusted
--                           server code (checkout, webhooks, admin mutations
--                           that have already passed an authorization check).
--
-- Security is enforced here, in the database — never by hiding a button (§30).
-- ============================================================================

alter table profiles                enable row level security;
alter table user_roles              enable row level security;
alter table media                   enable row level security;
alter table categories              enable row level security;
alter table collections             enable row level security;
alter table products                enable row level security;
alter table product_collections     enable row level security;
alter table product_tags            enable row level security;
alter table product_variants        enable row level security;
alter table product_sizes           enable row level security;
alter table product_images          enable row level security;
alter table product_recommendations enable row level security;
alter table inventory_locations     enable row level security;
alter table inventory               enable row level security;
alter table promotions              enable row level security;
alter table promotion_products      enable row level security;
alter table promotion_collections   enable row level security;
alter table promotion_categories    enable row level security;
alter table banners                 enable row level security;
alter table homepage_sections       enable row level security;
alter table stores                  enable row level security;
alter table store_images            enable row level security;
alter table pages                   enable row level security;
alter table site_settings           enable row level security;
alter table customers               enable row level security;
alter table addresses               enable row level security;
alter table carts                   enable row level security;
alter table cart_items              enable row level security;
alter table wishlists               enable row level security;
alter table wishlist_items          enable row level security;
alter table back_in_stock_requests  enable row level security;
alter table recently_viewed         enable row level security;
alter table orders                  enable row level security;
alter table order_items             enable row level security;
alter table order_events            enable row level security;
alter table returns                 enable row level security;
alter table lookbooks               enable row level security;
alter table lookbook_images         enable row level security;
alter table lookbook_hotspots       enable row level security;
alter table drops                   enable row level security;
alter table drop_products           enable row level security;
alter table drop_reminders          enable row level security;
alter table newsletter_subscribers  enable row level security;
alter table analytics_events        enable row level security;
alter table notifications           enable row level security;
alter table audit_logs              enable row level security;
alter table content_revisions       enable row level security;

-- ---------------------------------------------------------------------------
-- Identity
-- ---------------------------------------------------------------------------
create policy profiles_self_read on profiles
  for select using (id = auth.uid() or is_staff());
create policy profiles_self_update on profiles
  for update using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_owner_manage on profiles
  for all using (has_role('OWNER')) with check (has_role('OWNER'));

-- Only an OWNER may grant or revoke roles; staff may see who holds what.
create policy user_roles_read on user_roles
  for select using (user_id = auth.uid() or is_staff());
create policy user_roles_owner_manage on user_roles
  for all using (has_role('OWNER')) with check (has_role('OWNER'));

-- ---------------------------------------------------------------------------
-- Published storefront content — readable by the public
-- ---------------------------------------------------------------------------
create policy products_public_read on products
  for select using (status in ('ACTIVE', 'SOLD_OUT') and archived_at is null);
create policy products_staff_read on products
  for select using (is_staff());
create policy products_staff_write on products
  for all using (has_role('MANAGER')) with check (has_role('MANAGER'));

-- Child rows inherit their parent's visibility, so an unpublished product
-- cannot leak through its variants, sizes or images.
create policy variants_public_read on product_variants
  for select using (
    archived_at is null and exists (
      select 1 from products p
      where p.id = product_id and p.status in ('ACTIVE','SOLD_OUT') and p.archived_at is null));
create policy variants_staff_all on product_variants
  for all using (is_staff()) with check (has_role('MANAGER'));

create policy sizes_public_read on product_sizes
  for select using (exists (
    select 1 from product_variants v join products p on p.id = v.product_id
    where v.id = variant_id and p.status in ('ACTIVE','SOLD_OUT') and p.archived_at is null));
create policy sizes_staff_all on product_sizes
  for all using (is_staff()) with check (has_role('MANAGER'));

create policy product_images_public_read on product_images
  for select using (exists (
    select 1 from products p
    where p.id = product_id and p.status in ('ACTIVE','SOLD_OUT') and p.archived_at is null));
create policy product_images_staff_all on product_images
  for all using (is_staff()) with check (has_role('MANAGER'));

create policy media_public_read on media
  for select using (archived_at is null);
create policy media_staff_all on media
  for all using (is_staff()) with check (has_role('MANAGER'));

create policy categories_public_read on categories
  for select using (archived_at is null);
create policy categories_staff_all on categories
  for all using (is_staff()) with check (has_role('ADMIN'));

create policy collections_public_read on collections
  for select using (archived_at is null);
create policy collections_staff_all on collections
  for all using (is_staff()) with check (has_role('ADMIN'));

create policy product_collections_public_read on product_collections for select using (true);
create policy product_collections_staff_all on product_collections
  for all using (is_staff()) with check (has_role('MANAGER'));

create policy product_tags_public_read on product_tags for select using (true);
create policy product_tags_staff_all on product_tags
  for all using (is_staff()) with check (has_role('MANAGER'));

create policy recommendations_public_read on product_recommendations for select using (true);
create policy recommendations_staff_all on product_recommendations
  for all using (is_staff()) with check (has_role('MANAGER'));

-- Only live banners and visible homepage blocks reach the public; scheduling is
-- enforced in the database, not merely hidden by the UI.
create policy banners_public_read on banners
  for select using (
    status = 'ACTIVE' and archived_at is null
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at > now()));
create policy banners_staff_all on banners
  for all using (is_staff()) with check (has_role('ADMIN'));

create policy homepage_public_read on homepage_sections
  for select using (
    is_visible
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at > now()));
create policy homepage_staff_all on homepage_sections
  for all using (is_staff()) with check (has_role('ADMIN'));

create policy stores_public_read on stores for select using (is_published);
create policy stores_staff_all on stores
  for all using (is_staff()) with check (has_role('ADMIN'));
create policy store_images_public_read on store_images for select using (true);
create policy store_images_staff_all on store_images
  for all using (is_staff()) with check (has_role('ADMIN'));

create policy pages_public_read on pages
  for select using (status = 'ACTIVE');
create policy pages_staff_all on pages
  for all using (is_staff()) with check (has_role('ADMIN'));

create policy site_settings_public_read on site_settings for select using (true);
create policy site_settings_owner_write on site_settings
  for all using (has_role('ADMIN')) with check (has_role('ADMIN'));

create policy lookbooks_public_read on lookbooks for select using (status = 'ACTIVE');
create policy lookbooks_staff_all on lookbooks
  for all using (is_staff()) with check (has_role('ADMIN'));
create policy lookbook_images_public_read on lookbook_images
  for select using (exists (select 1 from lookbooks l where l.id = lookbook_id and l.status = 'ACTIVE'));
create policy lookbook_images_staff_all on lookbook_images
  for all using (is_staff()) with check (has_role('ADMIN'));
create policy hotspots_public_read on lookbook_hotspots for select using (true);
create policy hotspots_staff_all on lookbook_hotspots
  for all using (is_staff()) with check (has_role('ADMIN'));

-- A drop's products stay invisible until its launch moment passes (§23).
create policy drops_public_read on drops
  for select using (status = 'ACTIVE');
create policy drops_staff_all on drops
  for all using (is_staff()) with check (has_role('ADMIN'));
create policy drop_products_public_read on drop_products
  for select using (exists (
    select 1 from drops d where d.id = drop_id and d.status = 'ACTIVE' and d.launch_at <= now()));
create policy drop_products_staff_all on drop_products
  for all using (is_staff()) with check (has_role('ADMIN'));

-- Anyone may ask to be reminded; only staff may read the list.
create policy drop_reminders_insert on drop_reminders for insert with check (true);
create policy drop_reminders_staff_read on drop_reminders for select using (is_staff());

create policy newsletter_insert on newsletter_subscribers for insert with check (true);
create policy newsletter_staff_read on newsletter_subscribers for select using (is_staff());

-- Promotions are readable so the storefront can preview pricing; the engine's
-- authoritative pass still runs server-side at checkout (§79).
create policy promotions_public_read on promotions
  for select using (status = 'ACTIVE' and archived_at is null);
create policy promotions_staff_all on promotions
  for all using (is_staff()) with check (has_role('ADMIN'));
create policy promotion_products_read on promotion_products for select using (true);
create policy promotion_products_staff on promotion_products
  for all using (is_staff()) with check (has_role('ADMIN'));
create policy promotion_collections_read on promotion_collections for select using (true);
create policy promotion_collections_staff on promotion_collections
  for all using (is_staff()) with check (has_role('ADMIN'));
create policy promotion_categories_read on promotion_categories for select using (true);
create policy promotion_categories_staff on promotion_categories
  for all using (is_staff()) with check (has_role('ADMIN'));

-- ---------------------------------------------------------------------------
-- Inventory — availability is public, exact counts are not
-- ---------------------------------------------------------------------------
create policy inventory_locations_public_read on inventory_locations
  for select using (archived_at is null);
create policy inventory_locations_staff_all on inventory_locations
  for all using (is_staff()) with check (has_role('ADMIN'));

-- Deliberately no public policy on `inventory`: quantities are exposed only
-- through a view/RPC that returns availability, so competitors cannot scrape
-- stock levels (§21).
create policy inventory_staff_read on inventory for select using (is_staff());
create policy inventory_staff_write on inventory
  for all using (has_role('STAFF')) with check (has_role('STAFF'));

-- ---------------------------------------------------------------------------
-- Customers and their own data
-- ---------------------------------------------------------------------------
create policy customers_self on customers
  for select using (auth_id = auth.uid() or is_staff());
create policy customers_self_update on customers
  for update using (auth_id = auth.uid()) with check (auth_id = auth.uid());
create policy customers_staff_manage on customers
  for all using (has_role('ADMIN')) with check (has_role('ADMIN'));

create policy addresses_self on addresses
  for all
  using (exists (select 1 from customers c where c.id = customer_id and c.auth_id = auth.uid()) or is_staff())
  with check (exists (select 1 from customers c where c.id = customer_id and c.auth_id = auth.uid()));

create policy carts_self on carts
  for all
  using (customer_id is null or exists (
          select 1 from customers c where c.id = customer_id and c.auth_id = auth.uid()) or is_staff())
  with check (customer_id is null or exists (
          select 1 from customers c where c.id = customer_id and c.auth_id = auth.uid()));

create policy cart_items_self on cart_items
  for all
  using (exists (select 1 from carts ct where ct.id = cart_id
                 and (ct.customer_id is null
                      or exists (select 1 from customers c where c.id = ct.customer_id and c.auth_id = auth.uid()))))
  with check (exists (select 1 from carts ct where ct.id = cart_id
                 and (ct.customer_id is null
                      or exists (select 1 from customers c where c.id = ct.customer_id and c.auth_id = auth.uid()))));

create policy wishlists_self on wishlists
  for all
  using (customer_id is null or exists (
          select 1 from customers c where c.id = customer_id and c.auth_id = auth.uid()) or is_staff())
  with check (customer_id is null or exists (
          select 1 from customers c where c.id = customer_id and c.auth_id = auth.uid()));

create policy wishlist_items_self on wishlist_items
  for all
  using (exists (select 1 from wishlists w where w.id = wishlist_id
                 and (w.customer_id is null
                      or exists (select 1 from customers c where c.id = w.customer_id and c.auth_id = auth.uid()))))
  with check (exists (select 1 from wishlists w where w.id = wishlist_id
                 and (w.customer_id is null
                      or exists (select 1 from customers c where c.id = w.customer_id and c.auth_id = auth.uid()))));

create policy recently_viewed_self on recently_viewed
  for all
  using (exists (select 1 from customers c where c.id = customer_id and c.auth_id = auth.uid()))
  with check (exists (select 1 from customers c where c.id = customer_id and c.auth_id = auth.uid()));

-- Anyone may register interest in a sold-out size; only staff read the demand.
create policy bis_insert on back_in_stock_requests for insert with check (true);
create policy bis_staff_read on back_in_stock_requests for select using (is_staff());
create policy bis_staff_write on back_in_stock_requests
  for update using (has_role('MANAGER')) with check (has_role('MANAGER'));

-- ---------------------------------------------------------------------------
-- Orders
-- Orders are created by trusted server code (service_role) after the server has
-- recalculated pricing and reserved stock — never inserted straight from a
-- browser, which is why there is no public insert policy here.
-- ---------------------------------------------------------------------------
create policy orders_self_read on orders
  for select using (
    is_staff() or exists (
      select 1 from customers c where c.id = customer_id and c.auth_id = auth.uid()));
create policy orders_staff_write on orders
  for all using (has_role('STAFF')) with check (has_role('STAFF'));

create policy order_items_read on order_items
  for select using (exists (
    select 1 from orders o where o.id = order_id
      and (is_staff() or exists (select 1 from customers c where c.id = o.customer_id and c.auth_id = auth.uid()))));
create policy order_items_staff_write on order_items
  for all using (has_role('STAFF')) with check (has_role('STAFF'));

create policy order_events_read on order_events
  for select using (exists (
    select 1 from orders o where o.id = order_id
      and (is_staff() or exists (select 1 from customers c where c.id = o.customer_id and c.auth_id = auth.uid()))));
create policy order_events_staff_write on order_events
  for all using (has_role('STAFF')) with check (has_role('STAFF'));

create policy returns_self_read on returns
  for select using (exists (
    select 1 from orders o where o.id = order_id
      and (is_staff() or exists (select 1 from customers c where c.id = o.customer_id and c.auth_id = auth.uid()))));
create policy returns_staff_write on returns
  for all using (has_role('STAFF')) with check (has_role('STAFF'));

-- ---------------------------------------------------------------------------
-- Operations — staff only
-- ---------------------------------------------------------------------------
-- Storefront events are written through a server route that validates and rate
-- limits them, so no anonymous insert policy is granted here.
create policy analytics_staff_read on analytics_events for select using (is_staff());
create policy notifications_staff_read on notifications for select using (is_staff());
create policy notifications_staff_write on notifications
  for update using (is_staff()) with check (is_staff());

-- The audit trail is append-only from the application's perspective: readable
-- by owners, never updatable or deletable by any client role.
create policy audit_logs_owner_read on audit_logs for select using (has_role('ADMIN'));
create policy revisions_staff_read on content_revisions for select using (is_staff());
create policy revisions_staff_write on content_revisions
  for insert with check (is_staff());
