import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';

/// Reusable secondary button adhering to Second Brain design rules.
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.lightBlue,
          foregroundColor: AppColors.darkBlue,
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mediumBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space20,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.darkBlue),
              const SizedBox(width: AppSpacing.space8),
            ],
            Text(
              text,
              style: AppTextStyles.button.copyWith(color: AppColors.darkBlue),
            ),
          ],
        ),
      ),
    );
  }
}
