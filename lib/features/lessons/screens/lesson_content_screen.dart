import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/course.dart';
import '../../../shared/models/lesson.dart';
import '../../ai_tutor/models/tutor_context.dart';
import '../../ai_tutor/screens/chat_screen.dart';
import '../../ai_tutor/services/tutor_controller.dart';
import '../../quizzes/data/mock_quiz_data.dart';
import '../../quizzes/models/quiz.dart';
import '../../quizzes/screens/quiz_screen.dart';
import '../../quizzes/services/quiz_progress_service.dart';
import '../data/lesson_data.dart';
import '../services/learning_progress_service.dart';

class LessonContentScreen extends StatefulWidget {
  final Course course;
  final Lesson lesson;

  const LessonContentScreen({
    super.key,
    required this.course,
    required this.lesson,
  });

  @override
  State<LessonContentScreen> createState() =>
      _LessonContentScreenState();
}

class _LessonContentScreenState
    extends State<LessonContentScreen> {
  late final List<CourseModule> _modules;
  late final List<Lesson> _allLessons;
  late final Quiz? _quiz;

  @override
  void initState() {
    super.initState();

    _modules =
        LessonData.modulesForCourse(widget.course.title);

    _allLessons = _modules
        .expand((module) => module.lessons)
        .toList();

    _quiz = MockQuizData.quizForLesson(widget.lesson.id);
  }

  bool get _isCompleted {
    return LearningProgressService.instance.isCompleted(
      widget.lesson.id,
    );
  }

  int get _currentLessonIndex {
    return _allLessons.indexWhere(
      (lesson) => lesson.id == widget.lesson.id,
    );
  }

  bool get _hasPreviousLesson {
    return _currentLessonIndex > 0;
  }

  bool get _hasNextLesson {
    return _currentLessonIndex >= 0 &&
        _currentLessonIndex < _allLessons.length - 1;
  }

  Lesson? get _previousLesson {
    if (!_hasPreviousLesson) {
      return null;
    }

    return _allLessons[_currentLessonIndex - 1];
  }

  Lesson? get _nextLesson {
    if (!_hasNextLesson) {
      return null;
    }

    return _allLessons[_currentLessonIndex + 1];
  }

  void _markComplete() {
    LearningProgressService.instance.markCompleted(
      widget.lesson.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lesson completed! 🎉'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {});
  }

  /// Opens the AI Tutor about this lesson, resuming the last chat about it.
  void _openTutor() {
    final lessonContext = TutorContext.fromLesson(
      course: widget.course,
      lesson: widget.lesson,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversation: TutorController.instance.latestForLesson(
            widget.lesson.id,
          ),
          lesson: lessonContext,
        ),
      ),
    );
  }

  void _openQuiz(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(quiz: quiz),
      ),
    );
  }

  void _openLesson(Lesson lesson) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LessonContentScreen(
          course: widget.course,
          lesson: lesson,
        ),
      ),
    );
  }

  void _openPreviousLesson() {
    final previousLesson = _previousLesson;

    if (previousLesson == null) {
      return;
    }

    _openLesson(previousLesson);
  }

  void _openNextLesson() {
    final nextLesson = _nextLesson;

    if (nextLesson == null) {
      return;
    }

    if (!_isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete this lesson before moving to the next one.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _openLesson(nextLesson);
  }

  void _showLessonOutline() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LessonOutlineSheet(
          modules: _modules,
          currentLessonId: widget.lesson.id,
          onLessonSelected: (lesson) {
            Navigator.pop(context);
            _openLesson(lesson);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLessonNumber =
        _currentLessonIndex >= 0
            ? _currentLessonIndex + 1
            : 1;

    return AnimatedBuilder(
      animation: LearningProgressService.instance,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Lesson'),
            actions: [
              IconButton(
                tooltip: 'Ask AI Tutor',
                onPressed: _openTutor,
                icon: const Icon(
                  Icons.smart_toy_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Lesson outline',
                onPressed: _showLessonOutline,
                icon: const Icon(
                  Icons.list_alt_outlined,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _LessonProgressHeader(
                currentLesson: currentLessonNumber,
                totalLessons: _allLessons.length,
              ),

              const SizedBox(height: 20),

              const _VideoPlaceholder(),

              const SizedBox(height: 24),

              Text(
                widget.lesson.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium,
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.lesson.durationMinutes} minutes',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  if (_isCompleted)
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                'About this lesson',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 10),

              Text(
                widget.lesson.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      height: 1.6,
                    ),
              ),

              const SizedBox(height: 28),

              Text(
                'Lesson Content',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 12),

              Text(
                widget.lesson.content,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      height: 1.8,
                    ),
              ),

              const SizedBox(height: 30),

              const _ResourcesSection(),

              const SizedBox(height: 30),

              _TutorSection(
                onAsk: _openTutor,
              ),

              const SizedBox(height: 30),

              if (_quiz case final quiz?) ...[
                _QuizSection(
                  quiz: quiz,
                  onStart: () => _openQuiz(quiz),
                ),

                const SizedBox(height: 30),
              ],

              _CompletionSection(
                isCompleted: _isCompleted,
                hasNextLesson: _hasNextLesson,
                onComplete: _markComplete,
                onNextLesson: _openNextLesson,
              ),

              const SizedBox(height: 24),

              _LessonNavigationButtons(
                hasPreviousLesson: _hasPreviousLesson,
                hasNextLesson: _hasNextLesson,
                isCompleted: _isCompleted,
                onPrevious: _openPreviousLesson,
                onNext: _openNextLesson,
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}

class _LessonProgressHeader extends StatelessWidget {
  final int currentLesson;
  final int totalLessons;

  const _LessonProgressHeader({
    required this.currentLesson,
    required this.totalLessons,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        totalLessons == 0
            ? 0.0
            : currentLesson / totalLessons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lesson $currentLesson of $totalLessons',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircleAvatar(
          radius: 32,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.play_arrow,
            color: Colors.black87,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _ResourcesSection extends StatelessWidget {
  const _ResourcesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Resources',
          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(
                Icons.picture_as_pdf_outlined,
              ),
            ),
            title: const Text(
              'Lesson Notes',
            ),
            subtitle: const Text(
              'PDF resource',
            ),
            trailing: const Icon(
              Icons.download_outlined,
            ),
            onTap: () {},
          ),
        ),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.code),
            ),
            title: const Text(
              'Practice Code',
            ),
            subtitle: const Text(
              'Source code and examples',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _TutorSection extends StatelessWidget {
  final VoidCallback onAsk;

  const _TutorSection({
    required this.onAsk,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(
                    alpha: 0.1,
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stuck on this lesson?',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Get an explanation, an example, or a practice '
                        'question.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onAsk,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text(
                  'Ask AI Tutor',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizSection extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onStart;

  const _QuizSection({
    required this.quiz,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Your Knowledge',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: QuizProgressService.instance,
          builder: (context, child) {
            final score = QuizProgressService.instance.scoreFor(quiz.id);
            final passed = score?.passed ?? false;

            final subtitle = score == null
                ? '${quiz.questions.length} questions · '
                    'pass with ${QuizProgressService.passingPercentage.round()}%'
                : 'Best: ${score.bestCorrect}/${score.totalQuestions} '
                    '(${score.bestPercentage.round()}%) · '
                    '${passed ? 'Passed' : 'Not passed yet'}';

            final accent =
                passed ? Colors.green.shade600 : AppTheme.primaryColor;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: accent.withValues(alpha: 0.1),
                          child: Icon(
                            passed
                                ? Icons.check_circle_outline
                                : Icons.quiz_outlined,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lesson Quiz',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.tonalIcon(
                        onPressed: onStart,
                        icon: Icon(
                          score == null ? Icons.play_arrow : Icons.refresh,
                        ),
                        label: Text(
                          score == null ? 'Start Quiz' : 'Retake Quiz',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CompletionSection extends StatelessWidget {
  final bool isCompleted;
  final bool hasNextLesson;
  final VoidCallback onComplete;
  final VoidCallback onNextLesson;

  const _CompletionSection({
    required this.isCompleted,
    required this.hasNextLesson,
    required this.onComplete,
    required this.onNextLesson,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isCompleted)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lesson completed',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.check),
              label: const Text(
                'Mark Lesson Complete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: isCompleted && hasNextLesson
                ? onNextLesson
                : null,
            child: Text(
              hasNextLesson
                  ? 'Next Lesson'
                  : 'Course Completed',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonNavigationButtons extends StatelessWidget {
  final bool hasPreviousLesson;
  final bool hasNextLesson;
  final bool isCompleted;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _LessonNavigationButtons({
    required this.hasPreviousLesson,
    required this.hasNextLesson,
    required this.isCompleted,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                hasPreviousLesson
                    ? onPrevious
                    : null,
            icon: const Icon(
              Icons.arrow_back,
            ),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(
                double.infinity,
                52,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed:
                hasNextLesson && isCompleted
                    ? onNext
                    : null,
            icon: const Icon(
              Icons.arrow_forward,
            ),
            label: const Text('Next'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(
                double.infinity,
                52,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonOutlineSheet extends StatelessWidget {
  final List<CourseModule> modules;
  final String currentLessonId;
  final ValueChanged<Lesson> onLessonSelected;

  const _LessonOutlineSheet({
    required this.modules,
    required this.currentLessonId,
    required this.onLessonSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: AnimatedBuilder(
            animation: LearningProgressService.instance,
            builder: (context, child) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  30,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Lesson Outline',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...modules.asMap().entries.map(
                    (moduleEntry) {
                      final moduleNumber =
                          moduleEntry.key + 1;
                      final module =
                          moduleEntry.value;

                      return _OutlineModule(
                        moduleNumber: moduleNumber,
                        module: module,
                        currentLessonId:
                            currentLessonId,
                        onLessonSelected:
                            onLessonSelected,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _OutlineModule extends StatelessWidget {
  final int moduleNumber;
  final CourseModule module;
  final String currentLessonId;
  final ValueChanged<Lesson> onLessonSelected;

  const _OutlineModule({
    required this.moduleNumber,
    required this.module,
    required this.currentLessonId,
    required this.onLessonSelected,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount =
        LearningProgressService.instance
            .completedLessons(
              module.lessons
                  .map((lesson) => lesson.id)
                  .toList(),
            );

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      AppTheme.primaryColor.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    '$moduleNumber',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    module.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
                Text(
                  '$completedCount/${module.lessons.length}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...module.lessons.asMap().entries.map(
              (lessonEntry) {
                final lessonNumber =
                    lessonEntry.key + 1;
                final lesson =
                    lessonEntry.value;

                final isCurrent =
                    lesson.id == currentLessonId;

                final isCompleted =
                    LearningProgressService
                        .instance
                        .isCompleted(
                          lesson.id,
                        );

                return Container(
                  margin: const EdgeInsets.only(
                    top: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppTheme.primaryColor
                            .withValues(
                            alpha: 0.08,
                          )
                        : null,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: isCompleted
                          ? AppTheme.primaryColor
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : Text(
                              '$lessonNumber',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                    title: Text(
                      lesson.title,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isCurrent
                            ? AppTheme.primaryColor
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      '${lesson.durationMinutes} min',
                    ),
                    trailing: isCurrent
                        ? const Icon(
                            Icons.play_circle_fill,
                            color:
                                AppTheme.primaryColor,
                          )
                        : const Icon(
                            Icons.chevron_right,
                          ),
                    onTap: () {
                      onLessonSelected(lesson);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}