import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/features/investments/models/investment.dart';
import 'package:second_brain/features/investments/logic/investment_status.dart';

/// A single investment item in the list.
class InvestmentListItem extends StatelessWidget {
  final Investment investment;
  final String Function(double) formatAmount;
  final VoidCallback? onTap;

  const InvestmentListItem({
    super.key,
    required this.investment,
    required this.formatAmount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = investment.serverStatus != null
        ? InvestmentStatusExtension.fromString(investment.serverStatus)
        : deriveStatus(
            installmentsPaid: investment.installmentsPaid,
            totalInstallments: investment.totalInstallments,
            nextDueDate: investment.nextDueDate,
          );
    final progress = investment.progressPercentage != null
        ? (investment.progressPercentage! / 100.0).clamp(0.0, 1.0)
        : (investment.totalInstallments > 0
            ? (investment.installmentsPaid / investment.totalInstallments)
                .clamp(0.0, 1.0)
            : 0.0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            investment.type.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: AppSpacing.space12),

                // Monthly contribution
                Row(
                  children: [
                    Expanded(
                      child: _MetaItem(
                        label: 'Monthly',
                        value: formatAmount(investment.monthlyContribution),
                      ),
                    ),
                    Expanded(
                      child: _MetaItem(
                        label: 'Total Paid',
                        value: formatAmount(investment.totalPaid),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space8),

                // Installment progress
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${investment.installmentsPaid} / ${investment.totalInstallments} installments',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: AppColors.borderSubtle,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _progressColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Next due date
                if (investment.nextDueDate != null) ...[
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    'Next due · ${DateFormat('d MMM yyyy').format(investment.nextDueDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: status == InvestmentStatus.overdue
                          ? AppColors.negativeRed
                          : status == InvestmentStatus.dueSoon
                              ? AppColors.warningOrange
                              : AppColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _progressColor(InvestmentStatus status) {
    switch (status) {
      case InvestmentStatus.completed:
        return AppColors.primaryBrightBlue;
      case InvestmentStatus.overdue:
        return AppColors.negativeRed;
      case InvestmentStatus.dueSoon:
        return AppColors.warningOrange;
      case InvestmentStatus.onTrack:
        return AppColors.successGreen;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final InvestmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color text;

    switch (status) {
      case InvestmentStatus.onTrack:
        bg = AppColors.lightGreen;
        text = AppColors.successGreen;
        break;
      case InvestmentStatus.dueSoon:
        bg = AppColors.lightOrange;
        text = AppColors.warningOrange;
        break;
      case InvestmentStatus.overdue:
        bg = AppColors.lightRed;
        text = AppColors.negativeRed;
        break;
      case InvestmentStatus.completed:
        bg = AppColors.lightBlue;
        text = AppColors.primaryBrightBlue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }
}
