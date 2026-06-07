import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../cart/application/cart_controller.dart';
import '../../order/application/order_controller.dart';
import '../../order/data/order_repository.dart';

part 'checkout_controller.g.dart';

@riverpod
class Checkout extends _$Checkout {
  @override
  void build() {}

  Future<void> placeOrder(String? addressId) async {
    await ref.read(orderRepositoryProvider).createOrdersFromCart(addressId);
    ref.invalidate(cartProvider);
    ref.invalidate(ordersProvider);
  }
}
