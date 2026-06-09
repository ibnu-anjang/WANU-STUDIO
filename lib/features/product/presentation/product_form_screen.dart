import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/form_fields.dart';
import '../application/product_controller.dart';
import '../data/product.dart';
import '../data/product_repository.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.existing});

  final Product? existing;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _description =
      TextEditingController(text: widget.existing?.description);
  late final _basePrice = TextEditingController(
    text: widget.existing?.basePrice.toString(),
  );
  late bool _isActive = widget.existing?.isActive ?? true;
  late final List<VariantInput> _variants = widget.existing == null
      ? [VariantInput(name: 'Default')]
      : widget.existing!.variants
          .map((v) => VariantInput(
                id: v.id,
                name: v.name,
                price: v.price,
                stock: v.stock,
              ))
          .toList();
  late final List<String> _imageUrls =
      widget.existing?.images.map((e) => e.url).toList() ?? [];
  var _uploading = false;
  var _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _basePrice.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final url = await ref
          .read(productRepositoryProvider)
          .uploadImage(bytes, ext);
      setState(() => _imageUrls.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal satu varian')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(myProductsProvider.notifier).save(
            id: widget.existing?.id,
            title: _title.text.trim(),
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            basePrice: int.parse(_basePrice.text.trim()),
            isActive: _isActive,
            variants: _variants,
            imageUrls: _imageUrls,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Produk baru' : 'Edit produk'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            LabeledField(
              label: 'Foto produk',
              child: _ImagePicker(
                urls: _imageUrls,
                uploading: _uploading,
                onAdd: _pickImage,
                onRemove: (i) => setState(() => _imageUrls.removeAt(i)),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            LabeledField(
              label: 'Nama produk',
              child: TextFormField(
                controller: _title,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                decoration: const InputDecoration(hintText: 'Nama produk'),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            LabeledField(
              label: 'Deskripsi',
              child: TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Detail, bahan, ukuran…',
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            LabeledField(
              label: 'Harga dasar',
              child: TextFormField(
                controller: _basePrice,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 0) return 'Harga tidak valid';
                  return null;
                },
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(prefixText: 'Rp '),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            SwitchRow(
              title: 'Aktif (tampil di etalase)',
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: AppSpace.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Varian', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _variants.add(VariantInput())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            for (final v in _variants)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: _VariantRow(
                  key: ObjectKey(v),
                  variant: v,
                  onRemove: () => setState(() => _variants.remove(v)),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SaveBar(
        label: 'Simpan produk',
        saving: _saving,
        onSave: _save,
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.urls,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> urls;
  final bool uploading;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
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
                      height: 100,
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
            onTap: uploading ? null : onAdd,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.borderStrong),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: uploading
                  ? const Center(child: CircularProgressIndicator())
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: AppColors.textSecondary),
                        SizedBox(height: AppSpace.xs),
                        Text(
                          'Tambah',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
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

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    super.key,
    required this.variant,
    required this.onRemove,
  });

  final VariantInput variant;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: variant.name,
              onChanged: (v) => variant.name = v,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama?' : null,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              decoration: const InputDecoration(
                labelText: 'Varian',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: variant.price == 0 ? '' : variant.price.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => variant.price = int.tryParse(v) ?? 0,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              decoration: const InputDecoration(
                labelText: 'Harga',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: variant.stock == 0 ? '' : variant.stock.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => variant.stock = int.tryParse(v) ?? 0,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              decoration: const InputDecoration(
                labelText: 'Stok',
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              color: AppColors.danger,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
