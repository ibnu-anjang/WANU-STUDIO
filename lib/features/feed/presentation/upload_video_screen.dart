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

class _UploadVideoScreenState extends ConsumerState<UploadVideoScreen> {
  final _caption = TextEditingController();
  XFile? _picked;
  String? _productId;
  var _uploading = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file != null) setState(() => _picked = file);
  }

  Future<void> _upload() async {
    final file = _picked;
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'mp4';
      await ref.read(feedVideosProvider.notifier).upload(
            bytes: bytes,
            extension: ext,
            caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
            productId: _productId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video diupload')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload video')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          GestureDetector(
            onTap: _uploading ? null : _pick,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: _picked != null
                      ? AppColors.accent
                      : AppColors.borderStrong,
                  width: _picked != null ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _picked != null
                          ? Icons.check_circle_outline
                          : Icons.video_call_outlined,
                      size: 40,
                      color: _picked != null
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      _picked?.name ?? 'Pilih video dari galeri',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
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
        onSave: _picked == null ? null : _upload,
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
