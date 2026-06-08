-- WANU — template suntik user (admin / buyer) lewat Supabase SQL Editor.
-- Dipakai untuk DEV/seed manual, BUKAN migration (jangan taruh di migrations/,
-- nanti ke-apply ulang tiap db reset/push dengan kredensial hardcoded).
--
-- Cara pakai:
--   1. Buka Dashboard Supabase → SQL Editor → New query
--   2. Paste seluruh file ini
--   3. Edit 3 variabel di blok DECLARE (email, password, role)
--   4. Run
--
-- Catatan teknis (kenapa insert-nya begini):
--   - auth.users.confirmed_at = generated column → JANGAN di-insert
--   - email_confirmed_at di-set now() → user bisa login tanpa klik email
--   - auth.identities butuh provider_id (= uid) NOT NULL, kalau tidak ada
--     login email/password bisa gagal di GoTrue versi baru
--   - role disimpan di public.profiles.role ('admin' | 'buyer' | 'seller')

do $$
declare
  -- ── EDIT DI SINI ──────────────────────────────────────────────
  v_email    text := 'admin2@wanu.studio';
  v_password text := 'GantiPasswordIni#2026';
  v_role     text := 'admin';          -- 'admin' atau 'buyer'
  v_name     text := 'WANU Admin';
  -- ──────────────────────────────────────────────────────────────
  v_uid uuid := gen_random_uuid();
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change,
    email_change_token_new, email_change_token_current, reauthentication_token,
    is_sso_user, is_anonymous
  ) values (
    '00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated',
    v_email, crypt(v_password, gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('display_name', v_name),
    '', '', '', '', '', '',
    false, false
  );

  insert into auth.identities (
    provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_uid, v_uid,
    jsonb_build_object('sub', v_uid::text, 'email', v_email, 'email_verified', true),
    'email', now(), now(), now()
  );

  -- handle_new_user() biasanya sudah bikin baris profiles (role default 'buyer');
  -- upsert untuk set role & nama sesuai pilihan.
  insert into profiles (id, role, display_name)
  values (v_uid, v_role::user_role, v_name)
  on conflict (id) do update set role = excluded.role, display_name = excluded.display_name;

  raise notice 'User % dibuat dengan role % (uid %)', v_email, v_role, v_uid;
end $$;

-- Verifikasi:
select u.email, u.email_confirmed_at is not null as confirmed, p.role, p.display_name
from auth.users u
join profiles p on p.id = u.id
order by u.created_at desc
limit 5;
