import 'package:second_brain/features/expenses/models/expense.dart';
import 'package:second_brain/features/expenses/ocr/receipt_ocr_result.dart';

/// Pure, deterministic receipt text parser.
/// Parses raw OCR text into structured [ReceiptOcrResult] fields:
/// - Merchant name
/// - Total amount (handles ₹, Rs., Rs, INR, decimals, total indicator lines)
/// - Date (normalized to DateTime without inventing dates)
/// - Category (mapped directly to existing ExpenseCategory enum)
/// - Line items
class ReceiptParser {
  const ReceiptParser();

  /// Parses the raw OCR text into a [ReceiptOcrResult].
  ReceiptOcrResult parse(String rawText, {double? confidence}) {
    if (rawText.trim().isEmpty) {
      return ReceiptOcrResult(rawText: rawText, confidence: confidence);
    }

    final rawLines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final totalAmount = _extractTotalAmount(rawLines);
    final date = _extractDate(rawLines);
    final merchantName = _extractMerchantName(rawLines);
    final category = _detectCategory(merchantName, rawText);
    final lineItems = _extractLineItems(rawLines, totalAmount);

    return ReceiptOcrResult(
      merchantName: merchantName,
      totalAmount: totalAmount,
      date: date,
      category: category,
      currency: 'INR',
      rawText: rawText,
      confidence: confidence,
      detectedItems: lineItems,
    );
  }

  // ===========================================================================
  // 1. AMOUNT EXTRACTION
  // ===========================================================================

  static final RegExp _totalKeywordRegex = RegExp(
    r'(?:grand\s*total|net\s*total|net\s*amount|amount\s*payable|amount\s*due|total\s*amount|bill\s*amount|final\s*total|total\s*pay|total\s*inr|balance\s*due|paid\s*amount|sub\s*total|\btotal\b)',
    caseSensitive: false,
  );

  static final RegExp _amountRegex = RegExp(
    r'(?:₹|rs\.?|inr)?\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})|[0-9]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _taxOrMetaRegex = RegExp(
    r'(?:gst|cgst|sgst|igst|vat|tax|discount|round\s*off|change|cash\s*tendered|cash|invoice|bill\s*no|order\s*no|phone|tel|mob)',
    caseSensitive: false,
  );

  double? _extractTotalAmount(List<String> lines) {
    // Strategy 1: Check lines that contain explicit total keywords from bottom up
    // (Receipt totals are predominantly near the bottom)
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];

      if (_totalKeywordRegex.hasMatch(line)) {
        // Skip tax lines like "TOTAL TAX" or "TOTAL GST" or "TOTAL DISCOUNT"
        if (RegExp(r'total\s*(?:tax|gst|cgst|sgst|discount|savings)', caseSensitive: false).hasMatch(line)) {
          continue;
        }

        final amount = _findAmountInLineOrNeighbor(lines, i);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }

