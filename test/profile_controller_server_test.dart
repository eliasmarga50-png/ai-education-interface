import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_education_interface/core/network/api_exception.dart';

import 'package:ai_education_interface/features/profile/services/profile_api.dart';
import 'package:ai_education_interface/features/profile/services/profile_controller.dart';

import 'helpers/fake_profile_api.dart';

const ApiException _offline = ApiException(
  code: 'NETWORK_ERROR',
  message: "Can't reach the server. Check your connection and try again.",
);

Future<ProfileController> _signedIn(
  FakeProfileApi api, {
  String userId = 'u1',
  String name = 'Alice',
  String email = 'alice@example.com',
}) async {
  final controller = ProfileController.forTesting(api: api);
  await controller.bindToUser(userId: userId, name: name, email: email);
  await controller.refresh();
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('loading', () {
    test('shows the profile the server sends', () async {
      final api = FakeProfileApi(
        profile: ServerProfile(
          name: 'Alice Server',
          email: 'alice@example.com',
          bio: 'Hello',
          avatarUpdatedAt: null,
          preferences: LearningPreferences.defaults.copyWith(
            dailyGoalMinutes: 30,
          ),
        ),
      );

      final controller = await _signedIn(api);

      expect(controller.profile.name, 'Alice Server');
      expect(controller.profile.bio, 'Hello');
      expect(controller.preferences.dailyGoalMinutes, 30);
      expect(controller.hasSynced, isTrue);
      expect(controller.loadError, isNull);
    });

    test('keeps the saved copy and reports the problem when offline', () async {
      final api = FakeProfileApi();
      final first = await _signedIn(api);
      await first.updateProfile(name: 'Elias Tesfaye', bio: 'Hello');

      // "Restart" the app with no connection.
      final offline = FakeProfileApi()..failure = _offline;
      final second = ProfileController.forTesting(api: offline);
      await second.bindToUser(
        userId: 'u1',
        name: 'Alice',
        email: 'alice@example.com',
      );

      expect(second.profile.name, 'Elias Tesfaye');
      expect(second.profile.bio, 'Hello');
      expect(await second.refresh(), isFalse);
      expect(second.loadError, contains("Can't reach"));
      expect(second.hasSynced, isFalse);
      expect(second.profile.name, 'Elias Tesfaye');
    });
  });

  group('saving the profile', () {
    test('is sent to the server and kept', () async {
      final api = FakeProfileApi();
      final controller = await _signedIn(api);

      final saved = await controller.updateProfile(
        name: '  Elias   Tesfaye ',
        bio: ' Flutter student ',
      );

      expect(saved, isTrue);
      expect(api.profile.name, 'Elias Tesfaye');
      expect(api.profile.bio, 'Flutter student');
      expect(controller.profile.name, 'Elias Tesfaye');
    });

    test('fails with a message and keeps the old values when offline',
        () async {
      final api = FakeProfileApi();
      final controller = await _signedIn(api);

      api.failure = _offline;
      final saved = await controller.updateProfile(name: 'New Name', bio: 'x');

      expect(saved, isFalse);
      expect(controller.lastError, contains("Can't reach"));
      expect(controller.profile.name, 'Alice');
    });

    test('rejects invalid input before any request is made', () async {
      final api = FakeProfileApi();
      final controller = await _signedIn(api);

      expect(await controller.updateProfile(name: 'A', bio: ''), isFalse);
      expect(controller.lastError, isNotNull);

      expect(
        await controller.updateProfile(name: 'Alice', bio: 'x' * 161),
        isFalse,
      );
      expect(controller.lastError, contains('160'));
      expect(api.updateCalls, 0);
    });

    test('needs a signed-in account', () async {
      final controller = ProfileController.forTesting(api: FakeProfileApi());

      expect(await controller.updateProfile(name: 'Alice', bio: ''), isFalse);
      expect(controller.lastError, 'Please log in again.');
    });
  });

  group('preferences', () {
    test('are saved on the server and only changed fields are sent', () async {
      final api = FakeProfileApi();
      final controller = await _signedIn(api);

      final saved = await controller.updatePreferences(dailyGoalMinutes: 45);

      expect(saved, isTrue);
      expect(api.lastPreferenceChanges, {'dailyGoalMinutes': 45});
      expect(api.profile.preferences.dailyGoalMinutes, 45);
      expect(controller.preferences.dailyGoalMinutes, 45);
    });

    test('an unchanged value sends nothing', () async {
      final api = FakeProfileApi();
      final controller = await _signedIn(api);

      expect(await controller.updatePreferences(dailyGoalMinutes: 15), isTrue);
      expect(api.updateCalls, 0);
    });

    test('an out-of-range goal is refused locally', () async {
      final api = FakeProfileApi();
      final controller = await _signedIn(api);

      expect(await controller.updatePreferences(dailyGoalMinutes: 3), isFalse);
      expect(controller.lastError, contains('between'));
      expect(api.updateCalls, 0);
    });

    test('a failed save keeps the old preferences', () async {
      final api = FakeProfileApi();
      final controller = await _signedIn(api);

      api.failure = _offline;
      expect(await controller.updatePreferences(dailyGoalMinutes: 60), isFalse);
      expect(controller.preferences.dailyGoalMinutes, 15);
    });
  });

  group('photo', () {
    test('a file that is not JPEG, PNG or WebP is refused before upload',
        () async {
      final api = FakeProfileApi();
      final controller = await _signedIn(api);

      final saved = await controller.updateAvatarBytes(
        Uint8List.fromList([1, 2, 3, 4]),
      );

      expect(saved, isFalse);
      expect(controller.lastError, contains('JPEG'));
      expect(api.putAvatarCalls, 0);
    });

    test('a photo over 300 KB is refused before upload', () async {
      final api = FakeProfileApi();
      final controller = await _signedIn(api);

      final big = Uint8List(300 * 1024 + 1);
      big[0] = 0xFF;
      big[1] = 0xD8;
      big[2] = 0xFF;

      expect(await controller.updateAvatarBytes(big), isFalse);
      expect(controller.lastError, contains('too large'));
      expect(api.putAvatarCalls, 0);
    });
  });

  group('ownership', () {
    test("two accounts on one device never see each other's data", () async {
      final api = FakeProfileApi();
      final controller = await _signedIn(api);
      expect(
        await controller.updateProfile(name: 'Alice Cooper', bio: 'Alice bio'),
        isTrue,
      );
      controller.unbind();

      // Bob signs in on the same device, offline: only his account name is known.
      api.failure = _offline;
      await controller.bindToUser(
        userId: 'u2',
        name: 'Bob',
        email: 'bob@example.com',
      );
      expect(controller.profile.name, 'Bob');
      expect(controller.profile.bio, '');
      controller.unbind();

      // Alice comes back and still has her own saved copy.
      await controller.bindToUser(
        userId: 'u1',
        name: 'Alice',
        email: 'alice@example.com',
      );
      expect(controller.profile.name, 'Alice Cooper');
      expect(controller.profile.bio, 'Alice bio');
    });

    test('logging out clears the profile from memory', () async {
      final controller = await _signedIn(FakeProfileApi());

      controller.unbind();

      expect(controller.isBound, isFalse);
      expect(controller.profile.name, isEmpty);
      expect(controller.preferences, LearningPreferences.defaults);
    });
  });
}