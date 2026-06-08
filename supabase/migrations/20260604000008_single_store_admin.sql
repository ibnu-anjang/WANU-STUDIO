-- WANU — pivot ke SINGLE-STORE + role admin.
-- WANU Studio adalah satu-satunya toko (brand store), bukan marketplace.
-- Akses kelola produk/varian/gambar/video diatur lewat role 'admin' (kolom
-- profiles.role), bukan kepemilikan toko per-user. Store jadi singleton.

-- ── is_admin() ─────────────────────────────────────────────────────────
create or replace function is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  );
$$;
revoke execute on function is_admin() from public, anon;
grant execute on function is_admin() to authenticated;

-- ── store singleton ────────────────────────────────────────────────────
-- Brand store tak terikat ke satu user → owner_id boleh null.
alter table stores alter column owner_id drop not null;

insert into stores (id, owner_id, name, slug, is_verified, description)
values (
  '11111111-1111-4111-8111-111111111111',
  null,
  'WANU Studio',
  'wanu-studio',
  true,
  'Toko resmi WANU Studio'
)
on conflict (id) do nothing;

-- Produk baru otomatis nempel ke store singleton (admin tak perlu pilih toko).
alter table products
  alter column store_id set default '11111111-1111-4111-8111-111111111111';

-- ── RLS: ganti basis owner → admin ─────────────────────────────────────
drop policy "products write owner" on products;
create policy "products write admin" on products for all
  using (is_admin()) with check (is_admin());

drop policy "variants write owner" on product_variants;
create policy "variants write admin" on product_variants for all
  using (is_admin()) with check (is_admin());

drop policy "images write owner" on product_images;
create policy "images write admin" on product_images for all
  using (is_admin()) with check (is_admin());

drop policy "videos write owner" on videos;
create policy "videos write admin" on videos for all
  using (is_admin()) with check (is_admin());

drop policy "vtags write owner" on video_product_tags;
create policy "vtags write admin" on video_product_tags for all
  using (is_admin()) with check (is_admin());

drop policy "orders read involved" on orders;
create policy "orders read involved" on orders for select
  using (buyer_id = auth.uid() or is_admin());

drop policy "orders seller update status" on orders;
create policy "orders admin update status" on orders for update
  using (is_admin());

drop policy "order_items read involved" on order_items;
create policy "order_items read involved" on order_items for select
  using (exists (
    select 1 from orders o where o.id = order_id
      and (o.buyer_id = auth.uid() or is_admin())
  ));

drop policy "payments read involved" on payments;
create policy "payments read involved" on payments for select
  using (exists (
    select 1 from orders o where o.id = order_id
      and (o.buyer_id = auth.uid() or is_admin())
  ));

-- User biasa tak lagi bisa bikin/ubah toko; admin boleh edit brand store.
drop policy "stores insert own" on stores;
drop policy "stores update own" on stores;
create policy "stores update admin" on stores for update
  using (is_admin()) with check (is_admin());

-- ── Storage: upload product-images hanya admin ─────────────────────────
drop policy "product images authenticated insert" on storage.objects;
drop policy "product images authenticated update" on storage.objects;
drop policy "product images authenticated delete" on storage.objects;

create policy "product images admin insert" on storage.objects for insert
  to authenticated
  with check (bucket_id = 'product-images' and is_admin());
create policy "product images admin update" on storage.objects for update
  to authenticated
  using (bucket_id = 'product-images' and is_admin());
create policy "product images admin delete" on storage.objects for delete
  to authenticated
  using (bucket_id = 'product-images' and is_admin());
