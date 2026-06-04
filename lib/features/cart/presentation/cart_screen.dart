import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format.dart';
import '../application/cart_controller.dart';
import '../data/cart_item.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Keranjang kosong'));
          }
          final subtotal =
              items.fold<int>(0, (sum, i) => sum + i.lineTotal);
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _CartTile(item: items[i]),
                ),
              ),
              _CheckoutBar(subtotal: subtotal),
            ],
          );
        },
      ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(item.imageUrl!, fit: BoxFit.cover),
              )
            : const ColoredBox(
                color: Colors.white12,
                child: Icon(Icons.image_not_supported),
              ),
      ),
      title: Text(item.productTitle),
      subtitle: Text('${item.variantName} · ${formatRupiah(item.price)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () =>
                notifier.setQuantity(item.id, item.quantity - 1),
          ),
          Text('${item.quantity}'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                notifier.setQuantity(item.id, item.quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.subtotal});

  final int subtotal;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Subtotal'),
                  Text(
                    formatRupiah(subtotal),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checkout segera hadir')),
              ),
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
