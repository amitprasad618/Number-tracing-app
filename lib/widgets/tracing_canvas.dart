import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:kids_tracing_app/constants/app_constants.dart';
import 'package:kids_tracing_app/providers/learning_provider.dart';
import 'package:kids_tracing_app/services/number_path_service.dart';
import 'package:provider/provider.dart';

/// Interactive canvas where children trace a large outlined number.
class TracingCanvas extends StatefulWidget {
  const TracingCanvas({super.key, required this.digit});

  final int digit;

  @override
  State<TracingCanvas> createState() => _TracingCanvasState();
}

class _TracingCanvasState extends State<TracingCanvas> {
  final _numberPathService = NumberPathService();
  TextPainter? _outlinePainter;
  Rect _glyphBounds = Rect.zero;
  MaskResult? _maskResult;
  bool _debugShowMask = false;
  bool _isLoadingMask = false;

  Future<void> _handlePanDown(DragDownDetails details) async {
    final provider = context.read<LearningProvider>();
    if (_maskResult == null) {
      return;
    }

    provider.startNewStroke(details.localPosition);
    await _updateProgress(provider);
  }

  Future<void> _handlePanStart(DragStartDetails details) async {
    final provider = context.read<LearningProvider>();
    if (_maskResult == null ||
        !_isPointNearGlyph(details.localPosition) ||
        provider.strokes.isNotEmpty) {
      return;
    }

    provider.startNewStroke(details.localPosition);
    await _updateProgress(provider);
  }

  Future<void> _handlePanUpdate(DragUpdateDetails details) async {
    final provider = context.read<LearningProvider>();
    if (provider.strokes.isEmpty) {
      return;
    }

    provider.addStrokePoint(details.localPosition);
    await _updateProgress(provider);
  }

  bool _isPointNearGlyph(Offset point) {
    if (_maskResult == null) {
      return false;
    }

    final hitZone = _maskResult!.bounds.inflate(
      AppConstants.tracingMaskHitRadius + 14,
    );
    return hitZone.contains(point) || _maskResult!.containsPoint(point);
  }

  Future<void> _updateProgress(LearningProvider provider) async {
    await provider.updateTracingProgress();
  }

