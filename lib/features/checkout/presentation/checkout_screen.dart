import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/format.dart';
import '../../cart/application/cart_controller.dart';
import '../../order/application/order_controller.dart';
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
      ref.invalidate(cartProvider);
      ref.invalidate(ordersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan dibuat — lanjut bayar')),
      );
      context.go('/orders');
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      // Cart kosong server-side biasanya berarti order sudah terlanjur dibuat
      // (double-tap / cache basi). Sinkronkan cart, arahkan ke daftar pesanan.
      if (_isEmptyCart(e)) {
        ref.invalidate(cartProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keranjang kosong — cek pesanan kamu')),
        );
        context.go('/orders');
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
    }
  }

  bool _isEmptyCart(Object e) =>
      e.toString().toLowerCase().contains('cart is empty');

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
                  padding: const EdgeInsets.all(AppSpace.lg),
                  children: [
                    const _SectionLabel(
                      icon: Icons.location_on_outlined,
                      text: 'Alamat pengiriman',
                    ),
                    const SizedBox(height: AppSpace.md),
                    addresses.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpace.lg),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('Gagal memuat alamat: $e'),
                      data: (list) => _AddressSelector(
                        addresses: list,
                        selectedId: _addressId ??= _defaultId(list),
                        onChanged: (id) => setState(() => _addressId = id),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    const _SectionLabel(
                      icon: Icons.inventory_2_outlined,
                      text: 'Ringkasan pesanan',
                    ),
                    const SizedBox(height: AppSpace.md),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0)
                              const Divider(height: 1, indent: AppSpace.lg),
                            Padding(
                              padding: const EdgeInsets.all(AppSpace.lg),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          items[i].productTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${items[i].variantName} · '
                                          '${items[i].quantity}x',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(items[i].lineTotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _TotalBar(
                total: subtotal,
                placing: _placing,
                onPlace: _placing ? null : _placeOrder,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpace.sm),
        Text(text, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
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
      return GestureDetector(
        onTap: () => context.push('/profile/addresses/form'),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: const [
              Icon(Icons.add_location_alt_outlined, color: AppColors.accent),
              SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Belum ada alamat',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      'Tambah alamat pengiriman dulu',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final a in addresses)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _AddressCard(
              address: a,
              selected: selectedId == a.id,
              onTap: () => onChanged(a.id),
            ),
          ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppColors.accent : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.recipientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${address.line1}, ${address.city}, '
                    '${address.province} ${address.postalCode}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({
    required this.total,
    required this.placing,
    required this.onPlace,
  });

  final int total;
  final bool placing;
  final VoidCallback? onPlace;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgElevated,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(total),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: onPlace,
                  child: placing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Buat Pesanan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
