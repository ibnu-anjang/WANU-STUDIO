// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MyProducts)
final myProductsProvider = MyProductsProvider._();

final class MyProductsProvider
    extends $AsyncNotifierProvider<MyProducts, List<Product>> {
  MyProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProductsHash();

  @$internal
  @override
  MyProducts create() => MyProducts();
}

String _$myProductsHash() => r'51db78486056d220abddb648eb79da55690dd900';

abstract class _$MyProducts extends $AsyncNotifier<List<Product>> {
  FutureOr<List<Product>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Product>>, List<Product>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Product>>, List<Product>>,
              AsyncValue<List<Product>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
