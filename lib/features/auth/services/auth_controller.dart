import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';

enum AuthStatus {
  /// App just started; saved session has not been read yet.
  unknown,

  /// Nobody is signed in.
  unauthenticated,

  /// Account exists but the email is not verified yet.
  needsVerification,

  /// Signed in and verified: the app can be shown.
  authenticated,
}

/// Single source of truth for authentication.
///
/// AuthGate listens to this controller and decides which screen to show, so
/// screens never navigate into the app by hand.
///
/// Prototype only: one account lives on this device, and email verification
/// is simulated. Replace the bodies of register / logIn / verifyEmail /
/// resetPassword with real API calls later; the rest of the app is unaffected.
class AuthController extends ChangeNotifier {
  AuthController._();

  static final AuthController instance = AuthController._();

  /// Returns the shared instance, so `AuthController()` can never create a
  /// second, disconnected controller. Prefer `AuthController.instance`.
  factory AuthController() => instance;

  static const _kUser = 'auth_user';
  static const _kHash = 'auth_password_hash';
  static const _kSession = 'auth_session_active';

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  String? _lastError;

  AuthStatus get status => _status;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  /// The signed-in user, or the user waiting to verify their email.
  AuthUser? get currentUser => _user;

  /// Reason for the most recent failed register / logIn / verifyEmail call.
  String? get lastError => _lastError;

  /// Restores the saved session. Call once when the app starts.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final user = _readUser(prefs);
    final hasPassword = prefs.getString(_kHash) != null;
    final sessionActive = prefs.getBool(_kSession) ?? false;

    if (user == null || !hasPassword) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    } else if (!user.isVerified) {
      _user = user;
      _status = AuthStatus.needsVerification;
    } else if (sessionActive) {
      _user = user;
      _status = AuthStatus.authenticated;
    } else {
      _user = null;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Creates the account and moves to [AuthStatus.needsVerification].
  /// Returns null on failure; read [lastError] for the reason.
  Future<AuthUser?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.length < 2) {
      return _fail('Name must be at least 2 characters.');
    }
    if (!_emailPattern.hasMatch(cleanEmail)) {
      return _fail('Enter a valid email address.');
    }
    if (password.length < 8) {
      return _fail('Password must be at least 8 characters.');
    }

    final prefs = await SharedPreferences.getInstance();

    final existing = _readUser(prefs);
    if (existing != null && existing.email == cleanEmail) {
      return _fail('An account with this email already exists. Please log in.');
    }

    final user = AuthUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: cleanName,
      email: cleanEmail,
      isVerified: false,
    );

    await _saveUser(prefs, user);
    await prefs.setString(_kHash, _hash(cleanEmail, password));
    await prefs.setBool(_kSession, false);

    _user = user;
    _lastError = null;
    _status = AuthStatus.needsVerification;
    notifyListeners();

    return user;
  }

  /// Returns null on failure; read [lastError] for the reason. An account
  /// that has not verified its email moves to [AuthStatus.needsVerification].
  Future<AuthUser?> logIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final prefs = await SharedPreferences.getInstance();
    final user = _readUser(prefs);
    final savedHash = prefs.getString(_kHash);

    if (user == null || savedHash == null) {
      return _fail('No account found. Please create one first.');
    }
    if (user.email != cleanEmail ||
        _hash(cleanEmail, password) != savedHash) {
      return _fail('Incorrect email or password.');
    }

    _user = user;
    _lastError = null;

    if (user.isVerified) {
      await prefs.setBool(_kSession, true);
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.needsVerification;
    }

    notifyListeners();
    return user;
  }

  /// Simulated: trusts the "I Verified My Email" button. A real backend would
  /// confirm the link was opened. Returns null if nobody is waiting.
  Future<AuthUser?> verifyEmail() async {
    final current = _user;

    if (current == null) {
      return _fail('No account is waiting for verification.');
    }

    final prefs = await SharedPreferences.getInstance();
    final verified = current.copyWith(isVerified: true);

    await _saveUser(prefs, verified);
    await prefs.setBool(_kSession, true);

    _user = verified;
    _lastError = null;
    _status = AuthStatus.authenticated;
    notifyListeners();

    return verified;
  }

  /// Simulated: no email is sent. Returns true for any well-formed address so
  /// the screen never reveals whether an account exists.
  Future<bool> resetPassword({required String email}) async {
    if (!_emailPattern.hasMatch(email.trim().toLowerCase())) {
      return false;
    }

    // The real email service will be connected later.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// Ends the session but keeps the account so the user can log back in.
  Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSession, false);

    _user = null;
    _lastError = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Throws away an account that never verified its email (for example one
  /// registered with a mistyped address) so the user can start over.
  /// Unlike [logOut], this deletes the saved account, so a restart does not
  /// bring the user back to the verification screen.
  Future<void> discardUnverifiedAccount() async {
    final current = _user;

    // Never delete a verified account from here; that is what logOut is for.
    if (current == null || current.isVerified) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUser);
    await prefs.remove(_kHash);
    await prefs.remove(_kSession);

    _user = null;
    _lastError = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  AuthUser? _fail(String message) {
    _lastError = message;
    return null;
  }

  AuthUser? _readUser(SharedPreferences prefs) {
    final raw = prefs.getString(_kUser);
    if (raw == null) {
      return null;
    }

    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt or old-format data: treat as "no account".
      return null;
    }
  }

  Future<void> _saveUser(SharedPreferences prefs, AuthUser user) {
    return prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  String _hash(String email, String password) =>
      sha256.convert(utf8.encode('$email:$password')).toString();
}