import 'package:flutter/material.dart';

import '../models/quiz_question.dart';
import 'quiz_option_tile.dart';

/// One question with its tappable answer options.
///
/// This widget holds no state: the quiz screen owns the selected option and
/// passes it back in, which is what lets Previous / Next restore answers.
/// Answers are the position of the option in [QuizQuestion.options], which is
/// exactly what the server expects when the quiz is submitted.
class QuizQuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final int? selectedIndex;
  final ValueChanged<int> onAnswerSelected;

  const QuizQuestionCard({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.prompt,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 20),
            for (final entry in question.options.asMap().entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QuizOptionTile(
                  label: String.fromCharCode(65 + entry.key),
                  text: entry.value,
                  state: entry.key == selectedIndex
                      ? QuizOptionState.selected
                      : QuizOptionState.idle,
                  onTap: () => onAnswerSelected(entry.key),
                ),
              ),
          ],
        ),
      ),
    );
  }
}