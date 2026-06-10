import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../product/application/product_controller.dart';
import '../application/feed_controller.dart';
import '../data/feed_video.dart';

class EditFeedScreen extends ConsumerStatefulWidget {
  const EditFeedScreen({super.key, required this.post});

  final FeedVideo post;

  @override
  ConsumerState<EditFeedScreen> createState() => _EditFeedScreenState();
}

class _EditFeedScreenState extends ConsumerState<EditFeedScreen> {
  late final _caption = TextEditingController(text: widget.post.caption);
  late String? _productId = widget.post.product?.id;
  var _saving = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(feedVideosProvider.notifier).editPost(
            id: widget.post.id,
            caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
            productId: _productId,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit konten')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          LabeledField(
            label: 'Caption',
            child: TextField(
              controller: _caption,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Tulis caption…'),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          LabeledField(
            label: 'Tag produk',
            child: catalog.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Gagal memuat produk: $e'),
              data: (products) {
                final ids = products.map((p) => p.id).toSet();
                final value = ids.contains(_productId) ? _productId : null;
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: value,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceHigh,
                      hint: const Text('Tanpa produk'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tanpa produk'),
                        ),
                        for (final p in products)
                          DropdownMenuItem(
                            value: p.id,
                            child: Text(p.title,
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (id) => setState(() => _productId = id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SaveBar(
        label: 'Simpan',
        saving: _saving,
        onSave: _save,
      ),
    );
  }
}
