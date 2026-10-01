class Lesson {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final String content;
  final bool isCompleted;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.content,
    this.isCompleted = false,
  });
}

class CourseModule {
  final String id;
  final String title;
  final String description;
  final List<Lesson> lessons;

  const CourseModule({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
  });

  int get completedLessons {
    return lessons.where((lesson) => lesson.isCompleted).length;
  }

  double get progress {
    if (lessons.isEmpty) {
      return 0;
    }

    return completedLessons / lessons.length;
  }
}