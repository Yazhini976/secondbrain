import 'package:second_brain/core/network/api_client.dart';
import 'package:second_brain/features/expenses/models/expense.dart';

class ExpenseSummaryData {
  final int year;
  final int month;
  final double total;
  final Map<ExpenseCategory, double> categoryTotals;

  ExpenseSummaryData({
    required this.year,
    required this.month,
    required this.total,
    required this.categoryTotals,
  });

  factory ExpenseSummaryData.fromJson(Map<String, dynamic> json) {
    final catTotalsJson = json['category_totals'] as Map<String, dynamic>? ?? {};
    final categoryTotalsMap = <ExpenseCategory, double>{};
    catTotalsJson.forEach((key, val) {
      final category = ExpenseCategoryExtension.fromDisplayName(key);
      final doubleVal = (val is num) ? val.toDouble() : double.parse(val.toString());
      categoryTotalsMap[category] = doubleVal;
    });

    return ExpenseSummaryData(
      year: json['year'] as int,
      month: json['month'] as int,
      total: (json['total'] is num) ? (json['total'] as num).toDouble() : double.parse(json['total'].toString()),
      categoryTotals: categoryTotalsMap,
    );
  }
}

class ExpenseApi {
  final ApiClient _apiClient;

  ExpenseApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Expense>> getExpenses({
    int? year,
    int? month,
    String? category,
  }) async {
    final queryParams = <String, String>{};
    if (year != null) queryParams['year'] = year.toString();
    if (month != null) queryParams['month'] = month.toString();
    if (category != null && category.isNotEmpty) queryParams['category'] = category;

    final response = await _apiClient.get('/expenses', queryParameters: queryParams);
    final list = response as List<dynamic>;
    return list.map((item) => Expense.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ExpenseSummaryData> getExpenseSummary({
    required int year,
    required int month,
  }) async {
    final response = await _apiClient.get(
      '/expenses/summary',
      queryParameters: {'year': year.toString(), 'month': month.toString()},
    );
    return ExpenseSummaryData.fromJson(response as Map<String, dynamic>);
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await _apiClient.post('/expenses', body: expense.toJson());
    return Expense.fromJson(response as Map<String, dynamic>);
  }

  Future<Expense> updateExpense(Expense expense) async {
    final response = await _apiClient.patch('/expenses/${expense.id}', body: expense.toJson());
    return Expense.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteExpense(String id) async {
    await _apiClient.delete('/expenses/$id');
  }
}
