import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/chat_message.dart';
import '../models/tutor_context.dart';
import 'tutor_service.dart';

/// Real answers from Gemini.
///
/// The app never talks to Google directly (that would put the API key inside
/// the app). The chain is:
///   app -> Node.js backend  POST /api/tutor/reply   (login required)
///       -> ai-service       POST /v1/tutor/reply    (internal key)
///       
///
/// Only the question, recent messages and the lesson / course titles are sent.
/// Errors come back as [TutorServiceException] with a message that is safe to
/// show, so [TutorController] and the existing "Try again" banner need no change.
class RemoteTutorService implements TutorService {
  RemoteTutorService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  // Match the limits enforced by the backend and the ai-service.
  static const int maxQuestionLength = 2000;
  static const int _maxHistoryMessages = 12;
  static const int _maxHistoryTextLength = 4000;

  @override
  Future<String> getReply({
    required String question,
    required List<ChatMessage> history,
    TutorContext? lesson,
  }) async {
    final cleaned = question.trim();

    if (cleaned.isEmpty) {
      throw const TutorServiceException('Type a question first.');
    }

    if (cleaned.length > maxQuestionLength) {
      throw const TutorServiceException(
        'That question is too long. Please keep it under 2,000 characters.',
      );
    }

    final recent = history.length > _maxHistoryMessages
        ? history.sublist(history.length - _maxHistoryMessages)
        : history;

    final body = <String, dynamic>{
      'question': cleaned,
      'history': [
        for (final message in recent)
          if (message.text.trim().isNotEmpty)
            {
              'role': message.isUser ? 'user' : 'tutor',
              'text': _clip(message.text.trim(), _maxHistoryTextLength),
            },
      ],
      if (lesson != null)
        'lesson': {
          'title': lesson.lessonTitle,
          'course': lesson.courseTitle,
        },
    };

    final Map<String, dynamic> data;

    try {
      data = await _client.post(
        '/api/tutor/reply',
        body: body,
        auth: true,
        timeout: ApiConfig.aiTimeout,
      );
    } on ApiException catch (error) {
      throw TutorServiceException(error.message);
    }

    final reply = data['reply'];

    if (reply is String && reply.trim().isNotEmpty) {
      return reply.trim();
    }

    throw const TutorServiceException(
      'The tutor returned an empty answer. Please try again.',
    );
  }

  String _clip(String text, int max) {
    return text.length <= max ? text : text.substring(0, max);
  }
}