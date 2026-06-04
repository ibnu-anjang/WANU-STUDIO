# PRD — WANU (Video Commerce App)

> **Product Requirements Document**
> Versi: 0.1 (MVP) · Tanggal: 2026-06-04 · Status: Draft

## 1. Ringkasan Produk

WANU adalah aplikasi mobile yang menggabungkan **feed video short-form (ala TikTok/Reels)** dengan **marketplace lengkap**. User bisa scroll video vertikal tanpa henti, setiap video bisa di-tag produk, dan user bisa langsung beli dari video tersebut (keranjang → checkout → bayar). Mirip konsep **TikTok Shop / Shopee Video**.

**One-liner:** *Nonton, ngiler, checkout — tanpa pindah aplikasi.*

## 2. Masalah & Peluang

- Belanja online sekarang membosankan: katalog statik, foto produk doang.
- Video pendek terbukti meningkatkan konversi (konten → impulse buy).
- Seller kecil butuh kanal jualan yang engaging tanpa ribet.

## 3. Target User

| Persona | Kebutuhan |
|---|---|
| **Buyer (Penonton)** | Hiburan + nemu produk menarik + checkout cepat & aman |
| **Seller (Kreator/Toko)** | Upload video produk, kelola katalog, terima order & pembayaran |
| **Admin** | Moderasi konten, verifikasi seller, monitoring transaksi |

## 4. Scope MVP (v0.1)

Berdasarkan keputusan: **Short-form video feed + Marketplace full dengan payment gateway**.

### 4.1 Fitur In-Scope (MVP)

**Auth & Profil**
- Sign up / login (email + OTP, atau Google/Apple)
- Profil user (buyer) & onboarding jadi seller
- Alamat pengiriman (multiple address)

**Video Feed (For You)**
- Feed vertikal infinite scroll, autoplay
- Like, comment, share, follow seller
- Tag produk di video (1 video bisa banyak produk)
- Tombol "Lihat Produk" / keranjang langsung dari video

**Seller / Toko**
- Onboarding seller (verifikasi data toko)
- Upload video (rekam/galeri) + attach produk
- CRUD produk + varian (warna/ukuran) + stok + harga
- Dashboard order masuk + ubah status (proses → kirim)

**Marketplace & Transaksi**
- Halaman detail produk (galeri + video terkait)
- Search & kategori
- Keranjang (multi-seller → split order)
- Checkout: pilih alamat, ongkir (flat MVP), metode bayar
- **Pembayaran via Midtrans** (VA, e-wallet, kartu) + webhook update status
- Status order (pending → paid → shipped → completed)
- Review & rating produk setelah order selesai

**Notifikasi**
- Push (FCM): order update, pembayaran berhasil, video di-like/comment

### 4.2 Out-of-Scope (MVP — fase berikutnya)

- Live streaming jualan
- Chat buyer–seller real-time
- Affiliate / komisi kreator
- Voucher / flash sale / gamifikasi
- Multi-kurir real-time (RajaOngkir/Biteship integration)
- Iklan berbayar / boost video
- Web version

## 5. User Flow Inti

```
A. Discovery → Beli
   Buka app → Feed video → Tap produk di video → Detail produk
   → Add to cart → Checkout → Bayar (Midtrans) → Order dibuat → Notif

B. Seller jualan
   Daftar seller → Verifikasi → Tambah produk → Upload video + tag produk
   → Video tayang di feed → Terima order → Proses → Kirim → Selesai

C. Pasca-order
   Order completed → Buyer kasih review/rating → Tampil di produk
```

## 6. Requirement Fungsional (ringkas)

| ID | Requirement | Prioritas |
|---|---|---|
| FR-01 | User bisa register/login dengan OTP & social login | P0 |
| FR-02 | User bisa scroll feed video & autoplay | P0 |
| FR-03 | Seller bisa upload video & tag ≥1 produk | P0 |
| FR-04 | Buyer bisa add to cart lintas seller | P0 |
| FR-05 | Checkout menghasilkan order + transaksi Midtrans | P0 |
| FR-06 | Webhook Midtrans meng-update status pembayaran | P0 |
| FR-07 | Seller bisa update status pengiriman | P0 |
| FR-08 | Buyer bisa review produk setelah order selesai | P1 |
| FR-09 | Like, comment, follow di video | P1 |
| FR-10 | Push notif untuk order & interaksi sosial | P1 |
| FR-11 | Search & filter produk by kategori | P1 |

## 7. Requirement Non-Fungsional

- **Performa:** Feed video harus mulai play < 1.5s (adaptive bitrate HLS).
- **Skalabilitas:** Video di-offload ke CDN (Cloudflare Stream), bukan DB.
- **Keamanan:** RLS Supabase di semua tabel; pembayaran tidak pernah dipercaya dari client (hanya webhook server-side).
- **Reliability:** Status order = single source of truth dari webhook, bukan callback client.
- **Privasi:** Data pembayaran tidak disimpan (delegasi ke Midtrans).

## 8. Metrik Sukses (MVP)

- D1 retention ≥ 25%
- Rata-rata durasi sesi ≥ 5 menit
- Conversion video → add-to-cart ≥ 5%
- Checkout success rate (paid/initiated) ≥ 70%

## 9. Risiko & Asumsi

| Risiko | Mitigasi |
|---|---|
| Biaya video streaming membengkak | Pakai Cloudflare Stream (per menit murah), batasi durasi video ≤ 90s |
| Moderasi konten | Admin manual + report flow di MVP |
| Fraud pembayaran | Andalkan webhook server-side + status signature verification Midtrans |
| Stok race condition | Transaksi DB + decrement stok saat `paid`, bukan saat add-to-cart |

## 10. Roadmap Singkat

- **v0.1 (MVP):** Scope di atas
- **v0.2:** Chat buyer-seller, voucher, ongkir real-time (Biteship)
- **v0.3:** Live streaming, affiliate kreator
