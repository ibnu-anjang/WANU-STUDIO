import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/profile/application/profile_controller.dart';
import 'glass.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int i) => navigationShell.goBranch(
        i,
        initialLocation: i == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(currentProfileProvider).value?.isAdmin ?? false;
    final items = [
      (
        icon: Icons.play_circle_outline,
        active: Icons.play_circle,
        label: 'Feed',
      ),
      isAdmin
          ? (
              icon: Icons.receipt_long_outlined,
              active: Icons.receipt_long,
              label: 'Pesanan',
            )
          : (
              icon: Icons.explore_outlined,
              active: Icons.explore,
              label: 'Jelajah',
            ),
      (icon: Icons.person_outline, active: Icons.person, label: 'Profil'),
    ];
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          0,
          AppSpace.lg,
          AppSpace.md,
        ),
        child: GlassContainer(
          radius: AppRadius.pill,
          blur: 24,
          fill: AppColors.glassFillHigh,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavItem(
                  item: items[i],
                  selected: navigationShell.currentIndex == i,
                  onTap: () => _go(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, IconData active, String label}) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? AppSpace.lg : AppSpace.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.accentGradient : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          children: [
            Icon(
              selected ? item.active : item.icon,
              size: 22,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: AppSpace.sm),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
