import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/validation/validators.dart';
import '../models/learning_preferences.dart';
import '../models/profile.dart';
import 'avatar_storage.dart';
import 'profile_api.dart';

// Existing screens import LearningPreferences from here.
export '../models/learning_preferences.dart';

/// The profile of the signed-in account.
///
/// The server (GET/PATCH /api/profile) is the source of truth for name, bio,
/// photo and learning preferences. The email comes from the account and can't
/// be edited. A copy is kept on the device, per account id, so:
/// - the screens show something at once and still work offline, and
/// - two accounts on one device never see each other's data.
///
/// Rules:
/// - AuthController calls [bindToUser] after every sign-in / session restore and
///   [unbind] on logout or an expired session.
/// - [bindToUser] returns quickly with the saved copy and refreshes from the
///   server in the background ([isLoading], [loadError], [refresh]).
/// - Every save goes to the server first. Nothing is shown as saved unless the
///   server accepted it; on failure a method returns false and [lastError]
///   holds a message that is safe to show.
class ProfileController extends ChangeNotifier {
  ProfileController._({ProfileApi? api}) : _api = api ?? ProfileApi.instance;

  @visibleForTesting
  ProfileController.forTesting({ProfileApi? api})
      : _api = api ?? ProfileApi.instance;

  static final ProfileController instance = ProfileController._();

  static const int maxBioLength = 160;
  static const int _maxAvatarBytes = 300 * 1024;
  static const String _unexpected = 'Something went wrong. Please try again.';

  // Device-only storage of earlier versions. Still read once, so nobody loses a
  // bio or photo: it is uploaded to the account and then removed.
  static const _legacyName = 'profile_name';
  static const _legacyEmail = 'profile_email';
  static const _legacyBio = 'profile_bio';
  static const _legacyAvatar = 'profile_avatar';

  static String _v2Key(String userId, String field) =>
      'profile.v2.$userId.$field';

  /// Copy of what the server sent (name, bio, preferences, photo path/version).
  static String _cacheKey(String userId) => 'profile.v3.$userId';

  static const UserProfile _empty = UserProfile(
    name: '',
    email: '',
    bio: '',
    avatarUrl: '',
  );

  final ProfileApi _api;

  UserProfile _profile = _empty;
  LearningPreferences _preferences = LearningPreferences.defaults;
  String? _userId;
  int _generation = 0;

  int? _avatarVersion;
  bool _isLoading = false;
  bool _hasSynced = false;
  bool _isUpdatingAvatar = false;
  String? _loadError;
  String? _lastError;

  Future<bool>? _refreshInFlight;
  int _refreshGeneration = -1;

  /// Called when the server's name differs from the one the app knows, so the
  /// session copy of the account (AuthController) stays in step.
  void Function(String name)? onNameChanged;

  UserProfile get profile => _profile;
  LearningPreferences get preferences => _preferences;

  /// True while a signed-in account owns the profile.
  bool get isBound => _userId != null;
  String? get boundUserId => _userId;

  /// True while the profile is being loaded from the server.
  bool get isLoading => _isLoading;

  /// True once the server has answered at least once since sign-in. Until then
  /// the screens show the saved copy from the device.
  bool get hasSynced => _hasSynced;

  /// Why the last load failed (for example no connection), or null.
  String? get loadError => _loadError;

  bool get isUpdatingAvatar => _isUpdatingAvatar;

  /// Reason for the most recent failed save.
  String? get lastError => _lastError;

  /// Kept for main.dart. Nothing is loaded here: the profile belongs to an
  /// account, so it is loaded by [bindToUser] after sign-in.
  Future<void> initialize() async {}

  // ── Sign-in / sign-out ────────────────────────────────────────────────────

  /// Shows the saved copy of [userId]'s profile at once, then loads the real
  /// one from the server. [name] and [email] come from the account.
  Future<void> bindToUser({
    required String userId,
    required String name,
    required String email,
  }) async {
    final generation = ++_generation;
    final prefs = await SharedPreferences.getInstance();

    await _migrateLegacy(prefs, userId, email);

    final cache = _readCache(prefs, userId);
    final cachedName = cache['name'];
    final legacyName = prefs.getString(_v2Key(userId, 'name'))?.trim() ?? '';
    final cachedBio = cache['bio'];
    final cachedPrefs = cache['preferences'];

    var avatar = '';
    if (!kIsWeb) {
      final cachedAvatar = cache['avatarPath'];
      avatar = cachedAvatar is String && cachedAvatar.isNotEmpty
          ? cachedAvatar
          : (prefs.getString(_v2Key(userId, 'avatar')) ?? '');
      if (avatar.isNotEmpty && !await avatarFileExists(avatar)) {
        avatar = '';
      }
    }

    // Another sign-in / logout happened while we were reading.
    if (generation != _generation) {
      return;
    }

    _userId = userId;
    _avatarVersion = (cache['avatarVersion'] as num?)?.toInt();
    _hasSynced = false;
    _isLoading = false;
    _loadError = null;
    _lastError = null;
    _isUpdatingAvatar = false;
    _profile = UserProfile(
      name: cachedName is String && cachedName.trim().isNotEmpty
          ? cachedName
          : (legacyName.isNotEmpty ? legacyName : name),
      email: email,
      bio: cachedBio is String
          ? cachedBio
          : (prefs.getString(_v2Key(userId, 'bio')) ?? ''),
      avatarUrl: avatar,
    );
    _preferences = cachedPrefs is Map
        ? LearningPreferences.fromJson(Map<String, dynamic>.from(cachedPrefs))
        : LearningPreferences.defaults;
    notifyListeners();

    unawaited(refresh());
  }

