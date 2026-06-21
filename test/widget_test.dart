import 'package:flutter_test/flutter_test.dart';
import 'package:kids_tracing_app/constants/app_constants.dart';
import 'package:kids_tracing_app/main.dart';

void main() {
  testWidgets('Shows splash screen title', (WidgetTester tester) async {
    await tester.pumpWidget(const KidsNumberTracingApp());
    await tester.pump();

    expect(find.text(AppConstants.appTitle), findsOneWidget);
    expect(find.text('Learn numbers 1 to 20!'), findsOneWidget);
  });
}
