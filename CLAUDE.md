# WANU — Video Commerce App

Aplikasi mobile yang menggabungkan **feed video short-form (ala TikTok/Reels)** dengan **marketplace lengkap**. User scroll video vertikal, tiap video bisa di-tag produk, dan bisa langsung checkout. Konsep mirip TikTok Shop / Shopee Video.

Dokumen perencanaan ada di `docs/`: [PRD](./docs/PRD.md) · [TRD](./docs/TRD.md) · [ERD](./docs/ERD.md).

## Stack

- **Frontend**: Flutter + Riverpod (`riverpod_generator`) + `go_router` — target **Android + Web** (satu codebase)
- **Backend/DB**: Supabase — Postgres 15, Auth, RLS, Realtime, Edge Functions (Deno/TS)
- **Video**: Cloudflare Stream (transcoding + HLS adaptive + thumbnail) — **bukan** Supabase Storage
- **Gambar**: Supabase Storage
- **Payment**: Midtrans Snap (VA, e-wallet, kartu) — status hanya dari webhook server-side
- **Push notif**: Firebase Cloud Messaging (FCM)
- **Deploy**: Android → Play Store · Web → Firebase Hosting / Vercel (build `flutter build web`)

> ⚠️ **Flutter Web caveat**: SEO lemah (halaman produk tidak ramah crawler) & initial load berat. Untuk MVP web = pelengkap. Jika nanti web jadi kanal utama, pertimbangkan halaman produk publik pakai Next.js terpisah (backend Supabase tetap dipakai bareng).

Supabase project ref: `qtxgejyehvtdpasocvkn` (akses via MCP server `supabase`, lihat `.mcp.json`).

## Struktur Folder

```
docs/                # PRD, TRD, ERD (Bahasa Indonesia)
lib/
├── core/            # config, theme, router, supabase client, di
├── features/        # auth, feed, product, cart, checkout, order, seller, profile
│   └── <feature>/   # data/ · application/ (riverpod) · presentation/
└── shared/          # widgets, models, utils
supabase/
├── migrations/      # schema SQL versioned
└── functions/       # Edge Functions (create-order, midtrans-webhook, dll)
```

## Konvensi

- Bahasa kode: English (variabel, fungsi, komentar inline, commit)
- Docs & catatan: Bahasa Indonesia
- Commit: Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`)
- Branch: `feat/nama`, `fix/nama`, `chore/nama` — branch dari `main`
- RLS **wajib** di semua tabel Supabase
- Validasi & secret hanya di boundary/server (Edge Functions), tidak pernah di client

## Aturan Kritis (jangan dilanggar)

- **Status pembayaran hanya dari webhook Midtrans server-side**, tidak pernah dari client.
- **Decrement stok** saat order `paid` (di webhook), bukan saat add-to-cart / create-order.
- **Snapshot harga** disimpan di `order_items` agar order historis tidak berubah saat produk diedit.
- **Video** di-upload langsung ke Cloudflare Stream via one-time URL; Postgres hanya simpan `playback_id`.

## Perintah Penting

```bash
# Flutter
flutter pub get
flutter run
flutter analyze && flutter test     # zero error sebelum build
flutter build apk --release

# Supabase (CLI)
supabase start                      # local stack
supabase db reset                   # apply migrations ke local
supabase migration new <name>
supabase functions serve            # test Edge Functions lokal
supabase db push                    # push migrations ke remote
```
