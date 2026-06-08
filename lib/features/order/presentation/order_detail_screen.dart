import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
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
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            _Card(
              child: Row(
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      o.storeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  orderStatusChip(o.status),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            _Card(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < o.items.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: AppSpace.lg),
                    Padding(
                      padding: const EdgeInsets.all(AppSpace.lg),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  o.items[i].productTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${o.items[i].variantName} · '
                                  '${o.items[i].quantity}x',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatRupiah(o.items[i].lineTotal),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            _Card(
              child: Column(
                children: [
                  _SummaryRow(label: 'Subtotal', value: o.subtotal),
                  const SizedBox(height: AppSpace.md),
                  _SummaryRow(label: 'Ongkir', value: o.shippingFee),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpace.md),
                    child: Divider(height: 1),
                  ),
                  _SummaryRow(label: 'Total', value: o.total, emphasize: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: order.maybeWhen(
        data: (o) => o.isPending ? _PayBar(paying: _paying, onPay: _pay) : null,
        orElse: () => null,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(AppSpace.lg)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final int value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: emphasize ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
            fontSize: emphasize ? 16 : 14,
          ),
        ),
        Text(
          formatRupiah(value),
          style: TextStyle(
            color: emphasize ? AppColors.accentSoft : AppColors.textPrimary,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            fontSize: emphasize ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class _PayBar extends StatelessWidget {
  const _PayBar({required this.paying, required this.onPay});

  final bool paying;
  final VoidCallback onPay;

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
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: paying ? null : onPay,
              icon: paying
                  ? const SizedBox.shrink()
                  : const Icon(Icons.payments_outlined, size: 20),
              label: paying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Bayar Sekarang (Simulasi)'),
            ),
          ),
        ),
      ),
    );
  }
}
