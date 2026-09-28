import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/financial_goals/data/financial_repository.dart';
import 'package:second_brain/features/financial_goals/models/financial_goal.dart';

class AddGoalScreen extends StatefulWidget {
  final FinancialGoal? existingGoal;

  const AddGoalScreen({super.key, this.existingGoal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _currentController;
  late TextEditingController _contributionController;

  late FinancialGoalCategory _category;
  late FinancialGoalPriority _priority;
  late DateTime _deadline;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.existingGoal;
    _nameController = TextEditingController(text: g?.name ?? '');
    _targetController = TextEditingController(text: g != null ? g.targetAmount.toStringAsFixed(0) : '');
    _currentController = TextEditingController(text: g != null ? g.currentAmount.toStringAsFixed(0) : '0');
    _contributionController = TextEditingController(text: g != null ? g.monthlyContribution.toStringAsFixed(0) : '0');

    _category = g?.category ?? FinancialGoalCategory.emergencyFund;
    _priority = g?.priority ?? FinancialGoalPriority.medium;
    _deadline = g?.deadline ?? DateTime.now().add(const Duration(days: 365 * 3));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    _contributionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final targetVal = double.parse(_targetController.text.trim());
    final currentVal = double.parse(_currentController.text.trim());
    final contribVal = double.parse(_contributionController.text.trim());

    final goal = FinancialGoal(
      id: widget.existingGoal?.id,
      name: _nameController.text.trim(),
      category: _category,
      targetAmount: targetVal,
      currentAmount: currentVal,
      monthlyContribution: contribVal,
      deadline: _deadline,
      priority: _priority,
    );

    if (widget.existingGoal == null) {
      await FinancialRepository.instance.addGoal(goal);
    } else {
      await FinancialRepository.instance.updateGoal(goal);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingGoal != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Financial Goal' : 'Add Financial Goal'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    hintText: 'e.g. Home Downpayment, Emergency Fund',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter goal name' : null,
                ),
                const SizedBox(height: AppSpacing.space16),

                DropdownButtonFormField<FinancialGoalCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: FinancialGoalCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 18, color: AppColors.darkBlue),
                          const SizedBox(width: AppSpacing.space8),
                          Text(cat.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: AppSpacing.space16),

                TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (₹)',
                    hintText: 'e.g. 3000000',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter target amount';
                    if (double.tryParse(val.trim()) == null) return 'Enter valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _currentController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Current Saved (₹)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: TextFormField(
                        controller: _contributionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Contribution (₹)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space16),

                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Target Deadline',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      '${_deadline.year}-${_deadline.month.toString().padLeft(2, '0')}-${_deadline.day.toString().padLeft(2, '0')}',
                      style: AppTextStyles.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                DropdownButtonFormField<FinancialGoalPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: FinancialGoalPriority.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _priority = val);
                  },
                ),
                const SizedBox(height: AppSpacing.space24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mediumBorderRadius,
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveGoal,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isEdit ? 'Update Goal' : 'Save Goal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
