import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/glass.dart';
import '../../cart/application/cart_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../application/product_controller.dart';
import '../data/product.dart';
import '../data/product_review.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _variantId;
  var _adding = false;
  var _buying = false;

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    try {
      await ref.read(cartProvider.notifier).add(_variantId!, 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ditambahkan ke keranjang')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _buyNow() async {
    setState(() => _buying = true);
    try {
      await ref.read(cartProvider.notifier).add(_variantId!, 1);
      if (mounted) context.push('/checkout');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productDetailProvider(widget.productId));
    final isAdmin = ref.watch(currentProfileProvider).value?.isAdmin ?? false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(AppSpace.sm),
          child: GlassContainer(
            radius: AppRadius.pill,
            padding: const EdgeInsets.all(AppSpace.sm),
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
        ),
      ),
      body: AppBackground(
        child: product.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Gagal memuat: $e')),
          data: (p) => _Detail(
            product: p,
            selectedVariantId: _variantId,
            onSelectVariant: (id) => setState(() => _variantId = id),
          ),
        ),
      ),
      bottomNavigationBar: isAdmin
          ? null
          : product.maybeWhen(
        data: (p) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgElevated,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: _variantId == null
                  ? const SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: null,
                        child: Text('Pilih varian dulu'),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: (_adding || _buying) ? null : _addToCart,
                              icon: _adding
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add_shopping_cart,
                                      size: 20),
                              label: const Text('Keranjang'),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: FilledButton(
                              onPressed: (_adding || _buying) ? null : _buyNow,
                              child: _buying
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Beli Sekarang'),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _Detail extends StatefulWidget {
  const _Detail({
    required this.product,
    required this.selectedVariantId,
    required this.onSelectVariant,
  });

  final Product product;
  final String? selectedVariantId;
  final void Function(String) onSelectVariant;

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (product.images.isNotEmpty)
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: PageView(
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    for (final img in product.images)
                      Image.network(img.url, fit: BoxFit.cover),
                  ],
                ),
              ),
              if (product.images.length > 1)
                Positioned(
                  bottom: AppSpace.lg,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < product.images.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? Colors.white
                                : Colors.white38,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpace.md),
              ShaderMask(
                shaderCallback: (r) =>
                    AppColors.accentGradient.createShader(r),
                child: Text(
                  formatRupiah(product.basePrice),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (product.description != null) ...[
                const SizedBox(height: AppSpace.xl),
                Text(
                  'Deskripsi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  product.description!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.xl),
              Text(
                'Pilih varian',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final v in product.variants)
                    _VariantChip(
                      variant: v,
                      selected: widget.selectedVariantId == v.id,
                      onTap: v.stock == 0
                          ? null
                          : () => widget.onSelectVariant(v.id),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              _ReviewsSection(productId: product.id),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(productReviewsProvider(productId));

    return reviews.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        final avg = list.isEmpty
            ? 0.0
            : list.map((r) => r.rating).reduce((a, b) => a + b) / list.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Ulasan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: AppSpace.sm),
                if (list.isNotEmpty) ...[
                  const Icon(Icons.star_rounded,
                      size: 18, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 2),
                  Text(
                    '${avg.toStringAsFixed(1)} · ${list.length} ulasan',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.md),
            if (list.isEmpty)
              const Text(
                'Belum ada ulasan.',
                style: TextStyle(color: AppColors.textMuted),
              )
            else
              for (final r in list) ...[
                _ReviewTile(review: r),
                const SizedBox(height: AppSpace.md),
              ],
          ],
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.bgElevated,
                backgroundImage: review.authorAvatarUrl != null
                    ? NetworkImage(review.authorAvatarUrl!)
                    : null,
                child: review.authorAvatarUrl == null
                    ? const Icon(Icons.person, size: 14)
                    : null,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  review.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 14,
                      color: const Color(0xFFFBBF24),
                    ),
                ],
              ),
            ],
          ),
          if (review.comment?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              review.comment!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final ProductVariant variant;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        decoration: BoxDecoration(
          color: selected ? null : AppColors.surface,
          gradient: selected ? AppColors.accentGradient : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              variant.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: disabled
                    ? AppColors.textMuted
                    : selected
                        ? Colors.white
                        : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              variant.stock == 0
                  ? 'Habis'
                  : formatRupiah(variant.price),
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
