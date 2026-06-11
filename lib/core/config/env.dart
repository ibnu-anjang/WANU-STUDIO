// Nilai publik (URL + publishable key) aman di client. Secret server (service
// role, Midtrans, Cloudflare) tidak pernah ada di sini — hanya di Edge Functions.
// Override saat build: flutter run --dart-define=SUPABASE_URL=... dst.
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qtxgejyehvtdpasocvkn.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_4QvM6CKrtZVupGLIw87zMw_lI-kSZd0',
  );
}
