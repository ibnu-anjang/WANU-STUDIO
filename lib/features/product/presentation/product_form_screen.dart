import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
          padding: const EdgeInsets.all(16),
          children: [
            _ImagePicker(
              urls: _imageUrls,
              uploading: _uploading,
              onAdd: _pickImage,
              onRemove: (i) => setState(() => _imageUrls.removeAt(i)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              decoration: const InputDecoration(labelText: 'Nama produk'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _basePrice,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 0) return 'Harga tidak valid';
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Harga dasar',
                prefixText: 'Rp ',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif (tampil di etalase)'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Varian', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _variants.add(VariantInput())),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            for (final v in _variants)
              _VariantRow(
                key: ObjectKey(v),
                variant: v,
                onRemove: () => setState(() => _variants.remove(v)),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
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
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < urls.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      urls[i],
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: uploading ? null : onAdd,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: uploading
                  ? const Center(child: CircularProgressIndicator())
                  : const Icon(Icons.add_a_photo),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
              decoration: const InputDecoration(
                labelText: 'Varian',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: variant.price == 0 ? '' : variant.price.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => variant.price = int.tryParse(v) ?? 0,
              decoration: const InputDecoration(
                labelText: 'Harga',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: variant.stock == 0 ? '' : variant.stock.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => variant.stock = int.tryParse(v) ?? 0,
              decoration: const InputDecoration(
                labelText: 'Stok',
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
