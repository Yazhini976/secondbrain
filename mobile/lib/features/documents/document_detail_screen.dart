import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';
import 'package:second_brain/features/documents/add_document_screen.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/logic/document_status.dart';
import 'package:second_brain/features/documents/models/document.dart';
import 'package:second_brain/shared/widgets/app_card.dart';

/// Screen displaying complete details for a specific document,
/// with options to edit and delete.
class DocumentDetailScreen extends StatefulWidget {
  final String documentId;
  final String? documentTitle;
  final DocumentCategory? category;

  const DocumentDetailScreen({
    super.key,
    required this.documentId,
    this.documentTitle,
    this.category,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _hasChanges = false;

  Document? get _document =>
      DocumentRepository.instance.getDocumentById(widget.documentId);

  Future<void> _openEdit(Document doc) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddDocumentScreen(
          document: doc,
          isEditMode: true,
        ),
      ),
    );
    if (result == true) {
      _hasChanges = true;
      setState(() {});
    }
  }

  Future<void> _confirmDelete(Document doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text(
          'Are you sure you want to delete this document?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.negativeRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      DocumentRepository.instance.deleteDocument(doc.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _onAddFile() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File attachment will be implemented in the next step.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final doc = _document;

    if (doc == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Document Details'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Divider(height: 1.0, color: AppColors.border),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: AppColors.mutedText,
                ),
                const SizedBox(height: AppSpacing.space16),
                const Text(
                  'Document not found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(_hasChanges),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkBlue,
                    side: const BorderSide(color: AppColors.darkBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Return to Documents'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final status = deriveDocumentStatus(expiryDate: doc.expiryDate);
    final dateFormat = DateFormat('d MMM yyyy');

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Can handle pop updates if needed
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Document Details'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => _openEdit(doc),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.negativeRed),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(doc),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Divider(height: 1.0, color: AppColors.border),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Document Name, Category, and Derived Status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.veryLightBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      doc.category.icon,
                      size: 22,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc.category.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: AppSpacing.space24),

              // 2. Document Information Card
              _buildSectionTitle('Document Information'),
              const SizedBox(height: AppSpacing.space12),

              AppCard(
                child: Column(
                  children: [
                    _buildInfoRow('Document Name', doc.title),
                    const Divider(height: 20, color: AppColors.border),
                    _buildInfoRow('Category', doc.category.displayName),
                    const Divider(height: 20, color: AppColors.border),
                    _buildInfoRow(
                      'Description',
                      doc.description != null && doc.description!.trim().isNotEmpty
                          ? doc.description!
                          : 'No description',
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _buildInfoRow(
                      'Issue Date',
                      doc.issueDate != null
                          ? dateFormat.format(doc.issueDate!)
                          : 'Not specified',
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _buildExpiryRow(doc, status, dateFormat),
                    const Divider(height: 20, color: AppColors.border),
                    _buildInfoRow(
                      'Notes',
                      doc.notes != null && doc.notes!.trim().isNotEmpty
                          ? doc.notes!
                          : 'No notes',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space24),

              // 3. File Section
              _buildSectionTitle('Document File'),
              const SizedBox(height: AppSpacing.space12),

              AppCard(
                child: doc.fileName != null
                    ? Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.veryLightBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.insert_drive_file_outlined,
                              size: 20,
                              color: AppColors.darkBlue,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.fileName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    if (doc.fileType != null) doc.fileType,
                                    if (doc.fileSize != null)
                                      _formatFileSize(doc.fileSize),
                                  ].join(' · '),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
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
                                  'No file attached yet',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _onAddFile,
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

              // 4. Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _openEdit(doc),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Edit Document',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.negativeRed,
                    side: const BorderSide(color: AppColors.negativeRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _confirmDelete(doc),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text(
                    'Delete Document',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryRow(
    Document doc,
    DocumentStatus status,
    DateFormat dateFormat,
  ) {
    final String expiryText;
    final Color textColor;

    if (doc.expiryDate != null) {
      final formatted = dateFormat.format(doc.expiryDate!);
      switch (status) {
        case DocumentStatus.expired:
          expiryText = 'Expired $formatted';
          textColor = AppColors.negativeRed;
          break;
        case DocumentStatus.expiringSoon:
          expiryText = 'Expires $formatted';
          textColor = AppColors.warningOrange;
          break;
        case DocumentStatus.active:
          expiryText = 'Expires $formatted';
          textColor = AppColors.darkText;
          break;
      }
    } else {
      expiryText = 'No expiry date';
      textColor = AppColors.secondaryText;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 110,
          child: Text(
            'Expiry Date',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: Text(
            expiryText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(DocumentStatus status) {
    final Color bg;
    final Color fg;
    switch (status) {
      case DocumentStatus.active:
        bg = AppColors.lightGreen;
        fg = AppColors.successGreen;
        break;
      case DocumentStatus.expiringSoon:
        bg = AppColors.lightOrange;
        fg = AppColors.warningOrange;
        break;
      case DocumentStatus.expired:
        bg = AppColors.lightRed;
        fg = AppColors.negativeRed;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
