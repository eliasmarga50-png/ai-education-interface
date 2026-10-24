import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../profile/services/profile_controller.dart';
import '../models/auth_user.dart';
import 'account_api.dart';
import 'auth_api.dart';

enum AuthStatus {
  /// App just started; saved session has not been read yet.
  unknown,

  /// Nobody is signed in.
  unauthenticated,

  /// Account exists but the email code has not been entered yet.
  needsVerification,

  /// Signed in and verified: the app can be shown.
  authenticated,
}

/// Single source of truth for authentication.
///
/// AuthGate listens to this controller and decides which screen to show, so
/// screens never navigate into the app by hand. The public API is unchanged
/// from the prototype except where a real server needs more (the email code).
///
/// Every method that can fail returns null / false and puts a message that is
/// safe to show in [lastError]; nothing here throws to the UI.
class AuthController extends ChangeNotifier {
  AuthController._({
    AuthApi? api,
    AccountApi? account,
    TokenStorage? tokens,
    ProfileController? profile,
    bool listenForExpiredSession = true,
  })  : _api = api ?? AuthApi.instance,
        _account = account ?? AccountApi.instance,
        _tokens = tokens ?? TokenStorage.instance,
        _profile = profile ?? ProfileController.instance {
    if (listenForExpiredSession) {
      ApiClient.instance.onSessionExpired = _handleSessionExpired;
    }
    // A name changed on the Profile screen (or on another device) must also
    // update the account copy kept here.
    _profile.onNameChanged = _applyProfileName;
  }

  /// Same behaviour with fake collaborators, for unit tests.
  @visibleForTesting
  AuthController.forTesting({
    required AuthApi api,
    required TokenStorage tokens,
    required ProfileController profile,
    AccountApi? account,
  }) : this._(
          api: api,
          account: account,
          tokens: tokens,
          profile: profile,
          listenForExpiredSession: false,
        );

  static final AuthController instance = AuthController._();

  /// Returns the shared instance, so `AuthController()` can never create a
  /// second, disconnected controller. Prefer `AuthController.instance`.
  factory AuthController() => instance;

  /// Cached signed-in user, so the app can open offline.
  static const _kUser = 'auth_user';

  /// Account that registered but has not entered its email code yet.
  static const _kPending = 'auth_pending_user';

  static const _unexpected = 'Something went wrong. Please try again.';

  final AuthApi _api;
  final AccountApi _account;
  final TokenStorage _tokens;
  final ProfileController _profile;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  String? _lastError;
  String? _verificationNotice;
  DateTime? _resendAvailableAt;
  bool _initialized = false;

  AuthStatus get status => _status;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  /// The signed-in user, or the user waiting to verify their email.
  AuthUser? get currentUser => _user;

  /// Reason for the most recent failed call.
  String? get lastError => _lastError;

  /// Shown once on the verification screen (for example "we could not send the
  /// email yet"). Null when everything went fine.
  String? get verificationNotice => _verificationNotice;

  /// When the "Resend code" button becomes available again.
  DateTime? get resendAvailableAt => _resendAvailableAt;

  // ---------------------------------------------------------------------
  // Start-up
  // ---------------------------------------------------------------------

