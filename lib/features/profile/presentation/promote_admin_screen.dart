import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/form_fields.dart';
import '../data/profile_repository.dart';

class PromoteAdminScreen extends ConsumerStatefulWidget {
  const PromoteAdminScreen({super.key});

  @override
  ConsumerState<PromoteAdminScreen> createState() => _PromoteAdminScreenState();
}

class _PromoteAdminScreenState extends ConsumerState<PromoteAdminScreen> {
  final _identifier = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _promote() async {
    final id = _identifier.text.trim();
    if (id.isEmpty) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final name = await ref.read(profileRepositoryProvider).promoteToAdmin(id);
      if (!mounted) return;
      _identifier.clear();
      messenger.showSnackBar(
        SnackBar(content: Text('$name sekarang admin')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('tidak ditemukan')
          ? 'User tidak ditemukan. Cek username/email.'
          : 'Gagal mempromosikan. Coba lagi.';
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadikan user admin')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          const Text(
            'Masukkan username atau email user yang sudah terdaftar. '
            'Mereka akan langsung jadi admin.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpace.xl),
          LabeledField(
            label: 'Username atau email',
            child: TextField(
              controller: _identifier,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _promote(),
              decoration: const InputDecoration(
                hintText: 'username atau email@contoh.com',
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SaveBar(
        label: 'Jadikan admin',
        saving: _saving,
        onSave: _promote,
      ),
    );
  }
}
