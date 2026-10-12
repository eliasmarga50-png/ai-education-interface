import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/auth_user.dart';

/// The server accepted the sign-up (or login of an unverified account).
class PendingVerification {
  const PendingVerification({
    required this.user,
    required this.codeSent,
    required this.resendAfterSeconds,
  });

  final AuthUser user;

  /// false when the email could not be sent; the user can tap "Resend".
  final bool codeSent;
  final int resendAfterSeconds;
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}

/// One method per endpoint. No state, no UI: AuthController owns the state.
class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  static final AuthApi instance = AuthApi();

  final ApiClient _client;

  /// A reply that is not shaped like we expect (wrong server, proxy page...)
  /// becomes a normal ApiException instead of a crash in the UI.
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

  Future<PendingVerification> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/api/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );

    return _parse(
      () => PendingVerification(
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
        codeSent: data['codeSent'] as bool? ?? false,
        resendAfterSeconds:
            (data['resendAvailableInSeconds'] as num?)?.toInt() ?? 60,
      ),
    );
  }

  Future<AuthSession> verifyEmail({
    required String email,
    required String code,
  }) async {
    final data = await _client.post(
      '/api/auth/verify-email',
      body: {'email': email, 'code': code},
    );
    return _parse(() => AuthSession.fromJson(data));
  }

  /// Returns how many seconds until another code may be requested.
  Future<int> resendCode({required String email}) async {
    final data = await _client.post(
      '/api/auth/resend-code',
      body: {'email': email},
    );
    return (data['resendAvailableInSeconds'] as num?)?.toInt() ?? 60;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    return _parse(() => AuthSession.fromJson(data));
  }

  Future<AuthUser> me() async {
    final data = await _client.get('/api/auth/me', auth: true);
    return _parse(() => AuthUser.fromJson(data['user'] as Map<String, dynamic>));
  }

  Future<void> logout({required String refreshToken}) async {
    await _client.post(
      '/api/auth/logout',
      body: {'refreshToken': refreshToken},
    );
  }

  Future<void> forgotPassword({required String email}) async {
    await _client.post('/api/auth/forgot-password', body: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.post(
      '/api/auth/reset-password',
      body: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }
}