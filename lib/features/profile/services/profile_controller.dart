import 'package:flutter/foundation.dart';

import '../models/profile.dart';

class LearningPreferences {
  final String learningGoal;
  final String preferredDifficulty;
  final bool aiAssistance;
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

class ProfileController extends ChangeNotifier {
  ProfileController._();

  static final ProfileController instance =
      ProfileController._();

  UserProfile _profile = const UserProfile(
    name: 'Elias',
    email: 'elias@example.com',
    bio: 'Learning, building, and exploring new ideas.',
    avatarUrl: '',
    enrolledCourses: 5,
    completedCourses: 1,
    learningHours: 18,
    currentStreak: 7,
  );

  LearningPreferences _preferences =
      const LearningPreferences(
    learningGoal: 'Improve my skills',
    preferredDifficulty: 'Intermediate',
    aiAssistance: true,
    dailyReminders: true,
  );

  UserProfile get profile => _profile;

  LearningPreferences get preferences => _preferences;

  void updateProfile({
    required String name,
    required String email,
    required String bio,
  }) {
    _profile = UserProfile(
      name: name,
      email: email,
      bio: bio,
      avatarUrl: _profile.avatarUrl,
      enrolledCourses: _profile.enrolledCourses,
      completedCourses: _profile.completedCourses,
      learningHours: _profile.learningHours,
      currentStreak: _profile.currentStreak,
    );

    notifyListeners();
  }

  void updatePreferences({
    String? learningGoal,
    String? preferredDifficulty,
    bool? aiAssistance,
    bool? dailyReminders,
  }) {
    _preferences = _preferences.copyWith(
      learningGoal: learningGoal,
      preferredDifficulty: preferredDifficulty,
      aiAssistance: aiAssistance,
      dailyReminders: dailyReminders,
    );

    notifyListeners();
  }
}