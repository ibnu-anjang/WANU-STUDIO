class CartItem {
  const CartItem({
    required this.id,
    required this.variantId,
    required this.quantity,
    required this.variantName,
    required this.price,
    required this.productId,
    required this.productTitle,
    this.imageUrl,
  });

  final String id;
  final String variantId;
  final int quantity;
  final String variantName;
  final int price;
  final String productId;
  final String productTitle;
  final String? imageUrl;

  int get lineTotal => price * quantity;

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final variant = map['product_variants'] as Map<String, dynamic>;
    final product = variant['products'] as Map<String, dynamic>;
    final images = (product['product_images'] as List? ?? [])
        .cast<Map<String, dynamic>>()
      ..sort(
        (a, b) =>
            (a['sort_order'] as num).compareTo(b['sort_order'] as num),
      );
    return CartItem(
      id: map['id'] as String,
      variantId: map['variant_id'] as String,
      quantity: (map['quantity'] as num).toInt(),
      variantName: variant['name'] as String,
      price: (variant['price'] as num).toInt(),
      productId: variant['product_id'] as String,
      productTitle: product['title'] as String,
      imageUrl: images.isEmpty ? null : images.first['url'] as String,
    );
  }
}
