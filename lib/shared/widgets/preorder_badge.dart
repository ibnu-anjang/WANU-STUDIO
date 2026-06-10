import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PreorderBadge extends StatelessWidget {
  const PreorderBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC1F2937),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accentSoft.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 13, color: AppColors.accentSoft),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.accentSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
