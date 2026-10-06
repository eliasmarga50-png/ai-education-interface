


class QuizResult {
  final String quizId;
  final int totalQuestions;
  final int correctAnswers;

  const QuizResult({
    required this.quizId,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  int get incorrectAnswers {
    return totalQuestions - correctAnswers;
  }

  double get percentage {
    if (totalQuestions == 0) {
      return 0;
    }

    return (correctAnswers / totalQuestions) * 100;
  }

  bool get isPerfect {
    return totalQuestions > 0 && correctAnswers == totalQuestions;
  }
}



