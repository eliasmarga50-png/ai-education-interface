


import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';

class AuthController {
  static const String _userKey = 'auth_user';
  static const String _loggedInKey = 'auth_logged_in';

  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
}





