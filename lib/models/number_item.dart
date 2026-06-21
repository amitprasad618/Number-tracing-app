import 'package:kids_tracing_app/constants/app_constants.dart';

/// Represents a single number lesson.
class NumberItem {
  const NumberItem({required this.number});

  final int number;

  bool get isFirst => number == AppConstants.minNumber;
  bool get isLast => number == AppConstants.maxNumber;
}
