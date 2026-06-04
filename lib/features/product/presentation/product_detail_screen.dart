import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format.dart';
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
      appBar: AppBar(title: const Text('Detail produk')),
      body: product.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (p) => _Detail(
          product: p,
          selectedVariantId: _variantId,
          onSelectVariant: (id) => setState(() => _variantId = id),
        ),
      ),
      bottomNavigationBar: product.maybeWhen(
        data: (p) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: (_variantId == null || _adding) ? null : _addToCart,
              child: _adding
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _variantId == null
                          ? 'Pilih varian dulu'
                          : 'Tambah ke keranjang',
                    ),
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.product,
    required this.selectedVariantId,
    required this.onSelectVariant,
  });

  final Product product;
  final String? selectedVariantId;
  final void Function(String) onSelectVariant;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (product.images.isNotEmpty)
          AspectRatio(
            aspectRatio: 1,
            child: PageView(
              children: [
                for (final img in product.images)
                  Image.network(img.url, fit: BoxFit.cover),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                formatRupiah(product.basePrice),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (product.description != null) ...[
                const SizedBox(height: 16),
                Text(product.description!),
              ],
              const SizedBox(height: 24),
              Text('Varian', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final v in product.variants)
                    ChoiceChip(
                      label: Text(
                        '${v.name} · ${formatRupiah(v.price)}'
                        '${v.stock == 0 ? ' (habis)' : ''}',
                      ),
                      selected: selectedVariantId == v.id,
                      onSelected:
                          v.stock == 0 ? null : (_) => onSelectVariant(v.id),
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
