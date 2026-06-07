-- WANU — checkout & pembayaran (fase MOCK, sebelum Midtrans aktif)
-- Order INSERT & transisi ke 'paid' dilarang dari client oleh RLS, jadi logic-nya
-- ada di function SECURITY DEFINER (bypass RLS) yang validasi auth.uid() sendiri.
-- create_orders_from_cart nanti dipakai ulang oleh Edge Function Midtrans.
-- mark_order_paid = stand-in webhook → saat Midtrans aktif, REVOKE dari authenticated
-- dan panggil hanya dari Edge Function (service_role) setelah verifikasi signature.

-- ── create_orders_from_cart ────────────────────────────────────────────
-- Baca cart milik buyer, group per toko (orders.store_id NOT NULL → 1 order/toko),
-- snapshot harga ke order_items, buat payment pending, lalu kosongkan cart.
-- TIDAK menyentuh stok (stok turun saat paid, lihat mark_order_paid).
create or replace function create_orders_from_cart(p_address_id uuid)
returns table (order_id uuid, store_id uuid, total bigint)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_buyer uuid := auth.uid();
  v_store_id uuid;
  v_order_id uuid;
  v_subtotal bigint;
begin
  if v_buyer is null then
    raise exception 'not authenticated';
  end if;

  if not exists (select 1 from cart_items where user_id = v_buyer) then
    raise exception 'cart is empty';
  end if;

  if p_address_id is not null and not exists (
    select 1 from addresses where id = p_address_id and user_id = v_buyer
  ) then
    raise exception 'invalid address';
  end if;

  for v_store_id in
    select pr.store_id
    from cart_items ci
    join product_variants pv on pv.id = ci.variant_id
    join products pr on pr.id = pv.product_id
    where ci.user_id = v_buyer
    group by pr.store_id
  loop
    insert into orders (buyer_id, store_id, address_id, status, subtotal, shipping_fee, total)
    values (v_buyer, v_store_id, p_address_id, 'pending', 0, 0, 0)
    returning id into v_order_id;

    insert into order_items (order_id, variant_id, product_title, variant_name, unit_price, quantity)
    select v_order_id, pv.id, pr.title, pv.name, pv.price, ci.quantity
    from cart_items ci
    join product_variants pv on pv.id = ci.variant_id
    join products pr on pr.id = pv.product_id
    where ci.user_id = v_buyer and pr.store_id = v_store_id;

    select coalesce(sum(unit_price * quantity), 0) into v_subtotal
    from order_items where order_id = v_order_id;

    update orders set subtotal = v_subtotal, total = v_subtotal
    where id = v_order_id;

    insert into payments (order_id, provider, gross_amount, status)
    values (v_order_id, 'mock', v_subtotal, 'pending');

    order_id := v_order_id;
    store_id := v_store_id;
    total := v_subtotal;
    return next;
  end loop;

  delete from cart_items where user_id = v_buyer;
end;
$$;

-- ── mark_order_paid (MOCK webhook) ─────────────────────────────────────
-- Idempotent: hanya transisi pending → paid, decrement stok sekali.
-- Stok di-check (>= 0) di kolom, jadi oversell otomatis rollback seluruh tx.
create or replace function mark_order_paid(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_buyer uuid;
  v_updated int;
begin
  select buyer_id into v_buyer from orders where id = p_order_id;
  if v_buyer is null then
    raise exception 'order not found';
  end if;
  -- MOCK guard: hanya buyer yang boleh simulasi bayar order-nya sendiri.
  -- (Webhook Midtrans asli verifikasi signature, bukan auth.uid().)
  if v_buyer <> auth.uid() then
    raise exception 'not your order';
  end if;

  update orders set status = 'paid'
  where id = p_order_id and status = 'pending';
  get diagnostics v_updated = row_count;
  if v_updated = 0 then
    return; -- sudah diproses → no-op idempotent
  end if;

  update product_variants pv
  set stock = pv.stock - oi.quantity
  from order_items oi
  where oi.order_id = p_order_id and oi.variant_id = pv.id;

  update payments
  set status = 'settlement', paid_at = now()
  where order_id = p_order_id;
end;
$$;

-- Function dipanggil dari client (authenticated) selama fase mock.
revoke execute on function create_orders_from_cart(uuid) from public, anon;
revoke execute on function mark_order_paid(uuid) from public, anon;
grant execute on function create_orders_from_cart(uuid) to authenticated;
grant execute on function mark_order_paid(uuid) to authenticated;
