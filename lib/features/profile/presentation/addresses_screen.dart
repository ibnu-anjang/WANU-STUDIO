import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/address_controller.dart';
import '../data/address.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alamat pengiriman')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/profile/addresses/form'),
        child: const Icon(Icons.add),
      ),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Belum ada alamat'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => _AddressTile(address: list[i]),
          );
        },
      ),
    );
  }
}

class _AddressTile extends ConsumerWidget {
  const _AddressTile({required this.address});

  final Address address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.location_on),
      title: Row(
        children: [
          Flexible(child: Text(address.recipientName)),
          if (address.isDefault) ...[
            const SizedBox(width: 8),
            const Chip(
              label: Text('Utama'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${address.phone}\n${address.line1}, ${address.city}, '
        '${address.province} ${address.postalCode}',
      ),
      isThreeLine: true,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () =>
            ref.read(addressListProvider.notifier).delete(address.id),
      ),
      onTap: () =>
          context.push('/profile/addresses/form', extra: address),
    );
  }
}
