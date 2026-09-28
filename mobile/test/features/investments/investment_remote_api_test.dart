import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/investments/models/investment.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';

void main() {
  group('Step 10G — Remote Investments API & Repository Tests', () {
    setUp(() {
      InvestmentRepository.instance.resetSampleData();
    });

    test('1. Investment.fromJson maps JSON fields correctly', () {
      final json = {
        'id': 'test-uuid-123',
        'name': 'HDFC Term Fixed Deposit',
        'type': 'FD',
        'monthly_contribution': '5000.00',
        'total_paid': '50000.00',
        'total_installments': 12,
        'installments_paid': 10,
        'start_date': '2026-01-01',
        'next_due_date': '2026-11-01',
        'maturity_date': '2027-01-01',
        'notes': 'Emergency fund',
        'status': 'Due Soon',
        'progress_percentage': 83.33,
      };

      final inv = Investment.fromJson(json);

      expect(inv.id, 'test-uuid-123');
      expect(inv.name, 'HDFC Term Fixed Deposit');
      expect(inv.type, InvestmentType.fd);
      expect(inv.monthlyContribution, 5000.00);
      expect(inv.totalPaid, 50000.00);
      expect(inv.totalInstallments, 12);
      expect(inv.installmentsPaid, 10);
      expect(inv.startDate, DateTime(2026, 1, 1));
      expect(inv.nextDueDate, DateTime(2026, 11, 1));
      expect(inv.maturityDate, DateTime(2027, 1, 1));
      expect(inv.notes, 'Emergency fund');
      expect(inv.serverStatus, 'Due Soon');
      expect(inv.progressPercentage, 83.33);
    });

    test('2. Investment.toJson serializes model for POST/PATCH payload', () {
      final inv = Investment(
        id: 'test-123',
        name: 'Gold Scheme',
        type: InvestmentType.goldSavingScheme,
        monthlyContribution: 2000.0,
        totalPaid: 6000.0,
        installmentsPaid: 3,
        totalInstallments: 11,
        startDate: DateTime(2026, 2, 1),
        nextDueDate: DateTime(2026, 10, 1),
        notes: 'Monthly gold savings',
      );

      final json = inv.toJson();

      expect(json['name'], 'Gold Scheme');
      expect(json['type'], 'Gold Saving Schemes');
      expect(json['monthly_contribution'], 2000.0);
      expect(json['total_paid'], 6000.0);
      expect(json['installments_paid'], 3);
      expect(json['total_installments'], 11);
      expect(json['start_date'], '2026-02-01');
      expect(json['next_due_date'], '2026-10-01');
      expect(json['notes'], 'Monthly gold savings');
    });

    test('3. InvestmentSummaryData.fromJson parses portfolio summary JSON', () {
      final json = {
        'total_invested': '125000.50',
        'total_monthly_contribution': '15000.00',
        'active_count': 5,
        'completed_count': 2,
        'overdue_count': 1,
        'due_soon_count': 1,
      };

      final summary = InvestmentSummaryData.fromJson(json);

      expect(summary.totalInvested, 125000.50);
      expect(summary.totalMonthlyContribution, 15000.00);
      expect(summary.activeCount, 5);
      expect(summary.completedCount, 2);
      expect(summary.overdueCount, 1);
      expect(summary.dueSoonCount, 1);
    });

    test('4. Repository loadInvestments falls back gracefully when server is offline', () async {
      final repo = InvestmentRepository.instance;
      final list = await repo.loadInvestments();
      expect(list, isNotEmpty);
    });

    test('5. Repository loadInvestments by type filters locally on fallback', () async {
      final repo = InvestmentRepository.instance;
      final list = await repo.loadInvestments(type: 'FD');
      expect(list.every((i) => i.type == InvestmentType.fd), isTrue);
    });

    test('6. Add, edit, and delete in repository updates in-memory list', () async {
      final repo = InvestmentRepository.instance;
      final initialCount = repo.getInvestments().length;

      final newInv = Investment(
        name: 'Unit Test Insurance',
        type: InvestmentType.insurance,
        monthlyContribution: 1000.0,
        totalPaid: 2000.0,
        installmentsPaid: 2,
        totalInstallments: 12,
      );

      // Add
      try {
        await repo.addInvestment(newInv);
      } catch (_) {}
      expect(repo.getInvestments().length, initialCount + 1);

      // Edit
      final addedItem = repo.getInvestments().last;
      final updatedItem = addedItem.copyWith(totalPaid: 3000.0);
      try {
        await repo.updateInvestment(updatedItem);
      } catch (_) {}
      expect(repo.getInvestmentById(addedItem.id)?.totalPaid, 3000.0);

      // Delete
      try {
        await repo.deleteInvestment(addedItem.id);
      } catch (_) {}
      expect(repo.getInvestmentById(addedItem.id), isNull);
    });
  });
}
