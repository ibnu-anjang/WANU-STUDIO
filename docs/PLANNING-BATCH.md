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

> ⚠️ Masih perlu **commit** semua perubahan di atas (belum di-commit saat catatan ditulis).
> Branch `feat/order-status-review` juga belum di-push / belum ada PR.

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

## Batch B — Restrukturisasi role admin (UI, sedikit/tanpa skema)

- **#1 Tab "Jelajah" admin → "Pesanan/Kontrol"**. Admin lihat semua pesanan masuk
  + bisa ubah status (paid→processing→shipped) lewat `set_order_status` yang sudah ada.
  Buyer tetap lihat Jelajah normal. Gate berdasarkan `currentProfileProvider.isAdmin`.
- **#2 Profil admin dirapikan**: buang "Alamat pengiriman" & "Pesanan saya"
  (tidak relevan untuk admin). Tambah menu **"Jadikan user admin"** (input
  email/username → RPC promote). Sekalian cabut sisa entry-point cart/keranjang
  di sisi admin (ikon cart di nav, dll).
- **#11 Menu "Kelola Feed"** di admin — CRUD feed (list video/post, hapus, edit
  caption/tag produk). Reuse `video_repository`.

## Batch C — Butuh perubahan skema (migration + codegen)

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
- **Akun dev**: admin `admin@wanu.studio` / `admin123` (username `adminiben`),
  buyer `buyer@wanu.studio` / `buyer123`. Login bisa pakai email atau username.
- **RPC order**: `create_orders_from_cart(p_address_id)`, `mark_order_paid(p_order_id)`
  (mock), `set_order_status(p_order_id, p_to)`, `submit_review(...)`.
- `flutter analyze` harus 0 issue sebelum commit. Code English, docs Indonesia,
  Conventional Commits, trailer `Co-Authored-By: Claude Opus 4.8`.

## Urutan eksekusi yang disarankan

1. Commit dulu pekerjaan "SUDAH SELESAI" di atas.
2. Batch A (cepat, kasih hasil kelihatan).
3. Batch B (restrukturisasi admin).
4. Batch C (skema — paling berat, #10 media terakhir).
