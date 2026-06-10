import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/format.dart';
import '../application/order_controller.dart';
import '../data/order.dart';
import 'order_status.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ordersProvider);
            await ref.read(ordersProvider.future);
          },
          child: orders.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListView(
              children: [
                const SizedBox(height: 120),
                Center(child: Text('Gagal memuat: $e')),
              ],
            ),
            data: (list) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg,
                      AppSpace.lg,
                      AppSpace.lg,
                      AppSpace.md,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Pesanan Masuk',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  if (list.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'Belum ada pesanan masuk',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        0,
                        AppSpace.lg,
                        120,
                      ),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpace.md),
                        itemBuilder: (_, i) => _AdminOrderCard(order: list[i]),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AdminOrderCard extends ConsumerWidget {
  const _AdminOrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = order.adminNextStatus;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${order.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  orderStatusChip(order.status),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                formatDateTime(order.createdAt),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${order.items.length} item',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    formatRupiah(order.total),
                    style: const TextStyle(
                      color: AppColors.accentSoft,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (next != null) ...[
                const SizedBox(height: AppSpace.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _advance(context, ref, next),
                    child: Text(
                      next == 'processing' ? 'Proses Pesanan' : 'Kirim Pesanan',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _advance(
    BuildContext context,
    WidgetRef ref,
    String to,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(ordersProvider.notifier).setStatus(order.id, to);
      messenger.showSnackBar(
        SnackBar(content: Text('Status → ${orderStatusLabel(to)}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }
}
