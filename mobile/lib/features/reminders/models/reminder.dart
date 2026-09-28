import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';

/// Categories supported for reminders in Second Brain.
enum ReminderCategory {
  personal,
  document,
  investment,
  other,
}

extension ReminderCategoryExtension on ReminderCategory {
  String get displayName {
    switch (this) {
      case ReminderCategory.personal:
        return 'Personal';
      case ReminderCategory.document:
        return 'Document';
      case ReminderCategory.investment:
        return 'Investment';
      case ReminderCategory.other:
        return 'Other';
    }
  }

  static ReminderCategory fromString(String val) {
    final lower = val.toLowerCase().trim();
    switch (lower) {
      case 'document':
        return ReminderCategory.document;
      case 'investment':
        return ReminderCategory.investment;
      case 'other':
        return ReminderCategory.other;
      default:
        return ReminderCategory.personal;
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderCategory.personal:
        return Icons.person_outline;
      case ReminderCategory.document:
        return Icons.description_outlined;
      case ReminderCategory.investment:
        return Icons.trending_up;
      case ReminderCategory.other:
        return Icons.bookmark_border_outlined;
    }
  }
}

/// Priority levels for reminders (informational).
enum ReminderPriority {
  low,
  medium,
  high,
}

extension ReminderPriorityExtension on ReminderPriority {
  String get displayName {
    switch (this) {
      case ReminderPriority.low:
        return 'Low';
      case ReminderPriority.medium:
        return 'Medium';
      case ReminderPriority.high:
        return 'High';
    }
  }

  static ReminderPriority fromString(String val) {
    final lower = val.toLowerCase().trim();
    switch (lower) {
      case 'low':
        return ReminderPriority.low;
      case 'high':
        return ReminderPriority.high;
      default:
        return ReminderPriority.medium;
    }
  }

  Color get color {
    switch (this) {
      case ReminderPriority.low:
        return AppColors.secondaryText;
      case ReminderPriority.medium:
        return AppColors.warningOrange;
      case ReminderPriority.high:
        return AppColors.negativeRed;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ReminderPriority.low:
        return AppColors.borderSubtle;
      case ReminderPriority.medium:
        return AppColors.lightOrange;
      case ReminderPriority.high:
        return AppColors.lightRed;
    }
  }
}

/// Derived status of a reminder.
enum ReminderStatus {
  upcoming,
  dueToday,
  overdue,
  completed,
}

extension ReminderStatusExtension on ReminderStatus {
  String get displayName {
    switch (this) {
      case ReminderStatus.upcoming:
        return 'Upcoming';
      case ReminderStatus.dueToday:
        return 'Due Today';
      case ReminderStatus.overdue:
        return 'Overdue';
      case ReminderStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case ReminderStatus.upcoming:
        return AppColors.primaryBrightBlue;
      case ReminderStatus.dueToday:
        return AppColors.warningOrange;
      case ReminderStatus.overdue:
        return AppColors.negativeRed;
      case ReminderStatus.completed:
        return AppColors.successGreen;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ReminderStatus.upcoming:
        return AppColors.lightBlue;
      case ReminderStatus.dueToday:
        return AppColors.lightOrange;
      case ReminderStatus.overdue:
        return AppColors.lightRed;
      case ReminderStatus.completed:
        return AppColors.lightGreen;
    }
  }
}

/// Source of a reminder: created manually by the user or automatically derived.
enum ReminderSource {
  manual,
  documentExpiry,
  investmentDue,
}

extension ReminderSourceExtension on ReminderSource {
  String get displayName {
    switch (this) {
      case ReminderSource.manual:
        return 'Manual';
      case ReminderSource.documentExpiry:
      case ReminderSource.investmentDue:
        return 'Auto-generated';
    }
  }

  static ReminderSource fromString(String val) {
    switch (val) {
      case 'documentExpiry':
        return ReminderSource.documentExpiry;
      case 'investmentDue':
        return ReminderSource.investmentDue;
      default:
        return ReminderSource.manual;
    }
  }

  bool get isGenerated => this != ReminderSource.manual;
}

/// Immutable Reminder model.
class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final DateTime reminderDateTime;
  final ReminderCategory category;
  final ReminderPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? linkedEntityId;
  final String? linkedEntityType;
  final ReminderSource source;

  Reminder({
    String? id,
    required this.title,
    this.description,
    this.dueDate,
    required this.reminderDateTime,
    this.category = ReminderCategory.personal,
    this.priority = ReminderPriority.medium,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.linkedEntityId,
    this.linkedEntityType,
    this.source = ReminderSource.manual,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final dueAtStr = json['due_at'] as String?;
    final dt = dueAtStr != null ? DateTime.parse(dueAtStr) : DateTime.now();

    return Reminder(
      id: json['id'] as String?,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      dueDate: dt,
      reminderDateTime: dt,
      category: ReminderCategoryExtension.fromString((json['category'] ?? 'Personal') as String),
      priority: ReminderPriorityExtension.fromString((json['priority'] ?? 'Medium') as String),
      isCompleted: (json['is_completed'] as bool?) ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      linkedEntityId: json['linked_entity_id'] as String?,
      linkedEntityType: json['linked_entity_type'] as String?,
      source: ReminderSourceExtension.fromString((json['source'] ?? 'manual') as String),
    );
  }

  Map<String, dynamic> toJson() {
    final dt = reminderDateTime;
    return {
      'title': title,
      if (description != null) 'description': description,
      'due_at': dt.toIso8601String(),
      'category': category.displayName,
      'priority': priority.displayName,
      'is_completed': isCompleted,
      'source': source.name,
      if (linkedEntityType != null) 'linked_entity_type': linkedEntityType,
      if (linkedEntityId != null) 'linked_entity_id': linkedEntityId,
    };
  }

  Reminder copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? reminderDateTime,
    ReminderCategory? category,
    ReminderPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedEntityId,
    String? linkedEntityType,
    ReminderSource? source,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      linkedEntityId: linkedEntityId ?? this.linkedEntityId,
      linkedEntityType: linkedEntityType ?? this.linkedEntityType,
      source: source ?? this.source,
    );
  }
}
