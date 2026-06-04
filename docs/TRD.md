# TRD — WANU (Video Commerce App)

> **Technical Requirements Document**
> Versi: 0.1 (MVP) · Tanggal: 2026-06-04 · Status: Draft
> Lihat juga: [PRD.md](./PRD.md), [ERD.md](./ERD.md)

## 1. Arsitektur Tingkat Tinggi

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (Riverpod)                 │
│   Feed · Produk · Cart · Checkout · Seller Dashboard      │
└───────┬──────────────┬───────────────┬───────────────────┘
        │              │               │
        │ HLS stream   │ REST/RPC       │ Upload
        ▼              ▼               ▼
┌──────────────┐ ┌─────────────────────────────┐ ┌──────────────┐
│ Cloudflare   │ │        Supabase             │ │ Midtrans     │
│ Stream (CDN) │ │  Auth · Postgres (RLS) ·    │ │ (Snap +      │
│ video HLS    │ │  Storage(img) · Realtime ·  │ │  Webhook)    │
│ + thumbnail  │ │  Edge Functions             │ │              │
└──────────────┘ └──────────────┬──────────────┘ └──────┬───────┘
                                 │                        │
                                 │  webhook (server-side) │
                                 ◄────────────────────────┘
                                 │
                          ┌──────▼──────┐
                          │     FCM     │  push notif
                          └─────────────┘
```

## 2. Tech Stack Final

| Komponen | Teknologi | Catatan |
|---|---|---|
| Mobile | Flutter (stable) | Target Android & iOS |
| State mgmt | Riverpod + `riverpod_generator` | Sesuai preferensi |
| Routing | `go_router` | Deep link ke produk/video |
| Backend | Supabase | Postgres 15, Auth, RLS, Realtime |
| Server logic | Supabase Edge Functions (Deno/TS) | Checkout, webhook, signed upload |
| Video | **Cloudflare Stream** | Transcoding, HLS adaptive, thumbnail, signed URL |
| Image | Supabase Storage | Produk & avatar |
| Payment | **Midtrans Snap** | VA, e-wallet, kartu |
| Push | Firebase Cloud Messaging | Via Edge Function trigger |
| Search | Postgres FTS (MVP) | Upgrade Meilisearch nanti |
| Analytics | PostHog / Supabase logs | Opsional MVP |

## 3. Kenapa Pilihan Ini

- **Supabase > Firebase:** marketplace = data relational berat (order ↔ order_items ↔ products ↔ payments, stok, agregasi penjualan). Postgres + foreign key + transaksi ACID jauh lebih aman daripada Firestore. RLS = otorisasi rapi tanpa server tambahan.
- **Video TIDAK di Supabase Storage:** Storage = blob biasa, tidak ada transcoding/adaptive streaming. Short-form feed butuh HLS multi-bitrate biar mulus di koneksi jelek. Cloudflare Stream urus semua (upload → transcode → HLS + thumbnail), tinggal simpan `playback_id` di Postgres.
- **Edge Functions untuk hal sensitif:** checkout, decrement stok, verifikasi webhook Midtrans — tidak boleh di client.

## 4. Alur Teknis Kunci

### 4.1 Upload Video (Seller)
```
1. App minta one-time upload URL → Edge Function `create-video-upload`
2. Edge Function panggil Cloudflare Stream API → balikin uploadURL + uid
3. App upload file langsung ke Cloudflare (tidak lewat server)
4. Cloudflare webhook "ready" → Edge Function simpan playback_id ke tabel `videos`
5. App attach produk → insert ke `video_product_tags`
```

### 4.2 Checkout & Pembayaran (paling kritikal)
```
1. App POST cart → Edge Function `create-order`
2. Function (dalam 1 transaksi DB):
   - validasi stok tiap item
   - buat `orders` (status=pending) + `order_items` (snapshot harga)
   - split per seller jika multi-seller
