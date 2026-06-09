import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_providers.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signIn(String identifier, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      var email = identifier;
      if (!identifier.contains('@')) {
        final resolved =
            await client.rpc('email_for_username', params: {'p_username': identifier});
        if (resolved == null) throw Exception('Akun tidak ditemukan');
        email = resolved as String;
      }
      await client.auth.signInWithPassword(email: email, password: password);
    });
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
