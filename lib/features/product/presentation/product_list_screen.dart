import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/format.dart';
import '../application/product_controller.dart';
import '../data/product.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(myProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola produk')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/products/form'),
        child: const Icon(Icons.add),
      ),
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Belum ada produk'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => _ProductTile(product: list[i]),
          );
        },
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalStock =
        product.variants.fold<int>(0, (sum, v) => sum + v.stock);
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: product.coverUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(product.coverUrl!, fit: BoxFit.cover),
              )
            : const ColoredBox(
                color: Colors.white12,
                child: Icon(Icons.image_not_supported),
              ),
      ),
      title: Text(product.title),
      subtitle: Text(
        '${formatRupiah(product.basePrice)} · stok $totalStock'
        '${product.isActive ? '' : ' · nonaktif'}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () =>
            ref.read(myProductsProvider.notifier).delete(product.id),
      ),
      onTap: () => context.push('/admin/products/form', extra: product),
    );
  }
}
