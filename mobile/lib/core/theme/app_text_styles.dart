import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';

/// Centralized typography hierarchy for Second Brain.
/// Professional, clean, and legible without trendy or decorative fonts.
abstract final class AppTextStyles {
  /// Top screen title (e.g., page header)
  static const TextStyle screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.darkText,
    height: 1.25,
  );

  /// Major section header
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.darkText,
    height: 1.3,
  );

  /// Card title
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.darkText,
    height: 1.35,
  );

  /// Primary body text
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.darkText,
    height: 1.45,
  );

  /// Secondary descriptive text
  static const TextStyle secondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    height: 1.4,
  );

  /// Micro copy, tags, or captions
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
    letterSpacing: 0.1,
    height: 1.3,
  );

  /// Button label
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.2,
  );

  /// Bottom navigation label
  static const TextStyle navigation = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.2,
  );
}
