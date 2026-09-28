import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';
import 'package:second_brain/features/reminders/services/notification_service.dart';

/// Screen allowing the user to create a new reminder or edit an existing reminder.
class AddReminderScreen extends StatefulWidget {
  final Reminder? reminder;
  final Reminder? existing;
  final bool isEditMode;

  const AddReminderScreen({
    super.key,
    this.reminder,
    this.existing,
    this.isEditMode = false,
  });

  Reminder? get initialReminder => reminder ?? existing;
  bool get resolvedIsEditMode => isEditMode || initialReminder != null;

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.resolvedIsEditMode;
  Reminder? get _targetReminder => widget.initialReminder;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Selection state
  ReminderCategory _selectedCategory = ReminderCategory.personal;
  ReminderPriority _selectedPriority = ReminderPriority.medium;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String? _dateError;
  String? _timeError;
  String? _pastDateTimeError;

  @override
  void initState() {
    super.initState();
    final rem = _targetReminder;
    if (rem != null) {
      _titleController.text = rem.title;
      _selectedCategory = rem.category;
      _selectedPriority = rem.priority;
      if (rem.description != null) {
        _descriptionController.text = rem.description!;
      }
      _selectedDate = DateTime(
        rem.reminderDateTime.year,
        rem.reminderDateTime.month,
        rem.reminderDateTime.day,
      );
      _selectedTime = TimeOfDay(
        hour: rem.reminderDateTime.hour,
        minute: rem.reminderDateTime.minute,
      );
    } else {
      // Default to 1 hour from now
      final now = DateTime.now();
      final target = now.add(const Duration(hours: 1));
      _selectedDate = DateTime(target.year, target.month, target.day);
      _selectedTime = TimeOfDay(hour: target.hour, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final first = _isEditing
        ? DateTime(2020)
        : DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(2050),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = null;
        _validateDateTime();
      });
    }
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final initial = _selectedTime ?? TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeError = null;
        _validateDateTime();
      });
    }
  }

  bool _validateDateTime() {
    if (_selectedDate == null) {
      _dateError = 'Please select a date';
      return false;
    }
    if (_selectedTime == null) {
      _timeError = 'Please select a time';
      return false;
    }

    final combined = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (!_isEditing && combined.isBefore(DateTime.now())) {
      setState(() {
        _pastDateTimeError = 'Please select a future reminder time.';
      });
      return false;
    } else {
      setState(() {
        _pastDateTimeError = null;
      });
      return true;
    }
  }

  void _onSave() {
    FocusScope.of(context).unfocus();

    final isFormValid = _formKey.currentState?.validate() ?? false;
    final isDateTimeValid = _validateDateTime();

    if (!isFormValid || !isDateTimeValid) {
      return;
    }

    final combinedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    if (!_isEditing) {
      final hasDuplicateAuto = ReminderRepository.instance.getAll().any(
            (r) =>
                r.source != ReminderSource.manual &&
                !r.isCompleted &&
                r.title.toLowerCase().trim() == title.toLowerCase().trim(),
          );
      if (hasDuplicateAuto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An automatic reminder for this item already exists.',
              style: TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.darkBlue,
          ),
        );
        return;
      }
    }

    if (_isEditing && _targetReminder != null) {
      final updated = _targetReminder!.copyWith(
        title: title,
        description: description,
        reminderDateTime: combinedDateTime,
        dueDate: DateTime(
          combinedDateTime.year,
          combinedDateTime.month,
          combinedDateTime.day,
        ),
        category: _selectedCategory,
        priority: _selectedPriority,
        source: _targetReminder!.source,
      );
      ReminderRepository.instance.update(updated);
      // Cancel old notification and reschedule with updated time.
      NotificationService.instance.rescheduleReminder(updated);
    } else {
      final newReminder = Reminder(
        title: title,
        description: description,
        reminderDateTime: combinedDateTime,
        dueDate: DateTime(
          combinedDateTime.year,
          combinedDateTime.month,
          combinedDateTime.day,
        ),
        category: _selectedCategory,
        priority: _selectedPriority,
        isCompleted: false,
        source: ReminderSource.manual,
      );
      ReminderRepository.instance.add(newReminder);
      // Schedule notification if the reminder is in the future.
      NotificationService.instance.scheduleReminder(newReminder);
    }

    Navigator.of(context).pop(true);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _isEditing ? 'Edit Reminder' : 'Add Reminder';
    final buttonText = _isEditing ? 'Save Changes' : 'Save Reminder';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(titleText),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TITLE
                _buildFieldLabel('Reminder Title', isRequired: true),
                const SizedBox(height: AppSpacing.space8),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Renew vehicle insurance',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a reminder title';
                    }
                    if (value.trim().length > 120) {
                      return 'Title must be 120 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space16),

                // 2. CATEGORY
                _buildFieldLabel('Category', isRequired: true),
                const SizedBox(height: AppSpacing.space8),
                _buildCategoryDropdown(),
                const SizedBox(height: AppSpacing.space16),

                // 3. DATE & TIME
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Date', isRequired: true),
                          const SizedBox(height: AppSpacing.space8),
                          _buildDatePickerButton(),
                          if (_dateError != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _dateError!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.negativeRed,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),

                    // Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Time', isRequired: true),
                          const SizedBox(height: AppSpacing.space8),
                          _buildTimePickerButton(),
                          if (_timeError != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _timeError!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.negativeRed,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (_pastDateTimeError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _pastDateTimeError!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.negativeRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space16),

                // 4. PRIORITY
                _buildFieldLabel('Priority', isRequired: false),
                const SizedBox(height: AppSpacing.space8),
                _buildPrioritySelector(),
                const SizedBox(height: AppSpacing.space16),

                // 5. DESCRIPTION
                _buildFieldLabel('Description', isRequired: false),
                const SizedBox(height: AppSpacing.space8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Add details',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),

                // 6. SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mediumBorderRadius,
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: AppTextStyles.button.copyWith(color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
            fontSize: 13,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.negativeRed,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ReminderCategory>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space12,
        ),
      ),
      items: ReminderCategory.values.map((cat) {
        return DropdownMenuItem<ReminderCategory>(
          value: cat,
          child: Row(
            children: [
              Icon(
                cat.icon,
                size: 18,
                color: AppColors.darkBlue,
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                cat.displayName,
                style: AppTextStyles.body,
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (cat) {
        if (cat != null) {
          setState(() {
            _selectedCategory = cat;
          });
        }
      },
    );
  }

  Widget _buildDatePickerButton() {
    final dateStr = _selectedDate == null
        ? 'Select Date'
        : DateFormat('dd MMM yyyy').format(_selectedDate!);

    return InkWell(
      onTap: _pickDate,
      borderRadius: AppRadius.mediumBorderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mediumBorderRadius,
          border: Border.all(
            color: _dateError != null ? AppColors.negativeRed : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.secondaryText,
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: Text(
                dateStr,
                style: AppTextStyles.body.copyWith(
                  color: _selectedDate == null
                      ? AppColors.mutedText
                      : AppColors.darkText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerButton() {
    final timeStr = _selectedTime == null
        ? 'Select Time'
        : _formatTimeOfDay(_selectedTime!);

    return InkWell(
      onTap: _pickTime,
      borderRadius: AppRadius.mediumBorderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mediumBorderRadius,
          border: Border.all(
            color: _timeError != null ? AppColors.negativeRed : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 16,
              color: AppColors.secondaryText,
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: Text(
                timeStr,
                style: AppTextStyles.body.copyWith(
                  color: _selectedTime == null
                      ? AppColors.mutedText
                      : AppColors.darkText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: ReminderPriority.values.map((priority) {
        final isSelected = _selectedPriority == priority;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPriority = priority;
                });
              },
              borderRadius: AppRadius.smallBorderRadius,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? priority.backgroundColor
                      : AppColors.surface,
                  borderRadius: AppRadius.smallBorderRadius,
                  border: Border.all(
                    color: isSelected ? priority.color : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    priority.displayName,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? priority.color
                          : AppColors.secondaryText,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
