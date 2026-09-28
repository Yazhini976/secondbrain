import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';

/// Reusable category/type chip adhering to Second Brain restraint rules.
class CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smallBorderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkBlue : AppColors.veryLightBlue,
          borderRadius: AppRadius.smallBorderRadius,
          border: Border.all(
            color: isSelected ? AppColors.darkBlue : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.white : AppColors.darkBlue,
              ),
              const SizedBox(width: AppSpacing.space4),
            ],
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.white : AppColors.darkText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
