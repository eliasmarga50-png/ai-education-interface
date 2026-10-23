import { AppError } from './AppError.js';

const LOCAL_RE = /^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*$/i;
const LABEL_RE = /^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$/i;
const TLD_RE = /^([a-z]{2,63}|xn--[a-z0-9-]{1,59})$/i;

/** Trims, lowercases and validates the shape of an email. Throws a 422 AppError. */
export function normalizeEmail(input) {
  if (typeof input !== 'string' || input.trim() === '') {
    throw AppError.validation({ email: 'Please enter your email.' });
  }
  const email = input.trim().toLowerCase();
  const invalid = () => AppError.validation({ email: 'Enter a valid email address.' });

  if (email.length > 254) throw invalid();
  const parts = email.split('@');
  if (parts.length !== 2) throw invalid();

  const [local, domain] = parts;
  if (local.length === 0 || local.length > 64 || !LOCAL_RE.test(local)) throw invalid();

  const labels = domain.split('.');
  if (labels.length < 2) throw invalid();
  if (!labels.every((l) => LABEL_RE.test(l))) throw invalid();
  if (!TLD_RE.test(labels[labels.length - 1])) throw invalid();

  return email;
}

// Letters from any language (with combining marks), separated by single spaces,
// hyphens or apostrophes: "José", "Nguyễn Văn", "O'Brien", "Jean-Luc", "ዓለም".
const NAME_RE = /^\p{L}[\p{L}\p{M}]*(?:[ '\u2019-]\p{L}[\p{L}\p{M}]*)*$/u;

export function normalizeName(input) {
  if (typeof input !== 'string') throw AppError.validation({ name: 'Please enter your name.' });
  const name = input.normalize('NFC').trim().replace(/\s+/g, ' ');
  if (name.length === 0) throw AppError.validation({ name: 'Please enter your name.' });
  if (name.length < 2) throw AppError.validation({ name: 'Name must be at least 2 characters.' });
  if (name.length > 60) throw AppError.validation({ name: 'Name must be 60 characters or fewer.' });
  if (!NAME_RE.test(name)) {
    throw AppError.validation({
      name: 'Name can only contain letters, spaces, hyphens and apostrophes.',
    });
  }
  return name;
}

/** Optional short text under the name. Max 160 characters, line breaks allowed, no control characters. */
export function normalizeBio(input) {
  if (typeof input !== 'string') throw AppError.validation({ bio: 'Bio must be text.' });
  const bio = input
    .normalize('NFC')
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '')
    .replace(/\r\n?/g, '\n')
    .trim();
  if ([...bio].length > 160) throw AppError.validation({ bio: 'Bio must be 160 characters or fewer.' });
  return bio;
}

export function validatePassword(password) {
  if (typeof password !== 'string' || password.length === 0) {
    throw AppError.validation({ password: 'Please enter a password.' });
  }
  if (password.length > 128) {
    throw AppError.validation({ password: 'Password must be 128 characters or fewer.' });
  }
  if (password.length < 8 || !/\p{L}/u.test(password) || !/\d/.test(password)) {
    throw AppError.validation({
      password: 'Password must be at least 8 characters and include a letter and a number.',
    });
  }
  return password;
}

export function validateCode(code) {
  const value = typeof code === 'string' ? code.trim() : '';
  if (!/^\d{6}$/.test(value)) {
    throw AppError.validation({ code: 'Enter the 6-digit code.' });
  }
  return value;
}

export function requireString(value, field, label) {
  if (typeof value !== 'string' || value.length === 0) {
    throw AppError.validation({ [field]: `Please enter your ${label}.` });
  }
  return value;
}