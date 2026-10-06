


import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../models/quiz_result.dart';
import '../widgets/quiz_option_tile.dart';


enum QuizResultAction {
  retry,
  finish,
}


class QuizResultScreen extends StatefulWidget{
  final Quiz quiz;
  final QuizResult result;

  final List<String> answers;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.result,
    required this.answers,
  });
}



