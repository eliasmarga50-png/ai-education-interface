import assert from 'node:assert/strict';
import { beforeEach, describe, it } from 'node:test';
import { MemoryAuthRepository } from './helpers/memoryAuthRepository.js';
import { MemoryProfileRepository } from './helpers/memoryProfileRepository.js';
import {
  PREFERENCE_DEFAULTS,
  createProfileService,
  parseAvatar,
  parsePreferencesPatch,
  resolvePreferences,
} from '../src/modules/profile/profile.service.js';

const rejects = (p, code) => assert.rejects(p, (e) => e.code === code);

// 1x1 PNG / minimal JPEG and WebP headers: enough to pass the "real image" check.
const PNG = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(20, 1)]);
const JPEG = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(20, 2)]);
const WEBP = Buffer.concat([Buffer.from('RIFF'), Buffer.alloc(4), Buffer.from('WEBP'), Buffer.alloc(10)]);
const b64 = (buf) => buf.toString('base64');

async function setup() {
  const authRepo = new MemoryAuthRepository();
  const repo = new MemoryProfileRepository(authRepo);
  const clock = { t: 1_700_000_000_000 };
  const service = createProfileService({ repo, now: () => (clock.t += 1000) });
  for (const [id, name] of [['u1', 'Alice'], ['u2', 'Bob']]) {
    await authRepo.createUser({ id, name, email: `${name.toLowerCase()}@example.com`, passwordHash: 'h', now: 1 });
    await authRepo.markVerified(id, 2);
  }
  return { service, authRepo };
}

describe('get profile', () => {
  it('returns the account with default preferences, no bio and no photo', async () => {
    const { service } = await setup();
    const { profile } = await service.getProfile('u1');
    assert.equal(profile.name, 'Alice');
    assert.equal(profile.email, 'alice@example.com');
    assert.equal(profile.isVerified, true);
    assert.equal(profile.bio, '');
    assert.equal(profile.avatar, null);
    assert.deepEqual(profile.preferences, PREFERENCE_DEFAULTS);
    assert.equal(profile.password_hash, undefined);
  });

  it('answers 401 for an account that no longer exists', async () => {
    const { service } = await setup();
    await rejects(service.getProfile('ghost'), 'UNAUTHORIZED');
  });
});

describe('update profile', () => {
  let s;
  beforeEach(async () => (s = await setup()));

  it('saves a normalised name and bio, and returns the new profile', async () => {
    const { profile } = await s.service.updateProfile('u1', { name: '  Mary   Ann ', bio: '  Hello\r\nthere  ' });
    assert.equal(profile.name, 'Mary Ann');
    assert.equal(profile.bio, 'Hello\nthere');
    assert.equal((await s.service.getProfile('u1')).profile.name, 'Mary Ann');
  });

  it('changes only the fields that were sent', async () => {
    await s.service.updateProfile('u1', { bio: 'Learning Flutter' });
    const { profile } = await s.service.updateProfile('u1', { name: 'Alicia' });
    assert.equal(profile.name, 'Alicia');
    assert.equal(profile.bio, 'Learning Flutter');
  });

  it('can clear the bio', async () => {
    await s.service.updateProfile('u1', { bio: 'x' });
    assert.equal((await s.service.updateProfile('u1', { bio: '   ' })).profile.bio, '');
  });

  it('rejects bad names, long bios, wrong types and empty updates', async () => {
    await rejects(s.service.updateProfile('u1', { name: 'A' }), 'VALIDATION_ERROR');
    await rejects(s.service.updateProfile('u1', { name: 'R2D2' }), 'VALIDATION_ERROR');
    await rejects(s.service.updateProfile('u1', { name: 42 }), 'VALIDATION_ERROR');
    await rejects(s.service.updateProfile('u1', { bio: 'x'.repeat(161) }), 'VALIDATION_ERROR');
    await rejects(s.service.updateProfile('u1', { bio: null }), 'VALIDATION_ERROR');
    await rejects(s.service.updateProfile('u1', {}), 'VALIDATION_ERROR');
    await rejects(s.service.updateProfile('u1', undefined), 'VALIDATION_ERROR');
    assert.equal((await s.service.getProfile('u1')).profile.name, 'Alice');
  });

  it('counts a bio in characters, not UTF-16 units (160 emoji are allowed)', async () => {
    assert.equal((await s.service.updateProfile('u1', { bio: '😀'.repeat(160) })).profile.bio.length, 320);
    await rejects(s.service.updateProfile('u1', { bio: '😀'.repeat(161) }), 'VALIDATION_ERROR');
  });

  it('never touches another account', async () => {
    await s.service.updateProfile('u1', { name: 'Alicia', bio: 'mine' });
    const bob = (await s.service.getProfile('u2')).profile;
    assert.equal(bob.name, 'Bob');
    assert.equal(bob.bio, '');
  });
});