  Future<void> _loadNumberPathWithSize(
    Size size,
    LearningProvider provider,
  ) async {
    setState(() {
      _isLoadingMask = true;
      _outlinePainter = null;
    });

    // Build outline painter and rasterized interior mask from the font glyph.
    final outline = _numberPathService.buildOutlineTextPainter(
      widget.digit,
      size,
    );
    final maskResult = await _numberPathService.createInteriorMaskFromGlyph(
      widget.digit,
      size,
    );

    if (!mounted) return;

    provider.updateTraceMask(
      maskPoints: maskResult.points,
      numberBounds: maskResult.bounds,
    );

    setState(() {
      _outlinePainter = outline;
      _glyphBounds = maskResult.bounds;
      _maskResult = maskResult;
      _isLoadingMask = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LearningProvider>(
      builder: (context, provider, _) {
        return ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);

              if (_outlinePainter == null &&
                  !_isLoadingMask &&
                  size.width > 0 &&
                  size.height > 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _loadNumberPathWithSize(size, provider);
                  }
                });
              }

              return Stack(
                children: [
                  GestureDetector(
                    // Disable drawing until glyph mask is loaded; also disable
                    // when tracing already complete.
                    behavior: HitTestBehavior.opaque,
                    onPanDown:
                        (provider.isTracingComplete || _maskResult == null)
                        ? null
                        : _handlePanDown,
                    onPanStart:
                        (provider.isTracingComplete || _maskResult == null)
                        ? null
                        : _handlePanStart,
                    onPanUpdate:
                        (provider.isTracingComplete || _maskResult == null)
                        ? null
                        : _handlePanUpdate,
                    child: CustomPaint(
                      size: size,
                      painter: _TracingPainter(
                        outlinePainter: _outlinePainter,
                        glyphOffset: _glyphBounds.topLeft,
                        strokes: provider.strokes,
                        maskPoints: provider.maskPoints,
                        matchedMask: provider.matchedMask,
                        glyphImage: _maskResult?.image,
                        debugShowMask: _debugShowMask,
                      ),
                    ),
                  ),
                  // Live overlay cursor: positioned circle following last touch
                  // point for extra responsiveness. Only shown when a stroke is
                  // active and the point is inside the glyph.
                  Builder(
                    builder: (context) {
                      final strokes = provider.strokes;
                      if (strokes.isEmpty) return const SizedBox.shrink();
                      final lastStroke = strokes.last;
                      if (lastStroke.isEmpty) return const SizedBox.shrink();
                      final lastPoint = lastStroke.last;
                      if (_maskResult == null ||
                          !_maskResult!.containsPoint(lastPoint)) {
                        return const SizedBox.shrink();
                      }

                      const cursorSize = 28.0;
                      return Positioned(
                        left: lastPoint.dx - cursorSize / 2,
                        top: lastPoint.dy - cursorSize / 2,
                        child: IgnorePointer(
                          child: Container(
                            width: cursorSize,
                            height: cursorSize,
                            decoration: BoxDecoration(
                              color: AppConstants.secondaryColor.withValues(
                                alpha: 0.95,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppConstants.primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (_isLoadingMask)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  // Debug toggle for visualizing mask and matched hits.
                  Positioned(
                    right: 12,
                    top: 12,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _debugShowMask = !_debugShowMask),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppConstants.primaryColor),
                        ),
                        child: Text(
                          _debugShowMask ? 'Mask: ON' : 'Mask: OFF',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _TracingPainter extends CustomPainter {
  _TracingPainter({
    required this.outlinePainter,
    required this.glyphOffset,
    required this.strokes,
    required this.maskPoints,
    required this.matchedMask,
    required this.glyphImage,
    required this.debugShowMask,
  });

  final TextPainter? outlinePainter;
  final Offset glyphOffset;
  final List<List<Offset>> strokes;
  final List<Offset> maskPoints;
  final List<bool> matchedMask;
  final ui.Image? glyphImage;
  final bool debugShowMask;

  @override
  void paint(Canvas canvas, Size size) {
    if (outlinePainter == null) return;

    _drawFill(canvas);
    _drawOutline(canvas);
    _drawStrokes(canvas, size);
  }

  void _drawFill(Canvas canvas) {
    if (maskPoints.isEmpty || matchedMask.isEmpty) {
      return;
    }
    // Draw filled interior by painting overlapping circles at matched mask
    // points. This produces a continuous coloring-book style fill.
    final fillPaint = Paint()
      ..color = AppConstants.primaryColor.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    final pointRadius = AppConstants.tracingMaskSampleStep * 0.65;
    for (var i = 0; i < maskPoints.length; i++) {
      if (matchedMask[i]) {
        canvas.drawCircle(maskPoints[i], pointRadius, fillPaint);
      }
    }

    // Debug: draw all mask points as faint dots and matched as brighter.
    if (debugShowMask) {
      final back = Paint()..color = Colors.red.withValues(alpha: 0.12);
      final hit = Paint()..color = Colors.green.withValues(alpha: 0.9);
      for (var i = 0; i < maskPoints.length; i++) {
        canvas.drawCircle(maskPoints[i], 3, matchedMask[i] ? hit : back);
      }
    }
  }

  void _drawOutline(Canvas canvas) {
    // Paint the glyph outline via the provided TextPainter which uses
    // a stroke foreground paint.
    outlinePainter!.paint(canvas, glyphOffset);
  }

  void _drawStrokes(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = AppConstants.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Draw strokes into a layer and mask by the glyph image so nothing
    // appears outside the number shape. If the glyph image isn't ready,
    // don't draw strokes at all to avoid unmasked drawing.
    if (glyphImage == null) return;

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;

      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          9,
          strokePaint..style = PaintingStyle.fill,
        );
        continue;
      }

      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }

    // Draw a live trace cursor at the last touch point of the active stroke
    // so the child sees a responsive brush tip. This is drawn inside the
    // same layer and will be masked by the glyph image.
    final lastPoint = (strokes.isNotEmpty && strokes.last.isNotEmpty)
        ? strokes.last.last
        : null;
    if (lastPoint != null) {
      final cursorPaint = Paint()
        ..color = AppConstants.secondaryColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPoint, 12, cursorPaint);
      final ring = Paint()
        ..color = AppConstants.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(lastPoint, 14, ring);
    }

    if (glyphImage != null) {
      final maskPaint = Paint()..blendMode = BlendMode.dstIn;
      // The rendered glyph image already includes the glyph at its internal
      // offset; draw the image at the canvas origin so the glyph lines up
      // with the original sampling coordinates.
      canvas.drawImage(glyphImage!, Offset.zero, maskPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TracingPainter oldDelegate) {
    return oldDelegate.outlinePainter != outlinePainter ||
        oldDelegate.glyphOffset != glyphOffset ||
        oldDelegate.strokes != strokes ||
        oldDelegate.matchedMask != matchedMask ||
        oldDelegate.maskPoints != maskPoints;
  }
}
