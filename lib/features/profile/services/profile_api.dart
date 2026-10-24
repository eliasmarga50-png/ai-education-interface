import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/learning_preferences.dart';

/// The account's profile as the server sends it.
class ServerProfile {
  const ServerProfile({
    required this.name,
    required this.email,
    required this.bio,
    required this.avatarUpdatedAt,
    required this.preferences,
  });

  final String name;
  final String email;
  final String bio;

  /// Changes whenever the photo changes; null when the account has no photo.
  final int? avatarUpdatedAt;
  final LearningPreferences preferences;

  factory ServerProfile.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'];
    final preferences = json['preferences'];

    return ServerProfile(
      name: json['name'] as String,
      email: json['email'] as String,
      bio: json['bio'] as String? ?? '',
      avatarUpdatedAt: avatar is Map ? (avatar['updatedAt'] as num?)?.toInt() : null,
      preferences: preferences is Map
          ? LearningPreferences.fromJson(Map<String, dynamic>.from(preferences))
          : LearningPreferences.defaults,
    );
  }
}

class RemoteAvatar {
  const RemoteAvatar({
    required this.bytes,
    required this.contentType,
    required this.updatedAt,
  });

  final Uint8List bytes;
  final String contentType;
  final int updatedAt;
}

/// One method per endpoint (GET/PATCH /api/profile, /preferences, /avatar).
/// No state, no UI: ProfileController owns the state.
class ProfileApi {
  ProfileApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  static final ProfileApi instance = ProfileApi();

  final ApiClient _client;

  /// A reply that is not shaped like we expect becomes a normal ApiException
  /// instead of a crash in the UI.
  T _parse<T>(T Function() read) {
    try {
      return read();
    } catch (_) {
      throw const ApiException(
        code: 'BAD_RESPONSE',
        message: 'The server sent an unexpected response. Please try again.',
      );
    }
  }

  ServerProfile _profileFrom(Map<String, dynamic> data) {
    return _parse(
      () => ServerProfile.fromJson(data['profile'] as Map<String, dynamic>),
    );
  }

  Future<ServerProfile> getProfile() async {
    return _profileFrom(await _client.get('/api/profile', auth: true));
  }

  /// Send only what changed: a null field is left as it is on the server.
  Future<ServerProfile> updateProfile({String? name, String? bio}) async {
    final data = await _client.patch(
      '/api/profile',
      auth: true,
      body: {
        'name': ?name,
        'bio': ?bio,
      },
    );
    return _profileFrom(data);
  }

  Future<ServerProfile> updatePreferences(Map<String, dynamic> changes) async {
    final data = await _client.patch(
      '/api/profile/preferences',
      auth: true,
      body: changes,
    );
    return _profileFrom(data);
  }

  /// Throws an ApiException with code NO_AVATAR when there is no photo.
  Future<RemoteAvatar> getAvatar() async {
    final data = await _client.get('/api/profile/avatar', auth: true);

    return _parse(() {
      final avatar = data['avatar'] as Map<String, dynamic>;
      return RemoteAvatar(
        bytes: base64Decode(avatar['data'] as String),
        contentType: avatar['contentType'] as String,
        updatedAt: (avatar['updatedAt'] as num).toInt(),
      );
    });
  }

  /// Returns the new photo version (its updatedAt).
  Future<int> putAvatar({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final data = await _client.put(
      '/api/profile/avatar',
      auth: true,
      body: {'contentType': contentType, 'data': base64Encode(bytes)},
    );

    return _parse(
      () => ((data['avatar'] as Map<String, dynamic>)['updatedAt'] as num).toInt(),
    );
  }

  Future<void> deleteAvatar() async {
    await _client.delete('/api/profile/avatar', auth: true);
  }
}