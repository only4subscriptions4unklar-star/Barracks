-- ============================================================================
-- BARRACKS — migration of existing prototype content (brief §74)
-- ----------------------------------------------------------------------------
-- The ten pieces, their colourways, sizes, fabrics and copy already written for
-- the prototype are loaded here so the owner never re-enters them by hand.
--
-- What this file deliberately does NOT contain: invented stock counts, review
-- text, ratings or order history. Per §72 nothing fabricated is presented as
-- real — inventory starts at zero and is set by the owner in Admin, and every
-- product ships as DRAFT so nothing goes public until it has been checked and
-- photographed.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Structure
-- ---------------------------------------------------------------------------
insert into categories (id, slug, name, position) values
  ('a0000000-0000-4000-8000-000000000001', 'trousers',  'Trousers',      1),
  ('a0000000-0000-4000-8000-000000000002', 'shirting',  'Shirting',      2),
  ('a0000000-0000-4000-8000-000000000003', 'tees',      'Tees & Polos',  3),
  ('a0000000-0000-4000-8000-000000000004', 'outerwear', 'Outerwear',     4)
on conflict (slug) do nothing;

insert into collections (id, slug, name, intro, position, is_featured) values
  ('b0000000-0000-4000-8000-000000000001', 'ss26', 'Standard Issue SS26',
   'The season, entire — cut for the island.', 1, true),
  ('b0000000-0000-4000-8000-000000000002', 'standard-offer', 'The Standard Offer',
   'Any two trousers, Rs 5,000. Compose your pair.', 2, true)
on conflict (slug) do nothing;

insert into inventory_locations (id, code, name, is_online) values
  ('c0000000-0000-4000-8000-000000000001', 'KOHUWALA', 'Kohuwala',        false),
  ('c0000000-0000-4000-8000-000000000002', 'DEHIWALA', 'Dehiwala',        false),
  ('c0000000-0000-4000-8000-000000000003', 'ONLINE',   'Online warehouse', true)
on conflict (code) do nothing;

insert into stores (slug, name, address_line, city, phone, whatsapp, opening_hours,
                    map_embed_url, map_link_url, location_id, position)
values
  ('kohuwala', 'Kohuwala', '105 Dutugemunu Street', 'Kohuwala', '077 065 7669', '94770657669',
   'Open daily · 10:30–20:30',
   'https://maps.google.com/maps?q=Barracks%20Clothing%2C%20105%20Dutugemunu%20Street%2C%20Kohuwala%2C%20Sri%20Lanka&z=16&output=embed',
   'https://maps.app.goo.gl/h55XCDHyp8iNQaFo6',
   'c0000000-0000-4000-8000-000000000001', 1),
  ('dehiwala', 'Dehiwala', '75 Nikape Road', 'Dehiwala', '077 065 7669', '94770657669',
   'Open daily · 10:30–20:30',
   'https://maps.google.com/maps?q=Barracks%20Clothing%2C%2075%20Nikape%20Road%2C%20Dehiwala%2C%20Sri%20Lanka&z=16&output=embed',
   'https://www.google.com/maps/search/?api=1&query=Barracks+Clothing+75+Nikape+Road+Dehiwala',
   'c0000000-0000-4000-8000-000000000002', 2)
on conflict (slug) do nothing;

-- ---------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------
insert into products (id, slug, name, category_id, fabric, fit, care, price_minor,
                      short_description, long_description, status, promotion_eligible, position)
