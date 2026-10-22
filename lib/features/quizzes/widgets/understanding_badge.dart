import 'package:flutter/material.dart';

import '../models/quiz_result.dart';

/// One colour per understanding level, used everywhere results are shown.
Color understandingColor(String level) {
  switch (level) {
    case 'mastered':
      return Colors.green.shade600;
    case 'proficient':
      return Colors.blue.shade600;
    case 'developing':
      return Colors.orange.shade700;
    default:
      return Colors.red.shade600;
  }
}

IconData understandingIcon(String level) {
  switch (level) {
    case 'mastered':
      return Icons.workspace_premium_outlined;
    case 'proficient':
      return Icons.thumb_up_alt_outlined;
    case 'developing':
      return Icons.trending_up;
    default:
      return Icons.menu_book_outlined;
  }
}

/// A small pill such as "Proficient · 80%".
class UnderstandingBadge extends StatelessWidget {
  final Understanding understanding;

  /// Shown after the label when given.
  final double? percent;

  const UnderstandingBadge({
    super.key,
    required this.understanding,
    this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final color = understandingColor(understanding.level);
    final text = percent == null
        ? understanding.label
        : '${understanding.label} · ${percent!.round()}%';

    return Semantics(
      label: 'Understanding: $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(understandingIcon(understanding.level), size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}