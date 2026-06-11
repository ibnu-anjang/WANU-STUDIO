import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Frosted glass surface: blurred translucent fill + hairline border.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.radius = AppRadius.lg,
    this.blur = 18,
    this.fill = AppColors.glassFill,
    this.borderColor = AppColors.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color fill;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: fill,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: shape,
                border: Border.all(color: borderColor),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// App-wide backdrop: vertical gradient + a soft accent glow at the top.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowBlob(
              color: AppColors.accent.withValues(alpha: 0.18),
              size: 320,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _GlowBlob(
              color: const Color(0xFF6D5BFF).withValues(alpha: 0.12),
              size: 300,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
