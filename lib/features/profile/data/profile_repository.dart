import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import 'profile.dart';

part 'profile_repository.g.dart';

@riverpod
ProfileRepository profileRepository(Ref ref) =>
    ProfileRepository(ref.watch(supabaseClientProvider));

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile> fetchCurrent() async {
    final uid = _client.auth.currentUser!.id;
    final data =
        await _client.from('profiles').select().eq('id', uid).single();
    return Profile.fromMap(data);
  }

  Future<void> update({
    String? username,
    String? displayName,
    String? bio,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('profiles').update({
      'username': username,
      'display_name': displayName,
      'bio': bio,
    }).eq('id', uid);
  }

  // Promote user existing jadi admin via username/email. Mengembalikan nama
  // yang dipromosikan. Otorisasi & validasi dijaga RPC server-side.
  Future<String> promoteToAdmin(String identifier) async {
    final name = await _client
        .rpc('promote_to_admin', params: {'p_identifier': identifier});
    return name as String;
  }
}
