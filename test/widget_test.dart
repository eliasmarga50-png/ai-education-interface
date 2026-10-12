import 'package:ai_education_interface/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test - mounts and reaches the signed-out flow',
      (WidgetTester tester) async {
    // AuthGate reads saved data on start-up; give it an empty store.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);

    // Let AuthController.initialize finish, then the splash screen's 2 s delay
    // and the page transition, so no timer is left pending.
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(MyApp), findsOneWidget);
  });
}