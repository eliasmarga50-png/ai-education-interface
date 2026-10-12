import assert from 'node:assert/strict';
import { beforeEach, describe, it } from 'node:test';
import { MemoryAuthRepository } from './helpers/memoryAuthRepository.js';
import { createAuthService } from '../src/modules/auth/auth.service.js';
import { createEmailChecker } from '../src/modules/auth/emailCheck.js';
import { loadConfig } from '../src/config/env.js';

const config = loadConfig({
  DATABASE_URL: 'postgresql://user:pass@localhost:5432/test',
  AUTH_CODE_SECRET: 'x'.repeat(40),
  MAIL_MODE: 'console',
});
const silent = { log() {}, warn() {}, error() {} };

function setup({ mailFails = false } = {}) {
  const clock = { t: 1_700_000_000_000 };
  const sent = [];
  const mailer = {
    async sendCode(m) {
      if (mailFails) throw new Error('smtp down');
      sent.push(m);
    },
  };
  const auth = createAuthService({
    repo: new MemoryAuthRepository(),
    mailer,
    emailChecker: async () => {},
    config,
    now: () => clock.t,
    logger: silent,
  });
  const lastCode = () => sent.at(-1).code;
  const advance = (ms) => (clock.t += ms);
  return { auth, sent, lastCode, advance };
}

const alice = { name: 'Alice', email: 'Alice@Example.com ', password: 'secret123' };
const rejects = (p, code) => assert.rejects(p, (e) => e.code === code);

