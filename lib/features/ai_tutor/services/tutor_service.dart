


import '../models/chat_message.dart';
import '../models/tutor_context.dart';

/// The one seam between the app and "the thing that answers".
///
/// Today [MockTutorService] implements it. When the Node.js API exists, add
/// an HttpTutorService that POSTs to it and assign it in [TutorController].
/// Nothing else in the app needs to change.
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



