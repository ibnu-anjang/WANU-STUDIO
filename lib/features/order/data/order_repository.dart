import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import 'order.dart';

part 'order_repository.g.dart';

const _select =
    'id, status, subtotal, shipping_fee, total, created_at, '
    'stores(name), '
    'order_items(product_title, variant_name, unit_price, quantity), '
    'payments(status)';

@riverpod
OrderRepository orderRepository(Ref ref) =>
    OrderRepository(ref.watch(supabaseClientProvider));

class OrderRepository {
  OrderRepository(this._client);

  final SupabaseClient _client;

  Future<List<Order>> fetchOrders() async {
    final rows = await _client
        .from('orders')
        .select(_select)
        .order('created_at', ascending: false);
    return rows.map(Order.fromMap).toList();
  }

  Future<Order> fetchOrder(String id) async {
    final row = await _client.from('orders').select(_select).eq('id', id).single();
    return Order.fromMap(row);
  }

  Future<void> createOrdersFromCart(String? addressId) =>
      _client.rpc('create_orders_from_cart', params: {'p_address_id': addressId});

  // MOCK: simulasi webhook Midtrans. Saat gateway aktif, dipindah ke server.
  Future<void> markPaid(String orderId) =>
      _client.rpc('mark_order_paid', params: {'p_order_id': orderId});
}
