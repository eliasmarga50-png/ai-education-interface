import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, size: 26, color: scheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}