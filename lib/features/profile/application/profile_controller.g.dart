// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrentProfile)
final currentProfileProvider = CurrentProfileProvider._();

final class CurrentProfileProvider
    extends $AsyncNotifierProvider<CurrentProfile, Profile> {
  CurrentProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentProfileHash();

  @$internal
  @override
  CurrentProfile create() => CurrentProfile();
}

String _$currentProfileHash() => r'6411fd73643d2df285be86d309751639af8f46e1';

abstract class _$CurrentProfile extends $AsyncNotifier<Profile> {
  FutureOr<Profile> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Profile>, Profile>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Profile>, Profile>,
              AsyncValue<Profile>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
