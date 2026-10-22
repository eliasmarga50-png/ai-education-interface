import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../quizzes/models/quiz_performance.dart';
import '../../quizzes/widgets/understanding_badge.dart';
import '../models/course_resource.dart';

class ResourceTile extends StatelessWidget {
  final CourseResource resource;
  final VoidCallback onOpen;

  /// Opens the quiz for this resource. The quiz button is hidden when null.
  final VoidCallback? onTakeQuiz;

  /// The student's results on this resource's quiz, if they have taken it.
  final ScopePerformance? performance;

  const ResourceTile({
    super.key,
    required this.resource,
    required this.onOpen,
    this.onTakeQuiz,
    this.performance,
  });

  IconData get _icon {
    switch (resource.type) {
      case ResourceType.documentation:
        return Icons.description_outlined;
      case ResourceType.tutorial:
        return Icons.school_outlined;
      case ResourceType.video:
        return Icons.play_circle_outline;
      case ResourceType.course:
        return Icons.menu_book_outlined;
      case ResourceType.article:
        return Icons.article_outlined;
      case ResourceType.book:
        return Icons.book_outlined;
      case ResourceType.interactive:
        return Icons.touch_app_outlined;
      case ResourceType.other:
        return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      resource.provider,
      resource.type.label,
      if (resource.difficulty != null) resource.difficulty!,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: '${resource.title}, $meta. Opens in your browser.',
        child: Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resource.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(meta, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Text(
                          resource.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (onTakeQuiz != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: onTakeQuiz,
                                icon: const Icon(Icons.quiz_outlined, size: 18),
                                label: Text(
                                  performance == null
                                      ? 'Take quiz'
                                      : 'Retake quiz',
                                ),
                              ),
                              if (performance != null)
                                UnderstandingBadge(
                                  understanding: performance!.understanding,
                                  percent: performance!.lastScore,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_new, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}