values
  ('d0000000-0000-4000-8000-000000000001', 'golf-chino-trouser', 'The Golf Chino Trouser',
   'a0000000-0000-4000-8000-000000000001', 'Stretch cotton twill', 'Relaxed taper', 'Cold wash, hang dry', 275000,
   'The trouser the Standard Offer was composed around.',
   'A clean flat front, deep pockets and precisely enough stretch to carry a long day — the boardroom at nine, Galle Face by sunset.',
   'DRAFT', true, 1),
  ('d0000000-0000-4000-8000-000000000002', 'pure-linen-trouser', 'The Pure Linen Trouser',
   'a0000000-0000-4000-8000-000000000001', '100% linen', 'Straight, mid-rise', 'Gentle wash, low iron', 295000,
   'Colombo-weather linen.',
   'It breathes at noon and remains composed at the evening reception. Cut straight with a mid-rise so the cloth drapes rather than clings.',
   'DRAFT', true, 2),
  ('d0000000-0000-4000-8000-000000000003', 'wide-fold-trouser', 'The Wide Fold Trouser',
   'a0000000-0000-4000-8000-000000000001', 'Heavy 320gsm cotton', 'Wide, deep-fold hem', 'Cold wash inside-out', 320000,
   'The wide silhouette from the drops.',
   'Heavyweight cotton, a deep folded hem and a stacked break that falls exactly as it does on film.',
   'DRAFT', true, 3),
  ('d0000000-0000-4000-8000-000000000004', 'technical-trouser', 'The Technical Trouser',
   'a0000000-0000-4000-8000-000000000001', 'Water-repellent shell', 'Tapered, elastic cuff', 'Machine wash cold', 240000,
   'A taper for the monsoon.',
   'A light water-repellent shell that shrugs off drizzle, zipped pockets that keep a phone secure, and a cuff that stays clear of the chain.',
   'DRAFT', true, 4),
  ('d0000000-0000-4000-8000-000000000005', 'oversized-tee', 'The Oversized Tee',
   'a0000000-0000-4000-8000-000000000003', '220gsm combed cotton', 'Oversized, drop shoulder', 'Cold wash, no tumble', 195000,
   'The heavyweight boxy tee.',
   'Cut two sizes generous with a dropped shoulder, in 220gsm cotton that hangs perfectly straight and never turns sheer.',
   'DRAFT', true, 5),
  ('d0000000-0000-4000-8000-000000000006', 'performance-crew', 'The Performance Crew',
   'a0000000-0000-4000-8000-000000000003', 'Performance micro-poly', 'Athletic', 'Quick-dry, machine wash', 145000,
   'The original Barracks piece.',
   'The dry-fit crew the house was founded on. Feather-light, sweat-wicking, and priced to be bought in threes.',
   'DRAFT', true, 6),
  ('d0000000-0000-4000-8000-000000000007', 'pique-polo', 'The Piqué Polo',
   'a0000000-0000-4000-8000-000000000003', 'Cotton piqué', 'Regular', 'Cold wash', 215000,
   'Composed at the office, easy everywhere after.',
   'A tight piqué knit whose collar does not surrender by lunchtime.',
   'DRAFT', true, 7),
  ('d0000000-0000-4000-8000-000000000008', 'cuban-collar-shirt', 'The Cuban Collar Shirt',
   'a0000000-0000-4000-8000-000000000002', 'Fluid viscose', 'Relaxed', 'Gentle wash, drip dry', 345000,
   'The evening shirt.',
   'An open Cuban collar and a fluid drape that moves — composed for Colombo nights when the air conditioning concedes.',
   'DRAFT', true, 8),
  ('d0000000-0000-4000-8000-000000000009', 'band-collar-shirt', 'The Band Collar Shirt',
   'a0000000-0000-4000-8000-000000000002', 'Cotton poplin', 'Slim', 'Warm iron', 325000,
   'A band collar, no fuss.',
   'Buttoned to the neck for the formal hour, sleeves rolled for every hour after — from a poya-day lunch to a Monday meeting.',
   'DRAFT', true, 9),
  ('d0000000-0000-4000-8000-000000000010', 'varsity-jacket', 'The Varsity Jacket',
   'a0000000-0000-4000-8000-000000000004', 'Felt body, PU sleeves', 'Boxy', 'Spot clean', 590000,
   'The piece that sells out on film.',
   'A structured felt body, contrast sleeves and ribbed trims — cut boxy to layer over anything.',
   'DRAFT', false, 10)
on conflict (slug) do nothing;

