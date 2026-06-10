import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';
import '../data/profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: profile.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Gagal memuat profil: $e')),
            data: (p) => ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.lg,
                120,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Profil',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    GlassContainer(
                      radius: AppRadius.pill,
                      padding: const EdgeInsets.all(AppSpace.md),
                      onTap: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                      child: const Icon(
                        Icons.logout,
                        size: 20,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                _ProfileHeader(profile: p),
                const SizedBox(height: AppSpace.xl),
                _MenuTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit profil',
                  onTap: () => context.push('/profile/edit'),
                ),
                if (!p.isAdmin) ...[
                  _MenuTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Pesanan saya',
                    onTap: () => context.push('/orders'),
                  ),
                  _MenuTile(
                    icon: Icons.location_on_outlined,
                    title: 'Alamat pengiriman',
                    onTap: () => context.push('/profile/addresses'),
                  ),
                ],
                if (p.isAdmin) ...[
                  _MenuTile(
                    icon: Icons.storefront_outlined,
                    title: 'Kelola produk',
                    accent: true,
                    onTap: () => context.push('/admin/products'),
                  ),
                  _MenuTile(
                    icon: Icons.video_settings_outlined,
                    title: 'Kelola feed',
                    accent: true,
                    onTap: () => context.push('/admin/feed'),
                  ),
                  _MenuTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Jadikan user admin',
                    accent: true,
                    onTap: () => context.push('/admin/promote'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.accentGradient,
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.surfaceHigh,
              backgroundImage: profile.avatarUrl != null
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              child: profile.avatarUrl == null
                  ? const Icon(Icons.person, size: 36, color: Colors.white54)
                  : null,
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName ?? profile.username ?? 'Tanpa nama',
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.username != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@${profile.username}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
                if (profile.bio != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    profile.bio!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : AppColors.glassFill,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: accent ? AppColors.accent : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