    // Strategy 2: Look for lines with currency symbols (₹, Rs., INR)
    final currencyLines = <double>[];
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      if (RegExp(r'(?:₹|rs\.?|inr)', caseSensitive: false).hasMatch(line) &&
          !_isPhoneNumberOrGst(line)) {
        final amount = _parseAmountString(line);
        if (amount != null && amount > 0) {
          currencyLines.add(amount);
        }
      }
    }
    if (currencyLines.isNotEmpty) {
      // Return the maximum currency-denominated amount found
      currencyLines.sort();
      return currencyLines.last;
    }

    // Strategy 3: Plausible isolated total in bottom third of the receipt
    final startIndex = (lines.length * 0.6).floor();
    for (int i = lines.length - 1; i >= startIndex; i--) {
      final line = lines[i];
      if (_isPhoneNumberOrGst(line) || _isDateString(line)) continue;

      final amount = _parseAmountString(line);
      if (amount != null && amount > 0 && amount < 1000000) {
        return amount;
      }
    }

    return null;
  }

  double? _findAmountInLineOrNeighbor(List<String> lines, int index) {
    final line = lines[index];
    final match = _parseAmountString(line);
    if (match != null) return match;

    // Check next line (frequently formatted as "TOTAL" on one line and "1,248.50" on next)
    if (index + 1 < lines.length) {
      final nextMatch = _parseAmountString(lines[index + 1]);
      if (nextMatch != null) return nextMatch;
    }

    // Check previous line
    if (index - 1 >= 0) {
      final prevMatch = _parseAmountString(lines[index - 1]);
      if (prevMatch != null) return prevMatch;
    }

    return null;
  }

  double? _parseAmountString(String text) {
    // Exclude phone numbers, dates, GSTIN, and date/time metadata lines
    if (_isPhoneNumberOrGst(text) || _isDateString(text)) return null;
    if (RegExp(r'\b(?:date|dt|time|ph|tel|mob)\b', caseSensitive: false).hasMatch(text)) return null;

    final matches = _amountRegex.allMatches(text);
    if (matches.isEmpty) return null;

    // Pick the last valid number in the matched segment (common in: "TOTAL 2 1250.00")
    for (final match in matches.toList().reversed) {
      final rawNum = match.group(1);
      if (rawNum == null) continue;

      // Clean commas
      final cleaned = rawNum.replaceAll(',', '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null && parsed > 0) {
        // Disqualify numbers that look like pin codes (e.g., 600028) or years (e.g., 2026)
        if (parsed >= 1990 && parsed <= 2040 && !rawNum.contains('.')) {
          continue;
        }
        if (parsed >= 100000 && parsed <= 999999 && !rawNum.contains('.')) {
          continue;
        }
        return parsed;
      }
    }
    return null;
  }

  bool _isPhoneNumberOrGst(String text) {
    // 10-digit Indian phone numbers
    if (RegExp(r'\b[6-9][0-9]{9}\b').hasMatch(text)) return true;
    // GSTIN format (e.g. 33AAAAA0000A1Z5)
    if (RegExp(r'\b[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}\b', caseSensitive: false).hasMatch(text)) {
      return true;
    }
    return false;
  }

  bool _isDateString(String text) {
    return RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b').hasMatch(text);
  }

  // ===========================================================================
  // 2. DATE EXTRACTION
  // ===========================================================================

  static final List<RegExp> _datePatterns = [
    // DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    RegExp(r'\b([0-3]?[0-9])[/\-\.]([0-1]?[0-9])[/\-\.]((?:20|19)?[0-9]{2})\b'),
    // YYYY-MM-DD or YYYY/MM/DD
    RegExp(r'\b((?:20|19)[0-9]{2})[/\-\.]([0-1]?[0-9])[/\-\.]([0-3]?[0-9])\b'),
    // DD MMM YYYY (e.g. 28 Sep 2026, 28-Sep-2026)
    RegExp(r'\b([0-3]?[0-9])[\s\-\.](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s\-\.]((?:20|19)?[0-9]{2})\b', caseSensitive: false),
  ];

  DateTime? _extractDate(List<String> lines) {
    for (final line in lines) {
      // 1. DD/MM/YYYY or DD-MM-YYYY
      final match1 = _datePatterns[0].firstMatch(line);
      if (match1 != null) {
        final d = int.tryParse(match1.group(1)!);
        final m = int.tryParse(match1.group(2)!);
        var y = int.tryParse(match1.group(3)!);
        if (d != null && m != null && y != null) {
          if (y < 100) y += 2000;
          if (_isValidDate(y, m, d)) {
            return DateTime(y, m, d);
          }
        }
      }

      // 2. YYYY-MM-DD
      final match2 = _datePatterns[1].firstMatch(line);
      if (match2 != null) {
        final y = int.tryParse(match2.group(1)!);
        final m = int.tryParse(match2.group(2)!);
        final d = int.tryParse(match2.group(3)!);
        if (d != null && m != null && y != null && _isValidDate(y, m, d)) {
          return DateTime(y, m, d);
        }
      }

      // 3. DD MMM YYYY
      final match3 = _datePatterns[2].firstMatch(line);
      if (match3 != null) {
        final d = int.tryParse(match3.group(1)!);
        final mStr = match3.group(2)!.toLowerCase();
        var y = int.tryParse(match3.group(3)!);
        final m = _monthNameToNumber(mStr);
        if (d != null && m != null && y != null) {
          if (y < 100) y += 2000;
          if (_isValidDate(y, m, d)) {
            return DateTime(y, m, d);
          }
        }
      }
    }
    return null;
  }

  bool _isValidDate(int y, int m, int d) {
    if (y < 2000 || y > 2035) return false;
    if (m < 1 || m > 12) return false;
    if (d < 1 || d > 31) return false;
    return true;
  }

  int? _monthNameToNumber(String month) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
      'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
      'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[month.substring(0, 3)];
  }

  // ===========================================================================
  // 3. MERCHANT EXTRACTION
  // ===========================================================================

  static final RegExp _nonMerchantHeaderRegex = RegExp(
    r'^(?:tax\s*invoice|retail\s*invoice|cash\s*memo|bill\s*of\s*supply|invoice|receipt|cash\s*receipt|welcome|thank\s*you|gstin|gst\s*no|phone|mobile|tel|date|time|cin|pan|fssai|order|table|counter|token|pos|terminal|original|duplicate|copy)\b',
    caseSensitive: false,
  );

  String? _extractMerchantName(List<String> lines) {
    // Upper section of receipt (top 6 lines)
    final searchLines = lines.take(7).toList();

    for (final rawLine in searchLines) {
      final line = rawLine.replaceAll(RegExp(r'^[#*_\-~|]+\s*'), '').trim();

      // Skip non-merchant lines
      if (line.isEmpty) continue;
      if (line.length < 3) continue;
      if (_nonMerchantHeaderRegex.hasMatch(line)) continue;
      if (_isPhoneNumberOrGst(line)) continue;
      if (_isDateString(line)) continue;

      // Skip addresses or common place names
      if (RegExp(r'\b(?:road|street|nagar|floor|block|phase|complex|pincode|pin|chennai|bangalore|bengaluru|hyderabad|mumbai|delhi|india)\b', caseSensitive: false).hasMatch(line) &&
          !_hasKnownBrand(line)) {
        continue;
      }

      // Check for known brand
      final knownBrand = _getKnownBrandName(line);
      if (knownBrand != null) {
        return knownBrand;
      }

      // Clean up punctuation and return top candidate
      final cleaned = line.replaceAll(RegExp(r'[:;,]+$'), '').trim();
      if (cleaned.length >= 3 && RegExp(r'[a-zA-Z]').hasMatch(cleaned)) {
        return cleaned;
      }
    }

    return null;
  }

  static const List<String> _knownBrands = [
    'Reliance Smart', 'Reliance Fresh', 'Reliance Digital', 'D-Mart', 'DMart',
    'More Supermarket', 'More Retail', 'BigBasket', 'Blinkit', 'Zepto',
    'Swiggy', 'Zomato', 'McDonald\'s', 'KFC', 'Domino\'s', 'Subway', 'Starbucks',
    'Cafe Coffee Day', 'Chai Point', 'Apollo Pharmacy', 'MedPlus', 'Netmeds',
    'Indian Oil', 'Bharat Petroleum', 'Hindustan Petroleum', 'Shell',
    'Uber', 'Ola', 'Rapido', 'Croma', 'Vijay Sales', 'Decathlon',
    'Trends', 'Pantaloons', 'Westside', 'Zudio', 'Max Fashion', 'Zara', 'H&M',
    'Airtel', 'Jio', 'Vodafone Idea', 'Bescom', 'TNEB',
  ];

  bool _hasKnownBrand(String text) {
    final lower = text.toLowerCase();
    return _knownBrands.any((b) => lower.contains(b.toLowerCase()));
  }

  String? _getKnownBrandName(String text) {
    final lower = text.toLowerCase();
    for (final brand in _knownBrands) {
      if (lower.contains(brand.toLowerCase())) {
        return brand;
      }
    }
    return null;
  }

  // ===========================================================================
  // 4. CATEGORY DETECTION
  // ===========================================================================

  ExpenseCategory _detectCategory(String? merchant, String rawText) {
    final combined = '${merchant ?? ''} $rawText'.toLowerCase();

    // 1. Food & Dining
    if (RegExp(r'\b(?:restaurant|cafe|coffee|tea|dining|kitchen|bakery|hotel|bistro|pizza|burger|mcdonald|kfc|domino|subway|starbucks|chai|food|swiggy|zomato|supermarket|hypermarket|groceries|grocery|mart|provision|vegetable|fruit|milk|dairy|dmart|reliance\s*fresh|reliance\s*smart|more\s*retail|bigbasket|blinkit|zepto|instamart|spencer)\b').hasMatch(combined)) {
      return ExpenseCategory.food;
    }

    // 2. Transport
    if (RegExp(r'\b(?:fuel|petrol|diesel|cng|gas\s*station|indian\s*oil|iocl|bharat\s*petroleum|bpcl|hpcl|hindustan\s*petroleum|shell|uber|ola|rapido|taxi|cab|auto|railway|irctc|flight|indigo|air\s*india|spicejet|toll|fastag|parking|metro)\b').hasMatch(combined)) {
      return ExpenseCategory.transport;
    }

    // 3. Shopping
    if (RegExp(r'\b(?:shopping|apparel|clothing|garment|fashion|textile|mall|lifestyle|trends|zara|h&m|max\s*fashion|pantaloons|westside|zudio|electronics|croma|vijay\s*sales|reliance\s*digital|poorvika|sangeetha|amazon|flipkart|myntra|ajio|footwear|shoes|bata|decathlon)\b').hasMatch(combined)) {
      return ExpenseCategory.shopping;
    }

    // 4. Bills & Utilities
    if (RegExp(r'\b(?:electricity|power|bescom|tneb|cesc|discom|water|broadband|wifi|internet|airtel|jio|vodafone|bsnl|recharge|mobile\s*bill|cylinder|indane|bharat\s*gas|hp\s*gas|piped\s*gas|utility|maintenance|postpaid)\b').hasMatch(combined)) {
      return ExpenseCategory.bills;
    }

    return ExpenseCategory.other;
  }

  // ===========================================================================
  // 5. LINE ITEM EXTRACTION (OPTIONAL)
  // ===========================================================================

  List<ReceiptLineItem> _extractLineItems(List<String> lines, double? totalAmount) {
    final items = <ReceiptLineItem>[];
    final itemPattern = RegExp(r'^([A-Za-z0-9\s\.\-&]{3,25})\s+(?:₹|rs\.?|inr)?\s*([0-9]+(?:\.[0-9]{1,2})?)$');

    for (final line in lines) {
      if (_totalKeywordRegex.hasMatch(line)) continue;
      if (_taxOrMetaRegex.hasMatch(line)) continue;

      final match = itemPattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)!.trim();
        final price = double.tryParse(match.group(2)!);
        if (price != null && price > 0) {
          // If totalAmount is known, items must not exceed or equal the total
          if (totalAmount != null && price >= totalAmount) continue;
          items.add(ReceiptLineItem(name: name, price: price));
        }
      }
    }
    return items;
  }
}
