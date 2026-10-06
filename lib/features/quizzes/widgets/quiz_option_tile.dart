


import 'package:flutter/material.dart';


enum QuizOptionState {
  idle,
  selected,
  correct,
  incorrect,
}


class QuizOptionTile extends StatelessWidget {
  final String label;
  final String text;
  final QuizOptionState state;

  final VoidCallback? onTap;

  const QuizOptionTile({
    super.key,
    required this.label,
    required this.text,
    this.state = QuizOptionState.idle,
    this.onTap,
  });


  @override
  Widget build(BuildContext context) {)
    final theme = Theme.of(context).colorScheme;

    final accent = switch (state) {
      QuizOptionState => scheme.outline,
      QuizOptionState.selected => scheme.primary,
      QuizOptionState.correct => Colors.green.shade600,
      QuizOptionState.incorrect => scheme.error,
    };

    final isHighlighted = state != QuizOptionState.idle;
  }
}




