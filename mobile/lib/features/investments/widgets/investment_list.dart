import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/features/investments/models/investment.dart';
import 'package:second_brain/features/investments/widgets/investment_list_item.dart';

/// Renders the list of investments or an empty state if none are found.
class InvestmentList extends StatelessWidget {
  final List<Investment> investments;
  final String Function(double) formatAmount;
  final VoidCallback onAddInvestment;
  final void Function(Investment)? onInvestmentTap;

  const InvestmentList({
    super.key,
    required this.investments,
    required this.formatAmount,
    required this.onAddInvestment,
    this.onInvestmentTap,
  });

  @override
  Widget build(BuildContext context) {
    if (investments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space32,
          horizontal: AppSpacing.space24,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No investments yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space8),
            const Text(
              'Add your first investment to start tracking your contributions.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space16),
            OutlinedButton(
              onPressed: onAddInvestment,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.darkBlue,
                side: const BorderSide(color: AppColors.darkBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space20,
                  vertical: AppSpacing.space12,
                ),
              ),
              child: const Text(
                'Add Investment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: investments
          .map(
            (investment) => InvestmentListItem(
              key: ValueKey(investment.id),
              investment: investment,
              formatAmount: formatAmount,
              onTap: onInvestmentTap != null
                  ? () => onInvestmentTap!(investment)
                  : null,
            ),
          )
          .toList(),
    );
  }
}
