import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/store_controller.dart';
import '../data/store.dart';

class SellerOnboardingScreen extends ConsumerWidget {
  const SellerOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(myStoreProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Toko')),
      body: store.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (s) => s == null ? const _OnboardingForm() : _StoreInfo(store: s),
      ),
    );
  }
}

class _StoreInfo extends StatelessWidget {
  const _StoreInfo({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.storefront),
          title: Text(store.name),
          subtitle: Text('@${store.slug}'),
          trailing: store.isVerified
              ? const Icon(Icons.verified, color: Colors.blue)
              : null,
        ),
        if (store.description != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(store.description!),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.inventory_2),
          title: const Text('Kelola produk'),
          onTap: () => context.push('/seller/products'),
        ),
      ],
    );
  }
}

class _OnboardingForm extends ConsumerStatefulWidget {
  const _OnboardingForm();

  @override
  ConsumerState<_OnboardingForm> createState() => _OnboardingFormState();
}

class _OnboardingFormState extends ConsumerState<_OnboardingForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _description = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(myStoreProvider.notifier).becomeSeller(
            name: _name.text.trim(),
            slug: _slug.text.trim(),
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal membuka toko: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Buka toko untuk mulai jualan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            decoration: const InputDecoration(labelText: 'Nama toko'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _slug,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Wajib diisi';
              if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v.trim())) {
                return 'Hanya huruf kecil, angka, dan tanda hubung';
              }
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Slug toko',
              prefixText: '@',
              helperText: 'Dipakai di URL, mis. @toko-keren',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Buka toko'),
          ),
        ],
      ),
    );
  }
}
