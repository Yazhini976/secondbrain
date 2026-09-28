import 'package:second_brain/features/investments/models/investment.dart';

/// Realistic sample records covering all six required investment types.
/// Dates are relative to September 2026 to produce varied statuses.
class InvestmentSampleData {
  static final List<Investment> investments = [
    // --- Gold Saving Schemes ---
    Investment(
      id: 'inv-001',
      name: 'Gold Saving Scheme',
      type: InvestmentType.goldSavingScheme,
      monthlyContribution: 5000,
      totalPaid: 35000,
      installmentsPaid: 7,
      totalInstallments: 12,
      nextDueDate: DateTime(2026, 9, 30),
      maturityDate: DateTime(2027, 3, 30),
      notes: 'Muthoot Finance scheme',
    ),

    // --- RD ---
    Investment(
      id: 'inv-002',
      name: 'Recurring Deposit',
      type: InvestmentType.rd,
      monthlyContribution: 3000,
      totalPaid: 36000,
      installmentsPaid: 12,
      totalInstallments: 24,
      nextDueDate: DateTime(2026, 10, 5),
      maturityDate: DateTime(2028, 9, 5),
      notes: 'SBI RD account',
    ),

    // --- Insurance ---
    Investment(
      id: 'inv-003',
      name: 'Vehicle Insurance',
      type: InvestmentType.insurance,
      monthlyContribution: 2500,
      totalPaid: 25000,
      installmentsPaid: 10,
      totalInstallments: 12,
      nextDueDate: DateTime(2026, 9, 28),
      maturityDate: DateTime(2026, 11, 28),
    ),

    // --- FD ---
    Investment(
      id: 'inv-004',
      name: 'Fixed Deposit',
      type: InvestmentType.fd,
      monthlyContribution: 10000,
      totalPaid: 120000,
      installmentsPaid: 12,
      totalInstallments: 12,
      nextDueDate: null,
      maturityDate: DateTime(2027, 9, 1),
      notes: 'HDFC Bank FD — matured',
    ),

    // --- Chit Fund ---
    Investment(
      id: 'inv-005',
      name: 'Family Kuri',
      type: InvestmentType.chitFund,
      monthlyContribution: 4000,
      totalPaid: 20000,
      installmentsPaid: 5,
      totalInstallments: 20,
      nextDueDate: DateTime(2026, 9, 20), // past — Overdue
      maturityDate: DateTime(2028, 4, 20),
      notes: 'Local chit group',
    ),

    // --- Gold & Jewellery ---
    Investment(
      id: 'inv-006',
      name: 'Gold Jewellery Purchase',
      type: InvestmentType.gold,
      monthlyContribution: 8000,
      totalPaid: 48000,
      installmentsPaid: 6,
      totalInstallments: 10,
      nextDueDate: DateTime(2026, 10, 15),
      maturityDate: DateTime(2027, 3, 15),
      notes: 'Tanishq gold scheme',
    ),

    // --- Insurance (life) ---
    Investment(
      id: 'inv-007',
      name: 'Life Insurance Premium',
      type: InvestmentType.insurance,
      monthlyContribution: 1800,
      totalPaid: 21600,
      installmentsPaid: 12,
      totalInstallments: 12,
      nextDueDate: null,
      maturityDate: DateTime(2036, 9, 1),
      notes: 'LIC policy — annual premium completed',
    ),
  ];
}
