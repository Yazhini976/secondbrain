import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/investments/logic/investment_status.dart';
import 'package:second_brain/features/investments/models/investment.dart';
import 'package:second_brain/features/investments/add_investment_screen.dart';

void main() {
  group('Step 7B — Add Investment Tests', () {
    test('InvestmentRepository adds new investment properly', () {
      final repo = InvestmentRepository.instance;
      final initialCount = repo.getInvestments().length;

      final newInv = Investment(
        name: 'Monthly RD',
        type: InvestmentType.rd,
        monthlyContribution: 3000,
        totalPaid: 12000,
        installmentsPaid: 4,
        totalInstallments: 24,
        startDate: DateTime(2026, 9, 27),
        nextDueDate: DateTime(2026, 10, 5),
        maturityDate: DateTime(2028, 9, 5),
        notes: 'Monthly recurring deposit',
      );

      repo.addInvestment(newInv);

      expect(repo.getInvestments().length, initialCount + 1);
      final added = repo.getInvestments().firstWhere((i) => i.name == 'Monthly RD');
      expect(added.monthlyContribution, 3000);
      expect(added.totalPaid, 12000);
      expect(added.installmentsPaid, 4);
      expect(added.totalInstallments, 24);
      expect(added.type, InvestmentType.rd);

      // Verify derived status
      final status = deriveStatus(
        installmentsPaid: added.installmentsPaid,
        totalInstallments: added.totalInstallments,
        nextDueDate: added.nextDueDate,
      );
      expect(status, InvestmentStatus.onTrack);
    });

    testWidgets('AddInvestmentScreen validates empty name and invalid numbers',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddInvestmentScreen(),
        ),
      );

      // Tap Save Investment without filling required fields
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Investment');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Enter an investment name.'), findsOneWidget);
      expect(find.text('Enter a valid contribution.'), findsOneWidget);
      expect(find.text('Enter a valid total paid amount.'), findsOneWidget);
      expect(find.text('Enter total installments.'), findsOneWidget);
      expect(find.text('Enter installments paid.'), findsOneWidget);
    });

    testWidgets('AddInvestmentScreen validates installments paid > total installments',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddInvestmentScreen(),
        ),
      );

      final totalInstField = find.widgetWithText(TextFormField, 'Total Installments *');
      final paidInstField = find.widgetWithText(TextFormField, 'Installments Paid *');

      await tester.enterText(totalInstField, '10');
      await tester.enterText(paidInstField, '15');

      final saveButton = find.widgetWithText(ElevatedButton, 'Save Investment');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Installments paid cannot exceed total installments.'),
          findsOneWidget);
    });

    testWidgets('AddInvestmentScreen attachment placeholder shows SnackBar',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddInvestmentScreen(),
        ),
      );

      final attachButton = find.text('Attach Receipt / Document');
      await tester.ensureVisible(attachButton);
      await tester.tap(attachButton);
      await tester.pump();

      expect(find.text('Attachments will be available in a later step.'),
          findsOneWidget);
    });
  });
}
