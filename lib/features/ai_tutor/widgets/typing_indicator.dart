import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// "AI Tutor is thinking..." bubble with three bouncing dots.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(int index) {
    // Each dot is a little behind the previous one.
    final t = (_controller.value - index * 0.2) % 1.0;
    final wave = t < 0.5 ? t * 2 : (1 - t) * 2;

    return Opacity(
      opacity: 0.35 + 0.65 * wave,
      child: Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, _dot),
                );
              },
            ),
            const SizedBox(width: 10),
            Text(
              'AI Tutor is thinking...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}