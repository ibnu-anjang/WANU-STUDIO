-- Username unik (case-insensitive) karena dipakai buat login. Email sudah unik
-- otomatis di auth.users. NULL diabaikan (user yang belum set username).
create unique index if not exists profiles_username_lower_key
  on profiles (lower(username))
  where username is not null;
