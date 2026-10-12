import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/validation/validators.dart';
import '../models/profile.dart';
import 'avatar_storage.dart';

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

/// The profile of the signed-in account.
///
/// Ownership rules:
/// - AuthController calls [bindToUser] after every sign-in / session restore and
///   [unbind] on logout or an expired session. Nobody else can be shown or edited.
/// - Everything is stored under the account's id, so two accounts on one device
///   never see each other's name, bio or photo.
/// - The email always comes from the account (it is the login identity and the
///   server owns it), so it can't be edited here.
/// - The backend has no profile endpoints yet: name, bio and photo are stored on
///   this device only.
class ProfileController extends ChangeNotifier {
  ProfileController._();

  @visibleForTesting
  ProfileController.forTesting();

  static final ProfileController instance = ProfileController._();

  // Keys of the old, account-less storage (migrated once, see _migrateLegacy).
  static const _legacyName = 'profile_name';
  static const _legacyEmail = 'profile_email';
  static const _legacyBio = 'profile_bio';
  static const _legacyAvatar = 'profile_avatar';

  static String _key(String userId, String field) =>
      'profile.v2.$userId.$field';

  static const UserProfile _empty = UserProfile(
    name: '',
    email: '',
    bio: '',
    avatarUrl: '',
    enrolledCourses: 5,
    completedCourses: 1,
    learningHours: 18,
    currentStreak: 7,
  );

  UserProfile _profile = _empty;
  String? _userId;
  int _generation = 0;

  LearningPreferences _preferences = const LearningPreferences(
    learningGoal: 'Improve my skills',
    preferredDifficulty: 'Intermediate',
    aiAssistance: true,
    dailyReminders: true,
  );

  UserProfile get profile => _profile;
  LearningPreferences get preferences => _preferences;

  /// True while a signed-in account owns the profile.
  bool get isBound => _userId != null;
  String? get boundUserId => _userId;

  /// Kept for main.dart. Nothing is loaded here any more: the profile belongs
  /// to an account, so it is loaded by [bindToUser] after sign-in.
  Future<void> initialize() async {}

  /// Loads (or creates) the profile of [userId]. [name] and [email] come from
  /// the account; a name the user edited on this device takes precedence.
  Future<void> bindToUser({
    required String userId,
    required String name,
    required String email,
  }) async {
    final generation = ++_generation;
    final prefs = await SharedPreferences.getInstance();

    await _migrateLegacy(prefs, userId, email);

    final storedName = prefs.getString(_key(userId, 'name'))?.trim() ?? '';
    final bio = prefs.getString(_key(userId, 'bio')) ?? '';
    var avatar =
        kIsWeb ? '' : (prefs.getString(_key(userId, 'avatar')) ?? '');
    if (avatar.isNotEmpty && !await avatarFileExists(avatar)) {
      avatar = '';
    }

    // Another sign-in / logout happened while we were reading.
    if (generation != _generation) {
      return;
    }

    _userId = userId;
    _profile = UserProfile(
      name: storedName.isNotEmpty ? storedName : name,
      email: email,
      bio: bio,
      avatarUrl: avatar,
      enrolledCourses: _empty.enrolledCourses,
      completedCourses: _empty.completedCourses,
      learningHours: _empty.learningHours,
      currentStreak: _empty.currentStreak,
    );
    notifyListeners();
  }

  /// Forgets the in-memory profile (logout, expired session). The saved data
  /// stays on disk under the account's id for its next sign-in.
  void unbind() {
    _generation++;
    _userId = null;
    _profile = _empty;
    notifyListeners();
  }

  /// Saves name and bio of the bound account. Returns false when nobody is
  /// signed in or the name is invalid; nothing is changed in that case.
  Future<bool> updateProfile({
    required String name,
    required String bio,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return false;
    }

    final cleanName = Validators.normalizeName(name);
    if (Validators.name(cleanName) != null) {
      return false;
    }

    final cleanBio = bio.trim();
    if (cleanBio.length > 160) {
      return false;
    }

    final generation = _generation;
    final prefs = await SharedPreferences.getInstance();
    if (generation != _generation) {
      return false;
    }

    await prefs.setString(_key(userId, 'name'), cleanName);
    await prefs.setString(_key(userId, 'bio'), cleanBio);

    _profile = _copy(name: cleanName, bio: cleanBio);
    notifyListeners();
    return true;
  }

  /// Stores a picked photo permanently for the bound account.
  Future<bool> updateAvatar(String sourcePath) async {
    final userId = _userId;
    if (userId == null || sourcePath.isEmpty) {
      return false;
    }

    final generation = _generation;
    final String saved;
    try {
      saved = await saveAvatarFile(sourcePath: sourcePath, userId: userId);
    } catch (_) {
      return false;
    }

    if (generation != _generation) {
      // The user logged out while the file was being copied.
      await deleteAvatarFile(saved);
      return false;
    }

    final previous = _profile.avatarUrl;
    final prefs = await SharedPreferences.getInstance();
    if (!kIsWeb) {
      await prefs.setString(_key(userId, 'avatar'), saved);
    }

    _profile = _copy(avatarUrl: saved);
    notifyListeners();

    if (previous.isNotEmpty && previous != saved) {
      await deleteAvatarFile(previous);
    }
    return true;
  }

  Future<bool> removeAvatar() async {
    final userId = _userId;
    if (userId == null) {
      return false;
    }

    final previous = _profile.avatarUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId, 'avatar'));

    _profile = _copy(avatarUrl: '');
    notifyListeners();

    if (previous.isNotEmpty) {
      await deleteAvatarFile(previous);
    }
    return true;
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

  // ── Private helpers ───────────────────────────────────────────────────────

  UserProfile _copy({String? name, String? bio, String? avatarUrl}) {
    return UserProfile(
      name: name ?? _profile.name,
      email: _profile.email,
      bio: bio ?? _profile.bio,
      avatarUrl: avatarUrl ?? _profile.avatarUrl,
      enrolledCourses: _profile.enrolledCourses,
      completedCourses: _profile.completedCourses,
      learningHours: _profile.learningHours,
      currentStreak: _profile.currentStreak,
    );
  }

  /// Earlier versions kept one profile for the whole device. It is handed to
  /// the account whose email matches, once, and then removed. If the email
  /// does not match, the old data is left alone for its real owner.
  Future<void> _migrateLegacy(
    SharedPreferences prefs,
    String userId,
    String email,
  ) async {
    final legacyEmail = prefs.getString(_legacyEmail);
    if (legacyEmail == null ||
        legacyEmail.trim().toLowerCase() != email.trim().toLowerCase()) {
      return;
    }

    if (!prefs.containsKey(_key(userId, 'name'))) {
      final name = prefs.getString(_legacyName) ?? '';
      if (name.trim().isNotEmpty) {
        await prefs.setString(_key(userId, 'name'), name.trim());
      }
    }
    if (!prefs.containsKey(_key(userId, 'bio'))) {
      await prefs.setString(_key(userId, 'bio'), prefs.getString(_legacyBio) ?? '');
    }
    final avatar = prefs.getString(_legacyAvatar) ?? '';
    if (avatar.isNotEmpty && !prefs.containsKey(_key(userId, 'avatar'))) {
      await prefs.setString(_key(userId, 'avatar'), avatar);
    }

    for (final key in [_legacyName, _legacyEmail, _legacyBio, _legacyAvatar]) {
      await prefs.remove(key);
    }
  }
}