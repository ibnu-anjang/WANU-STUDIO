# Rencana Revisi WANU — Batch Plan

> Catatan kerja untuk lanjutin revisi sebelum masuk ke dependency eksternal
> (Midtrans/Cloudflare/FCM). Branch aktif: `feat/order-status-review`.
> Update terakhir: 2026-06-10.

## Cara pakai dokumen ini

Kalau sesi baru: bilang aja **"lanjutin sesuai docs/PLANNING-BATCH.md, mulai Batch A"**
(atau item spesifik). Tiap item ada nomor asli dari backlog user (#1–#11).

---

## Keputusan yang sudah dikunci

- **#2 akun admin baru** → promote user existing jadi admin lewat RPC (bukan bikin
  user dari nol — hindari dependency auth eksternal).
- **#10 feed** → dukung **post gambar** sekarang juga (ubah skema `videos` → `media`,
  carousel gambar + scrubber video).
- **#9 transaksi** → SUDAH SELESAI (lihat bawah).
- Admin **tidak boleh checkout** — jalur beli disembunyikan untuk admin.

---

## SUDAH SELESAI (jangan diulang)

- **#9 alur transaksi**. Akar masalah ada dua, dua-duanya sudah dibereskan:
  1. `create_orders_from_cart` error `column reference "order_id" is ambiguous`
     → migration `20260604000013_fix_checkout_ambiguous.sql` (qualify `oi.order_id`).
  2. **Disposed Ref**: `checkoutProvider` autoDispose, `ref.invalidate` dipanggil
     setelah `await` di notifier yang sudah dibuang → exception
     "Cannot use the Ref of checkoutProvider after it has been disposed".
     Fix: `checkout_controller.placeOrder` tidak menyentuh `ref` setelah await;
     invalidasi `cartProvider`+`ordersProvider` dipindah ke `checkout_screen`
     (cek `mounted` dulu).
- **Beli Sekarang** di `product_detail_screen` (add to cart → `/checkout`).
  Bottom bar jadi 2 tombol: Keranjang (outline) + Beli Sekarang (filled).
- **Admin gating**: bottom bar beli di detail produk disembunyikan kalau `isAdmin`.
- **Tombol back di `/orders`**: `context.canPop() ? pop : go('/profile')` —
  fix nyangkut setelah checkout (route top-level di luar shell).

> ✅ Sudah di-commit (`dc8a307`). Verifikasi ulang 2026-06-11: checkout_controller +
> checkout_screen + order_repository semua bersih (tak ada `ref` setelah await).
> Screenshot disposed-ref yang sempat ada itu bukti lama (pre-fix), bukan bug aktif.
> Branch `feat/order-status-review` belum di-push / belum ada PR.

- **Batch A — SELESAI** (commit batch A, 2026-06-11):
  - #4 refresh: catalog pull-to-refresh + tombol refresh di feed.
  - #5 search Jelajah: filter client-side live + tombol clear.
  - #6 drag mouse/trackpad di Web: `scrollBehavior` global di `main.dart`.
  - #8 konsistensi media: gambar produk grid + detail jadi `AspectRatio(1)` BoxFit.cover.
  - #10 (sebagian): wordmark "WANU STUDIO", overlay feed bottom-aligned, scrubber video.

---

## Batch A — Quick win, TIDAK sentuh skema

Mulai dari sini. Aman, cepat, tidak ada migration.

- **#4 Pull-to-refresh** di Feed & Jelajah (RefreshIndicator → `ref.invalidate`
  `feedVideosProvider` / `productsProvider`).
- **#5 Search di Jelajah** — aktifkan search bar (filter client-side dulu, atau
  `.ilike('title', ...)` ke Supabase).
- **#6 Scroll/drag gambar di Web gabisa** — pasang `ScrollConfiguration` global
  dengan `dragDevices` termasuk `PointerDeviceKind.mouse` (carousel PageView
  produk & detik feed). Cek di `main.dart` / `MaterialApp.scrollBehavior`.
- **#8 Ukuran gambar/video tidak konsisten** — bungkus dengan `AspectRatio`
  (mis. 1:1 untuk grid produk, 9:16 untuk feed) + `BoxFit.cover` konsisten.
