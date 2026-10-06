


import 'quiz_question.dart';

class Quiz {
  final String id;
  final String title;
  final String description;
  final String lessonId;
  final List<QuizQuestion> questions;

  const Quiz ({
    required this.id,
    required this.title,
    required this.description,
    required this.lessonId,
    required this.questions,
  }); 
}





