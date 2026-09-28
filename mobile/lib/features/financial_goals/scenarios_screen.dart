import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/financial_goals/data/financial_repository.dart';
import 'package:second_brain/features/financial_goals/models/financial_analysis.dart';

class ScenariosScreen extends StatefulWidget {
  final List<FinancialScenarioData> scenarios;

  const ScenariosScreen({super.key, required this.scenarios});

  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
  String? _applyingId;

  Future<void> _confirmAndApply(FinancialScenarioData scenario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Scenario Application'),
        content: Text(
          'Applying "${scenario.name}" will update your financial goals target amounts and deadlines.\n\n'
          'Are you sure you want to apply this scenario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkBlue,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apply Scenario'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _applyingId = scenario.id);
      await FinancialRepository.instance.applyScenario(scenario.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully applied "${scenario.name}"'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Feasible Alternatives'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.space16),
          itemCount: widget.scenarios.length,
          separatorBuilder: (ctx, idx) => const SizedBox(height: AppSpacing.space16),
          itemBuilder: (context, idx) {
            final sc = widget.scenarios[idx];
            final isApplying = _applyingId == sc.id;

            return Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.mediumBorderRadius,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.veryLightBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Option ${idx + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space8),
                      Expanded(
                        child: Text(
                          sc.name,
                          style: AppTextStyles.sectionTitle,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sc.isFeasible ? AppColors.lightGreen : AppColors.lightRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sc.isFeasible ? 'Feasible' : 'Infeasible',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: sc.isFeasible ? AppColors.successGreen : AppColors.negativeRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    sc.description,
                    style: AppTextStyles.secondary.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.space12),

                  const Divider(),

                  const Text(
                    'Key Trade-offs:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                  ),
                  const SizedBox(height: 4),
                  ...sc.tradeoffs.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(child: Text(t, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.space16),

                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkBlue,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mediumBorderRadius,
                        ),
                      ),
                      onPressed: isApplying ? null : () => _confirmAndApply(sc),
                      child: isApplying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Apply Scenario'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
