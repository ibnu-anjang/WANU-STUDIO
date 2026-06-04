-- WANU — triggers & functions

-- ── Auto-create profile saat user baru daftar ─────────────────────────
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ── Maintain videos.like_count ─────────────────────────────────────────
create or replace function bump_video_like_count()
returns trigger
language plpgsql
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

create trigger trg_video_like_count
  after insert or delete on video_likes
  for each row execute function bump_video_like_count();

-- ── Maintain videos.comment_count ──────────────────────────────────────
create or replace function bump_video_comment_count()
returns trigger
language plpgsql
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

create trigger trg_video_comment_count
  after insert or delete on video_comments
  for each row execute function bump_video_comment_count();

-- ── Helper: cek apakah profil saat ini adalah seller pemilik store ─────
create or replace function is_store_owner(target_store uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from stores where id = target_store and owner_id = auth.uid()
  );
$$;
