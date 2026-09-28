import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_radius.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';

/// Clean native modal sheet for selecting receipt input source (Camera or Gallery).
class ScanReceiptSheet extends StatelessWidget {
  const ScanReceiptSheet({super.key});

  /// Displays the modal sheet and returns the selected [ImageSource],
  /// or null if dismissed.
  static Future<ImageSource?> show(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      builder: (_) => const ScanReceiptSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space24,
          AppSpacing.space16,
          AppSpacing.space24,
          AppSpacing.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            const Text(
              'Scan Bill / Receipt',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Capture a receipt to automatically extract merchant, amount, date, and category.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.space20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.veryLightBlue,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.darkBlue,
                  size: 22,
                ),
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: const Text(
                'Use camera to capture physical bill',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.successGreen,
                  size: 22,
                ),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: const Text(
                'Select an existing receipt image',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}
