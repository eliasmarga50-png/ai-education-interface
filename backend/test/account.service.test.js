import assert from 'node:assert/strict';
import { beforeEach, describe, it } from 'node:test';
import { loadConfig } from '../src/config/env.js';
import { createAuthService } from '../src/modules/auth/auth.service.js';
import { createProfileService } from '../src/modules/profile/profile.service.js';
import { MemoryAuthRepository } from './helpers/memoryAuthRepository.js';
import { MemoryProfileRepository } from './helpers/memoryProfileRepository.js';

const config = loadConfig({
  DATABASE_URL: 'postgresql://user:pass@localhost:5432/test',
  AUTH_CODE_SECRET: 'x'.repeat(40),
  MAIL_MODE: 'console',
});
const silent = { log() {}, warn() {}, error() {} };
const rejects = (p, code) => assert.rejects(p, (e) => e.code === code);

async function setup() {
  const repo = new MemoryAuthRepository();
  const profileRepo = new MemoryProfileRepository(repo);
  const clock = { t: 1_700_000_000_000 };
  const sent = [];
  const auth = createAuthService({
    repo,
    mailer: { sendCode: async (m) => sent.push(m) },
    emailChecker: async () => {},
    config,
    now: () => clock.t,
    logger: silent,
  });
  const profile = createProfileService({ repo: profileRepo, now: () => clock.t });

  await auth.register({ name: 'Alice', email: 'alice@example.com', password: 'secret123' });
  const first = await auth.verifyEmail({ email: 'alice@example.com', code: sent.at(-1).code });
  const second = await auth.login({ email: 'alice@example.com', password: 'secret123' }); // a second device
  return { auth, profile, repo, first, second, clock };
}

describe('change password', () => {
  let s;
  beforeEach(async () => (s = await setup()));

  it('sets the new password, signs other devices out and returns fresh tokens', async () => {
    const id = s.first.user.id;
    const fresh = await s.auth.changePassword(id, { currentPassword: 'secret123', newPassword: 'newsecret456' });

    assert.ok(fresh.accessToken && fresh.refreshToken);
    assert.equal((await s.auth.authenticate(fresh.accessToken)).id, id);

    await rejects(s.auth.authenticate(s.first.accessToken), 'UNAUTHORIZED');
    await rejects(s.auth.authenticate(s.second.accessToken), 'UNAUTHORIZED');
    await rejects(s.auth.refresh({ refreshToken: s.second.refreshToken }), 'INVALID_REFRESH_TOKEN');

    await rejects(s.auth.login({ email: 'alice@example.com', password: 'secret123' }), 'INVALID_CREDENTIALS');
    assert.ok((await s.auth.login({ email: 'alice@example.com', password: 'newsecret456' })).accessToken);
  });

  it('needs the correct current password and a valid, different new one', async () => {
    const id = s.first.user.id;
    await rejects(s.auth.changePassword(id, { currentPassword: 'wrong-pass1', newPassword: 'newsecret456' }), 'INVALID_PASSWORD');
    await rejects(s.auth.changePassword(id, { currentPassword: '', newPassword: 'newsecret456' }), 'VALIDATION_ERROR');
    await rejects(s.auth.changePassword(id, { currentPassword: 'secret123', newPassword: 'short1' }), 'VALIDATION_ERROR');
    await rejects(s.auth.changePassword(id, { currentPassword: 'secret123', newPassword: 'secret123' }), 'VALIDATION_ERROR');
    await rejects(s.auth.changePassword(id, undefined), 'VALIDATION_ERROR');

    // Nothing changed: the old tokens and password still work.
    assert.equal((await s.auth.authenticate(s.first.accessToken)).id, id);
    assert.ok((await s.auth.login({ email: 'alice@example.com', password: 'secret123' })).accessToken);
  });

  it('does not answer 401 for a wrong password (the app would try to refresh its token)', async () => {
    await assert.rejects(
      s.auth.changePassword(s.first.user.id, { currentPassword: 'wrong-pass1', newPassword: 'newsecret456' }),
      (e) => e.statusCode === 403,
    );
  });

  it('locks the account after too many wrong passwords, like login', async () => {
    const id = s.first.user.id;
    for (let i = 0; i < config.auth.maxFailedLogins; i += 1) {
      await rejects(s.auth.changePassword(id, { currentPassword: 'wrong-pass1', newPassword: 'newsecret456' }), 'INVALID_PASSWORD');
    }
    await rejects(s.auth.changePassword(id, { currentPassword: 'secret123', newPassword: 'newsecret456' }), 'ACCOUNT_LOCKED');
    s.clock.t += config.auth.lockMs + 1000;
    assert.ok((await s.auth.changePassword(id, { currentPassword: 'secret123', newPassword: 'newsecret456' })).accessToken);
  });

  it('answers 401 for an account that no longer exists', async () => {
    await rejects(s.auth.changePassword('ghost', { currentPassword: 'secret123', newPassword: 'newsecret456' }), 'UNAUTHORIZED');
  });
});

describe('sign out everywhere', () => {
  it('revokes every session of the account only', async () => {
    const s = await setup();
    const sent = [];
    const other = createAuthService({
      repo: s.repo,
      mailer: { sendCode: async (m) => sent.push(m) },
      emailChecker: async () => {},
      config,
      logger: silent,
    });
    await other.register({ name: 'Bob', email: 'bob@example.com', password: 'secret123' });
    const bob = await other.verifyEmail({ email: 'bob@example.com', code: sent.at(-1).code });

    assert.deepEqual(await s.auth.logoutAll(s.first.user.id), { ok: true });
    await rejects(s.auth.authenticate(s.first.accessToken), 'UNAUTHORIZED');
    await rejects(s.auth.authenticate(s.second.accessToken), 'UNAUTHORIZED');
    assert.equal((await s.auth.authenticate(bob.accessToken)).email, 'bob@example.com');
    await rejects(s.auth.logoutAll('ghost'), 'UNAUTHORIZED');
  });
});

describe('delete account', () => {
  let s;
  beforeEach(async () => (s = await setup()));

  it('needs the password, then removes the account, its sessions and its photo', async () => {
    const id = s.first.user.id;
    await s.profile.setAvatar(id, { contentType: 'image/png', data: Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(8)]).toString('base64') });

    await rejects(s.auth.deleteAccount(id, { password: 'wrong-pass1' }), 'INVALID_PASSWORD');
    await rejects(s.auth.deleteAccount(id, {}), 'VALIDATION_ERROR');
    assert.equal((await s.auth.authenticate(s.first.accessToken)).id, id); // still there

    assert.deepEqual(await s.auth.deleteAccount(id, { password: 'secret123' }), { ok: true });
    await rejects(s.auth.authenticate(s.first.accessToken), 'UNAUTHORIZED');
    await rejects(s.auth.authenticate(s.second.accessToken), 'UNAUTHORIZED');
    await rejects(s.auth.login({ email: 'alice@example.com', password: 'secret123' }), 'INVALID_CREDENTIALS');
    await rejects(s.profile.getProfile(id), 'UNAUTHORIZED');
    await rejects(s.profile.getAvatar(id), 'NO_AVATAR');
  });
});