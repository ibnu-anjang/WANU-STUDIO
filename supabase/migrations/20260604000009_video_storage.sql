-- WANU — Feed video via Supabase Storage (MVP)
-- Pengganti sementara Cloudflare Stream: MP4 disimpan langsung di bucket
-- 'videos', URL publik disimpan di videos.video_url. Tidak ada transcoding /
-- HLS adaptif — cukup untuk MVP. cf_playback_id tetap ada untuk migrasi nanti.

alter table videos add column if not exists video_url text;

-- Bucket video: public:true → URL objek langsung jalan tanpa SELECT policy.
-- Sengaja TIDAK ada broad SELECT policy (hindari listing semua file); feed
-- nge-list via tabel `videos`, bukan storage listing. Tulis hanya authenticated.
-- Ownership tetap dijaga RLS tabel videos (creator_id = auth.uid()).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'videos',
  'videos',
  true,
  104857600, -- 100 MB, cukup untuk klip pendek
  array['video/mp4', 'video/quicktime', 'video/webm']
)
on conflict (id) do nothing;

create policy "videos authenticated insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'videos');

create policy "videos authenticated update"
  on storage.objects for update to authenticated
  using (bucket_id = 'videos');

create policy "videos authenticated delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'videos');
