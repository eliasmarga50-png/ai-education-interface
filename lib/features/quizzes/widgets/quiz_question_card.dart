


import 'package:flutter/material.dart';

import '../models/quiz_question.dart';
import 'quiz_option_tile.dart';

/// One question with its tappable answer options.
///
/// This widget holds no state: the quiz screen owns the selected answer and
/// passes it back in, which is what lets Previous / Next restore answers.
class QuizQuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswerSelected;

  const QuizQuestionCard({
    super.key,
    required this.question,
    required this.selectedAnswer,
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
              question.question,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 20),
            ...question.options.asMap().entries.map((entry) {
              final option = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QuizOptionTile(
                  label: String.fromCharCode(65 + entry.key),
                  text: option,
                  state: option == selectedAnswer
                      ? QuizOptionState.selected
                      : QuizOptionState.idle,
                  onTap: () => onAnswerSelected(option),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}



