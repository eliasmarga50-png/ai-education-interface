/// Form rules shared by every screen. They mirror the backend
/// (backend/src/utils/validators.js), which stays the final authority:
/// the app only gives faster feedback.
class Validators {
  Validators._();

  // Letters from any language (with combining marks), separated by single
  // spaces, hyphens or apostrophes: "José", "Nguyễn Văn", "O'Brien",
  // "Jean-Luc", "ዓለም". No digits, no symbols, no leading/trailing separators.
  static final RegExp _nameRe = RegExp(
    r"^\p{L}[\p{L}\p{M}]*(?:[ '\u2019-]\p{L}[\p{L}\p{M}]*)*$",
    unicode: true,
  );

  static final RegExp _emailLocalRe = RegExp(
    r"^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*$",
  );
  static final RegExp _emailLabelRe = RegExp(
    r'^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$',
  );
  static final RegExp _emailTldRe = RegExp(r'^([a-z]{2,63}|xn--[a-z0-9-]{1,59})$');

  static final RegExp _letterRe = RegExp(r'\p{L}', unicode: true);
  static final RegExp _digitRe = RegExp(r'\d');

  /// Trims and collapses inner whitespace ("  Mary   Ann " -> "Mary Ann").
  static String normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// null when valid, otherwise a message that is safe to show.
  static String? name(String? value) {
    final name = normalizeName(value ?? '');

    if (name.isEmpty) {
      return 'Please enter your name.';
    }
    if (name.length < 2) {
      return 'Name must be at least 2 characters.';
    }
    if (name.length > 60) {
      return 'Name must be 60 characters or fewer.';
    }
    if (!_nameRe.hasMatch(name)) {
      return 'Name can only contain letters, spaces, hyphens and apostrophes.';
    }
    return null;
  }

  static bool isValidEmail(String input) {
    final email = input.trim().toLowerCase();
    if (email.isEmpty || email.length > 254) {
      return false;
    }

    final parts = email.split('@');
    if (parts.length != 2) {
      return false;
    }

    final local = parts[0];
    final domain = parts[1];
    if (local.isEmpty || local.length > 64 || !_emailLocalRe.hasMatch(local)) {
      return false;
    }

    final labels = domain.split('.');
    if (labels.length < 2) {
      return false;
    }
    if (!labels.every(_emailLabelRe.hasMatch)) {
      return false;
    }
    return _emailTldRe.hasMatch(labels.last);
  }

  static String? email(String? value) {
    final email = (value ?? '').trim();

    if (email.isEmpty) {
      return 'Please enter your email.';
    }
    if (!isValidEmail(email)) {
      return 'Please enter a valid email.';
    }
    return null;
  }

  /// Sign-up and reset rule: 8-128 characters with a letter and a number.
  static String? newPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Please enter a password.';
    }
    if (password.length > 128) {
      return 'Password must be 128 characters or fewer.';
    }
    if (password.length < 8 ||
        !_letterRe.hasMatch(password) ||
        !_digitRe.hasMatch(password)) {
      return 'Use at least 8 characters, with a letter and a number.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }
}