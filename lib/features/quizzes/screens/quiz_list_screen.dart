import 'package:flutter/material.dart';

import '../../../shared/models/lesson.dart';
import '../../courses/data/course_data.dart';
import '../../lessons/data/lesson_data.dart';
import '../data/mock_quiz_data.dart';
import '../models/quiz.dart';
import '../services/quiz_progress_service.dart';
import 'quiz_screen.dart';

/// Every quiz in the app, grouped by course, with the user's best scores.
class QuizListScreen extends StatelessWidget {
  const QuizListScreen({super.key});

  /// Course title -> the (lesson, quiz) pairs that exist for that course.
  List<_CourseGroup> _buildGroups() {
    final groups = <_CourseGroup>[];
    final seenQuizIds = <String>{};

    for (final course in CourseData.courses) {
      final entries = <_QuizEntry>[];

      final lessons = LessonData.modulesForCourse(course.title)
          .expand((module) => module.lessons);

      for (final lesson in lessons) {
        final quiz = MockQuizData.quizForLesson(lesson.id);

        // modulesForCourse falls back to Flutter for unknown courses, so
        // skip anything already listed.
        if (quiz != null && seenQuizIds.add(quiz.id)) {
          entries.add(_QuizEntry(lesson: lesson, quiz: quiz));
        }
      }

      if (entries.isNotEmpty) {
        groups.add(_CourseGroup(courseTitle: course.title, entries: entries));
      }
    }

    return groups;
  }

  void _openQuiz(BuildContext context, Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(quiz: quiz),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
      ),
      body: AnimatedBuilder(
        animation: QuizProgressService.instance,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              _SummaryCard(totalQuizzes: MockQuizData.quizzes.length),

              for (final group in groups) ...[
                const SizedBox(height: 24),
                Text(
                  group.courseTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                for (final entry in group.entries)
                  _QuizTile(
                    entry: entry,
                    onTap: () => _openQuiz(context, entry.quiz),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _QuizEntry {
  final Lesson lesson;
  final Quiz quiz;

  const _QuizEntry({
    required this.lesson,
    required this.quiz,
  });
}

class _CourseGroup {
  final String courseTitle;
  final List<_QuizEntry> entries;

  const _CourseGroup({
    required this.courseTitle,
    required this.entries,
  });
}

class _SummaryCard extends StatelessWidget {
  final int totalQuizzes;

  const _SummaryCard({
    required this.totalQuizzes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = QuizProgressService.instance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            _SummaryStat(
              value: '${service.quizzesPassed}/$totalQuizzes',
              label: 'Passed',
              color: theme.colorScheme.primary,
            ),
            _SummaryStat(
              value: service.totalAttempts == 0
                  ? '--'
                  : '${service.averageBestPercentage.round()}%',
              label: 'Avg. best',
              color: Colors.green.shade600,
            ),
            _SummaryStat(
              value: '${service.totalAttempts}',
              label: 'Attempts',
              color: Colors.orange.shade700,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
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
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  final _QuizEntry entry;
  final VoidCallback onTap;

  const _QuizTile({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = QuizProgressService.instance.scoreFor(entry.quiz.id);
    final passed = score?.passed ?? false;

    final subtitle = score == null
        ? '${entry.quiz.questions.length} questions'
        : 'Best ${score.bestCorrect}/${score.totalQuestions} '
            '(${score.bestPercentage.round()}%) · '
            '${score.attempts} ${score.attempts == 1 ? 'attempt' : 'attempts'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: passed
              ? Colors.green.shade600
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            passed ? Icons.check : Icons.quiz_outlined,
            color: passed ? Colors.white : theme.colorScheme.onSurface,
            size: 20,
          ),
        ),
        title: Text(
          entry.lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}