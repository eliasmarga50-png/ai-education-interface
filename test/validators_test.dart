import 'package:ai_education_interface/core/validation/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.name', () {
    test('rejects empty and whitespace-only names', () {
      expect(Validators.name(null), isNotNull);
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('    '), isNotNull);
    });

    test('rejects numbers-only names and names containing digits', () {
      for (final bad in ['12345', '7', 'John2', '2John', 'Jo3hn', 'A1']) {
        expect(Validators.name(bad), isNotNull, reason: bad);
      }
    });

    test('rejects symbols, emoji and malformed separators', () {
      for (final bad in [
        'John!',
        'x_y',
        'a@b',
        '😀😀',
        '-Anna',
        'Anna-',
        "'Anna",
        "O''Brien",
        'a--b',
        'Anna - Lee',
        'John.',
      ]) {
        expect(Validators.name(bad), isNotNull, reason: bad);
      }
    });

    test('rejects too short and too long names', () {
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name('A' * 61), isNotNull);
      expect(Validators.name('A' * 60), isNull);
    });

    test('accepts international letters, spaces, hyphens and apostrophes', () {
      for (final good in [
        'José Álvarez',
        "Seán O'Brien",
        'Jean-Luc Picard',
        'Nguyễn Văn An',
        'Łukasz Żółć',
        'Müller',
        'محمد علي',
        '李小龙',
        'ዓለም ተስፋዬ',
        'Zoë',
        'D\u2019Angelo',
        'Ana María de la Cruz',
        'Li',
      ]) {
        expect(Validators.name(good), isNull, reason: good);
      }
    });

    test('normalizeName trims and collapses whitespace', () {
      expect(Validators.normalizeName('  Mary    Ann  '), 'Mary Ann');
    });
  });

  group('Validators.email', () {
    test('accepts normal addresses', () {
      for (final good in [
        'a@b.co',
        'First.Last@Example.com',
        'user+tag@sub.example.org',
        "o'brien@example.ie",
      ]) {
        expect(Validators.email(good), isNull, reason: good);
      }
    });

    test('rejects malformed addresses', () {
      for (final bad in [
        '',
        'plain',
        'a@',
        '@b.com',
        'a@b',
        'a@b.c',
        'a b@c.com',
        'a@@b.com',
        'a..b@c.com',
        '.a@c.com',
        'a@-b.com',
        'a@b..com',
      ]) {
        expect(Validators.email(bad), isNotNull, reason: bad);
      }
    });
  });

  group('Validators.newPassword / confirmPassword', () {
    test('requires 8+ characters with a letter and a number', () {
      expect(Validators.newPassword(''), isNotNull);
      expect(Validators.newPassword('short1'), isNotNull);
      expect(Validators.newPassword('onlyletters'), isNotNull);
      expect(Validators.newPassword('12345678'), isNotNull);
      expect(Validators.newPassword('A' * 129), isNotNull);
      expect(Validators.newPassword('secret123'), isNull);
    });

    test('confirmation must match', () {
      expect(Validators.confirmPassword('', 'secret123'), isNotNull);
      expect(Validators.confirmPassword('secret124', 'secret123'), isNotNull);
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
    });
  });
}