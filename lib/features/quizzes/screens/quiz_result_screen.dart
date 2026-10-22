import 'package:flutter/material.dart';

import '../../../shared/widgets/pressable_scale.dart';
import '../models/quiz_result.dart';
import '../widgets/quiz_option_tile.dart';
import '../widgets/understanding_badge.dart';

/// What the user chose to do on the result screen. [QuizScreen] receives this
/// from Navigator.pop and decides what happens next, so this screen never
/// has to import (or navigate to) the quiz screen itself.
enum QuizResultAction {
  retry,
  finish,
}

/// Shows the server's grading of one attempt: score, how well the student
/// understood the material, what to revisit, and every answer with its
/// explanation.
class QuizResultScreen extends StatefulWidget {
  final String quizTitle;
  final QuizResult result;

  const QuizResultScreen({
    super.key,
    required this.quizTitle,
    required this.result,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _showReview = false;

  QuizResult get _result => widget.result;

  String? get _comparison {
    final previous = _result.previousScore;

    if (previous == null) {
      return null;
    }

    final change = (_result.percentage - previous).round();

    if (change > 0) {
      return 'Up $change points from your last attempt';
    }

    if (change < 0) {
      return 'Down ${-change} points from your last attempt';
    }

    return 'Same as your last attempt';
  }

  void _finish() {
    Navigator.pop(context, QuizResultAction.finish);
  }

  void _retry() {
    Navigator.pop(context, QuizResultAction.retry);
  }

  void _toggleReview() {
    setState(() {
      _showReview = !_showReview;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = understandingColor(_result.understanding.level);
    final comparison = _comparison;

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
                        Text(
                          widget.quizTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
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
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scoreColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        UnderstandingBadge(
                          understanding: _result.understanding,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _result.understanding.message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PassBadge(
                          passed: _result.passed,
                          passingPercentage: _result.passingPercentage,
                        ),
                        if (comparison != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            '$comparison · best ${_result.bestScore.round()}%',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
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
                if (_result.recommendation.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _NextStepCard(
                    recommendation: _result.recommendation,
                    weakTopics: _result.isPerfect ? const [] : _result.weakTopics,
                  ),
                ],
                const SizedBox(height: 20),
                PressableScale(
                  onTap: _retry,
                  child: SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Retake Quiz',
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
                  onTap: _toggleReview,
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _toggleReview,
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
                  child: const Text('Done'),
                ),
                if (_showReview) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Review',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  for (final entry in _result.review.asMap().entries)
                    _ReviewCard(number: entry.key + 1, item: entry.value),
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
  final int passingPercentage;

  const _PassBadge({
    required this.passed,
    required this.passingPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color =
        passed ? Colors.green.shade600 : theme.colorScheme.onSurfaceVariant;

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
              passed ? 'Passed' : 'Score $passingPercentage% or more to pass',
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

/// What to do next, and which topics to revisit.
class _NextStepCard extends StatelessWidget {
  final String recommendation;
  final List<String> weakTopics;

  const _NextStepCard({
    required this.recommendation,
    required this.weakTopics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your next step', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(recommendation, style: theme.textTheme.bodyMedium),
            if (weakTopics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Revisit', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final topic in weakTopics) Chip(label: Text(topic)),
                ],
              ),
            ],
          ],
        ),
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
  final ReviewItem item;

  const _ReviewCard({
    required this.number,
    required this.item,
  });

  QuizOptionState _stateFor(int index) {
    if (index == item.correctIndex) {
      return QuizOptionState.correct;
    }

    if (index == item.selectedIndex) {
      return QuizOptionState.incorrect;
    }

    return QuizOptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor =
        item.isCorrect ? Colors.green.shade600 : theme.colorScheme.error;

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
                  item.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Question $number · ${item.isCorrect ? 'Correct' : 'Incorrect'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.prompt,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            for (final entry in item.options.asMap().entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: QuizOptionTile(
                  label: String.fromCharCode(65 + entry.key),
                  text: entry.value,
                  state: _stateFor(entry.key),
                ),
              ),
            if (item.explanation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.explanation,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}