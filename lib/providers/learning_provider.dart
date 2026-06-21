import 'package:flutter/material.dart';
import 'package:kids_tracing_app/data/number_data.dart';
import 'package:kids_tracing_app/models/number_item.dart';
import 'package:kids_tracing_app/services/audio_service.dart';
import 'package:kids_tracing_app/services/tracing_service.dart';

/// Manages the active lesson, tracing progress, and navigation state.
class LearningProvider extends ChangeNotifier {
  LearningProvider({TracingService? tracingService, AudioService? audioService})
    : _tracingService = tracingService ?? TracingService(),
      _audioService = audioService ?? AudioService();

  final TracingService _tracingService;
  final AudioService _audioService;

  int _currentIndex = 0;
  double _tracingProgress = 0;
  bool _isTracingComplete = false;
  bool _showSuccessOverlay = false;
  List<List<Offset>> _strokes = [];
  List<Offset> _maskPoints = [];
  List<bool> _matchedMask = [];
  Rect _numberBounds = Rect.zero;

  int get currentIndex => _currentIndex;
  double get tracingProgress => _tracingProgress;
  bool get isTracingComplete => _isTracingComplete;
  bool get showSuccessOverlay => _showSuccessOverlay;
  List<List<Offset>> get strokes => List.unmodifiable(_strokes);
  List<Offset> get maskPoints => List.unmodifiable(_maskPoints);
  List<bool> get matchedMask => List.unmodifiable(_matchedMask);
  Rect get numberBounds => _numberBounds;

  NumberItem get currentItem => NumberData.getByIndex(_currentIndex);

  bool get canGoPrevious => _currentIndex > 0;
  bool get canGoNext => _currentIndex < NumberData.items.length - 1;
  bool get isLastNumber => currentItem.isLast;

  TracingService get tracingService => _tracingService;
  AudioService get audioService => _audioService;

  Future<void> initialize() async {
    await _audioService.initialize();
  }

  void goToPrevious() {
    if (!canGoPrevious) {
      return;
    }
    _currentIndex--;
    _resetTracingState();
    notifyListeners();
  }

  void goToNext() {
    if (!canGoNext) {
      return;
    }
    _currentIndex++;
    _resetTracingState();
    notifyListeners();
  }

  void restartFromBeginning() {
    _currentIndex = 0;
    _resetTracingState();
    notifyListeners();
  }

  void clearTracing() {
    _strokes = [];
    _tracingProgress = 0;
    _matchedMask = List<bool>.filled(_maskPoints.length, false);
    _isTracingComplete = false;
    _showSuccessOverlay = false;
    notifyListeners();
  }

  void updateTraceMask({
    required List<Offset> maskPoints,
    required Rect numberBounds,
  }) {
    _maskPoints = maskPoints;
    _numberBounds = numberBounds;
    _matchedMask = List<bool>.filled(maskPoints.length, false);
    _tracingProgress = 0;
    _isTracingComplete = false;
    _showSuccessOverlay = false;
    notifyListeners();
  }

  void addStrokePoint(Offset point) {
    if (_isTracingComplete) {
      return;
    }

    if (_strokes.isEmpty) {
      _strokes.add([point]);
    } else {
      _strokes.last.add(point);
    }
    notifyListeners();
  }

  void startNewStroke(Offset point) {
    if (_isTracingComplete) {
      return;
    }

    _strokes.add([point]);
    notifyListeners();
  }

  Future<void> updateTracingProgress() async {
    if (_isTracingComplete || _maskPoints.isEmpty) {
      return;
    }

    final result = _tracingService.calculateProgress(
      maskPoints: _maskPoints,
      strokes: _strokes,
    );

    _matchedMask = result.matchedMask;
    _tracingProgress = result.coverage;
    notifyListeners();

    if (_tracingService.isTracingSuccessful(
      progressResult: result,
      numberBounds: _numberBounds,
    )) {
      await _handleTracingSuccess();
    }
  }

  Future<void> _handleTracingSuccess() async {
    _isTracingComplete = true;
    _tracingProgress = 1;
    _showSuccessOverlay = true;
    notifyListeners();

    await _audioService.playSuccessSound();
  }

  Future<void> advanceAfterSuccess() async {
    _showSuccessOverlay = false;

    if (isLastNumber) {
      notifyListeners();
      return;
    }

    _currentIndex++;
    _resetTracingState();
    notifyListeners();
  }

  void dismissSuccessOverlay() {
    _showSuccessOverlay = false;
    notifyListeners();
  }

  void _resetTracingState() {
    _strokes = [];
    _tracingProgress = 0;
    _matchedMask = [];
    _numberBounds = Rect.zero;
    _isTracingComplete = false;
    _showSuccessOverlay = false;
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
