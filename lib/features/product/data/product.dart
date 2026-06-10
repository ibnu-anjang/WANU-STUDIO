class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.sku,
  });

  final String id;
  final String name;
  final int price;
  final int stock;
  final String? sku;

  factory ProductVariant.fromMap(Map<String, dynamic> map) => ProductVariant(
    id: map['id'] as String,
    name: map['name'] as String,
    price: (map['price'] as num).toInt(),
    stock: (map['stock'] as num).toInt(),
    sku: map['sku'] as String?,
  );
}

class ProductImage {
  const ProductImage({
    required this.id,
    required this.url,
    required this.sortOrder,
  });

  final String id;
  final String url;
  final int sortOrder;

  factory ProductImage.fromMap(Map<String, dynamic> map) => ProductImage(
    id: map['id'] as String,
    url: map['url'] as String,
    sortOrder: (map['sort_order'] as num).toInt(),
  );
}

class Product {
  const Product({
    required this.id,
    required this.storeId,
    required this.title,
    required this.basePrice,
    required this.isActive,
    this.description,
    this.isPreorder = false,
    this.preorderDays,
    this.variants = const [],
    this.images = const [],
  });

  final String id;
  final String storeId;
  final String title;
  final int basePrice;
  final bool isActive;
  final String? description;
  final bool isPreorder;
  final int? preorderDays;
  final List<ProductVariant> variants;
  final List<ProductImage> images;

  String? get coverUrl => images.isEmpty ? null : images.first.url;

  String? get preorderLabel =>
      isPreorder ? 'PO ${preorderDays ?? '?'} hari' : null;

  factory Product.fromMap(Map<String, dynamic> map) {
    final variants = (map['product_variants'] as List? ?? [])
        .map((e) => ProductVariant.fromMap(e as Map<String, dynamic>))
        .toList();
    final images = (map['product_images'] as List? ?? [])
        .map((e) => ProductImage.fromMap(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Product(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      title: map['title'] as String,
      basePrice: (map['base_price'] as num).toInt(),
      isActive: map['is_active'] as bool,
      description: map['description'] as String?,
      isPreorder: map['is_preorder'] as bool? ?? false,
      preorderDays: (map['preorder_days'] as num?)?.toInt(),
      variants: variants,
      images: images,
    );
  }
}

class VariantInput {
  VariantInput({this.id, this.name = '', this.price = 0, this.stock = 0});

  final String? id;
  String name;
  int price;
  int stock;
}
