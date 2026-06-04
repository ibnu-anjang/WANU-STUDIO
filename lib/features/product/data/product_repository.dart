import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import 'product.dart';

part 'product_repository.g.dart';

const _bucket = 'product-images';
const _selectWithRelations = '*, product_variants(*), product_images(*)';

@riverpod
ProductRepository productRepository(Ref ref) =>
    ProductRepository(ref.watch(supabaseClientProvider));

class ProductRepository {
  ProductRepository(this._client);

  final SupabaseClient _client;

  Future<List<Product>> fetchByStore(String storeId) async {
    final rows = await _client
        .from('products')
        .select(_selectWithRelations)
        .eq('store_id', storeId)
        .order('created_at', ascending: false);
    return rows.map(Product.fromMap).toList();
  }

  Future<Product> fetchDetail(String id) async {
    final data = await _client
        .from('products')
        .select(_selectWithRelations)
        .eq('id', id)
        .single();
    return Product.fromMap(data);
  }

  Future<String> uploadImage(Uint8List bytes, String extension) async {
    final uid = _client.auth.currentUser!.id;
    final path =
        '$uid/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _client.storage.from(_bucket).uploadBinary(path, bytes);
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  Future<String> create({
    required String storeId,
    required String title,
    String? description,
    required int basePrice,
    required bool isActive,
  }) async {
    final data = await _client
        .from('products')
        .insert({
          'store_id': storeId,
          'title': title,
          'description': description,
          'base_price': basePrice,
          'is_active': isActive,
        })
        .select('id')
        .single();
    return data['id'] as String;
  }

  Future<void> updateFields({
    required String id,
    required String title,
    String? description,
    required int basePrice,
    required bool isActive,
  }) =>
      _client.from('products').update({
        'title': title,
        'description': description,
        'base_price': basePrice,
        'is_active': isActive,
      }).eq('id', id);

  Future<void> syncVariants(
    String productId,
    List<VariantInput> variants,
  ) async {
    final existing = await _client
        .from('product_variants')
        .select('id')
        .eq('product_id', productId);
    final keptIds = variants.map((v) => v.id).whereType<String>().toSet();
    final toDelete = existing
        .map((e) => e['id'] as String)
        .where((id) => !keptIds.contains(id))
        .toList();
    if (toDelete.isNotEmpty) {
      await _client
          .from('product_variants')
          .delete()
          .inFilter('id', toDelete);
    }
    for (final v in variants) {
      final values = {
        'product_id': productId,
        'name': v.name,
        'price': v.price,
        'stock': v.stock,
      };
      if (v.id == null) {
        await _client.from('product_variants').insert(values);
      } else {
        await _client
            .from('product_variants')
            .update(values)
            .eq('id', v.id!);
      }
    }
  }

  Future<void> syncImages(String productId, List<String> urls) async {
    await _client.from('product_images').delete().eq('product_id', productId);
    if (urls.isEmpty) return;
    await _client.from('product_images').insert([
      for (var i = 0; i < urls.length; i++)
        {'product_id': productId, 'url': urls[i], 'sort_order': i},
    ]);
  }

  Future<void> delete(String id) =>
      _client.from('products').delete().eq('id', id);
}
