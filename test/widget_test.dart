import 'package:flutter_test/flutter_test.dart';
import 'package:ai_education_interface/main.dart';

void main() {
  testWidgets('App smoke test - mounts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // The widget tree should build and render the initial AuthGate
    expect(find.byType(MyApp), findsOneWidget);
  });
}
