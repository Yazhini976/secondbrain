



import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/reminders/logic/reminder_status.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';

/// Compact Reminders section for the Home Dashboard.
/// Displays top prioritized active reminders (Overdue -> Due Today -> Upcoming).
class HomeRemindersSection extends StatelessWidget {
  final List<Reminder> reminders;
  final int totalActiveCount;
  final ValueChanged<Reminder> onReminderTap;
  final VoidCallback onViewAll;

  const HomeRemindersSection({
    super.key,
    required this.reminders,
    required this.totalActiveCount,
    required this.onReminderTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const Text(
                  'Reminders',
                  style: AppTextStyles.sectionTitle,
                ),
                if (totalActiveCount > 0) ...[
                  const SizedBox(width: AppSpacing.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      totalActiveCount.toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.darkBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            InkWell(
              onTap: onViewAll,
              borderRadius: AppRadius.smallBorderRadius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: 2,
                ),
                child: Text(
                  'View All',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryBrightBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space12),

        // List of Reminders or Empty State
        if (reminders.isEmpty)
          _buildEmptyState()
        else
          ...reminders.map(
            (reminder) => _HomeReminderItem(
              reminder: reminder,
              onTap: () => onReminderTap(reminder),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mediumBorderRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 20,
              color: AppColors.successGreen,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No upcoming reminders',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You’re all caught up.',
                  style: AppTextStyles.secondary.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeReminderItem extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onTap;

  const _HomeReminderItem({
    required this.reminder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = deriveReminderStatus(
      reminderDateTime: reminder.reminderDateTime,
      isCompleted: reminder.isCompleted,
    );
    final dateStr = formatReminderDateTime(reminder.reminderDateTime);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mediumBorderRadius,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mediumBorderRadius,
          border: Border.all(
            color: status == ReminderStatus.overdue
                ? AppColors.lightRed
                : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category Icon container
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: status == ReminderStatus.overdue
                    ? AppColors.lightRed
                    : (status == ReminderStatus.dueToday
                        ? AppColors.lightOrange
                        : AppColors.veryLightBlue),
                shape: BoxShape.circle,
              ),
              child: Icon(
                reminder.category.icon,
                size: 16,
                color: status == ReminderStatus.overdue
                    ? AppColors.negativeRed
                    : (status == ReminderStatus.dueToday
                        ? AppColors.warningOrange
                        : AppColors.darkBlue),
              ),
            ),
            const SizedBox(width: AppSpacing.space12),

            // Content details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reminder.title,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        reminder.category.displayName,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '•',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: status == ReminderStatus.overdue
                                ? AppColors.negativeRed
                                : (status == ReminderStatus.dueToday
                                    ? AppColors.warningOrange
                                    : AppColors.secondaryText),
                            fontWeight: status == ReminderStatus.overdue ||
                                    status == ReminderStatus.dueToday
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space8),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: status.backgroundColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.displayName,
                style: AppTextStyles.caption.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
