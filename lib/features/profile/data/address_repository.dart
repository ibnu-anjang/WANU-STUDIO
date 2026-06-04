import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import 'address.dart';

part 'address_repository.g.dart';

@riverpod
AddressRepository addressRepository(Ref ref) =>
    AddressRepository(ref.watch(supabaseClientProvider));

class AddressRepository {
  AddressRepository(this._client);

  final SupabaseClient _client;

  Future<List<Address>> fetchAll() async {
    final rows = await _client
        .from('addresses')
        .select()
        .order('is_default', ascending: false);
    return rows.map(Address.fromMap).toList();
  }

  Future<void> save({
    String? id,
    required String recipientName,
    required String phone,
    required String line1,
    required String city,
    required String province,
    required String postalCode,
    required bool isDefault,
  }) async {
    final uid = _client.auth.currentUser!.id;
    if (isDefault) {
      await _client
          .from('addresses')
          .update({'is_default': false}).eq('user_id', uid);
    }
    final values = {
      'user_id': uid,
      'recipient_name': recipientName,
      'phone': phone,
      'line1': line1,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'is_default': isDefault,
    };
    if (id == null) {
      await _client.from('addresses').insert(values);
    } else {
      await _client.from('addresses').update(values).eq('id', id);
    }
  }

  Future<void> delete(String id) =>
      _client.from('addresses').delete().eq('id', id);
}
