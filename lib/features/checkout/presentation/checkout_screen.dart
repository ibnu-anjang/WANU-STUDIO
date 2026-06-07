import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/format.dart';
import '../../cart/application/cart_controller.dart';
import '../../profile/application/address_controller.dart';
import '../../profile/data/address.dart';
import '../application/checkout_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _addressId;
  bool _placing = false;

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    try {
      await ref.read(checkoutProvider.notifier).placeOrder(_addressId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan dibuat — lanjut bayar')),
      );
      context.go('/orders');
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final addresses = ref.watch(addressListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Keranjang kosong'));
          }
          final subtotal = items.fold<int>(0, (sum, i) => sum + i.lineTotal);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    addresses.when(
                      loading: () => const ListTile(
                        leading: Icon(Icons.location_on_outlined),
                        title: Text('Memuat alamat…'),
                      ),
                      error: (e, _) => ListTile(
                        leading: const Icon(Icons.error_outline),
                        title: Text('Gagal memuat alamat: $e'),
                      ),
                      data: (list) => _AddressSelector(
                        addresses: list,
                        selectedId: _addressId ??= _defaultId(list),
                        onChanged: (id) => setState(() => _addressId = id),
                      ),
                    ),
                    const Divider(),
                    for (final item in items)
                      ListTile(
                        dense: true,
                        title: Text(item.productTitle),
                        subtitle: Text(
                          '${item.variantName} · ${item.quantity}x',
                        ),
                        trailing: Text(formatRupiah(item.lineTotal)),
                      ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total'),
                            Text(
                              formatRupiah(subtotal),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: _placing ? null : _placeOrder,
                        child: _placing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Buat Pesanan'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _defaultId(List<Address> list) {
    if (list.isEmpty) return null;
    return list.firstWhere((a) => a.isDefault, orElse: () => list.first).id;
  }
}

class _AddressSelector extends StatelessWidget {
  const _AddressSelector({
    required this.addresses,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Address> addresses;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (addresses.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.add_location_alt_outlined),
        title: const Text('Belum ada alamat'),
        subtitle: const Text('Tambah alamat pengiriman dulu'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/profile/addresses/form'),
      );
    }
    return RadioGroup<String>(
      groupValue: selectedId,
      onChanged: onChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Alamat pengiriman'),
          ),
          for (final a in addresses)
            RadioListTile<String>(
              value: a.id,
              title: Text(a.recipientName),
              subtitle: Text(
                '${a.line1}, ${a.city}, ${a.province} ${a.postalCode}',
              ),
            ),
        ],
      ),
    );
  }
}