- **#10 (sebagian, tanpa skema)**:
  - Feed: ganti teks "WANU" jadi "WANU STUDIO" (tambah "studio"-nya).
  - Layout overlay feed pas tidak ada caption/produk jangan terlalu ke tengah
    (rapikan alignment bawah).
  - **Scrubber detik** untuk video feed (slider posisi via `VideoPlayerController`).

## Batch B — Restrukturisasi role admin — ✅ SELESAI (2026-06-11)

- #1 Tab admin = `AdminOrdersScreen` (list semua order + advance status inline),
  nav label jadi "Pesanan". Switch via `_ExploreBranch` di router. Buyer tetap katalog.
- #2 Profil admin: entry buyer (Pesanan saya, Alamat) disembunyikan; tambah
  "Kelola feed" + "Jadikan user admin". RPC `promote_to_admin(text)` (migration
  `20260611000001`, match username/email, admin-gated). Cart entry-point admin
  sudah hilang (katalog disembunyikan + buy-bar di-gate sebelumnya).
- #11 `ManageFeedScreen` (route `/admin/feed`): list konten feed, hapus + konfirmasi,
  shortcut upload. `videoRepository.deleteVideo` (cascade ke tags).

> Catatan: edit caption/tag dari kelola-feed BELUM diimplement (cuma list+hapus+upload).
> Tambahkan kalau memang dibutuhkan.

### (referensi lama) Batch B — rencana awal

- **#1 Tab "Jelajah" admin → "Pesanan/Kontrol"**. Admin lihat semua pesanan masuk
  + bisa ubah status (paid→processing→shipped) lewat `set_order_status` yang sudah ada.
  Buyer tetap lihat Jelajah normal. Gate berdasarkan `currentProfileProvider.isAdmin`.
- **#2 Profil admin dirapikan**: buang "Alamat pengiriman" & "Pesanan saya"
  (tidak relevan untuk admin). Tambah menu **"Jadikan user admin"** (input
  email/username → RPC promote). Sekalian cabut sisa entry-point cart/keranjang
  di sisi admin (ikon cart di nav, dll).
- **#11 Menu "Kelola Feed"** di admin — CRUD feed (list video/post, hapus, edit
  caption/tag produk). Reuse `video_repository`.

## Batch C — status (2026-06-11)

- **#3 preorder — ✅ SELESAI**. Migration `20260611000002` (kolom `is_preorder`,
  `preorder_days` + check > 0). Form toggle + input hari, badge "PO X hari"
  (widget `PreorderBadge`) di katalog & detail.
- **#10 post gambar feed — ✅ SELESAI** (aditif, BUKAN rename tabel). Migration
  `20260611000003` (`videos.type` + `image_urls`, bucket `videos` izinkan mime
  gambar). Feed render carousel gambar / video, overlay dipakai bersama
  (`_OverlayLayer`). Upload screen mode Video/Gambar (multi-pick, upload per
  gambar lalu `createImagePost`). Manage feed thumbnail dari gambar pertama.
- **#7 hapus akun — ✅ SELESAI (hard delete)**. Edge Function `delete-account`
  (service role): hapus order user dulu (FK `orders.buyer_id` ON DELETE RESTRICT)
  lalu `auth.admin.deleteUser` → cascade profil + semua data. Tile danger
  "Hapus akun" di Profil (buyer & admin) + konfirmasi, lalu signOut.

### Tambahan
- **Edit Kelola Feed — ✅ SELESAI**. Row dapat tombol edit → `EditFeedScreen`
  (caption + dropdown tag produk, prefilled). `videoRepository.updatePost`
  ganti tag tunggal + update caption.

### (rencana awal) Batch C

- **#3 Produk preorder/PO**: tambah kolom `is_preorder bool` + `preorder_days int`
  di `products`. Form kelola produk dapat toggle + input hari. Tampilkan badge
  "PO X hari" di detail/katalog.
- **#7 Hapus akun** (buyer & admin): RPC `delete_own_account()` SECURITY DEFINER
  (hapus profil + data milik user, lalu `auth.admin` delete via Edge Function
  ATAU tandai disabled — putuskan saat eksekusi). Tombol di Profil dengan konfirmasi.
