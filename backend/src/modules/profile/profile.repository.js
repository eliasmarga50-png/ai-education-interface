/**
 * SQL for the profile (name, bio, preferences, photo). Same rules as AuthRepository: no SQL
 * outside this file, every method async. Updates are single statements, so two devices saving
 * at the same moment cannot half-overwrite each other.
 */
export class ProfileRepository {
  /** @param pool a node-postgres Pool (or anything with query()) */
  constructor(pool) {
    this.pool = pool;
  }

  async #one(sql, params) {
    const result = await this.pool.query(sql, params);
    return result.rows[0];
  }

  /** The profile row WITHOUT the photo bytes; avatar_updated_at is null when there is no photo. */
  getProfileRow(userId) {
    return this.#one(
      `SELECT u.id, u.name, u.email, u.email_verified_at, u.bio, u.preferences, u.created_at,
              a.updated_at AS avatar_updated_at
         FROM users u
         LEFT JOIN user_avatars a ON a.user_id = u.id
        WHERE u.id = $1`,
      [userId],
    );
  }

  /** null means "leave this field as it is". */
  async updateIdentity(userId, { name, bio, now }) {
    await this.pool.query(
      `UPDATE users
          SET name = COALESCE($1, name), bio = COALESCE($2, bio), updated_at = $3
        WHERE id = $4`,
      [name ?? null, bio ?? null, now, userId],
    );
  }

  /** Merges [patch] into the stored preferences in ONE statement (jsonb || jsonb). */
  async mergePreferences(userId, patch, now) {
    await this.pool.query(
      'UPDATE users SET preferences = preferences || $1::jsonb, updated_at = $2 WHERE id = $3',
      [JSON.stringify(patch), now, userId],
    );
  }

  getAvatar(userId) {
    return this.#one('SELECT content_type, data, updated_at FROM user_avatars WHERE user_id = $1', [userId]);
  }

  async saveAvatar({ userId, contentType, data, now }) {
    await this.pool.query(
      `INSERT INTO user_avatars (user_id, content_type, data, updated_at)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id) DO UPDATE
         SET content_type = EXCLUDED.content_type, data = EXCLUDED.data, updated_at = EXCLUDED.updated_at`,
      [userId, contentType, data, now],
    );
  }

  async deleteAvatar(userId) {
    await this.pool.query('DELETE FROM user_avatars WHERE user_id = $1', [userId]);
  }
}