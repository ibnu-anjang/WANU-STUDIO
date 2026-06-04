// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MyStore)
final myStoreProvider = MyStoreProvider._();

final class MyStoreProvider extends $AsyncNotifierProvider<MyStore, Store?> {
  MyStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myStoreHash();

  @$internal
  @override
  MyStore create() => MyStore();
}

String _$myStoreHash() => r'f8da40ec2ea9c56bfa89b5a6710a65c401bc479d';

abstract class _$MyStore extends $AsyncNotifier<Store?> {
  FutureOr<Store?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Store?>, Store?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Store?>, Store?>,
              AsyncValue<Store?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
