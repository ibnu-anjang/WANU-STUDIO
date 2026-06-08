import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/glass.dart';
import '../../cart/application/cart_controller.dart';
import '../application/product_controller.dart';
import '../data/product.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProductsProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(cartCount: cartCount),
              ),
              catalog.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Gagal memuat: $e')),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Belum ada produk')),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg,
                      AppSpace.sm,
                      AppSpace.lg,
                      120,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: AppSpace.md,
                        mainAxisSpacing: AppSpace.md,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _ProductCard(product: products[i]),
                        childCount: products.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cartCount});

  final int cartCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Jelajah',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: GlassContainer(
                  radius: AppRadius.pill,
                  padding: const EdgeInsets.all(AppSpace.md),
                  onTap: () => context.push('/cart'),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          GlassContainer(
            radius: AppRadius.md,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: 14,
            ),
            child: Row(
              children: const [
                Icon(Icons.search, size: 20, color: AppColors.textMuted),
                SizedBox(width: AppSpace.md),
                Text(
                  'Cari produk, brand, kategori…',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadow.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.coverUrl != null
                      ? Image.network(product.coverUrl!, fit: BoxFit.cover)
                      : const ColoredBox(
                          color: AppColors.surfaceHigh,
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                  Positioned(
                    left: AppSpace.sm,
                    bottom: AppSpace.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.md,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: AppShadow.accentGlow,
                      ),
                      child: Text(
                        formatRupiah(product.basePrice),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
