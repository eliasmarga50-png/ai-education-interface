import 'package:flutter/material.dart';

import '../../dashboard/models/dashboard_models.dart';
import '../../dashboard/services/dashboard_service.dart';

/// Streak, learning time, lessons done and quiz average.
class StatsGrid extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const StatsGrid({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final streakCaption = snapshot.streak == 0
        ? 'Study today to start one'
        : snapshot.activeToday
            ? 'Active today ✓ · best ${snapshot.longestStreak}'
            : 'Study today to keep it going';

    final lessonPercent = snapshot.totalLessons == 0
        ? 0
        : (snapshot.completedLessons / snapshot.totalLessons * 100).round();

    final quizAverage = snapshot.quizAverage;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFEA580C),
                  value: '${snapshot.streak}',
                  label: 'Day streak',
                  caption: streakCaption,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.schedule,
                  color: const Color(0xFF0284C7),
                  value: DashboardService.formatDuration(
                    snapshot.totalSeconds,
                  ),
                  label: 'Learning time',
                  caption:
                      '${DashboardService.formatDuration(snapshot.weekSeconds)} '
                      'this week',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.task_alt,
                  color: const Color(0xFF16A34A),
                  value:
                      '${snapshot.completedLessons}/${snapshot.totalLessons}',
                  label: 'Lessons done',
                  caption: '$lessonPercent% of all lessons',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.quiz_outlined,
                  color: const Color(0xFF7C3AED),
                  value: quizAverage == null
                      ? '--'
                      : '${quizAverage.round()}%',
                  label: 'Quiz average',
                  caption:
                      '${snapshot.quizzesPassed} of ${snapshot.totalQuizzes} '
                      'passed',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String caption;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}