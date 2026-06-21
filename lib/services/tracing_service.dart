import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kids_tracing_app/constants/app_constants.dart';

/// Result of tracing progress for an interior mask.
class TracingResult {
  TracingResult({
    required this.coverage,
    required this.matchedMask,
    required this.insideStrokeLength,
    required this.totalStrokePoints,
    required this.matchedStrokePoints,
  });

  final double coverage;
  final List<bool> matchedMask;
  final double insideStrokeLength;
  final int totalStrokePoints;
  final int matchedStrokePoints;

  bool get hasAnyMatch => matchedMask.any((value) => value);
}

/// Handles tracing validation logic based on interior mask points.
class TracingService {
  TracingResult calculateProgress({
    required List<Offset> maskPoints,
    required List<List<Offset>> strokes,
  }) {
    final matchedMask = List<bool>.filled(maskPoints.length, false);
    final radius = AppConstants.tracingMaskHitRadius;
    final radiusSquared = radius * radius;
    int totalStrokePoints = 0;
    int matchedStrokePoints = 0;
    double insideStrokeLength = 0;

    for (final stroke in strokes) {
      if (stroke.isEmpty) {
        continue;
      }

      for (final point in stroke) {
        totalStrokePoints++;
        if (_isPointInsideMask(point, maskPoints, radiusSquared)) {
          matchedStrokePoints++;
        }
      }

      for (var index = 1; index < stroke.length; index++) {
        final previous = stroke[index - 1];
        final current = stroke[index];
        final dx = current.dx - previous.dx;
        final dy = current.dy - previous.dy;
        final segmentLength = math.sqrt(dx * dx + dy * dy);

        if (_isPointInsideMask(previous, maskPoints, radiusSquared) ||
            _isPointInsideMask(current, maskPoints, radiusSquared)) {
          insideStrokeLength += segmentLength;
        }
      }
    }

    for (var index = 0; index < maskPoints.length; index++) {
      final maskPoint = maskPoints[index];
      for (final stroke in strokes) {
        if (stroke.any((point) {
          final dx = maskPoint.dx - point.dx;
          final dy = maskPoint.dy - point.dy;
          return (dx * dx) + (dy * dy) <= radiusSquared;
        })) {
          matchedMask[index] = true;
          break;
        }
      }
    }

    final covered = maskPoints.isEmpty
        ? 0
        : matchedMask.where((value) => value).length;

    return TracingResult(
      coverage: maskPoints.isEmpty ? 0 : covered / maskPoints.length,
      matchedMask: matchedMask,
      insideStrokeLength: insideStrokeLength,
      totalStrokePoints: totalStrokePoints,
      matchedStrokePoints: matchedStrokePoints,
    );
  }

  bool isTracingSuccessful({
    required TracingResult progressResult,
    required Rect numberBounds,
  }) {
    if (!progressResult.hasAnyMatch || progressResult.totalStrokePoints == 0) {
      return false;
    }

    if (progressResult.coverage < AppConstants.tracingSuccessThreshold) {
      return false;
    }

    final minStrokeLength =
        (math.min(numberBounds.width, numberBounds.height) *
                AppConstants.tracingMinimumStrokeLengthRatio)
            .clamp(60.0, double.infinity);

    final matchedStrokeRatio = progressResult.totalStrokePoints == 0
        ? 0
        : progressResult.matchedStrokePoints / progressResult.totalStrokePoints;

    return progressResult.insideStrokeLength >= minStrokeLength &&
        matchedStrokeRatio >= 0.1;
  }

  bool _isPointInsideMask(
    Offset point,
    List<Offset> maskPoints,
    double radiusSquared,
  ) {
    for (final maskPoint in maskPoints) {
      final dx = maskPoint.dx - point.dx;
      final dy = maskPoint.dy - point.dy;
      if ((dx * dx) + (dy * dy) <= radiusSquared) {
        return true;
      }
    }
    return false;
  }
}
