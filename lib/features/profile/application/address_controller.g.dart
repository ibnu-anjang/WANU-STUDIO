// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddressList)
final addressListProvider = AddressListProvider._();

final class AddressListProvider
    extends $AsyncNotifierProvider<AddressList, List<Address>> {
  AddressListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressListHash();

  @$internal
  @override
  AddressList create() => AddressList();
}

String _$addressListHash() => r'd42ab38bd9f12b2f67ea9ea0486a502307fc29d8';

abstract class _$AddressList extends $AsyncNotifier<List<Address>> {
  FutureOr<List<Address>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Address>>, List<Address>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Address>>, List<Address>>,
              AsyncValue<List<Address>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