  /// Forgets the in-memory profile (logout, expired session). The saved copy
  /// stays on disk under the account's id for its next sign-in.
  void unbind() {
    _generation++;
    _userId = null;
    _avatarVersion = null;
    _hasSynced = false;
    _isLoading = false;
    _isUpdatingAvatar = false;
    _loadError = null;
    _lastError = null;
    _profile = _empty;
    _preferences = LearningPreferences.defaults;
    notifyListeners();
  }

  /// Removes everything stored on this device for [userId] (account deleted).
  Future<void> clearLocalData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final avatar = _readCache(prefs, userId)['avatarPath'];

    for (final key in [
      _cacheKey(userId),
      _v2Key(userId, 'name'),
      _v2Key(userId, 'bio'),
      _v2Key(userId, 'avatar'),
    ]) {
      await prefs.remove(key);
    }

    if (avatar is String && avatar.isNotEmpty) {
      await deleteAvatarFile(avatar);
    }
    if (_userId == userId && _profile.avatarUrl.isNotEmpty) {
      await deleteAvatarFile(_profile.avatarUrl);
    }
    if (_userId == userId) {
      unbind();
    }
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  /// Loads the profile from the server. One request at a time. Returns true
  /// when the server answered; otherwise [loadError] says why and the saved
  /// copy stays on screen.
  Future<bool> refresh() {
    if (_userId == null) {
      return Future.value(false);
    }

    final running = _refreshInFlight;
    if (running != null && _refreshGeneration == _generation) {
      return running;
    }

    _refreshGeneration = _generation;
    final future = _refresh().whenComplete(() => _refreshInFlight = null);
    _refreshInFlight = future;
    return future;
  }

