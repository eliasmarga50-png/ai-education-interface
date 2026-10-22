import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/models/course.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../courses/services/course_repository.dart';
import '../models/quiz_performance.dart';
import '../services/quiz_progress_service.dart';
import '../services/quizzes_api.dart';
import '../widgets/understanding_badge.dart';
import 'quiz_screen.dart';

/// Every course with its quizzes (one for the course, one per resource) and
/// the student's results. The quizzes of a course load when it is opened.
class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final QuizzesApi _api = HttpQuizzesApi();

  @override
  void initState() {
    super.initState();
    CourseRepository.instance.ensureLoaded();
    QuizProgressService.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          CourseRepository.instance,
          QuizProgressService.instance,
        ]),
        builder: (context, _) {
          final courses = CourseRepository.instance.courses;
          final progress = QuizProgressService.instance;

          if (courses.isEmpty) {
            return const AppEmptyState(
              icon: Icons.quiz_outlined,
              title: 'No quizzes yet',
              message: 'Quizzes are created from the courses once they load.',
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _SummaryCard(progress: progress),
                  const SizedBox(height: 20),
                  for (final course in courses)
                    _CourseQuizzes(
                      key: ValueKey(course.id),
                      course: course,
                      api: _api,
                      courseResult: progress.courseFor(course.id),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final QuizProgressService progress;

  const _SummaryCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final understanding = progress.understanding;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your progress', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              progress.totalAttempts == 0
                  ? 'Take a quiz after using a course resource to see how well you understood it.'
                  : '${progress.quizzesPassed} of ${progress.totalQuizzes} quizzes passed · '
                      'average best score ${progress.averageBestPercentage.round()}%',
              style: theme.textTheme.bodyMedium,
            ),
            if (understanding != null) ...[
              const SizedBox(height: 10),
              UnderstandingBadge(understanding: understanding),
            ],
          ],
        ),
      ),
    );
  }
}

class _CourseQuizzes extends StatefulWidget {
  final Course course;
  final QuizzesApi api;
  final CoursePerformance? courseResult;

  const _CourseQuizzes({
    super.key,
    required this.course,
    required this.api,
    required this.courseResult,
  });

  @override
  State<_CourseQuizzes> createState() => _CourseQuizzesState();
}

class _CourseQuizzesState extends State<_CourseQuizzes> {
  List<QuizSummary>? _quizzes;
  ApiException? _error;
  bool _isLoading = false;

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final quizzes = await widget.api.listCourseQuizzes(widget.course.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _open(QuizSummary quiz) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          courseId: quiz.courseId,
          resourceId: quiz.resourceId,
          title: quiz.title,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    QuizProgressService.instance.refresh();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.courseResult;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(widget.course.title, style: theme.textTheme.titleMedium),
        subtitle: Text(
          result == null || result.quizzesAttempted == 0
              ? 'Not started'
              : '${result.quizzesPassed} of ${result.quizzesAvailable} passed · '
                  '${result.understanding.label}',
        ),
        onExpansionChanged: (expanded) {
          if (expanded && _quizzes == null && !_isLoading) {
            _load();
          }
        },
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Column(
              children: [
                Text(_error!.message),
                TextButton(onPressed: _load, child: const Text('Try again')),
              ],
            ),
          if (result != null && result.weakTopics.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Revisit: ${result.weakTopics.join(', ')}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          for (final quiz in _quizzes ?? const <QuizSummary>[])
            _QuizTile(quiz: quiz, onTap: () => _open(quiz)),
        ],
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  final QuizSummary quiz;
  final VoidCallback onTap;

  const _QuizTile({required this.quiz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stats = quiz.stats;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        quiz.isCourseQuiz ? Icons.school_outlined : Icons.quiz_outlined,
      ),
      title: Text(quiz.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: stats == null
            ? Text('${quiz.questionCount} questions')
            : Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  UnderstandingBadge(
                    understanding: stats.understanding,
                    percent: stats.lastScore,
                  ),
                  Text('Best ${stats.bestScore.round()}%'),
                ],
              ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}