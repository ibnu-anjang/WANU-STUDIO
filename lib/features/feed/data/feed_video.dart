class FeedProduct {
  const FeedProduct({
    required this.id,
    required this.title,
    required this.price,
    this.coverUrl,
  });

  final String id;
  final String title;
  final int price;
  final String? coverUrl;

  factory FeedProduct.fromMap(Map<String, dynamic> map) {
    final images = (map['product_images'] as List? ?? [])
        .cast<Map<String, dynamic>>()
      ..sort(
        (a, b) =>
            (a['sort_order'] as num).compareTo(b['sort_order'] as num),
      );
    return FeedProduct(
      id: map['id'] as String,
      title: map['title'] as String,
      price: (map['base_price'] as num).toInt(),
      coverUrl: images.isEmpty ? null : images.first['url'] as String,
    );
  }
}

class FeedVideo {
  const FeedVideo({
    required this.id,
    required this.type,
    required this.caption,
    required this.creatorName,
    this.videoUrl,
    this.imageUrls = const [],
    this.thumbnailUrl,
    this.creatorAvatarUrl,
    this.product,
  });

  final String id;
  final String type; // 'video' | 'image'
  final String? videoUrl;
  final List<String> imageUrls;
  final String? caption;
  final String creatorName;
  final String? thumbnailUrl;
  final String? creatorAvatarUrl;
  final FeedProduct? product;

  bool get isImage => type == 'image';

  factory FeedVideo.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    final tags = (map['video_product_tags'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final firstProduct = tags
        .map((t) => t['products'])
        .whereType<Map<String, dynamic>>()
        .firstOrNull;
    return FeedVideo(
      id: map['id'] as String,
      type: map['type'] as String? ?? 'video',
      videoUrl: map['video_url'] as String?,
      imageUrls:
          (map['image_urls'] as List?)?.cast<String>() ?? const [],
      caption: map['caption'] as String?,
      creatorName: profile?['display_name'] as String? ??
          profile?['username'] as String? ??
          'wanu',
      thumbnailUrl: map['cf_thumbnail_url'] as String?,
      creatorAvatarUrl: profile?['avatar_url'] as String?,
      product: firstProduct == null ? null : FeedProduct.fromMap(firstProduct),
    );
  }
}
