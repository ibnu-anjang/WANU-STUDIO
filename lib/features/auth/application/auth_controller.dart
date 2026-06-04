import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_providers.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(supabaseClientProvider)
          .auth
          .signInWithPassword(email: email, password: password),
    );
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(supabaseClientProvider)
          .auth
          .signUp(email: email, password: password),
    );
  }

  Future<void> signOut() =>
      ref.read(supabaseClientProvider).auth.signOut();
}
