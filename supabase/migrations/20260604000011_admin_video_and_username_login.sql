-- WANU — perketat upload video ke admin + dukung login pakai username.

-- Storage bucket `videos`: insert/update/delete hanya admin (samakan dgn RLS tabel
-- videos yang sudah is_admin()). Hindari file orphan dari non-admin.
drop policy if exists "videos authenticated insert" on storage.objects;
drop policy if exists "videos authenticated update" on storage.objects;
drop policy if exists "videos authenticated delete" on storage.objects;

create policy "videos admin insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'videos' and is_admin());

create policy "videos admin update" on storage.objects
  for update to authenticated
  using (bucket_id = 'videos' and is_admin());

create policy "videos admin delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'videos' and is_admin());

-- Resolve username -> email agar bisa login pakai username. SECURITY DEFINER
-- karena auth.users tidak bisa dibaca client. anon perlu execute (login pra-auth).
create or replace function email_for_username(p_username text)
returns text
language sql
security definer
set search_path = public
as $$
  select u.email
  from profiles p
  join auth.users u on u.id = p.id
  where lower(p.username) = lower(trim(p_username))
  limit 1;
$$;

revoke all on function email_for_username(text) from public;
grant execute on function email_for_username(text) to anon, authenticated;
