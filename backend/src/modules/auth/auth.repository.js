/**
 * Every SQL statement for authentication lives here (PostgreSQL via node-postgres).
 * The service never sees SQL, and every method is async.
 *
 * Atomic statements matter on a hosted database: several requests can run at the
 * same time, so "read, decide, write" would let two of them both win. The methods
 * that guard against that say so below.
 */
export class AuthRepository {
  /** @param pool a node-postgres Pool (or anything with query() and connect()) */
  constructor(pool) {
    this.pool = pool;
  }

  async #one(sql, params) {
    const result = await this.pool.query(sql, params);
    return result.rows[0];
  }

  /** Runs [work] inside BEGIN/COMMIT on a single connection; rolls back on error. */
  async #transaction(work) {
    const client = await this.pool.connect();
    let destroy = false;
    try {
      await client.query('BEGIN');
      const result = await work(client);
      await client.query('COMMIT');
      return result;
    } catch (err) {
      try {
        await client.query('ROLLBACK');
      } catch {
        destroy = true; // the connection itself is broken: do not return it to the pool
      }
      throw err;
    } finally {
      client.release(destroy);
    }
  }

  // ---- users ---------------------------------------------------------------

  findUserByEmail(email) {
    return this.#one('SELECT * FROM users WHERE email = $1', [email]);
  }

  findUserById(id) {
    return this.#one('SELECT * FROM users WHERE id = $1', [id]);
  }

  /**
   * Creates the user, or returns the row that already has this email (two parallel
   * sign-ups for one address must not crash on the UNIQUE constraint).
   */
  async createUser({ id, name, email, passwordHash, now }) {
    const created = await this.#one(
      `INSERT INTO users (id, name, email, password_hash, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $5)
       ON CONFLICT (email) DO NOTHING
       RETURNING *`,
      [id, name, email, passwordHash, now],
    );
    return created ?? this.findUserByEmail(email);
  }

  async markVerified(id, now) {
    await this.pool.query(
      'UPDATE users SET email_verified_at = COALESCE(email_verified_at, $1), updated_at = $1 WHERE id = $2',
      [now, id],
    );
  }

  async setLoginFailures(id, count, lockedUntil, now) {
    await this.pool.query(
      'UPDATE users SET failed_login_count = $1, locked_until = $2, updated_at = $3 WHERE id = $4',
      [count, lockedUntil, now, id],
    );
  }

  /**
   * Password reset in ONE transaction: new password, mailbox proven (verified),
   * lock cleared, and every session revoked. Either all of it happens or none.
   */
  updatePasswordAndRevokeSessions({ userId, passwordHash, now }) {
    return this.#transaction(async (client) => {
      await client.query(
        `UPDATE users
            SET password_hash = $1,
                email_verified_at = COALESCE(email_verified_at, $2),
                failed_login_count = 0,
                locked_until = NULL,
                updated_at = $2
          WHERE id = $3`,
        [passwordHash, now, userId],
      );
      await client.query(
        'UPDATE sessions SET revoked_at = $1 WHERE user_id = $2 AND revoked_at IS NULL',
        [now, userId],
      );
    });
  }

  // ---- verification codes --------------------------------------------------

  /** Newest code of this purpose (used or not), or undefined. */
  latestCode(userId, purpose) {
    return this.#one(
      `SELECT * FROM verification_codes
        WHERE user_id = $1 AND purpose = $2
        ORDER BY created_at DESC, seq DESC
        LIMIT 1`,
      [userId, purpose],
    );
  }

  async countCodesSince(userId, purpose, since) {
    const row = await this.#one(
      'SELECT COUNT(*) AS n FROM verification_codes WHERE user_id = $1 AND purpose = $2 AND created_at > $3',
      [userId, purpose, since],
    );
    return row.n;
  }

  /** Retires every unused code of this purpose and stores the new one, atomically. */
  replaceCode({ id, userId, purpose, codeHash, expiresAt, createdAt }) {
    return this.#transaction(async (client) => {
      await client.query(
        'UPDATE verification_codes SET consumed_at = $1 WHERE user_id = $2 AND purpose = $3 AND consumed_at IS NULL',
        [createdAt, userId, purpose],
      );
      await client.query(
        `INSERT INTO verification_codes (id, user_id, purpose, code_hash, expires_at, created_at)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [id, userId, purpose, codeHash, expiresAt, createdAt],
      );
    });
  }

  async deleteCode(id) {
    await this.pool.query('DELETE FROM verification_codes WHERE id = $1', [id]);
  }

  /**
   * Uses up one guess. Atomic: ten parallel guesses cannot get past the limit,
   * because the database only increments while attempts < max.
   * Returns the new attempt count, or null when no attempts are left.
   */
  async claimAttempt(id, maxAttempts) {
    const row = await this.#one(
      `UPDATE verification_codes
          SET attempts = attempts + 1
        WHERE id = $1 AND attempts < $2 AND consumed_at IS NULL
        RETURNING attempts`,
      [id, maxAttempts],
    );
    return row ? row.attempts : null;
  }

  /** True only for the request that actually consumed the code (a code works once). */
  async consumeCode(id, now) {
    const result = await this.pool.query(
      'UPDATE verification_codes SET consumed_at = $1 WHERE id = $2 AND consumed_at IS NULL',
      [now, id],
    );
    return result.rowCount === 1;
  }

  // ---- sessions ------------------------------------------------------------

  async createSession({ id, userId, accessHash, accessExpiresAt, refreshHash, refreshExpiresAt, now }) {
    await this.pool.query(
      `INSERT INTO sessions
         (id, user_id, access_hash, access_expires_at, refresh_hash, refresh_expires_at, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [id, userId, accessHash, accessExpiresAt, refreshHash, refreshExpiresAt, now],
    );
  }

  findSessionByAccessHash(hash) {
    return this.#one('SELECT * FROM sessions WHERE access_hash = $1', [hash]);
  }

  findSessionByRefreshHash(hash) {
    return this.#one('SELECT * FROM sessions WHERE refresh_hash = $1', [hash]);
  }

  /**
   * Swaps in new tokens only if the session still holds [oldRefreshHash] and is not
   * revoked. Atomic: when two requests refresh with the same token, exactly one wins.
   */
  async rotateSession(id, oldRefreshHash, { accessHash, accessExpiresAt, refreshHash, refreshExpiresAt }) {
    const result = await this.pool.query(
      `UPDATE sessions
          SET access_hash = $1, access_expires_at = $2, refresh_hash = $3, refresh_expires_at = $4
        WHERE id = $5 AND refresh_hash = $6 AND revoked_at IS NULL`,
      [accessHash, accessExpiresAt, refreshHash, refreshExpiresAt, id, oldRefreshHash],
    );
    return result.rowCount === 1;
  }

  async revokeSession(id, now) {
    await this.pool.query('UPDATE sessions SET revoked_at = $1 WHERE id = $2 AND revoked_at IS NULL', [now, id]);
  }

  // ---- housekeeping --------------------------------------------------------

  async purgeExpired(now) {
    const day = 24 * 60 * 60 * 1000;
    await this.pool.query(
      'DELETE FROM sessions WHERE refresh_expires_at < $1 OR (revoked_at IS NOT NULL AND revoked_at < $2)',
      [now, now - 7 * day],
    );
    await this.pool.query('DELETE FROM verification_codes WHERE created_at < $1', [now - day]);
    await this.pool.query('DELETE FROM users WHERE email_verified_at IS NULL AND created_at < $1', [now - 7 * day]);
  }
}