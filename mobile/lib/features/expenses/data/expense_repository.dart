import 'package:flutter/foundation.dart';
import 'package:second_brain/features/expenses/models/expense.dart';
import 'package:second_brain/features/expenses/models/expense_sample_data.dart';
import 'package:second_brain/features/expenses/data/expense_api.dart';

/// Expense Repository.
/// Acts as the clean domain abstraction between Flutter UI and backend API.
/// Extends [ChangeNotifier] so screens (Home, Expenses, etc.) reactively rebuild.
class ExpenseRepository extends ChangeNotifier {
  static ExpenseRepository instance = ExpenseRepository._internal();

  final ExpenseApi _api;
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  ExpenseRepository._internal({ExpenseApi? api})
      : _api = api ?? ExpenseApi() {
    _expenses = [];
  }

  /// Factory constructor for testing / dependency injection.
  factory ExpenseRepository({ExpenseApi? api}) {
    return ExpenseRepository._internal(api: api);
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Expense> getExpenses() => List.unmodifiable(_expenses);

  /// Clears in-memory expenses when switching users or logging out.
  void clear() {
    _expenses = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Returns an expense by ID, or null if not found.
  Expense? getById(String id) {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Loads expenses from backend for a specific month and optional category filter.
  Future<List<Expense>> loadExpensesForMonth(
    int year,
    int month, {
    String? category,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteExpenses = await _api.getExpenses(
        year: year,
        month: month,
        category: category,
      );
      _expenses = remoteExpenses;
      _isLoading = false;
      notifyListeners();
      return _expenses;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
      _isLoading = false;
      notifyListeners();
      return getExpensesForMonth(year, month);
    }
  }

  /// Fetches monthly summary data calculated server-side by PostgreSQL.
  Future<ExpenseSummaryData?> fetchMonthlySummary(int year, int month) async {
    try {
      return await _api.getExpenseSummary(year: year, month: month);
    } catch (e) {
      return null;
    }
  }

  /// Returns all in-memory loaded expenses in [month] of [year], sorted newest-first.
  List<Expense> getExpensesForMonth(int year, int month) {
    return _expenses
        .where((e) => e.date.year == year && e.date.month == month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Sum of all amounts for the given month/year.
  double getTotalForMonth(int year, int month) {
    return getExpensesForMonth(year, month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Returns the [limit] most-recent expenses across all months.
  List<Expense> getRecent({int limit = 5}) {
    final sorted = List<Expense>.from(_expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  /// Adds a new expense via backend API and updates state.
  Future<Expense> addExpense(Expense expense) async {
    try {
      final created = await _api.createExpense(expense);
      final idx = _expenses.indexWhere((e) => e.id == expense.id || e.id == created.id);
      if (idx != -1) {
        _expenses[idx] = created;
      } else {
        _expenses.add(created);
      }
      notifyListeners();
      return created;
    } catch (e) {
      // Local fallback for offline/test mode if server is unreachable
      if (!_expenses.any((e) => e.id == expense.id)) {
        _expenses.add(expense);
      }
      notifyListeners();
      return expense;
    }
  }

  /// Updates an expense via backend API and updates state.
  Future<Expense> updateExpense(Expense updated) async {
    try {
      final serverUpdated = await _api.updateExpense(updated);
      final index = _expenses.indexWhere((e) => e.id == serverUpdated.id);
      if (index != -1) {
        _expenses[index] = serverUpdated;
      } else {
        _expenses.add(serverUpdated);
      }
      notifyListeners();
      return serverUpdated;
    } catch (e) {
      final index = _expenses.indexWhere((e) => e.id == updated.id);
      if (index != -1) {
        _expenses[index] = updated;
        notifyListeners();
      }
      rethrow;
    }
  }

  /// Deletes an expense via backend API and updates state.
  Future<void> deleteExpense(String id) async {
    final index = _expenses.indexWhere((e) => e.id == id);

    try {
      await _api.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      // Fallback local deletion for offline/test mode
      if (index != -1) {
        _expenses.removeWhere((e) => e.id == id);
        notifyListeners();
      }
      rethrow;
    }
  }

  /// Resets to initial state for testing.
  void resetSampleData() {
    _expenses = List<Expense>.from(ExpenseSampleData.expenses);
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
