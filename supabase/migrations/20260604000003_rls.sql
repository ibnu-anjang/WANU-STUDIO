-- WANU — Row Level Security (lihat docs/TRD.md §7)
-- Prinsip: data publik bisa dibaca, tulis hanya oleh pemilik.
-- Operasi sensitif (buat order, ubah status bayar, decrement stok) dijalankan
-- lewat Edge Function pakai service_role yang BYPASS RLS — bukan langsung dari client.

alter table profiles            enable row level security;
alter table stores              enable row level security;
alter table addresses           enable row level security;
alter table categories          enable row level security;
alter table products            enable row level security;
alter table product_variants    enable row level security;
alter table product_images      enable row level security;
alter table videos              enable row level security;
alter table video_product_tags  enable row level security;
alter table video_likes         enable row level security;
alter table video_comments      enable row level security;
alter table follows             enable row level security;
alter table cart_items          enable row level security;
alter table orders              enable row level security;
alter table order_items         enable row level security;
alter table payments            enable row level security;
alter table reviews             enable row level security;

-- ── profiles ───────────────────────────────────────────────────────────
create policy "profiles read all"     on profiles for select using (true);
create policy "profiles update self"  on profiles for update using (id = auth.uid());

-- ── stores ─────────────────────────────────────────────────────────────
create policy "stores read all"       on stores for select using (true);
create policy "stores insert own"     on stores for insert with check (owner_id = auth.uid());
create policy "stores update own"     on stores for update using (owner_id = auth.uid());

-- ── addresses (privat) ─────────────────────────────────────────────────
create policy "addresses own"         on addresses for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ── categories (read publik; tulis admin via service_role) ─────────────
create policy "categories read all"   on categories for select using (true);

-- ── products ───────────────────────────────────────────────────────────
create policy "products read all"     on products for select using (true);
create policy "products write owner"  on products for all
  using (is_store_owner(store_id)) with check (is_store_owner(store_id));

-- ── product_variants ───────────────────────────────────────────────────
create policy "variants read all"     on product_variants for select using (true);
create policy "variants write owner"  on product_variants for all
  using (exists (select 1 from products p where p.id = product_id and is_store_owner(p.store_id)))
  with check (exists (select 1 from products p where p.id = product_id and is_store_owner(p.store_id)));

-- ── product_images ─────────────────────────────────────────────────────
create policy "images read all"       on product_images for select using (true);
create policy "images write owner"    on product_images for all
  using (exists (select 1 from products p where p.id = product_id and is_store_owner(p.store_id)))
  with check (exists (select 1 from products p where p.id = product_id and is_store_owner(p.store_id)));

-- ── videos ─────────────────────────────────────────────────────────────
create policy "videos read ready"     on videos for select
  using (status = 'ready' or creator_id = auth.uid());
create policy "videos write owner"    on videos for all
  using (creator_id = auth.uid()) with check (creator_id = auth.uid());

-- ── video_product_tags ─────────────────────────────────────────────────
create policy "vtags read all"        on video_product_tags for select using (true);
create policy "vtags write owner"     on video_product_tags for all
  using (exists (select 1 from videos v where v.id = video_id and v.creator_id = auth.uid()))
  with check (exists (select 1 from videos v where v.id = video_id and v.creator_id = auth.uid()));

-- ── video_likes ────────────────────────────────────────────────────────
create policy "likes read all"        on video_likes for select using (true);
create policy "likes write self"      on video_likes for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ── video_comments ─────────────────────────────────────────────────────
create policy "comments read all"     on video_comments for select using (true);
create policy "comments insert self"  on video_comments for insert with check (user_id = auth.uid());
create policy "comments delete self"  on video_comments for delete using (user_id = auth.uid());

-- ── follows ────────────────────────────────────────────────────────────
create policy "follows read all"      on follows for select using (true);
create policy "follows write self"    on follows for all
  using (follower_id = auth.uid()) with check (follower_id = auth.uid());

-- ── cart_items (privat) ────────────────────────────────────────────────
create policy "cart own"              on cart_items for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ── orders (buyer pemilik ATAU seller terkait; baca saja dari client) ──
create policy "orders read involved"  on orders for select
  using (buyer_id = auth.uid() or is_store_owner(store_id));
create policy "orders seller update status" on orders for update
  using (is_store_owner(store_id));
-- INSERT order & ubah ke 'paid' hanya via Edge Function (service_role).

-- ── order_items ────────────────────────────────────────────────────────
create policy "order_items read involved" on order_items for select
  using (exists (
    select 1 from orders o where o.id = order_id
      and (o.buyer_id = auth.uid() or is_store_owner(o.store_id))
  ));

-- ── payments (baca pihak terkait; tulis hanya service_role) ────────────
create policy "payments read involved" on payments for select
  using (exists (
    select 1 from orders o where o.id = order_id
      and (o.buyer_id = auth.uid() or is_store_owner(o.store_id))
  ));

-- ── reviews ────────────────────────────────────────────────────────────
create policy "reviews read all"      on reviews for select using (true);
create policy "reviews write self"    on reviews for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
