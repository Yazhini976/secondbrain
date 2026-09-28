import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/app.dart';
import 'package:second_brain/core/auth/auth_service.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/expenses/data/expense_repository.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/settings/data/user_profile_repository.dart';

void main() {
  setUp(() {
    AuthService.instance.ensureDevSession();
    ExpenseRepository.instance.resetSampleData();
    InvestmentRepository.instance.resetSampleData();
    DocumentRepository.instance.resetSampleData();
    ReminderRepository.instance.resetSampleData();
  });

  testWidgets('Home dashboard components and tab navigation test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SecondBrainApp());
    await tester.pumpAndSettle();

    // ── Compute expected live values from sample repositories ──────────────
    final now = DateTime.now();
    final currencyFmt = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final thisMonthSpending = ExpenseRepository.instance
        .getTotalForMonth(now.year, now.month);
    final totalInvested = InvestmentRepository.instance.getTotalInvested();

    final expectedSpending = currencyFmt.format(thisMonthSpending);
    final expectedInvested = currencyFmt.format(totalInvested);

    // 1. Verify Header — greeting is time-aware so we check user name + subtitle
    final profileName = UserProfileRepository.instance.name;
    expect(find.textContaining(profileName), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);

    // 2. Verify Summary cards — values now come from live repositories
    expect(find.text(expectedSpending), findsOneWidget);
    expect(find.text(expectedInvested), findsOneWidget);
    expect(find.text('Items needing attention'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);

    // 3. Verify Quick Actions
    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Goals AI'), findsOneWidget);
    expect(find.text('Add Document'), findsOneWidget);
    expect(find.text('Add Investment'), findsOneWidget);

    // 4. Verify Needs Attention (dynamic attention items)
    expect(find.text('Vehicle Insurance'), findsWidgets);

    // 5. Verify Recent Activity — live data; Swiggy is the most recent expense
    expect(find.text('Swiggy'), findsOneWidget);

    // 6. Test Tab Navigation
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('Total Spending'), findsOneWidget);

    await tester.tap(find.text('Investments'));
    await tester.pumpAndSettle();
    expect(find.text('Total Invested'), findsOneWidget);

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('Keep your important documents organised'), findsOneWidget);

    // 7. Verify Settings tab (added in Step 11)
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Vault Snapshot'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.textContaining(profileName), findsOneWidget);
  });
}
