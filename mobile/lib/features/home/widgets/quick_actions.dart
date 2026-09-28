import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/home/models/home_sample_data.dart';
import 'package:second_brain/shared/widgets/section_header.dart';

/// Configuration-driven Quick Actions section.
class QuickActions extends StatelessWidget {
  final List<QuickActionItem> actions;
  final ValueChanged<QuickActionItem> onActionTap;

  const QuickActions({
    super.key,
    required this.actions,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AppSpacing.space12),
        Row(
          children: actions.map((action) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _QuickActionButton(
                  action: action,
                  onTap: () => onActionTap(action),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final QuickActionItem action;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mediumBorderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space8,
          horizontal: AppSpacing.space4,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mediumBorderRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.veryLightBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                action.icon,
                size: 20,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.darkText,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
