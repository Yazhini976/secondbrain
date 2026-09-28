import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/features/expenses/models/expense.dart';
import 'package:second_brain/features/expenses/data/expense_repository.dart';
import 'package:second_brain/features/expenses/ocr/receipt_ocr_result.dart';
import 'package:second_brain/features/expenses/ocr/receipt_ocr_service.dart';
import 'package:second_brain/features/expenses/ocr/scan_receipt_sheet.dart';

class AddExpenseScreen extends StatefulWidget {
  /// Pass an existing expense to enter edit mode.
  final Expense? existing;
  final ReceiptOcrService? ocrService;
  final ReceiptOcrResult? initialOcrResult;

  const AddExpenseScreen({
    super.key,
    this.existing,
    this.ocrService,
    this.initialOcrResult,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _notesController;
  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  late final ReceiptOcrService _ocrService;
  bool _isSaving = false;
  bool _isScanning = false;
  String? _ocrBannerMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _ocrService = widget.ocrService ?? ReceiptOcrService();

    final e = widget.existing;
    _amountController = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(0) : '',
    );
    _merchantController = TextEditingController(text: e?.merchant ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _selectedCategory = e?.category ?? ExpenseCategory.other;
    _selectedDate = e?.date ?? DateTime.now();

    if (widget.initialOcrResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyOcrResult(widget.initialOcrResult!);
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    final source = await ScanReceiptSheet.show(context);
    if (source == null) return;

    final file = source == ImageSource.camera
        ? await _ocrService.captureReceiptCamera()
        : await _ocrService.pickReceiptGallery();

    if (file == null) return;

    setState(() {
      _isScanning = true;
      _ocrBannerMessage = null;
    });

    try {
      final result = await _ocrService.processReceipt(file.path);
      if (mounted) {
        _applyOcrResult(result);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read the bill. Please enter details manually.'),
            backgroundColor: AppColors.negativeRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _applyOcrResult(ReceiptOcrResult result) {
    if (!result.hasAnyExtractedField) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No readable text was found on this bill. Please enter details manually.'),
          backgroundColor: AppColors.darkBlue,
        ),
      );
      return;
    }

    if (result.totalAmount != null) {
      final amt = result.totalAmount!;
      _amountController.text =
          amt % 1 == 0 ? amt.toStringAsFixed(0) : amt.toStringAsFixed(2);
    }

    if (result.merchantName != null && result.merchantName!.trim().isNotEmpty) {
      _merchantController.text = result.merchantName!.trim();
    }

    if (result.category != null) {
      _selectedCategory = result.category!;
    }

    if (result.date != null) {
      _selectedDate = result.date!;
    }

    if (_notesController.text.trim().isEmpty) {
      final buffer = StringBuffer('Scanned from receipt');
      if (result.detectedItems.isNotEmpty) {
        buffer.write(': ');
        buffer.write(result.detectedItems.map((i) => i.name).join(', '));
      }
      _notesController.text = buffer.toString();
    }

    final missing = <String>[];
    if (result.totalAmount == null) missing.add('total amount');
    if (result.merchantName == null) missing.add('merchant');
    if (result.date == null) missing.add('date');

    String feedback;
    if (missing.isEmpty) {
      feedback = 'Bill details extracted! Please review and edit before saving.';
    } else {
      feedback = "Extracted bill details. Couldn't detect ${missing.join(', ')} — please enter manually.";
    }

    setState(() {
      _ocrBannerMessage = feedback;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feedback),
        backgroundColor: AppColors.darkBlue,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final amount = double.parse(_amountController.text);
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    try {
      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          amount: amount,
          merchant: _merchantController.text.trim(),
          category: _selectedCategory,
          date: _selectedDate,
          notes: notes,
        );
        await ExpenseRepository.instance.updateExpense(updated);
      } else {
        final expense = Expense(
          amount: amount,
          merchant: _merchantController.text.trim(),
          category: _selectedCategory,
          date: _selectedDate,
          notes: notes,
        );
        await ExpenseRepository.instance.addExpense(expense);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final message = e.toString().replaceAll('ApiException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.document_scanner_outlined, color: AppColors.darkBlue),
              tooltip: 'Scan Bill',
              onPressed: _isSaving || _isScanning ? null : _startScan,
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEditing) ...[
                // Scan Bill Card
                InkWell(
                  onTap: _isSaving || _isScanning ? null : _startScan,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: AppSpacing.space12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightBlue,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(
                        color: AppColors.primaryBrightBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.small),
                          ),
                          child: const Icon(
                            Icons.document_scanner_outlined,
                            color: AppColors.darkBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Scan Bill or Receipt',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Auto-fills merchant, amount, category & date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.mutedText,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space20),
              ],
              if (_isScanning) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkBlue),
                        ),
                      ),
                      SizedBox(width: AppSpacing.space12),
                      Text(
                        'Reading your bill...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space20),
              ],
              if (_ocrBannerMessage != null && !_isScanning) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(
                      color: AppColors.successGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.successGreen,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.space8),
                      Expanded(
                        child: Text(
                          _ocrBannerMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space20),
              ],
              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter an amount';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  if (double.parse(value) <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space16),

              // Merchant
              TextFormField(
                controller: _merchantController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Merchant / Payee',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a merchant name' : null,
              ),
              const SizedBox(height: AppSpacing.space16),

              // Category
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _selectedCategory,
                items: ExpenseCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Icon(c.icon, size: 18, color: AppColors.secondaryText),
                              const SizedBox(width: 8),
                              Text(c.displayName),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (c) =>
                    setState(() => _selectedCategory = c ?? ExpenseCategory.other),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Date
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  child: Text(
                    DateFormat('d MMM, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.space32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_isEditing ? 'Save Changes' : 'Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
