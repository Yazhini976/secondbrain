import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';
import 'package:second_brain/features/reminders/widgets/reminder_list_item.dart';

/// Compact list section for grouped reminders (Overdue, Due Today, Upcoming, Completed).
class ReminderSection extends StatelessWidget {
  final String title;
  final int count;
  final Color countBadgeColor;
  final Color countBadgeBgColor;
  final List<Reminder> items;
  final ValueChanged<Reminder>? onItemTap;

  const ReminderSection({
    super.key,
    required this.title,
    required this.count,
    required this.countBadgeColor,
    required this.countBadgeBgColor,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space8,
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: countBadgeBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: AppTextStyles.caption.copyWith(
                      color: countBadgeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Items List
          ...items.map(
            (reminder) => ReminderListItem(
              reminder: reminder,
              onTap: onItemTap != null ? () => onItemTap!(reminder) : null,
            ),
          ),
        ],
      ),
    );
  }
}
