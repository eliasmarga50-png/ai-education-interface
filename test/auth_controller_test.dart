import 'package:ai_education_interface/core/network/api_exception.dart';
import 'package:ai_education_interface/core/storage/token_storage.dart';
import 'package:ai_education_interface/features/auth/models/auth_user.dart';
import 'package:ai_education_interface/features/auth/services/auth_api.dart';
import 'package:ai_education_interface/features/auth/services/auth_controller.dart';
import 'package:ai_education_interface/features/profile/services/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeTokenStorage implements TokenStorage {
  String? _access;
  String? _refresh;

  @override
  String? get accessToken => _access;

  @override
  String? get refreshToken => _refresh;

  @override
  bool get hasSession => _refresh != null;

  @override
  Future<void> load() async {}

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}

const _verifiedUser = AuthUser(
  id: 'user-1',
  name: 'Elias Tesfaye',
  email: 'elias@example.com',
  isVerified: true,
);

class FakeAuthApi implements AuthApi {
  ApiException? registerError;
  ApiException? verifyError;
  ApiException? loginError;
  ApiException? meError;
  Object? unexpectedRegisterError;
  AuthUser meUser = _verifiedUser;

  final List<String> calls = [];
  String? loggedOutToken;

  @override
  Future<PendingVerification> register({
    required String name,
    required String email,
    required String password,
  }) async {
    calls.add('register');
    if (unexpectedRegisterError != null) {
      throw unexpectedRegisterError!;
    }
    if (registerError != null) {
      throw registerError!;
    }
    return PendingVerification(
      user: AuthUser(
        id: 'user-1',
        name: name,
        email: email.toLowerCase(),
        isVerified: false,
      ),
      codeSent: true,
      resendAfterSeconds: 60,
    );
  }

  @override
  Future<AuthSession> verifyEmail({
    required String email,
    required String code,
  }) async {
    calls.add('verifyEmail');
    if (verifyError != null) {
      throw verifyError!;
    }
    return AuthSession(
      user: AuthUser(
        id: 'user-1',
        name: 'Elias Tesfaye',
        email: email,
        isVerified: true,
      ),
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );
  }

  @override
  Future<int> resendCode({required String email}) async {
    calls.add('resendCode');
    return 60;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    calls.add('login');
    if (loginError != null) {
      throw loginError!;
    }
    return const AuthSession(
      user: _verifiedUser,
      accessToken: 'access-2',
      refreshToken: 'refresh-2',
    );
  }

  @override
  Future<AuthUser> me() async {
    calls.add('me');
    if (meError != null) {
      throw meError!;
    }
    return meUser;
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    calls.add('logout');
    loggedOutToken = refreshToken;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    calls.add('forgotPassword');
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    calls.add('resetPassword');
  }
}

class Rig {
  Rig({FakeAuthApi? api, FakeTokenStorage? tokens, ProfileController? profile})
      : api = api ?? FakeAuthApi(),
        tokens = tokens ?? FakeTokenStorage(),
        profile = profile ?? ProfileController.forTesting() {
    auth = AuthController.forTesting(
      api: this.api,
      tokens: this.tokens,
      profile: this.profile,
    );
  }

