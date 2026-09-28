import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/home/models/home_sample_data.dart';
import 'package:second_brain/shared/widgets/app_card.dart';
import 'package:second_brain/shared/widgets/section_header.dart';

/// Needs Attention section highlighting urgent due dates and expiries.
class AttentionSection extends StatelessWidget {
  final List<AttentionItem> items;
  final ValueChanged<AttentionItem>? onItemTap;

  const AttentionSection({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Needs Attention'),
        const SizedBox(height: AppSpacing.space12),
        if (items.isEmpty)
          const AppCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space12),
              child: Center(
                child: Text(
                  'No items needing attention',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  InkWell(
                    onTap: () => onItemTap?.call(item),
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
                              item.icon,
                              size: 18,
                              color: AppColors.darkBlue,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space8,
                              vertical: AppSpacing.space4,
                            ),
                            decoration: BoxDecoration(
                              color: item.statusBackgroundColor,
                              borderRadius: AppRadius.smallBorderRadius,
                            ),
                            child: Text(
                              item.statusText,
                              style: AppTextStyles.caption.copyWith(
                                color: item.statusColor,
                                fontWeight: FontWeight.w600,
                              ),
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
