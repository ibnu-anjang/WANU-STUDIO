import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../product/application/product_controller.dart';
import '../../product/data/product.dart';
import '../application/feed_controller.dart';

class UploadVideoScreen extends ConsumerStatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  ConsumerState<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

enum _Mode { video, image }

class _UploadVideoScreenState extends ConsumerState<UploadVideoScreen> {
  final _caption = TextEditingController();
  _Mode _mode = _Mode.video;
  XFile? _video;
  final List<String> _imageUrls = [];
  String? _productId;
  var _uploading = false;
  var _pickingImages = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  bool get _hasMedia =>
      _mode == _Mode.video ? _video != null : _imageUrls.isNotEmpty;

  Future<void> _pickVideo() async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file != null) setState(() => _video = file);
  }

  // Upload tiap gambar segera (seperti form produk) → preview pakai URL,
  // konsisten lintas web/mobile tanpa pusing path lokal.
  Future<void> _pickImages() async {
    final messenger = ScaffoldMessenger.of(context);
    final files = await ImagePicker().pickMultiImage(limit: 10);
    if (files.isEmpty) return;
    setState(() => _pickingImages = true);
    try {
      final notifier = ref.read(feedVideosProvider.notifier);
      for (final img in files) {
        final bytes = await img.readAsBytes();
        final url =
            await notifier.uploadImageBytes(bytes, _extOf(img.name, 'jpg'));
        if (!mounted) return;
        setState(() => _imageUrls.add(url));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _pickingImages = false);
    }
  }

  String _extOf(String name, String fallback) =>
      name.contains('.') ? name.split('.').last.toLowerCase() : fallback;

  Future<void> _upload() async {
    if (!_hasMedia) return;
    setState(() => _uploading = true);
    final messenger = ScaffoldMessenger.of(context);
    final caption =
        _caption.text.trim().isEmpty ? null : _caption.text.trim();
    try {
      final notifier = ref.read(feedVideosProvider.notifier);
      if (_mode == _Mode.video) {
        final bytes = await _video!.readAsBytes();
        await notifier.upload(
          bytes: bytes,
          extension: _extOf(_video!.name, 'mp4'),
          caption: caption,
          productId: _productId,
        );
      } else {
        await notifier.uploadImagePost(
          imageUrls: _imageUrls,
          caption: caption,
          productId: _productId,
        );
      }
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Konten diupload')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      messenger.showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload konten')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          SegmentedButton<_Mode>(
            segments: const [
              ButtonSegment(
                value: _Mode.video,
                label: Text('Video'),
                icon: Icon(Icons.videocam_outlined),
              ),
              ButtonSegment(
                value: _Mode.image,
                label: Text('Gambar'),
                icon: Icon(Icons.image_outlined),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: _uploading
                ? null
                : (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: AppSpace.lg),
          if (_mode == _Mode.video)
            _VideoDropZone(
              picked: _video,
              onTap: _uploading ? null : _pickVideo,
            )
          else
            _ImageDropZone(
              urls: _imageUrls,
              busy: _uploading || _pickingImages,
              onAdd: _pickImages,
              onRemove: (i) => setState(() => _imageUrls.removeAt(i)),
            ),
          const SizedBox(height: AppSpace.lg),
          LabeledField(
            label: 'Caption',
            child: TextField(
              controller: _caption,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Tulis caption…',
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          LabeledField(
            label: 'Tag produk (opsional)',
            child: catalog.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Gagal memuat produk: $e'),
              data: (products) => _ProductPicker(
                products: products,
                selectedId: _productId,
                onChanged: (id) => setState(() => _productId = id),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SaveBar(
        label: 'Upload',
        saving: _uploading,
        onSave: _hasMedia ? _upload : null,
      ),
    );
  }
}

class _VideoDropZone extends StatelessWidget {
  const _VideoDropZone({required this.picked, required this.onTap});

  final XFile? picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: picked != null ? AppColors.accent : AppColors.borderStrong,
            width: picked != null ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                picked != null
                    ? Icons.check_circle_outline
                    : Icons.video_call_outlined,
                size: 40,
                color:
                    picked != null ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                picked?.name ?? 'Pilih video dari galeri',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageDropZone extends StatelessWidget {
  const _ImageDropZone({
    required this.urls,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> urls;
  final bool busy;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < urls.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.sm),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.network(
                      urls[i],
                      width: 100,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: AppSpace.xs,
                    right: AppSpace.xs,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black87,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: busy ? null : onAdd,
            child: Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.borderStrong),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: busy
                  ? const Center(child: CircularProgressIndicator())
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: AppColors.textSecondary),
                        SizedBox(height: AppSpace.xs),
                        Text('Tambah',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPicker extends StatelessWidget {
  const _ProductPicker({
    required this.products,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Product> products;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Text(
        'Belum ada produk untuk ditag',
        style: TextStyle(color: AppColors.textMuted),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedId,
          isExpanded: true,
          dropdownColor: AppColors.surfaceHigh,
          hint: const Text('Tanpa produk'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tanpa produk')),
            for (final p in products)
              DropdownMenuItem(
                value: p.id,
                child: Text(p.title, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
