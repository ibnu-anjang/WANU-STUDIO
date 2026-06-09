// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FeedVideos)
final feedVideosProvider = FeedVideosProvider._();

final class FeedVideosProvider
    extends $AsyncNotifierProvider<FeedVideos, List<FeedVideo>> {
  FeedVideosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedVideosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedVideosHash();

  @$internal
  @override
  FeedVideos create() => FeedVideos();
}

String _$feedVideosHash() => r'466d5b42663e48ddd1a357ca4163d68dfb9efae8';

abstract class _$FeedVideos extends $AsyncNotifier<List<FeedVideo>> {
  FutureOr<List<FeedVideo>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<FeedVideo>>, List<FeedVideo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<FeedVideo>>, List<FeedVideo>>,
              AsyncValue<List<FeedVideo>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
