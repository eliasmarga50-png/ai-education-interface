import 'quiz_result.dart';

double _number(Object? value) => (value as num?)?.toDouble() ?? 0;

Map<String, dynamic> _map(Object? value) =>
    Map<String, dynamic>.from(value as Map);

/// A student's results on one quiz (a course quiz or a resource quiz).
class QuizStats {
  final int attempts;
  final double bestScore;
  final double lastScore;
  final bool passed;
  final Understanding understanding;

  const QuizStats({
    required this.attempts,
    required this.bestScore,
    required this.lastScore,
    required this.passed,
    required this.understanding,
  });

  factory QuizStats.fromJson(Map<String, dynamic> json) {
    return QuizStats(
      attempts: (json['attempts'] as num).toInt(),
      bestScore: _number(json['bestScore']),
      lastScore: _number(json['lastScore']),
      passed: json['passed'] as bool? ?? false,
      understanding: Understanding.fromJson(_map(json['understanding'])),
    );
  }
}

/// A quiz in a course's quiz list, with the student's results if any.
class QuizSummary {
  final String id;
  final String courseId;
  final String? resourceId;
  final String title;
  final String description;
  final int questionCount;
  final int passingPercentage;
  final QuizStats? stats;

  const QuizSummary({
    required this.id,
    required this.courseId,
    required this.resourceId,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.passingPercentage,
    required this.stats,
  });

  bool get isCourseQuiz => resourceId == null;

  factory QuizSummary.fromJson(Map<String, dynamic> json) {
    return QuizSummary(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      resourceId: json['resourceId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      passingPercentage: (json['passingPercentage'] as num?)?.toInt() ?? 60,
      stats: json['stats'] == null ? null : QuizStats.fromJson(_map(json['stats'])),
    );
  }
}

/// Results for one course quiz or one resource quiz, from the performance API.
class ScopePerformance {
  final String courseId;
  final String? resourceId;
  final int attempts;
  final double bestScore;
  final double lastScore;
  final bool passed;
  final Understanding understanding;

  const ScopePerformance({
    required this.courseId,
    required this.resourceId,
    required this.attempts,
    required this.bestScore,
    required this.lastScore,
    required this.passed,
    required this.understanding,
  });

  factory ScopePerformance.fromJson(Map<String, dynamic> json) {
    return ScopePerformance(
      courseId: json['courseId'] as String,
      resourceId: json['resourceId'] as String?,
      attempts: (json['attempts'] as num).toInt(),
      bestScore: _number(json['bestScore']),
      lastScore: _number(json['lastScore']),
      passed: json['passed'] as bool? ?? false,
      understanding: Understanding.fromJson(_map(json['understanding'])),
    );
  }
}

class CoursePerformance {
  final String courseId;
  final String courseTitle;
  final int quizzesAvailable;
  final int quizzesAttempted;
  final int quizzesPassed;
  final double averageScore;
  final Understanding understanding;
  final List<String> weakTopics;

  const CoursePerformance({
    required this.courseId,
    required this.courseTitle,
    required this.quizzesAvailable,
    required this.quizzesAttempted,
    required this.quizzesPassed,
    required this.averageScore,
    required this.understanding,
    required this.weakTopics,
  });

  factory CoursePerformance.fromJson(Map<String, dynamic> json) {
    return CoursePerformance(
      courseId: json['courseId'] as String,
      courseTitle: json['courseTitle'] as String? ?? '',
      quizzesAvailable: (json['quizzesAvailable'] as num?)?.toInt() ?? 0,
      quizzesAttempted: (json['quizzesAttempted'] as num?)?.toInt() ?? 0,
      quizzesPassed: (json['quizzesPassed'] as num?)?.toInt() ?? 0,
      averageScore: _number(json['averageScore']),
      understanding: Understanding.fromJson(_map(json['understanding'])),
      weakTopics:
          (json['weakTopics'] as List?)?.whereType<String>().toList() ??
              const [],
    );
  }
}

/// Everything the server knows about the signed-in student's quiz results.
class QuizPerformance {
  final int totalQuizzes;
  final int quizzesAttempted;
  final int quizzesPassed;
  final int totalAttempts;

  /// Average of the best score on every quiz attempted; null before the first attempt.
  final double? averageBestScore;

  /// How well the student understands the material overall; null before the first attempt.
  final Understanding? understanding;
  final List<CoursePerformance> courses;
  final List<ScopePerformance> scopes;

  const QuizPerformance({
    required this.totalQuizzes,
    required this.quizzesAttempted,
    required this.quizzesPassed,
    required this.totalAttempts,
    required this.averageBestScore,
    required this.understanding,
    required this.courses,
    required this.scopes,
  });

  static const QuizPerformance empty = QuizPerformance(
    totalQuizzes: 0,
    quizzesAttempted: 0,
    quizzesPassed: 0,
    totalAttempts: 0,
    averageBestScore: null,
    understanding: null,
    courses: [],
    scopes: [],
  );

  ScopePerformance? scopeFor(String courseId, String? resourceId) {
    for (final scope in scopes) {
      if (scope.courseId == courseId && scope.resourceId == resourceId) {
        return scope;
      }
    }
    return null;
  }

  CoursePerformance? courseFor(String courseId) {
    for (final course in courses) {
      if (course.courseId == courseId) {
        return course;
      }
    }
    return null;
  }

  factory QuizPerformance.fromJson(Map<String, dynamic> json) {
    return QuizPerformance(
      totalQuizzes: (json['totalQuizzes'] as num?)?.toInt() ?? 0,
      quizzesAttempted: (json['quizzesAttempted'] as num?)?.toInt() ?? 0,
      quizzesPassed: (json['quizzesPassed'] as num?)?.toInt() ?? 0,
      totalAttempts: (json['totalAttempts'] as num?)?.toInt() ?? 0,
      averageBestScore: (json['averageBestScore'] as num?)?.toDouble(),
      understanding: json['understanding'] == null
          ? null
          : Understanding.fromJson(_map(json['understanding'])),
      courses: (json['courses'] as List? ?? const [])
          .whereType<Map>()
          .map((c) => CoursePerformance.fromJson(_map(c)))
          .toList(),
      scopes: (json['scopes'] as List? ?? const [])
          .whereType<Map>()
          .map((s) => ScopePerformance.fromJson(_map(s)))
          .toList(),
    );
  }
}