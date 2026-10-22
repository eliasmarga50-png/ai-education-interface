import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/quiz.dart';
import '../models/quiz_performance.dart';
import '../models/quiz_result.dart';

/// One method per quiz endpoint of the course-service. No state, no UI.
abstract class QuizzesApi {
  Future<Quiz> getCourseQuiz(String courseId);

  Future<Quiz> getResourceQuiz(String courseId, String resourceId);

  Future<List<QuizSummary>> listCourseQuizzes(String courseId);

  /// [answers] holds, for each question id, the index of the chosen option.
  Future<QuizResult> submitAttempt(
    String quizId, {
    required Map<String, int> answers,
    int? durationSeconds,
  });

  Future<QuizPerformance> getPerformance();
}

class HttpQuizzesApi implements QuizzesApi {
  HttpQuizzesApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static const ApiException _invalidResponse = ApiException(
    code: 'INVALID_RESPONSE',
    message: 'The server sent an unexpected response. Please try again.',
  );

  Future<Map<String, dynamic>> _get(String path) {
    return _client.get(
      path,
      auth: true,
      baseUrl: ApiConfig.coursesBaseUrl,
    );
  }

  /// A malformed answer becomes an [ApiException] with a safe message.
  T _parse<T>(T Function() read) {
    try {
      return read();
    } catch (_) {
      throw _invalidResponse;
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> body) {
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  String _id(String value) => Uri.encodeComponent(value);

  @override
  Future<Quiz> getCourseQuiz(String courseId) async {
    final body = await _get('/api/courses/${_id(courseId)}/quiz');
    return _parse(() => Quiz.fromJson(_data(body)));
  }

  @override
  Future<Quiz> getResourceQuiz(String courseId, String resourceId) async {
    final body = await _get(
      '/api/courses/${_id(courseId)}/resources/${_id(resourceId)}/quiz',
    );
    return _parse(() => Quiz.fromJson(_data(body)));
  }

  @override
  Future<List<QuizSummary>> listCourseQuizzes(String courseId) async {
    final body = await _get('/api/courses/${_id(courseId)}/quizzes');
    return _parse(
      () => (body['data'] as List)
          .whereType<Map>()
          .map((q) => QuizSummary.fromJson(Map<String, dynamic>.from(q)))
          .toList(),
    );
  }

  @override
  Future<QuizResult> submitAttempt(
    String quizId, {
    required Map<String, int> answers,
    int? durationSeconds,
  }) async {
    final body = await _client.post(
      '/api/quizzes/${_id(quizId)}/attempts',
      auth: true,
      baseUrl: ApiConfig.coursesBaseUrl,
      body: {
        'answers': [
          for (final entry in answers.entries)
            {'questionId': entry.key, 'selectedIndex': entry.value},
        ],
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
      },
    );
    return _parse(() => QuizResult.fromJson(_data(body)));
  }

  @override
  Future<QuizPerformance> getPerformance() async {
    final body = await _get('/api/quizzes/performance');
    return _parse(() => QuizPerformance.fromJson(_data(body)));
  }
}