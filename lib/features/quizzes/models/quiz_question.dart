/// One question as the server sends it. The correct answer is not included:
/// it only comes back after the quiz is submitted (see [ReviewItem]).
class QuizQuestion {
  final String id;
  final int position;
  final String prompt;
  final List<String> options;

  /// What to revisit when this question is missed.
  final String topic;

  const QuizQuestion({
    required this.id,
    required this.position,
    required this.prompt,
    required this.options,
    required this.topic,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      position: (json['position'] as num?)?.toInt() ?? 0,
      prompt: json['prompt'] as String,
      options: (json['options'] as List).whereType<String>().toList(),
      topic: json['topic'] as String? ?? '',
    );
  }
}