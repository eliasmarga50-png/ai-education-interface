import 'dart:typed_data';

import 'package:ai_education_interface/core/network/api_exception.dart';
import 'package:ai_education_interface/features/profile/models/learning_preferences.dart';
import 'package:ai_education_interface/features/profile/services/profile_api.dart';

/// A server for one account, kept in memory.
///
/// ProfileApi calls have no user id (the access token says who is asking), so
/// one fake stands for one signed-in account. To test a second account, change
/// [profile] before binding it.
class FakeProfileApi implements ProfileApi {
  FakeProfileApi({ServerProfile? profile})
      : profile = profile ??
            const ServerProfile(
              name: 'Alice',
              email: 'alice@example.com',
              bio: '',
              avatarUpdatedAt: null,
              preferences: LearningPreferences.defaults,
            );

  /// What the "server" currently stores.
  ServerProfile profile;

  /// When set, every call throws it (for example a network error).
  ApiException? failure;

  int getCalls = 0;
  int updateCalls = 0;
  int putAvatarCalls = 0;
  Map<String, dynamic>? lastPreferenceChanges;

  void _check() {
    final error = failure;
    if (error != null) {
      throw error;
    }
  }

  ServerProfile _copy({
    String? name,
    String? bio,
    LearningPreferences? preferences,
  }) {
    return ServerProfile(
      name: name ?? profile.name,
      email: profile.email,
      bio: bio ?? profile.bio,
      avatarUpdatedAt: profile.avatarUpdatedAt,
      preferences: preferences ?? profile.preferences,
    );
  }

  @override
  Future<ServerProfile> getProfile() async {
    getCalls++;
    _check();
    return profile;
  }

  @override
  Future<ServerProfile> updateProfile({String? name, String? bio}) async {
    updateCalls++;
    _check();
    profile = _copy(name: name, bio: bio);
    return profile;
  }

  @override
  Future<ServerProfile> updatePreferences(Map<String, dynamic> changes) async {
    updateCalls++;
    lastPreferenceChanges = changes;
    _check();
    final merged = {...profile.preferences.toJson(), ...changes};
    profile = _copy(preferences: LearningPreferences.fromJson(merged));
    return profile;
  }

  @override
  Future<RemoteAvatar> getAvatar() async {
    _check();
    throw const ApiException(
      code: 'NO_AVATAR',
      message: 'No profile photo yet.',
    );
  }

  @override
  Future<int> putAvatar({
    required Uint8List bytes,
    required String contentType,
  }) async {
    putAvatarCalls++;
    _check();
    return 1;
  }

  @override
  Future<void> deleteAvatar() async {
    _check();
  }
}