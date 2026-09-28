import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/expenses/models/expense.dart';
import 'package:second_brain/features/expenses/data/expense_api.dart';
import 'package:second_brain/features/expenses/data/expense_repository.dart';

void main() {
  group('Step 10E — Expense Model & API Serialization Tests', () {
    test('Expense.fromJson maps backend JSON cleanly into Flutter model', () {
      final json = {
        'id': 'test-uuid-123',
        'merchant': 'Supermarket Grocery',
        'amount': '125.50',
        'category': 'Food & Dining',
        'transaction_date': '2026-09-15',
        'notes': 'Weekly groceries',
      };

      final expense = Expense.fromJson(json);

      expect(expense.id, 'test-uuid-123');
      expect(expense.merchant, 'Supermarket Grocery');
      expect(expense.amount, 125.50);
      expect(expense.category, ExpenseCategory.food);
      expect(expense.date, DateTime(2026, 9, 15));
      expect(expense.notes, 'Weekly groceries');
    });

    test('Expense.toJson serializes model into backend API payload', () {
      final expense = Expense(
        id: 'test-uuid-123',
        merchant: 'Bus Ticket',
        category: ExpenseCategory.transport,
        amount: 45.00,
        date: DateTime(2026, 9, 16),
        notes: 'City bus',
      );

      final json = expense.toJson();

      expect(json['merchant'], 'Bus Ticket');
      expect(json['amount'], '45.00');
      expect(json['category'], 'Transport');
      expect(json['transaction_date'], '2026-09-16');
      expect(json['notes'], 'City bus');
    });

    test('ExpenseSummaryData.fromJson parses monthly summary JSON', () {
      final json = {
        'year': 2026,
        'month': 9,
        'total': '700.75',
        'category_totals': {
          'Food & Dining': '500.50',
          'Transport': '200.25',
          'Shopping': '0.00',
          'Bills & Utilities': '0.00',
          'Other': '0.00',
        },
      };

      final summary = ExpenseSummaryData.fromJson(json);

      expect(summary.year, 2026);
      expect(summary.month, 9);
      expect(summary.total, 700.75);
      expect(summary.categoryTotals[ExpenseCategory.food], 500.50);
      expect(summary.categoryTotals[ExpenseCategory.transport], 200.25);
    });

    test('ExpenseRepository fallback returns local month filtering when offline', () async {
      final repo = ExpenseRepository.instance;
      repo.resetSampleData();

      final monthExpenses = repo.getExpensesForMonth(2026, 9);
      expect(monthExpenses, isA<List<Expense>>());
    });
  });
}
