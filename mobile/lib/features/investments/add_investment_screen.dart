import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/investments/models/investment.dart';

/// Screen allowing the user to create and save a new investment.
class AddInvestmentScreen extends StatefulWidget {
  final Investment? existing;

  const AddInvestmentScreen({super.key, this.existing});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.existing != null;
  bool _isSaving = false;

  // Text Controllers
  final _nameController = TextEditingController();
  final _monthlyContributionController = TextEditingController();
  final _totalPaidController = TextEditingController();
  final _totalInstallmentsController = TextEditingController();
  final _installmentsPaidController = TextEditingController();
  final _notesController = TextEditingController();

  // Investment Category
  InvestmentType _selectedType = InvestmentType.goldSavingScheme;

  // Dates
  DateTime _startDate = DateTime.now();
  late DateTime _nextDueDate;
  DateTime? _maturityDate;

  // Date validation error strings
  String? _nextDueDateError;
  String? _maturityDateError;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e.name;
      _monthlyContributionController.text = e.monthlyContribution.truncateToDouble() == e.monthlyContribution
          ? e.monthlyContribution.toInt().toString()
          : e.monthlyContribution.toString();
      _totalPaidController.text = e.totalPaid.truncateToDouble() == e.totalPaid
          ? e.totalPaid.toInt().toString()
          : e.totalPaid.toString();
      _totalInstallmentsController.text = e.totalInstallments.toString();
      _installmentsPaidController.text = e.installmentsPaid.toString();
      if (e.notes != null) _notesController.text = e.notes!;
      _selectedType = e.type;
      _startDate = e.startDate ?? DateTime.now();
      _nextDueDate = e.nextDueDate ??
          DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
      _maturityDate = e.maturityDate;
    } else {
      // Default next due date to 1 month from start date
      _nextDueDate = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _monthlyContributionController.dispose();
    _totalPaidController.dispose();
    _totalInstallmentsController.dispose();
    _installmentsPaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _validateDates();
      });
    }
  }

  Future<void> _pickNextDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate.isBefore(_startDate) ? _startDate : _nextDueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        _nextDueDate = picked;
        _validateDates();
      });
    }
  }

  Future<void> _pickMaturityDate() async {
    final initial = _maturityDate ??
        DateTime(_startDate.year + 1, _startDate.month, _startDate.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_startDate) ? _startDate : initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2060),
    );
    if (picked != null) {
      setState(() {
        _maturityDate = picked;
        _validateDates();
      });
    }
  }

  bool _validateDates() {
    bool isValid = true;
    final startDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final dueDay =
        DateTime(_nextDueDate.year, _nextDueDate.month, _nextDueDate.day);

    if (dueDay.isBefore(startDay)) {
      _nextDueDateError = 'Next due date cannot be before the start date.';
      isValid = false;
    } else {
      _nextDueDateError = null;
    }

    if (_maturityDate != null) {
      final maturityDay = DateTime(
        _maturityDate!.year,
        _maturityDate!.month,
        _maturityDate!.day,
      );
      if (maturityDay.isBefore(startDay)) {
        _maturityDateError = 'Maturity date cannot be before the start date.';
        isValid = false;
      } else {
        _maturityDateError = null;
      }
    } else {
      _maturityDateError = null;
    }

    return isValid;
  }

  void _onAttachmentTap() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attachments will be available in a later step.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveInvestment() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final datesValid = _validateDates();

    setState(() {});

    if (!formValid || !datesValid || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    final monthlyContribution =
        double.parse(_monthlyContributionController.text.trim());
    final totalPaid = double.parse(_totalPaidController.text.trim());
    final totalInstallments =
        int.parse(_totalInstallmentsController.text.trim());
    final installmentsPaid =
        int.parse(_installmentsPaidController.text.trim());
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    try {
      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          name: _nameController.text.trim(),
          type: _selectedType,
          monthlyContribution: monthlyContribution,
          totalPaid: totalPaid,
          installmentsPaid: installmentsPaid,
          totalInstallments: totalInstallments,
          startDate: _startDate,
          nextDueDate: _nextDueDate,
          maturityDate: _maturityDate,
          notes: notes,
        );
        await InvestmentRepository.instance.updateInvestment(updated);
      } else {
        final investment = Investment(
          name: _nameController.text.trim(),
          type: _selectedType,
          monthlyContribution: monthlyContribution,
          totalPaid: totalPaid,
          installmentsPaid: installmentsPaid,
          totalInstallments: totalInstallments,
          startDate: _startDate,
          nextDueDate: _nextDueDate,
          maturityDate: _maturityDate,
          notes: notes,
        );
        await InvestmentRepository.instance.addInvestment(investment);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final msg = e.toString().replaceAll('ApiException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save investment: $msg'),
            backgroundColor: AppColors.negativeRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Investment' : 'Add Investment'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
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
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.space16),
                  child: LinearProgressIndicator(minHeight: 2),
                ),

              // 1. Investment Details Group
              _buildSectionTitle('Investment Details'),
              const SizedBox(height: AppSpacing.space12),

              // Investment Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Investment Name *',
                  hintText: 'e.g. Gold Saving Scheme',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter an investment name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space16),

              // Investment Type
              DropdownButtonFormField<InvestmentType>(
                initialValue: _selectedType,
                items: InvestmentType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (type) {
                  if (type != null) {
                    setState(() => _selectedType = type);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Investment Type *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),

              // 2. Contribution Group
              _buildSectionTitle('Contribution'),
              const SizedBox(height: AppSpacing.space12),

              // Monthly Contribution
              TextFormField(
                controller: _monthlyContributionController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly Contribution *',
                  hintText: 'e.g. 5000',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter a valid contribution.';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid contribution.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space16),

              // Total Paid
              TextFormField(
                controller: _totalPaidController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Total Paid *',
                  hintText: 'e.g. 35000',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter a valid total paid amount.';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Total paid must be greater than or equal to 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space24),

              // 3. Schedule Group
              _buildSectionTitle('Schedule'),
              const SizedBox(height: AppSpacing.space12),

              // Start Date Picker
              InkWell(
                onTap: _pickStartDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  child: Text(
                    dateFormat.format(_startDate),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Next Due Date Picker
              InkWell(
                onTap: _pickNextDueDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Next Due Date *',
                    border: const OutlineInputBorder(),
                    suffixIcon:
                        const Icon(Icons.event_outlined, size: 18),
                    errorText: _nextDueDateError,
                  ),
                  child: Text(
                    dateFormat.format(_nextDueDate),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Maturity Date Picker (Optional)
              InkWell(
                onTap: _pickMaturityDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Maturity Date (optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: _maturityDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _maturityDate = null;
                                _maturityDateError = null;
                              });
                            },
                          )
                        : const Icon(Icons.event_available_outlined, size: 18),
                    errorText: _maturityDateError,
                  ),
                  child: Text(
                    _maturityDate != null
                        ? dateFormat.format(_maturityDate!)
                        : 'Select date (optional)',
                    style: TextStyle(
                      fontSize: 15,
                      color: _maturityDate != null
                          ? AppColors.darkText
                          : AppColors.mutedText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),

              // 4. Progress Group
              _buildSectionTitle('Progress'),
              const SizedBox(height: AppSpacing.space12),

              // Total Installments
              TextFormField(
                controller: _totalInstallmentsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Installments *',
                  hintText: 'e.g. 12',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter total installments.';
                  }
                  final parsed = int.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Total installments must be greater than 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space16),

              // Installments Paid
              TextFormField(
                controller: _installmentsPaidController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Installments Paid *',
                  hintText: 'e.g. 7',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter installments paid.';
                  }
                  final paid = int.tryParse(v.trim());
                  if (paid == null || paid < 0) {
                    return 'Installments paid must be 0 or greater.';
                  }
                  final total =
                      int.tryParse(_totalInstallmentsController.text.trim());
                  if (total != null && paid > total) {
                    return 'Installments paid cannot exceed total installments.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space24),

              // 5. Additional Group
              _buildSectionTitle('Additional'),
              const SizedBox(height: AppSpacing.space12),

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
              const SizedBox(height: AppSpacing.space16),

              // Attachment Placeholder
              InkWell(
                onTap: _onAttachmentTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space16,
                    vertical: AppSpacing.space12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 20,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Attach Receipt / Document',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.darkText,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Optional document or statement attachment',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.mutedText,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space32),

              // 6. Save Action Button
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
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _saveInvestment,
                  child: Text(_isEditing ? 'Save Changes' : 'Save Investment'),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.sectionTitle.copyWith(
        fontSize: 14,
        color: AppColors.secondaryText,
      ),
    );
  }
}
