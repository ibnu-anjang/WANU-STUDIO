# WANU

> **Nonton, ngiler, checkout — tanpa pindah aplikasi.**

WANU adalah aplikasi *video commerce* yang menggabungkan **feed video short-form** (ala TikTok/Reels) dengan **marketplace lengkap**. User scroll video vertikal tanpa henti, tiap video bisa di-tag produk, dan bisa langsung beli dari video tersebut (keranjang → checkout → bayar). Konsepnya mirip **TikTok Shop / Shopee Video**.

> **Status:** Draft MVP (v0.1). Repo ini berisi dokumen produk + skema database; implementasi aplikasi menyusul.

---

## Isi Repo

```
WANU-STUDIO/
├── docs/
│   ├── PRD.md         ← Product Requirements Document
│   ├── ERD.md         ← Entity Relationship Diagram
│   └── TRD.md         ← Technical Requirements Document
├── supabase/
│   └── migrations/    ← Skema, triggers, dan RLS policies (Postgres)
└── .mcp.json          ← Konfigurasi Supabase MCP
```

## Stack

- **Backend / DB:** Supabase (Postgres + Auth + Storage + RLS)
- **Target client:** aplikasi mobile (video feed + marketplace)

## Fitur (Scope MVP)

- **Auth & Profil** — sign up/login, onboarding seller, multi-alamat pengiriman
- **Video Feed** — feed vertikal infinite scroll, autoplay, like/comment/share/follow, tag produk di video
- **Seller / Toko** — onboarding & verifikasi, upload video + attach produk, CRUD produk + varian + stok, dashboard order
- **Marketplace & Transaksi** — detail produk, keranjang, checkout, pembayaran

Detail lengkap ada di [`docs/PRD.md`](docs/PRD.md).

## Database

Migration tersedia di [`supabase/migrations`](supabase/migrations):

1. `*_schema.sql` — tabel inti
2. `*_triggers.sql` — trigger
3. `*_rls.sql` — Row Level Security policies

Jalankan via Supabase CLI (`supabase db push`) atau salin SQL ke SQL Editor di dashboard Supabase.

## Lisensi

[MIT](LICENSE) © 2026 Ibnu Anjang Maulidi
