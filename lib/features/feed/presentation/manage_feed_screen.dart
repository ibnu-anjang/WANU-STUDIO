import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/format.dart';
import '../application/feed_controller.dart';
import '../data/feed_video.dart';

class ManageFeedScreen extends ConsumerWidget {
  const ManageFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedVideosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => context.push('/feed/upload'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedVideosProvider);
          await ref.read(feedVideosProvider.future);
        },
        child: feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text('Gagal memuat: $e')),
            ],
          ),
          data: (videos) {
            if (videos.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Belum ada konten feed',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpace.lg),
              itemCount: videos.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
              itemBuilder: (_, i) => _FeedRow(video: videos[i]),
            );
          },
        ),
      ),
    );
  }
}

class _FeedRow extends ConsumerWidget {
  const _FeedRow({required this.video});

  final FeedVideo video;

  String? get _thumbUrl =>
      video.isImage && video.imageUrls.isNotEmpty
          ? video.imageUrls.first
          : video.thumbnailUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 48,
              height: 64,
              child: _thumbUrl != null
                  ? Image.network(_thumbUrl!, fit: BoxFit.cover)
                  : ColoredBox(
                      color: AppColors.surfaceHigh,
                      child: Icon(
                        video.isImage
                            ? Icons.image_outlined
                            : Icons.play_arrow_rounded,
                        color: Colors.white38,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.caption?.isNotEmpty == true
                      ? video.caption!
                      : '(tanpa caption)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                if (video.product != null)
                  Text(
                    '🏷️ ${video.product!.title} · '
                    '${formatRupiah(video.product!.price)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  )
                else
                  const Text(
                    'Tanpa produk',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            onPressed: () => context.push('/admin/feed/edit', extra: video),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus konten?'),
        content: const Text('Konten feed ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(feedVideosProvider.notifier).delete(video.id);
      messenger.showSnackBar(const SnackBar(content: Text('Konten dihapus')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }
}
