import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/course.dart';
import '../../../shared/models/lesson.dart';
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
  late final List<Lesson> _allLessons;

  @override
  void initState() {
    super.initState();

    final modules =
        LessonData.modulesForCourse(widget.course.title);

    _allLessons = modules
        .expand((module) => module.lessons)
        .toList();
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

  bool get _hasNextLesson {
    return _currentLessonIndex >= 0 &&
        _currentLessonIndex < _allLessons.length - 1;
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

  void _openNextLesson() {
    final nextLesson = _nextLesson;

    if (nextLesson == null) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LessonContentScreen(
          course: widget.course,
          lesson: nextLesson,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LearningProgressService.instance,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Lesson'),
          ),

          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _VideoPlaceholder(),

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

              _CompletionSection(
                isCompleted: _isCompleted,
                hasNextLesson: _hasNextLesson,
                onComplete: _markComplete,
                onNextLesson: _openNextLesson,
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
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