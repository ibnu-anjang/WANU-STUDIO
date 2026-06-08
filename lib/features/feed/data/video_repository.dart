import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import 'feed_video.dart';

part 'video_repository.g.dart';

const _select = 'id, caption, video_url, cf_thumbnail_url, created_at, '
    'profiles(username, display_name, avatar_url), '
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

  Future<void> createVideo({
    required String videoUrl,
    String? caption,
    String? productId,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final inserted = await _client
        .from('videos')
        .insert({
          'creator_id': uid,
          'caption': caption,
          'video_url': videoUrl,
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

  String _mimeFor(String ext) => switch (ext.toLowerCase()) {
        'mov' => 'video/quicktime',
        'webm' => 'video/webm',
        _ => 'video/mp4',
      };
}
