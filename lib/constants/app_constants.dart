import 'package:flutter/material.dart';

/// Centralized constants to avoid magic numbers throughout the app.
class AppConstants {
  AppConstants._();

  static const String appTitle = 'Kids Number Tracing';

  static const int minNumber = 1;
  static const int maxNumber = 20;

  /// Total count of available numbers (inclusive of min and max).
  static const int totalNumbers = maxNumber - minNumber + 1;

  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration successAdvanceDuration = Duration(milliseconds: 1500);

  /// Minimum tracing coverage (0.0–1.0) required to mark a number as complete.
  static const double tracingSuccessThreshold = 0.80;

  /// Stroke width for the outlined number.
  static const double numberOutlineStrokeWidth = 10.0;

  /// The number should occupy most of the available area. Increased by 40%.
  static const double numberOutlineScale = 0.952; // 0.68 * 1.4

  /// Distance (in logical pixels) within which a stroke counts as covering an interior mask point.
  static const double tracingMaskHitRadius = 18.0;

  /// Number of sampled points used to build the tracing mask inside the number shape.
  static const int tracingMaskPointCount = 420;

  /// Pixel step used when sampling the interior of the number mask.
  static const int tracingMaskSampleStep = 8;

  /// Minimum stroke length ratio required inside the number shape.
  static const double tracingMinimumStrokeLengthRatio = 0.36;

  static const double sectionTopRatio = 0.25;
  static const double sectionMiddleRatio = 0.45;
  static const double sectionBottomRatio = 0.30;

  static const double minTouchTarget = 56.0;
  static const double buttonBorderRadius = 20.0;
  static const double cardBorderRadius = 24.0;

  static const String successSoundPath = 'sounds/success.mp3';

  // Child-friendly bright palette
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFFFF6B9D);
  static const Color accentColor = Color(0xFFFFD93D);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFFFF8E7);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color guideDotColor = Color(0xFF90A4AE);
  static const Color traceStrokeColor = Color(0xFF6C63FF);

  static const List<Color> celebrationColors = [
    Color(0xFFFF6B9D),
    Color(0xFF6C63FF),
    Color(0xFFFFD93D),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF00BCD4),
  ];
}
