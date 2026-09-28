import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/reminders/logic/reminder_status.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';
import 'package:second_brain/features/reminders/services/notification_service.dart';

/// Compact list row for displaying a single Reminder item.
///
/// Shows Title, Category, Priority, Formatted Date/Time, Status badge,
/// and an accessible completion checkbox control.
class ReminderListItem extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onTap;

  const ReminderListItem({
    super.key,
    required this.reminder,
    this.onTap,
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
            color: reminder.isCompleted ? AppColors.borderSubtle : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Completion Toggle Checkbox
            _buildCompletionToggle(context),
            const SizedBox(width: AppSpacing.space12),

            // Reminder Main Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    reminder.title,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: reminder.isCompleted
                          ? AppColors.mutedText
                          : AppColors.darkText,
                      decoration: reminder.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.mutedText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Metadata Row: Category & Priority
                  Row(
                    children: [
                      // Category Tag
                      Icon(
                        reminder.category.icon,
                        size: 13,
                        color: reminder.isCompleted
                            ? AppColors.mutedText
                            : AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reminder.category.displayName,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: reminder.isCompleted
                              ? AppColors.mutedText
                              : AppColors.secondaryText,
                        ),
                      ),
                      if (reminder.source.isGenerated) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Auto-generated',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryBrightBlue,
                            ),
                          ),
                        ),
                      ],
                      if (reminder.priority == ReminderPriority.high &&
                          !reminder.isCompleted) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'High',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.negativeRed,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Date / Time
                  Text(
                    dateStr,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: reminder.isCompleted
                          ? AppColors.mutedText
                          : (status == ReminderStatus.overdue
                              ? AppColors.negativeRed
                              : (status == ReminderStatus.dueToday
                                  ? AppColors.warningOrange
                                  : AppColors.secondaryText)),
                      fontWeight: status == ReminderStatus.overdue ||
                              status == ReminderStatus.dueToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space8),

            // Status Badge
            _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionToggle(BuildContext context) {
    return Semantics(
      label: reminder.isCompleted
          ? 'Mark reminder as incomplete'
          : 'Mark reminder as complete',
      button: true,
      child: InkWell(
        onTap: () {
          ReminderRepository.instance.toggleComplete(reminder.id);
          // Sync notification state: cancel if now completed, reschedule if
          // un-completed and the time is still in the future.
          final updated =
              ReminderRepository.instance.getById(reminder.id);
          if (updated != null) {
            NotificationService.instance.rescheduleReminder(updated);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reminder.isCompleted
                ? AppColors.successGreen
                : Colors.transparent,
            border: Border.all(
              color: reminder.isCompleted
                  ? AppColors.successGreen
                  : AppColors.secondaryText.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: reminder.isCompleted
              ? const Icon(
                  Icons.check,
                  size: 16,
                  color: AppColors.white,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReminderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.displayName,
        style: AppTextStyles.caption.copyWith(
          color: status.color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