describe('register + verify', () => {
  let s;
  beforeEach(() => (s = setup()));

  it('creates an unverified user, emails a code, and verifies into a session', async () => {
    const r = await s.auth.register(alice);
    assert.equal(r.user.email, 'alice@example.com');
    assert.equal(r.user.isVerified, false);
    assert.equal(r.codeSent, true);
    assert.equal(s.sent.length, 1);
    assert.match(s.lastCode(), /^\d{6}$/);

    const v = await s.auth.verifyEmail({ email: 'alice@example.com', code: s.lastCode() });
    assert.equal(v.user.isVerified, true);
    assert.ok(v.accessToken && v.refreshToken);
    assert.equal((await s.auth.authenticate(v.accessToken)).email, 'alice@example.com');
  });

  it('rejects bad input with field errors', async () => {
    await rejects(s.auth.register({ ...alice, email: 'nope' }), 'VALIDATION_ERROR');
    await rejects(s.auth.register({ ...alice, password: 'short1' }), 'VALIDATION_ERROR');
    await rejects(s.auth.register({ ...alice, password: 'onlyletters' }), 'VALIDATION_ERROR');
    await rejects(s.auth.register({ ...alice, name: ' ' }), 'VALIDATION_ERROR');
  });

  it('name validation: rejects empty, numbers-only and names containing digits', async () => {
    for (const bad of ['', '   ', '12345', 'John2', '2John', 'A1', 'x_y', 'John!', '-Anna', "Anna-", "O''Brien", 'a--b', 'Anna  -  Lee', '😀😀', 'A'.repeat(61)]) {
      await assert.rejects(s.auth.register({ ...alice, name: bad }), (e) => e.code === 'VALIDATION_ERROR' && Boolean(e.extra.fields.name), `should reject ${JSON.stringify(bad)}`);
    }
    await rejects(s.auth.register({ ...alice, name: 42 }), 'VALIDATION_ERROR');
    await rejects(s.auth.register({ ...alice, name: null }), 'VALIDATION_ERROR');
  });

  it('name validation: accepts international letters, spaces, hyphens and apostrophes', async () => {
    const good = ['José Álvarez', "Seán O'Brien", 'Jean-Luc Picard', 'Nguyễn Văn An', 'Łukasz Żółć', 'Müller', 'محمد علي', '李小龙', 'ዓለም ተስፋዬ', 'Zoë', "D’Angelo", 'Ana María de la Cruz'];
    for (const [i, name] of good.entries()) {
      const r = await s.auth.register({ name, email: `user${i}@example.com`, password: 'secret123' });
      assert.equal(r.user.name, name.normalize('NFC'));
    }
  });

  it('name is trimmed and inner whitespace collapsed', async () => {
    const r = await s.auth.register({ ...alice, name: '  Mary    Ann  ' });
    assert.equal(r.user.name, 'Mary Ann');
  });

  it('blocks a duplicate verified email', async () => {
    await s.auth.register(alice);
    await s.auth.verifyEmail({ email: alice.email, code: s.lastCode() });
    await rejects(s.auth.register(alice), 'EMAIL_TAKEN');
  });

  it('re-registering an UNVERIFIED email re-sends a code but never changes the password (no pre-hijacking)', async () => {
    await s.auth.register(alice);
    s.advance(61_000);
    const attacker = await s.auth.register({ name: 'Mallory', email: alice.email, password: 'attacker999' });
    assert.equal(attacker.codeSent, true);
    assert.equal(attacker.user.name, 'Alice');
    // the real owner types the code that arrived in their inbox
    await s.auth.verifyEmail({ email: alice.email, code: s.lastCode() });
    await rejects(s.auth.login({ email: alice.email, password: 'attacker999' }), 'INVALID_CREDENTIALS');
    await s.auth.login({ email: alice.email, password: 'secret123' });
  });

  it('an unverified owner can set a new password with Forgot password', async () => {
    await s.auth.register(alice);
    s.advance(61_000);
    await s.auth.forgotPassword({ email: alice.email });
    await s.auth.resetPassword({ email: alice.email, code: s.lastCode(), newPassword: 'newpass456' });
    const r = await s.auth.login({ email: alice.email, password: 'newpass456' });
    assert.equal(r.user.isVerified, true);
  });

  it('wrong code counts attempts and then invalidates', async () => {
    await s.auth.register(alice);
    const wrong = s.lastCode() === '000000' ? '111111' : '000000';
    for (let i = 0; i < 4; i++) await rejects(s.auth.verifyEmail({ email: alice.email, code: wrong }), 'INVALID_CODE');
    await rejects(s.auth.verifyEmail({ email: alice.email, code: wrong }), 'INVALID_CODE');
    await rejects(s.auth.verifyEmail({ email: alice.email, code: s.lastCode() }), 'TOO_MANY_ATTEMPTS');
  });

  it('expired code is refused; resend gives a new working code', async () => {
    await s.auth.register(alice);
    const old = s.lastCode();
    s.advance(11 * 60 * 1000);
    await rejects(s.auth.verifyEmail({ email: alice.email, code: old }), 'CODE_EXPIRED');
    await s.auth.resendCode({ email: alice.email });
    const v = await s.auth.verifyEmail({ email: alice.email, code: s.lastCode() });
    assert.equal(v.user.isVerified, true);
  });

  it('a code cannot be reused, and an older code dies when a new one is issued', async () => {
    await s.auth.register(alice);
    const first = s.lastCode();
    s.advance(61_000);
    await s.auth.resendCode({ email: alice.email });
    const second = s.lastCode();
    if (first !== second) await rejects(s.auth.verifyEmail({ email: alice.email, code: first }), 'INVALID_CODE');
    await s.auth.verifyEmail({ email: alice.email, code: second });
    await rejects(s.auth.verifyEmail({ email: alice.email, code: second }), 'ALREADY_VERIFIED');
  });

  it('resend has a cooldown and an hourly cap', async () => {
    await s.auth.register(alice);
    await rejects(s.auth.resendCode({ email: alice.email }), 'CODE_COOLDOWN');
    for (let i = 0; i < 4; i++) {
      s.advance(61_000);
      await s.auth.resendCode({ email: alice.email });
    }
    s.advance(61_000);
    await rejects(s.auth.resendCode({ email: alice.email }), 'CODE_LIMIT');
  });

  it('unknown email gives the generic answer', async () => {
    await rejects(s.auth.verifyEmail({ email: 'ghost@example.com', code: '123456' }), 'INVALID_CODE');
    const r = await s.auth.resendCode({ email: 'ghost@example.com' });
    assert.equal(r.sent, true);
    assert.equal(s.sent.length, 0);
  });
});

describe('mail failure', () => {
  it('register still succeeds but reports codeSent=false, and resend is not blocked by a cooldown', async () => {
    const s = setup({ mailFails: true });
    const r = await s.auth.register(alice);
    assert.equal(r.codeSent, false);
    await rejects(s.auth.resendCode({ email: alice.email }), 'EMAIL_SEND_FAILED');
  });
});

