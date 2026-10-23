import { AppError } from '../../utils/AppError.js';
import { normalizeBio, normalizeName } from '../../utils/validators.js';

export const LEARNING_GOALS = ['Improve my skills', 'Learn a new skill', 'Prepare for a career', 'Prepare for exams'];
export const DIFFICULTIES = ['Beginner', 'Intermediate', 'Advanced'];
export const MIN_DAILY_GOAL = 5;
export const MAX_DAILY_GOAL = 240;

export const PREFERENCE_DEFAULTS = Object.freeze({
  learningGoal: 'Improve my skills',
  preferredDifficulty: 'Intermediate',
  aiAssistance: true,
  dailyReminders: true,
  dailyGoalMinutes: 15,
});

const AVATAR_MAX_BYTES = 300 * 1024;
const AVATAR_TYPES = {
  'image/jpeg': (b) => b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff,
  'image/png': (b) => b.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
  'image/webp': (b) => b.subarray(0, 4).toString('latin1') === 'RIFF' && b.subarray(8, 12).toString('latin1') === 'WEBP',
};

const isInt = (v) => Number.isInteger(v);

/** Stored value + defaults. A bad or missing stored value falls back to its default. */
export function resolvePreferences(stored) {
  const s = stored && typeof stored === 'object' ? stored : {};
  return {
    learningGoal: LEARNING_GOALS.includes(s.learningGoal) ? s.learningGoal : PREFERENCE_DEFAULTS.learningGoal,
    preferredDifficulty: DIFFICULTIES.includes(s.preferredDifficulty)
      ? s.preferredDifficulty
      : PREFERENCE_DEFAULTS.preferredDifficulty,
    aiAssistance: typeof s.aiAssistance === 'boolean' ? s.aiAssistance : PREFERENCE_DEFAULTS.aiAssistance,
    dailyReminders: typeof s.dailyReminders === 'boolean' ? s.dailyReminders : PREFERENCE_DEFAULTS.dailyReminders,
    dailyGoalMinutes:
      isInt(s.dailyGoalMinutes) && s.dailyGoalMinutes >= MIN_DAILY_GOAL && s.dailyGoalMinutes <= MAX_DAILY_GOAL
        ? s.dailyGoalMinutes
        : PREFERENCE_DEFAULTS.dailyGoalMinutes,
  };
}

/** Validates a partial update. Only known fields are kept; anything invalid is a 422. */
export function parsePreferencesPatch(body) {
  const b = body && typeof body === 'object' ? body : {};
  const patch = {};
  const bad = (field, message) => AppError.validation({ [field]: message });

  if ('learningGoal' in b) {
    if (!LEARNING_GOALS.includes(b.learningGoal)) throw bad('learningGoal', 'Choose one of the listed learning goals.');
    patch.learningGoal = b.learningGoal;
  }
  if ('preferredDifficulty' in b) {
    if (!DIFFICULTIES.includes(b.preferredDifficulty)) throw bad('preferredDifficulty', 'Choose Beginner, Intermediate or Advanced.');
    patch.preferredDifficulty = b.preferredDifficulty;
  }
  for (const field of ['aiAssistance', 'dailyReminders']) {
    if (field in b) {
      if (typeof b[field] !== 'boolean') throw bad(field, 'This setting must be on or off.');
      patch[field] = b[field];
    }
  }
  if ('dailyGoalMinutes' in b) {
    const v = b.dailyGoalMinutes;
    if (!isInt(v) || v < MIN_DAILY_GOAL || v > MAX_DAILY_GOAL) {
      throw bad('dailyGoalMinutes', `Daily goal must be between ${MIN_DAILY_GOAL} and ${MAX_DAILY_GOAL} minutes.`);
    }
    patch.dailyGoalMinutes = v;
  }

  if (Object.keys(patch).length === 0) throw AppError.validation({ preferences: 'Nothing to update.' });
  return patch;
}

/** Checks a photo sent as base64: type, size, and that the bytes really are that image type. */
export function parseAvatar({ contentType, data } = {}) {
  const type = typeof contentType === 'string' ? contentType.trim().toLowerCase() : '';
  const check = AVATAR_TYPES[type];
  const bad = (message) => AppError.validation({ image: message });

  if (!check) throw bad('Choose a JPEG, PNG or WebP image.');
  if (typeof data !== 'string' || data.length === 0) throw bad('Choose a photo first.');
  // Reject early; the decoded size is checked again below.
  if (data.length > Math.ceil((AVATAR_MAX_BYTES * 4) / 3) + 8) throw bad('That photo is too large. Choose one under 300 KB.');
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(data) || data.length % 4 !== 0) throw bad('The photo could not be read. Try another one.');

  const bytes = Buffer.from(data, 'base64');
  if (bytes.length === 0) throw bad('The photo could not be read. Try another one.');
  if (bytes.length > AVATAR_MAX_BYTES) throw bad('That photo is too large. Choose one under 300 KB.');
  if (!check(bytes)) throw bad(`That file is not a valid ${type.replace('image/', '').toUpperCase()} image.`);
  return { contentType: type, bytes };
}

/** Profile rules: what may be changed, what is validated, what the app receives. No Express, no SQL. */
export function createProfileService({ repo, now = Date.now }) {
  const toProfile = (row) => ({
    id: row.id,
    name: row.name,
    email: row.email,
    isVerified: row.email_verified_at != null,
    bio: row.bio ?? '',
    avatar: row.avatar_updated_at != null ? { updatedAt: row.avatar_updated_at } : null,
    preferences: resolvePreferences(row.preferences),
    createdAt: row.created_at,
  });

  async function getProfile(userId) {
    const row = await repo.getProfileRow(userId);
    if (!row) throw new AppError(401, 'UNAUTHORIZED', 'Please log in again.');
    return { profile: toProfile(row) };
  }

  async function updateProfile(userId, body) {
    const b = body && typeof body === 'object' ? body : {};
    const changes = {};
    if ('name' in b) changes.name = normalizeName(b.name);
    if ('bio' in b) changes.bio = normalizeBio(b.bio);
    if (Object.keys(changes).length === 0) throw AppError.validation({ profile: 'Nothing to update.' });

    await repo.updateIdentity(userId, { ...changes, now: now() });
    return getProfile(userId);
  }

  async function updatePreferences(userId, body) {
    await repo.mergePreferences(userId, parsePreferencesPatch(body), now());
    return getProfile(userId);
  }

  async function getAvatar(userId) {
    const row = await repo.getAvatar(userId);
    if (!row) throw new AppError(404, 'NO_AVATAR', 'No profile photo yet.');
    return {
      avatar: {
        contentType: row.content_type,
        data: Buffer.from(row.data).toString('base64'),
        updatedAt: row.updated_at,
      },
    };
  }

  async function setAvatar(userId, body) {
    const { contentType, bytes } = parseAvatar(body);
    const t = now();
    await repo.saveAvatar({ userId, contentType, data: bytes, now: t });
    return { avatar: { updatedAt: t } };
  }

  async function deleteAvatar(userId) {
    await repo.deleteAvatar(userId);
    return { ok: true };
  }

  return { getProfile, updateProfile, updatePreferences, getAvatar, setAvatar, deleteAvatar };
}