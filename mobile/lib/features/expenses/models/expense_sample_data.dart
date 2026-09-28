import 'package:second_brain/features/expenses/models/expense.dart';

class ExpenseSampleData {
  static final List<Expense> expenses = [
    Expense(
      id: 'exp_1',
      merchant: 'Swiggy',
      category: ExpenseCategory.food,
      amount: 420.0,
      date: DateTime(2026, 9, 27),
    ),
    Expense(
      id: 'exp_2',
      merchant: 'Uber',
      category: ExpenseCategory.transport,
      amount: 280.0,
      date: DateTime(2026, 9, 26),
    ),
    Expense(
      id: 'exp_3',
      merchant: 'Amazon',
      category: ExpenseCategory.shopping,
      amount: 1299.0,
      date: DateTime(2026, 9, 20),
    ),
    Expense(
      id: 'exp_4',
      merchant: 'Electricity',
      category: ExpenseCategory.bills,
      amount: 1850.0,
      date: DateTime(2026, 9, 18),
    ),
    Expense(
      id: 'exp_5',
      merchant: 'Cafe',
      category: ExpenseCategory.food,
      amount: 320.0,
      date: DateTime(2026, 9, 17),
    ),
    Expense(
      id: 'exp_6',
      merchant: 'Grocery',
      category: ExpenseCategory.food,
      amount: 8000.0,
      date: DateTime(2026, 9, 10),
    ),
    Expense(
      id: 'exp_7',
      merchant: 'Metro',
      category: ExpenseCategory.transport,
      amount: 3870.0,
      date: DateTime(2026, 9, 5),
    ),
    Expense(
      id: 'exp_8',
      merchant: 'Clothes Store',
      category: ExpenseCategory.shopping,
      amount: 3980.0,
      date: DateTime(2026, 9, 2),
    ),
    Expense(
      id: 'exp_9',
      merchant: 'Internet',
      category: ExpenseCategory.bills,
      amount: 2380.0,
      date: DateTime(2026, 9, 1),
    ),
    Expense(
      id: 'exp_10',
      merchant: 'Misc',
      category: ExpenseCategory.other,
      amount: 2600.0,
      date: DateTime(2026, 9, 3),
    ),
  ];
}