  Future<bool> _refresh() async {
    final generation = _generation;
    final userId = _userId;
    if (userId == null) {
      return false;
    }

    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      var server = await _api.getProfile();
      if (generation != _generation) {
        return false;
      }

      server = await _migrateDeviceOnlyData(userId, server);
      if (generation != _generation) {
        return false;
      }

      _applyServer(server);
      await _syncAvatar(server, userId, generation);
      if (generation != _generation) {
        return false;
      }

      _hasSynced = true;
      await _saveCache(userId);
      return true;
    } on ApiException catch (e) {
      if (generation == _generation) {
        _loadError = e.message;
      }
      return false;
    } catch (_) {
      if (generation == _generation) {
        _loadError = _unexpected;
      }
      return false;
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // ── Saving ────────────────────────────────────────────────────────────────

  /// Saves name and bio to the account. Returns false when nobody is signed in,
  /// the input is invalid, or the server refused / could not be reached;
  /// read [lastError] for the reason.
  Future<bool> updateProfile({
    required String name,
    required String bio,
  }) async {
    _lastError = null;

    final userId = _userId;
    if (userId == null) {
      return _fail('Please log in again.');
    }

    final cleanName = Validators.normalizeName(name);
    final nameError = Validators.name(cleanName);
    if (nameError != null) {
      return _fail(nameError);
    }

    final cleanBio = bio.trim();
    if (cleanBio.runes.length > maxBioLength) {
      return _fail('Bio must be $maxBioLength characters or fewer.');
    }

    final generation = _generation;

    try {
      final server = await _api.updateProfile(name: cleanName, bio: cleanBio);
      if (generation != _generation) {
        return false;
      }

      _applyServer(server);
      await _saveCache(userId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      return _fail(e.message);
    } catch (_) {
      return _fail(_unexpected);
    }
  }

  /// Uploads the photo stored at [sourcePath] (a file on a phone). Returns
  /// false when the file can't be read; otherwise it works like
  /// [updateAvatarBytes].
  Future<bool> updateAvatar(String sourcePath) async {
    _lastError = null;

    try {
      final bytes = await readAvatarBytes(sourcePath);
      return await updateAvatarBytes(bytes);
    } catch (_) {
      return _fail('We could not read that photo. Please choose another one.');
    }
  }

  /// Uploads a picked photo (JPEG, PNG or WebP, up to 300 KB) and keeps a copy
  /// on the device.
  Future<bool> updateAvatarBytes(Uint8List bytes) async {
    _lastError = null;

    final userId = _userId;
    if (userId == null) {
      return _fail('Please log in again.');
    }

    final mimeType = detectImageMimeType(bytes);
    if (mimeType == null) {
      return _fail('Please choose a JPEG, PNG or WebP photo.');
    }
    if (bytes.length > _maxAvatarBytes) {
      return _fail('That photo is too large. Please choose a smaller one.');
    }
    if (_isUpdatingAvatar) {
      return false;
    }

    final generation = _generation;
    _isUpdatingAvatar = true;
    notifyListeners();

    try {
      final version = await _api.putAvatar(bytes: bytes, contentType: mimeType);
      if (generation != _generation) {
        return false;
      }

      final saved = await saveAvatarBytes(
        bytes: bytes,
        userId: userId,
        mimeType: mimeType,
      );
      if (generation != _generation) {
        await deleteAvatarFile(saved);
        return false;
      }

      await _setAvatar(saved, version);
      await _saveCache(userId);
      return true;
    } on ApiException catch (e) {
      return _fail(e.message);
    } catch (_) {
      return _fail('We could not save your photo. Please try again.');
    } finally {
      if (generation == _generation) {
        _isUpdatingAvatar = false;
        notifyListeners();
      }
    }
  }

  Future<bool> removeAvatar() async {
    _lastError = null;

    final userId = _userId;
    if (userId == null) {
      return _fail('Please log in again.');
    }
    if (_isUpdatingAvatar) {
      return false;
    }

    final generation = _generation;
    _isUpdatingAvatar = true;
    notifyListeners();

    try {
      await _api.deleteAvatar();
      if (generation != _generation) {
        return false;
      }

      await _setAvatar('', null);
      await _saveCache(userId);
      return true;
    } on ApiException catch (e) {
      return _fail(e.message);
    } catch (_) {
      return _fail(_unexpected);
    } finally {
      if (generation == _generation) {
        _isUpdatingAvatar = false;
        notifyListeners();
      }
    }
  }

  /// Saves the learning preferences. Only the fields that changed are sent.
  Future<bool> updatePreferences({
    String? learningGoal,
    String? preferredDifficulty,
    bool? aiAssistance,
    bool? dailyReminders,
    int? dailyGoalMinutes,
  }) async {
    _lastError = null;

    final userId = _userId;
    if (userId == null) {
      return _fail('Please log in again.');
    }

    if (dailyGoalMinutes != null &&
        (dailyGoalMinutes < LearningPreferences.minDailyGoalMinutes ||
            dailyGoalMinutes > LearningPreferences.maxDailyGoalMinutes)) {
      return _fail(
        'Daily goal must be between ${LearningPreferences.minDailyGoalMinutes} '
        'and ${LearningPreferences.maxDailyGoalMinutes} minutes.',
      );
    }

    final next = _preferences.copyWith(
      learningGoal: learningGoal,
      preferredDifficulty: preferredDifficulty,
      aiAssistance: aiAssistance,
      dailyReminders: dailyReminders,
      dailyGoalMinutes: dailyGoalMinutes,
    );
    final changes = _preferences.changesTo(next);
    if (changes.isEmpty) {
      return true;
    }

    final generation = _generation;

    try {
      final server = await _api.updatePreferences(changes);
      if (generation != _generation) {
        return false;
      }

      _preferences = server.preferences;
      await _saveCache(userId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      return _fail(e.message);
    } catch (_) {
      return _fail(_unexpected);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  bool _fail(String message) {
    _lastError = message;
    return false;
  }

  void _applyServer(ServerProfile server) {
    final nameChanged = server.name != _profile.name;

    _profile = _profile.copyWith(
      name: server.name,
      email: server.email,
      bio: server.bio,
    );
    _preferences = server.preferences;

    if (nameChanged) {
      onNameChanged?.call(server.name);
    }
  }

  Future<void> _setAvatar(String path, int? version) async {
    final previous = _profile.avatarUrl;

    _profile = _profile.copyWith(avatarUrl: path);
    _avatarVersion = version;
    notifyListeners();

    if (previous.isNotEmpty && previous != path) {
      await deleteAvatarFile(previous);
    }
  }

  /// Makes the photo on the device match the server's.
  Future<void> _syncAvatar(
    ServerProfile server,
    String userId,
    int generation,
  ) async {
    final version = server.avatarUpdatedAt;

    if (version == null) {
      if (_profile.avatarUrl.isNotEmpty) {
        await _setAvatar('', null);
      }
      return;
    }

    final current = _profile.avatarUrl;
    final upToDate = current.isNotEmpty &&
        _avatarVersion == version &&
        await avatarFileExists(current);
    if (upToDate) {
      return;
    }

    try {
      final remote = await _api.getAvatar();
      if (generation != _generation) {
        return;
      }

      final saved = await saveAvatarBytes(
        bytes: remote.bytes,
        userId: userId,
        mimeType: remote.contentType,
      );
      if (generation != _generation) {
        await deleteAvatarFile(saved);
        return;
      }

      await _setAvatar(saved, remote.updatedAt);
    } on ApiException catch (e) {
      // The saved photo stays; the profile itself did load.
      if (e.code == 'NO_AVATAR') {
        await _setAvatar('', null);
      }
    } catch (_) {
      // A photo that can't be stored is not worth failing the whole load.
    }
  }

  Map<String, dynamic> _readCache(SharedPreferences prefs, String userId) {
    final raw = prefs.getString(_cacheKey(userId));
    if (raw == null) {
      return const {};
    }

    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  Future<void> _saveCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final avatar = _profile.avatarUrl;

      await prefs.setString(
        _cacheKey(userId),
        jsonEncode({
          'name': _profile.name,
          'bio': _profile.bio,
          // A web data: URI is not stored; it is downloaded again next time.
          'avatarPath': avatar.startsWith('data:') ? '' : avatar,
          'avatarVersion': _avatarVersion,
          'preferences': _preferences.toJson(),
        }),
      );
    } catch (_) {
      // The copy on the device is only a convenience.
    }
  }

  /// Earlier versions kept the profile on the device only (name, bio, photo).
  /// Those values are sent to the account once, then removed. If the network
  /// is down it is tried again next time; if the server refuses a value, the
  /// old data is dropped so it can't block the load forever.
  Future<ServerProfile> _migrateDeviceOnlyData(
    String userId,
    ServerProfile server,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final oldName = (prefs.getString(_v2Key(userId, 'name')) ?? '').trim();
    final oldBio = (prefs.getString(_v2Key(userId, 'bio')) ?? '').trim();
    final oldAvatar =
        kIsWeb ? '' : (prefs.getString(_v2Key(userId, 'avatar')) ?? '');

    if (oldName.isEmpty && oldBio.isEmpty && oldAvatar.isEmpty) {
      return server;
    }

    var result = server;

    try {
      final name = oldName.isNotEmpty && oldName != server.name ? oldName : null;
      final bio = oldBio.isNotEmpty && server.bio.isEmpty ? oldBio : null;

      if (name != null || bio != null) {
        result = await _api.updateProfile(name: name, bio: bio);
      }

      if (server.avatarUpdatedAt == null &&
          oldAvatar.isNotEmpty &&
          await avatarFileExists(oldAvatar)) {
        final bytes = await readAvatarBytes(oldAvatar);
        final mimeType = detectImageMimeType(bytes);

        if (mimeType != null && bytes.length <= _maxAvatarBytes) {
          await _api.putAvatar(bytes: bytes, contentType: mimeType);
          result = await _api.getProfile();
        }
      }
    } on ApiException catch (e) {
      if (e.isNetwork) {
        return server;
      }
    } catch (_) {
      // Unreadable old file: drop it below.
    }

    for (final field in ['name', 'bio', 'avatar']) {
      await prefs.remove(_v2Key(userId, field));
    }
    if (oldAvatar.isNotEmpty) {
      await deleteAvatarFile(oldAvatar);
    }

    return result;
  }

  /// The very first versions kept one profile for the whole device. It is handed
  /// to the account whose email matches, once, and then removed. If the email
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

    if (!prefs.containsKey(_v2Key(userId, 'name'))) {
      final name = prefs.getString(_legacyName) ?? '';
      if (name.trim().isNotEmpty) {
        await prefs.setString(_v2Key(userId, 'name'), name.trim());
      }
    }
    if (!prefs.containsKey(_v2Key(userId, 'bio'))) {
      await prefs.setString(
        _v2Key(userId, 'bio'),
        prefs.getString(_legacyBio) ?? '',
      );
    }
    final avatar = prefs.getString(_legacyAvatar) ?? '';
    if (avatar.isNotEmpty && !prefs.containsKey(_v2Key(userId, 'avatar'))) {
      await prefs.setString(_v2Key(userId, 'avatar'), avatar);
    }

    for (final key in [_legacyName, _legacyEmail, _legacyBio, _legacyAvatar]) {
      await prefs.remove(key);
    }
  }
}