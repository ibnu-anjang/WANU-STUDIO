import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../order/data/order_repository.dart';

part 'checkout_controller.g.dart';

@riverpod
class Checkout extends _$Checkout {
  @override
  void build() {}

  // Jangan sentuh `ref` setelah await: provider ini autoDispose dan keburu
  // dibuang begitu RPC selesai. Invalidasi cart/orders dilakukan di layar.
  Future<void> placeOrder(String? addressId) {
    final repo = ref.read(orderRepositoryProvider);
    return repo.createOrdersFromCart(addressId);
  }
}
