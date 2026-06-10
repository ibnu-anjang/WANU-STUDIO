import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/glass.dart';
import '../../../shared/widgets/preorder_badge.dart';
import '../../cart/application/cart_controller.dart';
import '../application/product_controller.dart';
import '../data/product.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> _filter(List<Product> products) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products.where((p) => p.title.toLowerCase().contains(q)).toList();
  }

  Future<void> _refresh() async {
    ref.invalidate(catalogProductsProvider);
    await ref.read(catalogProductsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProductsProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    cartCount: cartCount,
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                  ),
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
                    final list = _filter(products);
                    if (list.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            _query.isEmpty
                                ? 'Belum ada produk'
                                : 'Tidak ada hasil untuk "$_query"',
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                        ),
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
                          childAspectRatio: 0.72,
                          crossAxisSpacing: AppSpace.md,
                          mainAxisSpacing: AppSpace.md,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _ProductCard(product: list[i]),
                          childCount: list.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cartCount,
    required this.controller,
    required this.onChanged,
  });

  final int cartCount;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

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
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                      border: InputBorder.none,
                      hintText: 'Cari produk…',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: const Icon(Icons.close,
                        size: 18, color: AppColors.textMuted),
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
            AspectRatio(
              aspectRatio: 1,
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
                  if (product.preorderLabel != null)
                    Positioned(
                      left: AppSpace.sm,
                      top: AppSpace.sm,
                      child: PreorderBadge(label: product.preorderLabel!),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
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
            ),
          ],
        ),
      ),
    );
  }
}
