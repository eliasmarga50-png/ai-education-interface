import 'package:flutter/material.dart';

import '../../../shared/models/course.dart';
import '../../dashboard/models/dashboard_models.dart';
import 'course_visuals.dart';

/// Courses the user has not started, ranked by level and interests.
class RecommendedCoursesSection extends StatelessWidget {
  final List<CourseRecommendation> recommendations;
  final ValueChanged<Course> onOpenCourse;

  const RecommendedCoursesSection({
    super.key,
    required this.recommendations,
    required this.onOpenCourse,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: recommendations.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final recommendation = recommendations[index];

          return _RecommendedCard(
            recommendation: recommendation,
            onTap: () => onOpenCourse(recommendation.info.course),
          );
        },
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final CourseRecommendation recommendation;
  final VoidCallback onTap;

  const _RecommendedCard({
    required this.recommendation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = recommendation.info.course;
    final color = courseCategoryColor(course.category);

    return SizedBox(
      width: 248,
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
                        courseCategoryIcon(course.category),
                        size: 22,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        course.level,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '⭐ ${course.rating}  ·  '
                  '${recommendation.info.totalLessons} lessons',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        recommendation.reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}