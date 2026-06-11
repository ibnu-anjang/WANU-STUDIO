-- WANU — hardening function (advisor: search_path & RPC exposure)

-- search_path eksplisit untuk trigger function (cegah search_path hijack)
create or replace function bump_video_like_count()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update videos set like_count = like_count + 1 where id = new.video_id;
  elsif tg_op = 'DELETE' then
    update videos set like_count = greatest(like_count - 1, 0) where id = old.video_id;
  end if;
  return null;
end;
$$;

create or replace function bump_video_comment_count()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update videos set comment_count = comment_count + 1 where id = new.video_id;
  elsif tg_op = 'DELETE' then
    update videos set comment_count = greatest(comment_count - 1, 0) where id = old.video_id;
  end if;
  return null;
end;
$$;

-- handle_new_user cuma dipakai sebagai trigger auth.users → cabut dari semua role
-- (Postgres default grant EXECUTE ke PUBLIC, jadi harus revoke dari public)
revoke execute on function handle_new_user() from public, anon, authenticated;

-- is_store_owner dipakai di RLS → cabut dari public, sisakan hanya authenticated
revoke execute on function is_store_owner(uuid) from public, anon;
grant execute on function is_store_owner(uuid) to authenticated;
