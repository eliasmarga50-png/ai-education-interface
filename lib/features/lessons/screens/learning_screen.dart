


import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/course.dart';
import '../../../shared/models/lesson.dart';
import '../data/lesson_data.dart';
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

    final totalLessons = modules.fold<int>(
      0,
      (total, module) => total + module.lessons.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _CourseHeader(
            course: course,
            totalLessons: totalLessons,
          ),

          const SizedBox(height: 28),

          Text(
            'Course Modules',
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 16),

          ...modules.asMap().entries.map(
                (entry) => _ModuleCard(
                  moduleNumber: entry.key + 1,
                  module: entry.value,
                ),
              ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _CourseHeader extends StatelessWidget {
  final Course course;
  final int totalLessons;

  const _CourseHeader({
    required this.course,
    required this.totalLessons,
  });

  @override
  Widget build(BuildContext context) {
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

          const Text(
            'Your progress',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              value: 0,
              minHeight: 8,
              backgroundColor: Colors.white24,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            '0% completed',
            style: TextStyle(
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
  final int moduleNumber;
  final CourseModule module;

  const _ModuleCard({
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
    final module = widget.module;

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
                    backgroundColor: AppTheme.primaryColor.withValues(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${module.lessons.length} lessons',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: module.lessons.asMap().entries.map(
                  (entry) {
                    return _LessonTile(
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
  }
}

class _LessonTile extends StatelessWidget {
  final int lessonNumber;
  final Lesson lesson;

  const _LessonTile({
    required this.lessonNumber,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: lesson.isCompleted
            ? AppTheme.primaryColor
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: lesson.isCompleted
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
      trailing: const Icon(
        Icons.chevron_right,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LessonContentScreen(
              lesson: lesson,
            ),
          ),
        );
      },
    );
  }
}


