class OrderItem {
  const OrderItem({
    required this.productTitle,
    required this.variantName,
    required this.unitPrice,
    required this.quantity,
  });

  final String productTitle;
  final String variantName;
  final int unitPrice;
  final int quantity;

  int get lineTotal => unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productTitle: map['product_title'] as String,
    variantName: map['variant_name'] as String,
    unitPrice: (map['unit_price'] as num).toInt(),
    quantity: (map['quantity'] as num).toInt(),
  );
}

class Order {
  const Order({
    required this.id,
    required this.storeName,
    required this.status,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.createdAt,
    required this.paymentStatus,
    required this.items,
  });

  final String id;
  final String storeName;
  final String status;
  final int subtotal;
  final int shippingFee;
  final int total;
  final DateTime createdAt;
  final String? paymentStatus;
  final List<OrderItem> items;

  bool get isPending => status == 'pending';

  factory Order.fromMap(Map<String, dynamic> map) {
    final store = map['stores'] as Map<String, dynamic>?;
    final rawPayment = map['payments'];
    final payment = rawPayment is List
        ? (rawPayment.isEmpty ? null : rawPayment.first as Map<String, dynamic>)
        : rawPayment as Map<String, dynamic>?;
    final items = (map['order_items'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(OrderItem.fromMap)
        .toList();
    return Order(
      id: map['id'] as String,
      storeName: store?['name'] as String? ?? 'Toko',
      status: map['status'] as String,
      subtotal: (map['subtotal'] as num).toInt(),
      shippingFee: (map['shipping_fee'] as num).toInt(),
      total: (map['total'] as num).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
      paymentStatus: payment?['status'] as String?,
      items: items,
    );
  }
}
