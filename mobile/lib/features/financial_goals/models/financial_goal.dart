import 'package:flutter/material.dart';

/// Categories supported for financial goals.
enum FinancialGoalCategory {
  emergencyFund,
  education,
  home,
  vehicle,
  retirement,
  investment,
  travel,
  other,
}

extension FinancialGoalCategoryExtension on FinancialGoalCategory {
  String get displayName {
    switch (this) {
      case FinancialGoalCategory.emergencyFund:
        return 'Emergency Fund';
      case FinancialGoalCategory.education:
        return 'Education';
      case FinancialGoalCategory.home:
        return 'Home';
      case FinancialGoalCategory.vehicle:
        return 'Vehicle';
      case FinancialGoalCategory.retirement:
        return 'Retirement';
      case FinancialGoalCategory.investment:
        return 'Investment';
      case FinancialGoalCategory.travel:
        return 'Travel';
      case FinancialGoalCategory.other:
        return 'Other';
    }
  }

  static FinancialGoalCategory fromString(String val) {
    final lower = val.toLowerCase().replaceAll(' ', '').trim();
    switch (lower) {
      case 'emergencyfund':
        return FinancialGoalCategory.emergencyFund;
      case 'education':
        return FinancialGoalCategory.education;
      case 'home':
        return FinancialGoalCategory.home;
      case 'vehicle':
        return FinancialGoalCategory.vehicle;
      case 'retirement':
        return FinancialGoalCategory.retirement;
      case 'investment':
        return FinancialGoalCategory.investment;
      case 'travel':
        return FinancialGoalCategory.travel;
      default:
        return FinancialGoalCategory.other;
    }
  }

  IconData get icon {
    switch (this) {
      case FinancialGoalCategory.emergencyFund:
        return Icons.health_and_safety_outlined;
      case FinancialGoalCategory.education:
        return Icons.school_outlined;
      case FinancialGoalCategory.home:
        return Icons.home_outlined;
      case FinancialGoalCategory.vehicle:
        return Icons.directions_car_outlined;
      case FinancialGoalCategory.retirement:
        return Icons.savings_outlined;
      case FinancialGoalCategory.investment:
        return Icons.trending_up;
      case FinancialGoalCategory.travel:
        return Icons.flight_takeoff_outlined;
      case FinancialGoalCategory.other:
        return Icons.flag_outlined;
    }
  }
}

/// Priority levels for goals.
enum FinancialGoalPriority {
  low,
  medium,
  high,
}

extension FinancialGoalPriorityExtension on FinancialGoalPriority {
  String get displayName {
    switch (this) {
      case FinancialGoalPriority.low:
        return 'Low';
      case FinancialGoalPriority.medium:
        return 'Medium';
      case FinancialGoalPriority.high:
        return 'High';
    }
  }

  static FinancialGoalPriority fromString(String val) {
    final lower = val.toLowerCase().trim();
    switch (lower) {
      case 'low':
        return FinancialGoalPriority.low;
      case 'high':
      case 'critical':
        return FinancialGoalPriority.high;
      default:
        return FinancialGoalPriority.medium;
    }
  }
}

/// Immutable FinancialGoal model.
class FinancialGoal {
  final String id;
  final String name;
  final FinancialGoalCategory category;
  final double targetAmount;
  final double currentAmount;
  final double monthlyContribution;
  final DateTime deadline;
  final FinancialGoalPriority priority;
  final bool isActive;
  final double remainingAmount;
  final double requiredMonthlyContribution;
  final double contributionGap;
  final int monthsRemaining;
  final bool isFeasible;
  final DateTime createdAt;
  final DateTime updatedAt;

  FinancialGoal({
    String? id,
    required this.name,
    this.category = FinancialGoalCategory.other,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.monthlyContribution = 0.0,
    required this.deadline,
    this.priority = FinancialGoalPriority.medium,
    this.isActive = true,
    double? remainingAmount,
    double? requiredMonthlyContribution,
    double? contributionGap,
    int? monthsRemaining,
    bool? isFeasible,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        remainingAmount = remainingAmount ?? (targetAmount - currentAmount > 0 ? targetAmount - currentAmount : 0.0),
        requiredMonthlyContribution = requiredMonthlyContribution ?? 0.0,
        contributionGap = contributionGap ?? 0.0,
        monthsRemaining = monthsRemaining ?? 12,
        isFeasible = isFeasible ?? true,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory FinancialGoal.fromJson(Map<String, dynamic> json) {
    final deadStr = (json['deadline'] ?? json['target_date']) as String?;
    final dLine = deadStr != null ? DateTime.parse(deadStr) : DateTime.now().add(const Duration(days: 365));

    final tAmt = double.tryParse(json['target_amount']?.toString() ?? '0') ?? 0.0;
    final cAmt = double.tryParse(json['current_amount']?.toString() ?? '0') ?? 0.0;
    final mCon = double.tryParse(json['monthly_contribution']?.toString() ?? '0') ?? 0.0;
    final rAmt = double.tryParse(json['remaining_amount']?.toString() ?? '0') ?? (tAmt - cAmt > 0 ? tAmt - cAmt : 0.0);
    final reqCon = double.tryParse(json['required_monthly_contribution']?.toString() ?? '0') ?? 0.0;
    final cGap = double.tryParse(json['contribution_gap']?.toString() ?? '0') ?? 0.0;

    return FinancialGoal(
      id: json['id'] as String?,
      name: (json['name'] ?? 'Untitled Goal') as String,
      category: FinancialGoalCategoryExtension.fromString((json['category'] ?? 'Other') as String),
      targetAmount: tAmt,
      currentAmount: cAmt,
      monthlyContribution: mCon,
      deadline: dLine,
      priority: FinancialGoalPriorityExtension.fromString((json['priority'] ?? 'Medium') as String),
      isActive: (json['is_active'] as bool?) ?? true,
      remainingAmount: rAmt,
      requiredMonthlyContribution: reqCon,
      contributionGap: cGap,
      monthsRemaining: (json['months_remaining'] as int?) ?? 12,
      isFeasible: (json['is_feasible'] as bool?) ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category.displayName,
      'target_amount': targetAmount.toStringAsFixed(2),
      'current_amount': currentAmount.toStringAsFixed(2),
      'monthly_contribution': monthlyContribution.toStringAsFixed(2),
      'deadline': deadline.toIso8601String().split('T')[0],
      'target_date': deadline.toIso8601String().split('T')[0],
      'priority': priority.displayName,
      'is_active': isActive,
    };
  }
}
