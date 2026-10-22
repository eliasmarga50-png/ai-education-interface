double _number(Object? value) => (value as num?)?.toDouble() ?? 0;

/// How well the student understands the material, decided by the server from
/// the score: mastered, proficient, developing or needs_review.
class Understanding {
  final String level;
  final String label;
  final String message;

  const Understanding({
    required this.level,
    required this.label,
    required this.message,
  });

  bool get isStrong => level == 'mastered' || level == 'proficient';

  factory Understanding.fromJson(Map<String, dynamic> json) {
    return Understanding(
      level: json['level'] as String? ?? 'needs_review',
      label: json['label'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

/// One graded question, sent back after submitting.
class ReviewItem {
  final String questionId;
  final String prompt;
  final List<String> options;
  final int selectedIndex;
  final int correctIndex;
  final bool isCorrect;
  final String explanation;
  final String topic;

  const ReviewItem({
    required this.questionId,
    required this.prompt,
    required this.options,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
    required this.explanation,
    required this.topic,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      questionId: json['questionId'] as String,
      prompt: json['prompt'] as String,
      options: (json['options'] as List).whereType<String>().toList(),
      selectedIndex: (json['selectedIndex'] as num).toInt(),
      correctIndex: (json['correctIndex'] as num).toInt(),
      isCorrect: json['isCorrect'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
    );
  }
}

/// The server's grading of one submitted attempt. The score is calculated and
/// saved on the server; nothing here is computed on the device.
class QuizResult {
  final String attemptId;
  final String quizId;
  final String courseId;
  final String? resourceId;
  final int totalQuestions;
  final int correctAnswers;
  final double percentage;
  final bool passed;
  final int passingPercentage;
  final Understanding understanding;
  final int attemptNumber;
  final double? previousScore;
  final double bestScore;
  final List<String> weakTopics;
  final String recommendation;
  final List<ReviewItem> review;

  const QuizResult({
    required this.attemptId,
    required this.quizId,
    required this.courseId,
    required this.resourceId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentage,
    required this.passed,
    required this.passingPercentage,
    required this.understanding,
    required this.attemptNumber,
    required this.previousScore,
    required this.bestScore,
    required this.weakTopics,
    required this.recommendation,
    required this.review,
  });

  int get incorrectAnswers => totalQuestions - correctAnswers;

  bool get isPerfect => totalQuestions > 0 && correctAnswers == totalQuestions;

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      attemptId: json['attemptId'] as String,
      quizId: json['quizId'] as String,
      courseId: json['courseId'] as String,
      resourceId: json['resourceId'] as String?,
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      correctAnswers: (json['correctCount'] as num).toInt(),
      percentage: _number(json['scorePercent']),
      passed: json['passed'] as bool? ?? false,
      passingPercentage: (json['passingPercentage'] as num?)?.toInt() ?? 60,
      understanding: Understanding.fromJson(
        Map<String, dynamic>.from(json['understanding'] as Map),
      ),
      attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 1,
      previousScore: (json['previousScore'] as num?)?.toDouble(),
      bestScore: _number(json['bestScore']),
      weakTopics:
          (json['weakTopics'] as List?)?.whereType<String>().toList() ??
              const [],
      recommendation: json['recommendation'] as String? ?? '',
      review: (json['review'] as List? ?? const [])
          .whereType<Map>()
          .map((r) => ReviewItem.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }
}