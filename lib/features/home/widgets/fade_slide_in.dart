import 'package:flutter/material.dart';

/// Fades a section in and slides it up a little. [index] staggers the start
/// so sections appear one after another instead of all at once.
class FadeSlideIn extends StatelessWidget {
  final int index;
  final Widget child;

  const FadeSlideIn({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final delayMs = index * 70;
    final totalMs = 450 + delayMs;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(
        delayMs / totalMs,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}