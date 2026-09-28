import 'package:flutter/material.dart';

/// Centralized corner radius constants for Second Brain.
/// Restrained, refined rounding rather than soft AI dashboard shapes.
abstract final class AppRadius {
  static const double small = 6.0;
  static const double medium = 10.0;
  static const double large = 14.0;

  static const BorderRadius smallBorderRadius = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumBorderRadius = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeBorderRadius = BorderRadius.all(Radius.circular(large));
}
