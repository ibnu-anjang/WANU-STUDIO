import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/address.dart';
import '../data/address_repository.dart';

part 'address_controller.g.dart';

@riverpod
class AddressList extends _$AddressList {
  @override
  Future<List<Address>> build() =>
      ref.watch(addressRepositoryProvider).fetchAll();

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
    await ref.read(addressRepositoryProvider).save(
          id: id,
          recipientName: recipientName,
          phone: phone,
          line1: line1,
          city: city,
          province: province,
          postalCode: postalCode,
          isDefault: isDefault,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await ref.read(addressRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}
