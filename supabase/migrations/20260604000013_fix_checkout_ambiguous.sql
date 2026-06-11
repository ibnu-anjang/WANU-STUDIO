-- Fix: create_orders_from_cart gagal dengan "column reference order_id is ambiguous".
-- Nama kolom OUT dari RETURNS TABLE (order_id) bentrok dengan kolom order_items.order_id
-- di subquery sum. Qualify kolom tabel dengan alias `oi`. Sisa fungsi identik.
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

    select coalesce(sum(oi.unit_price * oi.quantity), 0) into v_subtotal
    from order_items oi where oi.order_id = v_order_id;

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
