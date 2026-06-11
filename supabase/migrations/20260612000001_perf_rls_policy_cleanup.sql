-- WANU — bereskan temuan advisor (security + performance), pra-deploy.
-- 1. Drop policy UPDATE orders langsung — transisi status hanya via RPC
--    set_order_status (SECURITY DEFINER, tidak butuh policy ini).
-- 2. auth_rls_initplan: bungkus auth.uid()/is_admin() jadi (select ...) agar
--    dievaluasi sekali per query, bukan per baris.
-- 3. multiple_permissive_policies: pecah policy FOR ALL jadi insert/update/delete
--    supaya tidak tumpang tindih dengan policy SELECT "read all".
-- 4. unindexed_foreign_keys: tambah covering index untuk semua FK.

-- ── 1. orders: hapus jalur update langsung ──────────────────────────────
drop policy if exists "orders admin update status" on orders;

-- ── 2+3. profiles ───────────────────────────────────────────────────────
drop policy if exists "profiles update self" on profiles;
create policy "profiles update self" on profiles for update
  using (id = (select auth.uid()));

-- KRITIS: tanpa ini user bisa set role='admin' di barisnya sendiri (RLS
-- "update self" tidak membatasi kolom). Batasi UPDATE ke kolom profil saja;
-- role hanya berubah via promote_to_admin (SECURITY DEFINER, bypass grant).
revoke update on profiles from authenticated;
grant update (username, display_name, avatar_url, bio) on profiles to authenticated;

-- ── addresses (policy tunggal, cukup wrap) ──────────────────────────────
drop policy if exists "addresses own" on addresses;
create policy "addresses own" on addresses for all
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- ── cart_items (policy tunggal, cukup wrap) ─────────────────────────────
drop policy if exists "cart own" on cart_items;
create policy "cart own" on cart_items for all
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- ── products / variants / images: pecah FOR ALL admin ───────────────────
drop policy if exists "products write admin" on products;
create policy "products admin insert" on products for insert
  with check ((select is_admin()));
create policy "products admin update" on products for update
  using ((select is_admin()));
create policy "products admin delete" on products for delete
  using ((select is_admin()));

drop policy if exists "variants write admin" on product_variants;
create policy "variants admin insert" on product_variants for insert
  with check ((select is_admin()));
create policy "variants admin update" on product_variants for update
  using ((select is_admin()));
create policy "variants admin delete" on product_variants for delete
  using ((select is_admin()));

drop policy if exists "images write admin" on product_images;
create policy "images admin insert" on product_images for insert
  with check ((select is_admin()));
create policy "images admin update" on product_images for update
  using ((select is_admin()));
create policy "images admin delete" on product_images for delete
  using ((select is_admin()));

-- ── videos: FOR ALL admin dulunya juga memberi SELECT semua status ke
--    admin (dipakai Kelola Feed). Pertahankan lewat policy read. ─────────
drop policy if exists "videos read ready" on videos;
create policy "videos read ready" on videos for select
  using (
    status = 'ready'
    or creator_id = (select auth.uid())
    or (select is_admin())
  );

drop policy if exists "videos write admin" on videos;
create policy "videos admin insert" on videos for insert
  with check ((select is_admin()));
create policy "videos admin update" on videos for update
  using ((select is_admin()));
create policy "videos admin delete" on videos for delete
  using ((select is_admin()));

drop policy if exists "vtags write admin" on video_product_tags;
create policy "vtags admin insert" on video_product_tags for insert
  with check ((select is_admin()));
create policy "vtags admin update" on video_product_tags for update
  using ((select is_admin()));
create policy "vtags admin delete" on video_product_tags for delete
  using ((select is_admin()));

-- ── video_likes: pecah FOR ALL self ─────────────────────────────────────
drop policy if exists "likes write self" on video_likes;
create policy "likes insert self" on video_likes for insert
  with check (user_id = (select auth.uid()));
create policy "likes delete self" on video_likes for delete
  using (user_id = (select auth.uid()));

-- ── video_comments ──────────────────────────────────────────────────────
drop policy if exists "comments insert self" on video_comments;
create policy "comments insert self" on video_comments for insert
  with check (user_id = (select auth.uid()));
drop policy if exists "comments delete self" on video_comments;
create policy "comments delete self" on video_comments for delete
  using (user_id = (select auth.uid()));

-- ── follows: pecah FOR ALL self ─────────────────────────────────────────
drop policy if exists "follows write self" on follows;
create policy "follows insert self" on follows for insert
  with check (follower_id = (select auth.uid()));
create policy "follows delete self" on follows for delete
  using (follower_id = (select auth.uid()));

-- ── orders / order_items / payments: wrap uid + is_admin ────────────────
drop policy if exists "orders read involved" on orders;
create policy "orders read involved" on orders for select
  using (buyer_id = (select auth.uid()) or (select is_admin()));

drop policy if exists "order_items read involved" on order_items;
create policy "order_items read involved" on order_items for select
  using (exists (
    select 1 from orders o where o.id = order_id
      and (o.buyer_id = (select auth.uid()) or (select is_admin()))
  ));

drop policy if exists "payments read involved" on payments;
create policy "payments read involved" on payments for select
  using (exists (
    select 1 from orders o where o.id = order_id
      and (o.buyer_id = (select auth.uid()) or (select is_admin()))
  ));

-- ── 4. covering index untuk FK ──────────────────────────────────────────
create index if not exists idx_addresses_user        on addresses (user_id);
create index if not exists idx_cart_items_variant    on cart_items (variant_id);
create index if not exists idx_categories_parent     on categories (parent_id);
create index if not exists idx_follows_store         on follows (store_id);
create index if not exists idx_order_items_variant   on order_items (variant_id);
create index if not exists idx_orders_address        on orders (address_id);
create index if not exists idx_product_images_product on product_images (product_id);
create index if not exists idx_products_category     on products (category_id);
create index if not exists idx_reviews_product       on reviews (product_id);
create index if not exists idx_reviews_user          on reviews (user_id);
create index if not exists idx_video_comments_user   on video_comments (user_id);
create index if not exists idx_video_likes_user      on video_likes (user_id);
create index if not exists idx_videos_creator        on videos (creator_id);
create index if not exists idx_videos_store          on videos (store_id);
