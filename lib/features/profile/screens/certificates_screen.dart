import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../courses/services/course_repository.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../lessons/services/learning_progress_service.dart';
import 'my_courses_screen.dart';

/// One entry for every course whose lessons are all completed.
///
/// The list is real (from the lesson progress). Generating and downloading a
/// certificate file needs a backend that issues them, which does not exist yet.
class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Certificates')),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          LearningProgressService.instance,
          CourseRepository.instance,
        ]),
        builder: (context, _) {
          final completed = DashboardService.courseProgress()
              .where((info) => info.isComplete)
              .toList();

          if (completed.isEmpty) {
            return AppEmptyState(
              icon: Icons.workspace_premium_outlined,
              title: 'No certificates yet',
              message:
                  'Finish every lesson in a course to earn its certificate.',
              actionLabel: 'View my courses',
              onAction: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyCoursesScreen()),
                );
              },
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              for (final info in completed) ...[
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_outlined,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      info.course.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Certificate of completion · '
                      '${info.totalLessons} lessons',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              Text(
                'Downloadable certificate files are not available yet.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}