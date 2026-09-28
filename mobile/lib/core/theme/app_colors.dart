import 'package:flutter/material.dart';

/// Centralized color palette for Second Brain.
/// Based on the master visual identity.
abstract final class AppColors {
  // Primary brand blues
  static const Color darkBlue = Color(0xFF214086);
  static const Color primaryBrightBlue = Color(0xFF0052CC);
  static const Color lightBlue = Color(0xFFE8F2FF);
  static const Color veryLightBlue = Color(0xFFECF7FD);

  // Status colors
  static const Color successGreen = Color(0xFF16A34A);
  static const Color lightGreen = Color(0xFFE5F7F1);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color lightOrange = Color(0xFFFBF7F1);
  static const Color negativeRed = Color(0xFFDC2626);
  static const Color lightRed = Color(0xFFFEE2E2);

  // Neutrals
  static const Color darkText = Color(0xFF1F2937);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color mutedText = Color(0xFF9CA3AF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFF1F5F9);
}