  final FakeAuthApi api;
  final FakeTokenStorage tokens;
  final ProfileController profile;
  late final AuthController auth;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('registration', () {
    test('creates the account and waits for the email code', () async {
      final rig = Rig();
      await rig.auth.initialize();
      expect(rig.auth.status, AuthStatus.unauthenticated);

      final user = await rig.auth.register(
        name: '  José Álvarez ',
        email: 'Jose@Example.com ',
        password: 'secret123',
      );

      expect(user, isNotNull);
      expect(rig.auth.status, AuthStatus.needsVerification);
      expect(rig.auth.currentUser?.email, 'jose@example.com');
      expect(rig.tokens.hasSession, isFalse, reason: 'no session before verifying');
      expect(rig.auth.resendAvailableAt, isNotNull);
    });

    test('a pending verification survives an app restart', () async {
      final first = Rig();
      await first.auth.initialize();
      await first.auth.register(
        name: 'Elias',
        email: 'elias@example.com',
        password: 'secret123',
      );

      final second = Rig();
      await second.auth.initialize();

      expect(second.auth.status, AuthStatus.needsVerification);
      expect(second.auth.currentUser?.email, 'elias@example.com');
    });

    test('duplicate account: returns null with the server message', () async {
      final rig = Rig();
      rig.api.registerError = ApiException(
        code: 'EMAIL_TAKEN',
        message: 'An account with this email already exists. Please log in.',
        statusCode: 409,
      );
      await rig.auth.initialize();

      final user = await rig.auth.register(
        name: 'Elias',
        email: 'elias@example.com',
        password: 'secret123',
      );

      expect(user, isNull);
      expect(rig.auth.lastError, contains('already exists'));
      expect(rig.auth.status, AuthStatus.unauthenticated);
    });

    test('network failure is reported, not thrown', () async {
      final rig = Rig();
      rig.api.registerError = ApiException(
        code: 'NETWORK_ERROR',
        message: "Can't reach the server. Check your connection and try again.",
      );
      await rig.auth.initialize();

      final user = await rig.auth.register(
        name: 'Elias',
        email: 'elias@example.com',
        password: 'secret123',
      );

      expect(user, isNull);
      expect(rig.auth.lastError, contains("Can't reach the server"));
    });

    test('an unexpected error becomes a friendly message', () async {
      final rig = Rig();
      rig.api.unexpectedRegisterError = StateError('boom');
      await rig.auth.initialize();

      final user = await rig.auth.register(
        name: 'Elias',
        email: 'elias@example.com',
        password: 'secret123',
      );

      expect(user, isNull);
      expect(rig.auth.lastError, 'Something went wrong. Please try again.');
    });
  });

  group('email verification', () {
    test('a correct code signs the user in and loads their profile', () async {
      final rig = Rig();
      await rig.auth.initialize();
      await rig.auth.register(
        name: 'Elias Tesfaye',
        email: 'elias@example.com',
        password: 'secret123',
      );

      final user = await rig.auth.verifyEmail(code: '123456');

      expect(user, isNotNull);
      expect(rig.auth.status, AuthStatus.authenticated);
      expect(rig.tokens.refreshToken, 'refresh-1');
      expect(rig.profile.isBound, isTrue);
      expect(rig.profile.profile.email, 'elias@example.com');
    });

    test('a wrong code keeps the user on the verification step', () async {
      final rig = Rig();
      rig.api.verifyError = ApiException(
        code: 'INVALID_CODE',
        message: 'Incorrect code. 4 attempts left.',
        statusCode: 400,
      );
      await rig.auth.initialize();
      await rig.auth.register(
        name: 'Elias',
        email: 'elias@example.com',
        password: 'secret123',
      );

      final user = await rig.auth.verifyEmail(code: '000000');

      expect(user, isNull);
      expect(rig.auth.lastError, contains('Incorrect code'));
      expect(rig.auth.status, AuthStatus.needsVerification);
      expect(rig.tokens.hasSession, isFalse);
    });
  });

  group('login', () {
    test('success stores the session and binds the profile', () async {
      final rig = Rig();
      await rig.auth.initialize();

      final user = await rig.auth.logIn(
        email: 'elias@example.com',
        password: 'secret123',
      );

      expect(user?.id, 'user-1');
      expect(rig.auth.status, AuthStatus.authenticated);
      expect(rig.tokens.accessToken, 'access-2');
      expect(rig.profile.profile.name, 'Elias Tesfaye');
    });

    test('wrong password: null, message, still signed out', () async {
      final rig = Rig();
      rig.api.loginError = ApiException(
        code: 'INVALID_CREDENTIALS',
        message: 'Incorrect email or password.',
        statusCode: 401,
      );
      await rig.auth.initialize();

      final user = await rig.auth.logIn(
        email: 'elias@example.com',
        password: 'nope12345',
      );

      expect(user, isNull);
      expect(rig.auth.lastError, 'Incorrect email or password.');
      expect(rig.auth.status, AuthStatus.unauthenticated);
      expect(rig.tokens.hasSession, isFalse);
      expect(rig.profile.isBound, isFalse);
    });

    test('unverified account is sent to the code screen', () async {
      final rig = Rig();
      rig.api.loginError = ApiException(
        code: 'EMAIL_NOT_VERIFIED',
        message: 'Please verify your email to continue.',
        statusCode: 403,
        details: {'email': 'elias@example.com', 'codeSent': true, 'retryAfter': 60},
      );
      await rig.auth.initialize();

      final user = await rig.auth.logIn(
        email: 'Elias@Example.com',
        password: 'secret123',
      );

      expect(user, isNull);
      expect(rig.auth.status, AuthStatus.needsVerification);
      expect(rig.auth.currentUser?.email, 'elias@example.com');
      expect(rig.tokens.hasSession, isFalse);
    });
  });

