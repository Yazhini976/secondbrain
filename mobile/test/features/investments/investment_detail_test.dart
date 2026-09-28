import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/investments/models/investment.dart';
import 'package:second_brain/features/investments/investment_detail_screen.dart';
import 'package:second_brain/features/investments/add_investment_screen.dart';

void main() {
  group('Step 7C — Investment Detail Tests', () {
    late Investment testInvestment;

    setUp(() {
      testInvestment = Investment(
        id: 'test-inv-001',
        name: 'Gold Saving Scheme',
        type: InvestmentType.goldSavingScheme,
        monthlyContribution: 5000,
        totalPaid: 35000,
        installmentsPaid: 7,
        totalInstallments: 12,
        startDate: DateTime(2026, 3, 30),
        nextDueDate: DateTime(2026, 9, 30),
        maturityDate: DateTime(2027, 3, 30),
        notes: 'Muthoot Finance scheme',
      );
      InvestmentRepository.instance.addInvestment(testInvestment);
    });

    tearDown(() {
      InvestmentRepository.instance.deleteInvestment('test-inv-001');
    });

    testWidgets('InvestmentDetailScreen displays full investment information',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InvestmentDetailScreen(investmentId: testInvestment.id),
        ),
      );
      await tester.pumpAndSettle();

      // Name and Type
      expect(find.text('Gold Saving Scheme'), findsOneWidget);
      expect(find.text('Gold Saving Schemes'), findsOneWidget);

      // Financials
      expect(find.text('₹35,000'), findsOneWidget);

      // Installment Progress
      expect(find.text('7 / 12 installments'), findsOneWidget);
      expect(find.text('5 installments remaining'), findsOneWidget);

      // Schedule
      expect(find.text('30 Sep 2026'), findsOneWidget);
      expect(find.text('30 Mar 2027'), findsOneWidget);

      // Notes
      expect(find.text('Muthoot Finance scheme'), findsOneWidget);

      // Receipts
      expect(find.text('Receipts'), findsOneWidget);
      expect(find.text('No receipts added yet'), findsOneWidget);
    });

    testWidgets('Add Receipt shows temporary message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InvestmentDetailScreen(investmentId: testInvestment.id),
        ),
      );
      await tester.pumpAndSettle();

      final addReceiptBtn = find.text('Add Receipt');
      await tester.ensureVisible(addReceiptBtn);
      await tester.tap(addReceiptBtn);
      await tester.pump();

      expect(
        find.text('Receipt attachments will be available in a later step.'),
        findsOneWidget,
      );
    });

    testWidgets('Edit action opens AddInvestmentScreen with prefilled values',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AddInvestmentScreen(existing: testInvestment),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Investment'), findsOneWidget);
      expect(find.text('Gold Saving Scheme'), findsOneWidget);
      expect(find.text('5000'), findsOneWidget);
      expect(find.text('35000'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Muthoot Finance scheme'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Delete shows confirmation dialog and cancels without deleting',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InvestmentDetailScreen(investmentId: testInvestment.id),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete icon
      final deleteIcon = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Check dialog
      expect(find.text('Delete Investment?'), findsOneWidget);
      expect(
        find.text('This investment will be removed from your investment list.'),
        findsOneWidget,
      );

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Ensure investment still exists in repo
      expect(
        InvestmentRepository.instance.getInvestmentById(testInvestment.id),
        isNotNull,
      );
    });
  });
}
