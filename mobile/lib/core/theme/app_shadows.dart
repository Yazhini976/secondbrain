import 'package:flutter/material.dart';

/// Centralized restrained shadow system for Second Brain.
/// Subtle and grounded — no large floating or glowing shadows.
abstract final class AppShadows {
  /// Subtle card elevation shadow
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x08000000), // 3% opacity black
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Grounded bottom navigation elevation shadow
  static const List<BoxShadow> navigation = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 6,
      offset: Offset(0, -2),
    ),
  ];
}
