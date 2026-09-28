import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/features/documents/logic/document_status.dart';
import 'package:second_brain/features/documents/models/document.dart';

/// Compact, polished list row for a single document.
class DocumentListItem extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;

  const DocumentListItem({
    super.key,
    required this.document,
    this.onTap,
  });

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final status = deriveDocumentStatus(expiryDate: document.expiryDate);

    final attachmentDetails = [
      if (document.fileType != null && document.fileType!.isNotEmpty)
        document.fileType!,
      if (document.fileSize != null) _formatFileSize(document.fileSize),
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space12,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.veryLightBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    document.category.icon,
                    size: 18,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            document.category.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          if (attachmentDetails.isNotEmpty) ...[
                            const Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                attachmentDetails,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (document.expiryDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _expiryLabel(status, document.expiryDate!),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _expiryTextColor(status),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(status: status),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.mutedText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _expiryLabel(DocumentStatus status, DateTime expiry) {
    final formatted = DateFormat('d MMM yyyy').format(expiry);
    return status == DocumentStatus.expired
        ? 'Expired $formatted'
        : 'Expires $formatted';
  }

  Color _expiryTextColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.expired:
        return AppColors.negativeRed;
      case DocumentStatus.expiringSoon:
        return AppColors.warningOrange;
      case DocumentStatus.active:
        return AppColors.mutedText;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final DocumentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
