import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import 'cart_item.dart';

part 'cart_repository.g.dart';

const _select =
    'id, quantity, variant_id, '
    'product_variants(name, price, product_id, '
    'products(title, product_images(url, sort_order)))';

@riverpod
CartRepository cartRepository(Ref ref) =>
    CartRepository(ref.watch(supabaseClientProvider));

class CartRepository {
  CartRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  Future<List<CartItem>> fetchItems() async {
    final rows =
        await _client.from('cart_items').select(_select).order('id');
    return rows.map(CartItem.fromMap).toList();
  }

  Future<void> addVariant(String variantId, int quantity) async {
    final existing = await _client
        .from('cart_items')
        .select('id, quantity')
        .eq('user_id', _uid)
        .eq('variant_id', variantId)
        .maybeSingle();
    if (existing == null) {
      await _client.from('cart_items').insert({
        'user_id': _uid,
        'variant_id': variantId,
        'quantity': quantity,
      });
    } else {
      await _client.from('cart_items').update({
        'quantity': (existing['quantity'] as int) + quantity,
      }).eq('id', existing['id'] as String);
    }
  }

  Future<void> setQuantity(String id, int quantity) async {
    if (quantity <= 0) {
      await remove(id);
      return;
    }
    await _client
        .from('cart_items')
        .update({'quantity': quantity}).eq('id', id);
  }

  Future<void> remove(String id) =>
      _client.from('cart_items').delete().eq('id', id);
}
