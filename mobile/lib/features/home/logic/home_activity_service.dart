import 'package:flutter/material.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/expenses/data/expense_repository.dart';
import 'package:second_brain/features/expenses/models/expense.dart';
import 'package:second_brain/features/home/models/home_sample_data.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/investments/models/investment.dart';
import 'package:intl/intl.dart';

/// Builds a merged, time-sorted list of [RecentActivityItem]s from
/// live Expense, Investment, and Document repositories.
abstract final class HomeActivityService {
  static List<RecentActivityItem> getRecentActivity({int limit = 5}) {
    final items = <_TimedActivity>[];

    // --- Expenses ---
    for (final e in ExpenseRepository.instance.getRecent(limit: limit)) {
      items.add(_TimedActivity(
        date: e.date,
        item: RecentActivityItem(
          id: 'exp_${e.id}',
          title: e.merchant,
          category: e.category.displayName,
          amountOrDate: '-${_fmt(e.amount)}',
          icon: e.category.icon,
          isNegative: true,
        ),
      ));
    }

    // --- Investments ---
    for (final inv in InvestmentRepository.instance.getRecent(limit: limit)) {
      items.add(_TimedActivity(
        date: inv.startDate ?? DateTime.fromMillisecondsSinceEpoch(0),
        item: RecentActivityItem(
          id: 'inv_${inv.id}',
          title: inv.name,
          category: inv.type.displayName,
          amountOrDate: _fmt(inv.monthlyContribution),
          icon: _investmentIcon(inv.type),
          isNegative: false,
        ),
      ));
    }

    // --- Documents ---
    final docs = DocumentRepository.instance.getDocuments().toList()
      ..sort((a, b) {
        final aDate = a.issueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.issueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    for (final doc in docs.take(limit)) {
      final dateStr = doc.issueDate != null
          ? DateFormat('d MMM').format(doc.issueDate!)
          : 'N/A';
      items.add(_TimedActivity(
        date: doc.issueDate ?? DateTime.fromMillisecondsSinceEpoch(0),
        item: RecentActivityItem(
          id: 'doc_${doc.id}',
          title: doc.title,
          category: 'Document',
          amountOrDate: dateStr,
          icon: Icons.description_outlined,
          isNegative: false,
        ),
      ));
    }

    // Sort merged list by date descending, take limit
    items.sort((a, b) => b.date.compareTo(a.date));
    return items.take(limit).map((e) => e.item).toList();
  }

  static String _fmt(double amount) {
    final formatter = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(amount);
  }

  static IconData _investmentIcon(InvestmentType type) {
    switch (type) {
      case InvestmentType.gold:
      case InvestmentType.goldSavingScheme:
        return Icons.star_outline;
      case InvestmentType.chitFund:
        return Icons.groups_outlined;
      case InvestmentType.fd:
        return Icons.account_balance_outlined;
      case InvestmentType.rd:
        return Icons.savings_outlined;
      case InvestmentType.insurance:
        return Icons.shield_outlined;
    }
  }
}

class _TimedActivity {
  final DateTime date;
  final RecentActivityItem item;
  const _TimedActivity({required this.date, required this.item});
}
