import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/shared/widgets/app_card.dart';
import 'package:second_brain/shared/widgets/section_header.dart';
import 'package:second_brain/features/expenses/models/expense.dart';
import 'package:second_brain/features/expenses/data/expense_repository.dart';
import 'package:second_brain/features/expenses/data/expense_api.dart';
import 'package:second_brain/features/expenses/add_expense_screen.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _selectedMonth = DateTime.now();
  ExpenseCategory? _selectedCategoryFilter;
  ExpenseSummaryData? _serverSummary;
  bool _isLoadingBackend = false;
  bool _showAllTransactions = false;

  @override
  void initState() {
    super.initState();
    ExpenseRepository.instance.addListener(_onDataChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBackendData();
      }
    });
  }

  @override
  void dispose() {
    ExpenseRepository.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadBackendData() async {
    if (!mounted) return;
    setState(() => _isLoadingBackend = true);

    try {
      await ExpenseRepository.instance.loadExpensesForMonth(
        _selectedMonth.year,
        _selectedMonth.month,
        category: _selectedCategoryFilter?.displayName,
      );

      final summary = await ExpenseRepository.instance.fetchMonthlySummary(
        _selectedMonth.year,
        _selectedMonth.month,
      );

      if (mounted) {
        setState(() {
          _serverSummary = summary;
          _isLoadingBackend = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingBackend = false);
      }
    }
  }

  List<Expense> get _filteredExpenses {
    var list = ExpenseRepository.instance.getExpensesForMonth(
        _selectedMonth.year, _selectedMonth.month);
    if (_selectedCategoryFilter != null) {
      list = list.where((e) => e.category == _selectedCategoryFilter).toList();
    }
    return list;
  }

  double get _totalSpending {
    if (_serverSummary != null && _selectedCategoryFilter == null) {
      return _serverSummary!.total;
    }
    return _filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  // Spending for the previous month (for comparison)
  double get _prevMonthSpending {
    final prev = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    return ExpenseRepository.instance.getTotalForMonth(prev.year, prev.month);
  }

  Map<ExpenseCategory, double> get _categoryTotals {
    if (_serverSummary != null && _selectedCategoryFilter == null) {
      return _serverSummary!.categoryTotals;
    }
    final map = <ExpenseCategory, double>{};
    for (var e in _filteredExpenses) {
      map.update(e.category, (value) => value + e.amount,
          ifAbsent: () => e.amount);
    }
    return map;
  }

  final Map<ExpenseCategory, Color> _categoryColors = {
    ExpenseCategory.food: AppColors.darkBlue,
    ExpenseCategory.transport: AppColors.primaryBrightBlue,
    ExpenseCategory.shopping: AppColors.successGreen,
    ExpenseCategory.bills: AppColors.warningOrange,
    ExpenseCategory.other: AppColors.mutedText,
  };

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
    _loadBackendData();
  }

  String _formattedAmount(double amount) {
    final formatter = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    return DateFormat('d MMM').format(date);
  }

  Future<void> _openAddExpense() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    if (result == true) {
      _loadBackendData();
    }
  }

  Future<void> _openEditExpense(Expense expense) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(existing: expense),
      ),
    );
    if (result == true) {
      _loadBackendData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadBackendData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),

              // Category filter pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategoryFilter == null,
                      onSelected: (_) {
                        setState(() => _selectedCategoryFilter = null);
                        _loadBackendData();
                      },
                    ),
                    const SizedBox(width: 8),
                    ...ExpenseCategory.values.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat.displayName),
                            selected: _selectedCategoryFilter == cat,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryFilter = selected ? cat : null;
                              });
                              _loadBackendData();
                            },
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              if (_isLoadingBackend)
                const LinearProgressIndicator(minHeight: 2),

              _buildSummaryCard(),
              const SizedBox(height: AppSpacing.space16),
              if (_categoryTotals.values.any((v) => v > 0)) ...[
                _buildCategoryBreakdown(),
                const SizedBox(height: AppSpacing.space16),
              ],
              _buildTransactionList(),
              const SizedBox(height: AppSpacing.space24),
              // Add Expense button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _openAddExpense,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final prev = _prevMonthSpending;
    final diff = _totalSpending - prev;
    final isUp = diff >= 0;
    final diffPct =
        prev > 0 ? ((diff.abs() / prev) * 100).toStringAsFixed(1) : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Spending',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryText),
          ),
          const SizedBox(height: 4),
          Text(
            _formattedAmount(_totalSpending),
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${_filteredExpenses.length} transaction${_filteredExpenses.length == 1 ? '' : 's'}',
                style:
                    const TextStyle(fontSize: 13, color: AppColors.mutedText),
              ),
              if (diffPct != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        isUp ? AppColors.lightRed : AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 11,
                        color: isUp
                            ? AppColors.negativeRed
                            : AppColors.successGreen,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$diffPct% vs last month',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isUp
                              ? AppColors.negativeRed
                              : AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final activeCategories =
        _categoryTotals.entries.where((e) => e.value > 0).toList();
    if (activeCategories.isEmpty) return const SizedBox.shrink();

    final percentages = Map.fromEntries(activeCategories
        .map((e) => MapEntry(e.key, _totalSpending > 0 ? (e.value / _totalSpending * 100) : 0.0)));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Spending by Category'),
          const SizedBox(height: AppSpacing.space12),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: activeCategories.map((e) {
                  final percent = percentages[e.key] ?? 0.0;
                  return PieChartSectionData(
                    value: e.value,
                    title: '${percent.toStringAsFixed(1)}%',
                    color: _categoryColors[e.key] ?? AppColors.mutedText,
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          ...activeCategories.map((e) => Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        _categoryColors[e.key]?.withValues(alpha: 0.12) ??
                            Colors.grey.shade200,
                    child: Icon(e.key.icon,
                        size: 16,
                        color: _categoryColors[e.key] ?? Colors.grey),
                  ),
                  title: Text(e.key.displayName,
                      style: const TextStyle(fontSize: 14)),
                  trailing: Text(_formattedAmount(e.value),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final expenses = _filteredExpenses;
    final shown = _showAllTransactions ? expenses : expenses.take(5).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Transactions (${expenses.length})'),
          const SizedBox(height: AppSpacing.space8),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No transactions this month.',
                    style: TextStyle(color: AppColors.mutedText)),
              ),
            )
          else
            ...shown.map((e) => _buildTransactionTile(e)),
          if (expenses.length > 5)
            TextButton(
              onPressed: () =>
                  setState(() => _showAllTransactions = !_showAllTransactions),
              child: Text(_showAllTransactions
                  ? 'Show less'
                  : 'Show all ${expenses.length} transactions'),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Expense e) {
    return Dismissible(
      key: Key(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade50,
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Expense'),
            content: Text(
                'Delete "${e.merchant}" for ${_formattedAmount(e.amount)}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return confirmed == true;
      },
      onDismissed: (_) async {
        try {
          await ExpenseRepository.instance.deleteExpense(e.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${e.merchant} deleted'),
              ),
            );
            _loadBackendData();
          }
        } catch (err) {
          if (mounted) {
            final msg = err.toString().replaceAll('ApiException: ', '');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete: $msg'),
                backgroundColor: Colors.red,
              ),
            );
            _loadBackendData();
          }
        }
      },
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor:
                _categoryColors[e.category]?.withValues(alpha: 0.12) ??
                    Colors.grey.shade200,
            child: Icon(e.category.icon,
                size: 16, color: _categoryColors[e.category] ?? Colors.grey),
          ),
          title: Text(e.merchant,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text(
              '${e.category.displayName} · ${_formatDate(e.date)}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.mutedText)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_formattedAmount(e.amount),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.mutedText),
            ],
          ),
          onTap: () => _openEditExpense(e),
        ),
      ),
    );
  }
}
