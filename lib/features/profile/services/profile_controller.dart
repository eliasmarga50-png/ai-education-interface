


import 'package:flutter/foundation.dart';
import '../models/profile.dart';

class LearningPreferences {
  final String learningGoal;
  final String preferredDifficulty;
  final String aiAssistance;
  final bool dailyReminders;


  const LearningPreferences({
    required this.learningGoal,
    required this.preferredDifficulty,
    required this.aiAssistance,
    required this.dailyReminders,
  });

  LearningPreferences copyWith({
    String? learningGoal,
    String? preferredDifficulty,
    bool? aiAssistance,
    bool? dailyReminders,
  }) {
    return LearningPreferences(
      learningGoal: learningGoal ?? this.learningGoal,
      preferredDifficulty: 
            preferredDifficulty ?? this.preferredDifficulty,
      aiAssistance: aiAssistance ?? this.aiAssistance,
      dailyReminders: dailyReminders ?? this.dailyReminders,
    );
  }
}



