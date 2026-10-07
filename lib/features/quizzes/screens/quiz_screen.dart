import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../models/quiz_result.dart';
import '../services/quiz_progress_service.dart';
import '../widgets/quiz_progress_indicator.dart';
import '../widgets/quiz_question_card.dart';
import 'quiz_result_screen.dart';

/// Runs one quiz: question -> answer -> next ... -> submit -> results.
///
/// Answers are kept here as a list with one slot per question, which makes
/// Previous / Next simple and lets "Retry" reset by refilling the list.
class QuizScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizScreen({
    super.key,
    required this.quiz,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<String?> _answers;
  int _currentIndex = 0;

  Quiz get _quiz => widget.quiz;

  int get _totalQuestions => _quiz.questions.length;

  bool get _isLastQuestion => _currentIndex == _totalQuestions - 1;

  bool get _hasAnswers => _answers.any((answer) => answer != null);

  bool get _isCurrentAnswered => _answers[_currentIndex] != null;

  @override
  void initState() {
    super.initState();
    _answers = List<String?>.filled(_totalQuestions, null);
  }

  void _selectAnswer(String answer) {
    setState(() {
      _answers[_currentIndex] = answer;
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

  QuizResult _buildResult() {
    var correct = 0;

    for (var i = 0; i < _totalQuestions; i++) {
      if (_answers[i] == _quiz.questions[i].correctAnswer) {
        correct++;
      }
    }

    return QuizResult(
      quizId: _quiz.id,
      totalQuestions: _totalQuestions,
      correctAnswers: correct,
    );
  }

  Future<void> _submit() async {
    if (!_isCurrentAnswered) {
      return;
    }

    final result = _buildResult();

    // Saves the score, and marks the lesson complete when the quiz is passed.
    await QuizProgressService.instance.recordResult(
      result,
      lessonId: _quiz.lessonId,
    );

    if (!mounted) {
      return;
    }

    final action = await Navigator.push<QuizResultAction>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          quiz: _quiz,
          result: result,
          answers: List<String?>.unmodifiable(_answers),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (action == QuizResultAction.retry) {
      setState(() {
        _answers = List<String?>.filled(_totalQuestions, null);
        _currentIndex = 0;
      });
      return;
    }

    // "Back to Lesson", or the result screen was dismissed with Back.
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
    if (_totalQuestions == 0) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_quiz.title),
        ),
        body: const Center(
          child: Text('This quiz has no questions yet.'),
        ),
      );
    }

    final question = _quiz.questions[_currentIndex];

    return PopScope(
      // With no answers yet there is nothing to lose, so Back just works.
      canPop: !_hasAnswers,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_quiz.title),
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
                      selectedAnswer: _answers[_currentIndex],
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
                        onPressed: _currentIndex > 0 ? _goToPrevious : null,
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
                        onPressed: !_isCurrentAnswered
                            ? null
                            : (_isLastQuestion ? _submit : _goToNext),
                        icon: Icon(
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