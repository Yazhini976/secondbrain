import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/models/document.dart';

/// Screen allowing the user to create and save a new document.
/// Also supports edit mode if an [existing] document is provided.
class AddDocumentScreen extends StatefulWidget {
  final Document? existing;
  final Document? document;
  final bool isEditMode;

  const AddDocumentScreen({
    super.key,
    this.existing,
    this.document,
    this.isEditMode = false,
  });

  Document? get initialDocument => existing ?? document;
  bool get resolvedIsEditMode => isEditMode || initialDocument != null;

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.resolvedIsEditMode;
  Document? get _targetDoc => widget.initialDocument;

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  // Category
  DocumentCategory _selectedCategory = DocumentCategory.identity;

  // Dates
  DateTime? _issueDate;
  DateTime? _expiryDate;
  String? _dateOrderError;

  @override
  void initState() {
    super.initState();
    final doc = _targetDoc;
    if (doc != null) {
      _nameController.text = doc.title;
      _selectedCategory = doc.category;
      if (doc.description != null) _descriptionController.text = doc.description!;
      if (doc.notes != null) _notesController.text = doc.notes!;
      _issueDate = doc.issueDate;
      _expiryDate = doc.expiryDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickIssueDate() async {
    final now = DateTime.now();
    final initialDate = _issueDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        _issueDate = picked;
        _validateDates();
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final initialDate = _expiryDate ?? (_issueDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2060),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _validateDates();
      });
    }
  }

  bool _validateDates() {
    if (_issueDate != null && _expiryDate != null) {
      final issueDay = DateTime(_issueDate!.year, _issueDate!.month, _issueDate!.day);
      final expiryDay = DateTime(_expiryDate!.year, _expiryDate!.month, _expiryDate!.day);

      if (issueDay.isAfter(expiryDay)) {
        setState(() {
          _dateOrderError = 'Issue date cannot be after expiry date.';
        });
        return false;
      }
    }
    setState(() {
      _dateOrderError = null;
    });
    return true;
  }

  void _onAddFileTap() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File attachment will be implemented in the next step.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveDocument() {
    final formValid = _formKey.currentState?.validate() ?? false;
    final datesValid = _validateDates();

    if (!formValid || !datesValid) {
      return;
    }

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      final notes =
          _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      if (_isEditing && _targetDoc != null) {
        final updated = _targetDoc!.copyWith(
          title: name,
          category: _selectedCategory,
          description: description,
          issueDate: _issueDate,
          expiryDate: _expiryDate,
          notes: notes,
        );
        DocumentRepository.instance.updateDocument(updated);
      } else {
        final newDoc = Document(
          id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
          title: name,
          category: _selectedCategory,
          description: description,
          issueDate: _issueDate,
          expiryDate: _expiryDate,
          notes: notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        DocumentRepository.instance.addDocument(newDoc);
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save document: $e'),
          backgroundColor: AppColors.negativeRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Document' : 'Add Document'),
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
              // 1. General Info
              _buildSectionTitle('Document Information'),
              const SizedBox(height: AppSpacing.space12),

              // Document Name
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Document Name *',
                  hintText: 'e.g. Passport, Insurance Policy',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter a document name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space16),

              // Category
              DropdownButtonFormField<DocumentCategory>(
                initialValue: _selectedCategory,
                items: DocumentCategory.values
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon, size: 18, color: AppColors.darkBlue),
                            const SizedBox(width: AppSpacing.space8),
                            Text(cat.displayName),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (cat) {
                  if (cat != null) {
                    setState(() => _selectedCategory = cat);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? 'Select a category.' : null,
              ),
              const SizedBox(height: AppSpacing.space16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Short description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),

              // 2. Dates Section
              _buildSectionTitle('Dates'),
              const SizedBox(height: AppSpacing.space12),

              // Issue Date Picker
              InkWell(
                onTap: _pickIssueDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Issue Date (optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: _issueDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _issueDate = null;
                                _validateDates();
                              });
                            },
                          )
                        : const Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  child: Text(
                    _issueDate != null
                        ? dateFormat.format(_issueDate!)
                        : 'Select issue date',
                    style: TextStyle(
                      fontSize: 15,
                      color: _issueDate != null
                          ? AppColors.darkText
                          : AppColors.mutedText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Expiry Date Picker
              InkWell(
                onTap: _pickExpiryDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiry Date (optional)',
                    border: const OutlineInputBorder(),
                    errorText: _dateOrderError,
                    suffixIcon: _expiryDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _expiryDate = null;
                                _validateDates();
                              });
                            },
                          )
                        : const Icon(Icons.event_available_outlined, size: 18),
                  ),
                  child: Text(
                    _expiryDate != null
                        ? dateFormat.format(_expiryDate!)
                        : 'Select expiry date (or leave empty for no expiry)',
                    style: TextStyle(
                      fontSize: 15,
                      color: _expiryDate != null
                          ? AppColors.darkText
                          : AppColors.mutedText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),

              // 3. Notes Section
              _buildSectionTitle('Additional Details'),
              const SizedBox(height: AppSpacing.space12),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Additional details, physical location, etc.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),

              // 4. File Section
              _buildSectionTitle('Document File'),
              const SizedBox(height: AppSpacing.space12),

              Container(
                padding: const EdgeInsets.all(AppSpacing.space16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.veryLightBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.attach_file,
                        size: 20,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Document File',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'No file attached',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _onAddFileTap,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkBlue,
                        side: const BorderSide(color: AppColors.darkBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space12,
                          vertical: AppSpacing.space8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space32),

              // 5. Save Button
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
                  onPressed: _saveDocument,
                  child: Text(_isEditing ? 'Save Changes' : 'Save Document'),
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
