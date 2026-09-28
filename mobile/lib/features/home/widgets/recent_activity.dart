
import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/home/models/home_sample_data.dart';
import 'package:second_brain/shared/widgets/app_card.dart';
import 'package:second_brain/shared/widgets/section_header.dart';

/// Recent Activity section showing a compact list of recent actions.
class RecentActivity extends StatelessWidget {
  final List<RecentActivityItem> activities;
  final ValueChanged<RecentActivityItem>? onActivityTap;


  const RecentActivity({
    super.key,
    required this.activities,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Activity'),
        const SizedBox(height: AppSpacing.space12),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: activities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              final isLast = index == activities.length - 1;

              return Column(
                children: [
                  InkWell(
                    onTap: () => onActivityTap?.call(activity),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.space12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.veryLightBlue,
                              borderRadius: AppRadius.smallBorderRadius,
                            ),
                            child: Icon(
                              activity.icon,
                              size: 18,
                              color: AppColors.darkBlue,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.title,
                                  style: AppTextStyles.cardTitle.copyWith(
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  activity.category,
                                  style: AppTextStyles.secondary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space8),
                          Text(
                            activity.amountOrDate,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: activity.isNegative
                                  ? AppColors.darkText
                                  : AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 60,
                      color: AppColors.border,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
