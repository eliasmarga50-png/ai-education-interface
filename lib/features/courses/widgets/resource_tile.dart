import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/course_resource.dart';

class ResourceTile extends StatelessWidget {
  final CourseResource resource;
  final VoidCallback onOpen;

  const ResourceTile({
    super.key,
    required this.resource,
    required this.onOpen,
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