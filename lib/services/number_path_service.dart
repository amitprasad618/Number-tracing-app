import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_tracing_app/constants/app_constants.dart';

/// Provides glyph-based number rendering utilities.
class NumberPathService {
  /// Fallback path (not used by the glyph pipeline) kept for compatibility.
  Path buildNumberPath(int number, Size size) {
    final width = size.width * AppConstants.numberOutlineScale;
    final height = size.height * AppConstants.numberOutlineScale;
    final center = Offset(size.width / 2, size.height / 2);
    final top = center.dy - height / 2;
    final left = center.dx - width / 2;
    final rect = Rect.fromLTWH(left, top, width, height);
    final p = Path();
    p.addOval(rect);
    return p;
  }

  /// Build a [TextPainter] configured to draw an outline (stroke) of the
  /// glyph for [number] sized to [size]. The returned painter is already
  /// laid out and ready to paint.
  TextPainter buildOutlineTextPainter(int number, Size size) {
    final fontSize =
        math.min(size.width, size.height) * AppConstants.numberOutlineScale;
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppConstants.numberOutlineStrokeWidth
      ..color = AppConstants.primaryColor
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final textStyle = GoogleFonts.getFont(
      'Fredoka',
      textStyle: TextStyle(foreground: outlinePaint, fontSize: fontSize),
    );
    final tp = TextPainter(
      text: TextSpan(text: number.toString(), style: textStyle),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    return tp;
  }

  /// Rasterize the filled glyph into an image and sample interior pixels to
  /// produce mask points. Returns mask points in the canvas coordinate
  /// space along with the glyph bounds.
  Future<MaskResult> createInteriorMaskFromGlyph(int number, Size size) async {
    final fontSize =
        math.min(size.width, size.height) * AppConstants.numberOutlineScale;
    final fillStyle = GoogleFonts.getFont(
      'Fredoka',
      textStyle: TextStyle(color: Colors.white, fontSize: fontSize),
    );
    final tp = TextPainter(
      text: TextSpan(text: number.toString(), style: fillStyle),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    final offset = Offset(
      (size.width - tp.width) / 2,
      (size.height - tp.height) / 2,
    );
    tp.paint(canvas, offset);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppConstants.numberOutlineStrokeWidth
      ..color = Colors.white
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final strokeTextStyle = GoogleFonts.getFont(
      'Fredoka',
      textStyle: TextStyle(foreground: strokePaint, fontSize: fontSize),
    );
    final strokePainter = TextPainter(
      text: TextSpan(text: number.toString(), style: strokeTextStyle),
      textDirection: TextDirection.ltr,
    );
    strokePainter.layout();
    strokePainter.paint(canvas, offset);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.ceil().clamp(1, 4096),
      size.height.ceil().clamp(1, 4096),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) {
      return MaskResult(
        points: [],
        bounds: Rect.fromLTWH(offset.dx, offset.dy, tp.width, tp.height),
        image: image,
        imageData: Uint8List(0),
        imageWidth: image.width,
        imageHeight: image.height,
        imageOffset: offset,
      );
    }

    final data = bytes.buffer.asUint8List();
    final step = AppConstants.tracingMaskSampleStep;
    final points = <Offset>[];
    final w = image.width;

    for (var y = offset.dy.ceil(); y < offset.dy + tp.height; y += step) {
      for (var x = offset.dx.ceil(); x < offset.dx + tp.width; x += step) {
        final px = x.clamp(0, w - 1);
        final py = y.clamp(0, image.height - 1);
        final idx = (py * w + px) * 4;
        if (idx + 3 < data.length) {
          final alpha = data[idx + 3];
          if (alpha > 10) {
            points.add(Offset(x.toDouble(), y.toDouble()));
          }
        }
      }
    }

    List<Offset> finalPoints = points;
    if (points.length > AppConstants.tracingMaskPointCount) {
      final stride = points.length / AppConstants.tracingMaskPointCount;
      finalPoints = List.generate(
        AppConstants.tracingMaskPointCount,
        (i) => points[(i * stride).floor()],
      );
    }

    return MaskResult(
      points: finalPoints,
      bounds: Rect.fromLTWH(offset.dx, offset.dy, tp.width, tp.height),
      image: image,
      imageData: data,
      imageWidth: image.width,
      imageHeight: image.height,
      imageOffset: offset,
    );
  }
}

/// Result container for rasterized glyph mask and bounds.
class MaskResult {
  MaskResult({
    required this.points,
    required this.bounds,
    required this.image,
    required this.imageData,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageOffset,
  });

  final List<Offset> points;
  final Rect bounds;

  // Rendered glyph image and raw RGBA bytes for hit-testing.
  final ui.Image image;
  final Uint8List imageData;
  final int imageWidth;
  final int imageHeight;
  final Offset imageOffset;

  bool containsPoint(Offset p, {int alphaThreshold = 10}) {
    final localXf = p.dx - imageOffset.dx;
    final localYf = p.dy - imageOffset.dy;
    final baseX = localXf.round();
    final baseY = localYf.round();

    for (var oy = -2; oy <= 2; oy++) {
      for (var ox = -2; ox <= 2; ox++) {
        final x = baseX + ox;
        final y = baseY + oy;
        if (x < 0 || y < 0 || x >= imageWidth || y >= imageHeight) continue;
        final idx = (y * imageWidth + x) * 4;
        if (idx + 3 >= imageData.length) continue;
        final alpha = imageData[idx + 3];
        if (alpha > alphaThreshold) return true;
      }
    }

    return false;
  }
}
