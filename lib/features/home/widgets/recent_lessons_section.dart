import 'package:flutter/material.dart';

import '../../ai_tutor/utils/chat_time.dart';
import '../../dashboard/models/dashboard_models.dart';

/// The last few lessons the user opened.
class RecentLessonsSection extends StatelessWidget {
  final List<RecentLessonInfo> lessons;
  final ValueChanged<LessonRef> onOpen;

  const RecentLessonsSection({
    super.key,
    required this.lessons,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final item in lessons)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () => onOpen(item.ref),
              leading: CircleAvatar(
                backgroundColor: item.isCompleted
                    ? Colors.green.shade600.withValues(alpha: 0.14)
                    : theme.colorScheme.primary.withValues(alpha: 0.10),
                child: Icon(
                  item.isCompleted
                      ? Icons.check_circle
                      : Icons.play_circle_outline,
                  color: item.isCompleted
                      ? Colors.green.shade600
                      : theme.colorScheme.primary,
                ),
              ),
              title: Text(
                item.ref.lesson.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${item.ref.course.title} · '
                '${item.ref.lesson.durationMinutes} min',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                ChatTime.relative(item.openedAt),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
      ],
    );
  }
}