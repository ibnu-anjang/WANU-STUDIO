-- WANU — Storage bucket untuk gambar produk
-- Baca publik (URL bisa dipajang di app), tulis hanya authenticated.
-- Ownership produk tetap dijaga RLS tabel product_images (is_store_owner).

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

create policy "product images public read"
  on storage.objects for select
  using (bucket_id = 'product-images');

create policy "product images authenticated insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'product-images');

create policy "product images authenticated update"
  on storage.objects for update to authenticated
  using (bucket_id = 'product-images');

create policy "product images authenticated delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'product-images');
