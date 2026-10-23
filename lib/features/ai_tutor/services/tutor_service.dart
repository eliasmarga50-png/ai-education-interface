import '../models/chat_message.dart';
import '../models/tutor_context.dart';

/// The one seam between the app and "the thing that answers".
///
/// [RemoteTutorService] (Gemini through the Node.js backend) is the default.
/// [MockTutorService] stays available for offline UI work:
///   flutter run --dart-define=USE_MOCK_TUTOR=true
abstract class TutorService {
  /// [history] is every message before [question]. [lesson] is set when the
  /// chat is about one lesson.
  ///
  /// Throws [TutorServiceException] when no answer can be produced.
  Future<String> getReply({
    required String question,
    required List<ChatMessage> history,
    TutorContext? lesson,
  });
}

/// A failure whose [message] is safe to show to the user.
class TutorServiceException implements Exception {
  final String message;

  const TutorServiceException(this.message);

  @override
  String toString() => message;
}