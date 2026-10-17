import 'package:ai_education_interface/core/network/api_exception.dart';
import 'package:ai_education_interface/core/theme/app_theme.dart';
import 'package:ai_education_interface/features/courses/screens/course_details_screen.dart';
import 'package:ai_education_interface/features/courses/services/course_repository.dart';
import 'package:ai_education_interface/shared/models/course.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_courses_api.dart';

final Course listCourse = testCourse('c1', 'Flutter Development');

Future<void> pumpDetails(
  WidgetTester tester,
  FakeCoursesApi api, {
  LinkLauncher? launcher,
}) async {
  tester.view.physicalSize = const Size(420, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: CourseDetailsScreen(
        course: listCourse,
        repository: CourseRepository(api),
        launcher: launcher ?? (_) async => true,
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows API outcomes and resources, and opens a link', (tester) async {
    Uri? opened;
    final api = FakeCoursesApi(
      coursePages: [
        [testCourse('c1', 'Flutter Development', outcomes: ['Build real apps'])],
      ],
      resourcePages: [
        [testResource('r1', 'Official Docs', url: 'https://docs.flutter.dev/')],
      ],
    );

    await pumpDetails(tester, api, launcher: (uri) async {
      opened = uri;
      return true;
    });
    await tester.pumpAndSettle();

    expect(find.text('Build real apps'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Official Docs'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Official Docs'));
    await tester.pump();

    expect(opened.toString(), 'https://docs.flutter.dev/');
  });

  testWidgets('shows an empty state when a course has no resources', (tester) async {
    final api = FakeCoursesApi(coursePages: [
      [testCourse('c1', 'Flutter Development')],
    ]);

    await pumpDetails(tester, api);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('No resources yet'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('No resources yet'), findsOneWidget);
  });

  testWidgets('shows an error with retry when loading fails', (tester) async {
    final api = FakeCoursesApi(
      coursePages: [
        [testCourse('c1', 'Flutter Development')],
      ],
      resourcePages: [
        [testResource('r1', 'Official Docs')],
      ],
    )..failWith = const ApiException(code: 'NETWORK_ERROR', message: 'offline');

    await pumpDetails(tester, api);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text("Couldn't load resources"),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('offline'), findsOneWidget);

    api.failWith = null;
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(find.text('Official Docs'), findsOneWidget);
  });
}