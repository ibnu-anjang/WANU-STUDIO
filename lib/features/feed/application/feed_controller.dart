import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/feed_video.dart';
import '../data/video_repository.dart';

part 'feed_controller.g.dart';

@riverpod
class FeedVideos extends _$FeedVideos {
  @override
  Future<List<FeedVideo>> build() =>
      ref.watch(videoRepositoryProvider).fetchFeed();

  Future<void> upload({
    required Uint8List bytes,
    required String extension,
    String? caption,
    String? productId,
  }) async {
    final repo = ref.read(videoRepositoryProvider);
    final url = await repo.uploadVideo(bytes, extension);
    await repo.createVideo(
      videoUrl: url,
      caption: caption,
      productId: productId,
    );
    ref.invalidateSelf();
    await future;
  }

  // Post gambar: bytes sudah di-upload satu per satu jadi URL di layar upload.
  Future<void> uploadImagePost({
    required List<String> imageUrls,
    String? caption,
    String? productId,
  }) async {
    await ref.read(videoRepositoryProvider).createImagePost(
          imageUrls: imageUrls,
          caption: caption,
          productId: productId,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<String> uploadImageBytes(Uint8List bytes, String extension) =>
      ref.read(videoRepositoryProvider).uploadImage(bytes, extension);

  Future<void> delete(String id) async {
    await ref.read(videoRepositoryProvider).deleteVideo(id);
    ref.invalidateSelf();
    await future;
  }
}
