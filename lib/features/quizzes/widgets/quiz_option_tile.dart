import 'package:flutter/material.dart';

/// Visual state of one answer option.
///
/// While taking a quiz only [idle] and [selected] are used. The result
/// screen's review uses [correct] and [incorrect] as well.
enum QuizOptionState {
  idle,
  selected,
  correct,
  incorrect,
}

class QuizOptionTile extends StatelessWidget {
  /// Short badge text such as "A", "B", "C".
  final String label;
  final String text;
  final QuizOptionState state;

  /// Null makes the tile read-only (used in the review).
  final VoidCallback? onTap;

  const QuizOptionTile({
    super.key,
    required this.label,
    required this.text,
    this.state = QuizOptionState.idle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final accent = switch (state) {
      QuizOptionState.idle => scheme.outline,
      QuizOptionState.selected => scheme.primary,
      QuizOptionState.correct => Colors.green.shade600,
      QuizOptionState.incorrect => scheme.error,
    };

    final isHighlighted = state != QuizOptionState.idle;

    final Widget badgeChild;
    switch (state) {
      case QuizOptionState.correct:
        badgeChild = const Icon(Icons.check, size: 16, color: Colors.white);
      case QuizOptionState.incorrect:
        badgeChild = const Icon(Icons.close, size: 16, color: Colors.white);
      case QuizOptionState.idle:
      case QuizOptionState.selected:
        badgeChild = Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: state == QuizOptionState.selected
                ? Colors.white
                : scheme.onSurface,
          ),
        );
    }

    final badgeFilled = state != QuizOptionState.idle;

    return Material(
      color: isHighlighted
          ? accent.withValues(alpha: 0.08)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isHighlighted ? accent : scheme.outlineVariant,
          width: isHighlighted ? 1.8 : 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: badgeFilled
                    ? accent
                    : scheme.surfaceContainerHighest,
                child: badgeChild,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: state == QuizOptionState.selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}