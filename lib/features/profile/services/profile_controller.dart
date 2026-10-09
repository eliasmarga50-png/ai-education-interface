import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static final ProfileController instance = ProfileController._();

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kName   = 'profile_name';
  static const _kEmail  = 'profile_email';
  static const _kBio    = 'profile_bio';
  // Avatar is NOT persisted across reloads on web because blob: URLs are
  // session-scoped. On native we store the file path.
  static const _kAvatar = 'profile_avatar';

  UserProfile _profile = const UserProfile(
    name: '',
    email: '',
    bio: '',
    avatarUrl: '',
    enrolledCourses: 5,
    completedCourses: 1,
    learningHours: 18,
    currentStreak: 7,
  );

  LearningPreferences _preferences = const LearningPreferences(
    learningGoal: 'Improve my skills',
    preferredDifficulty: 'Intermediate',
    aiAssistance: true,
    dailyReminders: true,
  );

  UserProfile get profile => _profile;
  LearningPreferences get preferences => _preferences;

  /// Call once at app startup (after [WidgetsFlutterBinding.ensureInitialized]).
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final name   = prefs.getString(_kName)  ?? '';
    final email  = prefs.getString(_kEmail) ?? '';
    final bio    = prefs.getString(_kBio)   ?? '';
    // On web, blob URLs are session-scoped so we don't restore them.
    final avatar = kIsWeb ? '' : (prefs.getString(_kAvatar) ?? '');

    _profile = UserProfile(
      name:             name,
      email:            email,
      bio:              bio,
      avatarUrl:        avatar,
      enrolledCourses:  _profile.enrolledCourses,
      completedCourses: _profile.completedCourses,
      learningHours:    _profile.learningHours,
      currentStreak:    _profile.currentStreak,
    );

    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String email,
    required String bio,
  }) {
    _profile = UserProfile(
      name:             name,
      email:            email,
      bio:              bio,
      avatarUrl:        _profile.avatarUrl,
      enrolledCourses:  _profile.enrolledCourses,
      completedCourses: _profile.completedCourses,
      learningHours:    _profile.learningHours,
      currentStreak:    _profile.currentStreak,
    );

    notifyListeners();
    _persist();
  }

  void updateAvatar(String avatarPath) {
    _profile = UserProfile(
      name:             _profile.name,
      email:            _profile.email,
      bio:              _profile.bio,
      avatarUrl:        avatarPath,
      enrolledCourses:  _profile.enrolledCourses,
      completedCourses: _profile.completedCourses,
      learningHours:    _profile.learningHours,
      currentStreak:    _profile.currentStreak,
    );

    notifyListeners();
    _persistAvatar(avatarPath);
  }

  void removeAvatar() {
    _profile = UserProfile(
      name:             _profile.name,
      email:            _profile.email,
      bio:              _profile.bio,
      avatarUrl:        '',
      enrolledCourses:  _profile.enrolledCourses,
      completedCourses: _profile.completedCourses,
      learningHours:    _profile.learningHours,
      currentStreak:    _profile.currentStreak,
    );

    notifyListeners();
    _persistAvatar('');
  }

  void updatePreferences({
    String? learningGoal,
    String? preferredDifficulty,
    bool? aiAssistance,
    bool? dailyReminders,
  }) {
    _preferences = _preferences.copyWith(
      learningGoal:        learningGoal,
      preferredDifficulty: preferredDifficulty,
      aiAssistance:        aiAssistance,
      dailyReminders:      dailyReminders,
    );

    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName,  _profile.name);
    await prefs.setString(_kEmail, _profile.email);
    await prefs.setString(_kBio,   _profile.bio);
  }

  Future<void> _persistAvatar(String path) async {
    if (kIsWeb) return; // Blob URLs are session-scoped; don't persist them.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAvatar, path);
  }
}