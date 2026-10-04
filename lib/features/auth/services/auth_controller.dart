


import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';

class AuthController {
  static const String _userKey = 'auth_user';
  static const String _loggedInKey = 'auth_logged_in';

  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final loggedIn = preferences.getBool(_loggedInKey) ?? false;

    if (!loggedIn) {
      _currentUser = null;
      return;
    }

    final userJson = preferences.getString(_userKey);

    if (userJson==null) {
      _currentUser = null;
      await preferences.setBool(_loggedInKey, false);
      return;
    }
    try {
      final decoded = jsonDecode(userJson) as Map<String, dynamic>;
      _currentUser = AuthUser.fromJson(decoded);
    }
    catch (_) {
      _currentUser = null;
      await preferences.remove(_userKey);
      await preferences.setBool(_loggedInKey, false);
    }
  }

  Future<AuthUser?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      return null;
    }

    final user = AuthUser(
      id: 'local-user-1', 
      name: normalizedEmail.split('@').first, 
      email: normalizedEmail, 
      isVerified: true,
      );

      await _saveSession(user);
      return user;
  }

  
}





