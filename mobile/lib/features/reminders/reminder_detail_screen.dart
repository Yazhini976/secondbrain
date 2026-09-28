import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/document_detail_screen.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/investments/investment_detail_screen.dart';
import 'package:second_brain/features/reminders/add_reminder_screen.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/reminders/logic/reminder_status.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';
import 'package:second_brain/features/reminders/services/notification_service.dart';

/// Screen displaying complete details of a specific reminder,
/// with options to mark complete, edit, and delete.
class ReminderDetailScreen extends StatefulWidget {
  final String reminderId;
  final Reminder? reminder;

  const ReminderDetailScreen({
    super.key,
    required this.reminderId,
    this.reminder,
  });

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  Reminder? get _reminder =>
      ReminderRepository.instance.getById(widget.reminderId) ?? widget.reminder;

  String _getSourceTitle(Reminder reminder) {
    if (reminder.source == ReminderSource.documentExpiry) {
      final doc = DocumentRepository.instance.getDocumentById(reminder.linkedEntityId ?? '');
      return doc?.title ?? 'Document';
    } else if (reminder.source == ReminderSource.investmentDue) {
      final inv = InvestmentRepository.instance.getInvestmentById(reminder.linkedEntityId ?? '');
      return inv?.name ?? 'Investment';
    }
    return '';
  }

