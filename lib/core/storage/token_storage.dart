import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the login tokens in the platform's secure storage (Android Keystore /
/// iOS Keychain) instead of plain SharedPreferences.
class TokenStorage {
  /// Tests pass a fake [FlutterSecureStorage]; the app uses [instance].
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static final TokenStorage instance = TokenStorage();

  final FlutterSecureStorage _storage;
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get hasSession => _refreshToken != null;

  /// Reads the saved tokens into memory. Call once at start-up.
  Future<void> load() async {
    try {
      _accessToken = await _storage.read(key: _kAccess);
      _refreshToken = await _storage.read(key: _kRefresh);
    } catch (_) {
      // Unreadable storage (for example after a device restore): start signed out.
      _accessToken = null;
      _refreshToken = null;
    }
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    try {
      await _storage.delete(key: _kAccess);
      await _storage.delete(key: _kRefresh);
    } catch (_) {
      // Memory is already cleared; nothing else to do.
    }
  }
}