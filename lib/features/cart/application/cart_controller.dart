import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/cart_item.dart';
import '../data/cart_repository.dart';

part 'cart_controller.g.dart';

@riverpod
class Cart extends _$Cart {
  @override
  Future<List<CartItem>> build() =>
      ref.watch(cartRepositoryProvider).fetchItems();

  Future<void> add(String variantId, int quantity) async {
    await ref.read(cartRepositoryProvider).addVariant(variantId, quantity);
    ref.invalidateSelf();
    await future;
  }

  Future<void> setQuantity(String id, int quantity) async {
    await ref.read(cartRepositoryProvider).setQuantity(id, quantity);
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String id) async {
    await ref.read(cartRepositoryProvider).remove(id);
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
int cartCount(Ref ref) {
  final cart = ref.watch(cartProvider).asData?.value ?? [];
  return cart.fold(0, (sum, item) => sum + item.quantity);
}