describe('login', () => {
  let s;
  beforeEach(async () => {
    s = setup();
    await s.auth.register(alice);
    await s.auth.verifyEmail({ email: alice.email, code: s.lastCode() });
  });

  it('logs in with the right password', async () => {
    const r = await s.auth.login({ email: 'ALICE@example.com', password: 'secret123' });
    assert.equal(r.user.name, 'Alice');
  });

  it('gives one generic error for wrong password and unknown email', async () => {
    await rejects(s.auth.login({ email: alice.email, password: 'wrongpass1' }), 'INVALID_CREDENTIALS');
    await rejects(s.auth.login({ email: 'ghost@example.com', password: 'wrongpass1' }), 'INVALID_CREDENTIALS');
  });

  it('locks after 5 failures, even for the right password, then unlocks', async () => {
    for (let i = 0; i < 5; i++) await rejects(s.auth.login({ email: alice.email, password: 'bad12345' }), 'INVALID_CREDENTIALS');
    await rejects(s.auth.login({ email: alice.email, password: 'secret123' }), 'ACCOUNT_LOCKED');
    s.advance(16 * 60 * 1000);
    await s.auth.login({ email: alice.email, password: 'secret123' });
  });

  it('unverified account: 403 EMAIL_NOT_VERIFIED and a fresh code is sent', async () => {
    const t = setup();
    await t.auth.register({ name: 'Bob', email: 'bob@example.com', password: 'bobpass123' });
    t.advance(61_000);
    const before = t.sent.length;
    await assert.rejects(
      t.auth.login({ email: 'bob@example.com', password: 'bobpass123' }),
      (e) => e.code === 'EMAIL_NOT_VERIFIED' && e.statusCode === 403 && e.extra.codeSent === true,
    );
    assert.equal(t.sent.length, before + 1);
  });
});

describe('sessions', () => {
  let s, session;
  beforeEach(async () => {
    s = setup();
    await s.auth.register(alice);
    session = await s.auth.verifyEmail({ email: alice.email, code: s.lastCode() });
  });

  it('refresh rotates tokens and the old refresh token stops working', async () => {
    const next = await s.auth.refresh({ refreshToken: session.refreshToken });
    assert.notEqual(next.refreshToken, session.refreshToken);
    await rejects(s.auth.refresh({ refreshToken: session.refreshToken }), 'INVALID_REFRESH_TOKEN');
    assert.equal((await s.auth.authenticate(next.accessToken)).name, 'Alice');
    await rejects(s.auth.authenticate(session.accessToken), 'UNAUTHORIZED');
  });

  it('access token expires; refresh token expires later', async () => {
    s.advance(16 * 60 * 1000);
    await rejects(s.auth.authenticate(session.accessToken), 'UNAUTHORIZED');
    const next = await s.auth.refresh({ refreshToken: session.refreshToken });
    s.advance(31 * 24 * 60 * 60 * 1000);
    await rejects(s.auth.refresh({ refreshToken: next.refreshToken }), 'INVALID_REFRESH_TOKEN');
  });

  it('logout revokes the session', async () => {
    await s.auth.logout({ refreshToken: session.refreshToken });
    await rejects(s.auth.authenticate(session.accessToken), 'UNAUTHORIZED');
    await rejects(s.auth.refresh({ refreshToken: session.refreshToken }), 'INVALID_REFRESH_TOKEN');
    await s.auth.logout({ refreshToken: 'garbage' }); // idempotent
  });
});

describe('password reset', () => {
  let s, session;
  beforeEach(async () => {
    s = setup();
    await s.auth.register(alice);
    session = await s.auth.verifyEmail({ email: alice.email, code: s.lastCode() });
    s.advance(61_000);
  });

  it('never reveals whether the account exists', async () => {
    const a = await s.auth.forgotPassword({ email: alice.email });
    const b = await s.auth.forgotPassword({ email: 'ghost@example.com' });
    assert.equal(a.message, b.message);
  });

  it('resets with the code, signs out every device, and the new password works', async () => {
    await s.auth.forgotPassword({ email: alice.email });
    await s.auth.resetPassword({ email: alice.email, code: s.lastCode(), newPassword: 'brandnew789' });
    await rejects(s.auth.authenticate(session.accessToken), 'UNAUTHORIZED');
    await rejects(s.auth.login({ email: alice.email, password: 'secret123' }), 'INVALID_CREDENTIALS');
    await s.auth.login({ email: alice.email, password: 'brandnew789' });
  });

  it('a verify-email code cannot be used to reset a password', async () => {
    await s.auth.forgotPassword({ email: alice.email });
    const resetCode = s.lastCode();
    const wrong = resetCode === '123456' ? '654321' : '123456';
    await rejects(s.auth.resetPassword({ email: alice.email, code: wrong, newPassword: 'brandnew789' }), 'INVALID_CODE');
  });

  it('rejects a weak new password', async () => {
    await s.auth.forgotPassword({ email: alice.email });
    await rejects(s.auth.resetPassword({ email: alice.email, code: s.lastCode(), newPassword: 'weak' }), 'VALIDATION_ERROR');
  });
});

