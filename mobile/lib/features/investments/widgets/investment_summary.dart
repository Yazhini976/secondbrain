import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/shared/widgets/app_card.dart';

class InvestmentSummary extends StatelessWidget {
  final double totalInvested;
  final int activeCount;
  final String Function(double) formatAmount;

  const InvestmentSummary({
    super.key,
    required this.totalInvested,
    required this.activeCount,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Total Invested',
              value: formatAmount(totalInvested),
              valueColor: AppColors.darkBlue,
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Active',
              value: activeCount.toString(),
              valueColor: AppColors.primaryBrightBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
