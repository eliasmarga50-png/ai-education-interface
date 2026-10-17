import 'dart:async';

import 'package:ai_education_interface/core/network/api_exception.dart';
import 'package:ai_education_interface/core/network/paged_result.dart';
import 'package:ai_education_interface/features/courses/models/course_resource.dart';
import 'package:ai_education_interface/features/courses/services/courses_api.dart';
import 'package:ai_education_interface/shared/models/course.dart';

Course testCourse(
  String id,
  String title, {
  String category = 'Programming',
  List<String> outcomes = const [],
}) {
  return Course(
    id: id,
    slug: id,
    title: title,
    description: '$title description',
    category: category,
    level: 'Beginner',
    lessons: 12,
    rating: 4.5,
    imageUrl: '',
    outcomes: outcomes,
  );
}

CourseResource testResource(String id, String title, {String? url}) {
  return CourseResource(
    id: id,
    courseId: 'c1',
    title: title,
    url: url ?? 'https://docs.example.org/$id',
    type: ResourceType.documentation,
    description: 'About $title',
    provider: 'Docs Team',
    difficulty: 'Beginner',
  );
}

/// Pages of courses/resources served from memory. Set [failWith] to make every call throw,
/// and [gate] to hold calls until the test completes it.
class FakeCoursesApi implements CoursesApi {
  FakeCoursesApi({
    this.coursePages = const [],
    this.resourcePages = const [],
  });

  final List<List<Course>> coursePages;
  final List<List<CourseResource>> resourcePages;
  Object? failWith;
  Completer<void>? gate;
  int listCalls = 0;

  Future<void> _before() async {
    await gate?.future;
    final error = failWith;
    if (error != null) {
      throw error;
    }
  }

  PagedResult<T> _page<T>(List<List<T>> pages, int page, int limit) {
    final total = pages.fold<int>(0, (sum, p) => sum + p.length);
    return PagedResult<T>(
      items: pages.isEmpty ? <T>[] : pages[page - 1],
      page: page,
      limit: limit,
      total: total,
      totalPages: pages.isEmpty ? 1 : pages.length,
    );
  }

  @override
  Future<PagedResult<Course>> listCourses({
    int page = 1,
    int limit = 50,
    String? category,
    String? level,
    String? query,
  }) async {
    listCalls++;
    await _before();
    return _page(coursePages, page, limit);
  }

  @override
  Future<Course> getCourse(String id) async {
    await _before();
    for (final course in coursePages.expand((p) => p)) {
      if (course.id == id) {
        return course;
      }
    }
    throw const ApiException(
      code: 'NOT_FOUND',
      message: 'Course not found.',
      statusCode: 404,
    );
  }

  @override
  Future<PagedResult<CourseResource>> listResources(
    String courseId, {
    int page = 1,
    int limit = 50,
    ResourceType? type,
  }) async {
    await _before();
    return _page(resourcePages, page, limit);
  }
}