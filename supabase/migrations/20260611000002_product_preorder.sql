-- WANU — dukungan produk preorder (PO). Admin set flag + estimasi hari.
alter table products
  add column if not exists is_preorder boolean not null default false,
  add column if not exists preorder_days integer;

alter table products
  add constraint products_preorder_days_positive
  check (preorder_days is null or preorder_days > 0);
