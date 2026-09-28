import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  transport,
  shopping,
  bills,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.bills:
        return 'Bills & Utilities';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  static ExpenseCategory fromDisplayName(String name) {
    switch (name) {
      case 'Food & Dining':
        return ExpenseCategory.food;
      case 'Transport':
        return ExpenseCategory.transport;
      case 'Shopping':
        return ExpenseCategory.shopping;
      case 'Bills & Utilities':
        return ExpenseCategory.bills;
      case 'Other':
      default:
        return ExpenseCategory.other;
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.fastfood;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.shopping:
        return Icons.shopping_cart;
      case ExpenseCategory.bills:
        return Icons.receipt_long;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }
}

class Expense {
  final String id;
  final String merchant;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? notes;

  Expense({
    String? id,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Expense copyWith({
    String? merchant,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    String? notes,
  }) {
    return Expense(
      id: id,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      merchant: json['merchant'] as String,
      category: ExpenseCategoryExtension.fromDisplayName(json['category'] as String),
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.parse(json['amount'].toString()),
      date: DateTime.parse(json['transaction_date'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant': merchant,
      'amount': amount.toStringAsFixed(2),
      'category': category.displayName,
      'transaction_date':
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      if (notes != null) 'notes': notes,
    };
  }
}
