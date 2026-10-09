import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/course.dart';
import '../../../shared/models/lesson.dart';
import '../data/lesson_data.dart';
import '../services/learning_progress_service.dart';
import 'lesson_content_screen.dart';

class LearningScreen extends StatelessWidget {
  final Course course;

  const LearningScreen({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final modules = LessonData.modulesForCourse(course.title);

    return AnimatedBuilder(
      animation: LearningProgressService.instance,
      builder: (context, child) {
        final allLessons = modules
            .expand((module) => module.lessons)
            .toList();

        final lessonIds = allLessons
            .map((lesson) => lesson.id)
            .toList();

        final completedCount =
            LearningProgressService.instance.completedLessons(
          lessonIds,
        );

        final progress =
            LearningProgressService.instance.progress(
          lessonIds,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Learning'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _CourseHeader(
                course: course,
                totalLessons: allLessons.length,
                completedLessons: completedCount,
                progress: progress,
              ),

              const SizedBox(height: 28),

              Text(
                'Course Modules',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 16),

              ...modules.asMap().entries.map(
                    (entry) => _ModuleCard(
                      course: course,
                      moduleNumber: entry.key + 1,
                      module: entry.value,
                    ),
                  ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}

class _CourseHeader extends StatelessWidget {
  final Course course;
  final int totalLessons;
  final int completedLessons;
  final double progress;

  const _CourseHeader({
    required this.course,
    required this.totalLessons,
    required this.completedLessons,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.school_outlined,
            color: Colors.white,
            size: 36,
          ),

          const SizedBox(height: 16),

          Text(
            course.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '$totalLessons lessons • ${course.level}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your progress',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              Text(
                '$completedLessons/$totalLessons',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '$percentage% completed',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final Course course;
  final int moduleNumber;
  final CourseModule module;

  const _ModuleCard({
    required this.course,
    required this.moduleNumber,
    required this.module,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LearningProgressService.instance,
      builder: (context, child) {
        final module = widget.module;

        final lessonIds = module.lessons
            .map((lesson) => lesson.id)
            .toList();

        final completedLessons =
            LearningProgressService.instance.completedLessons(
          lessonIds,
        );

        final moduleProgress =
            LearningProgressService.instance.progress(
          lessonIds,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            AppTheme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          '${widget.moduleNumber}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              module.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '$completedLessons/${module.lessons.length} lessons completed',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),

                            const SizedBox(height: 8),

                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: moduleProgress,
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                      ),
                    ],
                  ),
                ),
              ),

              if (_expanded)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: module.lessons.asMap().entries.map(
                      (entry) {
                        return _LessonTile(
                          course: widget.course,
                          lessonNumber: entry.key + 1,
                          lesson: entry.value,
                        );
                      },
                    ).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Course course;
  final int lessonNumber;
  final Lesson lesson;

  const _LessonTile({
    required this.course,
    required this.lessonNumber,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LearningProgressService.instance,
      builder: (context, child) {
        final isCompleted =
            LearningProgressService.instance.isCompleted(
          lesson.id,
        );

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),

          leading: CircleAvatar(
            radius: 18,
            backgroundColor: isCompleted
                ? AppTheme.primaryColor
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : Text(
                    '$lessonNumber',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),

          title: Text(
            lesson.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          subtitle: Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text('${lesson.durationMinutes} min'),
            ],
          ),

          trailing: isCompleted
              ? const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                )
              : const Icon(
                  Icons.chevron_right,
                ),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LessonContentScreen(
                  course: course,
                  lesson: lesson,
                ),
              ),
            );
          },
        );
      },
    );
  }
}