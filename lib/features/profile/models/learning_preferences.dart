/// The student's learning settings.
///
/// The server keeps them (PATCH /api/profile/preferences) and validates the
/// same values as below; the device keeps a copy so the app opens offline.
class LearningPreferences {
  static const List<String> goals = [
    'Improve my skills',
    'Learn a new skill',
    'Prepare for a career',
    'Prepare for exams',
  ];

  static const List<String> difficulties = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  static const int minDailyGoalMinutes = 5;
  static const int maxDailyGoalMinutes = 240;

  final String learningGoal;
  final String preferredDifficulty;
  final bool aiAssistance;
  final bool dailyReminders;
  final int dailyGoalMinutes;

  const LearningPreferences({
    required this.learningGoal,
    required this.preferredDifficulty,
    required this.aiAssistance,
    required this.dailyReminders,
    this.dailyGoalMinutes = 15,
  });

  static const LearningPreferences defaults = LearningPreferences(
    learningGoal: 'Improve my skills',
    preferredDifficulty: 'Intermediate',
    aiAssistance: true,
    dailyReminders: true,
    dailyGoalMinutes: 15,
  );

  /// A missing or unknown value falls back to its default, so a bad reply can
  /// never put a value in a dropdown that it does not offer.
  factory LearningPreferences.fromJson(Map<String, dynamic> json) {
    final goal = json['learningGoal'];
    final level = json['preferredDifficulty'];
    final ai = json['aiAssistance'];
    final reminders = json['dailyReminders'];
    final minutes = json['dailyGoalMinutes'];

    return LearningPreferences(
      learningGoal:
          goal is String && goals.contains(goal) ? goal : defaults.learningGoal,
      preferredDifficulty: level is String && difficulties.contains(level)
          ? level
          : defaults.preferredDifficulty,
      aiAssistance: ai is bool ? ai : defaults.aiAssistance,
      dailyReminders: reminders is bool ? reminders : defaults.dailyReminders,
      dailyGoalMinutes: minutes is num &&
              minutes >= minDailyGoalMinutes &&
              minutes <= maxDailyGoalMinutes
          ? minutes.toInt()
          : defaults.dailyGoalMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learningGoal': learningGoal,
      'preferredDifficulty': preferredDifficulty,
      'aiAssistance': aiAssistance,
      'dailyReminders': dailyReminders,
      'dailyGoalMinutes': dailyGoalMinutes,
    };
  }

  LearningPreferences copyWith({
    String? learningGoal,
    String? preferredDifficulty,
    bool? aiAssistance,
    bool? dailyReminders,
    int? dailyGoalMinutes,
  }) {
    return LearningPreferences(
      learningGoal: learningGoal ?? this.learningGoal,
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      aiAssistance: aiAssistance ?? this.aiAssistance,
      dailyReminders: dailyReminders ?? this.dailyReminders,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
    );
  }

  /// Only the fields that differ from [other], in the shape the server expects.
  Map<String, dynamic> changesTo(LearningPreferences other) {
    return {
      if (other.learningGoal != learningGoal)
        'learningGoal': other.learningGoal,
      if (other.preferredDifficulty != preferredDifficulty)
        'preferredDifficulty': other.preferredDifficulty,
      if (other.aiAssistance != aiAssistance)
        'aiAssistance': other.aiAssistance,
      if (other.dailyReminders != dailyReminders)
        'dailyReminders': other.dailyReminders,
      if (other.dailyGoalMinutes != dailyGoalMinutes)
        'dailyGoalMinutes': other.dailyGoalMinutes,
    };
  }
}