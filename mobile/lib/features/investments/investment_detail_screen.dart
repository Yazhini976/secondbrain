import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/features/investments/add_investment_screen.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/investments/logic/investment_status.dart';
import 'package:second_brain/features/investments/models/investment.dart';
import 'package:second_brain/shared/widgets/app_card.dart';

/// Screen displaying complete details for a specific investment.
class InvestmentDetailScreen extends StatefulWidget {
  final String investmentId;

  const InvestmentDetailScreen({
    super.key,
    required this.investmentId,
  });

  @override
  State<InvestmentDetailScreen> createState() => _InvestmentDetailScreenState();
}

class _InvestmentDetailScreenState extends State<InvestmentDetailScreen> {
  bool _hasChanges = false;
  bool _isDeleting = false;

  Investment? get _investment =>
      InvestmentRepository.instance.getInvestmentById(widget.investmentId);

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _openEdit(Investment investment) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddInvestmentScreen(existing: investment),
      ),
    );
    if (result == true) {
      _hasChanges = true;
      setState(() {});
    }
  }

  Future<void> _confirmDelete(Investment investment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Investment?'),
        content: const Text(
          'This investment will be removed from your investment list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.negativeRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && !_isDeleting) {
      setState(() => _isDeleting = true);
      try {
        await InvestmentRepository.instance.deleteInvestment(investment.id);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (err) {
        if (mounted) {
          setState(() => _isDeleting = false);
          final msg = err.toString().replaceAll('ApiException: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $msg'),
              backgroundColor: AppColors.negativeRed,
            ),
          );
        }
      }
    }
  }

  void _onAddReceipt() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt attachments will be available in a later step.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final investment = _investment;

    if (investment == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Investment Details'),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Investment not found.'),
        ),
      );
    }

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

    final remainingInstallments =
        (investment.totalInstallments - investment.installmentsPaid)
            .clamp(0, investment.totalInstallments);

    final dateFormat = DateFormat('d MMM yyyy');

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasChanges) {
          // Parent screen will receive pop update if handled via route result
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Investment Details'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => _openEdit(investment),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.negativeRed),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(investment),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Divider(height: 1.0, color: AppColors.border),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isDeleting)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.space16),
                  child: LinearProgressIndicator(minHeight: 2),
                ),

              // 1. Header: Name, Type, and Status badge
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          investment.type.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: AppSpacing.space24),

              // 2. Financial Summary
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Contribution',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatCurrency(investment.monthlyContribution)} / month',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space16),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Paid',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(investment.totalPaid),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space20),

              // 3. Installment Progress
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Installment Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          '${investment.installmentsPaid} / ${investment.totalInstallments} installments',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.borderSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _progressColor(status),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}% paid',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                        if (status != InvestmentStatus.completed)
                          Text(
                            '$remainingInstallments installments remaining',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          )
                        else
                          const Text(
                            'Fully completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryBrightBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space20),

              // 4. Schedule Section
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    if (investment.startDate != null) ...[
                      _buildScheduleRow(
                        label: 'Start Date',
                        value: dateFormat.format(investment.startDate!),
                      ),
                      const Divider(height: 16, color: AppColors.borderSubtle),
                    ],
                    _buildScheduleRow(
                      label: 'Next Due',
                      value: investment.nextDueDate != null
                          ? dateFormat.format(investment.nextDueDate!)
                          : 'None scheduled',
                      valueColor: status == InvestmentStatus.overdue
                          ? AppColors.negativeRed
                          : status == InvestmentStatus.dueSoon
                              ? AppColors.warningOrange
                              : AppColors.darkText,
                    ),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildScheduleRow(
                      label: 'Maturity',
                      value: investment.maturityDate != null
                          ? dateFormat.format(investment.maturityDate!)
                          : 'Not applicable',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space20),

              // 5. Notes (shown only if notes exist)
              if (investment.notes != null &&
                  investment.notes!.trim().isNotEmpty) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        investment.notes!.trim(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space20),
              ],

              // 6. Receipts Section
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Receipts',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _onAddReceipt,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Receipt'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.darkBlue,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space16,
                        horizontal: AppSpacing.space12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 28,
                            color: AppColors.mutedText,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'No receipts added yet',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkText,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Receipts and payment proofs will appear here',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleRow({
    required String label,
    required String value,
    Color valueColor = AppColors.darkText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(InvestmentStatus status) {
    Color bg;
    Color text;

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: text,
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
