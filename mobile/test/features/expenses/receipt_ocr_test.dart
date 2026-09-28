import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/expenses/data/expense_repository.dart';
import 'package:second_brain/features/expenses/models/expense.dart';
import 'package:second_brain/features/expenses/ocr/receipt_ocr_result.dart';
import 'package:second_brain/features/expenses/ocr/receipt_parser.dart';

void main() {
  const parser = ReceiptParser();

  setUp(() {
    ExpenseRepository.instance.resetSampleData();
  });

  group('Receipt OCR & Intelligence Tests', () {
    // -------------------------------------------------------------------------
    // 1. OCR Result Model Parsing
    // -------------------------------------------------------------------------
    test('1. OCR result model parsing creates structured data correctly', () {
      final date = DateTime(2026, 9, 28);
      const item1 = ReceiptLineItem(name: 'Aashirvaad Atta 5kg', price: 275.0);
      final result = ReceiptOcrResult(
        merchantName: 'Reliance Smart',
        totalAmount: 1248.50,
        date: date,
        category: ExpenseCategory.food,
        rawText: 'RELIANCE SMART\nTOTAL: 1248.50',
        confidence: 0.95,
        detectedItems: const [item1],
      );

      expect(result.merchantName, 'Reliance Smart');
      expect(result.totalAmount, 1248.50);
      expect(result.date, date);
      expect(result.category, ExpenseCategory.food);
      expect(result.currency, 'INR');
      expect(result.formattedDate, '28/09/2026');
      expect(result.formattedAmount, '₹1,248.50');
      expect(result.hasAnyExtractedField, isTrue);
      expect(result.detectedItems.length, 1);
      expect(result.detectedItems.first.name, 'Aashirvaad Atta 5kg');
    });

    // -------------------------------------------------------------------------
    // 2. Amount Extraction
    // -------------------------------------------------------------------------
    test('2. Amount extraction extracts various Indian receipt total formats', () {
      const receipt1 = '''
      RELIANCE SMART
      ITEMS: 3
      GRAND TOTAL: ₹1,248.50
      THANK YOU
      ''';
      final res1 = parser.parse(receipt1);
      expect(res1.totalAmount, 1248.50);

      const receipt2 = '''
      SARAVANA BHAVAN
      MEALS: 200.00
      COFFEE: 50.00
      NET AMOUNT: Rs. 250
      CASH
      ''';
      final res2 = parser.parse(receipt2);
      expect(res2.totalAmount, 250.0);

      const receipt3 = '''
      INDIAN OIL CORPORATION
      PETROL: 45.2L
      TOTAL AMOUNT : INR 4600.00
      ''';
      final res3 = parser.parse(receipt3);
      expect(res3.totalAmount, 4600.0);
    });

    // -------------------------------------------------------------------------
    // 3. Currency Normalization
    // -------------------------------------------------------------------------
    test('3. Currency normalization defaults to INR and formats with ₹ symbol', () {
      const receipt = '''
      CAFE COFFEE DAY
      CAPPUCCINO 180
      AMOUNT DUE : Rs. 180.00
      ''';
      final res = parser.parse(receipt);
      expect(res.currency, 'INR');
      expect(res.formattedAmount, '₹180');
    });

    // -------------------------------------------------------------------------
    // 4. Date Extraction
    // -------------------------------------------------------------------------
    test('4. Date extraction supports DD/MM/YYYY, DD-MM-YYYY, and DD MMM YYYY', () {
      const receipt1 = '''
      DMART
      DATE: 28/09/2026
      TOTAL: 850
      ''';
      expect(parser.parse(receipt1).date, DateTime(2026, 9, 28));

      const receipt2 = '''
      APOLLO PHARMACY
      BILL DATE: 15-08-2026
      TOTAL: 320
      ''';
      expect(parser.parse(receipt2).date, DateTime(2026, 8, 15));

      const receipt3 = '''
      SHELL PETROL
      DT: 05 Oct 2026
      TOTAL: 1500
      ''';
      expect(parser.parse(receipt3).date, DateTime(2026, 10, 5));
    });

    // -------------------------------------------------------------------------
    // 5. Merchant Extraction
    // -------------------------------------------------------------------------
    test('5. Merchant extraction identifies store name and ignores non-merchant headers', () {
      const receipt = '''
      TAX INVOICE
      GSTIN: 33AAAAA0000A1Z5
      PHONE: 9876543210
      Reliance Smart
      123 M.G ROAD CHENNAI
      DATE: 28/09/2026
      TOTAL: 500
      ''';
      final res = parser.parse(receipt);
      expect(res.merchantName, 'Reliance Smart');
    });

    // -------------------------------------------------------------------------
    // 6. Category Mapping
    // -------------------------------------------------------------------------
    test('6. Category mapping maps receipts to existing ExpenseCategory enum', () {
      // Food & Dining
      final foodReceipt = parser.parse('ZOMATO\nFOOD DELIVERY\nTOTAL: 450');
      expect(foodReceipt.category, ExpenseCategory.food);

      final groceryReceipt = parser.parse('D-Mart Supermarket\nGroceries\nTOTAL: 1200');
      expect(groceryReceipt.category, ExpenseCategory.food);

      // Transport
      final fuelReceipt = parser.parse('BHARAT PETROLEUM\nPETROL FUEL\nTOTAL: 2000');
      expect(fuelReceipt.category, ExpenseCategory.transport);

      final uberReceipt = parser.parse('Uber India\nTrip Fare\nTOTAL: 350');
      expect(uberReceipt.category, ExpenseCategory.transport);

      // Shopping
      final shopReceipt = parser.parse('ZUDIO\nFASHION CLOTHING\nTOTAL: 1599');
      expect(shopReceipt.category, ExpenseCategory.shopping);

      // Bills & Utilities
      final billReceipt = parser.parse('BESCOM ELECTRICITY BILL\nPOWER CHARGES\nTOTAL: 850');
      expect(billReceipt.category, ExpenseCategory.bills);

      // Other fallback
      final otherReceipt = parser.parse('GENERAL STORE\nMISCELLANEOUS\nTOTAL: 100');
      expect(otherReceipt.category, ExpenseCategory.other);
    });

    // -------------------------------------------------------------------------
    // 7. Total Selection When Multiple Amounts Exist
    // -------------------------------------------------------------------------
    test('7. Total selection picks the grand/net total instead of subtotal or tax', () {
      const complexReceipt = '''
      SUPERMARKET
      ITEM 1: 250.00
      ITEM 2: 150.00
      ITEM 3: 100.00
      SUBTOTAL: 500.00
      CGST 2.5%: 12.50
      SGST 2.5%: 12.50
      TOTAL TAX: 25.00
      ROUND OFF: 0.00
      GRAND TOTAL: 525.00
      CASH TENDERED: 1000.00
      CHANGE DUE: 475.00
      ''';
      final res = parser.parse(complexReceipt);
      expect(res.totalAmount, 525.00);
    });

    // -------------------------------------------------------------------------
    // 8. Empty OCR Result
    // -------------------------------------------------------------------------
    test('8. Empty OCR result leaves fields null without throwing errors', () {
      final res = parser.parse('');
      expect(res.merchantName, isNull);
      expect(res.totalAmount, isNull);
      expect(res.date, isNull);
      expect(res.category, isNull);
      expect(res.hasAnyExtractedField, isFalse);
    });

    // -------------------------------------------------------------------------
    // 9. Partial OCR Result
    // -------------------------------------------------------------------------
    test('9. Partial OCR result retains detected fields and leaves missing null', () {
      const partialReceipt = '''
      Reliance Fresh
      DATE: 20/09/2026
      [UNREADABLE SMUDGE NO TOTAL DETECTED]
      THANK YOU VISIT AGAIN
      ''';
      final res = parser.parse(partialReceipt);
      expect(res.merchantName, 'Reliance Fresh');
      expect(res.category, ExpenseCategory.food);
      expect(res.date, DateTime(2026, 9, 20));
      expect(res.totalAmount, isNull);
      expect(res.hasAnyExtractedField, isTrue);
    });

    // -------------------------------------------------------------------------
    // 10. User Editing OCR Result Before Save
    // -------------------------------------------------------------------------
    test('10. User can modify OCR extracted fields before creating Expense model', () {
      const raw = 'INDIAN OIL\nPETROL\nTOTAL: 1500';
      final ocr = parser.parse(raw);

      // Simulates user editing amount from 1500 to 1450 and adding custom note
      final userModifiedExpense = Expense(
        merchant: ocr.merchantName ?? 'Unknown Station',
        category: ocr.category ?? ExpenseCategory.transport,
        amount: 1450.0, // User adjusted
        date: ocr.date ?? DateTime(2026, 9, 28),
        notes: 'Adjusted by user after bill scan',
      );

      expect(userModifiedExpense.amount, 1450.0);
      expect(userModifiedExpense.merchant, 'Indian Oil');
      expect(userModifiedExpense.category, ExpenseCategory.transport);
      expect(userModifiedExpense.notes, 'Adjusted by user after bill scan');
    });

    // -------------------------------------------------------------------------
    // 11. Confirmed OCR Expense Uses Existing Expense API
    // -------------------------------------------------------------------------
    test('11. Confirmed OCR expense saves via existing ExpenseRepository', () async {
      final ocr = parser.parse('MORE SUPERMARKET\nGROCERIES\nTOTAL: 650.00\nDATE: 28/09/2026');

      final expense = Expense(
        merchant: ocr.merchantName!,
        category: ocr.category!,
        amount: ocr.totalAmount!,
        date: ocr.date!,
        notes: 'Scanned from receipt',
      );

      final initialCount = ExpenseRepository.instance.getExpenses().length;
      final savedExpense = await ExpenseRepository.instance.addExpense(expense);

      expect(ExpenseRepository.instance.getExpenses().length, initialCount + 1);
      final saved = ExpenseRepository.instance.getById(savedExpense.id);
      expect(saved, isNotNull);
      expect(saved!.merchant, 'More Supermarket');
      expect(saved.amount, 650.0);
      expect(saved.category, ExpenseCategory.food);
    });

    // -------------------------------------------------------------------------
    // 12. OCR-Generated Expense Appears in Normal Expense List
    // -------------------------------------------------------------------------
    test('12. OCR-generated expense appears seamlessly in normal expense list', () async {
      final expense = Expense(
        merchant: 'Zara Fashion',
        category: ExpenseCategory.shopping,
        amount: 2490.0,
        date: DateTime.now(),
        notes: 'Scanned bill',
      );

      final created = await ExpenseRepository.instance.addExpense(expense);
      final allExpenses = ExpenseRepository.instance.getExpenses();

      expect(allExpenses.any((e) => e.id == created.id), isTrue);
      expect(allExpenses.firstWhere((e) => e.id == created.id).amount, 2490.0);
    });

    // -------------------------------------------------------------------------
    // 13. OCR-Generated Expense Affects Monthly Summary
    // -------------------------------------------------------------------------
    test('13. OCR-generated expense updates monthly spending calculation', () async {
      final now = DateTime.now();
      final beforeSpending = ExpenseRepository.instance.getTotalForMonth(now.year, now.month);

      final ocrExpense = Expense(
        merchant: 'Croma Electronics',
        category: ExpenseCategory.shopping,
        amount: 3200.0,
        date: now,
        notes: 'New mouse & keyboard',
      );

      await ExpenseRepository.instance.addExpense(ocrExpense);
      final afterSpending = ExpenseRepository.instance.getTotalForMonth(now.year, now.month);

      expect(afterSpending, beforeSpending + 3200.0);
    });
  });
}
