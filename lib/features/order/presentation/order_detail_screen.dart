import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/format.dart';
import '../../profile/application/profile_controller.dart';
import '../application/order_controller.dart';
import '../data/order.dart';
import 'order_status.dart';
import 'review_dialog.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(okMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _pay() => _run(
        () => ref.read(ordersProvider.notifier).mockPay(widget.orderId),
        'Pembayaran berhasil (simulasi)',
      );

  void _setStatus(String to, String okMessage) => _run(
        () => ref.read(ordersProvider.notifier).setStatus(widget.orderId, to),
        okMessage,
      );

  Future<void> _review(OrderItem item) async {
    final result = await showReviewDialog(
      context,
      initialRating: item.reviewRating,
      initialComment: item.reviewComment,
    );
    if (result == null) return;
    await _run(
      () => ref.read(ordersProvider.notifier).submitReview(
            item.id,
            result.rating,
            result.comment,
          ),
      'Ulasan tersimpan',
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));
    final isAdmin =
        ref.watch(currentProfileProvider).value?.isAdmin ?? false;

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
            _Card(child: _StatusTimeline(status: o.status)),
            const SizedBox(height: AppSpace.md),
            _Card(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < o.items.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: AppSpace.lg),
                    _ItemRow(
                      item: o.items[i],
                      reviewable: o.isCompleted,
                      onReview: () => _review(o.items[i]),
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
        data: (o) => _actionBar(o, isAdmin),
        orElse: () => null,
      ),
    );
  }

  Widget? _actionBar(Order o, bool isAdmin) {
    if (o.isPending) {
      return _ActionBar(
        busy: _busy,
        primaryLabel: 'Bayar Sekarang (Simulasi)',
        primaryIcon: Icons.payments_outlined,
        onPrimary: _pay,
        secondaryLabel: 'Batalkan',
        onSecondary: () => _setStatus('cancelled', 'Pesanan dibatalkan'),
      );
    }
    if (isAdmin && o.adminNextStatus != null) {
      final next = o.adminNextStatus!;
      return _ActionBar(
        busy: _busy,
        primaryLabel: next == 'processing' ? 'Proses Pesanan' : 'Kirim Pesanan',
        primaryIcon: next == 'processing'
            ? Icons.inventory_2_outlined
            : Icons.local_shipping_outlined,
        onPrimary: () => _setStatus(
          next,
          next == 'processing' ? 'Pesanan diproses' : 'Pesanan dikirim',
        ),
      );
    }
    if (o.canConfirmReceipt) {
      return _ActionBar(
        busy: _busy,
        primaryLabel: 'Konfirmasi Diterima',
        primaryIcon: Icons.check_circle_outline,
        onPrimary: () => _setStatus('completed', 'Pesanan selesai'),
      );
    }
    return null;
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});

  final String status;

  static const _steps = [
    ('pending', 'Dibuat'),
    ('paid', 'Dibayar'),
    ('processing', 'Diproses'),
    ('shipped', 'Dikirim'),
    ('completed', 'Selesai'),
  ];

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled' || status == 'expired') {
      return Row(
        children: [
          const Icon(Icons.cancel_outlined,
              size: 18, color: Color(0xFFFB7185)),
          const SizedBox(width: AppSpace.sm),
          Text(
            orderStatusLabel(status),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFFFB7185),
            ),
          ),
        ],
      );
    }

    final currentIndex = _steps.indexWhere((s) => s.$1 == status);
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= currentIndex
                    ? AppColors.accentSoft
                    : AppColors.border,
              ),
            ),
          _TimelineDot(
            label: _steps[i].$2,
            done: i <= currentIndex,
            active: i == currentIndex,
          ),
        ],
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.accentSoft : AppColors.textMuted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done ? AppColors.accentSoft : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: done ? AppColors.accentSoft : AppColors.border),
          ),
          child: done
              ? Icon(
                  active ? Icons.adjust : Icons.check,
                  size: 13,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 52,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.reviewable,
    required this.onReview,
  });

  final OrderItem item;
  final bool reviewable;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.variantName} · ${item.quantity}x',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatRupiah(item.lineTotal),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (reviewable) ...[
            const SizedBox(height: AppSpace.sm),
            if (item.reviewed)
              Row(
                children: [
                  _Stars(rating: item.reviewRating!),
                  const Spacer(),
                  TextButton(
                    onPressed: onReview,
                    child: const Text('Edit ulasan'),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('Beri ulasan'),
                ),
              ),
            if (item.reviewed &&
                (item.reviewComment?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 4),
              Text(
                item.reviewComment!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 18,
            color: const Color(0xFFFBBF24),
          ),
      ],
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

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.busy,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final bool busy;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

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
              if (secondaryLabel != null) ...[
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: busy ? null : onSecondary,
                      child: Text(secondaryLabel!),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
              ],
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: busy ? null : onPrimary,
                    icon: busy
                        ? const SizedBox.shrink()
                        : Icon(primaryIcon, size: 20),
                    label: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(primaryLabel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
