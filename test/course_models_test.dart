import 'package:ai_education_interface/features/courses/models/course_resource.dart';
import 'package:ai_education_interface/shared/models/course.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Course.fromJson maps the API fields and survives a round trip', () {
    final course = Course.fromJson({
      'id': 'abc',
      'slug': 'flutter-development',
      'title': 'Flutter Development',
      'description': 'Build apps.',
      'category': 'Programming',
      'level': 'Beginner',
      'lessonCount': 24,
      'rating': 4.9,
      'imageUrl': null,
      'outcomes': ['One', 'Two'],
      'resourceCount': 7,
    });

    expect(course.lessons, 24);
    expect(course.rating, 4.9);
    expect(course.imageUrl, '');
    expect(course.outcomes, ['One', 'Two']);

    final again = Course.fromJson(course.toJson());
    expect(again.title, course.title);
    expect(again.resourceCount, 7);
  });

  test('Course.fromJson tolerates a missing rating and outcomes', () {
    final course = Course.fromJson({'id': 'a', 'slug': 'a', 'title': 'A'});
    expect(course.rating, 0);
    expect(course.outcomes, isEmpty);
  });

  test('CourseResource.fromJson reads known types and falls back for unknown ones', () {
    final video = CourseResource.fromJson({
      'id': '1',
      'title': 'Talk',
      'url': 'https://example.org/talk',
      'type': 'video',
      'difficulty': 'Beginner',
    });
    expect(video.type, ResourceType.video);
    expect(video.uri?.host, 'example.org');
    expect(video.language, 'en');

    final unknown = CourseResource.fromJson({
      'id': '2',
      'title': 'Mystery',
      'url': 'https://example.org/x',
      'type': 'hologram',
    });
    expect(unknown.type, ResourceType.other);
  });
}