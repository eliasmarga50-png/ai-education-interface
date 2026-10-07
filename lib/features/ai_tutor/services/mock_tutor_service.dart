



import '../../quizzes/data/mock_quiz_data.dart';
import '../../quizzes/models/quiz.dart';
import '../../quizzes/models/quiz_question.dart';
import '../data/tutor_data.dart';
import '../models/chat_message.dart';
import '../models/tutor_context.dart';
import 'tutor_service.dart';

/// Canned answers with a short delay, so the loading and error states can be
/// built and tested before a backend exists.
class MockTutorService implements TutorService {
  final Set<String> _failedOnce = {};

  @override
  Future<String> getReply({
    required String question,
    required List<ChatMessage> history,
    TutorContext? lesson,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // Testing aid: put /fail in a question to see the error state. The first
    // attempt fails; tapping "Try again" succeeds.
    if (question.contains('/fail') && _failedOnce.add(question)) {
      throw const TutorServiceException(
        'I could not reach the tutor right now. '
        'Check your connection and try again.',
      );
    }

    final cleaned = question.replaceAll('/fail', '').trim();

    if (lesson != null) {
      return _lessonReply(cleaned, history, lesson);
    }

    return TutorData.responseFor(cleaned);
  }

  // ---------------------------------------------------------------------
  // Lesson-specific answers
  // ---------------------------------------------------------------------

  String _lessonReply(
    String question,
    List<ChatMessage> history,
    TutorContext lesson,
  ) {
    final text = question.toLowerCase();
    final quiz = MockQuizData.quizForLesson(lesson.lessonId);

    // A reply to a practice question comes first so "B" is graded, not
    // treated as a new topic.
    if (quiz != null) {
      final graded = _gradePracticeAnswer(text, history, quiz);

      if (graded != null) {
        return graded;
      }

      if (_hasAny(text, ['quiz me', 'practice', 'test me', 'test my'])) {
        return _practiceQuestion(history, quiz);
      }
    }

    if (_hasAny(text, ['example', 'demo', 'sample'])) {
      return TutorData.lessonExample(lesson);
    }

    if (_hasAny(text, ['summar', 'key point', 'recap', 'main point'])) {
      return _summary(lesson);
    }

    if (_hasAny(text, ['why', 'matter', 'useful'])) {
      return _whyItMatters(lesson);
    }

    if (_hasAny(text, [
      'explain', 'simple', 'what is', 'what are', 'teach',
      'understand', 'help', 'confus',
    ])) {
      return _explain(lesson);
    }

    return 'Good question about “${lesson.lessonTitle}”. '
        'I can explain the lesson in simple terms, show an example, '
        'summarize the key points, or quiz you on it.\n\n'
        'Which one would help most?';
  }

  bool _hasAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  List<String> _paragraphs(String content) {
    return content
        .split('\n\n')
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();
  }

  String _firstSentence(String paragraph) {
    final end = paragraph.indexOf('. ');

    if (end == -1) {
      return paragraph;
    }

    return paragraph.substring(0, end + 1);
  }

  String _explain(TutorContext lesson) {
    final paragraphs = _paragraphs(lesson.content).take(2).join('\n\n');

    return 'Let’s break down “${lesson.lessonTitle}” '
        'from ${lesson.courseTitle}.\n\n'
        '$paragraphs\n\n'
        'Want an example, the key points, or a practice question?';
  }

  String _summary(TutorContext lesson) {
    final points = <String>[lesson.description];

    for (final paragraph in _paragraphs(lesson.content)) {
      final sentence = _firstSentence(paragraph);

      if (!points.contains(sentence)) {
        points.add(sentence);
      }
    }

    final bullets = points.map((point) => '• $point').join('\n');

    return 'Key points from “${lesson.lessonTitle}”:\n\n$bullets';
  }

  String _whyItMatters(TutorContext lesson) {
    return 'Why “${lesson.lessonTitle}” matters:\n\n'
        '${lesson.description}\n\n'
        'It is a building block in ${lesson.courseTitle}, and later '
        'lessons assume you are comfortable with it. A practice question '
        'is a good way to check your understanding.';
  }

  String _practiceQuestion(List<ChatMessage> history, Quiz quiz) {
    final alreadyAsked = history
        .where((m) => m.isAi && m.text.contains('Practice question'))
        .length;

    final index = alreadyAsked % quiz.questions.length;
    final question = quiz.questions[index];

    final options = question.options
        .asMap()
        .entries
        .map((e) => '${String.fromCharCode(65 + e.key)}) ${e.value}')
        .join('\n');

    return 'Practice question ${index + 1} of ${quiz.questions.length}:\n\n'
        '${question.question}\n\n'
        '$options\n\n'
        'Reply with a letter (A–D), or ask me to show the answer.';
  }

  /// If the previous tutor message was a practice question and [text] looks
  /// like an answer to it, returns feedback. Otherwise null.
  String? _gradePracticeAnswer(
    String text,
    List<ChatMessage> history,
    Quiz quiz,
  ) {
    ChatMessage? lastAi;

    for (final message in history.reversed) {
      if (message.isAi) {
        lastAi = message;
        break;
      }
    }

    if (lastAi == null || !lastAi.text.contains('Practice question')) {
      return null;
    }

    QuizQuestion? asked;

    for (final question in quiz.questions) {
      if (lastAi.text.contains(question.question)) {
        asked = question;
        break;
      }
    }

    if (asked == null) {
      return null;
    }

    final reply = text.trim();
    String? chosen;

    final letter = RegExp(r'^\(?([a-d])\)?[.)]?$').firstMatch(reply);

    if (letter != null) {
      final index = letter.group(1)!.codeUnitAt(0) - 97;

      if (index < asked.options.length) {
        chosen = asked.options[index];
      }
    } else {
      for (final option in asked.options) {
        if (reply == option.toLowerCase()) {
          chosen = option;
        }
      }
    }

    if (chosen == null) {
      if (_hasAny(reply, ['answer', 'reveal', 'solution', 'give up'])) {
        return 'The correct answer is “${asked.correctAnswer}”.\n\n'
            'Want another practice question?';
      }

      return null;
    }

    if (chosen == asked.correctAnswer) {
      return 'Correct! ✅ “${asked.correctAnswer}” is right.\n\n'
          'Want another practice question?';
    }

    return 'Not quite. You chose “$chosen”, but the correct answer is '
        '“${asked.correctAnswer}”.\n\n'
        'Want another practice question?';
  }
}





