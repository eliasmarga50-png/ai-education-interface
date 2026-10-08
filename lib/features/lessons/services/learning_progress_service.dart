import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearningProgressService extends ChangeNotifier {
  LearningProgressService._();

  static final LearningProgressService instance =
      LearningProgressService._();

  static const String _storageKey = 'completed_lessons_v1';

  final Set<String> _completedLessonIds = {};

  /// Read-only view, used by the dashboard.
  Set<String> get completedLessonIds {
    return Set.unmodifiable(_completedLessonIds);
  }

  /// Loads saved progress. Call once before runApp.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_storageKey);

      if (saved != null) {
        _completedLessonIds.addAll(saved);
      }
    } catch (error) {
      debugPrint('LEARNING PROGRESS → could not load: $error');
    }

    notifyListeners();
  }

  bool isCompleted(String lessonId) {
    return _completedLessonIds.contains(lessonId);
  }

  void markCompleted(String lessonId) {
    if (_completedLessonIds.add(lessonId)) {
      notifyListeners();
      unawaited(_save());
    }
  }

  void markIncomplete(String lessonId) {
    if (_completedLessonIds.remove(lessonId)) {
      notifyListeners();
      unawaited(_save());
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
    unawaited(_save());
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setStringList(
        _storageKey,
        _completedLessonIds.toList(),
      );
    } catch (error) {
      debugPrint('LEARNING PROGRESS → could not save: $error');
    }
  }
}