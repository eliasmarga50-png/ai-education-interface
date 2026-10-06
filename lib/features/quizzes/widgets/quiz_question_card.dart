


import 'package:flutter/material.dart';
import '../models/quiz_question.dart';
import 'quiz_option_tile.dart';

class QuizQuestionCard extends StatelessWidget{
  final QuizQuestion question;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswerSelected;

  const QuizQuestionCard({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  });


  
}