describe('email checker', () => {
  const dnsWith = (impl) => ({
    resolveMx: impl.mx ?? (async () => []),
    resolve4: impl.a ?? (async () => []),
    resolve6: impl.aaaa ?? (async () => []),
  });
  const err = (code) => Object.assign(new Error(code), { code });

  it('suggests a fix for common typos', async () => {
    const check = createEmailChecker({ dns: dnsWith({}), logger: silent });
    await assert.rejects(check('sam@gmial.com'), (e) => e.code === 'EMAIL_TYPO' && /sam@gmail\.com/.test(e.message));
  });

  it('blocks disposable domains', async () => {
    const check = createEmailChecker({ dns: dnsWith({}), logger: silent });
    await rejects(check('x@mailinator.com'), 'EMAIL_DISPOSABLE');
  });

  it('accepts a domain with MX records', async () => {
    const check = createEmailChecker({ dns: dnsWith({ mx: async () => [{ exchange: 'mx.example.com', priority: 10 }] }), logger: silent });
    await check('a@example.com');
  });

  it('falls back to an A record when there is no MX', async () => {
    const check = createEmailChecker({ dns: dnsWith({ mx: async () => { throw err('ENODATA'); }, a: async () => ['1.2.3.4'] }), logger: silent });
    await check('a@example.com');
  });

  it('rejects a domain that does not exist', async () => {
    const nx = async () => { throw err('ENOTFOUND'); };
    const check = createEmailChecker({ dns: dnsWith({ mx: nx, a: nx, aaaa: nx }), logger: silent });
    await rejects(check('a@no-such-domain-xyz.com'), 'EMAIL_DOMAIN_INVALID');
  });

  it('rejects a null-MX domain', async () => {
    const check = createEmailChecker({ dns: dnsWith({ mx: async () => [{ exchange: '', priority: 0 }] }), logger: silent });
    await rejects(check('a@example.com'), 'EMAIL_DOMAIN_INVALID');
  });

  it('does NOT block users when DNS itself is failing', async () => {
    const check = createEmailChecker({ dns: dnsWith({ mx: async () => { throw err('ETIMEOUT'); } }), logger: silent });
    await check('a@example.com');
  });
});

describe('concurrency (what changes when many requests share one hosted database)', () => {
  it('parallel wrong guesses cannot exceed the attempt limit, and the right code is then refused', async () => {
    const s = setup();
    await s.auth.register(alice);
    const right = s.lastCode();
    const wrong = right === '000000' ? '111111' : '000000';

    const results = await Promise.allSettled(
      Array.from({ length: 12 }, () => s.auth.verifyEmail({ email: alice.email, code: wrong })),
    );
    const invalid = results.filter((r) => r.reason?.code === 'INVALID_CODE').length;
    const tooMany = results.filter((r) => r.reason?.code === 'TOO_MANY_ATTEMPTS').length;
    assert.equal(invalid, 5);
    assert.equal(tooMany, 7);
    await rejects(s.auth.verifyEmail({ email: alice.email, code: right }), 'TOO_MANY_ATTEMPTS');
  });

  it('one code cannot start two sessions when submitted twice at once', async () => {
    const s = setup();
    await s.auth.register(alice);
    const code = s.lastCode();
    const results = await Promise.allSettled([
      s.auth.verifyEmail({ email: alice.email, code }),
      s.auth.verifyEmail({ email: alice.email, code }),
    ]);
    assert.equal(results.filter((r) => r.status === 'fulfilled').length, 1);
  });

  it('two refreshes with the same token: exactly one succeeds', async () => {
    const s = setup();
    await s.auth.register(alice);
    const session = await s.auth.verifyEmail({ email: alice.email, code: s.lastCode() });
    const results = await Promise.allSettled([
      s.auth.refresh({ refreshToken: session.refreshToken }),
      s.auth.refresh({ refreshToken: session.refreshToken }),
    ]);
    assert.equal(results.filter((r) => r.status === 'fulfilled').length, 1);
    assert.equal(results.find((r) => r.status === 'rejected').reason.code, 'INVALID_REFRESH_TOKEN');
  });

  it('two sign-ups for the same new email at once create ONE account', async () => {
    const s = setup();
    const [a, b] = await Promise.all([s.auth.register(alice), s.auth.register(alice)]);
    assert.equal(a.user.id, b.user.id);
  });
});