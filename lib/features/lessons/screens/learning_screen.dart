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
          body: ListView(
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
        );
      },
    );
  }
}