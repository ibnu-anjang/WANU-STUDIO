import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/products/form'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Produk'),
      ),
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada produk',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.lg,
              96,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: _ProductTile(product: list[i]),
            ),
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => context.push('/admin/products/form', extra: product),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: product.coverUrl != null
                      ? Image.network(product.coverUrl!, fit: BoxFit.cover)
                      : const ColoredBox(
                          color: AppColors.surfaceHigh,
                          child: Icon(Icons.image_outlined,
                              color: AppColors.textMuted),
                        ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!product.isActive) ...[
                          const SizedBox(width: AppSpace.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.glassFill,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: const Text(
                              'Nonaktif',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      formatRupiah(product.basePrice),
                      style: const TextStyle(
                        color: AppColors.accentSoft,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stok $totalStock',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textMuted,
                ),
                onPressed: () =>
                    ref.read(myProductsProvider.notifier).delete(product.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
