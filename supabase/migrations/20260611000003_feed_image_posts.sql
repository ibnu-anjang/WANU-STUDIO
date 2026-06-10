-- WANU — feed dukung post gambar (carousel) selain video.
-- Aditif: tabel tetap `videos`, tambah `type` + `image_urls`. video_url
-- sudah nullable (post gambar tak punya video).
alter table videos
  add column if not exists type text not null default 'video'
    check (type in ('video', 'image')),
  add column if not exists image_urls text[];

-- Post gambar pakai bucket 'videos' yang sama (public). Izinkan mime gambar.
update storage.buckets
set allowed_mime_types = array[
  'video/mp4', 'video/quicktime', 'video/webm',
  'image/jpeg', 'image/png', 'image/webp'
]
where id = 'videos';
