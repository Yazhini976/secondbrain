import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/reminders/add_reminder_screen.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/reminders/logic/reminder_service.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';
import 'package:second_brain/features/reminders/reminder_detail_screen.dart';
import 'package:second_brain/features/reminders/widgets/reminder_section.dart';

/// Reminders Screen for Second Brain.
///
/// Displays local reminders categorized into Overdue, Due Today, Upcoming,
/// and Completed sections. Supports opening details, marking complete, and adding reminders.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ReminderRepository.instance.loadReminders();
      }
    });
  }

  Future<void> _openAddReminder(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddReminderScreen(),
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _openReminderDetail(BuildContext context, Reminder reminder) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReminderDetailScreen(
          reminderId: reminder.id,
          reminder: reminder,
        ),
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: AppColors.darkBlue,
              size: 22,
            ),
            tooltip: 'Add Reminder',
            onPressed: () => _openAddReminder(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: ReminderRepository.instance,
          builder: (context, _) {
            final allReminders = ReminderRepository.instance.getAll();
            final overdueItems = ReminderService.getOverdueReminders(allReminders);
            final dueTodayItems = ReminderService.getDueTodayReminders(allReminders);
            final upcomingItems = ReminderService.getUpcomingReminders(allReminders);
            final completedItems = ReminderService.getCompletedReminders(allReminders);

            final bool hasAnyReminders = allReminders.isNotEmpty;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Screen Subtitle & Header Info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space16,
                      AppSpacing.space16,
                      AppSpacing.space16,
                      AppSpacing.space8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important things to remember',
                          style: AppTextStyles.secondary.copyWith(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Empty State or Grouped Sections
                if (!hasAnyReminders)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space16,
                      AppSpacing.space4,
                      AppSpacing.space16,
                      AppSpacing.space24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 1. Overdue Section
                        if (overdueItems.isNotEmpty)
                          ReminderSection(
                            title: 'Overdue',
                            count: overdueItems.length,
                            countBadgeColor: AppColors.negativeRed,
                            countBadgeBgColor: AppColors.lightRed,
                            items: overdueItems,
                            onItemTap: (reminder) => _openReminderDetail(context, reminder),
                          ),

                        // 2. Due Today Section
                        if (dueTodayItems.isNotEmpty)
                          ReminderSection(
                            title: 'Due Today',
                            count: dueTodayItems.length,
                            countBadgeColor: AppColors.warningOrange,
                            countBadgeBgColor: AppColors.lightOrange,
                            items: dueTodayItems,
                            onItemTap: (reminder) => _openReminderDetail(context, reminder),
                          ),

                        // 3. Upcoming Section
                        if (upcomingItems.isNotEmpty)
                          ReminderSection(
                            title: 'Upcoming',
                            count: upcomingItems.length,
                            countBadgeColor: AppColors.primaryBrightBlue,
                            countBadgeBgColor: AppColors.lightBlue,
                            items: upcomingItems,
                            onItemTap: (reminder) => _openReminderDetail(context, reminder),
                          ),

                        // 4. Completed Section
                        if (completedItems.isNotEmpty)
                          ReminderSection(
                            title: 'Completed',
                            count: completedItems.length,
                            countBadgeColor: AppColors.successGreen,
                            countBadgeBgColor: AppColors.lightGreen,
                            items: completedItems,
                            onItemTap: (reminder) => _openReminderDetail(context, reminder),
                          ),

                        const SizedBox(height: AppSpacing.space12),

                        // Add Reminder Primary Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkBlue,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mediumBorderRadius,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => _openAddReminder(context),
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text(
                              'Add Reminder',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space24),
                      ]),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.veryLightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                size: 28,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            const Text(
              'No reminders yet',
              style: AppTextStyles.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'Add reminders for important dates and tasks.',
              style: AppTextStyles.secondary.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkBlue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space20,
                  vertical: AppSpacing.space12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mediumBorderRadius,
                ),
                elevation: 0,
              ),
              onPressed: () => _openAddReminder(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add Reminder',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
