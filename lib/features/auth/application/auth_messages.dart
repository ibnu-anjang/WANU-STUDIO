/// Ubah error auth (AuthException / pesan teknis) jadi kalimat ramah Bahasa
/// Indonesia untuk ditampilkan ke user.
String humanizeAuthError(Object error) {
  final raw = error.toString().toLowerCase();

  if (raw.contains('invalid login credentials')) {
    return 'Email/username atau password salah.';
  }
  if (raw.contains('akun tidak ditemukan') || raw.contains('username')) {
    return 'Akun tidak ditemukan. Cek lagi username-nya.';
  }
  if (raw.contains('email not confirmed')) {
    return 'Email belum dikonfirmasi. Cek inbox kamu dulu.';
  }
  if (raw.contains('user already registered') ||
      raw.contains('already been registered')) {
    return 'Email ini sudah terdaftar. Coba masuk saja.';
  }
  if (raw.contains('password should be at least') ||
      raw.contains('weak password')) {
    return 'Password terlalu pendek (minimal 6 karakter).';
  }
  if (raw.contains('unable to validate email') ||
      raw.contains('invalid email')) {
    return 'Format email tidak valid.';
  }
  if (raw.contains('rate limit') || raw.contains('too many')) {
    return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
  }
  if (raw.contains('socketexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('clientexception') ||
      raw.contains('network')) {
    return 'Gagal terhubung. Cek koneksi internetmu.';
  }
  return 'Terjadi kesalahan. Coba lagi sebentar.';
}