describe('preferences', () => {
  let s;
  beforeEach(async () => (s = await setup()));

  it('merges a partial update and keeps the rest', async () => {
    await s.service.updatePreferences('u1', { dailyGoalMinutes: 30 });
    const { profile } = await s.service.updatePreferences('u1', { learningGoal: 'Prepare for exams', dailyReminders: false });
    assert.deepEqual(profile.preferences, {
      ...PREFERENCE_DEFAULTS,
      dailyGoalMinutes: 30,
      learningGoal: 'Prepare for exams',
      dailyReminders: false,
    });
  });

  it('validates every field', () => {
    for (const bad of [
      { learningGoal: 'Rule the world' },
      { preferredDifficulty: 'Impossible' },
      { aiAssistance: 'yes' },
      { dailyReminders: 1 },
      { dailyGoalMinutes: 4 },
      { dailyGoalMinutes: 241 },
      { dailyGoalMinutes: 20.5 },
      { dailyGoalMinutes: '20' },
      {},
      null,
      { unknownField: true },
    ]) {
      assert.throws(() => parsePreferencesPatch(bad), (e) => e.code === 'VALIDATION_ERROR', JSON.stringify(bad));
    }
    assert.deepEqual(parsePreferencesPatch({ dailyGoalMinutes: 5, extra: 'ignored' }), { dailyGoalMinutes: 5 });
  });

  it('falls back to defaults for missing or corrupt stored values', () => {
    assert.deepEqual(resolvePreferences(null), PREFERENCE_DEFAULTS);
    assert.deepEqual(resolvePreferences({ learningGoal: 'old value', dailyGoalMinutes: -3, aiAssistance: 'x' }), PREFERENCE_DEFAULTS);
    assert.equal(resolvePreferences({ dailyReminders: false }).dailyReminders, false);
  });
});

describe('profile photo', () => {
  let s;
  beforeEach(async () => (s = await setup()));

  it('stores, returns and deletes a photo', async () => {
    const saved = await s.service.setAvatar('u1', { contentType: 'image/png', data: b64(PNG) });
    assert.ok(saved.avatar.updatedAt > 0);
    assert.equal((await s.service.getProfile('u1')).profile.avatar.updatedAt, saved.avatar.updatedAt);

    const got = await s.service.getAvatar('u1');
    assert.equal(got.avatar.contentType, 'image/png');
    assert.equal(got.avatar.data, b64(PNG));
    assert.equal(got.avatar.updatedAt, saved.avatar.updatedAt);

    await s.service.deleteAvatar('u1');
    assert.equal((await s.service.getProfile('u1')).profile.avatar, null);
    await rejects(s.service.getAvatar('u1'), 'NO_AVATAR');
  });

  it('a new photo replaces the old one and changes updatedAt', async () => {
    const a = await s.service.setAvatar('u1', { contentType: 'image/jpeg', data: b64(JPEG) });
    const b = await s.service.setAvatar('u1', { contentType: 'image/webp', data: b64(WEBP) });
    assert.notEqual(a.avatar.updatedAt, b.avatar.updatedAt);
    assert.equal((await s.service.getAvatar('u1')).avatar.contentType, 'image/webp');
  });

  it('photos are private to their owner and deleting twice is fine', async () => {
    await s.service.setAvatar('u1', { contentType: 'image/png', data: b64(PNG) });
    await rejects(s.service.getAvatar('u2'), 'NO_AVATAR');
    assert.deepEqual(await s.service.deleteAvatar('u2'), { ok: true });
    assert.deepEqual(await s.service.deleteAvatar('u2'), { ok: true });
  });

  it('rejects wrong types, fake images, broken base64, empty and oversized files', () => {
    const bad = (input) => assert.throws(() => parseAvatar(input), (e) => e.code === 'VALIDATION_ERROR');
    bad({ contentType: 'image/gif', data: b64(PNG) });
    bad({ contentType: 'text/html', data: b64(Buffer.from('<script>')) });
    bad({ contentType: 'image/png', data: b64(JPEG) }); // type says PNG, bytes are JPEG
    bad({ contentType: 'image/png', data: b64(Buffer.from('not an image at all')) });
    bad({ contentType: 'image/png', data: 'not base64!!' });
    bad({ contentType: 'image/png', data: 'abc' }); // length not a multiple of 4
    bad({ contentType: 'image/png', data: '' });
    bad({ contentType: 'image/png' });
    bad({});
    bad(undefined);
    bad({ contentType: 'image/png', data: b64(Buffer.concat([PNG, Buffer.alloc(300 * 1024)])) });
  });

  it('accepts a photo right at the size limit', () => {
    const exactly = Buffer.concat([PNG, Buffer.alloc(300 * 1024 - PNG.length)]);
    assert.equal(parseAvatar({ contentType: 'IMAGE/PNG ', data: b64(exactly) }).bytes.length, 300 * 1024);
  });
});