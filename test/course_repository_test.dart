import 'package:ai_education_interface/core/network/api_exception.dart';
import 'package:ai_education_interface/features/courses/services/course_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_courses_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loads every page of the catalogue', () async {
    final api = FakeCoursesApi(coursePages: [
      [testCourse('1', 'Flutter Development')],
      [testCourse('2', 'Python Programming')],
    ]);
    final repo = CourseRepository(api);

    await repo.refresh();

    expect(repo.courses.map((c) => c.title),
        ['Flutter Development', 'Python Programming']);
    expect(repo.hasLoaded, isTrue);
    expect(repo.isLoading, isFalse);
    expect(repo.error, isNull);
    expect(api.listCalls, 2);
    expect(repo.findById('2')?.title, 'Python Programming');
  });

  test('shares one request between simultaneous callers', () async {
    final api = FakeCoursesApi(coursePages: [
      [testCourse('1', 'A')],
    ]);
    final repo = CourseRepository(api);

    await Future.wait([repo.refresh(), repo.refresh(), repo.ensureLoaded()]);

    expect(api.listCalls, 1);
  });

  test('exposes a failure, then recovers on retry', () async {
    final api = FakeCoursesApi(coursePages: [
      [testCourse('1', 'A')],
    ])
      ..failWith = const ApiException(
        code: 'NETWORK_ERROR',
        message: "Can't reach the server.",
      );
    final repo = CourseRepository(api);

    await repo.refresh();
    expect(repo.hasLoaded, isFalse);
    expect(repo.error?.code, 'NETWORK_ERROR');

    api.failWith = null;
    await repo.refresh();
    expect(repo.hasLoaded, isTrue);
    expect(repo.error, isNull);
    expect(repo.courses, hasLength(1));
  });

  test('turns an unexpected response into a safe error', () async {
    final api = FakeCoursesApi()..failWith = StateError('bad json');
    final repo = CourseRepository(api);

    await repo.refresh();

    expect(repo.error?.code, 'INVALID_RESPONSE');
  });

  test('keeps showing the saved catalogue when a refresh fails', () async {
    final first = CourseRepository(FakeCoursesApi(coursePages: [
      [testCourse('1', 'Saved Course')],
    ]));
    await first.refresh();

    final offline = FakeCoursesApi()
      ..failWith = const ApiException(code: 'NETWORK_ERROR', message: 'offline');
    final second = CourseRepository(offline);
    await second.initialize();
    await second.refresh();

    expect(second.courses.single.title, 'Saved Course');
    expect(second.hasLoaded, isTrue);
    expect(second.error?.code, 'NETWORK_ERROR');
  });

  test('fetchResources reads every page and wraps unexpected errors', () async {
    final api = FakeCoursesApi(resourcePages: [
      [testResource('1', 'One')],
      [testResource('2', 'Two')],
    ]);
    final repo = CourseRepository(api);

    final resources = await repo.fetchResources('c1');
    expect(resources.map((r) => r.title), ['One', 'Two']);

    api.failWith = StateError('boom');
    expect(
      () => repo.fetchResources('c1'),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'INVALID_RESPONSE')),
    );
  });
}