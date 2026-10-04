


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

if (userJson == null) {
  _currentUser = null;
  await preferences.setBool(_loggedInKey, false);
  return;
}

try {
  final decoded = jsonDecode(userJson) as Map<String, dynamic>;
  _currentUser = AuthUser.fromJson(decoded);
} catch (_) {
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

/*
 * Phase 2 currently uses local/mock authentication.
 *
 * Later this method will call the backend authentication service
 * and receive a real JWT-based authenticated user.
 */
final user = AuthUser(
  id: 'local-user-1',
  name: normalizedEmail.split('@').first,
  email: normalizedEmail,
  isVerified: true,
);

await _saveSession(user);

return user;


}

Future<AuthUser?> register({
required String name,
required String email,
required String password,
}) async {
final normalizedName = name.trim();
final normalizedEmail = email.trim().toLowerCase();


if (normalizedName.isEmpty ||
    normalizedEmail.isEmpty ||
    password.isEmpty) {
  return null;
}

/*
 * Registration is local/mock for Phase 2.
 *
 * New users start as unverified so the verification screen
 * can be demonstrated before entering the main application.
 */
final user = AuthUser(
  id: 'local-user-1',
  name: normalizedName,
  email: normalizedEmail,
  isVerified: false,
);

await _saveSession(user);

return user;


}

Future<AuthUser?> verifyEmail() async {
final user = _currentUser;


if (user == null) {
  return null;
}

final verifiedUser = user.copyWith(
  isVerified: true,
);

await _saveSession(verifiedUser);

return verifiedUser;


}

Future<void> logout() async {
final preferences = await SharedPreferences.getInstance();


_currentUser = null;

await preferences.remove(_userKey);
await preferences.setBool(_loggedInKey, false);


}

Future<bool> resetPassword({
required String email,
}) async {
final normalizedEmail = email.trim().toLowerCase();


if (normalizedEmail.isEmpty) {
  return false;
}

/*
 * Password reset is simulated for now.
 *
 * The real implementation will call the Django API and
 * trigger the backend email/password-reset workflow.
 */
return true;


}

Future<void> _saveSession(AuthUser user) async {
final preferences = await SharedPreferences.getInstance();


_currentUser = user;

await preferences.setString(
  _userKey,
  jsonEncode(user.toJson()),
);

await preferences.setBool(
  _loggedInKey,
  true,
);


}
}
