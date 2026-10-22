import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../models/quiz.dart';
import '../models/quiz_result.dart';
import '../services/quiz_progress_service.dart';
import '../services/quizzes_api.dart';
import '../widgets/quiz_progress_indicator.dart';
import '../widgets/quiz_question_card.dart';
import 'quiz_result_screen.dart';

/// Runs one quiz: load from the server -> question -> answer -> next ... ->
/// submit -> results.
///
/// The quiz is about [courseId], or about one of its resources when
/// [resourceId] is given. The server builds the questions from the course
/// content, grades the answers and saves the score; this screen only shows
/// the questions and sends the answers.
class QuizScreen extends StatefulWidget {
  final String courseId;
  final String? resourceId;

  /// Shown in the app bar while the quiz loads.
  final String? title;

  /// Injectable for tests; defaults to the real backend.
  final QuizzesApi? api;

  const QuizScreen({
    super.key,
    required this.courseId,
    this.resourceId,
    this.title,
    this.api,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizzesApi _api = widget.api ?? HttpQuizzesApi();

  Quiz? _quiz;
  ApiException? _error;
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<int?> _answers = const [];
  int _currentIndex = 0;
  Stopwatch _timer = Stopwatch();

  int get _totalQuestions => _quiz?.questions.length ?? 0;

  bool get _isLastQuestion => _currentIndex == _totalQuestions - 1;

  bool get _hasAnswers => _answers.any((answer) => answer != null);

  bool get _isCurrentAnswered => _answers[_currentIndex] != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final resourceId = widget.resourceId;
      final quiz = resourceId == null
          ? await _api.getCourseQuiz(widget.courseId)
          : await _api.getResourceQuiz(widget.courseId, resourceId);

      if (!mounted) {
        return;
      }

      setState(() {
        _quiz = quiz;
        _answers = List<int?>.filled(quiz.questions.length, null);
        _currentIndex = 0;
        _isLoading = false;
        _timer = Stopwatch()..start();
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(int optionIndex) {
    setState(() {
      _answers[_currentIndex] = optionIndex;
    });
  }

  void _goToPrevious() {
    if (_currentIndex == 0) {
      return;
    }

    setState(() {
      _currentIndex--;
    });
  }

  void _goToNext() {
    if (!_isCurrentAnswered || _isLastQuestion) {
      return;
    }

    setState(() {
      _currentIndex++;
    });
  }

  Future<void> _submit() async {
    final quiz = _quiz;

    if (quiz == null || _isSubmitting || _answers.any((a) => a == null)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final QuizResult result;

    try {
      result = await _api.submitAttempt(
        quiz.id,
        answers: {
          for (var i = 0; i < quiz.questions.length; i++)
            quiz.questions[i].id: _answers[i]!,
        },
        durationSeconds: _timer.elapsed.inSeconds,
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    }

    // The score is saved on the server; fetch the updated totals for the app.
    QuizProgressService.instance.refresh();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    final action = await Navigator.push<QuizResultAction>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          quizTitle: quiz.title,
          result: result,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (action == QuizResultAction.retry) {
      setState(() {
        _answers = List<int?>.filled(quiz.questions.length, null);
        _currentIndex = 0;
        _timer = Stopwatch()..start();
      });
      return;
    }

    // "Done", or the result screen was dismissed with Back.
    Navigator.pop(context);
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) {
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Leave quiz?'),
          content: const Text(
            'Your answers so far will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Going'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;
    final title = quiz?.title ?? widget.title ?? 'Quiz';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Semantics(
            label: 'Preparing your quiz',
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_error != null || quiz == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AppErrorState(
          title: "Couldn't load the quiz",
          message: _error?.message ?? 'Something went wrong.',
          onRetry: _load,
        ),
      );
    }

    if (_totalQuestions == 0) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(
          child: Text('This quiz has no questions yet.'),
        ),
      );
    }

    final question = quiz.questions[_currentIndex];

    return PopScope(
      // With no answers yet there is nothing to lose, so Back just works.
      canPop: !_hasAnswers || _isSubmitting,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: QuizProgressIndicator(
                  currentQuestion: _currentIndex + 1,
                  totalQuestions: _totalQuestions,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: QuizQuestionCard(
                      key: ValueKey(question.id),
                      question: question,
                      selectedIndex: _answers[_currentIndex],
                      onAnswerSelected: _selectAnswer,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _currentIndex > 0 && !_isSubmitting
                            ? _goToPrevious
                            : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: !_isCurrentAnswered || _isSubmitting
                            ? null
                            : (_isLastQuestion ? _submit : _goToNext),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isLastQuestion
                                    ? Icons.check
                                    : Icons.arrow_forward,
                              ),
                        label: Text(_isLastQuestion ? 'Submit' : 'Next'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}