  group('session restoration', () {
    test('no saved session: signed out', () async {
      final rig = Rig();
      await rig.auth.initialize();

      expect(rig.auth.status, AuthStatus.unauthenticated);
      expect(rig.api.calls, isNot(contains('me')));
    });

    test('valid saved session is restored after a restart', () async {
      final tokens = FakeTokenStorage();
      final first = Rig(tokens: tokens);
      await first.auth.initialize();
      await first.auth.logIn(email: 'elias@example.com', password: 'secret123');

      final second = Rig(tokens: tokens);
      await second.auth.initialize();

      expect(second.auth.status, AuthStatus.authenticated);
      expect(second.auth.currentUser?.email, 'elias@example.com');
      expect(second.profile.isBound, isTrue);
      expect(second.api.calls, contains('me'));
    });

    test('offline start keeps the user signed in with the cached account', () async {
      final tokens = FakeTokenStorage();
      final first = Rig(tokens: tokens);
      await first.auth.initialize();
      await first.auth.logIn(email: 'elias@example.com', password: 'secret123');

      final offline = Rig(tokens: tokens);
      offline.api.meError = ApiException(
        code: 'NETWORK_ERROR',
        message: "Can't reach the server. Check your connection and try again.",
      );
      await offline.auth.initialize();

      expect(offline.auth.status, AuthStatus.authenticated);
      expect(tokens.hasSession, isTrue, reason: 'offline must not log the user out');
    });

    test('a rejected session is cleared and the user is signed out', () async {
      final tokens = FakeTokenStorage();
      final first = Rig(tokens: tokens);
      await first.auth.initialize();
      await first.auth.logIn(email: 'elias@example.com', password: 'secret123');

      final expired = Rig(tokens: tokens);
      expired.api.meError = ApiException(
        code: 'INVALID_REFRESH_TOKEN',
        message: 'Your session has expired. Please log in again.',
        statusCode: 401,
      );
      await expired.auth.initialize();

      expect(expired.auth.status, AuthStatus.unauthenticated);
      expect(tokens.hasSession, isFalse);
      expect(expired.profile.isBound, isFalse);
    });
  });

  group('logout', () {
    test('clears the session, the profile and tells the server', () async {
      final rig = Rig();
      await rig.auth.initialize();
      await rig.auth.logIn(email: 'elias@example.com', password: 'secret123');
      expect(rig.profile.isBound, isTrue);

      await rig.auth.logOut();
      await Future<void>.delayed(Duration.zero);

      expect(rig.auth.status, AuthStatus.unauthenticated);
      expect(rig.auth.currentUser, isNull);
      expect(rig.tokens.hasSession, isFalse);
      expect(rig.profile.isBound, isFalse);
      expect(rig.profile.profile.name, isEmpty);
      expect(rig.api.loggedOutToken, 'refresh-2');
    });

    test('a logged-out app does not restore the old session', () async {
      final tokens = FakeTokenStorage();
      final first = Rig(tokens: tokens);
      await first.auth.initialize();
      await first.auth.logIn(email: 'elias@example.com', password: 'secret123');
      await first.auth.logOut();

      final second = Rig(tokens: tokens);
      await second.auth.initialize();

      expect(second.auth.status, AuthStatus.unauthenticated);
    });
  });
}