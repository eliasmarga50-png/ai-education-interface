import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/services/learning_activity_service.dart';
import '../../lessons/services/learning_progress_service.dart';
import '../models/quiz_result.dart';

/// The best result a user has achieved on one quiz, plus how often they
/// have tried it.
class QuizScore {
  final String lessonId;
  final int bestCorrect;
  final int totalQuestions;
  final int attempts;

  const QuizScore({
    required this.lessonId,
    required this.bestCorrect,
    required this.totalQuestions,
    required this.attempts,
  });

  double get bestPercentage {
    if (totalQuestions == 0) {
      return 0;
    }

    return (bestCorrect / totalQuestions) * 100;
  }

  bool get passed {
    return bestPercentage >= QuizProgressService.passingPercentage;
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'bestCorrect': bestCorrect,
      'totalQuestions': totalQuestions,
      'attempts': attempts,
    };
  }

  factory QuizScore.fromJson(Map<String, dynamic> json) {
    return QuizScore(
      lessonId: json['lessonId'] as String,
      bestCorrect: (json['bestCorrect'] as num).toInt(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      attempts: (json['attempts'] as num).toInt(),
    );
  }
}

/// Keeps quiz scores for the whole app and saves them on the device.
///
/// Passing a quiz also marks its lesson complete in
/// [LearningProgressService], which is how quizzes feed the course progress
/// bars.
class QuizProgressService extends ChangeNotifier {
  QuizProgressService._();

  static final QuizProgressService instance = QuizProgressService._();

  /// Score (in percent) needed to pass a quiz. 2 of 3 questions passes.
  static const double passingPercentage = 60;

  static const String _storageKey = 'quiz_scores_v1';

  final Map<String, QuizScore> _scores = {};

  /// Loads saved scores. Call once before runApp.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;

        decoded.forEach((quizId, value) {
          _scores[quizId] = QuizScore.fromJson(
            value as Map<String, dynamic>,
          );
        });
      }
    } catch (error) {
      debugPrint('QUIZ PROGRESS → could not load scores: $error');
      _scores.clear();
    }

    // Lesson completion is not saved yet, so re-apply it from passed quizzes.
    for (final score in _scores.values) {
      if (score.passed) {
        LearningProgressService.instance.markCompleted(score.lessonId);
      }
    }

    notifyListeners();
  }

  QuizScore? scoreFor(String quizId) {
    return _scores[quizId];
  }

  bool isPassed(String quizId) {
    return _scores[quizId]?.passed ?? false;
  }

  int get quizzesPassed {
    return _scores.values.where((score) => score.passed).length;
  }

  int get totalAttempts {
    return _scores.values.fold(0, (sum, score) => sum + score.attempts);
  }

  /// Average of the best score on every quiz that has been attempted.
  double get averageBestPercentage {
    if (_scores.isEmpty) {
      return 0;
    }

    final total = _scores.values.fold<double>(
      0,
      (sum, score) => sum + score.bestPercentage,
    );

    return total / _scores.length;
  }

  /// Records one finished attempt and returns true when it passed.
  Future<bool> recordResult(
    QuizResult result, {
    required String lessonId,
  }) async {
    final previous = _scores[result.quizId];

    var bestCorrect = result.correctAnswers;
    var totalQuestions = result.totalQuestions;

    // Keep the old best when this attempt did not beat it.
    if (previous != null &&
        previous.bestPercentage >= result.percentage) {
      bestCorrect = previous.bestCorrect;
      totalQuestions = previous.totalQuestions;
    }

    _scores[result.quizId] = QuizScore(
      lessonId: lessonId,
      bestCorrect: bestCorrect,
      totalQuestions: totalQuestions,
      attempts: (previous?.attempts ?? 0) + 1,
    );

    // Taking a quiz counts toward the daily streak.
    LearningActivityService.instance.recordActivity();

    final passed = result.percentage >= passingPercentage;

    if (passed) {
      LearningProgressService.instance.markCompleted(lessonId);
    }

    notifyListeners();
    await _save();

    return passed;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final encoded = jsonEncode(
        _scores.map((quizId, score) => MapEntry(quizId, score.toJson())),
      );

      await prefs.setString(_storageKey, encoded);
    } catch (error) {
      debugPrint('QUIZ PROGRESS → could not save scores: $error');
    }
  }
}