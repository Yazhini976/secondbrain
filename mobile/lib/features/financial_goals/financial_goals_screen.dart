import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/financial_goals/add_goal_screen.dart';
import 'package:second_brain/features/financial_goals/ai_financial_chat_screen.dart';
import 'package:second_brain/features/financial_goals/data/financial_repository.dart';
import 'package:second_brain/features/financial_goals/models/financial_goal.dart';
import 'package:second_brain/core/auth/auth_service.dart';
import 'package:second_brain/features/financial_goals/scenarios_screen.dart';

/// Financial Goals & Intelligence Master Screen.
class FinancialGoalsScreen extends StatefulWidget {
  const FinancialGoalsScreen({super.key});

  @override
  State<FinancialGoalsScreen> createState() => _FinancialGoalsScreenState();
}

class _FinancialGoalsScreenState extends State<FinancialGoalsScreen> {
  @override
  void initState() {
    super.initState();
    FinancialRepository.instance.addListener(_onRepoChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FinancialRepository.instance.loadAnalysis();
      }
    });
  }

  @override
  void dispose() {
    FinancialRepository.instance.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openAddGoal([FinancialGoal? existingGoal]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddGoalScreen(existingGoal: existingGoal)),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _openScenarios() async {
    final analysis = FinancialRepository.instance.analysis;
    if (analysis == null || analysis.scenarios.isEmpty) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ScenariosScreen(scenarios: analysis.scenarios)),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _openAIChat() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AIFinancialChatScreen()),
    );
  }

  Future<void> _editCapacity(double currentCapacity) async {
    final controller = TextEditingController(text: currentCapacity.toStringAsFixed(0));
    final updated = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Financial Capacity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your available monthly budget for investments and financial goals.',
              style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
            const SizedBox(height: AppSpacing.space16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Monthly Capacity',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkBlue,
              foregroundColor: AppColors.white,
            ),
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', ''));
              if (val != null && val >= 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated != null) {
      await AuthService.instance.updateFinancialProfile(monthlyCapacity: updated);
      await FinancialRepository.instance.loadAnalysis();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financial Goals & Intelligence'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, color: AppColors.darkBlue),
            tooltip: 'AI Financial Assistant',
            onPressed: _openAIChat,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.darkBlue),
            tooltip: 'Add Goal',
            onPressed: () => _openAddGoal(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: FinancialRepository.instance,
          builder: (context, _) {
            final repo = FinancialRepository.instance;
            final goals = repo.getGoals();
            final analysis = repo.analysis;
            final conflict = analysis?.conflict;
            final cashFlow = analysis?.cashFlow;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Financial Capacity & Cash Flow Summary Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.mediumBorderRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Monthly Financial Capacity',
                                style: AppTextStyles.secondary.copyWith(fontSize: 13),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.veryLightBlue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${goals.length} Goals',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                cashFlow != null
                                    ? '₹${cashFlow.availableCapacity.toStringAsFixed(0)} / mo'
                                    : '₹25,000 / mo',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkBlue,
                                ),
                              ),
                              InkWell(
                                onTap: () => _editCapacity(cashFlow?.availableCapacity ?? 25000.0),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.veryLightBlue,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primaryBrightBlue.withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryBrightBlue),
                                      SizedBox(width: 4),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryBrightBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space12),
                          const Divider(),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Required', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                                    Text(
                                      conflict != null
                                          ? '₹${conflict.totalRequiredContribution.toStringAsFixed(0)}'
                                          : '₹0',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Remaining Cap', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                                    Text(
                                      cashFlow != null
                                          ? '₹${cashFlow.remainingGoalCapacity.toStringAsFixed(0)}'
                                          : '₹0',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: (cashFlow?.remainingGoalCapacity ?? 0) >= 0
                                            ? AppColors.successGreen
                                            : AppColors.negativeRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Conflict Warning Banner (If Conflict Exists)
                if (conflict != null && conflict.hasConflict)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.space16),
                        decoration: BoxDecoration(
                          color: AppColors.lightRed,
                          borderRadius: AppRadius.mediumBorderRadius,
                          border: Border.all(color: AppColors.negativeRed.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppColors.negativeRed, size: 22),
                                const SizedBox(width: AppSpacing.space8),
                                const Text(
                                  'FINANCIAL CONFLICT DETECTED',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.negativeRed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.space8),
                            Text(
                              'Monthly Shortfall: ₹${conflict.monthlyShortfall.toStringAsFixed(0)}/month',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              conflict.conflictReason,
                              style: AppTextStyles.secondary.copyWith(fontSize: 12),
                            ),
                            const SizedBox(height: AppSpacing.space12),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.darkBlue,
                                        foregroundColor: AppColors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: AppRadius.mediumBorderRadius,
                                        ),
                                      ),
                                      onPressed: _openScenarios,
                                      icon: const Icon(Icons.auto_awesome, size: 16),
                                      label: const Text('Alternatives', style: TextStyle(fontSize: 13)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.space8),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.darkBlue,
                                        side: const BorderSide(color: AppColors.darkBlue),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: AppRadius.mediumBorderRadius,
                                        ),
                                      ),
                                      onPressed: _openAIChat,
                                      icon: const Icon(Icons.smart_toy_outlined, size: 16),
                                      label: const Text('Ask AI', style: TextStyle(fontSize: 13)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (conflict != null && !conflict.hasConflict && goals.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.space16),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: AppRadius.mediumBorderRadius,
                          border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 22),
                            const SizedBox(width: AppSpacing.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ALL GOALS ARE IN BALANCE',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.successGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your monthly capacity fully covers all active goals with no shortfall.',
                                    style: AppTextStyles.secondary.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 3. Goal List Section Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space16,
                      AppSpacing.space20,
                      AppSpacing.space16,
                      AppSpacing.space8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Active Financial Goals', style: AppTextStyles.sectionTitle),
                        TextButton.icon(
                          onPressed: _openAIChat,
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('AI Analysis'),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Goals Cards List
                if (goals.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flag_outlined, size: 48, color: AppColors.secondaryText),
                          const SizedBox(height: AppSpacing.space12),
                          const Text('No financial goals created yet', style: AppTextStyles.sectionTitle),
                          const SizedBox(height: AppSpacing.space16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkBlue,
                              foregroundColor: AppColors.white,
                            ),
                            onPressed: () => _openAddGoal(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Goal'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) {
                          final goal = goals[idx];
                          final percent = goal.targetAmount > 0
                              ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
                              : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.space12),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.space16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.mediumBorderRadius,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(goal.category.icon, color: AppColors.darkBlue, size: 20),
                                      const SizedBox(width: AppSpacing.space8),
                                      Expanded(
                                        child: Text(
                                          goal.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: goal.isFeasible ? AppColors.lightGreen : AppColors.lightRed,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          goal.isFeasible ? 'Feasible' : 'Infeasible',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: goal.isFeasible
                                                ? AppColors.successGreen
                                                : AppColors.negativeRed,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _openAddGoal(goal);
                                          } else if (val == 'delete') {
                                            repo.deleteGoal(goal.id);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.space12),

                                  // Progress bar
                                  LinearProgressIndicator(
                                    value: percent,
                                    backgroundColor: AppColors.borderSubtle,
                                    color: goal.isFeasible ? AppColors.darkBlue : AppColors.warningOrange,
                                    minHeight: 6,
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Saved: ₹${goal.currentAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}',
                                        style: AppTextStyles.secondary.copyWith(fontSize: 12),
                                      ),
                                      Text(
                                        '${(percent * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.space8),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Monthly: ₹${goal.monthlyContribution.toStringAsFixed(0)}/mo',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Req: ₹${goal.requiredMonthlyContribution.toStringAsFixed(0)}/mo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: goal.monthlyContribution >= goal.requiredMonthlyContribution
                                              ? AppColors.successGreen
                                              : AppColors.negativeRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: goals.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space32)),
              ],
            );
          },
        ),
      ),
    );
  }
}
