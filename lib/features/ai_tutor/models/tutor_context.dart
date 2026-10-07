




import '../../../shared/models/course.dart';
import '../../../shared/models/lesson.dart';

/// What the tutor needs to know to help with one specific lesson.
class TutorContext {
  final String lessonId;
  final String lessonTitle;
  final String courseTitle;
  final String description;
  final String content;

  const TutorContext({
    required this.lessonId,
    required this.lessonTitle,
    required this.courseTitle,
    required this.description,
    required this.content,
  });

  factory TutorContext.fromLesson({
    required Course course,
    required Lesson lesson,
  }) {
    return TutorContext(
      lessonId: lesson.id,
      lessonTitle: lesson.title,
      courseTitle: course.title,
      description: lesson.description,
      content: lesson.content,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'courseTitle': courseTitle,
      'description': description,
      'content': content,
    };
  }

  factory TutorContext.fromJson(Map<String, dynamic> json) {
    return TutorContext(
      lessonId: json['lessonId'] as String,
      lessonTitle: json['lessonTitle'] as String,
      courseTitle: json['courseTitle'] as String,
      description: json['description'] as String,
      content: json['content'] as String,
    );
  }
}



