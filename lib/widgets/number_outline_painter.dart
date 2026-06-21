import 'package:flutter/material.dart';
import 'package:kids_tracing_app/constants/app_constants.dart';

class NumberOutlinePainter extends CustomPainter {
  NumberOutlinePainter({required this.path, required this.strokeWidth});

  final Path path;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant NumberOutlinePainter oldDelegate) {
    return oldDelegate.path != path || oldDelegate.strokeWidth != strokeWidth;
  }
}
