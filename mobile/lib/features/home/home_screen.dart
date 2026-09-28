import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/auth/auth_service.dart';
import 'package:second_brain/features/financial_goals/data/financial_repository.dart';
import 'package:second_brain/features/auth/login_screen.dart';
import 'package:second_brain/features/auth/signup_screen.dart';
import 'package:second_brain/features/documents/add_document_screen.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/document_detail_screen.dart';
import 'package:second_brain/features/documents/logic/document_service.dart';
import 'package:second_brain/features/expenses/add_expense_screen.dart';
import 'package:second_brain/features/expenses/data/expense_repository.dart';
import 'package:second_brain/features/financial_goals/financial_goals_screen.dart';
import 'package:second_brain/features/home/logic/home_activity_service.dart';
import 'package:second_brain/features/home/models/home_sample_data.dart';
import 'package:second_brain/features/home/widgets/attention_section.dart';
import 'package:second_brain/features/home/widgets/home_header.dart';
import 'package:second_brain/features/home/widgets/home_reminders_section.dart';
import 'package:second_brain/features/home/widgets/quick_actions.dart';
import 'package:second_brain/features/home/widgets/recent_activity.dart';
import 'package:second_brain/features/home/widgets/summary_section.dart';
import 'package:second_brain/features/investments/add_investment_screen.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/investments/logic/investment_status.dart';
import 'package:second_brain/features/investments/investment_detail_screen.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/reminders/logic/reminder_service.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';
import 'package:second_brain/features/reminders/reminder_detail_screen.dart';
import 'package:second_brain/features/reminders/reminders_screen.dart';

