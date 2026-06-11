-- WANU — bucket product-images sudah public: object diakses lewat public URL
-- tanpa perlu SELECT policy di storage.objects. Policy SELECT broad justru
-- mengizinkan listing semua file (advisor 0025), jadi dihapus.

drop policy "product images public read" on storage.objects;