3. Function panggil Midtrans Snap → balikin snap_token
4. App buka Snap (Midtrans Flutter SDK) → user bayar
5. Midtrans → POST webhook → Edge Function `midtrans-webhook`:
   - verifikasi signature_key (sha512)
   - jika settlement/capture → order.status=paid, DECREMENT stok di sini
   - trigger FCM ke buyer & seller
6. Client TIDAK PERNAH menentukan status paid — hanya webhook.
```
> **Aturan stok:** stok dikurangi saat status `paid` (di webhook), bukan saat add-to-cart maupun create-order. Validasi ulang stok di webhook; jika habis → refund flow (out-of-scope MVP, log untuk admin).

### 4.3 Feed Video (For You)
```
- Query videos JOIN profiles (seller) + agregasi like/comment
- Pagination: keyset (cursor by created_at, id) — bukan OFFSET
- Ranking MVP: chronological + sedikit boost engagement (sort sederhana)
- Video player pakai playback HLS URL dari Cloudflare (signed jika perlu)
```

## 5. Struktur Folder Flutter (usulan)

```
lib/
├── core/           # config, theme, router, supabase client, di
├── features/
│   ├── auth/
│   ├── feed/       # video feed + player
│   ├── product/
│   ├── cart/
│   ├── checkout/
│   ├── order/
│   ├── seller/     # dashboard, upload, manage product
│   └── profile/
├── shared/         # widgets, models, utils
└── main.dart
```
Tiap feature: `data/` (repository + dto) · `application/` (riverpod providers/notifier) · `presentation/` (screens + widgets).

## 6. Edge Functions (Deno/TS)

| Function | Tugas |
|---|---|
| `create-video-upload` | Generate Cloudflare Stream upload URL |
| `video-ready-webhook` | Terima callback Cloudflare, simpan playback_id |
| `create-order` | Validasi stok, buat order + items, panggil Midtrans |
| `midtrans-webhook` | Verifikasi signature, update status, decrement stok, push notif |
| `send-notification` | Wrapper FCM |

## 7. Keamanan

- **RLS aktif di semua tabel.** Contoh kebijakan:
  - `products`: SELECT publik, INSERT/UPDATE hanya `seller_id = auth.uid()`
  - `orders`: SELECT hanya buyer pemilik ATAU seller terkait
  - `videos`: SELECT publik (status=ready), tulis hanya owner
- Webhook Midtrans: verifikasi `signature_key = sha512(order_id + status_code + gross_amount + server_key)`.
- Secret (Midtrans server key, Cloudflare token) hanya di Edge Function env, tidak pernah di app.
- Upload langsung ke Cloudflare via one-time URL (app tidak pegang token).

## 8. Lingkungan & Konfigurasi

```bash
# .env.example (Edge Functions / server)
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
MIDTRANS_SERVER_KEY=
MIDTRANS_CLIENT_KEY=
MIDTRANS_IS_PRODUCTION=false
CLOUDFLARE_ACCOUNT_ID=
CLOUDFLARE_STREAM_TOKEN=
FCM_SERVER_KEY=

# Flutter (--dart-define)
SUPABASE_URL=
SUPABASE_ANON_KEY=
MIDTRANS_CLIENT_KEY=
```

## 9. Non-Fungsional / Operasional

- **Migrasi DB:** Supabase migrations (SQL versioned di repo).
- **Typegen:** generate Dart model dari schema (atau manual DTO + `freezed`).
- **Testing:** unit (Riverpod notifier) + integration checkout flow (sandbox Midtrans).
- **CI:** `flutter analyze` + `flutter test` zero error sebelum build.
- **Observability:** log Edge Functions + tabel `payment_logs` untuk audit webhook.

## 10. Estimasi Urutan Kerja

1. Setup Supabase + schema + RLS (lihat ERD)
2. Auth + profil + seller onboarding
3. Produk CRUD + Storage gambar
4. Cloudflare Stream + upload video + feed
5. Cart + checkout + Midtrans + webhook (paling lama)
6. Order status + review
7. Push notif + polish