-- Every piece belongs to the season; trousers additionally to the offer collection.
insert into product_collections (product_id, collection_id)
select id, 'b0000000-0000-4000-8000-000000000001' from products
on conflict do nothing;

insert into product_collections (product_id, collection_id)
select id, 'b0000000-0000-4000-8000-000000000002' from products
where category_id = 'a0000000-0000-4000-8000-000000000001' and promotion_eligible
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- Colourways
-- ---------------------------------------------------------------------------
insert into product_variants (product_id, colour_name, colour_hex, position)
values
  ('d0000000-0000-4000-8000-000000000001','Olive','#4A5240',1),
  ('d0000000-0000-4000-8000-000000000001','Khaki','#B3A886',2),
  ('d0000000-0000-4000-8000-000000000001','Black','#26282A',3),
  ('d0000000-0000-4000-8000-000000000001','Navy','#2E3A4A',4),
  ('d0000000-0000-4000-8000-000000000002','Natural','#C9BB98',1),
  ('d0000000-0000-4000-8000-000000000002','Sand','#B8A582',2),
  ('d0000000-0000-4000-8000-000000000002','Black','#26282A',3),
  ('d0000000-0000-4000-8000-000000000003','Grey Marl','#7D7A72',1),
  ('d0000000-0000-4000-8000-000000000003','Stone','#A39D8D',2),
  ('d0000000-0000-4000-8000-000000000003','Black','#26282A',3),
  ('d0000000-0000-4000-8000-000000000004','Black','#26282A',1),
  ('d0000000-0000-4000-8000-000000000004','Graphite','#4A4E4C',2),
  ('d0000000-0000-4000-8000-000000000005','Off-White','#CFCBBE',1),
  ('d0000000-0000-4000-8000-000000000005','Black','#26282A',2),
  ('d0000000-0000-4000-8000-000000000005','Olive','#4A5240',3),
  ('d0000000-0000-4000-8000-000000000005','Washed Blue','#5A6C7E',4),
  ('d0000000-0000-4000-8000-000000000006','Black','#26282A',1),
  ('d0000000-0000-4000-8000-000000000006','White','#CFCBBE',2),
  ('d0000000-0000-4000-8000-000000000006','Maroon','#6B3238',3),
  ('d0000000-0000-4000-8000-000000000007','Olive','#4A5240',1),
  ('d0000000-0000-4000-8000-000000000007','Navy','#2E3A4A',2),
  ('d0000000-0000-4000-8000-000000000007','Stone','#A39D8D',3),
  ('d0000000-0000-4000-8000-000000000008','Sage','#97A08A',1),
  ('d0000000-0000-4000-8000-000000000008','Cream','#C4B999',2),
  ('d0000000-0000-4000-8000-000000000008','Black','#26282A',3),
  ('d0000000-0000-4000-8000-000000000009','White','#CFCBBE',1),
  ('d0000000-0000-4000-8000-000000000009','Black','#26282A',2),
  ('d0000000-0000-4000-8000-000000000009','Olive','#4A5240',3),
  ('d0000000-0000-4000-8000-000000000010','Black/Cream','#26282A',1),
  ('d0000000-0000-4000-8000-000000000010','Wine','#6B3238',2),
  ('d0000000-0000-4000-8000-000000000010','Navy','#2E3A4A',3)
on conflict (product_id, colour_name) do nothing;

-- ---------------------------------------------------------------------------
-- Sizes — waist sizing for trousers, alpha sizing for everything else
-- ---------------------------------------------------------------------------
insert into product_sizes (variant_id, label, position)
select v.id, s.label, s.position
from product_variants v
join products p on p.id = v.product_id
cross join lateral (
  select * from (values ('28',1),('30',2),('32',3),('34',4),('36',5),('38',6)) as t(label, position)
) s
where p.category_id = 'a0000000-0000-4000-8000-000000000001'
  and p.slug <> 'technical-trouser'
on conflict do nothing;

