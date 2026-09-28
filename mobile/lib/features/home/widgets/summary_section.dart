import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/home/models/home_sample_data.dart';
import 'package:second_brain/shared/widgets/app_card.dart';

/// Summary section showing the 4 key overview metrics.
class SummarySection extends StatelessWidget {
  final List<SummaryCardData> summaries;

  const SummarySection({
    super.key,
    required this.summaries,
  });

  @override
  Widget build(BuildContext context) {
    if (summaries.length < 4) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SummaryCard(data: summaries[0])),
            const SizedBox(width: AppSpacing.space12),
            Expanded(child: _SummaryCard(data: summaries[1])),
          ],
        ),
        const SizedBox(height: AppSpacing.space12),
        Row(
          children: [
            Expanded(child: _SummaryCard(data: summaries[2])),
            const SizedBox(width: AppSpacing.space12),
            Expanded(child: _SummaryCard(data: summaries[3])),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final SummaryCardData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: data.iconBackgroundColor,
                  borderRadius: AppRadius.smallBorderRadius,
                ),
                child: Icon(
                  data.icon,
                  size: 18,
                  color: data.iconColor,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  data.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          Text(
            data.value,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
