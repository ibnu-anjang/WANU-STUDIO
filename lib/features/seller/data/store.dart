class Store {
  const Store({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.slug,
    required this.isVerified,
    this.logoUrl,
    this.description,
  });

  final String id;
  final String ownerId;
  final String name;
  final String slug;
  final bool isVerified;
  final String? logoUrl;
  final String? description;

  factory Store.fromMap(Map<String, dynamic> map) => Store(
    id: map['id'] as String,
    ownerId: map['owner_id'] as String,
    name: map['name'] as String,
    slug: map['slug'] as String,
    isVerified: map['is_verified'] as bool,
    logoUrl: map['logo_url'] as String?,
    description: map['description'] as String?,
  );
}
