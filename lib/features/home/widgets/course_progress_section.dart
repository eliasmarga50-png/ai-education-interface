import 'package:flutter/material.dart';

import '../../../shared/models/course.dart';
import '../../dashboard/models/dashboard_models.dart';
import 'course_visuals.dart';

/// Horizontal list of the courses the user has started.
class CourseProgressSection extends StatelessWidget {
  final List<CourseProgressInfo> courses;
  final ValueChanged<Course> onOpenCourse;
  final VoidCallback onBrowseCourses;

  const CourseProgressSection({
    super.key,
    required this.courses,
    required this.onOpenCourse,
    required this.onBrowseCourses,
  });

  @override
  Widget build(BuildContext context) {
    final started = courses.where((info) => info.isStarted).toList()
      ..sort((a, b) {
        // Unfinished courses first, then by how far along they are.
        if (a.isComplete != b.isComplete) {
          return a.isComplete ? 1 : -1;
        }

        return b.progress.compareTo(a.progress);
      });

    if (started.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onBrowseCourses,
          leading: const CircleAvatar(
            child: Icon(Icons.rocket_launch_outlined),
          ),
          title: const Text(
            'Start your first course',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Complete a lesson and your progress shows up here.',
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: started.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final info = started[index];

          return _CourseProgressCard(
            info: info,
            onTap: () => onOpenCourse(info.course),
          );
        },
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  final CourseProgressInfo info;
  final VoidCallback onTap;

  const _CourseProgressCard({
    required this.info,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = courseCategoryColor(info.course.category);
    final percent = (info.progress * 100).round();
    final next = info.nextLesson;

    return SizedBox(
      width: 232,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(
                        courseCategoryIcon(info.course.category),
                        size: 22,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    if (info.isComplete)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                      )
                    else
                      Text(
                        '$percent%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  info.course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${info.completedLessons} of ${info.totalLessons} lessons',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: info.progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 7,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.12),
                      ),
                    );
                  },
                ),
                const Spacer(),
                Text(
                  next == null
                      ? 'Course complete'
                      : 'Next: ${next.lesson.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}