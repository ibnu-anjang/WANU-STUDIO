import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/order.dart';
import '../data/order_repository.dart';

part 'order_controller.g.dart';

@riverpod
class Orders extends _$Orders {
  @override
  Future<List<Order>> build() =>
      ref.watch(orderRepositoryProvider).fetchOrders();

  Future<void> mockPay(String orderId) async {
    await ref.read(orderRepositoryProvider).markPaid(orderId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> setStatus(String orderId, String to) async {
    await ref.read(orderRepositoryProvider).setStatus(orderId, to);
    ref.invalidateSelf();
    await future;
  }

  Future<void> submitReview(
    String orderItemId,
    int rating,
    String? comment,
  ) async {
    await ref.read(orderRepositoryProvider).submitReview(orderItemId, rating, comment);
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
Future<Order> orderDetail(Ref ref, String id) =>
    ref.watch(orderRepositoryProvider).fetchOrder(id);
