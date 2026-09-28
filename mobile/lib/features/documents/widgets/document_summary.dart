import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/shared/widgets/app_card.dart';

/// Compact summary strip showing total, expiring-soon and expired counts.
class DocumentSummary extends StatelessWidget {
  final int total;
  final int expiringSoon;
  final int expired;

  const DocumentSummary({
    super.key,
    required this.total,
    required this.expiringSoon,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Total',
              value: total.toString(),
              valueColor: AppColors.darkBlue,
            ),
          ),
          _divider(),
          Expanded(
            child: _SummaryItem(
              label: 'Expiring Soon',
              value: expiringSoon.toString(),
              valueColor: AppColors.warningOrange,
            ),
          ),
          _divider(),
          Expanded(
            child: _SummaryItem(
              label: 'Expired',
              value: expired.toString(),
              valueColor: AppColors.negativeRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: AppColors.border,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
      );
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
            fontSize: 11,
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
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
