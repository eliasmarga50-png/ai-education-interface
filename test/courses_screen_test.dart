import 'dart:async';

import 'package:ai_education_interface/core/network/api_exception.dart';
import 'package:ai_education_interface/core/theme/app_theme.dart';
import 'package:ai_education_interface/features/courses/screens/courses_screen.dart';
import 'package:ai_education_interface/features/courses/services/course_repository.dart';
import 'package:ai_education_interface/shared/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_courses_api.dart';

Future<void> pumpCourses(WidgetTester tester, FakeCoursesApi api) async {
  CourseRepository.instance = CourseRepository(api);
  tester.view.physicalSize = const Size(420, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.lightTheme, home: const CoursesScreen()),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows a skeleton while loading, then the courses', (tester) async {
    final gate = Completer<void>();
    final api = FakeCoursesApi(coursePages: [
      [
        testCourse('1', 'Flutter Development'),
        testCourse('2', 'UI/UX Design', category: 'Design'),
      ],
    ])
      ..gate = gate;

    await pumpCourses(tester, api);
    await tester.pump();

    expect(find.byType(AppShimmer), findsWidgets);
    expect(find.text('Flutter Development'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Flutter Development'), findsOneWidget);
    expect(find.text('UI/UX Design'), findsOneWidget);
    expect(find.text('2 courses'), findsOneWidget);
  });

  testWidgets('category chips come from the data and filter the list', (tester) async {
    final api = FakeCoursesApi(coursePages: [
      [
        testCourse('1', 'Flutter Development'),
        testCourse('2', 'UI/UX Design', category: 'Design'),
      ],
    ]);

    await pumpCourses(tester, api);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Design'));
    await tester.pumpAndSettle();

    expect(find.text('UI/UX Design'), findsOneWidget);
    expect(find.text('Flutter Development'), findsNothing);
  });

  testWidgets('shows an error state and recovers when retrying', (tester) async {
    final api = FakeCoursesApi(coursePages: [
      [testCourse('1', 'Flutter Development')],
    ])
      ..failWith = const ApiException(
        code: 'NETWORK_ERROR',
        message: "Can't reach the server. Check your connection and try again.",
      );

    await pumpCourses(tester, api);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load courses"), findsOneWidget);
    expect(find.textContaining("Can't reach the server"), findsOneWidget);

    api.failWith = null;
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(find.text('Flutter Development'), findsOneWidget);
  });

  testWidgets('shows an empty state when the catalogue has no courses', (tester) async {
    final api = FakeCoursesApi(coursePages: [<dynamic>[].cast()]);

    await pumpCourses(tester, api);
    await tester.pumpAndSettle();

    expect(find.text('No courses available yet'), findsOneWidget);
  });
}