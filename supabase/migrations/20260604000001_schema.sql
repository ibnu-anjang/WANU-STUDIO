-- WANU — schema awal (lihat docs/ERD.md)
-- Money disimpan sebagai bigint dalam rupiah (smallest unit, tanpa sen).

create extension if not exists "pgcrypto";

-- ── Enums ──────────────────────────────────────────────────────────────
create type user_role     as enum ('buyer', 'seller', 'admin');
create type video_status   as enum ('processing', 'ready', 'failed');
create type order_status   as enum ('pending', 'paid', 'processing', 'shipped', 'completed', 'cancelled', 'expired');
create type payment_status as enum ('pending', 'settlement', 'capture', 'deny', 'expire', 'cancel');

-- ── profiles (extends auth.users) ──────────────────────────────────────
create table profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  username     text unique,
  display_name text,
  avatar_url   text,
  bio          text,
  role         user_role not null default 'buyer',
  created_at   timestamptz not null default now()
);

-- ── stores ─────────────────────────────────────────────────────────────
create table stores (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null unique references profiles (id) on delete cascade,
  name        text not null,
  slug        text not null unique,
  logo_url    text,
  description text,
  is_verified boolean not null default false,
  created_at  timestamptz not null default now()
);

-- ── addresses ──────────────────────────────────────────────────────────
create table addresses (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references profiles (id) on delete cascade,
  recipient_name text not null,
  phone          text not null,
  line1          text not null,
  city           text not null,
  province       text not null,
  postal_code    text not null,
  is_default     boolean not null default false
);

-- ── categories (nested) ────────────────────────────────────────────────
create table categories (
  id        uuid primary key default gen_random_uuid(),
  parent_id uuid references categories (id) on delete set null,
  name      text not null,
  slug      text not null unique
);

-- ── products ───────────────────────────────────────────────────────────
create table products (
  id          uuid primary key default gen_random_uuid(),
  store_id    uuid not null references stores (id) on delete cascade,
  category_id uuid references categories (id) on delete set null,
  title       text not null,
  description text,
  base_price  bigint not null check (base_price >= 0),
  is_active   boolean not null default true,
  search_tsv  tsvector generated always as (
    to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(description, ''))
  ) stored,
  created_at  timestamptz not null default now()
);

-- ── product_variants (sumber harga & stok sebenarnya) ──────────────────
create table product_variants (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references products (id) on delete cascade,
  name       text not null,
  sku        text,
  price      bigint not null check (price >= 0),
  stock      integer not null default 0 check (stock >= 0)
);

-- ── product_images ─────────────────────────────────────────────────────
create table product_images (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references products (id) on delete cascade,
  url        text not null,
  sort_order integer not null default 0
);

-- ── videos (short-form feed) ───────────────────────────────────────────
create table videos (
  id               uuid primary key default gen_random_uuid(),
  creator_id       uuid not null references profiles (id) on delete cascade,
  store_id         uuid references stores (id) on delete set null,
  caption          text,
  cf_playback_id   text,
  cf_thumbnail_url text,
  duration_sec     integer check (duration_sec is null or duration_sec <= 90),
  status           video_status not null default 'processing',
  like_count       integer not null default 0,
  comment_count    integer not null default 0,
  created_at       timestamptz not null default now()
);

-- ── video_product_tags (M:N video ↔ product) ───────────────────────────
create table video_product_tags (
  video_id   uuid not null references videos (id) on delete cascade,
  product_id uuid not null references products (id) on delete cascade,
  primary key (video_id, product_id)
);

-- ── video_likes ────────────────────────────────────────────────────────
create table video_likes (
  video_id   uuid not null references videos (id) on delete cascade,
  user_id    uuid not null references profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (video_id, user_id)
);

-- ── video_comments ─────────────────────────────────────────────────────
create table video_comments (
  id         uuid primary key default gen_random_uuid(),
  video_id   uuid not null references videos (id) on delete cascade,
  user_id    uuid not null references profiles (id) on delete cascade,
  body       text not null,
  created_at timestamptz not null default now()
);

-- ── follows (user → store) ─────────────────────────────────────────────
create table follows (
  follower_id uuid not null references profiles (id) on delete cascade,
  store_id    uuid not null references stores (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (follower_id, store_id)
);

-- ── cart_items ─────────────────────────────────────────────────────────
create table cart_items (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references profiles (id) on delete cascade,
  variant_id uuid not null references product_variants (id) on delete cascade,
  quantity   integer not null check (quantity >= 1),
  unique (user_id, variant_id)
);

-- ── orders ─────────────────────────────────────────────────────────────
create table orders (
  id                uuid primary key default gen_random_uuid(),
  buyer_id          uuid not null references profiles (id) on delete restrict,
  store_id          uuid not null references stores (id) on delete restrict,
  address_id        uuid references addresses (id) on delete set null,
  status            order_status not null default 'pending',
  subtotal          bigint not null default 0,
  shipping_fee      bigint not null default 0,
  total             bigint not null default 0,
  midtrans_order_id text unique,
  created_at        timestamptz not null default now()
);

-- ── order_items (snapshot harga saat beli) ─────────────────────────────
create table order_items (
  id            uuid primary key default gen_random_uuid(),
  order_id      uuid not null references orders (id) on delete cascade,
  variant_id    uuid references product_variants (id) on delete set null,
  product_title text not null,
  variant_name  text not null,
  unit_price    bigint not null,
  quantity      integer not null check (quantity >= 1)
);

-- ── payments ───────────────────────────────────────────────────────────
create table payments (
  id             uuid primary key default gen_random_uuid(),
  order_id       uuid not null unique references orders (id) on delete cascade,
  provider       text not null default 'midtrans',
  snap_token     text,
  transaction_id text,
  payment_type   text,
  gross_amount   bigint not null,
  status         payment_status not null default 'pending',
  raw_payload    jsonb,
  paid_at        timestamptz
);

-- ── reviews ────────────────────────────────────────────────────────────
create table reviews (
  id            uuid primary key default gen_random_uuid(),
  order_item_id uuid not null unique references order_items (id) on delete cascade,
  product_id    uuid not null references products (id) on delete cascade,
  user_id       uuid not null references profiles (id) on delete cascade,
  rating        integer not null check (rating between 1 and 5),
  comment       text,
  created_at    timestamptz not null default now()
);

-- ── Indexes ────────────────────────────────────────────────────────────
create index idx_products_search   on products using gin (search_tsv);
create index idx_products_store     on products (store_id);
create index idx_videos_feed        on videos (status, created_at desc);
create index idx_video_tags_product on video_product_tags (product_id);
create index idx_order_items_order   on order_items (order_id);
create index idx_orders_buyer        on orders (buyer_id);
create index idx_orders_store        on orders (store_id);
create index idx_cart_user           on cart_items (user_id);
create index idx_variants_product    on product_variants (product_id);
create index idx_comments_video      on video_comments (video_id);
