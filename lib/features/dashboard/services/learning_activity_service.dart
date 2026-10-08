import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One lesson the user opened, newest first in [LearningActivityService].
class RecentLessonEntry {
  final String lessonId;
  final DateTime openedAt;

  const RecentLessonEntry({
    required this.lessonId,
    required this.openedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'openedAt': openedAt.toIso8601String(),
    };
  }

  factory RecentLessonEntry.fromJson(Map<String, dynamic> json) {
    return RecentLessonEntry(
      lessonId: json['lessonId'] as String,
      openedAt: DateTime.parse(json['openedAt'] as String),
    );
  }
}

/// Records when and how long the user studies. This is the source of the
/// streak, the learning time and the "recent lessons" list on Home.
///
/// A day counts as active when the user opens a lesson, takes a quiz or
/// talks to the AI Tutor. Learning time is the time a lesson screen was open
/// while the app was in the foreground.
class LearningActivityService extends ChangeNotifier {
  LearningActivityService._();

  static final LearningActivityService instance =
      LearningActivityService._();

  static const String _storageKey = 'learning_activity_v1';
  static const int _maxRecent = 10;

  /// One lesson session never counts for more than this, so leaving a lesson
  /// open overnight does not inflate the numbers.
  static const int _maxSessionSeconds = 30 * 60;

  final Map<String, int> _secondsByDay = {};
  final Set<String> _activeDays = {};
  final List<RecentLessonEntry> _recent = [];

  // ---------------------------------------------------------------------
  // Dates
  // ---------------------------------------------------------------------

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime _previousDay(DateTime date) {
    return DateTime(date.year, date.month, date.day - 1);
  }

  static String _key(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  static DateTime _parseKey(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  // ---------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------

  /// Loads saved activity. Call once before runApp.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;

        final seconds = decoded['secondsByDay'] as Map<String, dynamic>;
        seconds.forEach((day, value) {
          _secondsByDay[day] = (value as num).toInt();
        });

        _activeDays.addAll(
          (decoded['activeDays'] as List<dynamic>).cast<String>(),
        );

        _recent.addAll(
          (decoded['recent'] as List<dynamic>).map(
            (item) => RecentLessonEntry.fromJson(
              item as Map<String, dynamic>,
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('LEARNING ACTIVITY → could not load: $error');
      _secondsByDay.clear();
      _activeDays.clear();
      _recent.clear();
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Reading
  // ---------------------------------------------------------------------

  List<RecentLessonEntry> get recentLessons {
    return List.unmodifiable(_recent);
  }

  int secondsOn(DateTime day) {
    return _secondsByDay[_key(day)] ?? 0;
  }

  bool isActiveOn(DateTime day) {
    return _activeDays.contains(_key(day));
  }

  bool get activeToday => isActiveOn(DateTime.now());

  int get totalSeconds {
    return _secondsByDay.values.fold(0, (sum, value) => sum + value);
  }

  /// Consecutive active days ending today. If today is not active yet, the
  /// streak still counts up to yesterday, so it only breaks after a full
  /// missed day.
  int get currentStreak {
    final today = dateOnly(DateTime.now());
    var day = isActiveOn(today) ? today : _previousDay(today);
    var count = 0;

    while (isActiveOn(day)) {
      count++;
      day = _previousDay(day);
    }

    return count;
  }

  int get longestStreak {
    final days = _activeDays.map(_parseKey).toList()..sort();

    var longest = 0;
    var run = 0;
    DateTime? previous;

    for (final day in days) {
      if (previous != null && _previousDay(day) == previous) {
        run++;
      } else {
        run = 1;
      }

      if (run > longest) {
        longest = run;
      }

      previous = day;
    }

    return longest;
  }

  // ---------------------------------------------------------------------
  // Recording
  // ---------------------------------------------------------------------

  void recordLessonOpened(String lessonId) {
    final now = DateTime.now();

    _activeDays.add(_key(now));

    _recent.removeWhere((entry) => entry.lessonId == lessonId);
    _recent.insert(0, RecentLessonEntry(lessonId: lessonId, openedAt: now));

    if (_recent.length > _maxRecent) {
      _recent.removeRange(_maxRecent, _recent.length);
    }

    _changed();
  }

  /// Marks today as active (quiz taken, tutor used).
  void recordActivity() {
    if (_activeDays.add(_key(DateTime.now()))) {
      _changed();
    }
  }

  void addStudySeconds(int seconds) {
    if (seconds < 1) {
      return;
    }

    final capped = seconds > _maxSessionSeconds ? _maxSessionSeconds : seconds;
    final key = _key(DateTime.now());

    _secondsByDay[key] = (_secondsByDay[key] ?? 0) + capped;
    _activeDays.add(key);

    _changed();
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  /// Notifies after the current frame. Callers include initState and
  /// dispose, where notifying listeners immediately would make Home try to
  /// rebuild while the widget tree is locked.
  void _changed() {
    scheduleMicrotask(notifyListeners);
    unawaited(_save());
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final encoded = jsonEncode({
        'secondsByDay': _secondsByDay,
        'activeDays': _activeDays.toList(),
        'recent': _recent.map((entry) => entry.toJson()).toList(),
      });

      await prefs.setString(_storageKey, encoded);
    } catch (error) {
      debugPrint('LEARNING ACTIVITY → could not save: $error');
    }
  }
}