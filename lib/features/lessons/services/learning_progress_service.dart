import 'package:flutter/foundation.dart';

class LearningProgressService extends ChangeNotifier {
  LearningProgressService._();

  static final LearningProgressService instance =
      LearningProgressService._();

  final Set<String> _completedLessonIds = {};

  bool isCompleted(String lessonId) {
    return _completedLessonIds.contains(lessonId);
  }

  void markCompleted(String lessonId) {
    if (_completedLessonIds.add(lessonId)) {
      notifyListeners();
    }
  }

  void markIncomplete(String lessonId) {
    if (_completedLessonIds.remove(lessonId)) {
      notifyListeners();
    }
  }

  int completedLessons(List<String> lessonIds) {
    return lessonIds.where(_completedLessonIds.contains).length;
  }

  double progress(List<String> lessonIds) {
    if (lessonIds.isEmpty) {
      return 0;
    }

    return completedLessons(lessonIds) / lessonIds.length;
  }

  void resetProgress() {
    if (_completedLessonIds.isEmpty) {
      return;
    }

    _completedLessonIds.clear();
    notifyListeners();
  }
}