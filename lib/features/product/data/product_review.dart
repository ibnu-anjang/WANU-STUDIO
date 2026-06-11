class ProductReview {
  const ProductReview({
    required this.rating,
    required this.createdAt,
    required this.authorName,
    this.comment,
    this.authorAvatarUrl,
  });

  final int rating;
  final DateTime createdAt;
  final String authorName;
  final String? comment;
  final String? authorAvatarUrl;

  factory ProductReview.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return ProductReview(
      rating: (map['rating'] as num).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
      authorName: profile?['display_name'] as String? ??
          profile?['username'] as String? ??
          'Pengguna',
      comment: map['comment'] as String?,
      authorAvatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
