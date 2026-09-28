import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';

/// Clean model representing home header user profile info.
class HomeProfileData {
  final String greeting;
  final String userName;
  final String subtitle;

  const HomeProfileData({
    required this.greeting,
    required this.userName,
    required this.subtitle,
  });
}

/// Category of urgency for attention items.
enum AttentionUrgency {
  upcoming,
  overdue,
  normal,
}

/// Item in the Needs Attention section.
class AttentionItem {
  final String id;
  final String title;
  final String statusText;
  final AttentionUrgency urgency;
  final IconData icon;
  final String? documentId;

  const AttentionItem({
    required this.id,
    required this.title,
    required this.statusText,
    required this.urgency,
    required this.icon,
    this.documentId,
  });

  Color get statusColor {
    switch (urgency) {
      case AttentionUrgency.overdue:
        return AppColors.negativeRed;
      case AttentionUrgency.upcoming:
        return AppColors.warningOrange;
      case AttentionUrgency.normal:
        return AppColors.successGreen;
    }
  }

  Color get statusBackgroundColor {
    switch (urgency) {
      case AttentionUrgency.overdue:
        return AppColors.lightRed;
      case AttentionUrgency.upcoming:
        return AppColors.lightOrange;
      case AttentionUrgency.normal:
        return AppColors.lightGreen;
    }
  }
}

/// Item in the Quick Actions section.
class QuickActionItem {
  final String id;
  final String label;
  final IconData icon;

  const QuickActionItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// Item in Recent Activity list.
class RecentActivityItem {
  final String id;
  final String title;
  final String category;
  final String amountOrDate;
  final IconData icon;
  final bool isNegative;

  const RecentActivityItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amountOrDate,
    required this.icon,
    this.isNegative = false,
  });
}

/// Summary card data item.
class SummaryCardData {
  final String id;
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;

  const SummaryCardData({
    required this.id,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
  });
}

/// Configuration data for Home screen actions.
abstract final class HomeSampleData {
  static const List<QuickActionItem> quickActions = [
    QuickActionItem(
      id: 'add_expense',
      label: 'Add Expense',
      icon: Icons.add_circle_outline,
    ),
    QuickActionItem(
      id: 'financial_goals',
      label: 'Goals AI',
      icon: Icons.auto_awesome,
    ),
    QuickActionItem(
      id: 'add_doc',
      label: 'Add Document',
      icon: Icons.upload_file_outlined,
    ),
    QuickActionItem(
      id: 'add_investment',
      label: 'Add Investment',
      icon: Icons.trending_up,
    ),
  ];
}