- **#10 (sisanya) Post gambar di feed**: skema `videos` → konsep `media`
  (kolom `type: 'video'|'image'`, dukung multi-gambar). Carousel gambar geser
  + tetap support video. Upload screen dukung pilih gambar (image_picker sudah ada).
  Ini paling besar — kerjakan terakhir.

---

## Konteks teknis penting (biar sesi baru gak nyari-nyari)

- **Migration via MCP `apply_migration`** (Supabase CLI belum di-setup). Ref
  project `qtxgejyehvtdpasocvkn`. Selalu `list_migrations` dulu.
- **Riverpod 3.x**, codegen: `flutter pub run build_runner build`
  (BUKAN `dart run`). `custom_lint`/`riverpod_lint` sengaja tidak dipasang.
  Ref type = `Ref`.
- **Single-store + admin role**: store id `11111111-1111-4111-8111-111111111111`
  (`wanuStoreId` di `lib/core/config/constants.dart`). `is_admin()` di Postgres,
  `profiles.role`. Cek admin di Flutter: `currentProfileProvider.value?.isAdmin`.
- **Akun dev**: admin `admin@wanu.studio` (username `adminiben`), buyer
  `buyer@wanu.studio`. Password JANGAN ditulis di repo — simpan di password
  manager. ⚠️ Rotasi password kedua akun ini SEBELUM deploy publik (password
  lama lemah dan sempat ter-commit di dokumen ini). Login bisa email/username.
- **RPC order**: `create_orders_from_cart(p_address_id)`, `mark_order_paid(p_order_id)`
  (mock), `set_order_status(p_order_id, p_to)`, `submit_review(...)`.
- `flutter analyze` harus 0 issue sebelum commit. Code English, docs Indonesia,
  Conventional Commits, trailer `Co-Authored-By: Claude Opus 4.8`.

## Checklist Deploy (audit 2026-06-12)

Sudah dibereskan (migration `20260612000001_perf_rls_policy_cleanup`):

- ✅ **Privilege escalation `profiles.role`** — user bisa set `role='admin'` sendiri
  via PATCH REST. Fix: column-level grant (UPDATE hanya username/display_name/
  avatar_url/bio); role hanya via `promote_to_admin`.
- ✅ Policy `orders admin update status` di-drop (redundan; transisi via RPC saja).
- ✅ Advisor performance: `auth.uid()`/`is_admin()` di-wrap `(select ...)`,
  policy FOR ALL dipecah insert/update/delete, 14 FK index ditambahkan.
- ✅ `widget_test.dart` disesuaikan ("WANU" → "WANU STUDIO").

Masih HARUS sebelum terima uang nyata:

- ⬜ **Midtrans**: Edge Function `create-order` (Snap token) + `midtrans-webhook`
  (verifikasi signature → panggil logic `mark_order_paid` pakai service_role),
  lalu `REVOKE EXECUTE` `mark_order_paid` dari `authenticated`. Selama belum,
  semua order bisa "paid" gratis dari client (fase mock, by design).
- ⬜ **Rotasi password** akun dev `admin@wanu.studio` & `buyer@wanu.studio`
  (password lama lemah + sempat ter-commit di repo).
- ⬜ **Aktifkan leaked password protection** (Dashboard → Auth → Passwords).

Disarankan / keputusan bisnis:

- ⬜ `email_for_username` callable oleh `anon` → siapa pun bisa memetakan
  username → email. Opsi: pindahkan resolusi + sign-in ke Edge Function.
- ⬜ `delete-account` menghapus order user (termasuk paid) → catatan penjualan
  hilang. Pertimbangkan anonimisasi alih-alih hard delete order.
- ⬜ Egress video: MP4 hingga 100 MB diserve dari Supabase Storage — pantau
  kuota bandwidth setelah launch.

## Urutan eksekusi yang disarankan

1. Commit dulu pekerjaan "SUDAH SELESAI" di atas.
2. Batch A (cepat, kasih hasil kelihatan).
3. Batch B (restrukturisasi admin).
4. Batch C (skema — paling berat, #10 media terakhir).
