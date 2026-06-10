import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/format.dart';
import '../../profile/application/profile_controller.dart';
import '../application/feed_controller.dart';
import '../data/feed_video.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedVideosProvider);
    final isAdmin =
        ref.watch(currentProfileProvider).value?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          feed.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => _FeedMessage(
              icon: Icons.error_outline,
              text: 'Gagal memuat feed:\n$e',
            ),
            data: (videos) {
              if (videos.isEmpty) {
                return const _FeedMessage(
                  icon: Icons.video_library_outlined,
                  text: 'Belum ada video.\nUpload yang pertama!',
                );
              }
              return PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: videos.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _VideoPage(
                  video: videos[i],
                  active: i == _page,
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
              child: Row(
                children: [
                  Image.asset(
                    'assets/logo-mark.png',
                    height: 40,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    'WANU STUDIO',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => ref.invalidate(feedVideosProvider),
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 26),
                  ),
                  if (isAdmin)
                    IconButton(
                      onPressed: () => context.push('/feed/upload'),
                      icon: const Icon(Icons.add_box_outlined,
                          color: Colors.white, size: 28),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.white38),
          const SizedBox(height: AppSpace.lg),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _VideoPage extends ConsumerStatefulWidget {
  const _VideoPage({required this.video, required this.active});

  final FeedVideo video;
  final bool active;

  @override
  ConsumerState<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends ConsumerState<_VideoPage> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl));
    _controller = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      if (!mounted) return;
      setState(() => _ready = true);
      if (widget.active) c.play();
    } catch (_) {
      // leave thumbnail/placeholder if the video fails to load
    }
  }

  @override
  void didUpdateWidget(_VideoPage old) {
    super.didUpdateWidget(old);
    final c = _controller;
    if (c == null || !_ready) return;
    if (widget.active && !old.active) {
      c.play();
    } else if (!widget.active && old.active) {
      c
        ..pause()
        ..seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !_ready) return;
    c.value.isPlaying ? c.pause() : c.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    final c = _controller;

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready && c != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            )
          else
            _Placeholder(thumbnailUrl: v.thumbnailUrl),
          if (_ready && c != null && !c.value.isPlaying)
            const Center(
              child: Icon(Icons.play_arrow_rounded,
                  size: 72, color: Colors.white70),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xE6000000)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                0,
                AppSpace.lg,
                100,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_Overlay(video: v)],
              ),
            ),
          ),
          if (_ready && c != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: VideoProgressIndicator(
                  c,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.sm,
                  ),
                  colors: const VideoProgressColors(
                    playedColor: AppColors.accent,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.thumbnailUrl});

  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl != null) {
      return Image.network(thumbnailUrl!, fit: BoxFit.cover);
    }
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1130), Color(0xFF06060A)],
        ),
      ),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.video});

  final FeedVideo video;

  @override
  Widget build(BuildContext context) {
    final p = video.product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceHigh,
              backgroundImage: video.creatorAvatarUrl != null
                  ? NetworkImage(video.creatorAvatarUrl!)
                  : null,
              child: video.creatorAvatarUrl == null
                  ? const Icon(Icons.person, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              '@${video.creatorName}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        if (video.caption != null) ...[
          const SizedBox(height: AppSpace.md),
          Text(
            video.caption!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
          ),
        ],
        if (p != null) ...[
          const SizedBox(height: AppSpace.md),
          GestureDetector(
            onTap: () => context.push('/product/${p.id}'),
            child: Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: const Color(0x80000000),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: p.coverUrl != null
                          ? Image.network(p.coverUrl!, fit: BoxFit.cover)
                          : const ColoredBox(
                              color: AppColors.surfaceHigh,
                              child: Icon(Icons.image_outlined,
                                  size: 20, color: Colors.white38),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatRupiah(p.price),
                          style: const TextStyle(
                            color: AppColors.accentSoft,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      'Lihat Produk',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

