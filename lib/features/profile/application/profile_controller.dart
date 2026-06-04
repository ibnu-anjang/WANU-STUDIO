import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/profile.dart';
import '../data/profile_repository.dart';

part 'profile_controller.g.dart';

@riverpod
class CurrentProfile extends _$CurrentProfile {
  @override
  Future<Profile> build() =>
      ref.watch(profileRepositoryProvider).fetchCurrent();

  Future<void> save({
    String? username,
    String? displayName,
    String? bio,
  }) async {
    await ref.read(profileRepositoryProvider).update(
          username: username,
          displayName: displayName,
          bio: bio,
        );
    ref.invalidateSelf();
    await future;
  }
}
