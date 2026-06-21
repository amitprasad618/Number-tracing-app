import 'package:kids_tracing_app/constants/app_constants.dart';
import 'package:kids_tracing_app/models/number_item.dart';

/// Static lesson data for numbers 1 through 20.
class NumberData {
  NumberData._();

  static final List<NumberItem> items = List.generate(
    AppConstants.totalNumbers,
    (index) => NumberItem(number: index + AppConstants.minNumber),
  );

  static NumberItem getByIndex(int index) => items[index];

  static NumberItem getByNumber(int number) {
    final index = number - AppConstants.minNumber;
    return items[index];
  }
}