  void _navigateToSource(BuildContext context, Reminder reminder) {
    if (reminder.source == ReminderSource.documentExpiry && reminder.linkedEntityId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentDetailScreen(
            documentId: reminder.linkedEntityId!,
          ),
        ),
      );
    } else if (reminder.source == ReminderSource.investmentDue && reminder.linkedEntityId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InvestmentDetailScreen(
            investmentId: reminder.linkedEntityId!,
          ),
        ),
      );
    }
  }

  Future<void> _openEdit(Reminder reminder) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddReminderScreen(
          reminder: reminder,
          isEditMode: true,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmDelete(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: const Text(
          'Are you sure you want to delete this reminder?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.negativeRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Cancel the scheduled notification before removing the reminder.
      NotificationService.instance.cancelReminder(reminder.id);
      ReminderRepository.instance.delete(reminder.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _toggleComplete(Reminder reminder) {
    ReminderRepository.instance.toggleComplete(reminder.id);
    // Re-read updated reminder and reschedule or cancel its notification.
    final updated = ReminderRepository.instance.getById(reminder.id);
    if (updated != null) {
      NotificationService.instance.rescheduleReminder(updated);
    }
    setState(() {});
  }

  String _formatTime(DateTime dateTime) {
    final int hour = dateTime.hour;
    final int minute = dateTime.minute;
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final String minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReminderRepository.instance,
      builder: (context, _) {
        final reminder = _reminder;

        if (reminder == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Reminder Details'),
              backgroundColor: AppColors.surface,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Reminder not found',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Return to Reminders'),
                  ),
                ],
              ),
            ),
          );
        }

        final status = deriveReminderStatus(
          reminderDateTime: reminder.reminderDateTime,
          isCompleted: reminder.isCompleted,
        );

        final dateStr = DateFormat('dd MMM yyyy').format(reminder.reminderDateTime);
        final timeStr = _formatTime(reminder.reminderDateTime);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Reminder Details'),
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1.0),
              child: Divider(height: 1.0, color: AppColors.border),
            ),
            actions: [
              if (!reminder.source.isGenerated)
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.darkBlue,
                    size: 20,
                  ),
                  tooltip: 'Edit Reminder',
                  onPressed: () => _openEdit(reminder),
                ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.negativeRed,
                  size: 20,
                ),
                tooltip: 'Delete Reminder',
                onPressed: () => _confirmDelete(reminder),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Card (Title, Category, Status)
                  Container(
                    width: double.infinity,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                reminder.title,
                                style: AppTextStyles.screenTitle.copyWith(
                                  fontSize: 18,
                                  decoration: reminder.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: reminder.isCompleted
                                      ? AppColors.mutedText
                                      : AppColors.darkText,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space8),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space12),
                        Row(
                          children: [
                            Icon(
                              reminder.category.icon,
                              size: 16,
                              color: AppColors.darkBlue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              reminder.category.displayName,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkBlue,
                              ),
                            ),
                            if (reminder.source.isGenerated) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Auto-generated',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primaryBrightBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),

                  // 2. Source Card (for auto-generated reminders)
                  if (reminder.source.isGenerated) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.mediumBorderRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Source',
                            style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: AppSpacing.space12),
                          const Divider(height: 1, color: AppColors.borderSubtle),
                          const SizedBox(height: AppSpacing.space12),
                          Row(
                            children: [
                              Icon(
                                reminder.source == ReminderSource.documentExpiry
                                    ? Icons.description_outlined
                                    : Icons.trending_up,
                                size: 16,
                                color: AppColors.secondaryText,
                              ),
                              const SizedBox(width: AppSpacing.space8),
                              Expanded(
                                child: Text(
                                  _getSourceTitle(reminder),
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () => _navigateToSource(context, reminder),
                              icon: Icon(
                                reminder.source == ReminderSource.documentExpiry
                                    ? Icons.description_outlined
                                    : Icons.trending_up,
                                size: 18,
                                color: AppColors.primaryBrightBlue,
                              ),
                              label: Text(
                                reminder.source == ReminderSource.documentExpiry
                                    ? 'View Document'
                                    : 'View Investment',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.primaryBrightBlue,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primaryBrightBlue),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.mediumBorderRadius,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                  ],

                  // 3. Schedule Information Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.mediumBorderRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule & Priority',
                          style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: AppSpacing.space12),
                        const Divider(height: 1, color: AppColors.borderSubtle),
                        const SizedBox(height: AppSpacing.space12),

                        // Date
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: dateStr,
                        ),
                        const SizedBox(height: AppSpacing.space12),

                        // Time
                        _buildInfoRow(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: timeStr,
                        ),
                        const SizedBox(height: AppSpacing.space12),

                        // Priority
                        Row(
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                              size: 16,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: AppSpacing.space8),
                            Text(
                              'Priority',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: reminder.priority.backgroundColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                reminder.priority.displayName,
                                style: AppTextStyles.caption.copyWith(
                                  color: reminder.priority.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),

                  // 3. Description (if present)
                  if (reminder.description != null &&
                      reminder.description!.trim().isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.mediumBorderRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: AppSpacing.space8),
                          Text(
                            reminder.description!,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                  ],

                  // 4. Action Buttons
                  // Toggle Complete Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleComplete(reminder),
                      icon: Icon(
                        reminder.isCompleted
                            ? Icons.replay
                            : Icons.check_circle_outline,
                        color: reminder.isCompleted
                            ? AppColors.darkBlue
                            : AppColors.successGreen,
                        size: 20,
                      ),
                      label: Text(
                        reminder.isCompleted
                            ? 'Mark as Incomplete'
                            : 'Mark as Complete',
                        style: AppTextStyles.button.copyWith(
                          color: reminder.isCompleted
                              ? AppColors.darkBlue
                              : AppColors.successGreen,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: reminder.isCompleted
                              ? AppColors.darkBlue
                              : AppColors.successGreen,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mediumBorderRadius,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space12),

                  // Edit Button (only for manual reminders)
                  if (!reminder.source.isGenerated) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _openEdit(reminder),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.white,
                        ),
                        label: Text(
                          'Edit Reminder',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkBlue,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.mediumBorderRadius,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                  ],

                  // Delete Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton.icon(
                      onPressed: () => _confirmDelete(reminder),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.negativeRed,
                      ),
                      label: Text(
                        'Delete Reminder',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.negativeRed,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.negativeRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ReminderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: 4,
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: AppSpacing.space8),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }
}
