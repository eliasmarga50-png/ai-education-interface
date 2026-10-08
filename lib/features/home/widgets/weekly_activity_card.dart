import 'dart:math';

import 'package:flutter/material.dart';

import '../../dashboard/models/dashboard_models.dart';
import '../../dashboard/services/dashboard_service.dart';

/// Today's goal ring plus the last seven days as bars.
class WeeklyActivityCard extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const WeeklyActivityCard({
    super.key,
    required this.snapshot,
  });

  static const List<String> _weekdayLetters = [
    'M', 'T', 'W', 'T', 'F', 'S', 'S',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final goal = snapshot.dailyGoalMinutes;
    final todayMinutes = snapshot.todaySeconds / 60;
    final goalProgress = (todayMinutes / goal).clamp(0.0, 1.0);
    final reached = todayMinutes >= goal;

    final maxMinutes = snapshot.week.fold<double>(
      goal.toDouble(),
      (current, day) => max(current, day.minutes),
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: goalProgress),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: value,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            color: reached
                                ? Colors.green.shade600
                                : primary,
                            backgroundColor: primary.withValues(alpha: 0.12),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${todayMinutes.floor()}',
                                  style:
                                      theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'min',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily goal',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reached
                            ? 'Goal reached. Great work! 🎉'
                            : '${(goal - todayMinutes).ceil()} more min to '
                                'reach your $goal min goal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Last 7 days',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  DashboardService.formatDuration(snapshot.weekSeconds),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in snapshot.week)
                    Expanded(
                      child: _Bar(
                        day: day,
                        letter: _weekdayLetters[day.date.weekday - 1],
                        maxMinutes: maxMinutes,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final DayActivity day;
  final String letter;
  final double maxMinutes;

  const _Bar({
    required this.day,
    required this.letter,
    required this.maxMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    const maxBarHeight = 64.0;
    const minBarHeight = 5.0;

    final targetHeight = day.seconds == 0
        ? minBarHeight
        : max(minBarHeight, maxBarHeight * (day.minutes / maxMinutes));

    final Color color;

    if (day.isToday) {
      color = primary;
    } else if (day.seconds > 0) {
      color = primary.withValues(alpha: 0.5);
    } else if (day.isActive) {
      color = primary.withValues(alpha: 0.28);
    } else {
      color = theme.colorScheme.outlineVariant;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: minBarHeight, end: targetHeight),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, height, _) {
            return Container(
              width: 16,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          letter,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: day.isToday ? FontWeight.bold : FontWeight.normal,
            color: day.isToday ? primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}