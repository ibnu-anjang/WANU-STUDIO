import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import 'feed_video.dart';

part 'video_repository.g.dart';

const _select =
    'id, type, caption, video_url, image_urls, cf_thumbnail_url, created_at, '
    'profiles!videos_creator_id_fkey(username, display_name, avatar_url), '
    'video_product_tags(products(id, title, base_price, '
    'product_images(url, sort_order)))';

const _bucket = 'videos';

@riverpod
VideoRepository videoRepository(Ref ref) =>
    VideoRepository(ref.watch(supabaseClientProvider));

class VideoRepository {
  VideoRepository(this._client);

  final SupabaseClient _client;

  Future<List<FeedVideo>> fetchFeed() async {
    final rows = await _client
        .from('videos')
        .select(_select)
        .eq('status', 'ready')
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(FeedVideo.fromMap).toList();
  }

  Future<String> uploadVideo(Uint8List bytes, String extension) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mimeFor(extension)),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  Future<String> uploadImage(Uint8List bytes, String extension) async {
    final uid = _client.auth.currentUser!.id;
    final path =
        '$uid/${DateTime.now().millisecondsSinceEpoch}_${bytes.length}.$extension';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _imageMimeFor(extension)),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  Future<void> createVideo({
    required String videoUrl,
    String? caption,
    String? productId,
  }) =>
      _insertPost(
        type: 'video',
        videoUrl: videoUrl,
        caption: caption,
        productId: productId,
      );

  Future<void> createImagePost({
    required List<String> imageUrls,
    String? caption,
    String? productId,
  }) =>
      _insertPost(
        type: 'image',
        imageUrls: imageUrls,
        caption: caption,
        productId: productId,
      );

  Future<void> _insertPost({
    required String type,
    String? videoUrl,
    List<String>? imageUrls,
    String? caption,
    String? productId,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final inserted = await _client
        .from('videos')
        .insert({
          'creator_id': uid,
          'type': type,
          'caption': caption,
          'video_url': videoUrl,
          'image_urls': imageUrls,
          'status': 'ready',
        })
        .select('id')
        .single();
    if (productId != null) {
      await _client.from('video_product_tags').insert({
        'video_id': inserted['id'],
        'product_id': productId,
      });
    }
  }

  // Tag ikut terhapus via ON DELETE CASCADE. RLS membatasi ke admin.
  Future<void> deleteVideo(String id) =>
      _client.from('videos').delete().eq('id', id);

  // Edit caption + tag produk (single tag). Tag lama diganti.
  Future<void> updatePost({
    required String id,
    String? caption,
    String? productId,
  }) async {
    await _client.from('videos').update({'caption': caption}).eq('id', id);
    await _client.from('video_product_tags').delete().eq('video_id', id);
    if (productId != null) {
      await _client.from('video_product_tags').insert({
        'video_id': id,
        'product_id': productId,
      });
    }
  }

  String _mimeFor(String ext) => switch (ext.toLowerCase()) {
        'mov' => 'video/quicktime',
        'webm' => 'video/webm',
        _ => 'video/mp4',
      };

  String _imageMimeFor(String ext) => switch (ext.toLowerCase()) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
}
