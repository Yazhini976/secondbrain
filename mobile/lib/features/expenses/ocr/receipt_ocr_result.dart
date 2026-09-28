import 'package:intl/intl.dart';
import 'package:second_brain/features/expenses/models/expense.dart';

/// Single item detected on a receipt (e.g., Rice, Milk, Soap).
class ReceiptLineItem {
  final String name;
  final double price;
  final int? quantity;

  const ReceiptLineItem({
    required this.name,
    required this.price,
    this.quantity,
  });

  @override
  String toString() => '$name: ₹${price.toStringAsFixed(2)}';
}

/// Structured result produced by the on-device receipt OCR pipeline.
/// Assumes all extracted business fields except [rawText] are nullable.
class ReceiptOcrResult {
  final String? merchantName;
  final double? totalAmount;
  final DateTime? date;
  final ExpenseCategory? category;
  final String currency;
  final String rawText;
  final double? confidence;
  final List<ReceiptLineItem> detectedItems;

  const ReceiptOcrResult({
    this.merchantName,
    this.totalAmount,
    this.date,
    this.category,
    this.currency = 'INR',
    required this.rawText,
    this.confidence,
    this.detectedItems = const [],
  });

  /// True if at least one meaningful business field was extracted.
  bool get hasAnyExtractedField =>
      merchantName != null || totalAmount != null || date != null || category != null;

  /// Human-readable amount formatted with Indian currency symbol.
  String? get formattedAmount {
    if (totalAmount == null) return null;
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currency == 'INR' ? '₹' : '$currency ',
      decimalDigits: totalAmount! % 1 == 0 ? 0 : 2,
    );
    return formatter.format(totalAmount);
  }

  /// Formatted date string in 'dd/MM/yyyy' format.
  String? get formattedDate {
    if (date == null) return null;
    return DateFormat('dd/MM/yyyy').format(date!);
  }

  ReceiptOcrResult copyWith({
    String? merchantName,
    double? totalAmount,
    DateTime? date,
    ExpenseCategory? category,
    String? currency,
    String? rawText,
    double? confidence,
    List<ReceiptLineItem>? detectedItems,
  }) {
    return ReceiptOcrResult(
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
      detectedItems: detectedItems ?? this.detectedItems,
    );
  }

  @override
  String toString() {
    return 'ReceiptOcrResult(merchant: $merchantName, amount: $totalAmount, date: $formattedDate, category: ${category?.displayName})';
  }
}
