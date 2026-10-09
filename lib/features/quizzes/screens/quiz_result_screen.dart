import 'package:flutter/material.dart';

import '../../../shared/widgets/pressable_scale.dart';
import '../models/quiz.dart';
import '../models/quiz_result.dart';
import '../services/quiz_progress_service.dart';
import '../widgets/quiz_option_tile.dart';

/// What the user chose to do on the result screen. [QuizScreen] receives this
/// from Navigator.pop and decides what happens next, so this screen never
/// has to import (or navigate to) the quiz screen itself.
enum QuizResultAction {
  retry,
  finish,
}

class QuizResultScreen extends StatefulWidget {
  final Quiz quiz;
  final QuizResult result;

  /// The user's answer for each question, in question order.
  final List<String?> answers;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.result,
    required this.answers,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _showReview = false;

  QuizResult get _result => widget.result;

  bool get _passed {
    return _result.percentage >= QuizProgressService.passingPercentage;
  }

  String get _headline {
    if (_result.isPerfect) {
      return 'Perfect score! 🎉';
    }

    if (_result.percentage >= 80) {
      return 'Great job!';
    }

    if (_result.percentage >= 50) {
      return 'Good effort!';
    }

    return 'Keep practicing!';
  }

  String get _message {
    if (_result.isPerfect) {
      return 'You answered every question correctly.';
    }

    if (_result.percentage >= 80) {
      return 'You clearly understand this lesson.';
    }

    if (_result.percentage >= 50) {
      return 'Review the questions you missed and try again.';
    }

    return 'Re-read the lesson, then give the quiz another try.';
  }

  Color _scoreColor(BuildContext context) {
    if (_result.percentage >= 80) {
      return Colors.green.shade600;
    }

    if (_result.percentage >= 50) {
      return Colors.orange.shade700;
    }

    return Theme.of(context).colorScheme.error;
  }

  void _finish() {
    Navigator.pop(context, QuizResultAction.finish);
  }

  void _retry() {
    Navigator.pop(context, QuizResultAction.retry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _scoreColor(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: _result.percentage / 100,
                            strokeWidth: 10,
                            color: scoreColor,
                            backgroundColor:
                                scoreColor.withValues(alpha: 0.15),
                          ),
                          Center(
                            child: Text(
                              '${_result.percentage.round()}%',
                              style:
                                  theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _headline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PassBadge(passed: _passed),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _StatTile(
                          label: 'Correct',
                          value: '${_result.correctAnswers}',
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 12),
                        _StatTile(
                          label: 'Incorrect',
                          value: '${_result.incorrectAnswers}',
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        _StatTile(
                          label: 'Total',
                          value: '${_result.totalQuestions}',
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            PressableScale(
              onTap: _retry,
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Retry Quiz',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            PressableScale(
              onTap: () {
                setState(() {
                  _showReview = !_showReview;
                });
              },
              child: SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showReview = !_showReview;
                    });
                  },
                  icon: Icon(
                    _showReview
                        ? Icons.visibility_off_outlined
                        : Icons.fact_check_outlined,
                  ),
                  label: Text(
                    _showReview ? 'Hide Review' : 'Review Answers',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: _finish,
              child: const Text('Back to Lesson'),
            ),

            if (_showReview) ...[
              const SizedBox(height: 16),
              Text(
                'Review',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...widget.quiz.questions.asMap().entries.map(
                    (entry) => _ReviewCard(
                      number: entry.key + 1,
                      questionText: entry.value.question,
                      options: entry.value.options,
                      correctAnswer: entry.value.correctAnswer,
                      selectedAnswer: entry.key < widget.answers.length
                          ? widget.answers[entry.key]
                          : null,
                    ),
                  ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  ),
);
  }
}

class _PassBadge extends StatelessWidget {
  final bool passed;

  const _PassBadge({
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color =
        passed ? Colors.green.shade600 : theme.colorScheme.onSurfaceVariant;

    final needed = QuizProgressService.passingPercentage.round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.info_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              passed
                  ? 'Passed · lesson marked complete'
                  : 'Score $needed% or more to pass',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int number;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? selectedAnswer;

  const _ReviewCard({
    required this.number,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.selectedAnswer,
  });

  bool get _isCorrect => selectedAnswer == correctAnswer;

  QuizOptionState _stateFor(String option) {
    if (option == correctAnswer) {
      return QuizOptionState.correct;
    }

    if (option == selectedAnswer) {
      return QuizOptionState.incorrect;
    }

    return QuizOptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor =
        _isCorrect ? Colors.green.shade600 : theme.colorScheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle : Icons.cancel,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Question $number · ${_isCorrect ? 'Correct' : 'Incorrect'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              questionText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            ...options.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: QuizOptionTile(
                      label: String.fromCharCode(65 + entry.key),
                      text: entry.value,
                      state: _stateFor(entry.value),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}