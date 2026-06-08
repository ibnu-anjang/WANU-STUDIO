import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/form_fields.dart';
import '../application/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  var _saving = false;
  var _initialized = false;

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(currentProfileProvider.notifier).save(
            displayName: _displayName.text.trim(),
            username: _username.text.trim().isEmpty
                ? null
                : _username.text.trim(),
            bio: _bio.text.trim(),
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
    final profile = ref.watch(currentProfileProvider);
    profile.whenData((p) {
      if (!_initialized) {
        _displayName.text = p.displayName ?? '';
        _username.text = p.username ?? '';
        _bio.text = p.bio ?? '';
        _initialized = true;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          LabeledField(
            label: 'Nama tampilan',
            child: TextField(
              controller: _displayName,
              decoration: const InputDecoration(hintText: 'Nama kamu'),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          LabeledField(
            label: 'Username',
            child: TextField(
              controller: _username,
              decoration: const InputDecoration(
                hintText: 'username',
                prefixText: '@',
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          LabeledField(
            label: 'Bio',
            child: TextField(
              controller: _bio,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ceritakan sedikit tentang kamu',
              ),
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
