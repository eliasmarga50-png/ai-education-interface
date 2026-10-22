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

    // Quizzes are built by the backend from the course resources, so the
    // tutor points to them instead of asking its own questions.
    if (_hasAny(text, ['quiz me', 'practice', 'test me', 'test my'])) {
      return 'Quizzes are made from the course and its learning resources. '
          'Open the course, use a resource, then tap “Take quiz” to see how '
          'well you understood it. I can explain anything you miss.';
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
}