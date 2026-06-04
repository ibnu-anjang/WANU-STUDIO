import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import 'store.dart';

part 'store_repository.g.dart';

@riverpod
StoreRepository storeRepository(Ref ref) =>
    StoreRepository(ref.watch(supabaseClientProvider));

class StoreRepository {
  StoreRepository(this._client);

  final SupabaseClient _client;

  Future<Store?> fetchMine() async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client
        .from('stores')
        .select()
        .eq('owner_id', uid)
        .maybeSingle();
    return data == null ? null : Store.fromMap(data);
  }

  Future<Store> create({
    required String name,
    required String slug,
    String? description,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final data = await _client
        .from('stores')
        .insert({
          'owner_id': uid,
          'name': name,
          'slug': slug,
          'description': description,
        })
        .select()
        .single();
    await _client.from('profiles').update({'role': 'seller'}).eq('id', uid);
    return Store.fromMap(data);
  }
}
