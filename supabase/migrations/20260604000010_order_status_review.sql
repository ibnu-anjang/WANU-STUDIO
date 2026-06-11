-- WANU — Order status transitions + product reviews
-- State machine order dijaga server-side via RPC SECURITY DEFINER:
--   admin : paid -> processing -> shipped
--   buyer : shipped -> completed (konfirmasi terima), pending -> cancelled (batal)
-- Review hanya boleh dibuat pembeli atas item dari order miliknya yang completed.

create or replace function set_order_status(p_order_id uuid, p_to order_status)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order orders%rowtype;
  v_is_admin boolean := is_admin();
  v_is_owner boolean;
begin
  select * into v_order from orders where id = p_order_id;
  if not found then
    raise exception 'Order tidak ditemukan';
  end if;

  v_is_owner := v_order.buyer_id = auth.uid();
  if not (v_is_admin or v_is_owner) then
    raise exception 'Tidak diizinkan';
  end if;

  if v_is_admin and v_order.status = 'paid' and p_to = 'processing' then
    null;
  elsif v_is_admin and v_order.status = 'processing' and p_to = 'shipped' then
    null;
  elsif v_order.status = 'shipped' and p_to = 'completed' then
    null; -- buyer atau admin
  elsif v_order.status = 'pending' and p_to = 'cancelled' then
    null; -- buyer atau admin
  else
    raise exception 'Transisi status tidak valid: % -> %', v_order.status, p_to;
  end if;

  update orders set status = p_to where id = p_order_id;
end;
$$;

create or replace function submit_review(
  p_order_item_id uuid,
  p_rating int,
  p_comment text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_product_id uuid;
begin
  if p_rating < 1 or p_rating > 5 then
    raise exception 'Rating harus antara 1 dan 5';
  end if;

  select pv.product_id into v_product_id
  from order_items oi
  join orders o on o.id = oi.order_id
  join product_variants pv on pv.id = oi.variant_id
  where oi.id = p_order_item_id
    and o.buyer_id = auth.uid()
    and o.status = 'completed';

  if v_product_id is null then
    raise exception 'Item tidak valid untuk diulas';
  end if;

  insert into reviews (order_item_id, product_id, user_id, rating, comment)
  values (p_order_item_id, v_product_id, auth.uid(), p_rating,
          nullif(trim(p_comment), ''))
  on conflict (order_item_id) do update
    set rating = excluded.rating, comment = excluded.comment;
end;
$$;

-- Review insert hanya lewat submit_review (SECURITY DEFINER). Hapus tulis langsung.
-- "reviews read all" (SELECT true) tetap dipertahankan.
drop policy if exists "reviews write self" on reviews;

revoke all on function set_order_status(uuid, order_status) from public;
revoke all on function submit_review(uuid, int, text) from public;
grant execute on function set_order_status(uuid, order_status) to authenticated;
grant execute on function submit_review(uuid, int, text) to authenticated;
