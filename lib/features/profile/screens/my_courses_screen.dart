import 'package:flutter/material.dart';

import '../../../core/navigation/main_tabs.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../courses/screens/course_details_screen.dart';
import '../../courses/services/course_repository.dart';
import '../../dashboard/models/dashboard_models.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../lessons/services/learning_progress_service.dart';

/// The courses the student has started, with real lesson progress.
class MyCoursesScreen extends StatelessWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = CourseRepository.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          LearningProgressService.instance,
          repository,
        ]),
        builder: (context, _) {
          if (repository.courses.isEmpty) {
            if (repository.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final error = repository.error;
            if (error != null) {
              return AppErrorState(
                message: error.message,
                onRetry: repository.refresh,
              );
            }
          }

          final started = DashboardService.courseProgress()
              .where((info) => info.isStarted)
              .toList()
            ..sort((a, b) {
              if (a.isComplete != b.isComplete) {
                return a.isComplete ? 1 : -1;
              }
              return b.progress.compareTo(a.progress);
            });

          if (started.isEmpty) {
            return AppEmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No courses started yet',
              message:
                  'Complete a lesson in any course and it will show up here '
                  'with your progress.',
              actionLabel: 'Browse courses',
              onAction: () {
                Navigator.pop(context);
                MainTabs.go(MainTabs.courses);
              },
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            itemCount: started.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _CourseProgressCard(
              info: started[index],
            ),
          );
        },
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  final CourseProgressInfo info;

  const _CourseProgressCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailsScreen(course: info.course),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      info.course.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (info.isComplete)
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${info.completedLessons} of ${info.totalLessons} lessons · '
                '${(info.progress * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: info.progress,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}