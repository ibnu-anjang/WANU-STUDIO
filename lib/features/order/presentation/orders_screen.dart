import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/format.dart';
import '../application/order_controller.dart';
import 'order_status.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Belum ada pesanan'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final order = list[i];
              return ListTile(
                title: Text(order.storeName),
                subtitle: Text(
                  '${order.items.length} item · ${formatRupiah(order.total)}',
                ),
                trailing: orderStatusChip(order.status),
                onTap: () => context.push('/orders/${order.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
