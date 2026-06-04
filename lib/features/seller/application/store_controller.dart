import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../profile/application/profile_controller.dart';
import '../data/store.dart';
import '../data/store_repository.dart';

part 'store_controller.g.dart';

@riverpod
class MyStore extends _$MyStore {
  @override
  Future<Store?> build() => ref.watch(storeRepositoryProvider).fetchMine();

  Future<void> becomeSeller({
    required String name,
    required String slug,
    String? description,
  }) async {
    await ref.read(storeRepositoryProvider).create(
          name: name,
          slug: slug,
          description: description,
        );
    ref.invalidateSelf();
    ref.invalidate(currentProfileProvider);
    await future;
  }
}
