import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/services/auth_controller.dart';
import '../models/quiz_performance.dart';
import '../models/quiz_result.dart';
import 'quizzes_api.dart';

/// The student's quiz results for the whole app.
///
/// The scores are calculated and saved by the backend; this class only holds
/// the latest copy the server sent so Home, Profile, Courses and the quiz list
/// can show it. Results are never kept on the device, and a copy that belongs
/// to a different signed-in student is ignored.
class QuizProgressService extends ChangeNotifier {
  QuizProgressService._({QuizzesApi? api}) : _api = api ?? HttpQuizzesApi();

  static final QuizProgressService instance = QuizProgressService._();

  /// Same behaviour with a fake API, for tests.
  @visibleForTesting
  QuizProgressService.forTesting(QuizzesApi api) : _api = api;

  final QuizzesApi _api;

  QuizPerformance? _performance;
  String? _ownerId;
  bool _isLoading = false;
  ApiException? _error;
  Future<void>? _inFlight;

  String? get _currentUserId => AuthController.instance.currentUser?.id;

  QuizPerformance get performance {
    final current = _performance;
    if (current == null || _ownerId == null || _ownerId != _currentUserId) {
      return QuizPerformance.empty;
    }
    return current;
  }

  bool get isLoading => _isLoading;

  /// The last refresh failure, or null.
  ApiException? get error => _error;

  int get totalQuizzes => performance.totalQuizzes;

  int get quizzesPassed => performance.quizzesPassed;

  int get totalAttempts => performance.totalAttempts;

  double get averageBestPercentage => performance.averageBestScore ?? 0;

  Understanding? get understanding => performance.understanding;

  ScopePerformance? scopeFor(String courseId, String? resourceId) {
    return performance.scopeFor(courseId, resourceId);
  }

  CoursePerformance? courseFor(String courseId) {
    return performance.courseFor(courseId);
  }

  /// Loads the student's results from the server. One request at a time.
  Future<void> refresh() {
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<void> _load() async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fresh = await _api.getPerformance();
      _performance = fresh;
      _ownerId = userId;
    } on ApiException catch (e) {
      _error = e;
    } catch (_) {
      _error = const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'The server sent an unexpected response. Please try again.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}