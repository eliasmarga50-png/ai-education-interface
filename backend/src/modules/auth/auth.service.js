import { randomUUID } from 'node:crypto';
import { AppError } from '../../utils/AppError.js';
import {
  generateCode,
  hashPassword,
  hmacCode,
  randomToken,
  safeEqual,
  sha256Hex,
  verifyPassword,
} from '../../utils/crypto.js';
import {
  normalizeEmail,
  normalizeName,
  requireString,
  validateCode,
  validatePassword,
} from '../../utils/validators.js';

const HOUR = 60 * 60 * 1000;

/**
 * All authentication rules. No Express and no SQL in here, so it can be unit-tested
 * with an in-memory repository.
 *
 * Tokens are opaque random strings (not JWTs): only their SHA-256 hash is stored,
 * every session can be revoked instantly, and there is no signing secret to leak.
 *
 * The database is shared by many requests at once (hosted PostgreSQL), so anything
 * that must happen "only once" (a guess counter, a code, a refresh token) is decided
 * by ONE atomic repository call, never by "read, check in JavaScript, write".
 */
export function createAuthService({ repo, mailer, emailChecker, config, now = Date.now, logger = console }) {
  const policy = config.auth;
  let dummyHash = null; // used so "unknown email" takes as long as "wrong password"

  const publicUser = (u) => ({
    id: u.id,
    name: u.name,
    email: u.email,
    isVerified: u.email_verified_at != null,
  });

  // ---- verification codes -------------------------------------------------

  /**
   * Creates a fresh code and emails it. soft=true never throws for cooldown /
   * limit / mail problems; it reports them in the return value instead.
   */
  async function issueCode(user, purpose, { soft = false } = {}) {
    const t = now();

    const last = await repo.latestCode(user.id, purpose);
    if (last) {
      const waitMs = last.created_at + policy.resendCooldownMs - t;
      if (waitMs > 0) {
        const retryAfter = Math.ceil(waitMs / 1000);
        if (soft) return { sent: false, retryAfter, reason: 'COOLDOWN' };
        throw new AppError(429, 'CODE_COOLDOWN', `Please wait ${retryAfter}s before requesting another code.`, {
          retryAfter,
        });
      }
    }

    if ((await repo.countCodesSince(user.id, purpose, t - HOUR)) >= policy.maxCodesPerHour) {
      if (soft) return { sent: false, retryAfter: 3600, reason: 'LIMIT' };
      throw new AppError(429, 'CODE_LIMIT', 'Too many codes requested. Please try again in an hour.', {
        retryAfter: 3600,
      });
    }

    const code = generateCode();
    const id = randomUUID();
    await repo.replaceCode({
      id,
      userId: user.id,
      purpose,
      codeHash: hmacCode(code, policy.codeSecret, user.id, purpose),
      expiresAt: t + policy.codeTtlMs,
      createdAt: t,
    });

    try {
      await mailer.sendCode({
        to: user.email,
        name: user.name,
        code,
        purpose,
        expiresInMinutes: Math.round(policy.codeTtlMs / 60000),
      });
    } catch (err) {
      logger.error('[mail] sending failed:', err.message);
      await repo.deleteCode(id); // a code nobody received must not start a cooldown
      if (soft) return { sent: false, retryAfter: 0, reason: 'MAIL_FAILED' };
      throw new AppError(502, 'EMAIL_SEND_FAILED', "We couldn't send the email. Please try again in a moment.");
    }

    return { sent: true, retryAfter: Math.ceil(policy.resendCooldownMs / 1000) };
  }

  /** Throws unless [code] matches the newest unused code. Consumes it on success. */
  async function checkCode(user, purpose, rawCode) {
    const code = validateCode(rawCode);
    const t = now();
    const rec = await repo.latestCode(user.id, purpose);

    if (!rec || rec.consumed_at || rec.expires_at <= t) {
      throw new AppError(400, 'CODE_EXPIRED', 'This code has expired. Please request a new one.');
    }

    // Spend a guess BEFORE comparing, in one atomic step, so parallel guesses
    // cannot get past the attempt limit.
    const attempts = await repo.claimAttempt(rec.id, policy.maxCodeAttempts);
    if (attempts === null) {
      throw new AppError(429, 'TOO_MANY_ATTEMPTS', 'Too many incorrect attempts. Please request a new code.');
    }

    const expected = hmacCode(code, policy.codeSecret, user.id, purpose);
    if (!safeEqual(expected, rec.code_hash)) {
      const left = policy.maxCodeAttempts - attempts;
      throw new AppError(
        400,
        'INVALID_CODE',
        left > 0
          ? `Incorrect code. ${left} attempt${left === 1 ? '' : 's'} left.`
          : 'Incorrect code. Please request a new one.',
        { attemptsLeft: left },
      );
    }

    // Only one request can consume a code, even if it was sent twice at once.
    if (!(await repo.consumeCode(rec.id, t))) {
      throw new AppError(400, 'CODE_EXPIRED', 'This code has expired. Please request a new one.');
    }
  }

  const unknownCode = () => new AppError(400, 'INVALID_CODE', 'Incorrect or expired code.');

  // ---- sessions -----------------------------------------------------------

  async function startSession(user) {
    const t = now();
    const tokens = newTokens();
    await repo.createSession({
      id: randomUUID(),
      userId: user.id,
      accessHash: sha256Hex(tokens.accessToken),
      accessExpiresAt: t + policy.accessTtlMs,
      refreshHash: sha256Hex(tokens.refreshToken),
      refreshExpiresAt: t + policy.refreshTtlMs,
      now: t,
    });
    return { user: publicUser(user), ...tokens };
  }

  function newTokens() {
    return {
      accessToken: randomToken(),
      refreshToken: randomToken(),
      accessTokenExpiresIn: Math.floor(policy.accessTtlMs / 1000),
    };
  }

  // ---- public operations --------------------------------------------------

  async function register({ name, email, password } = {}) {
    const cleanName = normalizeName(name);
    const cleanEmail = normalizeEmail(email);
    validatePassword(password);

    await emailChecker(cleanEmail); // typo / disposable / domain cannot receive mail -> 422

    const taken = () =>
      new AppError(409, 'EMAIL_TAKEN', 'An account with this email already exists. Please log in.');

    const existing = await repo.findUserByEmail(cleanEmail);
    if (existing?.email_verified_at) throw taken();

    // An unverified account keeps its ORIGINAL name and password. If registering
    // again replaced them, anyone who knew the email could set a password of their
    // own and then log in as soon as the real owner typed the emailed code
    // ("pre-hijacking"). The owner can still use "Forgot password" to choose a new one.
    const user =
      existing ??
      (await repo.createUser({
        id: randomUUID(),
        name: cleanName,
        email: cleanEmail,
        passwordHash: await hashPassword(password),
        now: now(),
      }));

    // createUser returns the existing row when a parallel request won the race.
    if (user.email_verified_at) throw taken();

    const dispatch = await issueCode(user, 'verify_email', { soft: true });
    return {
      user: publicUser(user),
      codeSent: dispatch.sent,
      resendAvailableInSeconds: dispatch.retryAfter,
    };
  }

  async function verifyEmail({ email, code } = {}) {
    const cleanEmail = normalizeEmail(email);
    const user = await repo.findUserByEmail(cleanEmail);
    if (!user) {
      validateCode(code);
      throw unknownCode();
    }
    if (user.email_verified_at) {
      throw new AppError(409, 'ALREADY_VERIFIED', 'This email is already verified. Please log in.');
    }

    await checkCode(user, 'verify_email', code);
    await repo.markVerified(user.id, now());
    return startSession(await repo.findUserById(user.id));
  }

  async function resendCode({ email } = {}) {
    const cleanEmail = normalizeEmail(email);
    const user = await repo.findUserByEmail(cleanEmail);
    // Same answer whether or not the account exists, so this cannot be used to probe emails.
    if (!user || user.email_verified_at) {
      return { sent: true, resendAvailableInSeconds: Math.ceil(policy.resendCooldownMs / 1000) };
    }
    const dispatch = await issueCode(user, 'verify_email');
    return { sent: true, resendAvailableInSeconds: dispatch.retryAfter };
  }

  async function login({ email, password } = {}) {
    const cleanEmail = normalizeEmail(email);
    requireString(password, 'password', 'password');
    const invalid = () => new AppError(401, 'INVALID_CREDENTIALS', 'Incorrect email or password.');

    const user = await repo.findUserByEmail(cleanEmail);
    if (!user) {
      dummyHash ??= await hashPassword('timing-equalizer');
      await verifyPassword(password, dummyHash);
      throw invalid();
    }

    const t = now();
    if (user.locked_until && user.locked_until > t) {
      const retryAfter = Math.ceil((user.locked_until - t) / 1000);
      const mins = Math.ceil(retryAfter / 60);
      throw new AppError(
        429,
        'ACCOUNT_LOCKED',
        `Too many failed attempts. Try again in ${mins} minute${mins === 1 ? '' : 's'}.`,
        { retryAfter },
      );
    }

    if (!(await verifyPassword(password, user.password_hash))) {
      const count = user.failed_login_count + 1;
      if (count >= policy.maxFailedLogins) await repo.setLoginFailures(user.id, 0, t + policy.lockMs, t);
      else await repo.setLoginFailures(user.id, count, null, t);
      throw invalid();
    }

    if (user.failed_login_count > 0 || user.locked_until) await repo.setLoginFailures(user.id, 0, null, t);

    if (!user.email_verified_at) {
      const dispatch = await issueCode(user, 'verify_email', { soft: true });
      throw new AppError(403, 'EMAIL_NOT_VERIFIED', 'Please verify your email to continue.', {
        email: user.email,
        codeSent: dispatch.sent,
        retryAfter: dispatch.retryAfter,
      });
    }

    return startSession(user);
  }

  async function refresh({ refreshToken } = {}) {
    const bad = () => new AppError(401, 'INVALID_REFRESH_TOKEN', 'Your session has expired. Please log in again.');
    if (typeof refreshToken !== 'string' || refreshToken === '') throw bad();

    const oldHash = sha256Hex(refreshToken);
    const session = await repo.findSessionByRefreshHash(oldHash);
    const t = now();
    if (!session || session.revoked_at || session.refresh_expires_at <= t) throw bad();

    const user = await repo.findUserById(session.user_id);
    if (!user) throw bad();

    const tokens = newTokens();
    const rotated = await repo.rotateSession(session.id, oldHash, {
      accessHash: sha256Hex(tokens.accessToken),
      accessExpiresAt: t + policy.accessTtlMs,
      refreshHash: sha256Hex(tokens.refreshToken),
      refreshExpiresAt: t + policy.refreshTtlMs,
    });
    // Another request used this refresh token a moment earlier.
    if (!rotated) throw bad();

    return { user: publicUser(user), ...tokens };
  }

  async function logout({ refreshToken } = {}) {
    if (typeof refreshToken === 'string' && refreshToken !== '') {
      const session = await repo.findSessionByRefreshHash(sha256Hex(refreshToken));
      if (session) await repo.revokeSession(session.id, now());
    }
    return { ok: true };
  }

  /** Used by the authenticate middleware. */
  async function authenticate(accessToken) {
    const unauthorized = () => new AppError(401, 'UNAUTHORIZED', 'Please log in again.');
    if (typeof accessToken !== 'string' || accessToken === '') throw unauthorized();

    const session = await repo.findSessionByAccessHash(sha256Hex(accessToken));
    if (!session || session.revoked_at || session.access_expires_at <= now()) throw unauthorized();

    const user = await repo.findUserById(session.user_id);
    if (!user) throw unauthorized();
    return publicUser(user);
  }

  async function forgotPassword({ email } = {}) {
    const cleanEmail = normalizeEmail(email);
    const user = await repo.findUserByEmail(cleanEmail);
    if (user) {
      await issueCode(user, 'reset_password', { soft: true });
    }
    // Always the same answer: never reveal whether the email has an account.
    return { message: 'If an account exists for this email, a reset code has been sent.' };
  }

  async function resetPassword({ email, code, newPassword } = {}) {
    const cleanEmail = normalizeEmail(email);
    validateCode(code);
    validatePassword(newPassword);

    const user = await repo.findUserByEmail(cleanEmail);
    if (!user) throw unknownCode();

    await checkCode(user, 'reset_password', code);

    // One transaction: new password, mailbox proven (verified), lock cleared and every
    // device signed out. Receiving the code proves the mailbox is theirs.
    await repo.updatePasswordAndRevokeSessions({
      userId: user.id,
      passwordHash: await hashPassword(newPassword),
      now: now(),
    });
    return { message: 'Password updated. Please log in.' };
  }

  async function purgeExpired() {
    await repo.purgeExpired(now());
  }

  return {
    register,
    verifyEmail,
    resendCode,
    login,
    refresh,
    logout,
    authenticate,
    forgotPassword,
    resetPassword,
    purgeExpired,
  };
}