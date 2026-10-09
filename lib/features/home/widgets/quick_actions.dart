import 'package:flutter/material.dart';
import '../../../shared/widgets/pressable_scale.dart';

/// Three shortcuts under the hero card.
class QuickActions extends StatelessWidget {
  final VoidCallback onCourses;
  final VoidCallback onAiTutor;
  final VoidCallback onQuizzes;

  const QuickActions({
    super.key,
    required this.onCourses,
    required this.onAiTutor,
    required this.onQuizzes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.menu_book_outlined,
            label: 'Courses',
            onTap: onCourses,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon: Icons.smart_toy_outlined,
            label: 'AI Tutor',
            onTap: onAiTutor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon: Icons.quiz_outlined,
            label: 'Quizzes',
            onTap: onQuizzes,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: 'Open $label',
      child: PressableScale(
        onTap: onTap,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 24, color: scheme.primary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}