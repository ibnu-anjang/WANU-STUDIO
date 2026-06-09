import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/product.dart';
import '../data/product_repository.dart';
import '../data/product_review.dart';

part 'product_controller.g.dart';

@riverpod
Future<List<Product>> catalogProducts(Ref ref) =>
    ref.watch(productRepositoryProvider).fetchCatalog();

@riverpod
Future<Product> productDetail(Ref ref, String id) =>
    ref.watch(productRepositoryProvider).fetchDetail(id);

@riverpod
Future<List<ProductReview>> productReviews(Ref ref, String id) =>
    ref.watch(productRepositoryProvider).fetchReviews(id);

@riverpod
class MyProducts extends _$MyProducts {
  @override
  Future<List<Product>> build() =>
      ref.watch(productRepositoryProvider).fetchAll();

  Future<void> save({
    String? id,
    required String title,
    String? description,
    required int basePrice,
    required bool isActive,
    required List<VariantInput> variants,
    required List<String> imageUrls,
  }) async {
    final repo = ref.read(productRepositoryProvider);
    final productId = id ??
        await repo.create(
          title: title,
          description: description,
          basePrice: basePrice,
          isActive: isActive,
        );
    if (id != null) {
      await repo.updateFields(
        id: id,
        title: title,
        description: description,
        basePrice: basePrice,
        isActive: isActive,
      );
    }
    await repo.syncVariants(productId, variants);
    await repo.syncImages(productId, imageUrls);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await ref.read(productRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}
