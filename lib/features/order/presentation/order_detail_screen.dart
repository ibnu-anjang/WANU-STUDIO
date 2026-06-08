import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format.dart';
import '../application/order_controller.dart';
import 'order_status.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _paying = false;

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      await ref.read(ordersProvider.notifier).mockPay(widget.orderId);
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil (simulasi)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (o) => ListView(
          children: [
            ListTile(
              title: Text(o.storeName),
              trailing: orderStatusChip(o.status),
            ),
            const Divider(),
            for (final item in o.items)
              ListTile(
                dense: true,
                title: Text(item.productTitle),
                subtitle: Text('${item.variantName} · ${item.quantity}x'),
                trailing: Text(formatRupiah(item.lineTotal)),
              ),
            const Divider(),
            ListTile(
              title: const Text('Subtotal'),
              trailing: Text(formatRupiah(o.subtotal)),
            ),
            ListTile(
              title: const Text('Ongkir'),
              trailing: Text(formatRupiah(o.shippingFee)),
            ),
            ListTile(
              title: const Text('Total'),
              trailing: Text(
                formatRupiah(o.total),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (o.isPending)
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _paying ? null : _pay,
                  child: _paying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Bayar (Simulasi)'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
