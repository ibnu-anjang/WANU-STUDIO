import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/glass.dart';
import '../../cart/application/cart_controller.dart';
import '../application/product_controller.dart';
import '../data/product.dart';

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

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productDetailProvider(widget.productId));

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
      bottomNavigationBar: product.maybeWhen(
        data: (p) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgElevated,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: (_variantId == null || _adding) ? null : _addToCart,
                  icon: _adding
                      ? const SizedBox.shrink()
                      : const Icon(Icons.add_shopping_cart, size: 20),
                  label: _adding
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _variantId == null
                              ? 'Pilih varian dulu'
                              : 'Tambah ke keranjang',
                        ),
                ),
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
            ],
          ),
        ),
      ],
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
