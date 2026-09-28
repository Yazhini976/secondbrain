import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/settings/data/user_profile_repository.dart';

/// Top header for the Home screen.
///
/// Displays a time-aware greeting and the user's name pulled from
/// [UserProfileRepository] (reactive — updates immediately when the user
/// changes their name in Settings).
class HomeHeader extends StatelessWidget {
  final VoidCallback? onSecurityTap;
  final VoidCallback? onRemindersTap;
  final VoidCallback? onProfileTap;

  const HomeHeader({
    super.key,
    this.onSecurityTap,
    this.onRemindersTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserProfileRepository.instance,
      builder: (context, _) {
        final profile = UserProfileRepository.instance;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${profile.greeting}, ${profile.name}',
                    style: AppTextStyles.screenTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.subtitle,
                    style: AppTextStyles.secondary,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onRemindersTap,
              borderRadius: AppRadius.smallBorderRadius,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.veryLightBlue,
                  borderRadius: AppRadius.smallBorderRadius,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 20,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            InkWell(
              onTap: onProfileTap,
              borderRadius: AppRadius.smallBorderRadius,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.veryLightBlue,
                  borderRadius: AppRadius.smallBorderRadius,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_outline,
                    size: 20,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            InkWell(
              onTap: onSecurityTap,
              borderRadius: AppRadius.smallBorderRadius,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.veryLightBlue,
                  borderRadius: AppRadius.smallBorderRadius,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
