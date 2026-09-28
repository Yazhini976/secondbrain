import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_shadows.dart';
import 'package:second_brain/core/theme/app_spacing.dart';

/// Reusable card component adhering to Second Brain restraint rules.
/// Subtly bordered, clean elevation, no large floating shadows.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final bool hasBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.space16),
    this.margin,
    this.onTap,
    this.backgroundColor = AppColors.surface,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.mediumBorderRadius,
        border: hasBorder ? Border.all(color: AppColors.border, width: 1) : null,
        boxShadow: AppShadows.card,
      ),
      child: child,
    );

    if (margin != null) {
      if (onTap != null) {
        return Padding(
          padding: margin!,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.mediumBorderRadius,
            child: cardContent,
          ),
        );
      }
      return Padding(
        padding: margin!,
        child: cardContent,
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mediumBorderRadius,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
