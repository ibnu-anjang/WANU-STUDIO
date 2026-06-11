-- WANU — promosikan user existing jadi admin (dipanggil dari Profil admin).
-- Cocokkan via username (case-insensitive) atau email auth.users. SECURITY
-- DEFINER agar bisa baca auth.users; hanya admin yang boleh memanggil.
create or replace function promote_to_admin(p_identifier text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_name text;
  v_key text := lower(trim(p_identifier));
begin
  if not is_admin() then
    raise exception 'Hanya admin yang boleh mempromosikan user';
  end if;

  select p.id into v_id
  from profiles p
  left join auth.users u on u.id = p.id
  where lower(p.username) = v_key or lower(u.email) = v_key
  limit 1;

  if v_id is null then
    raise exception 'User tidak ditemukan: %', p_identifier;
  end if;

  update profiles set role = 'admin'
  where id = v_id
  returning coalesce(display_name, username, 'user') into v_name;

  return v_name;
end;
$$;

revoke all on function promote_to_admin(text) from public, anon;
grant execute on function promote_to_admin(text) to authenticated;