  /// Restores the saved session. Safe to call more than once.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      await _restoreSession();
    } catch (_) {
      // Unreadable storage must never leave the app on a spinner.
      _user = null;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _tokens.load();

    // The prototype kept a password hash on the device. The server owns
    // passwords now, so remove the leftovers.
    await prefs.remove('auth_password_hash');
    await prefs.remove('auth_session_active');

    if (_tokens.hasSession) {
      final cached = _readUser(prefs, _kUser);

      try {
        // Refreshes the access token by itself if it has expired.
        final fresh = await _api.me();
        _user = fresh;
        _status = AuthStatus.authenticated;
        await _saveUser(prefs, _kUser, fresh);
        await _bindProfile(fresh);
      } on ApiException catch (e) {
        if (e.isNetwork && cached != null) {
          // Offline: let the user in with what we know; the next online
          // request will refresh or sign them out.
          _user = cached;
          _status = AuthStatus.authenticated;
          await _bindProfile(cached);
        } else if (!e.isNetwork) {
          await _tokens.clear();
          await prefs.remove(_kUser);
        }
      }
    }

    if (_status == AuthStatus.unknown) {
      final pending = _readUser(prefs, _kPending);
      if (pending != null) {
        _user = pending;
        _status = AuthStatus.needsVerification;
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
    }
  }

  // ---------------------------------------------------------------------
  // Sign up / verify
  // ---------------------------------------------------------------------

  /// Creates the account; the server emails a 6-digit code and the app moves
  /// to [AuthStatus.needsVerification]. Returns null on failure.
  Future<AuthUser?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final pending = await _api.register(
        name: name.trim(),
        email: email.trim(),
        password: password,
      );

      await _enterVerification(
        pending.user,
        resendAfterSeconds: pending.resendAfterSeconds,
        codeSent: pending.codeSent,
      );
      return pending.user;
    } on ApiException catch (e) {
      return _fail(e);
    } catch (_) {
      return _failMessage(_unexpected);
    }
  }

  /// Checks the 6-digit [code] the user received. On success the user is
  /// signed in. Returns null on failure (wrong code, expired, too many tries).
  Future<AuthUser?> verifyEmail({required String code}) async {
    final current = _user;
    if (current == null) {
      return _failMessage('No account is waiting for verification.');
    }

    try {
      final session = await _api.verifyEmail(
        email: current.email,
        code: code.trim(),
      );
      await _startSession(session);
      return session.user;
    } on ApiException catch (e) {
      return _fail(e);
    } catch (_) {
      return _failMessage(_unexpected);
    }
  }

  /// Emails a new code. Returns false if it was refused (cooldown, limit...);
  /// read [lastError] for the reason.
  Future<bool> resendVerificationCode() async {
    final current = _user;
    if (current == null) {
      _lastError = 'No account is waiting for verification.';
      return false;
    }

    try {
      final seconds = await _api.resendCode(email: current.email);
      _setResendCooldown(seconds);
      _lastError = null;
      _verificationNotice = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      if (e.retryAfter != null) {
        _setResendCooldown(e.retryAfter!);
        notifyListeners();
      }
      return false;
    } catch (_) {
      _lastError = _unexpected;
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Log in / out
  // ---------------------------------------------------------------------

  /// Returns null on failure; read [lastError] for the reason. An account
  /// that has not verified its email moves to [AuthStatus.needsVerification]
  /// and gets a fresh code.
  Future<AuthUser?> logIn({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _api.login(
        email: email.trim(),
        password: password,
      );
      await _startSession(session);
      return session.user;
    } on ApiException catch (e) {
      if (e.code == 'EMAIL_NOT_VERIFIED') {
        final serverEmail = e.details['email'] as String?;
        await _enterVerification(
          AuthUser(
            id: '',
            name: '',
            email: serverEmail ?? email.trim().toLowerCase(),
            isVerified: false,
          ),
          resendAfterSeconds: e.retryAfter ?? 60,
          codeSent: e.details['codeSent'] == true,
        );
        _lastError = e.message;
        return null;
      }
      return _fail(e);
    } catch (_) {
      return _failMessage(_unexpected);
    }
  }

  /// Ends the session on this device straight away (the server is told in
  /// the background, so logging out works offline too).
  Future<void> logOut() async {
    final refreshToken = _tokens.refreshToken;

    await _tokens.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUser);

    _profile.unbind();
    _user = null;
    _lastError = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();

    if (refreshToken != null) {
      unawaited(
        _api.logout(refreshToken: refreshToken).catchError((Object _) {}),
      );
    }
  }

  // ---------------------------------------------------------------------
  // Signed-in account actions (Profile > Privacy)
  // ---------------------------------------------------------------------

  /// Changes the password. The server signs the other devices out and sends
  /// new tokens for this one. Returns false on failure; read [lastError].
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final session = await _account.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await _tokens.save(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      _lastError = null;
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      return false;
    } catch (_) {
      _lastError = _unexpected;
      return false;
    }
  }

  /// Ends every session of the account (all devices), then signs out here.
  Future<bool> logOutEverywhere() async {
    try {
      await _account.logoutAll();
    } on ApiException catch (e) {
      _lastError = e.message;
      return false;
    } catch (_) {
      _lastError = _unexpected;
      return false;
    }

    await logOut();
    return true;
  }

  /// Permanently deletes the account (the server asks for the password again),
  /// removes its data from this device and signs out.
  Future<bool> deleteAccount({required String password}) async {
    final userId = _user?.id;

    try {
      await _account.deleteAccount(password: password);
    } on ApiException catch (e) {
      _lastError = e.message;
      return false;
    } catch (_) {
      _lastError = _unexpected;
      return false;
    }

    if (userId != null) {
      await _profile.clearLocalData(userId);
    }
    await logOut();
    return true;
  }

  /// Leaves the verification screen (for example after a mistyped email) so
  /// the user can start over. The server removes abandoned unverified
  /// accounts by itself after a few days.
  Future<void> discardUnverifiedAccount() async {
    final current = _user;
    if (current == null || current.isVerified) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPending);

    _user = null;
    _lastError = null;
    _verificationNotice = null;
    _resendAvailableAt = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------

  /// Asks the server to email a reset code. The server answers the same way
  /// whether or not the account exists, so true only means "request accepted".
  Future<bool> requestPasswordReset({required String email}) async {
    try {
      await _api.forgotPassword(email: email.trim());
      _lastError = null;
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      return false;
    } catch (_) {
      _lastError = _unexpected;
      return false;
    }
  }

  /// Sets a new password using the emailed [code]. The user is not signed in
  /// by this; they log in with the new password afterwards.
  Future<bool> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _api.resetPassword(
        email: email.trim(),
        code: code.trim(),
        newPassword: newPassword,
      );
      _lastError = null;
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      return false;
    } catch (_) {
      _lastError = _unexpected;
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  Future<void> _startSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();

    await _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await _saveUser(prefs, _kUser, session.user);
    await prefs.remove(_kPending);

    _user = session.user;
    _lastError = null;
    _verificationNotice = null;
    _resendAvailableAt = null;
    _status = AuthStatus.authenticated;

    await _bindProfile(session.user);
    notifyListeners();
  }

  Future<void> _enterVerification(
    AuthUser user, {
    required int resendAfterSeconds,
    required bool codeSent,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveUser(prefs, _kPending, user);

    _user = user;
    _lastError = null;
    _verificationNotice = codeSent
        ? null
        : 'We could not send the email yet. Tap "Resend code" in a moment.';
    _setResendCooldown(resendAfterSeconds);
    _status = AuthStatus.needsVerification;
    notifyListeners();
  }

  void _setResendCooldown(int seconds) {
    _resendAvailableAt = DateTime.now().add(Duration(seconds: seconds));
  }

  /// Hands the profile screens to the account that just signed in.
  Future<void> _bindProfile(AuthUser user) {
    return _profile.bindToUser(
      userId: user.id,
      name: user.name,
      email: user.email,
    );
  }

  /// Keeps the cached account in step with the profile's name.
  void _applyProfileName(String name) {
    final current = _user;
    if (current == null || current.name == name) {
      return;
    }

    final updated = current.copyWith(name: name);
    _user = updated;
    unawaited(
      SharedPreferences.getInstance().then((prefs) {
        return _saveUser(prefs, _kUser, updated);
      }),
    );
  }

  /// The refresh token was rejected (expired, revoked, password was reset) or
  /// there is no token at all.
  void _handleSessionExpired() {
    // Already signed out (for example a request that finished after logout).
    if (_status != AuthStatus.authenticated) {
      return;
    }

    _profile.unbind();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _lastError = 'Your session has expired. Please log in again.';
    notifyListeners();
  }

  AuthUser? _fail(ApiException error) => _failMessage(error.message);

  AuthUser? _failMessage(String message) {
    _lastError = message;
    return null;
  }

  AuthUser? _readUser(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) {
      return null;
    }

    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt or old-format data (for example the prototype's): ignore it.
      return null;
    }
  }

  Future<void> _saveUser(SharedPreferences prefs, String key, AuthUser user) {
    return prefs.setString(key, jsonEncode(user.toJson()));
  }
}