import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat profil: $e')),
        data: (p) => ListView(
          children: [
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundImage:
                    p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                child: p.avatarUrl == null
                    ? const Icon(Icons.person, size: 44)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                p.displayName ?? p.username ?? 'Tanpa nama',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (p.username != null)
              Center(child: Text('@${p.username}')),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit profil'),
              onTap: () => context.push('/profile/edit'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Alamat pengiriman'),
              onTap: () => context.push('/profile/addresses'),
            ),
            ListTile(
              leading: Icon(p.isSeller ? Icons.storefront : Icons.store),
              title: Text(p.isSeller ? 'Toko saya' : 'Buka toko'),
              onTap: () => context.push('/profile/become-seller'),
            ),
          ],
        ),
      ),
    );
  }
}