insert into product_sizes (variant_id, label, position)
select v.id, s.label, s.position
from product_variants v
join products p on p.id = v.product_id
cross join lateral (
  select * from (values ('S',1),('M',2),('L',3),('XL',4),('XXL',5)) as t(label, position)
) s
where p.category_id <> 'a0000000-0000-4000-8000-000000000001'
   or p.slug = 'technical-trouser'
on conflict do nothing;

-- Stock rows exist at zero for every size in every location; the owner sets the
-- real numbers in Admin. Zero is honest — an invented count is not.
insert into inventory (size_id, location_id, on_hand)
select s.id, l.id, 0
from product_sizes s cross join inventory_locations l
on conflict (size_id, location_id) do nothing;

-- ---------------------------------------------------------------------------
-- The Standard Offer, as data
-- ---------------------------------------------------------------------------
insert into promotions (id, name, customer_message, rule_kind, rule_config, status,
                        stackable, priority, internal_note)
values
  ('e0000000-0000-4000-8000-000000000001', 'The Standard Offer',
   'Any two trousers · Rs 5,000',
   'BUNDLE_FIXED_PRICE',
   '{"quantity": 2, "bundlePriceMinor": 500000}'::jsonb,
   'ACTIVE', false, 10,
   'The signature Barracks bundle. Edit the price or pause it here — never in code.'),
  ('e0000000-0000-4000-8000-000000000002', 'Complimentary island-wide delivery',
   'Complimentary island-wide delivery above Rs 7,500',
   'FREE_SHIPPING',
   '{"minSpendMinor": 750000}'::jsonb,
   'ACTIVE', true, 100,
   'Free-delivery threshold. Changing this updates the cart progress bar automatically.')
on conflict (id) do nothing;

insert into promotion_categories (promotion_id, category_id) values
  ('e0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001')
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- Homepage composition and global settings
-- ---------------------------------------------------------------------------
insert into homepage_sections (kind, position, config) values
  ('HERO',            1, '{}'::jsonb),
  ('TEXT_STATEMENT',  2, '{"eyebrow":"The House of Barracks","body":"Cut for the island, held to a standard — trousers, shirting and essentials from Dutugemunu Street, worn from Colombo boardrooms to Galle Face at dusk."}'::jsonb),
  ('COLLECTION_GRID', 3, '{"title":"The Collections"}'::jsonb),
  ('PRODUCT_RAIL',    4, '{"title":"Latest Pieces","source":"new_arrivals"}'::jsonb),
  ('STANDARD_OFFER',  5, '{"promotionId":"e0000000-0000-4000-8000-000000000001"}'::jsonb),
  ('EDITORIAL_SPLIT', 6, '{"title":"A neighbourhood house, kept to a standard"}'::jsonb),
  ('SERVICES',        7, '{}'::jsonb),
  ('SOCIAL',          8, '{"handle":"@barracksclothing"}'::jsonb),
  ('STORE_FEATURE',   9, '{}'::jsonb),
  ('NEWSLETTER',     10, '{}'::jsonb)
on conflict do nothing;

insert into site_settings (key, value) values
  ('brand',    '{"name":"Barracks","tagline":"Always different. That''s the standard."}'::jsonb),
  ('contact',  '{"whatsapp":"94770657669","phone":"077 065 7669","email":"barrackslk@gmail.com"}'::jsonb),
  ('social',   '{"tiktok":"https://www.tiktok.com/@barracksclothing","instagram":"https://www.instagram.com/barracksclothing/","facebook":"https://www.facebook.com/barracks.lk/"}'::jsonb),
  ('commerce', '{"currency":"LKR","freeShippingThresholdMinor":750000,"codEnabled":true,"storePickupEnabled":false,"orderPrefix":"BRK"}'::jsonb),
  ('seo',      '{"title":"Barracks — Fine Menswear of Kohuwala & Dehiwala","description":"Trousers, shirting and essentials cut for the island, delivered across Sri Lanka."}'::jsonb)
on conflict (key) do nothing;
