import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'auth_api.dart';

/// Actions of a signed-in account (Profile > Privacy). Kept apart from
/// [AuthApi], which only covers signing in and out, so fakes of AuthApi in
/// tests don't have to know about them.
class AccountApi {
  AccountApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  static final AccountApi instance = AccountApi();

  final ApiClient _client;

  /// Sets a new password for the signed-in account. The server asks for the
  /// current password again, signs every other device out and answers with
  /// fresh tokens for this one.
  Future<AuthSession> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final data = await _client.post(
      '/api/auth/change-password',
      auth: true,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );

    try {
      return AuthSession.fromJson(data);
    } catch (_) {
      throw const ApiException(
        code: 'BAD_RESPONSE',
        message: 'The server sent an unexpected response. Please try again.',
      );
    }
  }

  /// Ends every session of the account, on all devices.
  Future<void> logoutAll() async {
    await _client.post('/api/auth/logout-all', auth: true);
  }

  /// Permanently deletes the account. The server asks for the password again.
  Future<void> deleteAccount({required String password}) async {
    await _client.post(
      '/api/auth/delete-account',
      auth: true,
      body: {'password': password},
    );
  }
}