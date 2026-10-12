/**
 * In-memory stand-in for AuthRepository, used by the unit tests so they run with
 * no database. It follows the same contract, including the atomic rules
 * (claimAttempt, consumeCode, rotateSession). The real SQL is checked by
 * `npm run db:check` against an actual PostgreSQL database.
 */
export class MemoryAuthRepository {
  constructor() {
    this.users = new Map();
    this.codes = [];
    this.sessions = new Map();
    this.seq = 0;
  }

  async findUserByEmail(email) {
    return [...this.users.values()].find((u) => u.email === email);
  }

  async findUserById(id) {
    return this.users.get(id);
  }

  async createUser({ id, name, email, passwordHash, now }) {
    const existing = await this.findUserByEmail(email);
    if (existing) return existing; // same as ON CONFLICT DO NOTHING + re-read
    const user = {
      id, name, email, password_hash: passwordHash, email_verified_at: null,
      failed_login_count: 0, locked_until: null, created_at: now, updated_at: now,
    };
    this.users.set(id, user);
    return user;
  }

  async markVerified(id, now) {
    const u = this.users.get(id);
    u.email_verified_at ??= now;
    u.updated_at = now;
  }

  async setLoginFailures(id, count, lockedUntil, now) {
    Object.assign(this.users.get(id), { failed_login_count: count, locked_until: lockedUntil, updated_at: now });
  }

  async updatePasswordAndRevokeSessions({ userId, passwordHash, now }) {
    const u = this.users.get(userId);
    Object.assign(u, { password_hash: passwordHash, failed_login_count: 0, locked_until: null, updated_at: now });
    u.email_verified_at ??= now;
    for (const s of this.sessions.values()) if (s.user_id === userId && !s.revoked_at) s.revoked_at = now;
  }

  async latestCode(userId, purpose) {
    return this.codes
      .filter((c) => c.user_id === userId && c.purpose === purpose)
      .sort((a, b) => b.created_at - a.created_at || b.seq - a.seq)[0];
  }

  async countCodesSince(userId, purpose, since) {
    return this.codes.filter((c) => c.user_id === userId && c.purpose === purpose && c.created_at > since).length;
  }

  async replaceCode({ id, userId, purpose, codeHash, expiresAt, createdAt }) {
    for (const c of this.codes) {
      if (c.user_id === userId && c.purpose === purpose && !c.consumed_at) c.consumed_at = createdAt;
    }
    this.codes.push({
      id, seq: ++this.seq, user_id: userId, purpose, code_hash: codeHash,
      expires_at: expiresAt, attempts: 0, consumed_at: null, created_at: createdAt,
    });
  }

  async deleteCode(id) {
    this.codes = this.codes.filter((c) => c.id !== id);
  }

  async claimAttempt(id, maxAttempts) {
    const c = this.codes.find((x) => x.id === id);
    if (!c || c.consumed_at || c.attempts >= maxAttempts) return null;
    c.attempts += 1;
    return c.attempts;
  }

  async consumeCode(id, now) {
    const c = this.codes.find((x) => x.id === id);
    if (!c || c.consumed_at) return false;
    c.consumed_at = now;
    return true;
  }

  async createSession({ id, userId, accessHash, accessExpiresAt, refreshHash, refreshExpiresAt, now }) {
    this.sessions.set(id, {
      id, user_id: userId, access_hash: accessHash, access_expires_at: accessExpiresAt,
      refresh_hash: refreshHash, refresh_expires_at: refreshExpiresAt, created_at: now, revoked_at: null,
    });
  }

  async findSessionByAccessHash(hash) {
    return [...this.sessions.values()].find((s) => s.access_hash === hash);
  }

  async findSessionByRefreshHash(hash) {
    return [...this.sessions.values()].find((s) => s.refresh_hash === hash);
  }

  async rotateSession(id, oldRefreshHash, { accessHash, accessExpiresAt, refreshHash, refreshExpiresAt }) {
    const s = this.sessions.get(id);
    if (!s || s.refresh_hash !== oldRefreshHash || s.revoked_at) return false;
    Object.assign(s, {
      access_hash: accessHash, access_expires_at: accessExpiresAt,
      refresh_hash: refreshHash, refresh_expires_at: refreshExpiresAt,
    });
    return true;
  }

  async revokeSession(id, now) {
    const s = this.sessions.get(id);
    if (s && !s.revoked_at) s.revoked_at = now;
  }

  async purgeExpired() {}
}