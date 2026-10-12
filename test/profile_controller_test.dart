import 'package:ai_education_interface/features/profile/services/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProfileController> bound(
  String id, {
  String name = 'Elias Tesfaye',
  String email = 'elias@example.com',
}) async {
  final controller = ProfileController.forTesting();
  await controller.bindToUser(userId: id, name: name, email: email);
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('profile creation and persistence', () {
    test('a new account starts from its server name and email', () async {
      final c = await bound('u1');

      expect(c.isBound, isTrue);
      expect(c.profile.name, 'Elias Tesfaye');
      expect(c.profile.email, 'elias@example.com');
      expect(c.profile.bio, isEmpty);
    });

    test('edits are saved and loaded again after a restart', () async {
      final first = await bound('u1');
      final saved = await first.updateProfile(name: '  José   Álvarez ', bio: ' Learning ');
      expect(saved, isTrue);
      expect(first.profile.name, 'José Álvarez');

      final afterRestart = await bound('u1');

      expect(afterRestart.profile.name, 'José Álvarez');
      expect(afterRestart.profile.bio, 'Learning');
      expect(afterRestart.profile.email, 'elias@example.com');
    });

    test('invalid names and too-long bios are refused and nothing changes', () async {
      final c = await bound('u1');

      for (final bad in ['', '12345', 'John2', 'x_y']) {
        expect(await c.updateProfile(name: bad, bio: ''), isFalse, reason: bad);
      }
      expect(await c.updateProfile(name: 'Elias', bio: 'x' * 161), isFalse);
      expect(c.profile.name, 'Elias Tesfaye');

      final again = await bound('u1');
      expect(again.profile.name, 'Elias Tesfaye');
    });
  });

  group('ownership', () {
    test('nobody can edit while signed out', () async {
      final c = ProfileController.forTesting();

      expect(c.isBound, isFalse);
      expect(await c.updateProfile(name: 'Mallory', bio: 'x'), isFalse);
      expect(await c.updateAvatar('/tmp/photo.jpg'), isFalse);
      expect(await c.removeAvatar(), isFalse);
    });

    test('unbind removes the profile from memory and blocks edits', () async {
      final c = await bound('u1');
      await c.updateProfile(name: 'Elias', bio: 'private bio');

      c.unbind();

      expect(c.isBound, isFalse);
      expect(c.profile.name, isEmpty);
      expect(c.profile.bio, isEmpty);
      expect(c.profile.email, isEmpty);
      expect(await c.updateProfile(name: 'Mallory', bio: ''), isFalse);
    });

    test('two accounts on one device never see each other\'s data', () async {
      final a = await bound('u1');
      await a.updateProfile(name: 'Alice', bio: 'alice bio');

      final b = await bound('u2', name: 'Bob Builder', email: 'bob@example.com');
      expect(b.profile.name, 'Bob Builder');
      expect(b.profile.bio, isEmpty);
      await b.updateProfile(name: 'Bobby', bio: 'bob bio');

      final aAgain = await bound('u1');
      expect(aAgain.profile.name, 'Alice');
      expect(aAgain.profile.bio, 'alice bio');
    });

    test('the email can only come from the account', () async {
      final c = await bound('u1');
      await c.updateProfile(name: 'Elias', bio: '');

      expect(c.profile.email, 'elias@example.com');
    });
  });

  group('legacy single-profile storage', () {
    test('is handed to the matching account once, then removed', () async {
      SharedPreferences.setMockInitialValues({
        'profile_name': 'Old Name',
        'profile_email': 'ELIAS@example.com',
        'profile_bio': 'old bio',
      });

      final c = await bound('u1');

      expect(c.profile.name, 'Old Name');
      expect(c.profile.bio, 'old bio');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('profile_email'), isFalse);
    });

    test('is NOT given to a different account', () async {
      SharedPreferences.setMockInitialValues({
        'profile_name': 'Old Name',
        'profile_email': 'someone.else@example.com',
        'profile_bio': 'old bio',
      });

      final c = await bound('u1');

      expect(c.profile.name, 'Elias Tesfaye');
      expect(c.profile.bio, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('profile_email'), isTrue,
          reason: 'left for its real owner');
    });
  });
}