/// Real Home / Dashboard Screen for Second Brain.
///
/// All four summary cards, the recent activity list, and the attention section
/// now pull from live repositories. Any add/edit/delete in Expenses,
/// Investments, Documents or Reminders automatically rebuilds this screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final _currencyFmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  void _showComingNextNotice(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.darkBlue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  Future<void> _openAddExpense(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    // ExpenseRepository is a ChangeNotifier — Home rebuilds automatically.
  }

  Future<void> _openAddInvestment(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
    );
    // InvestmentRepository is a ChangeNotifier — Home rebuilds automatically.
  }

  Future<void> _openAddDocument(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddDocumentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        DocumentRepository.instance,
        ReminderRepository.instance,
        ExpenseRepository.instance,
        InvestmentRepository.instance,
        AuthService.instance,
      ]),
      builder: (context, _) {
        final now = DateTime.now();
        final userIncome = AuthService.instance.currentUser?.monthlyIncome ?? 75000.0;

        // ── Live spending this month ──────────────────────────────────────────
        final thisMonthSpending =
            ExpenseRepository.instance.getTotalForMonth(now.year, now.month);

        // ── Live total invested ───────────────────────────────────────────────
        final totalInvested = InvestmentRepository.instance.getTotalInvested();

        // ── Attention items (100% dynamic from database) ──────────────────────
        final docAttentionItems = DocumentService.getDocumentAttentionItems();

        final invAttentionItems = <AttentionItem>[];
        for (final inv in InvestmentRepository.instance.getInvestments()) {
          final status = deriveStatus(
            installmentsPaid: inv.installmentsPaid,
            totalInstallments: inv.totalInstallments,
            nextDueDate: inv.nextDueDate,
          );
          if (status == InvestmentStatus.overdue) {
            invAttentionItems.add(
              AttentionItem(
                id: 'inv_${inv.id}',
                title: inv.name,
                statusText: 'Payment overdue',
                urgency: AttentionUrgency.overdue,
                icon: Icons.savings_outlined,
              ),
            );
          } else if (status == InvestmentStatus.dueSoon) {
            invAttentionItems.add(
              AttentionItem(
                id: 'inv_${inv.id}',
                title: inv.name,
                statusText: 'Payment due soon',
                urgency: AttentionUrgency.upcoming,
                icon: Icons.savings_outlined,
              ),
            );
          }
        }

        final allReminders = ReminderRepository.instance.getAll();
        final combinedAttentionItems = [
          ...docAttentionItems,
          ...invAttentionItems,
        ];
        final homeReminders =
            ReminderService.getHomeReminders(allReminders, limit: 3);
        final totalActiveReminders =
            ReminderService.activeCount(allReminders);

        // ── Summary cards (2×2) ───────────────────────────────────────────────
        final summaries = [
          SummaryCardData(
            id: 'spending',
            label: 'This month',
            value: _currencyFmt.format(thisMonthSpending),
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.primaryBrightBlue,
            iconBackgroundColor: AppColors.lightBlue,
          ),
          SummaryCardData(
            id: 'investments',
            label: 'Total invested',
            value: _currencyFmt.format(totalInvested),
            icon: Icons.trending_up,
            iconColor: AppColors.darkBlue,
            iconBackgroundColor: AppColors.veryLightBlue,
          ),
          SummaryCardData(
            id: 'expiring',
            label: 'Items needing attention',
            value: combinedAttentionItems.length.toString(),
            icon: Icons.access_time,
            iconColor: AppColors.warningOrange,
            iconBackgroundColor: AppColors.lightOrange,
          ),
          SummaryCardData(
            id: 'overdue',
            label: 'Needs attention',
            value: combinedAttentionItems
                .where((i) => i.urgency == AttentionUrgency.overdue)
                .length
                .toString(),
            icon: Icons.error_outline,
            iconColor: AppColors.negativeRed,
            iconBackgroundColor: AppColors.lightRed,
          ),
        ];

        // ── Recent activity (live) ────────────────────────────────────────────
        final recentActivities =
            HomeActivityService.getRecentActivity(limit: 5);

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER
              HomeHeader(
                onProfileTap: () => _openAccountProfile(context),
                onRemindersTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RemindersScreen(),
                    ),
                  );
                },
                onSecurityTap: () {
                  _showComingNextNotice(
                      context, 'Vault security settings coming next.');
                },
              ),
              const SizedBox(height: AppSpacing.space16),

              // 2. MONTHLY INCOME SEGMENT (NEAR THIS MONTH'S EXPENSE)
              _buildMonthlyIncomeSegment(context, userIncome),
              const SizedBox(height: AppSpacing.space12),

              // 3. SUMMARY AREA (This month expense, Total invested, etc.)
              SummarySection(summaries: summaries),
              const SizedBox(height: AppSpacing.space24),

              // 3. QUICK ACTIONS
              QuickActions(
                actions: HomeSampleData.quickActions,
                onActionTap: (action) {
                  switch (action.id) {
                    case 'add_expense':
                      _openAddExpense(context);
                    case 'financial_goals':
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FinancialGoalsScreen()),
                      );
                    case 'add_doc':
                      _openAddDocument(context);
                    case 'add_investment':
                      _openAddInvestment(context);
                    default:
                      _showComingNextNotice(
                          context, '${action.label} coming next.');
                  }
                },
              ),
              const SizedBox(height: AppSpacing.space24),

              // 4. ATTENTION AREA
              AttentionSection(
                items: combinedAttentionItems,
                onItemTap: (item) {
                  if (item.documentId != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DocumentDetailScreen(
                          documentId: item.documentId!,
                        ),
                      ),
                    );
                  } else if (item.id.startsWith('inv_')) {
                    final invId = item.id.replaceFirst('inv_', '');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InvestmentDetailScreen(
                          investmentId: invId,
                        ),
                      ),
                    );
                  } else if (item.id.startsWith('rem_')) {
                    final remId = item.id.replaceFirst('rem_', '');
                    final rem = ReminderRepository.instance.getById(remId);
                    if (rem != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReminderDetailScreen(
                            reminderId: rem.id,
                            reminder: rem,
                          ),
                        ),
                      );
                    }
                  } else {
                    _showComingNextNotice(
                        context, '${item.title} details coming next.');
                  }
                },
              ),
              const SizedBox(height: AppSpacing.space24),

              // 5. REMINDERS SECTION
              HomeRemindersSection(
                reminders: homeReminders,
                totalActiveCount: totalActiveReminders,
                onReminderTap: (reminder) {
                  if (reminder.source == ReminderSource.documentExpiry &&
                      reminder.linkedEntityId != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DocumentDetailScreen(
                          documentId: reminder.linkedEntityId!,
                        ),
                      ),
                    );
                  } else if (reminder.source == ReminderSource.investmentDue &&
                      reminder.linkedEntityId != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InvestmentDetailScreen(
                          investmentId: reminder.linkedEntityId!,
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReminderDetailScreen(
                          reminderId: reminder.id,
                          reminder: reminder,
                        ),
                      ),
                    );
                  }
                },
                onViewAll: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RemindersScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.space24),

              // 6. RECENT ACTIVITY (live)
              if (recentActivities.isNotEmpty)
                RecentActivity(
                  activities: recentActivities,
                  onActivityTap: (activity) {
                    _showComingNextNotice(
                        context, '${activity.title} details coming next.');
                  },
                ),
              const SizedBox(height: AppSpacing.space24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyIncomeSegment(BuildContext context, double userIncome) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mediumBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: AppRadius.smallBorderRadius,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: AppColors.successGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Income',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currencyFmt.format(userIncome),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _editMonthlyIncome(context, userIncome),
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
    );
  }

  Future<void> _editMonthlyIncome(BuildContext context, double currentIncome) async {
    final controller = TextEditingController(text: currentIncome.toStringAsFixed(0));
    final updated = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Monthly Income'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your regular monthly earnings. Used for accurate cash flow & savings capacity.',
              style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
            const SizedBox(height: AppSpacing.space16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Monthly Income',
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
              if (val != null && val > 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated != null) {
      await AuthService.instance.updateFinancialProfile(monthlyIncome: updated);
      await FinancialRepository.instance.loadAnalysis();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Monthly income updated to ${_currencyFmt.format(updated)}'),
            backgroundColor: AppColors.darkBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openAccountProfile(BuildContext context) async {
    final user = AuthService.instance.currentUser;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.darkBlue,
                      child: Text(
                        (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Second Brain User',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
                          ),
                          Text(
                            user?.email ?? user?.phone ?? 'Account Profile',
                            style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.login_rounded, color: AppColors.darkBlue),
                  title: const Text('Sign In to Account'),
                  subtitle: const Text('Login with phone or email'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final res = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    if (res == true) {
                      final now = DateTime.now();
                      ExpenseRepository.instance.loadExpensesForMonth(now.year, now.month);
                      InvestmentRepository.instance.loadInvestments();
                      DocumentRepository.instance.loadDocuments();
                      ReminderRepository.instance.loadReminders();
                      FinancialRepository.instance.loadAnalysis();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_outlined, color: AppColors.primaryBrightBlue),
                  title: const Text('Create New Account'),
                  subtitle: const Text('Sign up with name, email, phone & password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final res = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                    if (res == true) {
                      final now = DateTime.now();
                      ExpenseRepository.instance.loadExpensesForMonth(now.year, now.month);
                      InvestmentRepository.instance.loadInvestments();
                      DocumentRepository.instance.loadDocuments();
                      ReminderRepository.instance.loadReminders();
                      FinancialRepository.instance.loadAnalysis();
                    }
                  },
                ),
                if (AuthService.instance.isAuthenticated)
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.negativeRed),
                    title: const Text('Log Out', style: TextStyle(color: AppColors.negativeRed)),
                    onTap: () {
                      AuthService.instance.logout();
                      Navigator.of(ctx).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
